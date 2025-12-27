//
//  AppState.swift
//  CountriesSwiftUI
//
//  Created by Alexey Naumov on 23.10.2019.
//  Copyright © 2019 Alexey Naumov. All rights reserved.
//  Refactored for improved performance and memory management
//

import SwiftUI
import Combine

/// Optimized application state with efficient memory management
@MainActor
final class AppState: ObservableObject, Identifiable {
    @Published private(set) var routing = ViewRouting()
    @Published private(set) var system = System()
    @Published private(set) var permissions = Permissions()
    
    private var cancellables = Set<AnyCancellable>()
    
    /// Reset all state to initial values
    func reset() {
        routing = ViewRouting()
        system = System()
        permissions = Permissions()
    }
    
    /// Update routing state efficiently
    func updateRouting(_ update: (inout ViewRouting) -> Void) {
        var newRouting = routing
        update(&newRouting)
        if newRouting != routing {
            routing = newRouting
        }
    }
    
    /// Update system state efficiently
    func updateSystem(_ update: (inout System) -> Void) {
        var newSystem = system
        update(&newSystem)
        if newSystem != system {
            system = newSystem
        }
    }
    
    /// Update permissions state efficiently
    func updatePermissions(_ update: (inout Permissions) -> Void) {
        var newPermissions = permissions
        update(&newPermissions)
        if newPermissions != permissions {
            permissions = newPermissions
        }
    }
}

// MARK: - Nested State Structures

extension AppState {
    /// View routing state with optimized navigation
    struct ViewRouting: Equatable, Codable {
        var countriesList = CountriesList.Routing()
        var countryDetails = CountryDetails.Routing()
        
        /// Reset all routing state
        mutating func reset() {
            countriesList = CountriesList.Routing()
            countryDetails = CountryDetails.Routing()
        }
    }
}

extension AppState {
    /// System state with performance optimizations
    struct System: Equatable, Codable {
        var isActive: Bool = false
        var keyboardHeight: CGFloat = 0
        var lastActiveTime: Date = Date()
        var memoryPressureLevel: MemoryPressureLevel = .normal
        
        enum MemoryPressureLevel: String, Codable {
            case normal, warning, critical
        }
    }
}

extension AppState {
    /// Permissions state with efficient updates
    struct Permissions: Equatable, Codable {
        var push: Permission.Status = .unknown
        var location: Permission.Status = .unknown
        var camera: Permission.Status = .unknown
        
        /// Get permission status for a specific permission
        func status(for permission: Permission) -> Permission.Status {
            switch permission {
            case .pushNotifications: return push
            case .location: return location
            case .camera: return camera
            }
        }
    }
    
    /// Get key path for permission updates
    static func permissionKeyPath(for permission: Permission) -> WritableKeyPath<Permissions, Permission.Status> {
        switch permission {
        case .pushNotifications: return \.push
        case .location: return \.location
        case .camera: return \.camera
        }
    }
}

// MARK: - Performance Extensions

extension AppState {
    /// Efficient state comparison for UI updates
    static func == (lhs: AppState, rhs: AppState) -> Bool {
        return lhs.routing == rhs.routing
            && lhs.system == rhs.system
            && lhs.permissions == rhs.permissions
    }
    
    /// Check if state has meaningful changes
    func hasMeaningfulChanges(from previous: AppState) -> Bool {
        return routing != previous.routing
            || system != previous.system
            || permissions != previous.permissions
    }
}

// MARK: - Memory Management

extension AppState {
    /// Clean up resources when app goes to background
    func cleanupForBackground() {
        // Clear sensitive data
        permissions = Permissions()
        
        // Reset navigation state to reduce memory footprint
        routing.reset()
    }
    
    /// Optimize state for foreground
    func optimizeForForeground() {
        system.lastActiveTime = Date()
        system.memoryPressureLevel = .normal
    }
}
