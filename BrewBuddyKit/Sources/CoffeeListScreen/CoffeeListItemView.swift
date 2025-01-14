//
//  CoffeeListItemView.swift
//  BrewBuddyKit
//
//  Created by Noam Efergan on 14/01/2025.
//

import CoffeeTheme
import Models
import SwiftUI

struct CoffeeListItemView: View {
  let name: String
  let roasterName: String
  let score: Int
  
  private var formattedScore: String {
    score > 5 ? "Not rated" : "\(score)/5"
  }
  var body: some View {
    VStack(alignment: .leading) {
      Text(name)
        .font(.title3)
        .bold()
        .foregroundStyle(CoffeeTheme.AccentColor.text)
      HStack {
        Text(roasterName)
          .font(.subheadline)
        Spacer()
        Text(formattedScore)
          .font(.caption)
      }
      .foregroundStyle(CoffeeTheme.AccentColor.text.secondary)
    }
    .fontDesign(.rounded)
    .padding()
  }
}

#Preview {
  let coffee = [CoffeeDataModel].mockCoffees.first!
  return CoffeeListItemView(name: coffee.name, roasterName: coffee.roasterName, score: coffee.rating)
}
