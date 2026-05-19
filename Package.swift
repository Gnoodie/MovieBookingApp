// swift-tools-version: 5.5
import PackageDescription

let package = Package(
    name: "MovieBookingApp",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "SharedKit",
            targets: ["SharedKit"]
        ),
    ],
    dependencies: [
        // Firebase iOS SDK — dùng Firestore làm backend
        .package(
            url: "https://github.com/firebase/firebase-ios-sdk.git",
            .upToNextMajor(from: "11.0.0")
        ),
    ],
    targets: [
        .target(
            name: "SharedKit",
            dependencies: [
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestoreSwift", package: "firebase-ios-sdk"),
            ],
            path: "Shared"
        ),
        .testTarget(
            name: "SharedKitTests",
            dependencies: ["SharedKit"],
            path: "Tests/UnitTests"
        ),
    ]
)
