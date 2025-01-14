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
import SwiftUI

struct ContainerView: View {
  @State private var viewModel = ContainerViewModel()
  @Environment(\.modelContext) private var modelContext
  var body: some View {
    TabView(selection: $viewModel.selectedTab) {
      Tab("Add Coffee", systemImage: "cup.and.heat.waves.fill", value: .addCoffee) {
        AddCoffeeScreen(didSaveCoffee: handleAddCoffee)
      }
      Tab("Coffee list", systemImage: "list.bullet", value: .coffeeList) {
        CoffeeListScreen()
      }
    }
    .tint(CoffeeTheme.AccentColor.text)
    .toast(isPresenting: $viewModel.isShowingToast) {
      AlertToast(displayMode: .hud, type: .complete(.green), title: "Successfully added coffee")
    }
  }

  private func handleAddCoffee(_ coffeeModel: CoffeeModel) {
    modelContext.insert(CoffeeDataModel(coffeeModel: coffeeModel))
    viewModel.isShowingToast = true
  }
}

#Preview {
  ContainerView()
}
