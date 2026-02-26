// swift-tools-version:5.9
// Package.swift — DockSDK
//
// The shared dynamic framework that defines the contract between the
// Superdock host and all dock plugins. Every dock links against this
// package to conform to the DockPlugin protocol.
//
// Usage (in a dock's Package.swift):
//
//   dependencies: [
//       .package(url: "https://github.com/<org>/DockSDK.git", from: "1.0.0"),
//       // or for local development:
//       .package(path: "../DockSDK"),
//   ],
//   targets: [
//       .target(name: "MyDock", dependencies: ["DockSDK"]),
//   ]
//
// IMPORTANT: DockSDK MUST be built as a dynamic library so that the
// host app and all dock bundles share a single copy of the protocol
// types in memory. If linked statically, `as? DockPlugin` casts fail
// silently across bundle boundaries.

import PackageDescription

let package = Package(
    name: "DockSDK",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "DockSDK",
            type: .dynamic, // MUST be dynamic — see note above
            targets: ["DockSDK"]
        ),
    ],
    targets: [
        .target(
            name: "DockSDK",
            path: "Sources/DockSDK"
        ),
    ]
)
