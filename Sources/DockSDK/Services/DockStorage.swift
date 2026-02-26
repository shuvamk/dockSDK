// DockSDK/Sources/Services/DockStorage.swift
//
// File-based key-value persistence scoped to individual docks.

import Foundation

/// Persistent key-value storage for docks.
///
/// Each dock gets its own directory at:
/// `~/Library/Application Support/Superdock/DockData/{identifier}/`
///
/// Keys map to individual JSON files: `{key}.json`.
@objc(DockStorage)
public class DockStorage: NSObject {

    private let storageDirectory: URL

    @objc public init(dockIdentifier: String) {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        self.storageDirectory = appSupport
            .appendingPathComponent("Superdock/DockData")
            .appendingPathComponent(dockIdentifier)
        super.init()

        try? FileManager.default.createDirectory(
            at: storageDirectory,
            withIntermediateDirectories: true
        )
    }

    @objc public func data(forKey key: String) -> Data? {
        let fileURL = storageDirectory.appendingPathComponent(sanitize(key) + ".json")
        return try? Data(contentsOf: fileURL)
    }

    @objc public func set(_ data: Data, forKey key: String) {
        let fileURL = storageDirectory.appendingPathComponent(sanitize(key) + ".json")
        do {
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("[DockStorage] Failed to write key '\(key)': \(error)")
        }
    }

    @objc public func removeData(forKey key: String) {
        let fileURL = storageDirectory.appendingPathComponent(sanitize(key) + ".json")
        try? FileManager.default.removeItem(at: fileURL)
    }

    @objc public func allKeys() -> [String] {
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: storageDirectory,
            includingPropertiesForKeys: nil
        ) else { return [] }

        return contents
            .filter { $0.pathExtension == "json" }
            .map { $0.deletingPathExtension().lastPathComponent }
    }

    private func sanitize(_ key: String) -> String {
        key.replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "\\", with: "_")
            .replacingOccurrences(of: ":", with: "_")
    }
}
