//
//  NavigationState.swift
//  CountriesSwiftUI
//
//  Type-safe navigation state management
//

import SwiftUI

protocol RoutingState: Equatable {
    init()
}

extension View {
    func syncRouting<State: RoutingState>(
        _ localState: Binding<State>,
        with globalState: Store<AppState>,
        keyPath: WritableKeyPath<AppState, State>
    ) -> some View {
        self
            .onReceive(globalState.updates(for: keyPath)) { state in
                localState.wrappedValue = state
            }
    }
}

extension Binding where Value: Equatable {
    func syncedToGlobal<State>(
        _ state: Store<State>,
        _ keyPath: WritableKeyPath<State, Value>
    ) -> Self {
        return dispatched(to: state, keyPath)
    }
}
