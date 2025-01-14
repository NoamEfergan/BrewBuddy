import Foundation

public enum BrewMethod: String, CaseIterable, Codable {
  case espresso = "Espresso"
  case coldBrew = "Cold Brew"
  case pourOver = "Pour Over"
  case frenchPress = "French Press"
  case aeropress = "Aeropress"
  case chemex = "Chemex"
}
