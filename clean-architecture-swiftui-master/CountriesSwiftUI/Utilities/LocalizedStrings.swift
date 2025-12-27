//
//  LocalizedStrings.swift
//  CountriesSwiftUI
//
//  Centralized string constants for localization
//

import Foundation

enum LocalizedStrings {
    enum Common {
        static let ok = NSLocalizedString("OK", comment: "")
        static let cancel = NSLocalizedString("Cancel", comment: "")
        static let retry = NSLocalizedString("Retry", comment: "")
        static let error = NSLocalizedString("An Error Occurred", comment: "")
        static let loading = NSLocalizedString("Loading...", comment: "")
    }
    
    enum Countries {
        static let title = NSLocalizedString("Countries", comment: "")
        static let searchPlaceholder = NSLocalizedString("Search countries", comment: "")
        static let noMatches = NSLocalizedString("No matches found", comment: "")
        static let allowPush = NSLocalizedString("Allow Push", comment: "")
        static let cancelLoading = NSLocalizedString("Cancel loading", comment: "")
    }
    
    enum CountryDetails {
        static let basicInfo = NSLocalizedString("Basic Info", comment: "")
        static let code = NSLocalizedString("Code", comment: "")
        static let population = NSLocalizedString("Population", comment: "")
        static let capital = NSLocalizedString("Capital", comment: "")
        static let currencies = NSLocalizedString("Currencies", comment: "")
        static let neighbors = NSLocalizedString("Neighboring countries", comment: "")
    }
    
    enum Errors {
        static let loadImageFailed = NSLocalizedString("Unable to load image", comment: "")
        static let databaseIssue = NSLocalizedString("⚠️ There is an issue with local database", comment: "")
    }
}
