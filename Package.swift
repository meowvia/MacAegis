// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MacAegis",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "MacAegisCore",
            targets: ["MacAegisCore"]
        ),
        .executable(
            name: "MacAegisApp",
            targets: ["MacAegisApp"]
        ),
        .executable(
            name: "macaegis",
            targets: ["MacAegisCLI"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "MacAegisCore",
            dependencies: [],
            path: "Sources/MacAegisCore"
        ),
        .executableTarget(
            name: "MacAegisApp",
            dependencies: ["MacAegisCore"],
            path: "Sources/MacAegisApp"
        ),
        .executableTarget(
            name: "MacAegisCLI",
            dependencies: ["MacAegisCore"],
            path: "Sources/MacAegisCLI"
        ),
        .testTarget(
            name: "MacAegisTests",
            dependencies: ["MacAegisCore"],
            path: "Tests/MacAegisTests"
        )
    ]
)
