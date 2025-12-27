//
//  AppConfiguration.swift
//  CountriesSwiftUI
//
//  Centralized configuration for the application with performance optimizations
//

import Foundation

enum AppConfiguration {
    
    enum API {
        static let baseURL = "https://restcountries.com/v2"
        static let flagBaseURL = "https://flagcdn.com/w640"
        static let acceptHeader = "application/json"
        
        enum Timeout {
            static let request: TimeInterval = 60
            static let resource: TimeInterval = 120
        }
        
        enum Fields {
            static let countryList = "name,translations,population,flag,alpha3Code"
        }
    }
    
    enum Network {
        static let maxConnectionsPerHost = 5
        static let cachePolicy: URLRequest.CachePolicy = .returnCacheDataElseLoad
        
        // Performance optimizations
        static let requestTimeout: TimeInterval = 30.0
        static let resourceTimeout: TimeInterval = 60.0
        static let allowsCellularAccess = true
        static let waitsForConnectivity = true
    }
    
    enum Database {
        static let defaultName = "CountriesApp"
        static let stubName = "stub"
        
        // Performance optimizations
        static let prefetchDistance = 20
        static let batchSize = 50
    }
    
    enum Memory {
        static let maxImageCacheSize = 50 * 1024 * 1024 // 50MB
        static let maxConcurrentOperations = 3
        static let cleanupInterval: TimeInterval = 300 // 5 minutes
    }
    
    enum UI {
        static let debounceInterval: TimeInterval = 0.3
        static let animationDuration: TimeInterval = 0.25
        static let listPreloadDistance = 10
    }
}
