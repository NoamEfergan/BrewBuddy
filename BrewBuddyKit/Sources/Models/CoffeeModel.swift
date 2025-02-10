import Foundation

public struct CoffeeModel {
    public let name: String
    public let roasterName: String
    public let price: Double
    public let origin: String
    public let rating: Int

    public init(name: String,
                roasterName: String,
                price: Double,
                origin: String,
                rating: Int)
    {
        self.name = name
        self.roasterName = roasterName
        self.price = price
        self.origin = origin
        self.rating = rating
    }

    public init(dataModel: CoffeeDataModel) {
        name = dataModel.name
        roasterName = dataModel.roasterName
        price = dataModel.price
        origin = dataModel.origin
        rating = dataModel.rating
    }
}
