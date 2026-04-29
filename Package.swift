// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MovieBookingApp",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "SharedKit",
            targets: ["SharedKit"]
        ),
    ],
    targets: [
        .target(
            name: "SharedKit",
            path: "Shared"
        ),
        .testTarget(
            name: "SharedKitTests",
            dependencies: ["SharedKit"],
            path: "Tests/UnitTests"
        ),
    ]
)
