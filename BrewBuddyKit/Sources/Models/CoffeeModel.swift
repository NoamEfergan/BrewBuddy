import Foundation

public struct CoffeeModel {
    public let name: String
    public let roasterName: String
    public let brewMethod: BrewMethod
    public let price: Double
    public let origin: String
    public let rating: Int

    public init(name: String,
                roasterName: String,
                brewMethod: BrewMethod,
                price: Double,
                origin: String,
                rating: Int)
    {
        self.name = name
        self.roasterName = roasterName
        self.brewMethod = brewMethod
        self.price = price
        self.origin = origin
        self.rating = rating
    }

    public init(dataModel: CoffeeDataModel) {
        name = dataModel.name
        roasterName = dataModel.roasterName
        brewMethod = dataModel.brewMethod
        price = dataModel.price
        origin = dataModel.origin
        rating = dataModel.rating
    }
}
