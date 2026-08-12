// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "STMedia",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "STMedia",
            targets: ["STMedia"]
        ),
    ],
    dependencies: [
        // 发布时改为远程仓库：
        // .package(url: "https://github.com/i-stack/STBaseProject.git", from: "1.6.0")
        .package(name: "STBaseProject", path: "../STBaseProject")
    ],
    targets: [
        .target(
            name: "STMedia",
            dependencies: [
                .product(name: "STBaseProject", package: "STBaseProject")
            ],
            path: "Sources/STMedia",
            resources: [
                .process("PrivacyInfo.xcprivacy")
            ]
        ),
    ],
    swiftLanguageVersions: [.v5]
)
