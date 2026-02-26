// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MacPulse",
    platforms: [.macOS(.v14)],
    targets: [
        .target(
            name: "MacPulseCore",
            path: "Sources/MacPulse",
            linkerSettings: [
                .linkedFramework("IOKit"),
            ]
        ),
        .executableTarget(
            name: "MacPulse",
            dependencies: ["MacPulseCore"],
            path: "Sources/MacPulseApp",
            linkerSettings: [
                .linkedFramework("IOKit"),
            ]
        ),
        .executableTarget(
            name: "MacPulseTests",
            dependencies: ["MacPulseCore"],
            path: "Tests/MacPulseTests",
            linkerSettings: [
                .linkedFramework("IOKit"),
            ]
        ),
    ]
)
