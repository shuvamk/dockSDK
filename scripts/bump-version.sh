#!/bin/bash
# scripts/bump-version.sh
#
# Bumps the DockSDK version, commits, tags, and optionally pushes.
#
# Usage:
#   ./scripts/bump-version.sh <version>           # e.g. 1.3.0
#   ./scripts/bump-version.sh <version> --push    # also pushes to remote
#
# What it does:
#   1. Updates SDKVersion.swift with the new version
#   2. Commits the change
#   3. Creates a git tag (e.g. 1.3.0)
#   4. If --push: pushes commit + tag to origin

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
VERSION_FILE="$ROOT_DIR/Sources/DockSDK/SDKVersion.swift"

# --- Argument parsing ---

if [ $# -lt 1 ]; then
    echo "Usage: $0 <version> [--push]"
    echo "  Example: $0 1.3.0"
    echo "  Example: $0 1.3.0 --push"
    exit 1
fi

NEW_VERSION="$1"
SHOULD_PUSH=false

if [ "${2:-}" = "--push" ]; then
    SHOULD_PUSH=true
fi

# --- Validate semver format ---

if ! echo "$NEW_VERSION" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$'; then
    echo "Error: Version must be in semver format (e.g. 1.3.0)"
    exit 1
fi

IFS='.' read -r MAJOR MINOR PATCH <<< "$NEW_VERSION"

# --- Check for clean working tree ---

cd "$ROOT_DIR"

if [ -n "$(git status --porcelain)" ]; then
    echo "Error: Working tree is not clean. Commit or stash your changes first."
    exit 1
fi

# --- Check tag doesn't already exist ---

if git rev-parse "$NEW_VERSION" >/dev/null 2>&1; then
    echo "Error: Tag '$NEW_VERSION' already exists."
    exit 1
fi

# --- Show current version ---

CURRENT_VERSION=$(grep 'static let current' "$VERSION_FILE" | sed 's/.*"\(.*\)".*/\1/')
echo "DockSDK version bump: $CURRENT_VERSION → $NEW_VERSION"
echo ""

# --- Update SDKVersion.swift ---

cat > "$VERSION_FILE" << EOF
// DockSDK/Sources/SDKVersion.swift
//
// DockSDK version constants.

import Foundation

@objc(DockSDKVersion)
public class DockSDKVersion: NSObject {
    @objc public static let current: String = "$NEW_VERSION"
    @objc public static let major: Int = $MAJOR
    @objc public static let minor: Int = $MINOR
    @objc public static let patch: Int = $PATCH
}
EOF

echo "  Updated SDKVersion.swift"

# --- Commit ---

git add "$VERSION_FILE"
git commit -m "Bump DockSDK version to $NEW_VERSION"
echo "  Committed"

# --- Tag ---

git tag "$NEW_VERSION"
echo "  Tagged $NEW_VERSION"

# --- Push ---

if [ "$SHOULD_PUSH" = true ]; then
    git push origin main
    git push origin "$NEW_VERSION"
    echo "  Pushed to origin (commit + tag)"
else
    echo ""
    echo "  Not pushed. Run: git push origin main && git push origin $NEW_VERSION"
fi

echo ""
echo "Done! Consumers can now update to DockSDK $NEW_VERSION."
echo "In project.yml / Package.swift, update: from: \"$NEW_VERSION\""
