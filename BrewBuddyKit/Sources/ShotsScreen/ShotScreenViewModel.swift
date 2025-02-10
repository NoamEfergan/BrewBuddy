import Foundation
import Models

@Observable
final class ShotScreenViewModel {
    var brewMethod: BrewMethod = .espresso
    var gramsIn: String = ""
    var gramsOut: String = ""
    var time: String = ""
    var rating: Int = 1
    var notes: String = ""
    var createdAt: Date = .init()
}
