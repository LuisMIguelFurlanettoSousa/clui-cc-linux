#!/bin/bash
# Fix Electron sandbox permissions after .deb install
SANDBOX="/opt/Clui CC/chrome-sandbox"
if [ -f "$SANDBOX" ]; then
  chown root:root "$SANDBOX"
  chmod 4755 "$SANDBOX"
fi
