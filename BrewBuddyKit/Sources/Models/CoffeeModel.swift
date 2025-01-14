import Foundation

public struct CoffeeModel {
  public let name: String
  public let roasterName: String
  public let roastDate: Date
  public let brewMethod: BrewMethod
  public let price: Double

  public init(name: String,
              roasterName: String,
              roastDate: Date,
              brewMethod: BrewMethod,
              price: Double) {
    self.name = name
    self.roasterName = roasterName
    self.roastDate = roastDate
    self.brewMethod = brewMethod
    self.price = price
  }
}
