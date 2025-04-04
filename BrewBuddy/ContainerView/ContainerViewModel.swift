import Foundation
import Models
import SwiftData

@Observable
final class ContainerViewModel {
    public var selectedTab: Tabs = .addCoffee
    public var isShowingSuccessToast = false
    public var isShowingDeleteToast = false
    public var isShowingSuccessAddShotToast = false
}

enum Tabs {
    case addCoffee
    case coffeeList
    case addShot
}
