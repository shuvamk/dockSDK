// DockSDK/Sources/Services/DockSpotlightService.swift
//
// Service for docks to interact with the host's Spotlight command launcher.
// Provides methods to programmatically show/hide spotlight, register dynamic
// actions, and push inline results.
//
// v1.3.0

import AppKit

/// Service for docks to interact with the host's Spotlight command palette.
///
/// ## Usage
/// ```swift
/// func dockDidLoad(context: DockContext) {
///     // Show spotlight programmatically
///     context.spotlight.show()
///
///     // Show with a pre-filled query
///     context.spotlight.show(query: "clipboard")
///
///     // Register a dynamic inline result
///     context.spotlight.registerInlineResult(
///         identifier: "my-calc",
///         title: "Custom Calculation",
///         result: "= 42",
///         icon: nil,
///         category: DockSpotlightCategory.calculations
///     )
///
///     // Hide spotlight
///     context.spotlight.hide()
/// }
/// ```
@objc(DockSpotlightService)
public class DockSpotlightService: NSObject {

    // MARK: - Callbacks (wired by host)

    /// Called by dock to request showing the spotlight panel.
    @objc public var onShow: (() -> Void)?

    /// Called by dock to request showing spotlight with a pre-filled query.
    @objc public var onShowWithQuery: ((String) -> Void)?

    /// Called by dock to request hiding the spotlight panel.
    @objc public var onHide: (() -> Void)?

    /// Called by dock to request toggling the spotlight panel.
    @objc public var onToggle: (() -> Void)?

    /// Called by dock to register a persistent inline result.
    /// Parameters: (identifier, title, subtitle, inlineResult, iconAccentColor, category)
    @objc public var onRegisterInlineResult: ((String, String, String, String, String?, String) -> Void)?

    /// Called by dock to remove a previously registered inline result.
    @objc public var onRemoveInlineResult: ((String) -> Void)?

    /// Called by dock to check if spotlight is currently visible.
    @objc public var onIsVisible: (() -> Bool)?

    /// Called by dock to refresh its spotlight actions (e.g., after data changes).
    @objc public var onRefresh: (() -> Void)?

    // MARK: - Public API

    /// Show the spotlight command palette.
    @objc public func show() {
        if let handler = onShow {
            handler()
        } else {
            print("[DockSpotlightService] show() ignored — no handler wired")
        }
    }

    /// Show the spotlight command palette with a pre-filled search query.
    ///
    /// - Parameter query: The text to pre-fill in the search bar.
    @objc public func show(query: String) {
        if let handler = onShowWithQuery {
            handler(query)
        } else {
            print("[DockSpotlightService] show(query:) ignored — no handler wired")
        }
    }

    /// Hide the spotlight command palette.
    @objc public func hide() {
        if let handler = onHide {
            handler()
        } else {
            print("[DockSpotlightService] hide() ignored — no handler wired")
        }
    }

    /// Toggle the spotlight command palette visibility.
    @objc public func toggle() {
        if let handler = onToggle {
            handler()
        } else {
            print("[DockSpotlightService] toggle() ignored — no handler wired")
        }
    }

    /// Check if the spotlight panel is currently visible.
    @objc public var isVisible: Bool {
        return onIsVisible?() ?? false
    }

    /// Register a persistent inline result that appears when the user's query
    /// matches the given title or keywords. Useful for docks that want to show
    /// computed values or quick results in the spotlight.
    ///
    /// - Parameters:
    ///   - identifier: Unique identifier for this result (used for updates/removal).
    ///   - title: The display title.
    ///   - subtitle: Secondary text.
    ///   - inlineResult: The inline result text (e.g., "= 42").
    ///   - iconAccentColor: Optional accent color name for the icon background.
    ///   - category: The category to group this result under.
    @objc public func registerInlineResult(
        identifier: String,
        title: String,
        subtitle: String,
        inlineResult: String,
        iconAccentColor: String?,
        category: String
    ) {
        if let handler = onRegisterInlineResult {
            handler(identifier, title, subtitle, inlineResult, iconAccentColor, category)
        } else {
            print("[DockSpotlightService] registerInlineResult() ignored — no handler wired")
        }
    }

    /// Remove a previously registered inline result.
    ///
    /// - Parameter identifier: The identifier used when registering.
    @objc public func removeInlineResult(identifier: String) {
        if let handler = onRemoveInlineResult {
            handler(identifier)
        } else {
            print("[DockSpotlightService] removeInlineResult() ignored — no handler wired")
        }
    }

    /// Notify the host to refresh this dock's spotlight actions.
    /// Call this after your dock's data changes (e.g., new items added).
    @objc public func refreshActions() {
        if let handler = onRefresh {
            handler()
        } else {
            print("[DockSpotlightService] refreshActions() ignored — no handler wired")
        }
    }
}
