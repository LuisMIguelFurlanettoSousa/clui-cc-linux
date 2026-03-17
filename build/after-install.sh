#!/bin/bash
# Fix Electron sandbox permissions after .deb install
for SANDBOX in "/opt/Clui CC/chrome-sandbox" "/opt/clui-cc/chrome-sandbox"; do
  if [ -f "$SANDBOX" ]; then
    chown root:root "$SANDBOX"
    chmod 4755 "$SANDBOX"
  fi
done
