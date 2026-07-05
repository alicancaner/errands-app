// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ErrandKit",
    products: [
        .library(name: "ErrandKit", targets: ["ErrandKit"])
    ],
    targets: [
        // Foundation-only: no CoreLocation/UIKit imports, ever.
        // Reason: this package must compile and test on Windows and Linux,
        // where Apple's iOS frameworks don't exist.
        .target(name: "ErrandKit"),
        .testTarget(name: "ErrandKitTests", dependencies: ["ErrandKit"]),
    ]
)
