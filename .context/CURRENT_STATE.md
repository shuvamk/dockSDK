# Current State

## Project Overview

DockSDK is the shared dynamic framework that defines the contract between the Superdock host application and all dock plugins. It provides the `DockPlugin` protocol, a service locator (`DockContext`), and seven service classes that give dock plugins access to storage, secure storage, navigation, notifications, UI, logging, and networking. Any third-party developer building a Superdock dock depends on this package.

## Tech Stack

- **Language**: Swift 5.9
- **Platform**: macOS 14.0+ (Sonoma)
- **Distribution**: Swift Package Manager (dynamic library)
- **Frameworks used**: AppKit, Foundation, Security (Keychain), os.log
- **Build tool**: SPM (`swift build`), optionally XcodeGen for Xcode project generation
- **No external dependencies** — the package is entirely self-contained

## Architecture Summary

DockSDK is a single-target SPM package producing a **dynamic** library. The dynamic linking is critical: the Superdock host app embeds the DockSDK dylib, and all dock plugin bundles link against (but do not embed) the same dylib. This ensures a single copy of the `DockPlugin` protocol exists in memory at runtime, which is required for Objective-C `as? DockPlugin` casts to succeed across bundle boundaries.

The architecture follows a **service locator** pattern:

1. **DockPlugin protocol** — the contract every dock's principal class must conform to. Uses `@objc(DockPlugin)` for stable cross-bundle type identity.
2. **DockContext** — instantiated per-dock by the host, providing access to all seven services.
3. **Seven service classes** — each is an `@objc` NSObject subclass with callback hooks the host wires during context creation.

Entry point: There is no single entry point. DockSDK is a library consumed by others. Consumers import it and conform to `DockPlugin`.

## Data Model

DockSDK does not define application data models. Its core entities are:

- **DockPlugin** (protocol) — identity properties (identifier, name, version, description, minimumSDKVersion, icon) plus lifecycle methods (dockDidLoad, createMainView, dockDidBecomeActive, dockDidResignActive, dockWillUnload) plus capability methods (requiredCapabilities, toolbarItems, handleURL, menuItems)
- **DockContext** (class) — holds hostVersion, sdkVersion, isDevMode, dockIdentifier, and references to all seven service instances
- **DockManifest** (class) — parses dock metadata from bundle Info.plist (identifier, name, version, minimumSDKVersion, author, description, bundleURL, iconName)
- **DockSDKVersion** (class) — static version constants (current: "1.0.0")

### Service Classes

| Service | Storage Location | Description |
|---------|-----------------|-------------|
| DockStorage | `~/Library/Application Support/Superdock/DockData/{id}/` | File-based JSON key-value persistence, scoped per dock |
| DockSecureStorage | macOS Keychain | Keychain wrapper scoped by service name `com.superdock.dock.{id}` |
| DockNavigation | In-memory callbacks | Cross-dock navigation requests and URL opening |
| DockNotificationCenter | In-memory observer list | Cross-dock fire-and-forget notification bus with Data payloads |
| DockUIService | Host callbacks | Toasts, confirmation dialogs, sheet presentation |
| DockLogger | os.log + optional callback | Structured logging via Apple's unified logging system |
| DockNetworking | URLSession | Shared HTTP client with callback-based API |

## External Integrations

None. DockSDK has zero external dependencies and makes no third-party API calls. DockNetworking provides a URLSession wrapper that docks use for their own network requests.

## Environment & Infrastructure

### Local Development

```bash
# Build the package
cd DockSDK && swift build

# Run tests (none exist yet)
cd DockSDK && swift test
```

### Integration with Consumers

Consumers reference DockSDK via SPM:

- **Local path** (development): `.package(path: "../DockSDK")`
- **Git URL** (production): `.package(url: "https://github.com/<org>/DockSDK.git", from: "1.0.0")`

Known consumers:
- `superdock/Superdock/project.yml` — host app (embeds the dylib)
- `superdock/Docks/HelloDock/project.yml` — reference dock (links, does not embed)
- `taskdock/TaskDockPlugin/project.yml` — task management dock (links, does not embed)

### Deployment

DockSDK is not deployed independently. It is embedded inside the Superdock.app bundle at `Contents/Frameworks/DockSDK.framework`. Dock plugins find it at runtime via `@executable_path/../Frameworks` or `@loader_path/../Frameworks` runpath search paths.

## Current Status

| Feature | Status |
|---------|--------|
| DockPlugin protocol | Complete — all lifecycle and capability methods defined |
| DockContext service locator | Complete |
| DockStorage (file persistence) | Complete |
| DockSecureStorage (Keychain) | Complete |
| DockNavigation | Complete — callback-based |
| DockNotificationCenter | Complete — thread-safe with concurrent queue |
| DockUIService | Partial — toast and confirmation work, sheet presentation stubbed (callback not wired in host) |
| DockLogger | Complete — os.log + optional host callback |
| DockNetworking | Complete — callback-based, no async/await wrapper |
| DockManifest | Complete |
| SPM Package | Complete — dynamic library, macOS 14+ |
| Unit tests | Not started |
| Documentation | README exists, inline doc comments on all public API |

## Known Issues & Tech Debt

1. **No unit tests** — zero test coverage. The `swift test` target is not configured.
2. **No async/await API** — DockNetworking uses callback-based completion handlers. Should add async wrappers for modern Swift.
3. **DockUIService sheet callbacks not wired** — `onPresentSheet` and `onDismissSheet` are declared but the host does not wire them yet.
4. **DockStorage uses print() for errors** — should use DockLogger instead, but there's a bootstrapping issue (storage is created before logger is available in DockContext init).
5. **DockNotificationCenter observer cleanup** — docks that forget to call `removeAllObservers()` during `dockWillUnload()` will leak observers. No automatic cleanup mechanism.
6. **No version compatibility checking** — `minimumSDKVersion` is declared in the protocol but there's no built-in comparison logic. The host must implement version gating.
7. **Hardcoded User-Agent** — DockNetworking uses `"Superdock/1.0 DockSDK/1.0"` instead of reading from `DockSDKVersion.current`.
8. **Git repository not pushed to remote** — the repo is initialized locally but has no remote configured. Needs to be pushed to a hosting service for production SPM consumption.
9. **Old internal copy still exists** — `superdock/DockSDK/` directory still contains the original pre-extraction source files and xcodeproj. Should be removed once the SPM migration is verified.

## In Progress / Next Steps

- Verify that all three consumers (Superdock, HelloDock, TaskDock) compile successfully with the standalone SPM package
- Push the DockSDK repo to a Git hosting service (GitHub, GitLab, etc.)
- Remove the old internal `superdock/DockSDK/` directory once SPM migration is confirmed
- Add unit tests for core services (DockStorage, DockNotificationCenter, DockManifest)
- Add async/await wrappers to DockNetworking
