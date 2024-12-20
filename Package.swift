// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "swift-shell-client",
    platforms: [
        .macOS(.v10_15),
    ],
    products: [
        .executable(name: "version", targets: ["version"]),
        .library(name: "ShellClient", targets: ["ShellClient"]),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-dependencies.git", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
        .package(url: "https://github.com/adorkable/swift-log-format-and-pipe.git", from: "0.1.0"),
        .package(url: "https://github.com/onevcat/Rainbow", from: "4.0.0"),
        .package(url: "https://github.com/apple/swift-docc-plugin.git", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "ShellClient",
            dependencies: [
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "LoggingFormatAndPipe", package: "swift-log-format-and-pipe"),
                .product(name: "Rainbow", package: "Rainbow"),
            ]
        ),
        .testTarget(
            name: "ShellClientTests",
            dependencies: [
                "ShellClient",
            ]
        ),
        .executableTarget(
            name: "test-library",
            dependencies: [
                "ShellClient",
            ]
        ),
        .executableTarget(
            name: "version",
            dependencies: [
                "ShellClient",
            ]
        ),
    ]
)
