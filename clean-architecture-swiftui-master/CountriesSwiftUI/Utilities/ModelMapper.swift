//
//  ModelMapper.swift
//  CountriesSwiftUI
//
//  Utilities for mapping between API and DB models
//

import Foundation

protocol ModelMapper {
    associatedtype Source
    associatedtype Destination
    
    static func map(_ source: Source) -> Destination
}

extension Array {
    func map<Mapper: ModelMapper>(_ mapper: Mapper.Type) -> [Mapper.Destination] where Mapper.Source == Element {
        return self.map { Mapper.map($0) }
    }
}

enum CountryMapper: ModelMapper {
    static func map(_ source: ApiModel.Country) -> DBModel.Country {
        return DBModel.Country(
            name: source.name,
            translations: source.translations,
            population: source.population,
            flag: source.flag,
            alpha3Code: source.alpha3Code
        )
    }
}

enum CurrencyMapper: ModelMapper {
    static func map(_ source: ApiModel.Currency) -> DBModel.Currency {
        return DBModel.Currency(
            code: source.code,
            symbol: source.symbol,
            name: source.name
        )
    }
}
