//
//  CoffeeDetailScreen.swift
//  BrewBuddyKit
//
//  Created by Noam Efergan on 14/01/2025.
//

import CoffeeTheme
import Models
import SwiftData
import SwiftUI

struct CoffeeDetailScreen: View {
  @Bindable var coffee: CoffeeDataModel
  @State private var rating = 0
  var body: some View {
    Form {
      Section("info") {
        LabeledContent("Roaster", value: coffee.roasterName)
        LabeledContent("Origin", value: coffee.origin)
        LabeledContent("Brew method", value: coffee.brewMethod.rawValue)
        LabeledContent("Price",
                       value: coffee.price.formatted(.currency(code: Locale.current.currency?.identifier ?? "GBP")))
      }

      Section("score") {
        RatingView(rating: $rating)
          .frame(maxWidth: .infinity)
      }
    }
    .scrollContentBackground(.hidden)
    .background(CoffeeTheme.AccentColor.background)
    .navigationTitle(coffee.name)
    .task {
      if coffee.rating > 5 {
        rating = 0
      } else {
        rating = coffee.rating
      }
    }
    .onChange(of: rating) { oldValue, newValue in
      coffee.rating = newValue
    }
  }
}

#Preview {
  let config = ModelConfiguration(isStoredInMemoryOnly: true)
  let container = try! ModelContainer(for: CoffeeDataModel.self, configurations: config)
  for coffee in [CoffeeDataModel].mockCoffees {
    container.mainContext.insert(coffee)
  }

  return NavigationView { CoffeeDetailScreen(coffee: [CoffeeDataModel].mockCoffees.last!) }
    .modelContainer(container)
}
