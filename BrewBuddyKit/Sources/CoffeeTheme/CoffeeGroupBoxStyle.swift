//
//  CoffeeGroupBoxStyle.swift
//  BrewBuddyKit
//
//  Created by Noam Efergan on 16/01/2025.
//

import SwiftUI

public struct CoffeeGroupBoxStyle: GroupBoxStyle {
    public init() {}
    public func makeBody(configuration: Configuration) -> some View {
        configuration.content
            .padding()
            .background(CoffeeTheme.AccentColor.highlight)
            .cornerRadius(8)
            .foregroundStyle(CoffeeTheme.AccentColor.text)
    }
}
