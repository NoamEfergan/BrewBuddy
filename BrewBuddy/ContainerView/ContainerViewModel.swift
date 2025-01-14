import Foundation
import Models
import SwiftData

@Observable
final class ContainerViewModel {
  public var selectedTab: Tabs = .addCoffee
  public var isShowingToast = false
}

enum Tabs {
  case addCoffee
  case coffeeList
}
