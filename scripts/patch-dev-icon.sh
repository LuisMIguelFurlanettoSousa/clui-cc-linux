#!/usr/bin/env bash
set -euo pipefail

OS="$(uname)"

if [ "$OS" = "Darwin" ]; then
  # ── macOS: patch .icns and re-sign Electron.app ──
  ELECTRON_APP="node_modules/electron/dist/Electron.app"
  RESOURCES="$ELECTRON_APP/Contents/Resources"
  ICON_SRC="resources/icon.icns"

  # Only run if source icon exists
  [[ -f "$ICON_SRC" ]] || exit 0

  # Only run if Electron.app exists
  [[ -d "$ELECTRON_APP" ]] || exit 0

  # Replace the icon
  cp "$ICON_SRC" "$RESOURCES/electron.icns"

  # Touch the bundle to invalidate macOS icon cache
  touch "$ELECTRON_APP"

  # Re-sign with ad-hoc signature (required after modifying bundle contents)
  codesign --force --deep --sign - "$ELECTRON_APP" 2>/dev/null || true

elif [ "$OS" = "Linux" ]; then
  # ── Linux: Electron has no .app bundle, skip icon patching ──
  # The desktop icon is handled by the .desktop file and electron-builder.
  # Nothing to patch for the dev binary.
  echo "Linux detected — skipping Electron dev icon patch (not applicable)."
fi
