//
//  ShotsScreen.swift
//  BrewBuddyKit
//
//  Created by Noam Efergan on 16/01/2025.
//

import CoffeeTheme
import CommonUI
import Models
import SwiftData
import SwiftUI

public struct ShotsScreen: View {
    @State private var viewModel = ShotScreenViewModel()
    @State private var isAnimating = false
    @State private var validationError: ShotScreenViewModel.ShotValidationError? = nil
    @Query(sort: [SortDescriptor(\CoffeeDataModel.name, comparator: .localizedStandard)])
    private var coffees: [CoffeeDataModel]
    @State private var selectedCoffee: CoffeeDataModel?
    private let onNavigateToAdd: (() -> Void)?
    private let onSuccessfulAdd: (() -> Void)?

    public init(onNavigateToAdd: (() -> Void)? = nil, onSuccessfulAdd: (() -> Void)? = nil) {
        self.onNavigateToAdd = onNavigateToAdd
        self.onSuccessfulAdd = onSuccessfulAdd
    }

    public var body: some View {
        Group {
            if coffees.isEmpty {
                EmptyStatePopToAddView(onNavigateToAdd: onNavigateToAdd)
            } else {
                VStack(spacing: 0) {
                    Form {
                        Section {
                            Menu(selectedCoffee?.name ?? "Select a coffee") {
                                ForEach(coffees) { coffee in
                                    Button(coffee.name) {
                                        selectedCoffee = coffee
                                    }
                                }
                            }
                        }
                        Section {
                            Picker("Brew method", selection: $viewModel.brewMethod) {
                                ForEach(BrewMethod.allCases, id: \.self) { method in
                                    Text(method.rawValue)
                                        .tag(method)
                                }
                            }
                            HStack {
                                HStack {
                                    TextField("Grams in", text: $viewModel.gramsIn)
                                    Text("g")
                                }

                                HStack {
                                    TextField("Grams out", text: $viewModel.gramsOut)
                                    Text("g")
                                }
                            }
                            .keyboardType(.decimalPad)
                            HStack {
                                TextField("Time (seconds)", text: $viewModel.time)
                                Text("s")
                            }
                            RatingView(rating: $viewModel.rating)
                        }
                        .textFieldStyle(.roundedBorder)
                        Section("notes") {
                            TextField("", text: $viewModel.notes, axis: .vertical)
                                .lineLimit(5, reservesSpace: true)
                            // TODO: Add a photo here
                        }
                        Section {
                            Button("Save") {
                                do {
                                    guard let selectedCoffee else {
                                        validationError = ShotScreenViewModel.ShotValidationError.noCoffeeSelected
                                        return
                                    }
                                    let model = try viewModel.save()
                                    validationError = nil
                                    selectedCoffee.shots.append(model)
                                    onSuccessfulAdd?()
                                } catch {
                                    validationError = error as? ShotScreenViewModel.ShotValidationError
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .tint(CoffeeTheme.AccentColor.highlight)
                            .modifier(WiggleModifier(isAnimating: isAnimating))
                        } footer: {
                            if let error = validationError {
                                Text(error.localizedDescription)
                                    .foregroundColor(CoffeeTheme.AccentColor.primary)
                            }
                        }
                    }
                }
            }
        }
        .foregroundStyle(CoffeeTheme.AccentColor.text)
        .scrollContentBackground(.hidden)
        .background(CoffeeTheme.AccentColor.background)
        .navigationTitle("Log a shot")
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: CoffeeDataModel.self, configurations: config)
    for coffee in [CoffeeDataModel].mockCoffees {
        container.mainContext.insert(coffee)
    }

    return ShotsScreen()
        .modelContainer(container)
}

#Preview("No coffees") {
    ShotsScreen()
}
