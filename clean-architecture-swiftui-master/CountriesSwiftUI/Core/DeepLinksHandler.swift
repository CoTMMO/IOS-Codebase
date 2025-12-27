//
//  DeepLinksHandler.swift
//  CountriesSwiftUI
//
//  Created by Alexey Naumov on 26.04.2020.
//  Copyright © 2020 Alexey Naumov. All rights reserved.
//  Refactored for improved performance and memory management
//

import Foundation

enum DeepLink: Equatable {
    
    case showCountryFlag(alpha3Code: String)

    init?(url: URL) {
        guard
            let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
            components.host == "www.example.com",
            let query = components.queryItems
            else { return nil }
        if let item = query.first(where: { $0.name == "alpha3code" }),
            let alpha3Code = item.value {
            self = .showCountryFlag(alpha3Code: alpha3Code)
            return
        }
        return nil
    }
}

// MARK: - DeepLinksHandler Protocol

@MainActor
protocol DeepLinksHandler: AnyObject {
    func open(deepLink: DeepLink)
}

// MARK: - Optimized DeepLinksHandler Implementation

@MainActor
final class OptimizedDeepLinksHandler: DeepLinksHandler {
    
    // MARK: - Properties
    
    private weak var container: DIContainer?
    private var pendingDeepLink: DeepLink?
    private var isProcessingDeepLink = false
    private let navigationQueue = DispatchQueue(label: "com.countries.deepLink.navigation", qos: .userInitiated)
    
    // MARK: - Initialization
    
    init(container: DIContainer) {
        self.container = container
    }
    
    // MARK: - DeepLinksHandler Protocol
    
    func open(deepLink: DeepLink) {
        // Prevent concurrent deep link processing
        guard !isProcessingDeepLink else {
            pendingDeepLink = deepLink
            return
        }
        
        isProcessingDeepLink = true
        pendingDeepLink = nil
        
        navigationQueue.async { [weak self] in
            await self?.processDeepLink(deepLink)
        }
    }
    
    // MARK: - Private Methods
    
    @MainActor
    private func processDeepLink(_ deepLink: DeepLink) async {
        defer {
            isProcessingDeepLink = false
            // Process any pending deep link
            if let pendingLink = pendingDeepLink {
                pendingDeepLink = nil
                open(deepLink: pendingLink)
            }
        }
        
        guard let container = container else { return }
        
        switch deepLink {
        case let .showCountryFlag(alpha3Code):
            await processCountryFlagDeepLink(container: container, alpha3Code: alpha3Code)
        }
    }
    
    @MainActor
    private func processCountryFlagDeepLink(container: DIContainer, alpha3Code: String) async {
        // Use optimized state updates
        container.appState.updateRouting { routing in
            routing.countriesList.countryCode = alpha3Code
            routing.countryDetails.detailsSheet = true
        }
        
        // Check if we need to reset navigation state
        let defaultRouting = AppState.ViewRouting()
        if container.appState.routing != defaultRouting {
            // Use optimized navigation with proper timing
            await resetNavigationIfNeeded(container: container)
        }
    }
    
    @MainActor
    private func resetNavigationIfNeeded(container: DIContainer) async {
        // Reset routing state
        container.appState.updateRouting { $0 = AppState.ViewRouting() }
        
        // Wait for UI to settle before navigating
        let delay: DispatchTime = .now() + (ProcessInfo.processInfo.isRunningTests ? 0 : 1.5)
        
        await withCheckedContinuation { continuation in
            DispatchQueue.main.asyncAfter(deadline: delay) {
                self.performNavigation(container: container)
                continuation.resume()
            }
        }
    }
    
    @MainActor
    private func performNavigation(container: DIContainer) {
        container.appState.updateRouting { routing in
            routing.countriesList.countryCode = pendingDeepLink?.alpha3Code ?? ""
            routing.countryDetails.detailsSheet = true
        }
    }
}

// MARK: - Extension for Alpha3Code Extraction

private extension DeepLink {
    var alpha3Code: String {
        switch self {
        case .showCountryFlag(let code):
            return code
        }
    }
}
