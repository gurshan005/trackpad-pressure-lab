// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "TremorCheckMVP",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(url: "https://github.com/Kyome22/OpenMultitouchSupport.git", exact: "3.0.3")
    ],
    targets: [
        .executableTarget(
            name: "TremorCheckMVP",
            dependencies: ["OpenMultitouchSupport"],
            path: "Sources"
        ),
        .testTarget(name: "TremorCheckMVPTests", dependencies: ["TremorCheckMVP"], path: "Tests")
    ],
    swiftLanguageModes: [.v5]
)
