// DockSDK/Sources/DockSpotlightProvider.swift
//
// Protocol for docks that want to provide dynamic, real-time search
// results to the Spotlight command palette. Unlike spotlightActions()
// which returns static actions, a DockSpotlightProvider generates
// results on-the-fly based on the user's search query.
//
// This enables docks to:
// - Provide live search results (e.g., a bookmark dock searching its links)
// - Return inline computed values (e.g., calculations, conversions)
// - Offer drill-down sub-views in the Spotlight panel
// - Respond to natural language queries
//
// v1.2.0

import AppKit

/// Protocol for docks that provide dynamic spotlight search results.
///
/// Conform to this protocol in your dock's principal class alongside `DockPlugin`.
/// The host calls `searchSpotlight(query:)` on every keystroke (debounced)
/// and merges results with built-in and other dock results.
///
/// ## Example
/// ```swift
/// @objc(MyDockPlugin)
/// class MyDockPlugin: NSObject, DockPlugin, DockSpotlightProvider {
///     func searchSpotlight(query: String) -> [DockSpotlightResult] {
///         // Return results matching the query
///         return myData.filter { $0.name.contains(query) }.map { item in
///             DockSpotlightResult(
///                 identifier: item.id,
///                 title: item.name,
///                 subtitle: "My Dock",
///                 icon: nil,
///                 category: "My Items"
///             ).onAction { /* handle selection */ }
///         }
///     }
/// }
/// ```
@objc(DockSpotlightProvider)
public protocol DockSpotlightProvider: NSObjectProtocol {

    /// Called by the host when the user types in the Spotlight search bar.
    /// Return an array of results that match the query. Called on every
    /// keystroke with debouncing (~50ms). Keep this fast — aim for <5ms.
    ///
    /// - Parameter query: The current search text (lowercased by the host).
    /// - Returns: Array of matching results. Empty array if no matches.
    @objc func searchSpotlight(query: String) -> [DockSpotlightResult]

    /// Optional: Provide a sub-view for drill-down navigation when the user
    /// selects a spotlight action that has `hasDrillDown = true`.
    ///
    /// - Parameter actionIdentifier: The identifier of the selected action.
    /// - Returns: An NSView to display in the Spotlight panel, or nil.
    @objc optional func createSpotlightSubView(for actionIdentifier: String) -> NSView?

    /// Optional: Called when the Spotlight panel is about to show.
    /// Use this to prepare/refresh data for search.
    @objc optional func spotlightWillShow()

    /// Optional: Called when the Spotlight panel is dismissed.
    /// Use this to clean up resources.
    @objc optional func spotlightDidHide()

    /// Optional: Return the categories this provider populates.
    /// Used by the host to show category headers even before searching.
    @objc optional func spotlightCategories() -> [String]

    /// Optional: Return a placeholder string for the search bar when
    /// the user has drilled into this dock's sub-view.
    @objc optional func spotlightSearchPlaceholder() -> String
}

// MARK: — Spotlight Provider Info

/// Metadata about a spotlight provider, used by the host for registration.
@objc(DockSpotlightProviderInfo)
public class DockSpotlightProviderInfo: NSObject {

    /// The dock identifier of the provider.
    @objc public let dockIdentifier: String

    /// Human-readable name of the dock providing results.
    @objc public let dockName: String

    /// Whether this provider supports drill-down sub-views.
    @objc public let supportsDrillDown: Bool

    /// Maximum number of results this provider returns per query.
    @objc public let maxResults: Int

    @objc public init(
        dockIdentifier: String,
        dockName: String,
        supportsDrillDown: Bool = false,
        maxResults: Int = 10
    ) {
        self.dockIdentifier = dockIdentifier
        self.dockName = dockName
        self.supportsDrillDown = supportsDrillDown
        self.maxResults = maxResults
        super.init()
    }
}
