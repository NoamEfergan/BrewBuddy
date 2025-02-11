//
//  ContainerView.swift
//  BrewBuddy
//
//  Created by Noam Efergan on 14/01/2025.
//

import AddCoffeeScreen
import AlertToast
import CoffeeListScreen
import CoffeeTheme
import Models
import ShotsScreen
import SwiftData
import SwiftUI

// MARK: - ContainerView

struct ContainerView: View {
    @State private var viewModel = ContainerViewModel()
    @Environment(\.modelContext) private var modelContext
    var body: some View {
        TabView(selection: $viewModel.selectedTab) {
            Tab("Add Coffee", systemImage: "cup.and.heat.waves.fill", value: .addCoffee) {
                AddCoffeeScreen(didSaveCoffee: handleAddCoffee)
            }
            Tab("Coffee list", systemImage: "list.bullet", value: .coffeeList) {
                CoffeeListScreen {
                    viewModel.isShowingDeleteToast = true
                } onNavigateToAdd: {
                    viewModel.selectedTab = .addCoffee
                }
            }
            Tab("Log a shot", systemImage: "plus.circle", value: .addShot) {
                ShotsScreen {
                    viewModel.selectedTab = .addCoffee
                } onSuccessfulAdd: {
                    viewModel.isShowingSuccessAddShotToast = true
                }
            }
        }
        .tint(CoffeeTheme.AccentColor.text)
        .toast(isPresenting: $viewModel.isShowingSuccessToast) {
            AlertToast(displayMode: .hud, type: .complete(.green), title: "Successfully added coffee")
        }
        .toast(isPresenting: $viewModel.isShowingDeleteToast) {
            AlertToast(displayMode: .hud, type: .regular, title: "Successfully deleted coffee")
        }
        .toast(isPresenting: $viewModel.isShowingSuccessAddShotToast, duration: 3) {
            AlertToast(displayMode: .hud, type: .complete(.green), title: "Successfully logged a shot")
        }
    }

    private func handleAddCoffee(_ coffeeModel: CoffeeModel) {
        modelContext.insert(CoffeeDataModel(coffeeModel: coffeeModel))
        viewModel.isShowingSuccessToast = true
    }
}

#Preview("Loaded state") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: CoffeeDataModel.self, configurations: config)
    for coffee in [CoffeeDataModel].mockCoffees {
        container.mainContext.insert(coffee)
    }

    return NavigationView { ContainerView() }
        .modelContainer(container)
}

#Preview("Empty state") {
    ContainerView()
}
