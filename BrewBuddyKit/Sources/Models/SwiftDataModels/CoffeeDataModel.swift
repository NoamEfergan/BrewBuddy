import Foundation
import SwiftData

// MARK: - CoffeeDataModel

@Model
public final class CoffeeDataModel {
    @Attribute(.unique)
    public var id: String
    public var name: String
    public var roasterName: String
    public var price: Double
    public var origin: String
    public var rating: Int

    public init(id: String = UUID().uuidString,
                name: String,
                roasterName: String,
                price: Double,
                origin: String,
                rating: Int)
    {
        self.id = id
        self.name = name
        self.roasterName = roasterName
        self.price = price
        self.origin = origin
        self.rating = rating
    }

    public init(coffeeModel: CoffeeModel) {
        id = UUID().uuidString
        name = coffeeModel.name
        roasterName = coffeeModel.roasterName
        price = coffeeModel.price
        origin = coffeeModel.origin
        rating = coffeeModel.rating
    }
}

public extension [CoffeeDataModel] {
    static var mockCoffees: [CoffeeDataModel] {
        [
            CoffeeDataModel(name: "Ethiopian Yirgacheffe",
                            roasterName: "Blue Bottle Coffee",
                            price: 18.99,
                            origin: "Ethiopia",
                            rating: 6),
            CoffeeDataModel(name: "Colombian Supremo",
                            roasterName: "Stumptown Coffee Roasters",
                            price: 16.50,
                            origin: "Colombia",
                            rating: 4),
            CoffeeDataModel(name: "Sumatra Mandheling",
                            roasterName: "Intelligentsia Coffee",
                            price: 19.99,
                            origin: "Sumatra",
                            rating: 4),
            CoffeeDataModel(name: "Kenya AA",
                            roasterName: "Counter Culture Coffee",
                            price: 21.00,
                            origin: "Kenya",
                            rating: 5),
            CoffeeDataModel(name: "Guatemala Antigua",
                            roasterName: "Verve Coffee Roasters",
                            price: 17.50,
                            origin: "Guatemala",
                            rating: 4),
            CoffeeDataModel(name: "Costa Rica Tarrazu",
                            roasterName: "Heart Coffee Roasters",
                            price: 20.00,
                            origin: "Costa Rica",
                            rating: 5),
            CoffeeDataModel(name: "Brazil Santos",
                            roasterName: "Ritual Coffee Roasters",
                            price: 15.99,
                            origin: "Brazil",
                            rating: 3),
            CoffeeDataModel(name: "Mexico Chiapas",
                            roasterName: "Four Barrel Coffee",
                            price: 16.99,
                            origin: "Mexico",
                            rating: 4),
            CoffeeDataModel(name: "Honduras SHG",
                            roasterName: "Sightglass Coffee",
                            price: 18.50,
                            origin: "Honduras",
                            rating: 4),
            CoffeeDataModel(name: "Rwanda Nyungwe",
                            roasterName: "Equator Coffees",
                            price: 22.00,
                            origin: "Rwanda",
                            rating: 5),
        ]
    }
}
