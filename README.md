<p align="center">
  <img src="resources/icon.png" width="120" alt="Clui CC Linux logo" />
</p>

# <p align="center">Clui CC Linux</p>

<p align="center">
  Desktop overlay for Claude Code CLI on Linux.<br/>
  Float, tab, approve, and prompt without leaving your workflow.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/build-passing-brightgreen" alt="Build" />
  <img src="https://img.shields.io/badge/platform-Linux-blue" alt="Platform" />
  <img src="https://img.shields.io/badge/electron-33-blue" alt="Electron" />
  <img src="https://img.shields.io/github/license/LuisMIguelFurlanettoSousa/clui-cc-linux" alt="License" />
  <a href="https://github.com/lcoutodemos/clui-cc"><img src="https://img.shields.io/badge/fork%20of-clui--cc-orange" alt="Fork of clui-cc" /></a>
</p>

## What's Different in This Fork

This is a Linux adaptation of [clui-cc](https://github.com/lcoutodemos/clui-cc) by Lucas Couto. The original project targets macOS only. This fork adds:

- **Linux support** — tested on Ubuntu 22+, Fedora 38+, and Arch Linux
- **Screenshot capture** — auto-detects `gnome-screenshot`, `scrot`, or `import` (ImageMagick)
- **Terminal detection** — opens your default terminal automatically (GNOME Terminal, Konsole, Alacritty, etc.)
- **Tray icon** — adapted for Linux desktop environments (GNOME, KDE, XFCE)
- **Desktop integration** — `.desktop` file and Linux-compatible icon set
- **Python 3.12+ fix** — auto-installs `setuptools` when missing (removed from stdlib in 3.12)
- **Electron sandbox fix** — handles the `--no-sandbox` requirement on Linux automatically

## Features

- **Floating overlay** — transparent, always-on-top window. Toggle with `Alt+Space`
- **Multi-tab sessions** — each tab spawns its own `claude -p` process with independent session state
- **Permission approval UI** — review and approve/deny tool calls in-app before execution
- **Conversation history** — browse and resume past Claude Code sessions
- **Skills marketplace** — install plugins from Anthropic's GitHub repos without leaving the app
- **Voice input** — local speech-to-text via Whisper (no cloud transcription)
- **File & screenshot attachments** — paste images or attach files directly
- **Dark/light theme** — follows system preference
- **Auto-detection** — finds your terminal, screenshot tool, and shell automatically

## Quick Start

```bash
git clone https://github.com/LuisMIguelFurlanettoSousa/clui-cc-linux.git
cd clui-cc-linux
./start.sh
```

> Requires **Node.js 18+**, **Python 3**, and **Claude Code CLI**. The start script checks everything and tells you what's missing.

Toggle the overlay: **Alt+Space** (or **Ctrl+Shift+K** as fallback).

<details>
<summary><strong>Prerequisites</strong></summary>

**1.** Install Node.js 18+ (via your package manager or [nvm](https://github.com/nvm-sh/nvm)):

```bash
# Ubuntu/Debian
sudo apt install nodejs npm

# Fedora
sudo dnf install nodejs npm

# Or via nvm (any distro)
nvm install --lts
```

**2.** Install Python 3:

```bash
# Ubuntu/Debian
sudo apt install python3

# Fedora
sudo dnf install python3
```

**3.** Install build tools:

```bash
# Ubuntu/Debian
sudo apt install build-essential

# Fedora
sudo dnf groupinstall "Development Tools"
```

**4.** Install Claude Code CLI:

```bash
npm install -g @anthropic-ai/claude-code
```

**5.** Authenticate Claude Code (follow the prompts):

```bash
claude
```

</details>

<details>
<summary><strong>Development</strong></summary>

```bash
npm install
npm run dev    # hot-reload (renderer changes update instantly)
npm run build  # production build
```

Renderer changes update instantly during `dev`. Main-process changes require restarting `npm run dev`.

</details>

<details>
<summary><strong>Architecture and Internals</strong></summary>

Clui CC is an Electron app with three layers:

```
┌─────────────────────────────────────────────────┐
│  Renderer (React 19 + Zustand + Tailwind CSS 4) │
│  Components, theme, state management             │
├─────────────────────────────────────────────────┤
│  Preload (window.clui bridge)                    │
│  Secure IPC surface between renderer and main    │
├─────────────────────────────────────────────────┤
│  Main Process                                    │
│  ControlPlane → RunManager → claude -p (NDJSON)  │
│  PermissionServer (HTTP hooks on 127.0.0.1)      │
│  Marketplace catalog (GitHub raw fetch + cache)   │
└─────────────────────────────────────────────────┘
```

### Project Structure

```
src/
├── main/                   # Electron main process
│   ├── claude/             # ControlPlane, RunManager, EventNormalizer
│   ├── hooks/              # PermissionServer (PreToolUse HTTP hooks)
│   ├── marketplace/        # Plugin catalog fetching + install
│   ├── skills/             # Skill auto-installer
│   └── index.ts            # Window creation, IPC handlers, tray
├── renderer/               # React frontend
│   ├── components/         # TabStrip, ConversationView, InputBar, etc.
│   ├── stores/             # Zustand session store
│   ├── hooks/              # Event listeners, health reconciliation
│   └── theme.ts            # Dual palette + CSS custom properties
├── preload/                # Secure IPC bridge (window.clui API)
└── shared/                 # Canonical types, IPC channel definitions
```

### How It Works

1. Each tab creates a `claude -p --output-format stream-json` subprocess.
2. NDJSON events are parsed by `RunManager` and normalized by `EventNormalizer`.
3. `ControlPlane` manages tab lifecycle (connecting → idle → running → completed/failed/dead).
4. Tool permission requests arrive via HTTP hooks to `PermissionServer` (localhost only).
5. The renderer polls backend health every 1.5s and reconciles tab state.
6. Sessions are resumed with `--resume <session-id>` for continuity.

### Network Behavior

Clui CC operates almost entirely offline. The only outbound network calls are:

| Endpoint | Purpose | Required |
|----------|---------|----------|
| `raw.githubusercontent.com/anthropics/*` | Marketplace catalog (cached 5 min) | No — graceful fallback |
| `api.github.com/repos/anthropics/*/tarball/*` | Skill auto-install on startup | No — skipped on failure |

No telemetry, analytics, or auto-update mechanisms. All Claude Code interaction goes through the local CLI.

</details>

## Tested On

| Component | Version |
|-----------|---------|
| Ubuntu | 24.04 LTS |
| Fedora | 38+ |
| Node.js | 20.x LTS, 22.x |
| Python | 3.12 - 3.14 |
| Electron | 33.x |
| Claude Code CLI | 2.1.71+ |

## Known Limitations

- **Requires Claude Code CLI** — Clui CC is a UI layer, not a standalone AI client. You need an authenticated `claude` CLI.
- **Transparent click-through not available on Linux** — this is an Electron limitation on X11/Wayland.
- **Alt+Space may conflict** — some Linux window managers (e.g., KDE, i3) bind `Alt+Space` by default. Remap the WM shortcut or use `Ctrl+Shift+K`.

## Troubleshooting

For setup issues and recovery commands, see [`docs/TROUBLESHOOTING.md`](docs/TROUBLESHOOTING.md).

Quick self-check:

```bash
npm run doctor
```

## Contributing

See [`CONTRIBUTING.md`](CONTRIBUTING.md) for guidelines.

## Credits

- **Original project** by [Lucas Couto](https://github.com/lcoutodemos/clui-cc)
- **Linux adaptation** by [Luis Miguel](https://github.com/LuisMIguelFurlanettoSousa)

## License

[MIT](LICENSE)

---

<p align="center">If you found this useful, give it a ⭐ to help others discover it!</p>
