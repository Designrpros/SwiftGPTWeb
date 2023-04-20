// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "GPTWebSearchBot",
    dependencies: [
        .package(url: "https://github.com/SwiftyJSON/SwiftyJSON.git", from: "5.0.0"),
    ],
    targets: [
        .target(
            name: "GPTWebSearchBot",
            dependencies: ["SwiftyJSON"]),
        .testTarget(
            name: "GPTWebSearchBotTests",
            dependencies: ["GPTWebSearchBot"]),
    ]
)
