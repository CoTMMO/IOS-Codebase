//
//  PushNotificationsHandler.swift
//  CountriesSwiftUI
//
//  Created by Alexey Naumov on 26.04.2020.
//  Copyright © 2020 Alexey Naumov. All rights reserved.
//  Refactored for improved performance and memory management
//

import UserNotifications

protocol PushNotificationsHandler: AnyObject { }

@MainActor
final class OptimizedPushNotificationsHandler: NSObject, PushNotificationsHandler, UNUserNotificationCenterDelegate {
    
    // MARK: - Properties
    
    private weak var deepLinksHandler: DeepLinksHandler?
    private var pendingNotifications: [UNNotification] = []
    private let notificationQueue = DispatchQueue(label: "com.countries.notifications", qos: .userInitiated)
    private let maxPendingNotifications = 10
    
    // MARK: - Initialization
    
    init(deepLinksHandler: DeepLinksHandler) {
        self.deepLinksHandler = deepLinksHandler
        super.init()
        setupNotificationCenter()
    }
    
    deinit {
        cleanup()
    }
    
    // MARK: - Setup
    
    private func setupNotificationCenter() {
        UNUserNotificationCenter.current().delegate = self
    }
    
    // MARK: - Cleanup
    
    private func cleanup() {
        pendingNotifications.removeAll()
        UNUserNotificationCenter.current().delegate = nil
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler:
        @escaping (UNNotificationPresentationOptions) -> Void) {
        
        // Process notification before showing
        processNotification(userInfo: notification.request.content.userInfo)
        
        // Show notification with optimized options
        let options: UNNotificationPresentationOptions = [.list, .banner]
        if #available(iOS 14.0, *) {
            options.insert(.badge)
        }
        
        completionHandler(options)
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        
        let userInfo = response.notification.request.content.userInfo
        handleNotification(userInfo: userInfo, completionHandler: completionHandler)
    }
    
    // MARK: - Public Methods
    
    func handleNotification(userInfo: [AnyHashable: Any], completionHandler: @escaping () -> Void) {
        notificationQueue.async { [weak self] in
            await self?.processNotification(userInfo: userInfo, completionHandler: completionHandler)
        }
    }
    
    // MARK: - Private Methods
    
    @MainActor
    private func processNotification(userInfo: [AnyHashable: Any], completionHandler: (() -> Void)? = nil) async {
        defer {
            completionHandler?()
        }
        
        guard let payload = userInfo["aps"] as? [AnyHashable: Any],
              let countryCode = payload["country"] as? String else {
            return
        }
        
        // Process deep link
        await deepLinksHandler?.open(deepLink: .showCountryFlag(alpha3Code: countryCode))
    }
    
    @MainActor
    private func processNotification(userInfo: [AnyHashable: Any]) {
        // Add to pending notifications if processing is slow
        if pendingNotifications.count >= maxPendingNotifications {
            pendingNotifications.removeFirst()
        }
        
        // Create notification object for processing
        if let aps = userInfo["aps"] as? [AnyHashable: Any],
           let alert = aps["alert"] as? [String: Any],
           let title = alert["title"] as? String,
           let body = alert["body"] as? String {
            
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.userInfo = userInfo
            
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
            let notification = UNNotification(request: request, date: Date())
            
            pendingNotifications.append(notification)
        }
    }
}
