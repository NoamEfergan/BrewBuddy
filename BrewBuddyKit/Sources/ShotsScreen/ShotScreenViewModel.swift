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

    func save() throws(ShotValidationError) -> ShotDataModel {
        guard let gramsInDouble = validateStringToDoubleValue(value: gramsIn) else {
            throw ShotValidationError.gramsInInvalid
        }
        guard let gramsOutDouble = validateStringToDoubleValue(value: gramsOut) else {
            throw ShotValidationError.gramsOutInvalid
        }
        guard let timeDouble = validateStringToDoubleValue(value: time) else {
            throw ShotValidationError.timeInvalid
        }
        let model = ShotDataModel(
            brewMethod: brewMethod,
            gramsIn: gramsInDouble,
            gramsOut: gramsOutDouble,
            time: timeDouble,
            rating: rating,
            notes: notes,
            createdAt: .now
        )
        wipeData()
        return model
    }

    private func wipeData() {
        gramsIn = ""
        gramsOut = ""
        time = ""
        rating = 1
        notes = ""
    }

    // TODO: Unit test
    private func validateStringToDoubleValue(value: String) -> Double? {
        if !value.isEmpty {
            guard let doubleValue = Double(value) else {
                return nil
            }
            return doubleValue
        } else { return 0 }
    }

    enum ShotValidationError: Error {
        case gramsInInvalid
        case gramsOutInvalid
        case timeInvalid
        case noCoffeeSelected

        var localizedDescription: String {
            return switch self {
            case .gramsInInvalid:
                "Please enter a valid grams in value"
            case .gramsOutInvalid:
                "Please enter a valid grams out value"
            case .timeInvalid:
                "Please enter a valid time value"
            case .noCoffeeSelected:
                "Please select a coffee to log the shot to"
            }
        }
    }
}
