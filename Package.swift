// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "GemPDFKit",
    platforms: [
        .iOS(.v15), .macOS(.v12)
    ],
    products: [
        .library(
            name: "GemPDFKit",
            targets: ["GemPDFKit"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-parsing", from: "0.13.0"),
        .package(url: "https://github.com/Quick/Nimble", from: "10.0.0"),
    ],
    targets: [
        .target(
            name: "GemPDFKit",
            dependencies: [
                .product(name: "Parsing", package: "swift-parsing"),
            ]
        ),
        .testTarget(
            name: "GemPDFKitTests",
            dependencies: [
                "GemPDFKit",
                .product(name: "Nimble", package: "nimble"),
            ],
            resources: [
                .copy("TestData/")
            ]
        )
    ]
)
