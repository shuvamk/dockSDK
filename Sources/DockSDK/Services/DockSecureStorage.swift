// DockSDK/Sources/Services/DockSecureStorage.swift
//
// macOS Keychain wrapper for storing dock secrets.

import Foundation
import Security

/// Keychain-backed secure storage for sensitive data.
///
/// Entries are scoped by service name: `com.superdock.dock.{identifier}`.
/// Each key maps to an account name within that service.
@objc(DockSecureStorage)
public class DockSecureStorage: NSObject {

    private let serviceName: String

    @objc public init(dockIdentifier: String) {
        self.serviceName = "com.superdock.dock.\(dockIdentifier)"
        super.init()
    }

    @objc public func set(_ value: String, forKey key: String) {
        let data = Data(value.utf8)

        // Remove existing entry first
        delete(forKey: key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked,
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            print("[DockSecureStorage] Failed to store key '\(key)': \(status)")
        }
    }

    @objc public func string(forKey key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    @objc public func delete(forKey key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
        ]
        SecItemDelete(query as CFDictionary)
    }
}
