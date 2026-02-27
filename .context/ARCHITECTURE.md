# Architecture

## Directory Structure

```
DockSDK/
├── .context/                    # LLM context management (this directory)
│   ├── ARCHITECTURE.md          # This file — technical reference
│   ├── CHANGELOG.md             # Change history
│   ├── CURRENT_STATE.md         # Project overview and status
│   ├── DECISIONS.md             # Architectural decision records
│   ├── HANDOFF_PROMPT.md        # Session-end handoff instructions
│   ├── README.md                # Guide to using .context/
│   └── sessions/                # Per-session logs (archival)
├── .gitignore                   # Ignores .build/, .swiftpm/, DerivedData/, etc.
├── Package.swift                # SPM package definition (dynamic library)
├── README.md                    # Usage instructions for dock developers
└── Sources/
    └── DockSDK/
        ├── DockPlugin.swift             # Core protocol — the contract every dock implements
        ├── DockContext.swift             # Service locator passed to docks at load time
        ├── DockManifest.swift           # Info.plist metadata parser for dock bundles
        ├── SDKVersion.swift             # Static version constants (1.2.0)
        ├── DockKeyBinding.swift         # Keyboard shortcut type with action closure
        ├── DockSpotlightAction.swift    # Static spotlight action + DockSpotlightResult + DockSpotlightCategory
        ├── DockSpotlightProvider.swift  # Protocol for dynamic real-time spotlight search
        └── Services/
            ├── DockStorage.swift           # File-based JSON key-value persistence
            ├── DockSecureStorage.swift      # macOS Keychain wrapper
            ├── DockNavigation.swift         # Cross-dock navigation requests
            ├── DockNotificationCenter.swift # Cross-dock notification bus
            ├── DockUIService.swift          # Toasts, confirmations, sheets
            ├── DockLogger.swift             # Structured logging (os.log)
            └── DockNetworking.swift         # Shared URLSession wrapper
```

## Key Abstractions

### DockPlugin (protocol)

The single most important type. Every dock's principal class must:
1. Inherit from `NSObject`
2. Conform to `DockPlugin`
3. Use `@objc(ClassName)` matching `NSPrincipalClass` in Info.plist
4. Implement required properties: `identifier`, `name`, `version`, `dockDescription`, `minimumSDKVersion`, `icon`
5. Implement required methods: `init()`, `dockDidLoad(context:)`, `createMainView() -> NSView`
6. Optionally implement: `dockDidBecomeActive()`, `dockDidResignActive()`, `dockWillUnload()`, `requiredCapabilities`, `toolbarItems()`, `handleURL(_:)`, `menuItems()`

### DockContext (class)

Service locator created by the host for each dock. Contains seven service properties plus metadata (hostVersion, sdkVersion, isDevMode, dockIdentifier). All services are scoped to the dock's identifier.

### Service Classes

All services follow the same pattern:
- `@objc(ServiceName)` annotation for cross-bundle stability
- Inherit from `NSObject`
- Optional callback closures (e.g., `onNavigationRequest`, `onShowToast`) that the host wires before passing the context to the dock
- Fallback behavior when callbacks aren't wired (console output or direct AppKit calls)

### DockManifest (class)

Parses custom Info.plist keys: `DockIdentifier`, `DockName`, `DockVersion`, `DockMinimumSDKVersion`, `DockAuthor`, `DockDescription`, `DockIconName`. Falls back to standard CFBundle keys when custom keys are absent.

## Conventions

### Naming

- **Files**: PascalCase matching the primary type they contain (e.g., `DockStorage.swift` contains `class DockStorage`)
- **Types**: PascalCase, prefixed with `Dock` (e.g., `DockPlugin`, `DockContext`, `DockStorage`)
- **Properties/Methods**: camelCase
- **ObjC names**: Match Swift names exactly via `@objc(Name)` annotations
- **Service scoping**: Uses reverse-DNS dock identifier for namespacing (e.g., `com.superdock.dock.{identifier}`)

### Import Pattern

Each file imports only what it needs:
- `Foundation` — most files
- `AppKit` — files using NSView, NSImage, NSAlert, NSMenuItem (DockPlugin, DockUIService)
- `Security` — DockSecureStorage (Keychain APIs)
- `os.log` — DockLogger

### Error Handling

- Services use `print()` for error logging (tech debt — should use DockLogger)
- `try?` is used throughout for non-critical operations (file I/O, directory creation)
- No custom error types defined
- Keychain operations log `SecItemAdd` status codes on failure

### Configuration / Environment Variables

None. DockSDK is a pure library with no runtime configuration. All configuration flows through `DockContext` properties set by the host at initialization time.

## Data Flow

### Flow 1: Dock Loading (host → SDK → dock)

```
Host scans PlugIns/ for .dock bundles
  → NSBundle(url:).load()
  → NSBundle.principalClass → as? DockPlugin.Type
  → DockPlugin.init()
  → Host creates DockContext(hostVersion:sdkVersion:isDevMode:dockIdentifier:)
  → Host wires callbacks on context.navigation, context.ui, context.logger
  → Host calls dock.dockDidLoad(context:)
  → Dock stores context reference
  → Host calls dock.createMainView() when dock is first activated
  → NSView returned, host inserts into content area
```

### Flow 2: Dock Persisting Data (dock → SDK → filesystem)

```
Dock calls context.storage.set(data, forKey: "tasks")
  → DockStorage sanitizes key ("tasks" → "tasks")
  → Writes to ~/Library/Application Support/Superdock/DockData/{id}/tasks.json
  → Atomic write (Data.write options: .atomic)

Dock calls context.storage.data(forKey: "tasks")
  → DockStorage reads ~/Library/Application Support/Superdock/DockData/{id}/tasks.json
  → Returns Data? (nil if file doesn't exist)
```

### Flow 3: Cross-Dock Navigation (dock → SDK → host → target dock)

```
Dock A calls context.navigation.navigate(to: "com.superdock.dock-b")
  → DockNavigation.onNavigationRequest?("com.superdock.dock-b")
  → Host receives callback, activates Dock B
  → Host calls dockA.dockDidResignActive()
  → Host calls dockB.dockDidBecomeActive()
```

### Flow 4: Cross-Dock Notification (dock → SDK → other docks)

```
Dock A calls context.notifications.post(name: "taskCompleted", payload: jsonData)
  → DockNotificationCenter iterates observers matching "taskCompleted"
  → Each observer.handler(jsonData) dispatched on main thread
  → Dock B's handler fires with the payload
```

## Key Files

| File | Description |
|------|-------------|
| `Package.swift` | SPM package definition — dynamic library, macOS 14+, single target |
| `Sources/DockSDK/DockPlugin.swift` | The core protocol every dock must conform to. Defines identity, lifecycle, and capability methods |
| `Sources/DockSDK/DockContext.swift` | Service locator class — instantiated per-dock, provides access to all seven services |
| `Sources/DockSDK/DockManifest.swift` | Parses dock metadata from Info.plist custom keys with CFBundle fallbacks |
| `Sources/DockSDK/SDKVersion.swift` | Static version constants (1.0.0) |
| `Sources/DockSDK/Services/DockStorage.swift` | File-based JSON persistence at ~/Library/Application Support/Superdock/DockData/{id}/ |
| `Sources/DockSDK/Services/DockSecureStorage.swift` | macOS Keychain wrapper scoped by service name |
| `Sources/DockSDK/Services/DockNavigation.swift` | Cross-dock navigation and URL opening via host callbacks |
| `Sources/DockSDK/Services/DockNotificationCenter.swift` | Thread-safe notification bus with concurrent dispatch queue |
| `Sources/DockSDK/Services/DockUIService.swift` | Toast, confirmation dialog, and sheet presentation via host callbacks |
| `Sources/DockSDK/Services/DockLogger.swift` | Structured logging via os.log with optional host callback capture |
| `Sources/DockSDK/Services/DockNetworking.swift` | Shared URLSession with callback-based data fetching |
| `README.md` | Quick-start guide for dock developers with SPM and XcodeGen instructions |

## Testing

**No tests exist yet.** The package has no test target configured. Priority areas for testing:

1. `DockStorage` — file write/read/delete/allKeys with sanitization
2. `DockNotificationCenter` — observer registration, posting, removal, thread safety
3. `DockManifest` — Info.plist parsing with various key combinations
4. `DockSecureStorage` — Keychain operations (requires macOS runtime)

To add tests, add a test target to `Package.swift`:
```swift
.testTarget(name: "DockSDKTests", dependencies: ["DockSDK"], path: "Tests/DockSDKTests")
```

## Build & Deploy

### Build

```bash
cd DockSDK
swift build                    # Debug build
swift build -c release         # Release build
```

Output: `.build/debug/` or `.build/release/` containing the dynamic library.

### Integration with XcodeGen consumers

Consumers using XcodeGen add DockSDK to their `project.yml`:

```yaml
packages:
  DockSDK:
    path: ../DockSDK          # relative path from project.yml location

targets:
  MyDock:
    dependencies:
      - package: DockSDK
        product: DockSDK
```

Then run `xcodegen generate` to produce an Xcode project with the SPM dependency.

### Deployment

DockSDK is not deployed on its own. The Superdock host app embeds it (`embed: true` in project.yml). Dock bundles link against it but do not embed (`embed: false` or omitted). At runtime, dock bundles find the dylib via runpath search paths:

```
@executable_path/../Frameworks    (for the host)
@loader_path/../Frameworks        (for dock bundles)
```

### Future: Remote SPM Distribution

Once pushed to a Git hosting service, consumers can reference it by URL:

```swift
.package(url: "https://github.com/<org>/DockSDK.git", from: "1.0.0")
```

Or in XcodeGen:

```yaml
packages:
  DockSDK:
    url: https://github.com/<org>/DockSDK.git
    from: "1.0.0"
```
