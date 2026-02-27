// DockSDK/Sources/DockContext.swift
//
// Service locator object passed to every dock during initialization.
// Provides access to all host-provided services.

import Foundation

/// Service locator providing access to all host services.
///
/// A single `DockContext` instance is created per dock during loading.
/// The host wires callback closures on the service objects before passing
/// the context to the dock via `dockDidLoad(context:)`.
///
/// ## Usage
/// ```swift
/// func dockDidLoad(context: DockContext) {
///     self.context = context
///     context.logger.info("Dock loaded!")
///     context.storage.set(someData, forKey: "myKey")
/// }
/// ```
@objc(DockContext)
public class DockContext: NSObject {

    /// Host application version string
    @objc public let hostVersion: String

    /// DockSDK version the host was built with
    @objc public let sdkVersion: String

    /// Whether the host is running in developer mode
    @objc public let isDevMode: Bool

    /// This dock's reverse-DNS identifier
    @objc public let dockIdentifier: String

    /// File-based key-value persistence scoped to this dock
    @objc public let storage: DockStorage

    /// macOS Keychain wrapper scoped to this dock
    @objc public let secureStorage: DockSecureStorage

    /// Cross-dock navigation requests
    @objc public let navigation: DockNavigation

    /// Cross-dock notification bus
    @objc public let notifications: DockNotificationCenter

    /// UI services: toasts, confirmations, sheets
    @objc public let ui: DockUIService

    /// Structured logging via os.log
    @objc public let logger: DockLogger

    /// Shared URLSession for network requests
    @objc public let networking: DockNetworking

    /// Spotlight command palette integration (v1.3.0)
    @objc public let spotlight: DockSpotlightService

    @objc public init(hostVersion: String, sdkVersion: String, isDevMode: Bool, dockIdentifier: String) {
        self.hostVersion = hostVersion
        self.sdkVersion = sdkVersion
        self.isDevMode = isDevMode
        self.dockIdentifier = dockIdentifier
        self.storage = DockStorage(dockIdentifier: dockIdentifier)
        self.secureStorage = DockSecureStorage(dockIdentifier: dockIdentifier)
        self.navigation = DockNavigation()
        self.notifications = DockNotificationCenter()
        self.ui = DockUIService()
        self.logger = DockLogger(dockIdentifier: dockIdentifier)
        self.networking = DockNetworking()
        self.spotlight = DockSpotlightService()
        super.init()
    }
}
