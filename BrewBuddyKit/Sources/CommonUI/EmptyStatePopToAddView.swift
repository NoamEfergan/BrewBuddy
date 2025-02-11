//
//  EmptyStatePopToAddView.swift
//  BrewBuddyKit
//
//  Created by Noam Efergan on 11/02/2025.
//

import CoffeeTheme
import SwiftUI

public struct EmptyStatePopToAddView: View {
    private let onNavigateToAdd: (() -> Void)?

    public init(onNavigateToAdd: (() -> Void)? = nil) {
        self.onNavigateToAdd = onNavigateToAdd
    }

    public var body: some View {
        VStack {
            Text("No coffees yet! add some ")
                .font(.title)
                .bold()
                .fontDesign(.rounded)
            Button("Pop to add") {
                onNavigateToAdd?()
            }
            .buttonStyle(.borderedProminent)
            .tint(CoffeeTheme.AccentColor.highlight)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    EmptyStatePopToAddView()
}
