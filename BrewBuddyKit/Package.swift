// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BrewBuddyKit",
    defaultLocalization: "en",
    platforms: [
      .iOS(.v17),
      ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "AddCoffeeScreen",
            targets: ["AddCoffeeScreen"]),
        .library(
          name: "CoffeeTheme",
          targets: ["CoffeeTheme"]),
        .library(
            name: "Models",
            targets: ["Models"]),
    ],
    targets: [
        .target(
            name: "AddCoffeeScreen",
            dependencies: ["Models", "CoffeeTheme"]
        ),
        .target(name: "Models"),
        .target(
          name: "CoffeeTheme",
          resources: [
            .process("Resources/Colors.xcassets")
          ]
        ),
        .testTarget(
            name: "AddCoffeeScreenTests",
            dependencies: ["AddCoffeeScreen"]
        ),
    ]
)
