// DockSDK/Sources/Services/DockNotificationCenter.swift
//
// Cross-dock notification bus for fire-and-forget messaging.

import Foundation

/// Cross-dock notification system.
///
/// Docks can post named notifications with optional Data payloads,
/// and observe notifications from other docks. Observers are identified
/// by opaque tokens returned from `observe(name:handler:)`.
@objc(DockNotificationCenter)
public class DockNotificationCenter: NSObject {

    /// Represents an active observation. Call `remove(observer:)` to unsubscribe.
    @objc(DockNotificationObserver)
    public class Observer: NSObject {
        let name: String
        let handler: (Data?) -> Void
        let id: UUID

        init(name: String, handler: @escaping (Data?) -> Void) {
            self.name = name
            self.handler = handler
            self.id = UUID()
            super.init()
        }
    }

    private var observers: [Observer] = []
    private let queue = DispatchQueue(label: "com.superdock.notifications", attributes: .concurrent)

    /// Post a notification to all observers of the given name.
    ///
    /// - Parameters:
    ///   - name: The notification name (typically reverse-DNS).
    ///   - payload: Optional data payload.
    @objc public func post(name: String, payload: Data?) {
        queue.sync {
            let matching = observers.filter { $0.name == name }
            for observer in matching {
                DispatchQueue.main.async {
                    observer.handler(payload)
                }
            }
        }
    }

    /// Observe notifications with the given name.
    ///
    /// - Parameters:
    ///   - name: The notification name to observe.
    ///   - handler: Called on the main thread when a matching notification is posted.
    /// - Returns: An observer token. Pass to `remove(observer:)` to stop observing.
    @objc public func observe(name: String, handler: @escaping (Data?) -> Void) -> Observer {
        let observer = Observer(name: name, handler: handler)
        queue.async(flags: .barrier) {
            self.observers.append(observer)
        }
        return observer
    }

    /// Remove a previously registered observer.
    @objc public func remove(observer: Observer) {
        queue.async(flags: .barrier) {
            self.observers.removeAll { $0.id == observer.id }
        }
    }

    /// Remove all observers. Called during dock unload.
    @objc public func removeAllObservers() {
        queue.async(flags: .barrier) {
            self.observers.removeAll()
        }
    }
}
