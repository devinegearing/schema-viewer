// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "SchemaViewer",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/sparkle-project/Sparkle.git", from: "2.6.0"),
    ],
    targets: [
        .executableTarget(
            name: "SchemaViewer",
            dependencies: [
                .product(name: "Sparkle", package: "Sparkle"),
            ],
            path: "Sources/SchemaViewer",
            resources: [.process("Resources")],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency"),
            ]
        ),
        .testTarget(
            name: "SchemaViewerTests",
            dependencies: ["SchemaViewer"],
            path: "Tests/SchemaViewerTests"
        ),
    ]
)
