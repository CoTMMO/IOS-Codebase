//
//  ImageView.swift
//  CountriesSwiftUI
//
//  Created by Alexey Naumov on 25.10.2019.
//  Copyright © 2019 Alexey Naumov. All rights reserved.
//

import SwiftUI
import Combine

struct ImageView: View {
    
    private let imageURL: URL
    @Environment(\.injected) var injected: DIContainer
    @State private var image: Loadable<UIImage>
    let inspection = Inspection<Self>()
    
    init(imageURL: URL, image: Loadable<UIImage> = .notRequested) {
        self.imageURL = imageURL
        self._image = .init(initialValue: image)
    }
    
    var body: some View {
        content
            .onReceive(inspection.notice) { self.inspection.visit(self, $0) }
    }
    
    @ViewBuilder private var content: some View {
        LoadableView(
            loadable: image,
            content: loadedView,
            onAppear: loadImage
        )
    }
}

// MARK: - Side Effects

private extension ImageView {
    func loadImage() {
        injected.interactors.images
            .load(image: $image, url: imageURL)
    }
}

// MARK: - Content

private extension ImageView {
    func loadedView(_ uiImage: UIImage) -> some View {
        Image(uiImage: uiImage)
            .resizable()
            .aspectRatio(contentMode: .fit)
    }
}

#Preview {
    VStack {
        ImageView(imageURL: URL(string: "https://flagcdn.com/w640/us.jpg")!)
        ImageView(imageURL: URL(string: "https://flagcdn.com/w640/al.jpg")!)
        ImageView(imageURL: URL(string: "https://flagcdn.com/w640/ru.jpg")!)
    }
}
