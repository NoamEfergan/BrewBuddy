import Foundation
import SwiftData
import Models

@Model
final class CoffeeDataModel {
  var name: String
  var roasterName: String
  var brewMethod: BrewMethod
  var price: Double
  
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
