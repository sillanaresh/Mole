// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "Eagle",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "EagleCore",
            targets: ["EagleCore"]
        ),
        .executable(
            name: "Eagle",
            targets: ["Eagle"]
        )
    ],
    targets: [
        .target(
            name: "EagleCore"
        ),
        .executableTarget(
            name: "Eagle",
            dependencies: ["EagleCore"],
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "EagleCoreTests",
            dependencies: ["EagleCore"]
        ),
        .testTarget(
            name: "EagleTests",
            dependencies: ["Eagle", "EagleCore"]
        )
    ]
)
