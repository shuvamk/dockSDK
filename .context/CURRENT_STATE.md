# Current State

## Project Overview

DockSDK is the shared dynamic framework that defines the contract between the Superdock host application and all dock plugins. It provides the `DockPlugin` protocol, a `DockSpotlightProvider` protocol for dynamic search, a service locator (`DockContext`), seven service classes, and Spotlight-related types. Any third-party developer building a Superdock dock depends on this package.

## Tech Stack

- **Language**: Swift 5.9
- **Platform**: macOS 14.0+ (Sonoma)
- **Distribution**: Swift Package Manager (dynamic library)
- **Frameworks used**: AppKit, Foundation, Security (Keychain), os.log
- **Build tool**: SPM (`swift build`), optionally XcodeGen for Xcode project generation
- **No external dependencies** — the package is entirely self-contained

## Architecture Summary

DockSDK is a single-target SPM package producing a **dynamic** library. The dynamic linking is critical: the Superdock host app embeds the DockSDK dylib, and all dock plugin bundles link against (but do not embed) the same dylib. This ensures a single copy of the `DockPlugin` protocol exists in memory at runtime.

The architecture follows a **service locator** pattern:

1. **DockPlugin protocol** — the contract every dock's principal class must conform to. Uses `@objc(DockPlugin)` for stable cross-bundle type identity.
2. **DockSpotlightProvider protocol** — optional protocol for docks providing dynamic real-time search results to the Spotlight launcher.
3. **DockContext** — instantiated per-dock by the host, providing access to all seven services.
4. **Seven service classes** — each is an `@objc` NSObject subclass with callback hooks.
5. **Spotlight types** — `DockSpotlightAction` (static actions), `DockSpotlightResult` (dynamic results), `DockSpotlightCategory` (category constants), `DockKeyBinding` (keyboard shortcuts).

## Data Model

DockSDK does not define application data models. Its core entities are:

- **DockPlugin** (protocol) — identity, lifecycle, capabilities, key bindings, spotlight actions, spotlight sub-views
- **DockSpotlightProvider** (protocol) — dynamic search, sub-views, lifecycle hooks
- **DockContext** (class) — service locator with hostVersion, sdkVersion, isDevMode, dockIdentifier, 7 services
- **DockManifest** (class) — parses dock metadata from bundle Info.plist
- **DockSDKVersion** (class) — static version constants (current: "1.2.0")
- **DockSpotlightAction** (class) — static quick action with identifier, title, subtitle, icon, keywords, category, priority, shortcutHint, hasDrillDown, inlineResult, iconAccentColor
- **DockSpotlightResult** (class) — dynamic search result with action closure
- **DockSpotlightCategory** (class) — predefined category name constants
- **DockSpotlightProviderInfo** (class) — metadata about a spotlight provider
- **DockKeyBinding** (class) — keyboard shortcut with action closure

### Service Classes

| Service | Storage Location | Description |
|---------|-----------------|-------------|
| DockStorage | `~/Library/Application Support/Superdock/DockData/{id}/` | File-based JSON key-value persistence, scoped per dock |
| DockSecureStorage | macOS Keychain | Keychain wrapper scoped by service name `com.superdock.dock.{id}` |
| DockNavigation | In-memory callbacks | Cross-dock navigation requests and URL opening |
| DockNotificationCenter | In-memory observer list | Cross-dock notification bus with Data payloads |
| DockUIService | Host callbacks | Toasts, confirmation dialogs, sheet presentation |
| DockLogger | os.log + optional callback | Structured logging via Apple's unified logging system |
| DockNetworking | URLSession | Shared HTTP client with callback-based API |

## External Integrations

None.

## Environment & Infrastructure

### Local Development

```bash
cd DockSDK && swift build
```

### Integration with Consumers

Consumers reference DockSDK via SPM:
- **Local path** (development): `.package(path: "../DockSDK")`
- **Git URL** (production): `.package(url: "https://github.com/<org>/DockSDK.git", from: "1.2.0")`

Known consumers: Superdock host, HelloDock, TaskDock.

## Current Status

| Feature | Status |
|---------|--------|
| DockPlugin protocol | Complete — all lifecycle, capability, key binding, and spotlight methods defined |
| DockSpotlightProvider protocol | Complete — searchSpotlight, createSpotlightSubView, lifecycle hooks |
| DockSpotlightAction (enhanced) | Complete — shortcutHint, priority, hasDrillDown, inlineResult, iconAccentColor |
| DockSpotlightResult | Complete — dynamic results with action closures |
| DockSpotlightCategory | Complete — predefined category constants |
| DockContext service locator | Complete |
| DockStorage (file persistence) | Complete |
| DockSecureStorage (Keychain) | Complete |
| DockNavigation | Complete |
| DockNotificationCenter | Complete |
| DockUIService | Partial — sheet callbacks not wired in host |
| DockLogger | Complete |
| DockNetworking | Complete — callback-based |
| DockManifest | Complete |
| SPM Package | Complete — dynamic library, macOS 14+ |
| Unit tests | Not started |
| Documentation | README + inline doc comments |

**Note**: v1.2.0 changes have not been build-verified yet (written in sandbox without Swift compiler). Previous v1.1.0 built cleanly.

## Known Issues & Tech Debt

1. **No unit tests** — zero test coverage
2. **No async/await API** — DockNetworking uses callback-based completion handlers
3. **DockUIService sheet callbacks not wired** in the host
4. **DockStorage uses print() for errors** — should use DockLogger
5. **DockNotificationCenter observer cleanup** — no automatic cleanup when docks unload
6. **No version compatibility checking** — minimumSDKVersion declared but no built-in comparison
7. **Hardcoded User-Agent** — DockNetworking uses static string
8. **Git repository not pushed to remote**
9. **v1.2.0 not build-verified** — needs Xcode compilation check

## In Progress / Next Steps

- Build-verify v1.2.0 with `swift build`
- Push DockSDK repo to Git hosting service
- Add unit tests for core services and new Spotlight types
- Add async/await wrappers to DockNetworking
- Remove old internal `superdock/DockSDK/` directory
