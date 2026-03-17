#!/bin/bash
set -e
cd "$(dirname "$0")"

# ── Helpers ──

fail=0
INSTALL_WHISPER=0

for arg in "$@"; do
  case "$arg" in
    --with-voice)
      INSTALL_WHISPER=1
      ;;
    --help|-h)
      echo "Usage: ./start.sh [--with-voice]"
      echo
      echo "  --with-voice   Install openai-whisper via pip before launch."
      exit 0
      ;;
  esac
done

step() {
  echo
  echo "--- $1"
}

pass() {
  echo "  OK: $1"
}

fail() {
  echo "  FAIL: $1"
  fail=1
}

fix() {
  echo
  echo "  To fix, copy and run this command:"
  echo
  echo "    $1"
  echo
}

fix_block() {
  echo
  echo "  To fix, run these commands one at a time:"
  echo
  while [ $# -gt 0 ]; do
    echo "    $1"
    shift
  done
  echo
}

# ── Version helpers ──

# Compare two dotted versions: returns 0 if $1 >= $2
version_gte() {
  [ "$(printf '%s\n%s' "$1" "$2" | sort -V | head -1)" = "$2" ]
}

# ── Detect package manager ──

pkg_install_hint() {
  if command -v apt &>/dev/null; then
    echo "sudo apt install $1"
  elif command -v dnf &>/dev/null; then
    echo "sudo dnf install $1"
  elif command -v pacman &>/dev/null; then
    echo "sudo pacman -S $1"
  else
    echo "Install '$1' using your distribution's package manager"
  fi
}

# ── Preflight Checks ──

step "Checking environment"

# 0. Linux
if [ "$(uname)" != "Linux" ]; then
  fail "This script is intended for Linux. Detected: $(uname). Use start.command for macOS."
else
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    pass "Linux ($PRETTY_NAME)"
  else
    pass "Linux ($(uname -r))"
  fi
fi

# 1. Node
if command -v node &>/dev/null; then
  node_ver=$(node --version | sed 's/^v//')
  if version_gte "$node_ver" "18.0.0"; then
    pass "Node.js v$node_ver"
  else
    fail "Node.js v$node_ver is too old. Clui CC requires Node 18+."
    fix "$(pkg_install_hint nodejs)"
  fi
else
  fail "Node.js is not installed."
  fix "$(pkg_install_hint nodejs)"
fi

# 2. npm
if command -v npm &>/dev/null; then
  pass "npm $(npm --version)"
else
  fail "npm is not installed (should come with Node.js)."
  fix "$(pkg_install_hint npm)"
fi

# 3. Python 3
if command -v python3 &>/dev/null; then
  pass "Python $(python3 --version 2>&1 | awk '{print $2}')"
else
  fail "Python 3 is not installed."
  fix "$(pkg_install_hint python3)"
fi

# 4. build-essential (gcc/g++)
if command -v g++ &>/dev/null; then
  gver=$(g++ --version 2>&1 | head -1)
  pass "g++ available ($gver)"
else
  fail "g++ not found. Build tools are required for native modules."
  fix "$(pkg_install_hint build-essential)"
fi

# 6. C++ headers probe
if command -v g++ &>/dev/null; then
  PROBE_DIR=$(mktemp -d)
  PROBE_FILE="$PROBE_DIR/probe.cpp"
  echo '#include <functional>' > "$PROBE_FILE"
  echo 'int main() { return 0; }' >> "$PROBE_FILE"
  if g++ -std=c++17 -c "$PROBE_FILE" -o "$PROBE_DIR/probe.o" 2>/dev/null; then
    pass "C++ standard headers OK"
  else
    fail "C++ headers are broken (<functional> not found)."
    fix "$(pkg_install_hint build-essential)"
  fi
  rm -rf "$PROBE_DIR"
fi

# 7. Claude CLI
if command -v claude &>/dev/null; then
  pass "Claude Code CLI found"
else
  fail "Claude Code CLI is not installed."
  fix "npm install -g @anthropic-ai/claude-code"
fi

# Bail if any check failed
if [ "$fail" -ne 0 ]; then
  echo
  echo "Some checks failed. Fix them above, then rerun:"
  echo
  echo "  ./start.sh"
  echo
  exit 1
fi

echo
echo "All checks passed."

# ── Optional Voice Setup ──

if command -v whisper &>/dev/null; then
  pass "Whisper found (voice input ready)"
elif [ "$INSTALL_WHISPER" -eq 1 ]; then
  step "Installing optional voice dependency (Whisper)"
  if command -v pip3 &>/dev/null || command -v pip &>/dev/null; then
    PIP_CMD="pip3"
    command -v pip3 &>/dev/null || PIP_CMD="pip"
    if $PIP_CMD install openai-whisper; then
      pass "openai-whisper installed"
    else
      echo "  Could not install openai-whisper automatically."
      echo "  You can retry manually: pip install openai-whisper"
    fi
  else
    echo "  pip not found. Install whisper manually if needed."
    echo "  See: https://github.com/openai/whisper"
  fi
else
  echo
  echo "  INFO: Voice input is optional and Whisper is not installed."
  echo "  Install anytime with:"
  echo "    pip install openai-whisper"
  echo "  Or run this script with:"
  echo "    ./start.sh --with-voice"
fi

# ── Ensure Python distutils (needed by node-gyp) ──

if command -v python3 &>/dev/null; then
  if ! python3 -c "import distutils" 2>/dev/null; then
    step "Installing Python setuptools (provides distutils for node-gyp)"
    python3 -m pip install --break-system-packages setuptools 2>/dev/null \
      || python3 -m pip install setuptools 2>/dev/null \
      || true
  fi
fi

# ── Install ──

if [ ! -d "node_modules" ]; then
  step "Installing dependencies"
  if ! npm install; then
    echo
    echo "npm install failed. Most common fixes:"
    echo
    echo "  1. Install build tools:"
    echo "       $(pkg_install_hint build-essential)"
    echo
    echo "  2. Install Python setuptools:"
    echo "       python3 -m pip install --upgrade pip setuptools"
    echo
    echo "  3. Rerun this script:"
    echo "       ./start.sh"
    echo
    exit 1
  fi
fi

# ── Build ──

step "Building Clui CC"
if ! npx electron-vite build --mode production; then
  echo
  echo "Build failed. Most common fixes:"
  echo
  echo "  1. Install build tools:"
  echo "       $(pkg_install_hint build-essential)"
  echo
  echo "  2. Install Python setuptools:"
  echo "       python3 -m pip install --upgrade pip setuptools"
  echo
  echo "  3. Reinstall dependencies:"
  echo "       rm -rf node_modules && npm install"
  echo
  echo "  4. Rerun this script:"
  echo "       ./start.sh"
  echo
  exit 1
fi

# ── Fix Electron sandbox (Linux SUID requirement) ──

CHROME_SANDBOX="node_modules/electron/dist/chrome-sandbox"
if [ -f "$CHROME_SANDBOX" ]; then
  if [ "$(stat -c '%U' "$CHROME_SANDBOX" 2>/dev/null)" != "root" ] || \
     [ "$(stat -c '%a' "$CHROME_SANDBOX" 2>/dev/null)" != "4755" ]; then
    step "Configuring Electron sandbox (requires sudo)"
    echo "  The Electron sandbox binary needs root ownership and SUID bit."
    echo "  Running: sudo chown root:root && sudo chmod 4755"
    if sudo chown root:root "$CHROME_SANDBOX" && sudo chmod 4755 "$CHROME_SANDBOX"; then
      pass "Electron sandbox configured"
    else
      echo "  Could not configure sandbox. Launching with --no-sandbox fallback."
      export ELECTRON_DISABLE_SANDBOX=1
    fi
  fi
fi

# ── Launch ──

step "Launching Clui CC"
echo "  Alt+Space to toggle the overlay."
echo "  Use ./stop.sh or tray icon > Quit to close."
echo
if [ "${ELECTRON_DISABLE_SANDBOX:-}" = "1" ]; then
  exec npx electron . --no-sandbox
else
  exec npx electron .
fi
