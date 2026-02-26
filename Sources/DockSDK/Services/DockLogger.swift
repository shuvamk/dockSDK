// DockSDK/Sources/Services/DockLogger.swift
//
// Structured logging via Apple's unified logging system (os.log).

import Foundation
import os.log

/// Structured logging service for docks.
///
/// Uses Apple's `os.log` system. The host can also hook `onLogEntry`
/// to capture log entries for a dev console.
@objc(DockLogger)
public class DockLogger: NSObject {

    private let dockIdentifier: String
    private let osLog: OSLog

    /// Callback set by the host to capture log entries.
    /// Parameters: (level, identifier, message).
    @objc public var onLogEntry: ((String, String, String) -> Void)?

    @objc public init(dockIdentifier: String) {
        self.dockIdentifier = dockIdentifier
        self.osLog = OSLog(subsystem: "com.superdock.dock.\(dockIdentifier)", category: "dock")
        super.init()
    }

    @objc public func debug(_ message: String) {
        os_log(.debug, log: osLog, "%{public}@", message)
        onLogEntry?("DEBUG", dockIdentifier, message)
    }

    @objc public func info(_ message: String) {
        os_log(.info, log: osLog, "%{public}@", message)
        onLogEntry?("INFO", dockIdentifier, message)
    }

    @objc public func warning(_ message: String) {
        os_log(.default, log: osLog, "%{public}@", message)
        onLogEntry?("WARNING", dockIdentifier, message)
    }

    @objc public func error(_ message: String) {
        os_log(.error, log: osLog, "%{public}@", message)
        onLogEntry?("ERROR", dockIdentifier, message)
    }
}
