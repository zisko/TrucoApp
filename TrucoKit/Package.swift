
// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "TrucoKit",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "TrucoKit",
            targets: ["TrucoKit"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "TrucoKit",
            dependencies: []),
    ]
)
