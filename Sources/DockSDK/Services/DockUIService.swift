// DockSDK/Sources/Services/DockUIService.swift
//
// UI services: toasts, confirmation dialogs, and sheet presentation.

import AppKit

/// Host-provided UI services for docks.
///
/// The host wires callback closures during context creation. If callbacks
/// aren't wired, services fall back to console output or NSAlert.
@objc(DockUIService)
public class DockUIService: NSObject {

    // MARK: - Toast Callbacks

    /// Callback set by the host to display a toast notification.
    /// Parameters: (message, style) where style is 0=info, 1=success, 2=warning, 3=error.
    @objc public var onShowToast: ((String, Int) -> Void)?

    // MARK: - Confirmation Callbacks

    /// Callback set by the host to show a confirmation dialog.
    /// Parameters: (title, message, confirmTitle). Returns true if confirmed.
    @objc public var onShowConfirmation: ((String, String, String) -> Bool)?

    // MARK: - Sheet Callbacks (not yet wired in host)

    @objc public var onPresentSheet: ((NSView) -> Void)?
    @objc public var onDismissSheet: (() -> Void)?

    // MARK: - Public API

    /// Show a toast notification in the host window.
    ///
    /// - Parameters:
    ///   - message: The message to display.
    ///   - style: 0 = info, 1 = success, 2 = warning, 3 = error.
    @objc public func showToast(message: String, style: Int) {
        if let handler = onShowToast {
            handler(message, style)
        } else {
            let styleNames = ["INFO", "SUCCESS", "WARNING", "ERROR"]
            let styleName = style >= 0 && style < styleNames.count ? styleNames[style] : "UNKNOWN"
            print("[Toast:\(styleName)] \(message)")
        }
    }

    /// Show a confirmation dialog.
    ///
    /// - Parameters:
    ///   - title: The dialog title.
    ///   - message: The dialog message body.
    ///   - confirmTitle: The text for the confirm button (e.g. "Delete", "Proceed").
    /// - Returns: `true` if the user confirmed, `false` if cancelled.
    @objc public func showConfirmation(title: String, message: String, confirmTitle: String) -> Bool {
        if let handler = onShowConfirmation {
            return handler(title, message, confirmTitle)
        }

        // Fallback: use NSAlert directly
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.addButton(withTitle: confirmTitle)
        alert.addButton(withTitle: "Cancel")
        alert.alertStyle = .warning
        return alert.runModal() == .alertFirstButtonReturn
    }

    /// Present a sheet in the host window.
    @objc public func presentSheet(_ view: NSView) {
        if let handler = onPresentSheet {
            handler(view)
        } else {
            print("[DockUIService] presentSheet ignored — no handler wired")
        }
    }

    /// Dismiss the currently presented sheet.
    @objc public func dismissSheet() {
        if let handler = onDismissSheet {
            handler()
        } else {
            print("[DockUIService] dismissSheet ignored — no handler wired")
        }
    }
}
