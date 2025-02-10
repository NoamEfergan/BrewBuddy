//
//  WiggleModifier.swift
//  BrewBuddyKit
//
//  Created by Noam Efergan on 14/01/2025.
//
import SwiftUI

// MARK: - WiggleModifier

public struct WiggleModifier: ViewModifier {
    public let isAnimating: Bool

    public init(isAnimating: Bool) {
        self.isAnimating = isAnimating
    }

    public func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(isAnimating ? 2 : 0))
            .animation(isAnimating ?
                .easeInOut(duration: 0.1)
                .repeatCount(3, autoreverses: true) :
                .default,
                value: isAnimating)
    }
}
