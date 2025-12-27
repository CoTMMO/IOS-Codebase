//
//  ModelContainer.swift
//  CountriesSwiftUI
//
//  Created by Alexey on 7/11/24.
//  Copyright © 2024 Alexey Naumov. All rights reserved.
//

import SwiftData

extension ModelContainer {

    static func appModelContainer(
        inMemoryOnly: Bool = false, isStub: Bool = false
    ) throws -> ModelContainer {
        let schema = Schema.appSchema
        let configName = isStub ? AppConfiguration.Database.stubName : AppConfiguration.Database.defaultName
        let modelConfiguration = ModelConfiguration(
            configName,
            schema: schema,
            isStoredInMemoryOnly: inMemoryOnly
        )
        return try ModelContainer(for: schema, configurations: [modelConfiguration])
    }

    static var stub: ModelContainer {
        try! appModelContainer(inMemoryOnly: true, isStub: true)
    }

    var isStub: Bool {
        return configurations.first?.name == AppConfiguration.Database.stubName
    }
}

@ModelActor
final actor MainDBRepository { }
