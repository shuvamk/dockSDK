# Changelog

## 2026-02-27 — DockSDK v1.2.0: Raycast-Style Spotlight Integration

- Added `DockSpotlightProvider` protocol for docks providing dynamic real-time search results
- Added `DockSpotlightProviderInfo` class for provider metadata
- Enhanced `DockSpotlightAction` with: shortcutHint, priority, hasDrillDown, inlineResult, iconAccentColor
- Added `DockSpotlightResult` class for dynamic search results with action closures
- Added `DockSpotlightCategory` class with predefined category name constants
- Added `createSpotlightSubView(for:)` optional method to DockPlugin protocol
- Updated documentation throughout for v1.2.0 Spotlight integration patterns
- Bumped version from 1.1.0 to 1.2.0

## 2026-02-27 — Context System Initialized

- Created `.context/` directory with CURRENT_STATE.md, DECISIONS.md, ARCHITECTURE.md, CHANGELOG.md, HANDOFF_PROMPT.md, README.md
- Analyzed existing codebase and documented current state
- Documented 8 architectural decisions inferred from code

## 2026-02-27 — DockSDK Extracted to Standalone Repository

- Extracted DockSDK from `superdock/DockSDK/` monorepo into standalone Git repository
- Created `Package.swift` with dynamic library product (macOS 14+)
- Copied all 11 source files (4 core + 7 services) to `Sources/DockSDK/`
- Created README.md with SPM and XcodeGen integration instructions
- Initialized Git repository with initial commit
- Updated all three consumers (Superdock, HelloDock, TaskDock) to reference via SPM local paths
