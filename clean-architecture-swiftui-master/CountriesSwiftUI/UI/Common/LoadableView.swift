//
//  LoadableView.swift
//  CountriesSwiftUI
//
//  Reusable view for displaying loadable content states
//

import SwiftUI

struct LoadableView<Content: View, Value>: View {
    let loadable: Loadable<Value>
    let content: (Value) -> Content
    let retryAction: (() -> Void)?
    let onAppear: (() -> Void)?
    
    init(
        loadable: Loadable<Value>,
        @ViewBuilder content: @escaping (Value) -> Content,
        retryAction: (() -> Void)? = nil,
        onAppear: (() -> Void)? = nil
    ) {
        self.loadable = loadable
        self.content = content
        self.retryAction = retryAction
        self.onAppear = onAppear
    }
    
    var body: some View {
        switch loadable {
        case .notRequested:
            defaultView
        case .isLoading:
            loadingView
        case .loaded(let value):
            content(value)
        case .failed(let error):
            failedView(error)
        }
    }
    
    @ViewBuilder
    private var defaultView: some View {
        Text("")
            .onAppear {
                onAppear?()
            }
    }
    
    @ViewBuilder
    private var loadingView: some View {
        ProgressView()
            .progressViewStyle(CircularProgressViewStyle())
    }
    
    @ViewBuilder
    private func failedView(_ error: Error) -> some View {
        if let retry = retryAction {
            ErrorView(error: error, retryAction: retry)
        } else {
            VStack {
                Text("An Error Occurred")
                    .font(.title)
                Text(error.localizedDescription)
                    .font(.callout)
                    .multilineTextAlignment(.center)
                    .padding()
            }
        }
    }
}

struct CancellableLoadableView<Content: View, Value>: View {
    let loadable: Loadable<Value>
    let content: (Value) -> Content
    let retryAction: () -> Void
    let cancelAction: () -> Void
    let onAppear: (() -> Void)?
    
    init(
        loadable: Loadable<Value>,
        @ViewBuilder content: @escaping (Value) -> Content,
        retryAction: @escaping () -> Void,
        cancelAction: @escaping () -> Void,
        onAppear: (() -> Void)? = nil
    ) {
        self.loadable = loadable
        self.content = content
        self.retryAction = retryAction
        self.cancelAction = cancelAction
        self.onAppear = onAppear
    }
    
    var body: some View {
        switch loadable {
        case .notRequested:
            defaultView
        case .isLoading:
            loadingView
        case .loaded(let value):
            content(value)
        case .failed(let error):
            ErrorView(error: error, retryAction: retryAction)
        }
    }
    
    @ViewBuilder
    private var defaultView: some View {
        Text("")
            .onAppear {
                onAppear?()
            }
    }
    
    @ViewBuilder
    private var loadingView: some View {
        VStack {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
            Button(action: cancelAction) {
                Text("Cancel loading")
            }
        }
    }
}
