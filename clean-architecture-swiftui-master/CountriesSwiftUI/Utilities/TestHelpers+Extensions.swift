//
//  TestHelpers+Extensions.swift
//  CountriesSwiftUI
//
//  Additional test helper utilities
//

import Foundation
import SwiftUI

#if DEBUG
extension Loadable {
    static func mock(value: T) -> Loadable<T> {
        return .loaded(value)
    }
    
    static var mockLoading: Loadable<T> {
        return .isLoading(last: nil, cancelBag: CancelBag(equalToAny: true))
    }
    
    static func mockError(_ message: String = "Mock error") -> Loadable<T> {
        return .failed(NSError(domain: "MockError", code: -1, userInfo: [
            NSLocalizedDescriptionKey: message
        ]))
    }
}

extension Store {
    static func mock(_ initialValue: Output) -> Store<Output> {
        return Store(initialValue)
    }
}

extension DIContainer {
    static var preview: DIContainer {
        DIContainer(appState: AppState(), interactors: .stub)
    }
}
#endif
