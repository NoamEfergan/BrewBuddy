import Foundation
import SwiftData

@Model
public final class ShotDataModel {
    @Attribute(.unique)
    public var id: String
    public var brewMethod: BrewMethod
    public var gramsIn: Double
    public var gramsOut: Double
    public var time: Double
    public var rating: Int
    public var notes: String
    public var createdAt: Date

    @Relationship
    public var coffee: CoffeeDataModel?

    public init(
        id: String = UUID().uuidString,
        brewMethod: BrewMethod,
        gramsIn: Double,
        gramsOut: Double,
        time: Double,
        rating: Int,
        notes: String,
        createdAt: Date
    ) {
        self.id = id
        self.brewMethod = brewMethod
        self.gramsIn = gramsIn
        self.gramsOut = gramsOut
        self.time = time
        self.rating = rating
        self.notes = notes
        self.createdAt = createdAt
    }

    public static var mock: Self {
        .init(
            brewMethod: .espresso,
            gramsIn: 18,
            gramsOut: 36,
            time: 30,
            rating: 4,
            notes: "This was a good shot",
            createdAt: .now
        )
    }
}
