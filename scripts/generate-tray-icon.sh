#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────────────
# generate-tray-icon.sh
#
# No macOS, tray icons usam o prefixo "Template" (trayTemplate.png).
# No Linux, tray icons devem ser PNGs comuns sem esse prefixo.
#
# Este script copia trayTemplate.png para tray-icon.png para uso no Linux.
# Se trayTemplate.png não existir, usa icon.png como fallback.
# ──────────────────────────────────────────────────────────────────────────────
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

RESOURCES="$PROJECT_ROOT/resources"
TRAY_TEMPLATE="$RESOURCES/trayTemplate.png"
TRAY_TEMPLATE_2X="$RESOURCES/trayTemplate@2x.png"
TRAY_OUTPUT="$RESOURCES/tray-icon.png"

if [ -f "$TRAY_TEMPLATE_2X" ]; then
  cp "$TRAY_TEMPLATE_2X" "$TRAY_OUTPUT"
  echo "Tray icon criado a partir de trayTemplate@2x.png → tray-icon.png"
elif [ -f "$TRAY_TEMPLATE" ]; then
  cp "$TRAY_TEMPLATE" "$TRAY_OUTPUT"
  echo "Tray icon criado a partir de trayTemplate.png → tray-icon.png"
else
  echo "AVISO: trayTemplate.png não encontrado."
  echo "No Linux, o app usará resources/icon.png como tray icon."

  # Copia icon.png como fallback
  if [ -f "$RESOURCES/icon.png" ]; then
    cp "$RESOURCES/icon.png" "$TRAY_OUTPUT"
    echo "Fallback: icon.png → tray-icon.png"
  fi
fi
