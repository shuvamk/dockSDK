// DockSDK/Sources/DockPlugin.swift
//
// The core protocol that every dock's principal class must conform to.
// This is the single most important type in the entire Superdock ecosystem.

import AppKit

/// The contract between a dock bundle and the Superdock host.
///
/// The `@objc(DockPlugin)` annotation provides a stable Objective-C runtime name
/// that works across bundle boundaries. Without it, Swift's name mangling produces
/// different names per module, and `as? DockPlugin` silently returns `nil`.
///
/// ## Implementing a Dock
/// 1. Create a class inheriting from `NSObject`
/// 2. Conform to `DockPlugin`
/// 3. Add `@objc(YourClassName)` matching `NSPrincipalClass` in Info.plist
/// 4. Link against `DockSDK.framework` (do NOT embed it)
///
/// ## Lifecycle
/// `init()` → `dockDidLoad(context:)` → `createMainView()` → `dockDidBecomeActive()`
/// → (user interacts) → `dockDidResignActive()` → ... → `dockWillUnload()`
///
/// ## Spotlight Integration (v1.2.0)
/// Docks can expose functionality to the Raycast-style command palette in two ways:
/// 1. **Static actions** via `spotlightActions()` — registered once, always searchable
/// 2. **Dynamic search** via `DockSpotlightProvider` protocol — real-time query results
///
/// For dynamic search, also conform to `DockSpotlightProvider` in your principal class.
@objc(DockPlugin)
public protocol DockPlugin: NSObjectProtocol {

    // MARK: - Identity

    /// Reverse-DNS identifier, e.g. "com.superdock.hello-dock"
    var identifier: String { get }

    /// Human-readable display name
    var name: String { get }

    /// Semantic version string, e.g. "1.0.0"
    var version: String { get }

    /// Short description of the dock's purpose
    var dockDescription: String { get }

    /// Minimum DockSDK version required, e.g. "1.0.0"
    var minimumSDKVersion: String { get }

    /// Optional icon for sidebar and settings display
    var icon: NSImage? { get }

    // MARK: - Lifecycle

    /// Required parameterless initializer for NSBundle principal class instantiation.
    init()

    /// Called after the host has loaded the bundle and created a DockContext.
    /// Perform setup here, not in `init()`.
    func dockDidLoad(context: DockContext)

    /// Create and return the dock's main NSView. Called lazily on first activation.
    /// Typically wraps a SwiftUI view in `NSHostingView`.
    func createMainView() -> NSView

    /// Called when the dock becomes the active (visible) dock.
    @objc optional func dockDidBecomeActive()

    /// Called when the dock is deactivated (another dock is activated).
    @objc optional func dockDidResignActive()

    /// Called before the host shuts down. Save state here.
    @objc optional func dockWillUnload()

    // MARK: - Capabilities

    /// List of capability strings this dock requires, e.g. ["network", "filesystem"].
    @objc optional var requiredCapabilities: [String] { get }

    /// Toolbar items to display in the host toolbar when this dock is active.
    @objc optional func toolbarItems() -> [NSView]

    /// Handle a deep link URL routed to this dock via `superdock://identifier/path`.
    /// Return `true` if the URL was handled.
    @objc optional func handleURL(_ url: URL) -> Bool

    /// Menu items to add to the host menu when this dock is active.
    @objc optional func menuItems() -> [NSMenuItem]

    // MARK: - Key Bindings (v1.1.0)

    /// Keyboard shortcuts this dock wants to register with the host.
    /// Bindings are scoped: only active when this dock is focused.
    @objc optional func keyBindings() -> [DockKeyBinding]

    // MARK: - Spotlight Actions (v1.1.0, enhanced v1.2.0)

    /// Static quick actions exposed to the host's global Spotlight command palette.
    /// These are registered once when the dock loads and always appear in search results.
    ///
    /// For dynamic, query-based results, also conform to `DockSpotlightProvider`.
    @objc optional func spotlightActions() -> [DockSpotlightAction]

    /// Called by the host when the user selects a spotlight action for this dock.
    @objc optional func executeSpotlightAction(identifier: String)

    // MARK: - Spotlight Sub-View (v1.2.0)

    /// Create a sub-view for drill-down navigation in the Spotlight panel.
    /// Called when the user selects a spotlight action with `hasDrillDown = true`.
    ///
    /// The returned NSView is displayed inside the Spotlight panel, replacing
    /// the results list. The user presses Escape to go back.
    ///
    /// - Parameter actionIdentifier: The identifier of the selected action.
    /// - Returns: An NSView to display, or nil to fall back to default behavior.
    @objc optional func createSpotlightSubView(for actionIdentifier: String) -> NSView?
}
