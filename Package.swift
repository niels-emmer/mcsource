// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "mcsource",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "AudioCore", targets: ["AudioCore"]),
        .executable(name: "McSource", targets: ["McSourceApp"]),
    ],
    targets: [
        .target(
            name: "AudioCore",
            path: "Sources/AudioCore",
            linkerSettings: [.linkedFramework("CoreAudio")]
        ),
        .executableTarget(
            name: "McSourceApp",
            dependencies: ["AudioCore"],
            path: "Sources/McSourceApp",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("CoreAudio"),
                .linkedFramework("ServiceManagement"),
            ]
        ),
        .testTarget(
            name: "AudioCoreTests",
            dependencies: ["AudioCore"],
            path: "Tests/AudioCoreTests"
        ),
    ]
)
