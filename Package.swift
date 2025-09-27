// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "STMedia",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "STMedia",
            targets: ["STMedia"]
        ),
    ],
    targets: [
        .target(
            name: "STMedia",
            path: "Sources"
        ),
    ],
    swiftLanguageVersions: [.v5]
)
