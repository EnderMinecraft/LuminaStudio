// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "VectorCore",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "VectorCore",
            targets: ["VectorCore"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "VectorCore",
            dependencies: [],
            path: "Sources/VectorCore"
        ),
        .testTarget(
            name: "VectorCoreTests",
            dependencies: ["VectorCore"],
            path: "Tests/VectorCoreTests"
        )
    ]
)
