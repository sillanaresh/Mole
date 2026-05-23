// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "CheepuruKatta",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "CheepuruKattaCore",
            targets: ["CheepuruKattaCore"]
        ),
        .executable(
            name: "CheepuruKatta",
            targets: ["CheepuruKatta"]
        )
    ],
    targets: [
        .target(
            name: "CheepuruKattaCore"
        ),
        .executableTarget(
            name: "CheepuruKatta",
            dependencies: ["CheepuruKattaCore"]
        ),
        .testTarget(
            name: "CheepuruKattaCoreTests",
            dependencies: ["CheepuruKattaCore"]
        )
    ]
)
