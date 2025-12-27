//
//  SystemEventsHandler.swift
//  CountriesSwiftUI
//
//  Created by Alexey Naumov on 27.10.2019.
//  Copyright © 2019 Alexey Naumov. All rights reserved.
//  Refactored for improved performance and memory management
//

import UIKit
import Combine

@MainActor
protocol SystemEventsHandler: AnyObject {
    func sceneOpenURLContexts(_ urlContexts: Set<UIOpenURLContext>)
    func sceneDidBecomeActive()
    func sceneWillResignActive()
    func handlePushRegistration(result: Result<Data, Error>)
    func appDidReceiveRemoteNotification(payload: [AnyHashable: Any]) async -> UIBackgroundFetchResult
    func cleanup()
}

@MainActor
final class OptimizedSystemEventsHandler: SystemEventsHandler {

    // MARK: - Properties
    
    private weak var container: DIContainer?
    private let deepLinksHandler: DeepLinksHandler
    private let pushNotificationsHandler: PushNotificationsHandler
    private let pushTokenWebRepository: PushTokenWebRepository
    
    // MARK: - Memory Management
    
    private var cancellables = Set<AnyCancellable>()
    private var keyboardHeightSubscription: AnyCancellable?
    private var permissionSubscription: AnyCancellable?
    private var memoryPressureObserver: NSObjectProtocol?
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    
    // MARK: - Initialization
    
    init(container: DIContainer,
         deepLinksHandler: DeepLinksHandler,
         pushNotificationsHandler: PushNotificationsHandler,
         pushTokenWebRepository: PushTokenWebRepository) {
        
        self.container = container
        self.deepLinksHandler = deepLinksHandler
        self.pushNotificationsHandler = pushNotificationsHandler
        self.pushTokenWebRepository = pushTokenWebRepository
        
        setupSubscriptions()
        setupMemoryPressureObserver()
        setupBackgroundTaskExpirationHandler()
    }
    
    deinit {
        cleanup()
    }
    
    // MARK: - Setup Methods
    
    private func setupSubscriptions() {
        guard let container = container else { return }
        
        // Optimized keyboard height observer with throttling
        keyboardHeightSubscription = NotificationCenter.default
            .keyboardHeightPublisher
            .throttle(for: .milliseconds(100), scheduler: DispatchQueue.main, latest: true)
            .sink { [weak container] height in
                container?.appState.updateSystem { $0.keyboardHeight = height }
            }
        
        // Optimized permission status observer
        permissionSubscription = container.appState
            .updates(for: AppState.permissionKeyPath(for: .pushNotifications))
            .removeDuplicates()
            .filter { $0 != .unknown }
            .sink { [weak container] status in
                if status == .granted {
                    container?.interactors.userPermissions.request(permission: .pushNotifications)
                }
            }
    }
    
    private func setupMemoryPressureObserver() {
        memoryPressureObserver = NotificationCenter.default
            .addObserver(forName: UIApplication.didReceiveMemoryWarningNotification,
                        object: nil,
                        queue: .main) { [weak self] _ in
                self?.handleMemoryPressure()
            }
    }
    
    private func setupBackgroundTaskExpirationHandler() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.startBackgroundTask()
        }
    }
    
    // MARK: - SystemEventsHandler Protocol
    
    func sceneOpenURLContexts(_ urlContexts: Set<UIOpenURLContext>) {
        guard let url = urlContexts.first?.url else { return }
        handle(url: url)
    }
    
    func sceneDidBecomeActive() {
        guard let container = container else { return }
        
        container.appState.updateSystem {
            $0.isActive = true
            $0.lastActiveTime = Date()
            $0.memoryPressureLevel = .normal
        }
        
        container.interactors.userPermissions.resolveStatus(for: .pushNotifications)
    }
    
    func sceneWillResignActive() {
        guard let container = container else { return }
        
        container.appState.updateSystem { $0.isActive = false }
        container.appState.cleanupForBackground()
        
        // Cleanup resources when going to background
        cleanupForBackground()
    }
    
    func handlePushRegistration(result: Result<Data, Error>) {
        // Optimized push registration handling
        switch result {
        case .success(let deviceToken):
            Task { @MainActor in
                await registerPushToken(deviceToken)
            }
        case .failure(let error):
            handlePushRegistrationError(error)
        }
    }
    
    func appDidReceiveRemoteNotification(payload: [AnyHashable: Any]) async -> UIBackgroundFetchResult {
        guard let container = container else { return .noData }
        
        // Start background task for processing notification
        let taskID = startBackgroundTask()
        
        defer {
            endBackgroundTask(taskID)
        }
        
        do {
            let result = try await processRemoteNotification(payload, container: container)
            return result
        } catch {
            return .failed
        }
    }
    
    func cleanup() {
        // Cancel all subscriptions
        cancellables.removeAll()
        keyboardHeightSubscription?.cancel()
        permissionSubscription?.cancel()
        
        // Remove observers
        if let observer = memoryPressureObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        
        // End any active background tasks
        if backgroundTask != .invalid {
            endBackgroundTask(backgroundTask)
        }
    }
    
    // MARK: - Private Methods
    
    private func handle(url: URL) {
        guard let deepLink = DeepLink(url: url) else { return }
        deepLinksHandler.open(deepLink: deepLink)
    }
    
    private func handleMemoryPressure() {
        guard let container = container else { return }
        
        // Update memory pressure level
        container.appState.updateSystem { $0.memoryPressureLevel = .warning }
        
        // Trigger cleanup
        container.appState.cleanupForBackground()
        
        // Clear caches if needed
        clearCachesIfNeeded()
    }
    
    private func clearCachesIfNeeded() {
        // Clear image cache
        URLCache.shared.removeAllCachedResponses()
        
        // Clear any in-memory caches
        // (Implementation depends on your caching strategy)
    }
    
    private func startBackgroundTask() -> UIBackgroundTaskIdentifier {
        let taskID = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.endBackgroundTask(taskID)
        }
        return taskID
    }
    
    private func endBackgroundTask(_ taskID: UIBackgroundTaskIdentifier) {
        if taskID != .invalid {
            UIApplication.shared.endBackgroundTask(taskID)
        }
    }
    
    private func cleanupForBackground() {
        // Perform background cleanup
        keyboardHeightSubscription?.cancel()
        permissionSubscription?.cancel()
    }
    
    private func registerPushToken(_ deviceToken: Data) async {
        // Optimized push token registration with retry logic
        let maxRetries = 3
        var retryCount = 0
        
        while retryCount < maxRetries {
            do {
                try await pushTokenWebRepository.register(deviceToken: deviceToken)
                break
            } catch {
                retryCount += 1
                if retryCount < maxRetries {
                    try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
                }
            }
        }
    }
    
    private func handlePushRegistrationError(_ error: Error) {
        // Log error but don't crash
        #if DEBUG
        print("Push registration failed: \(error.localizedDescription)")
        #endif
    }
    
    private func processRemoteNotification(_ payload: [AnyHashable: Any], container: DIContainer) async throws -> UIBackgroundFetchResult {
        guard let aps = payload["aps"] as? [AnyHashable: Any],
              let countryCode = aps["country"] as? String else {
            return .noData
        }
        
        // Process notification in background
        await MainActor.run {
            deepLinksHandler.open(deepLink: .showCountryFlag(alpha3Code: countryCode))
        }
        
        return .newData
    }
}

// MARK: - Notifications Extension

private extension NotificationCenter {
    var keyboardHeightPublisher: AnyPublisher<CGFloat, Never> {
        let willShow = publisher(for: UIApplication.keyboardWillShowNotification)
            .map { $0.keyboardHeight }
        let willHide = publisher(for: UIApplication.keyboardWillHideNotification)
            .map { _ in CGFloat(0) }
        return Publishers.Merge(willShow, willHide)
            .eraseToAnyPublisher()
    }
}

private extension Notification {
    var keyboardHeight: CGFloat {
        return (userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?
            .cgRectValue.height ?? 0
    }
}
