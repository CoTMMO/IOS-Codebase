//
//  Repository.swift
//  CountriesSwiftUI
//
//  Base protocols for repositories
//

import Foundation

protocol Repository {
}

protocol ReadRepository: Repository {
    associatedtype Entity
    associatedtype Identifier
    
    func fetch(id: Identifier) async throws -> Entity?
    func fetchAll() async throws -> [Entity]
}

protocol WriteRepository: Repository {
    associatedtype Entity
    
    func save(_ entity: Entity) async throws
    func save(_ entities: [Entity]) async throws
    func delete(_ entity: Entity) async throws
}

protocol CRUDRepository: ReadRepository, WriteRepository {
}

protocol CacheableRepository: Repository {
    var cachePolicy: CachePolicy { get }
}

enum CachePolicy {
    case cacheFirst
    case networkFirst
    case cacheOnly
    case networkOnly
    case cacheAndNetwork
}
