//
//  AppConfiguration.swift
//  CountriesSwiftUI
//
//  Centralized configuration for the application
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
    }
    
    enum Database {
        static let defaultName = "CountriesApp"
        static let stubName = "stub"
    }
}
