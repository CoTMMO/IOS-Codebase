//
//  View+Extensions.swift
//  CountriesSwiftUI
//
//  Common view extensions and modifiers
//

import SwiftUI

extension View {
    func eraseToAnyView() -> AnyView {
        AnyView(self)
    }
}

struct ConditionalModifier<TrueContent: View, FalseContent: View>: ViewModifier {
    let condition: Bool
    let trueContent: (Self.Content) -> TrueContent
    let falseContent: (Self.Content) -> FalseContent
    
    func body(content: Content) -> some View {
        Group {
            if condition {
                trueContent(content)
            } else {
                falseContent(content)
            }
        }
    }
}

extension View {
    func conditional<TrueContent: View, FalseContent: View>(
        _ condition: Bool,
        ifTrue: @escaping (Self) -> TrueContent,
        ifFalse: @escaping (Self) -> FalseContent
    ) -> some View {
        modifier(ConditionalModifier(
            condition: condition,
            trueContent: ifTrue,
            falseContent: ifFalse
        ))
    }
    
    func conditional<TrueContent: View>(
        _ condition: Bool,
        transform: @escaping (Self) -> TrueContent
    ) -> some View {
        conditional(condition, ifTrue: transform, ifFalse: { $0 })
    }
}

struct SectionHeaderStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.headline)
            .foregroundColor(.secondary)
    }
}

extension View {
    func sectionHeaderStyle() -> some View {
        modifier(SectionHeaderStyle())
    }
}
