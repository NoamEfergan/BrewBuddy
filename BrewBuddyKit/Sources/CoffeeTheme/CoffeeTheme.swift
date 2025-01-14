import SwiftUI

public enum CoffeeTheme {
  // MARK: - Color Definitions

  /// Main accent color definitions
  public enum AccentColor {
    /// Primary accent color - Deep Brown
    public static let primary = Color("AccentPrimary", bundle: .module)

    /// Secondary accent color - Coffee Brown
    public static let secondary = Color("AccentSecondary", bundle: .module)

    /// Highlight accent color - Latte
    public static let highlight = Color("AccentHighlight", bundle: .module)

    /// Background color - Cream
    public static let background = Color("AccentBackground", bundle: .module)

    /// Text color - Dark Roast
    public static let text = Color("AccentText", bundle: .module)
  }

  // MARK: - Color Variations

  /// Returns color with adjusted opacity
  public static func withOpacity(_ color: Color, opacity: Double) -> Color {
    color.opacity(opacity)
  }

  /// Returns a lighter version of the color
  public static func lighter(_ color: Color, percentage _: Double = 0.2) -> Color {
    // Implement color lightening logic here
    color
  }

  /// Returns a darker version of the color
  public static func darker(_ color: Color, percentage _: Double = 0.2) -> Color {
    // Implement color darkening logic here
    color
  }
}
