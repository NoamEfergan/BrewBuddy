//
//  ContainerView.swift
//  BrewBuddy
//
//  Created by Noam Efergan on 14/01/2025.
//

import AddCoffeeScreen
import Models
import SwiftUI
import CoffeeTheme

struct ContainerView: View {
  @State private var viewModel = ContainerViewModel()
  @Environment(\.modelContext) private var modelContext
  var body: some View {
    TabView(selection: $viewModel.selectedTab) {
      Tab("Add Coffee", systemImage: "cup.and.heat.waves.fill", value: .addCoffee) {
        AddCoffeeScreen(didSaveCoffee: handleAddCoffee)
      }
    }
    .tint(CoffeeTheme.AccentColor.text)
  }

  private func handleAddCoffee(_ coffeeModel: CoffeeModel) {
    let persistenceModel = CoffeeDataModel(name: coffeeModel.name,
                                           roasterName: coffeeModel.roasterName,
                                           brewMethod: coffeeModel.brewMethod,
                                           price: coffeeModel.price)
    modelContext.insert(persistenceModel)
  }
}

#Preview {
  ContainerView()
}
