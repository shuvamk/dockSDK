// DockSDK/Sources/DockSpotlightAction.swift
//
// Represents a quick action that a dock exposes to the host's
// global Spotlight command palette (Raycast-style launcher).
//
// v1.2.0: Enhanced with priority, shortcut hints, inline result support,
// and sub-view provider for drill-down navigation.

import AppKit

// MARK: — Spotlight Action

@objc(DockSpotlightAction)
public class DockSpotlightAction: NSObject {

    @objc public let identifier: String
    @objc public let title: String
    @objc public let subtitle: String
    @objc public let icon: NSImage?
    @objc public let keywords: [String]
    @objc public let category: String

    /// Whether the host should activate (switch to) this dock before executing.
    @objc public let requiresActivation: Bool

    /// Optional shortcut hint displayed on the right side of the result row.
    /// Example: "⌘C", "⌘⇧P". Purely cosmetic — actual key handling is separate.
    @objc public let shortcutHint: String?

    /// Priority for ordering within the same category (higher = shown first).
    /// Default is 0. Built-in commands use 100+.
    @objc public let priority: Int

    /// If true, this action supports drill-down: selecting it opens a sub-view
    /// provided by the dock's `createSpotlightSubView(for:)` method.
    @objc public let hasDrillDown: Bool

    /// Optional inline result text shown directly in search results
    /// without needing to select the action. Example: a calculator result.
    @objc public var inlineResult: String?

    /// Optional accent color name (SF Symbol color) for the icon background.
    /// Supported: "blue", "green", "orange", "red", "purple", "pink", "yellow", "teal"
    @objc public let iconAccentColor: String?

    @objc public init(
        identifier: String,
        title: String,
        subtitle: String,
        icon: NSImage?,
        keywords: [String],
        category: String,
        requiresActivation: Bool = false,
        shortcutHint: String? = nil,
        priority: Int = 0,
        hasDrillDown: Bool = false,
        inlineResult: String? = nil,
        iconAccentColor: String? = nil
    ) {
        self.identifier = identifier
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.keywords = keywords
        self.category = category
        self.requiresActivation = requiresActivation
        self.shortcutHint = shortcutHint
        self.priority = priority
        self.hasDrillDown = hasDrillDown
        self.inlineResult = inlineResult
        self.iconAccentColor = iconAccentColor
        super.init()
    }
}

// MARK: — Spotlight Search Result (returned by DockSpotlightProvider)

/// A dynamic search result returned by a dock's spotlight provider.
/// Unlike DockSpotlightAction (static, registered once), these are
/// generated on-the-fly in response to search queries.
@objc(DockSpotlightResult)
public class DockSpotlightResult: NSObject {

    @objc public let identifier: String
    @objc public let title: String
    @objc public let subtitle: String
    @objc public let icon: NSImage?
    @objc public let category: String

    /// The action to execute when the user selects this result.
    /// Not @objc — closures aren't ObjC-representable.
    public var action: (() -> Void)?

    /// Optional inline result (e.g., "= 42" for calculations).
    @objc public var inlineResult: String?

    /// Optional shortcut hint for the result row.
    @objc public var shortcutHint: String?

    /// Priority for result ordering (higher = first).
    @objc public var priority: Int

    /// Accent color name for the icon background.
    @objc public var iconAccentColor: String?

    @objc public init(
        identifier: String,
        title: String,
        subtitle: String,
        icon: NSImage?,
        category: String,
        priority: Int = 0,
        inlineResult: String? = nil,
        shortcutHint: String? = nil,
        iconAccentColor: String? = nil
    ) {
        self.identifier = identifier
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.category = category
        self.priority = priority
        self.inlineResult = inlineResult
        self.shortcutHint = shortcutHint
        self.iconAccentColor = iconAccentColor
        super.init()
    }

    /// Fluent setter for the action closure.
    @discardableResult
    public func onAction(_ handler: @escaping () -> Void) -> DockSpotlightResult {
        self.action = handler
        return self
    }
}

// MARK: — Spotlight Command Category

/// Pre-defined spotlight categories for consistent grouping.
@objc(DockSpotlightCategory)
public class DockSpotlightCategory: NSObject {
    @objc public static let applications = "Applications"
    @objc public static let commands = "Commands"
    @objc public static let quickLinks = "Quick Links"
    @objc public static let snippets = "Snippets"
    @objc public static let system = "System"
    @objc public static let files = "Files"
    @objc public static let calculations = "Calculations"
    @objc public static let conversions = "Conversions"
    @objc public static let clipboard = "Clipboard"
    @objc public static let docks = "Docks"
    @objc public static let themes = "Themes"
    @objc public static let utilities = "Utilities"
    @objc public static let suggested = "Suggested"
}
