// swift-tools-version: 6.1

import PackageDescription

let package = Package(
  name: "ColorToImage",
  dependencies: [
    .package(url: "https://github.com/realm/SwiftLint", from: "0.58.2"),
    .package(
      url: "https://github.com/takanoriyanagitani/sw-img2png", from: "0.2.0",
    ),
  ],
  targets: [
    .executableTarget(
      name: "ColorToImage",
      dependencies: [
        .product(name: "ImageToPng", package: "sw-img2png"),
        .product(name: "FpUtil", package: "sw-img2png"),
      ]
    )
  ]
)
