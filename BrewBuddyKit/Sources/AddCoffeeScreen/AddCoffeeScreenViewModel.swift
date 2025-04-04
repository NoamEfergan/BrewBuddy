//
//  AddCoffeeScreenViewModel.swift
//  BrewBuddyKit
//
//  Created by Noam Efergan on 14/01/2025.
//

import Foundation
import Models

// MARK: - AddCoffeeScreenViewModel

@Observable
class AddCoffeeScreenViewModel {
    var name: String = ""
    var roasterName: String = ""
    var price: String = ""
    var origin: String = ""
    var rating: Int = 6

    func onClickSave() throws(CoffeeValidationError) -> CoffeeModel {
        guard !name.isEmpty else {
            throw CoffeeValidationError.nameEmpty
        }
        guard !roasterName.isEmpty else {
            throw CoffeeValidationError.roasterNameEmpty
        }
        guard !price.isEmpty else {
            throw CoffeeValidationError.priceEmpty
        }
        guard let priceInDouble = Double(price) else {
            throw CoffeeValidationError.priceInvalid
        }
        let model = CoffeeModel(name: name,
                                roasterName: roasterName,
                                price: priceInDouble,
                                origin: origin.isEmpty ? "Unknown origin" : origin,
                                rating: rating)
        wipeData()
        return model
    }

    private func wipeData() {
        name = ""
        roasterName = ""
        price = ""
        origin = ""
        rating = 6
    }
}

// MARK: - CoffeeValidationError

enum CoffeeValidationError: Error {
    case nameEmpty
    case roasterNameEmpty
    case priceEmpty
    case priceInvalid

    var localizedDescription: String {
        return switch self {
        case .nameEmpty:
            "Name cannot be empty"
        case .roasterNameEmpty:
            "Roaster name cannot be empty"
        case .priceEmpty:
            "Price cannot be empty"
        case .priceInvalid:
            "Price must be a valid number"
        }
    }
}
