# DockSDK

The shared framework that defines the contract between the **Superdock** host application and dock plugins.

## What is this?

DockSDK provides:

- **`DockPlugin`** protocol — the single interface every dock must conform to
- **`DockContext`** — service locator giving docks access to storage, logging, navigation, notifications, UI, and networking
- **7 service classes** — `DockStorage`, `DockSecureStorage`, `DockNavigation`, `DockNotificationCenter`, `DockUIService`, `DockLogger`, `DockNetworking`
- **`DockManifest`** — metadata parser for dock bundle Info.plist

## Adding DockSDK to your dock

### Swift Package Manager (recommended)

In your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/<org>/DockSDK.git", from: "1.0.0"),
],
targets: [
    .target(name: "MyDock", dependencies: ["DockSDK"]),
]
```

Or for local development alongside the Superdock repo:

```swift
dependencies: [
    .package(path: "../DockSDK"),
],
```

### XcodeGen

In your dock's `project.yml`:

```yaml
packages:
  DockSDK:
    path: "../DockSDK"  # or url + version for remote

targets:
  MyDock:
    dependencies:
      - package: DockSDK
        product: DockSDK
```

## Critical: Dynamic linking

DockSDK **must** be linked as a dynamic library. The `Package.swift` enforces this with `type: .dynamic`. If you link statically, the Objective-C runtime sees different copies of the `DockPlugin` protocol in the host and dock bundles, and `as? DockPlugin` casts silently return `nil`.

## Quick start

```swift
import AppKit
import SwiftUI
import DockSDK

@objc(MyDockPlugin)
class MyDockPlugin: NSObject, DockPlugin {
    var identifier: String { "com.example.my-dock" }
    var name: String { "My Dock" }
    var version: String { "1.0.0" }
    var dockDescription: String { "A custom dock." }
    var minimumSDKVersion: String { "1.0.0" }
    var icon: NSImage? { nil }

    private var context: DockContext?

    required override init() { super.init() }

    func dockDidLoad(context: DockContext) {
        self.context = context
        context.logger.info("My dock loaded!")
    }

    func createMainView() -> NSView {
        NSHostingView(rootView: Text("Hello from My Dock!"))
    }
}
```

## Version

Current: **1.0.0**
