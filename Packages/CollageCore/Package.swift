// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CollageCore",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "CollageCore",
            targets: ["CollageCore"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "CollageCore",
            dependencies: [],
            path: "Sources/CollageCore"
        ),
        .testTarget(
            name: "CollageCoreTests",
            dependencies: ["CollageCore"],
            path: "Tests/CollageCoreTests"
        )
    ]
)
