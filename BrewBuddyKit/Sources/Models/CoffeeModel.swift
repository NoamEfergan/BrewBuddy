import Foundation

public struct CoffeeModel {
  public let name: String
  public let roasterName: String
  public let brewMethod: BrewMethod
  public let price: Double

  public init(name: String,
              roasterName: String,
              brewMethod: BrewMethod,
              price: Double) {
    self.name = name
    self.roasterName = roasterName
    self.brewMethod = brewMethod
    self.price = price
  }
}
