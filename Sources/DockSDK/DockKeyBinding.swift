// DockSDK/Sources/DockKeyBinding.swift
//
// Represents a keyboard shortcut that a dock can register with the host.
// The host's KeyBindingManager handles scoping, conflict resolution,
// and user overrides.

import AppKit

@objc(DockKeyBinding)
public class DockKeyBinding: NSObject {

    @objc public let identifier: String
    @objc public let title: String
    @objc public let key: String
    @objc public let modifiers: NSEvent.ModifierFlags
    @objc public let category: String

    /// The closure executed when the key binding fires.
    /// Not @objc — closures aren't ObjC-representable, but this is
    /// accessed from Swift only (KeyBindingManager).
    public var action: (() -> Void)?

    @objc public init(identifier: String, title: String, key: String, modifiers: NSEvent.ModifierFlags, category: String) {
        self.identifier = identifier
        self.title = title
        self.key = key
        self.modifiers = modifiers
        self.category = category
        super.init()
    }

    /// Fluent setter for the action closure. Returns self for chaining.
    @discardableResult
    public func onAction(_ handler: @escaping () -> Void) -> DockKeyBinding {
        self.action = handler
        return self
    }

    /// Human-readable shortcut string (e.g. "⌘⇧K").
    @objc public var displayString: String {
        var parts: [String] = []
        if modifiers.contains(.control) { parts.append("⌃") }
        if modifiers.contains(.option) { parts.append("⌥") }
        if modifiers.contains(.shift) { parts.append("⇧") }
        if modifiers.contains(.command) { parts.append("⌘") }
        parts.append(key.uppercased())
        return parts.joined()
    }
}
