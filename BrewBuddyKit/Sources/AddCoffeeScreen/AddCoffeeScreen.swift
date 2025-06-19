//
//  AddCoffeeScreen.swift
//  BrewBuddyKit
//
//  Created by Noam Efergan on 14/01/2025.
//

import CoffeeTheme
import CommonUI
import Models
import SwiftUI

// MARK: - AddCoffeeScreen

public struct AddCoffeeScreen: View {
    @State private var viewModel = AddCoffeeScreenViewModel()
    @State private var validationError: CoffeeValidationError? = nil
    @State private var isAnimating = false
    public var didSaveCoffee: ((CoffeeModel) -> Void)?

    public init(didSaveCoffee: ((CoffeeModel) -> Void)? = nil) {
        self.didSaveCoffee = didSaveCoffee
    }

    public var body: some View {
        Form {
            Section("Coffee Details") {
                TextField("Name", text: $viewModel.name)
                TextField("Roaster Name", text: $viewModel.roasterName)
                TextField("Price", text: $viewModel.price)
                    .keyboardType(.decimalPad)
                TextField("Origin", text: $viewModel.origin)
            }
            Section("Actions") {
                HStack {
                    Button("Save") {
                        do {
                            let model = try viewModel.onClickSave()
                            didSaveCoffee?(model)
                            validationError = nil
                        } catch {
                            validationError = error as? CoffeeValidationError
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .tint(CoffeeTheme.AccentColor.highlight)
                    .modifier(WiggleModifier(isAnimating: isAnimating))
                }
            } footer: {
                if let error = validationError {
                    Text(error.localizedDescription)
                        .foregroundColor(CoffeeTheme.AccentColor.primary)
                }
            }
        }
        .animation(.bouncy, value: validationError)
        .onChange(of: validationError) { _, newValue in
            if newValue != nil {
                isAnimating = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    isAnimating = false
                }
            }
        }
        .foregroundStyle(CoffeeTheme.AccentColor.text)
        .scrollContentBackground(.hidden)
        .background(CoffeeTheme.AccentColor.background)
        .navigationTitle("Add Coffee")
    }
}

#Preview {
    NavigationView {
        AddCoffeeScreen()
    }
}
