//
//  ShotsScreen.swift
//  BrewBuddyKit
//
//  Created by Noam Efergan on 16/01/2025.
//

import CoffeeTheme
import CommonUI
import Models
import SwiftUI

public struct ShotsScreen: View {
    let title: String
    @State private var viewModel = ShotScreenViewModel()
    public var body: some View {
        VStack(spacing: 0) {
            Text(title)
                .font(.title)
                .fontDesign(.rounded)
                .bold()
            Form {
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
            }
        }
        .foregroundStyle(CoffeeTheme.AccentColor.text)
        .scrollContentBackground(.hidden)
        .background(CoffeeTheme.AccentColor.background)
        .navigationTitle("Log a shot")
    }
}

#Preview {
    ShotsScreen(title: "Some Coffee Name")
}
