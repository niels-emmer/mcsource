// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "McAudio",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "AudioCore", targets: ["AudioCore"]),
        .executable(name: "McAudio", targets: ["McAudioApp"]),
    ],
    targets: [
        .target(
            name: "AudioCore",
            path: "Sources/AudioCore",
            linkerSettings: [.linkedFramework("CoreAudio")]
        ),
        .executableTarget(
            name: "McAudioApp",
            dependencies: ["AudioCore"],
            path: "Sources/McAudioApp",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("CoreAudio"),
                .linkedFramework("ServiceManagement"),
                .linkedFramework("Carbon"),
            ]
        ),
        .testTarget(
            name: "AudioCoreTests",
            dependencies: ["AudioCore"],
            path: "Tests/AudioCoreTests"
        ),
    ]
)
