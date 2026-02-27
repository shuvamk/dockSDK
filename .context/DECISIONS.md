# Decisions

## 2026-02-27: DockSpotlightProvider as Separate Protocol

- **Context**: The Spotlight launcher needs docks to provide dynamic, real-time search results. Static actions (`spotlightActions()`) are registered once, but dynamic results must be generated per-keystroke.
- **Options considered**:
  1. Add `searchSpotlight(query:)` to DockPlugin directly (forces all docks to implement it)
  2. Separate `DockSpotlightProvider` protocol (chosen — opt-in)
  3. Callback-based registration on DockContext
- **Decision**: Separate `@objc(DockSpotlightProvider)` protocol. Docks that want dynamic search conform to both `DockPlugin` and `DockSpotlightProvider`. The host checks `dock.plugin as? DockSpotlightProvider` at search time.
- **Tradeoffs**: Opt-in complexity, clean separation, backward compatibility. But two protocols for full Spotlight integration, and runtime type checking is less discoverable.
- **Affected areas**: DockSpotlightProvider.swift (new), SpotlightManager.queryDockProviders(), HelloDockPlugin (reference impl)

## 2026-02-27: DockSpotlightResult with Non-@objc Action Closure

- **Context**: Dynamic search results need to carry an action closure, but Swift closures aren't representable in Objective-C.
- **Options considered**:
  1. Target-action pattern with @objc selectors (too rigid)
  2. Non-@objc closure property on an @objc class (chosen — same as DockKeyBinding)
  3. Identifier-based dispatch through executeSpotlightAction
- **Decision**: `DockSpotlightResult.action` is a non-@objc `(() -> Void)?` property with a fluent `.onAction()` setter. Same pattern established by `DockKeyBinding`.
- **Tradeoffs**: Simple API, consistent with existing patterns. But action can only be set/called from Swift code, not from ObjC-only consumers.
- **Affected areas**: DockSpotlightResult class, SpotlightManager result collection

## 2026-02-27: Extract DockSDK into Standalone Swift Package

- **Context**: DockSDK was originally an Xcode framework project embedded inside the Superdock monorepo (`superdock/DockSDK/`). Third-party dock developers had to either clone the entire Superdock repo or manually copy the framework. Adding TaskDock (a new dock in a sibling directory) caused "No such module 'DockSDK'" errors, and the first fix — adding TaskDock to the Superdock workspace — was rejected because it broke the core principle of independent dock development.
- **Options considered**:
  1. Add all docks to the Superdock workspace (rejected — couples docks to host)
  2. Pre-built XCFramework distributed as a binary artifact
  3. Swift Package Manager Git repo (chosen)
  4. Both SPM + XCFramework for different workflows
- **Decision**: Extract DockSDK into its own Git repository with a `Package.swift` producing a dynamic library. All consumers (Superdock host, HelloDock, TaskDock, future docks) declare it as an SPM dependency — local `path:` for development, `url:` for production.
- **Tradeoffs**: Gained true independence for dock developers (any dock can be built without cloning the host repo). Added a dependency management step (SPM resolution). Requires DockSDK to be hosted on a Git service for non-local consumption.
- **Affected areas**: Package.swift, all consumer project.yml files, SuperdockWorkspace.xcworkspace, build pipeline

## Pre-history: Dynamic Library Requirement

- **Context**: Superdock loads dock plugins as `.dock` bundles (renamed `.bundle`) at runtime using `NSBundle` dynamic loading. The host casts each bundle's principal class to `DockPlugin` using `as? DockPlugin`.
- **Options considered**:
  1. Static linking (each bundle gets its own copy of DockSDK types)
  2. Dynamic linking (single shared copy at runtime)
- **Decision**: DockSDK must be built as a dynamic library (`type: .dynamic` in Package.swift). This is enforced in the package definition.
- **Tradeoffs**: Dynamic linking adds framework embedding complexity (host must embed, docks must not). But it's strictly required — static linking causes `as? DockPlugin` casts to silently return `nil` because the Objective-C runtime sees different protocol metadata in each bundle.
- **Affected areas**: Package.swift `type: .dynamic`, host project embedding settings, dock runpath search paths

## Pre-history: @objc Protocol with Stable Runtime Names

- **Context**: Swift's name mangling produces module-qualified type names. When `DockPlugin` is defined in module A and checked in module B (a dynamically loaded bundle), the Swift runtime treats them as different types even if the source is identical.
- **Options considered**:
  1. Pure Swift protocols (fails across bundle boundaries)
  2. `@objc` protocols with explicit `@objc(Name)` annotations (chosen)
  3. C-level plugin interface (too low-level)
- **Decision**: All public types use `@objc(StableName)` annotations — e.g., `@objc(DockPlugin)`, `@objc(DockContext)`, `@objc(DockStorage)`, etc. This gives them fixed Objective-C runtime names that work across bundle boundaries.
- **Tradeoffs**: Constrains the API to types representable in Objective-C (NSObject inheritance, no generics, no Swift-only features in the protocol). Gained reliable cross-bundle type casting.
- **Affected areas**: Every public class and the DockPlugin protocol

## Pre-history: Service Locator Pattern via DockContext

- **Context**: Dock plugins need access to host services (storage, logging, navigation, etc.) but shouldn't directly depend on host internals.
- **Options considered**:
  1. Dependency injection via protocol (more flexible, more boilerplate)
  2. Service locator object (chosen — single object passed to docks)
  3. Global singletons (breaks scoping per dock)
- **Decision**: `DockContext` acts as a service locator. The host creates one per dock, wires callback closures on the service objects, and passes it to `dockDidLoad(context:)`. Each service is scoped to the dock's identifier.
- **Tradeoffs**: Simple API for dock developers (one object, seven properties). But it's not easily mockable for testing — dock developers can't substitute test doubles without subclassing the concrete service classes.
- **Affected areas**: DockContext.swift, all seven service classes, DockPlugin protocol lifecycle

## Pre-history: File-Based JSON Storage

- **Context**: Docks need persistent storage for their data.
- **Options considered**:
  1. UserDefaults with suite names (limited to property list types)
  2. CoreData (heavy, complex for plugin use)
  3. SQLite per dock (overkill for most use cases)
  4. File-based JSON persistence (chosen)
- **Decision**: `DockStorage` writes each key as a separate `.json` file under `~/Library/Application Support/Superdock/DockData/{identifier}/`. Keys are sanitized to remove path-unsafe characters.
- **Tradeoffs**: Simple, human-readable, no schema management. But no transactional guarantees, no query capability, and performance degrades with many small files. Docks needing more can use their own storage (SQLite, CoreData) independently.
- **Affected areas**: DockStorage.swift, file system layout

## Pre-history: Callback-Based Service Wiring

- **Context**: Services like DockNavigation, DockUIService, and DockLogger need to communicate back to the host, but the SDK shouldn't depend on host types.
- **Options considered**:
  1. Delegate protocols (more type-safe, more code)
  2. Closure callbacks on service objects (chosen)
  3. NotificationCenter (too loose, hard to trace)
- **Decision**: Each service exposes optional callback properties (`onNavigationRequest`, `onShowToast`, `onLogEntry`, etc.) that the host sets during context creation. If callbacks aren't wired, services fall back to console output or direct AppKit calls.
- **Tradeoffs**: Very simple to implement and understand. But callbacks are untyped at the ObjC boundary and there's no compile-time guarantee that the host wires all of them.
- **Affected areas**: DockNavigation, DockUIService, DockLogger, DockNotificationCenter

## Pre-history: macOS 14 (Sonoma) Minimum Deployment Target

- **Context**: Need to choose a minimum macOS version for the SDK.
- **Options considered**:
  1. macOS 12 (broader compatibility)
  2. macOS 13 (Ventura — reasonable middle ground)
  3. macOS 14 (Sonoma — chosen, enables latest SwiftUI features)
- **Decision**: macOS 14.0 minimum, matching the host app's deployment target.
- **Tradeoffs**: Limits the user base to Sonoma or later. Gains access to modern SwiftUI features (Observable macro, etc.) and the latest AppKit improvements.
- **Affected areas**: Package.swift platforms, all consumer project.yml deploymentTarget settings

## Pre-history: Dock Bundle Extension (.dock)

- **Context**: Dock plugins are macOS bundles loaded at runtime. Need a file extension.
- **Options considered**:
  1. `.bundle` (standard, but ambiguous)
  2. `.plugin` (common in macOS plugin architectures)
  3. `.dock` (custom, chosen)
- **Decision**: Use `.dock` as the bundle extension, set via `WRAPPER_EXTENSION: dock` in XcodeGen project.yml. The host scans for `.dock` files in its PlugIns directory.
- **Tradeoffs**: Custom extension makes Superdock docks immediately identifiable. But macOS doesn't natively recognize `.dock` files, so Finder won't show a custom icon without additional UTI declarations.
- **Affected areas**: Dock project.yml files (WRAPPER_EXTENSION), host bundle loading code, install scripts
