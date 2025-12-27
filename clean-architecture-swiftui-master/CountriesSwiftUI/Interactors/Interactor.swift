//
//  Interactor.swift
//  CountriesSwiftUI
//
//  Base protocols for interactors
//

import Foundation

protocol Interactor {
}

protocol AsyncInteractor: Interactor {
    associatedtype Input
    associatedtype Output
    
    func execute(_ input: Input) async throws -> Output
}

protocol VoidInputInteractor: Interactor {
    associatedtype Output
    
    func execute() async throws -> Output
}

protocol VoidOutputInteractor: Interactor {
    associatedtype Input
    
    func execute(_ input: Input) async throws
}

protocol SimpleInteractor: Interactor {
    func execute() async throws
}
