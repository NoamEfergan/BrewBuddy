import Foundation
import Models
import SwiftData

@Observable
final class ContainerViewModel {
  public var selectedTab: Tabs = .addCoffee
}

enum Tabs {
  case addCoffee
}
