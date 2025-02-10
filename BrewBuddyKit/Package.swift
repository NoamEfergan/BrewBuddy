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
        .library(name: "AddCoffeeScreen", targets: ["AddCoffeeScreen"]),
        .library(name: "CoffeeListScreen", targets: ["CoffeeListScreen"]),
        .library(name: "CoffeeTheme", targets: ["CoffeeTheme"]),
        .library(name: "ShotsScreen", targets: ["ShotsScreen"]),
        .library(name: "Models", targets: ["Models"]),
    ],
    targets: [
        .target(name: "AddCoffeeScreen", dependencies: ["Models", "CoffeeTheme"]),
        .target(name: "CoffeeListScreen", dependencies: ["Models", "CoffeeTheme", "CommonUI"]),
        .target(name: "ShotsScreen", dependencies: ["Models", "CoffeeTheme", "CommonUI"]),
        .target(name: "Models"),
        .target(name: "CommonUI"),
        .target(name: "CoffeeTheme", resources: [.process("Resources/Colors.xcassets")]),
        .testTarget(name: "AddCoffeeScreenTests", dependencies: ["AddCoffeeScreen"]),
    ]
)
