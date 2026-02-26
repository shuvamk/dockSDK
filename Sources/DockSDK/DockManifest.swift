// DockSDK/Sources/DockManifest.swift
//
// Parses dock metadata from the bundle's Info.plist.

import Foundation

/// Metadata parsed from a dock bundle's Info.plist.
///
/// Custom keys used:
/// - `DockIdentifier` — reverse-DNS identifier
/// - `DockName` — human-readable name
/// - `DockVersion` — semantic version
/// - `DockMinimumSDKVersion` — minimum DockSDK version required
/// - `DockAuthor` — author name
/// - `DockDescription` — short description
@objc(DockManifest)
public class DockManifest: NSObject {

    @objc public let identifier: String
    @objc public let name: String
    @objc public let version: String
    @objc public let minimumSDKVersion: String
    @objc public let author: String
    @objc public let dockDescription: String
    @objc public let bundleURL: URL
    @objc public let iconName: String

    @objc public init(bundle: Bundle) {
        let info = bundle.infoDictionary ?? [:]

        self.identifier = info["DockIdentifier"] as? String
            ?? bundle.bundleIdentifier
            ?? "unknown"
        self.name = info["DockName"] as? String
            ?? info["CFBundleName"] as? String
            ?? "Unnamed Dock"
        self.version = info["DockVersion"] as? String
            ?? info["CFBundleShortVersionString"] as? String
            ?? "0.0.0"
        self.minimumSDKVersion = info["DockMinimumSDKVersion"] as? String ?? "1.0.0"
        self.author = info["DockAuthor"] as? String ?? "Unknown"
        self.dockDescription = info["DockDescription"] as? String ?? ""
        self.bundleURL = bundle.bundleURL
        self.iconName = info["DockIconName"] as? String ?? ""

        super.init()
    }
}
