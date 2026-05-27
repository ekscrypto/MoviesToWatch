// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MoviesToWatch",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "DomainLogic", targets: ["DomainLogic"]),
        .executable(name: "MoviesToWatchApp", targets: ["MoviesToWatchApp"]),
    ],
    targets: [
        .target(
            name: "DomainLogic",
            path: "Sources/DomainLogic"
        ),
        .executableTarget(
            name: "MoviesToWatchApp",
            dependencies: ["DomainLogic"],
            path: "Sources/MoviesToWatchApp"
        ),
        .testTarget(
            name: "DomainLogicTests",
            dependencies: ["DomainLogic"],
            path: "Tests/DomainLogicTests"
        ),
    ],
    swiftLanguageVersions: [.v5]
)
