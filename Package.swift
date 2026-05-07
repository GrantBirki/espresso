// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "Espresso",
    platforms: [
        .macOS(.v26),
    ],
    products: [
        .executable(
            name: "Espresso",
            targets: ["Espresso"]
        ),
    ],
    targets: [
        .executableTarget(
            name: "Espresso",
            path: "Sources",
            resources: [
                .process("Resources"),
            ]
        ),
        .testTarget(
            name: "EspressoTests",
            dependencies: ["Espresso"],
            path: "Tests"
        ),
    ],
    swiftLanguageModes: [.v6]
)
