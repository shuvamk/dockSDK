// DockSDK/Sources/Services/DockNavigation.swift
//
// Cross-dock navigation via the host.

import Foundation

/// Allows docks to request navigation to other docks.
///
/// The host wires `onNavigationRequest` during context creation.
/// When a dock calls `navigate(to:)`, the host activates the target dock.
@objc(DockNavigation)
public class DockNavigation: NSObject {

    /// Callback set by the host to handle navigation requests.
    @objc public var onNavigationRequest: ((String) -> Void)?

    /// Callback set by the host to handle URL-based navigation.
    @objc public var onOpenURL: ((URL) -> Void)?

    /// Request the host to activate another dock.
    ///
    /// - Parameter dockIdentifier: The reverse-DNS identifier of the target dock.
    @objc public func navigate(to dockIdentifier: String) {
        if let handler = onNavigationRequest {
            handler(dockIdentifier)
        } else {
            print("[DockNavigation] Navigation request ignored — no handler wired for '\(dockIdentifier)'")
        }
    }

    /// Request the host to open a URL.
    ///
    /// - Parameter url: The URL to open (can be `superdock://` scheme or external).
    @objc public func openURL(_ url: URL) {
        if let handler = onOpenURL {
            handler(url)
        } else {
            print("[DockNavigation] openURL ignored — no handler wired for '\(url)'")
        }
    }
}
