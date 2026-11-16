// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "EditorCore",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "EditorCore",
            targets: ["EditorCore"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "EditorCore",
            dependencies: [],
            path: "Sources/EditorCore",
            resources: [
                .process("Shaders")
            ]
        ),
        .testTarget(
            name: "EditorCoreTests",
            dependencies: ["EditorCore"],
            path: "Tests/EditorCoreTests"
        )
    ]
)
