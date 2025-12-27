//
//  CountriesDBRepository.swift
//  CountriesSwiftUI
//
//  Created by Alexey on 7/11/24.
//  Copyright © 2024 Alexey Naumov. All rights reserved.
//

import SwiftData
import Foundation

protocol CountriesDBRepository {
    @MainActor
    func countryDetails(for country: DBModel.Country) async throws -> DBModel.CountryDetails?
    func store(countries: [ApiModel.Country]) async throws
    func store(countryDetails: ApiModel.CountryDetails, for country: DBModel.Country) async throws
}

extension MainDBRepository: CountriesDBRepository {

    @MainActor
    func countryDetails(for country: DBModel.Country) async throws -> DBModel.CountryDetails? {
        let alpha3Code = country.alpha3Code
        let fetchDescriptor = FetchDescriptor(predicate: #Predicate<DBModel.CountryDetails> {
            $0.alpha3Code == alpha3Code
        })
        return try modelContainer.mainContext.fetch(fetchDescriptor).first
    }

    func store(countries: [ApiModel.Country]) async throws {
        try modelContext.transaction {
            countries
                .map(CountryMapper.map)
                .forEach(modelContext.insert)
        }
    }

    func store(countryDetails: ApiModel.CountryDetails, for country: DBModel.Country) async throws {
        let alpha3Code = country.alpha3Code
        try modelContext.transaction {
            let currencies = countryDetails.currencies.map(CurrencyMapper.map)
            let neighborsFetch = FetchDescriptor(predicate: #Predicate<DBModel.Country> { countryDBModel in
                countryDetails.borders?.contains(countryDBModel.alpha3Code) == true
            })
            let neighbors = try modelContext.fetch(neighborsFetch)
            currencies.forEach(modelContext.insert)
            let object = DBModel.CountryDetails(
                alpha3Code: alpha3Code,
                capital: countryDetails.capital,
                currencies: currencies,
                neighbors: neighbors)
            modelContext.insert(object)
        }
    }
}

