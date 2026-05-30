# Cross-Platform Dotfiles Setup

## Overview

Replicate the macOS `~/.cfg` bare-repo environment on Windows machines for
shader/game/3D development with offline LLM tooling. No Android or Apple
development dependencies are included.

**Target machines:**

| Machine | RAM | Role |
|---|---|---|
| Desktop | 128 GB | Primary workstation — shader dev, game engines, 3D, large LLMs |
| Laptop | 64 GB | Portable mirror — same workflow, scaled-down model sizes |

**Architecture:**

```
┌──────────────────────────────────────────────────────────────────────┐
│  Windows 11 (native)                                                  │
│  ┌──────────────────────────────────────────────────────────────────┐│
│  │ WezTerm • Ollama • VS Code • Blender • Engines • RenderDoc      ││
│  └──────────────────────────────────────────────────────────────────┘│
│                                                                        │
│  ┌──────────────────────────────────────────────────────────────────┐│
│  │ WSL2 Ubuntu (shell environment)                                   ││
│  │  zsh • oh-my-zsh • tmux • vim • git • gh • mise • pipx          ││
│  │  bare repo (~/.cfg) • dotfiles • shader CLI tools                ││
│  └──────────────────────────────────────────────────────────────────┘│
└──────────────────────────────────────────────────────────────────────┘
```

---

## 1 — Repository Organization

### 1.1 Directory Layout (after migration)

```
~/ (home — work tree for the bare repo)
├── .aliases                 # shared (platform-agnostic)
├── .exports                 # shared (platform-agnostic)
├── .functions               # shared (portable functions only)
├── .gitconfig               # shared
├── .gitignore               # shared
├── .vimrc                   # shared
├── .tmux.conf               # shared (works in WSL2 unchanged)
├── .inputrc                 # shared
├── .zshrc                   # shared (has platform detection block)
├── .vim/                    # shared
├── .bin/install.sh          # macOS bootstrap only
│
├── platform/
│   ├── macos/
│   │   ├── extra            # macOS PATH, Homebrew, VS Code .app path
│   │   ├── aliases-local    # macOS-only: ls -GFh, /usr/local/bin/vim
│   │   └── env-local        # macOS-only env vars
│   │
│   ├── linux/
│   │   ├── extra            # Linux PATH, credential helper, locale
│   │   ├── aliases-local    # Linux-only: ls --color, clip.exe, sysup
│   │   └── env-local        # Linux-only env vars (OLLAMA_HOST, WSL bridges)
│   │
│   └── windows/
│       ├── wezterm.lua      # WezTerm config (C-a prefix, tmux-like binds)
│       ├── profile.ps1      # PowerShell profile (nav aliases, wsl-dev)
│       └── wslconfig        # .wslconfig template (has hardware tier markers)
│
├── bootstrap/
│   ├── generate.sh          # ONE-SHOT: reads macOS files → writes platform/
│   ├── windows.ps1          # Windows-side first-boot script
│   └── linux.sh             # WSL2-side first-boot script (idempotent)
│
└── README.md
```

### 1.2 Sparse-Checkout Strategy

Each platform uses sparse-checkout to avoid pulling files it doesn't need:

**macOS (`~/.cfg` on Mac):**
```
/*
!platform/linux/
!platform/windows/
!bootstrap/windows.ps1
```

**WSL2 / Linux (`~/.cfg` inside WSL):**
```
/*
!platform/macos/
!.bin/install.sh
!.bin/subl
!.local/bin/studio
```

**Windows native (PowerShell repo for WezTerm/profile — optional):**
Only `platform/windows/` is relevant; the rest lives in WSL2's filesystem.

Setup command (run once after clone):
```bash
config sparse-checkout init --cone
config sparse-checkout set \
  .aliases .exports .functions .gitconfig .gitignore .vimrc .tmux.conf \
  .inputrc .zshrc .vim platform/linux bootstrap/linux.sh README.md
```

### 1.3 Platform Detection in `.zshrc`

Replace the current hard-coded sourcing loop with:

```zsh
# Platform detection — sources the right platform/* files
case "$OSTYPE" in
  darwin*)  _platform="macos" ;;
  linux*)   _platform="linux" ;;
esac

# Source shared dotfiles
for file in ~/.{exports,aliases,functions}; do
  [[ -r "$file" ]] && source "$file"
done

# Source platform-specific overrides
for file in ~/platform/${_platform}/{extra,aliases-local,env-local}; do
  [[ -r "$file" ]] && source "$file"
done

unset _platform file
```

This replaces the current `.{extra,exports,aliases,env-local,functions,env-android,aliases-android}` loop.

---

## 2 — One-Shot Generator (`bootstrap/generate.sh`)

Run this on macOS. It reads your current dotfiles and produces all
`platform/linux/` and `platform/windows/` files automatically. Commit the
output into the repo.

```bash
#!/usr/bin/env bash
set -euo pipefail
#
# generate.sh — Run on macOS to produce cross-platform files from source configs.
# Output: ~/platform/linux/*, ~/platform/macos/*, ~/platform/windows/*
#
# Usage:
#   chmod +x ~/bootstrap/generate.sh
#   ~/bootstrap/generate.sh [--tier desktop|laptop]
#
# Default tier: desktop (128 GB). Laptop tier adjusts .wslconfig + Ollama settings.

TIER="${1:-desktop}"
[[ "$TIER" == "--tier" ]] && TIER="${2:-desktop}"

PLATFORM_DIR="$HOME/platform"
mkdir -p "$PLATFORM_DIR"/{macos,linux,windows}

echo "==> Generating platform files (tier: $TIER)"

# ─── platform/macos/extra ────────────────────────────────────────────────────
# Extract from current ~/.extra, stripping Android lines
echo "  → platform/macos/extra"
cat > "$PLATFORM_DIR/macos/extra" << 'MACOS_EXTRA'
# macOS PATH setup — auto-generated, edit source in ~/.extra then re-run generate.sh
BREW_PREFIX="$(brew --prefix 2>/dev/null || echo /opt/homebrew)"

PATH=$PATH:$BREW_PREFIX/lib
PATH=$PATH:/usr/local/bin
PATH=$PATH:/usr/bin
PATH=$PATH:/bin
PATH=$PATH:/usr/sbin
PATH=$PATH:/sbin

# VS Code
VSCODE_BIN="$(command -v code 2>/dev/null)"
if [ -z "$VSCODE_BIN" ]; then
  VSCODE_APP_BIN="/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
  [ -d "$VSCODE_APP_BIN" ] && PATH="$PATH:$VSCODE_APP_BIN"
fi

# gnu-sed (Homebrew)
GNU_SED_BIN="$BREW_PREFIX/opt/gnu-sed/libexec/gnubin"
[ -d "$GNU_SED_BIN" ] && PATH="$GNU_SED_BIN:$PATH"

export PATH
MACOS_EXTRA

# ─── platform/macos/aliases-local ────────────────────────────────────────────
echo "  → platform/macos/aliases-local"
cat > "$PLATFORM_DIR/macos/aliases-local" << 'MACOS_ALIASES'
# macOS-specific aliases
alias ls="ls -GFh"
alias vi="/usr/local/bin/vim"
alias brewup='brew update && brew upgrade && brew cleanup'
MACOS_ALIASES

# ─── platform/macos/env-local ────────────────────────────────────────────────
echo "  → platform/macos/env-local"
cat > "$PLATFORM_DIR/macos/env-local" << 'MACOS_ENV'
# macOS-specific environment variables
# (empty for now — add as needed)
MACOS_ENV

# ─── platform/linux/extra ────────────────────────────────────────────────────
echo "  → platform/linux/extra"
cat > "$PLATFORM_DIR/linux/extra" << 'LINUX_EXTRA'
# Linux/WSL2 PATH setup — auto-generated by generate.sh

PATH=$HOME/.local/bin:$PATH
PATH=$PATH:/usr/local/bin
PATH=$PATH:/usr/bin
PATH=$PATH:/bin
PATH=$PATH:/usr/sbin
PATH=$PATH:/sbin

# mise (version manager)
if [ -f "$HOME/.local/bin/mise" ]; then
  eval "$(~/.local/bin/mise activate zsh)"
fi

# VS Code (available via Windows PATH in WSL2 if "code" remote extension enabled)
# No manual PATH needed — WSL2 inherits Windows PATH for .exe

export PATH
LINUX_EXTRA

# ─── platform/linux/aliases-local ────────────────────────────────────────────
echo "  → platform/linux/aliases-local"
cat > "$PLATFORM_DIR/linux/aliases-local" << 'LINUX_ALIASES'
# Linux/WSL2-specific aliases — auto-generated by generate.sh

# ls — GNU coreutils uses --color instead of macOS -G
alias ls="ls --color=auto -Fh"
alias ll="ls -al"
alias vi="vim"

# Clipboard — bridge to Windows clipboard via WSL interop
alias pbcopy='clip.exe'
alias pbpaste='powershell.exe -command "Get-Clipboard"'

# Open — use Windows explorer from WSL
alias open='explorer.exe'

# System update (replaces 'brewup')
alias sysup='sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y'
LINUX_ALIASES

# ─── platform/linux/env-local ────────────────────────────────────────────────
echo "  → platform/linux/env-local"
cat > "$PLATFORM_DIR/linux/env-local" << 'LINUX_ENV'
# Linux/WSL2 environment — auto-generated by generate.sh

# Locale (some Ubuntu installs are missing this)
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

# Ollama — connect to Windows-native Ollama from WSL2
WIN_IP=$(grep -m1 nameserver /etc/resolv.conf | awk '{print $2}')
export OLLAMA_HOST="http://${WIN_IP}:11434"

# Quick LLM functions
ai()    { curl -s "$OLLAMA_HOST/api/generate" -d "{\"model\":\"llama3.3\",\"prompt\":\"$*\",\"stream\":false}" | python3 -c "import sys,json; print(json.load(sys.stdin)['response'])" ; }
codex() { curl -s "$OLLAMA_HOST/api/generate" -d "{\"model\":\"qwen2.5-coder:32b\",\"prompt\":\"$*\",\"stream\":false}" | python3 -c "import sys,json; print(json.load(sys.stdin)['response'])" ; }

# Git credential helper (replaces osxkeychain)
# Note: requires libsecret to be installed — see bootstrap/linux.sh
LINUX_ENV

# ─── platform/windows/wezterm.lua ────────────────────────────────────────────
echo "  → platform/windows/wezterm.lua"
cat > "$PLATFORM_DIR/windows/wezterm.lua" << 'WEZTERM'
-- WezTerm config — mirrors tmux C-a prefix and navigation binds
-- Auto-generated by generate.sh

local wezterm = require 'wezterm'
local act = wezterm.action
local config = wezterm.config_builder()

-- Visual
config.color_scheme = 'Molokai'
config.font = wezterm.font('MesloLGS NF')
config.font_size = 11.0
config.window_background_opacity = 0.95
config.hide_tab_bar_if_only_one_tab = true
config.window_padding = { left = 2, right = 2, top = 2, bottom = 2 }

-- Use C-a as leader (mirrors tmux prefix)
config.leader = { key = 'a', mods = 'CTRL', timeout_milliseconds = 1500 }

-- Default shell: WSL2 zsh
config.default_prog = { 'wsl.exe', '-d', 'Ubuntu-24.04', '--cd', '~', '-e', 'zsh', '-l' }

-- Tab bar styling (orange accent like tmux status bar)
config.colors = {
  tab_bar = {
    background = '#1c1c1c',
    active_tab = { bg_color = '#d75f00', fg_color = '#1c1c1c', intensity = 'Bold' },
    inactive_tab = { bg_color = '#3c3c3c', fg_color = '#808080' },
    new_tab = { bg_color = '#1c1c1c', fg_color = '#808080' },
  },
}

-- Key bindings (tmux-like)
config.keys = {
  -- Splits
  { key = '|', mods = 'LEADER|SHIFT', action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
  { key = '-', mods = 'LEADER', action = act.SplitVertical { domain = 'CurrentPaneDomain' } },

  -- Navigation (vim-style)
  { key = 'h', mods = 'LEADER', action = act.ActivatePaneDirection 'Left' },
  { key = 'j', mods = 'LEADER', action = act.ActivatePaneDirection 'Down' },
  { key = 'k', mods = 'LEADER', action = act.ActivatePaneDirection 'Up' },
  { key = 'l', mods = 'LEADER', action = act.ActivatePaneDirection 'Right' },

  -- Resize (arrows)
  { key = 'LeftArrow',  mods = 'LEADER', action = act.AdjustPaneSize { 'Left', 5 } },
  { key = 'RightArrow', mods = 'LEADER', action = act.AdjustPaneSize { 'Right', 5 } },
  { key = 'UpArrow',    mods = 'LEADER', action = act.AdjustPaneSize { 'Up', 3 } },
  { key = 'DownArrow',  mods = 'LEADER', action = act.AdjustPaneSize { 'Down', 3 } },

  -- Tabs
  { key = 'c', mods = 'LEADER', action = act.SpawnTab 'CurrentPaneDomain' },
  { key = 'n', mods = 'LEADER', action = act.ActivateTabRelative(1) },
  { key = 'p', mods = 'LEADER', action = act.ActivateTabRelative(-1) },

  -- Close pane
  { key = 'x', mods = 'LEADER', action = act.CloseCurrentPane { confirm = true } },

  -- Zoom pane (like tmux C-a z)
  { key = 'z', mods = 'LEADER', action = act.TogglePaneZoomState },

  -- Copy mode (like tmux C-a [)
  { key = '[', mods = 'LEADER', action = act.ActivateCopyMode },

  -- Send literal C-a (press C-a twice)
  { key = 'a', mods = 'LEADER|CTRL', action = act.SendKey { key = 'a', mods = 'CTRL' } },
}

return config
WEZTERM

# ─── platform/windows/profile.ps1 ────────────────────────────────────────────
echo "  → platform/windows/profile.ps1"
cat > "$PLATFORM_DIR/windows/profile.ps1" << 'PWSH_PROFILE'
# PowerShell profile — auto-generated by generate.sh
# Symlink or copy to: $PROFILE (~\Documents\PowerShell\Microsoft.PowerShell_profile.ps1)

# Navigation (mirrors shell aliases)
function .. { Set-Location .. }
function ... { Set-Location ../.. }
function .... { Set-Location ../../.. }

# Utilities
function ll { Get-ChildItem -Force @args }
function which($cmd) { Get-Command $cmd -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source }
Set-Alias -Name cc -Value Clear-Host

# Jump into WSL2 dev session with tmux
function wsl-dev { wsl -d Ubuntu-24.04 -- zsh -c "cd ~/Development && tmux new-session -A -s dev" }

# Quick Ollama (native Windows)
function ai { ollama run llama3.3 @args }
function codex { ollama run qwen2.5-coder:32b @args }

# Scoop completions
Import-Module "$($(Get-Item $(Get-Command scoop.ps1 -ErrorAction SilentlyContinue).Path).Directory.Parent.FullName)\modules\scoop-completion" -ErrorAction SilentlyContinue
PWSH_PROFILE

# ─── platform/windows/wslconfig ──────────────────────────────────────────────
echo "  → platform/windows/wslconfig (tier: $TIER)"
if [[ "$TIER" == "desktop" ]]; then
cat > "$PLATFORM_DIR/windows/wslconfig" << 'WSLCONFIG_DESKTOP'
# .wslconfig — 128 GB Desktop Tier
# Copy to: C:\Users\<you>\.wslconfig
[wsl2]
memory=32GB
processors=12
swap=8GB
localhostForwarding=true
nestedVirtualization=true

[experimental]
autoMemoryReclaim=gradual
sparseVhd=true
WSLCONFIG_DESKTOP
else
cat > "$PLATFORM_DIR/windows/wslconfig" << 'WSLCONFIG_LAPTOP'
# .wslconfig — 64 GB Laptop Tier
# Copy to: C:\Users\<you>\.wslconfig
[wsl2]
memory=16GB
processors=8
swap=4GB
localhostForwarding=true

[experimental]
autoMemoryReclaim=gradual
sparseVhd=true
WSLCONFIG_LAPTOP
fi

echo ""
echo "==> Done. Generated files in ~/platform/"
echo "    Review, then commit:"
echo "      config add platform/"
echo "      config commit -m 'Add cross-platform dotfiles'"
echo ""
echo "==> Next steps:"
echo "    1. Update ~/.zshrc with the platform detection block (see plan section 1.3)"
echo "    2. Move macOS-specific content out of shared .aliases/.functions/.extra"
echo "    3. Run: config add .aliases .functions .zshrc && config commit"
```

---

## 3 — Shared File Cleanup

These files currently contain macOS/Android-specific content that must be
removed from the shared versions and moved into `platform/macos/`.

### 3.1 `.aliases` — Remove / Relocate

| Current content | Action |
|---|---|
| `alias ls="ls -GFh"` | **Move** → `platform/macos/aliases-local` |
| `alias vi="/usr/local/bin/vim"` | **Move** → `platform/macos/aliases-local` |
| `alias brewup='brew update…'` | **Move** → `platform/macos/aliases-local` |
| `adb()` function | **Delete** (no Android dev on any platform) |
| `adb-screenshot()` | **Delete** |
| `alias studio` / `studio()` | **Delete** |

**Shared `.aliases` keeps:** `..`, `...`, `....`, `~`, `-`, `cc`, `h`,
`dl`, `dt`, `ip`, `config` alias, `cls`, git shortcuts, tmux shortcuts.

### 3.2 `.functions` — Remove / Relocate

| Current content | Action |
|---|---|
| `get_local_ip()` — uses `ipconfig getifaddr en0` | **Move** → `platform/macos/aliases-local`; add Linux variant to `platform/linux/aliases-local` |
| `studio()` — uses `open -na "Android Studio.app"` | **Delete** |
| `parse_git_branch()` | Keep (portable) |
| `wtadd()`, `wtls()`, `wtrm()` | Keep (portable git worktree helpers) |

Linux `get_local_ip()` equivalent for `platform/linux/aliases-local`:
```bash
get_local_ip() { hostname -I | awk '{print $1}'; }
```

### 3.3 `.exports` — Remove

| Current content | Action |
|---|---|
| `ANDROID_HOME=$HOME/Library/Android/sdk` | **Delete** |

Everything else (`EDITOR`, `HISTSIZE`, `LANG`, etc.) is portable — keep in shared.

### 3.4 `.gitconfig` — Platform Override

The shared `.gitconfig` contains `credential.helper = osxkeychain`. This is
handled by `.gitconfig.local` (untracked) overriding it on each platform:

- **macOS:** No override needed (osxkeychain works)
- **Linux/WSL2:** Create `~/.gitconfig.local` with:
  ```ini
  [credential]
      helper = /usr/lib/git-core/git-credential-libsecret
  [user]
      email = william.meger@crunchyroll.com
  ```

### 3.5 `.zshrc` — Update Sourcing Loop

Replace the current loop:
```zsh
for file in ~/.{extra,exports,aliases,env-local,functions,env-android,aliases-android}; do
```

With the platform detection block from section 1.3.

Also remove:
- `gradle-completion` from plugins list (Android-specific)
- `adb` completion sourcing
- Any `env-android` / `aliases-android` references

---

## 4 — Bootstrap: Windows Side (`bootstrap/windows.ps1`)

Run this on a fresh Windows 11 machine in an elevated PowerShell. It installs
everything on the native Windows side and enables WSL2.

```powershell
#Requires -RunAsAdministrator
<#
.SYNOPSIS
  Windows-side bootstrap for cross-platform dotfiles setup.
  Run once on a fresh Win11 machine. Reboot required at the end.
.PARAMETER Tier
  Hardware tier: 'desktop' (128 GB) or 'laptop' (64 GB). Default: desktop.
#>
param(
    [ValidateSet('desktop','laptop')]
    [string]$Tier = 'desktop'
)

Write-Host "`n=== Windows Bootstrap (tier: $Tier) ===`n" -ForegroundColor Cyan

# ─── Scoop ────────────────────────────────────────────────────────────────────
if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
    Write-Host "[1/7] Installing Scoop..." -ForegroundColor Yellow
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
    Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
} else {
    Write-Host "[1/7] Scoop already installed" -ForegroundColor Green
}

# ─── Scoop packages ──────────────────────────────────────────────────────────
Write-Host "[2/7] Installing Scoop packages..." -ForegroundColor Yellow
scoop bucket add extras
scoop bucket add nerd-fonts
scoop install `
    git gh neovim ripgrep fzf delta bat fd cmake ninja `
    python wezterm git-lfs imagemagick

scoop install nerd-fonts/Meslo-NF

# ─── Winget packages ─────────────────────────────────────────────────────────
Write-Host "[3/7] Installing Winget packages..." -ForegroundColor Yellow
$wingetApps = @(
    'Ollama.Ollama'
    'LMStudio.LMStudio'
    'Microsoft.VisualStudioCode'
    'Docker.DockerDesktop'
    'KhronosGroup.VulkanSDK'
    'Microsoft.VisualStudio.2022.BuildTools'
    'BaldurKarlsson.RenderDoc'
    'BlenderFoundation.Blender'
    'GodotEngine.GodotEngine'
    'Unity.UnityHub'
)
foreach ($app in $wingetApps) {
    winget install --id $app --accept-source-agreements --accept-package-agreements --silent
}

# ─── WezTerm config ──────────────────────────────────────────────────────────
Write-Host "[4/7] Deploying WezTerm config..." -ForegroundColor Yellow
$weztermDir = "$env:USERPROFILE\.config\wezterm"
New-Item -ItemType Directory -Path $weztermDir -Force | Out-Null

# This will be the repo path once WSL2 is up; for now create a placeholder
# The linux.sh bootstrap copies from ~/platform/windows/wezterm.lua
if (Test-Path "$PSScriptRoot\..\platform\windows\wezterm.lua") {
    Copy-Item "$PSScriptRoot\..\platform\windows\wezterm.lua" "$weztermDir\wezterm.lua" -Force
    Write-Host "    Copied wezterm.lua" -ForegroundColor Green
} else {
    Write-Host "    wezterm.lua not found — will be deployed by linux.sh bootstrap" -ForegroundColor DarkYellow
}

# ─── PowerShell profile ──────────────────────────────────────────────────────
Write-Host "[5/7] Installing PowerShell profile..." -ForegroundColor Yellow
$profileDir = Split-Path $PROFILE -Parent
New-Item -ItemType Directory -Path $profileDir -Force | Out-Null

if (Test-Path "$PSScriptRoot\..\platform\windows\profile.ps1") {
    Copy-Item "$PSScriptRoot\..\platform\windows\profile.ps1" $PROFILE -Force
    Write-Host "    Installed to $PROFILE" -ForegroundColor Green
}

# ─── .wslconfig ───────────────────────────────────────────────────────────────
Write-Host "[6/7] Deploying .wslconfig (tier: $Tier)..." -ForegroundColor Yellow
$wslconfigSrc = "$PSScriptRoot\..\platform\windows\wslconfig"
if (Test-Path $wslconfigSrc) {
    Copy-Item $wslconfigSrc "$env:USERPROFILE\.wslconfig" -Force
    Write-Host "    Installed .wslconfig" -ForegroundColor Green
} else {
    # Generate inline based on tier
    if ($Tier -eq 'desktop') {
        @"
[wsl2]
memory=32GB
processors=12
swap=8GB
localhostForwarding=true
nestedVirtualization=true

[experimental]
autoMemoryReclaim=gradual
sparseVhd=true
"@ | Set-Content "$env:USERPROFILE\.wslconfig"
    } else {
        @"
[wsl2]
memory=16GB
processors=8
swap=4GB
localhostForwarding=true

[experimental]
autoMemoryReclaim=gradual
sparseVhd=true
"@ | Set-Content "$env:USERPROFILE\.wslconfig"
    }
    Write-Host "    Generated .wslconfig for $Tier tier" -ForegroundColor Green
}

# ─── WSL2 ─────────────────────────────────────────────────────────────────────
Write-Host "[7/7] Enabling WSL2..." -ForegroundColor Yellow
$wslStatus = wsl --status 2>&1
if ($LASTEXITCODE -ne 0) {
    wsl --install -d Ubuntu-24.04
    Write-Host "`n⚠️  Reboot required. After reboot:" -ForegroundColor Red
    Write-Host "   1. Open WezTerm (it will launch into WSL2 Ubuntu)" -ForegroundColor White
    Write-Host "   2. Run: ~/bootstrap/linux.sh --tier $Tier" -ForegroundColor White
} else {
    Write-Host "    WSL2 already enabled" -ForegroundColor Green
    Write-Host "`n✅ Windows side complete. Now run inside WSL2:" -ForegroundColor Cyan
    Write-Host "   ~/bootstrap/linux.sh --tier $Tier" -ForegroundColor White
}

# ─── Ollama env vars ─────────────────────────────────────────────────────────
Write-Host "`nConfiguring Ollama environment..." -ForegroundColor Yellow
if ($Tier -eq 'desktop') {
    [Environment]::SetEnvironmentVariable("OLLAMA_MAX_LOADED_MODELS", "3", "User")
    [Environment]::SetEnvironmentVariable("OLLAMA_NUM_PARALLEL", "4", "User")
} else {
    [Environment]::SetEnvironmentVariable("OLLAMA_MAX_LOADED_MODELS", "2", "User")
    [Environment]::SetEnvironmentVariable("OLLAMA_NUM_PARALLEL", "2", "User")
}
[Environment]::SetEnvironmentVariable("OLLAMA_KEEP_ALIVE", "30m", "User")
[Environment]::SetEnvironmentVariable("OLLAMA_HOST", "0.0.0.0:11434", "User")
Write-Host "    Set OLLAMA_HOST=0.0.0.0:11434 (accessible from WSL2)" -ForegroundColor Green

Write-Host "`n=== Windows bootstrap complete ===`n" -ForegroundColor Cyan
```

---

## 5 — Bootstrap: WSL2 Side (`bootstrap/linux.sh`)

Run inside WSL2 after the Windows bootstrap + reboot. Fully idempotent.

```bash
#!/usr/bin/env bash
set -euo pipefail
#
# linux.sh — WSL2/Linux environment bootstrap
# Usage: ~/bootstrap/linux.sh [--tier desktop|laptop]
#

TIER="desktop"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --tier) TIER="$2"; shift 2 ;;
    *) echo "Unknown arg: $1"; exit 1 ;;
  esac
done

echo ""
echo "=== Linux Bootstrap (tier: $TIER) ==="
echo ""

# ─── 1. Base packages ────────────────────────────────────────────────────────
echo "[1/10] Installing base packages..."
sudo apt update && sudo apt upgrade -y
sudo apt install -y \
  zsh git curl wget vim tmux tree shellcheck \
  build-essential libssl-dev zlib1g-dev \
  unzip xclip xdg-utils python3-pip python3-venv \
  libsecret-1-0 libsecret-1-dev \
  glslang-tools spirv-tools spirv-cross

# Build git-credential-libsecret if not present
if ! [ -f /usr/lib/git-core/git-credential-libsecret ]; then
  echo "    Building git-credential-libsecret..."
  cd /usr/share/doc/git/contrib/credential/libsecret
  sudo make
  sudo cp git-credential-libsecret /usr/lib/git-core/
  cd ~
fi

# ─── 2. Set zsh as default shell ─────────────────────────────────────────────
echo "[2/10] Setting zsh as default shell..."
if [[ "$SHELL" != *"zsh"* ]]; then
  chsh -s "$(which zsh)"
fi

# ─── 3. oh-my-zsh ────────────────────────────────────────────────────────────
echo "[3/10] Installing oh-my-zsh..."
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  RUNZSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# ─── 4. Dotfiles bare repo ───────────────────────────────────────────────────
echo "[4/10] Cloning dotfiles bare repo..."
if [ ! -d "$HOME/.cfg" ]; then
  git clone --bare git@github.com:williammeger/dotfiles.git "$HOME/.cfg"

  # Define config alias for this script
  config() { /usr/bin/git --git-dir="$HOME/.cfg/" --work-tree="$HOME" "$@"; }

  config config --local status.showUntrackedFiles no

  # Setup sparse checkout
  config sparse-checkout init --cone
  config sparse-checkout set \
    .aliases .exports .functions .gitconfig .gitignore .vimrc .tmux.conf \
    .inputrc .zshrc .vim platform/linux bootstrap README.md

  # Attempt checkout — backup conflicts
  if ! config checkout 2>/dev/null; then
    echo "    Backing up conflicting files..."
    mkdir -p ~/.cfg-backup
    config checkout 2>&1 | grep -E "^\s+\." | awk '{print $1}' | \
      xargs -I{} sh -c 'mkdir -p ~/.cfg-backup/$(dirname "{}") && mv "{}" ~/.cfg-backup/{}'
    config checkout
  fi
else
  echo "    ~/.cfg already exists — skipping clone"
  config() { /usr/bin/git --git-dir="$HOME/.cfg/" --work-tree="$HOME" "$@"; }
fi

# ─── 5. vim-plug ─────────────────────────────────────────────────────────────
echo "[5/10] Installing vim-plug..."
if [ ! -f "$HOME/.vim/autoload/plug.vim" ]; then
  curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
fi
vim +PlugInstall +qall 2>/dev/null || true

# ─── 6. mise (version manager) ───────────────────────────────────────────────
echo "[6/10] Installing mise..."
if ! command -v mise &>/dev/null && [ ! -f "$HOME/.local/bin/mise" ]; then
  curl https://mise.run | sh
fi

# ─── 7. gh CLI ────────────────────────────────────────────────────────────────
echo "[7/10] Installing gh CLI..."
if ! command -v gh &>/dev/null; then
  (type -p wget >/dev/null || sudo apt install wget -y) \
    && sudo mkdir -p -m 755 /etc/apt/keyrings \
    && out=$(mktemp) && wget -nv -O"$out" https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    && cat "$out" | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
    && sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
       | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && sudo apt update \
    && sudo apt install gh -y
fi

# ─── 8. pipx ─────────────────────────────────────────────────────────────────
echo "[8/10] Installing pipx + Python tools..."
if ! command -v pipx &>/dev/null; then
  sudo apt install -y pipx
  pipx ensurepath
fi


# ─── 9. Git identity ─────────────────────────────────────────────────────────
echo "[9/10] Setting up git identity..."
if [ ! -f "$HOME/.gitconfig.local" ]; then
  cat > "$HOME/.gitconfig.local" << 'GIT_LOCAL'
[credential]
    helper = /usr/lib/git-core/git-credential-libsecret

[user]
    email = william.meger@crunchyroll.com
GIT_LOCAL
  echo "    Created ~/.gitconfig.local"
fi

# ─── 10. Deploy Windows-side configs ─────────────────────────────────────────
echo "[10/10] Deploying configs to Windows side..."
WIN_USER=$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r')
WIN_HOME="/mnt/c/Users/$WIN_USER"

# WezTerm config
WEZTERM_DIR="$WIN_HOME/.config/wezterm"
if [ -f "$HOME/platform/windows/wezterm.lua" ]; then
  mkdir -p "$WEZTERM_DIR"
  cp "$HOME/platform/windows/wezterm.lua" "$WEZTERM_DIR/wezterm.lua"
  echo "    Deployed wezterm.lua → $WEZTERM_DIR/"
fi

# PowerShell profile
PS_PROFILE_DIR="$WIN_HOME/Documents/PowerShell"
if [ -f "$HOME/platform/windows/profile.ps1" ]; then
  mkdir -p "$PS_PROFILE_DIR"
  cp "$HOME/platform/windows/profile.ps1" "$PS_PROFILE_DIR/Microsoft.PowerShell_profile.ps1"
  echo "    Deployed profile.ps1 → $PS_PROFILE_DIR/"
fi

# ─── SSH key check ────────────────────────────────────────────────────────────
echo ""
if [ ! -f "$HOME/.ssh/id_ed25519" ] && [ ! -f "$HOME/.ssh/id_rsa" ]; then
  echo "⚠️  No SSH keys found. Either:"
  echo "   • Copy from macOS: scp mac:~/.ssh/id_ed25519* ~/.ssh/ && chmod 600 ~/.ssh/id_*"
  echo "   • Or generate new: ssh-keygen -t ed25519 -C 'william.meger@crunchyroll.com'"
fi

echo ""
echo "=== Linux bootstrap complete ==="
echo ""
echo "Next steps:"
echo "  1. Close and reopen WezTerm (to pick up zsh as default shell)"
echo "  2. Run: gh auth login"
echo "  3. Pull Ollama models (see section 7 of the plan)"
echo ""
```

---

## 6 — Shader / Game / 3D Toolchain

All of these run native Windows. Installed by `bootstrap/windows.ps1`.

### 6.1 Graphics APIs & SDKs

| Tool | Install | Purpose |
|---|---|---|
| Vulkan SDK | `winget install KhronosGroup.VulkanSDK` | `glslc`, `glslangValidator`, `spirv-cross`, validation layers |
| Windows SDK | Ships with VS Build Tools | `dxc.exe` (HLSL shader compiler), PIX hooks |
| RenderDoc | `winget install BaldurKarlsson.RenderDoc` | GPU frame capture, shader debugging |
| Slang | `winget install ShaderSlang.Slang` | Write once → HLSL/GLSL/SPIR-V/Metal/CUDA |
| NSight Graphics | Manual download (nvidia.com) | NVIDIA shader debugger + GPU profiler |

### 6.2 Shader Dev Workflow (WSL2 CLI)

```bash
# Compile GLSL → SPIR-V
glslangValidator -V shader.vert -o vert.spv
glslangValidator -V shader.frag -o frag.spv

# Inspect SPIR-V
spirv-dis vert.spv

# Cross-compile SPIR-V → HLSL (for DX12 targets)
spirv-cross vert.spv --hlsl --output vert.hlsl

# Ask LLM to explain or fix shader code
cat shader.frag | codex "This GLSL fragment shader has a compile error. Diagnose and fix it."
```

### 6.3 VS Code Shader Extensions

```powershell
code --install-extension slevesque.shader
code --install-extension raczzalan.glsl-linter
code --install-extension TimJones.hlsl-preview
code --install-extension shader-slang.slang-vscode-extension
```

### 6.4 Game Engines

| Engine | Install | Notes |
|---|---|---|
| Godot 4 | `winget install GodotEngine.GodotEngine` | Vulkan-native, GDScript + C# + GDExtension (C++) |
| Unreal Engine 5 | Epic Games Launcher | 128 GB handles shader compilation well |
| Unity | `winget install Unity.UnityHub` | URP/HDRP + Shader Graph |

### 6.5 3D & Asset Tools

| Tool | Install | Notes |
|---|---|---|
| Blender | `winget install BlenderFoundation.Blender` | Modeling, rendering, geometry/shader nodes |
| Houdini | sidefx.com (apprentice free) | Procedural 3D, VFX, large VDB sims |
| ImageMagick | `scoop install imagemagick` | CLI texture/image processing |
| Git LFS | `scoop install git-lfs` | Required for binary assets (textures, meshes) |

### 6.6 C++ Build System (Custom Engines)

```powershell
# VS Build Tools (installs MSVC compiler)
winget install Microsoft.VisualStudio.2022.BuildTools

# vcpkg (C++ package manager)
git clone https://github.com/microsoft/vcpkg C:\vcpkg
C:\vcpkg\bootstrap-vcpkg.bat
[Environment]::SetEnvironmentVariable("VCPKG_ROOT", "C:\vcpkg", "User")

# Common graphics libs
cd C:\vcpkg
.\vcpkg install glfw3 glm imgui vulkan-headers spirv-cross shaderc
```

---

## 7 — Offline LLM Stack (Step-by-Step)

> **What is an LLM?** A Large Language Model is an AI that runs locally on your
> hardware. It can answer questions, write code, explain errors, and generate
> content — all without internet. Think of it as a private ChatGPT that lives
> entirely on your machine.
>
> **What is a "model"?** A downloadable file (typically 5–40 GB) containing the
> AI's knowledge. Different models are good at different things (code, reasoning,
> image understanding). You download them once, then they run locally forever.
>
> **What is "quantization" (Q4_K_M, Q3_K_M)?** A compression technique that
> shrinks models to fit in less RAM with minimal quality loss. Q4_K_M is the
> sweet spot (4-bit precision, good quality). Q3_K_M is more compressed (3-bit,
> slightly lower quality, smaller file). Higher numbers = better quality but
> larger files.

Two tools are configured: **Ollama** (headless API server, terminal-first) and
**LM Studio** (GUI app with built-in chat, server mode, and model management).
They complement each other — Ollama is always running as a background service;
LM Studio provides a visual interface when you want one.

Both are **completely offline** after initial model downloads. No accounts, no
cloud services, no telemetry. Your prompts and code never leave your machine.

### 7.1 Hardware-Tiered Model Recommendations

**Desktop (128 GB RAM):**

| Use Case | Model | RAM (Q4_K_M) | Notes |
|---|---|---|---|
| General reasoning | `llama3.3:70b` | ~40 GB | Best general model at this size |
| Code generation | `qwen2.5-coder:32b` | ~20 GB | Excellent for C++/GLSL/HLSL |
| Fast completions | `qwen2.5-coder:7b` | ~5 GB | Keep in VRAM for instant response |
| Deep reasoning | `deepseek-r1:32b` | ~20 GB | Architecture decisions, math |
| Multimodal | `llava:34b` | ~22 GB | Describe textures, RenderDoc frames |
| **Concurrent** | 2–3 loaded | ~65–85 GB | Leaves 40–60 GB for OS + tools |

**Laptop (64 GB RAM + RTX 3070 8 GB VRAM):**

| Use Case | Model | RAM (Q4_K_M) | Notes |
|---|---|---|---|
| General reasoning | `llama3.3:70b-q3_K_M` | ~32 GB | Lower quant, still capable |
| Code generation | `qwen2.5-coder:14b` | ~9 GB | Good balance of quality/speed |
| Fast completions | `qwen2.5-coder:7b` | ~5 GB | Fully GPU-offloaded on 3070 |
| Deep reasoning | `deepseek-r1:14b` | ~9 GB | Scaled down but functional |
| Multimodal | `llava:13b` | ~8 GB | Lighter multimodal |
| **Concurrent** | 2 loaded | ~40–45 GB | Leaves 20–24 GB for OS + tools |

---

### 7.2 Ollama — Complete Setup Guide

#### Step 1: Install Ollama

Ollama is the engine that actually runs AI models on your machine. It installs
as a Windows background service (like antivirus or Bluetooth — always running,
no window needed).

```powershell
# From PowerShell (elevated — right-click PowerShell → "Run as administrator")
winget install Ollama.Ollama
```

After install, Ollama runs as a **Windows service** (you'll see a llama icon
in the system tray, bottom-right of taskbar). It starts automatically on boot
— no manual launch needed.

Verify it's running:
```powershell
# Open a NEW PowerShell window (not the admin one) and run:
ollama --version
# Expected output: something like "ollama version 0.x.x"

# Also verify the local server is responding:
curl http://localhost:11434
# Expected output: "Ollama is running"
```

> **If `ollama` is not recognized:** Close and reopen PowerShell. The installer
> adds it to PATH but existing windows don't pick it up until reopened.

#### Step 2: Configure Environment Variables

Environment variables tell Ollama how to behave. You need to set these so that:
- WSL2 (the Linux layer) can talk to Ollama running on the Windows side
- Ollama knows how many models to keep in memory based on your hardware

**How to set them (GUI method):**
1. Press `Win + R`, type `sysdm.cpl`, press Enter
2. Click **Advanced** tab → **Environment Variables** button
3. Under **User variables** (top section), click **New** for each:

| Variable Name | Value (Desktop 128 GB) | Value (Laptop 64 GB) | What it does |
|---|---|---|---|
| `OLLAMA_HOST` | `0.0.0.0:11434` | `0.0.0.0:11434` | Lets WSL2 connect to Ollama (default only allows localhost) |
| `OLLAMA_MAX_LOADED_MODELS` | `3` | `2` | Number of models kept ready in RAM at once |
| `OLLAMA_NUM_PARALLEL` | `4` | `2` | How many requests can run at the same time |
| `OLLAMA_KEEP_ALIVE` | `30m` | `15m` | How long an unused model stays in RAM before unloading |
| `OLLAMA_MODELS` | `D:\ollama\models` | *(leave blank/skip)* | Where model files are stored (set this only if C: drive is low on space) |

**Or set them via PowerShell (faster, same result):**
```powershell
[Environment]::SetEnvironmentVariable("OLLAMA_HOST", "0.0.0.0:11434", "User")
[Environment]::SetEnvironmentVariable("OLLAMA_MAX_LOADED_MODELS", "3", "User")  # use "2" for laptop
[Environment]::SetEnvironmentVariable("OLLAMA_NUM_PARALLEL", "4", "User")       # use "2" for laptop
[Environment]::SetEnvironmentVariable("OLLAMA_KEEP_ALIVE", "30m", "User")       # use "15m" for laptop
```

**After setting these, restart Ollama:**
Right-click the llama icon in the system tray (bottom-right of taskbar) → **Quit Ollama**.
Then relaunch it from the Start menu (search "Ollama"). It will pick up the new settings.

#### Step 3: Pull (Download) Models

"Pulling" a model means downloading it to your machine. This only happens once
per model — after that it's stored locally and loads from disk.

**⚠️ These are large downloads. Use a wired connection if possible.**

```powershell
# ── Desktop (128 GB) — run these one at a time ───────────────────────────
ollama pull llama3.3:70b            # ~40 GB — general Q&A, reasoning
ollama pull qwen2.5-coder:32b      # ~20 GB — code generation (GLSL, C++, HLSL)
ollama pull qwen2.5-coder:7b       # ~5 GB  — fast autocomplete
ollama pull deepseek-r1:32b        # ~20 GB — complex reasoning, math
ollama pull llava:34b              # ~22 GB — can "see" images (screenshots, textures)

# ── Laptop (64 GB) — smaller variants ────────────────────────────────────
ollama pull llama3.3:70b-q3_K_M    # ~32 GB — same model, more compressed
ollama pull qwen2.5-coder:14b      # ~9 GB  — good code model, smaller
ollama pull qwen2.5-coder:7b       # ~5 GB  — fast autocomplete (same as desktop)
ollama pull deepseek-r1:14b        # ~9 GB  — reasoning, smaller
ollama pull llava:13b              # ~8 GB  — image understanding, smaller
```

Each pull shows a progress bar. When it says "success", the model is ready.

Verify your downloaded models:
```powershell
ollama list
# Shows all downloaded models with their sizes
# Example output:
# NAME                       SIZE
# llama3.3:70b               40 GB
# qwen2.5-coder:32b          20 GB
# qwen2.5-coder:7b           4.7 GB
```

#### Step 4: Test from Terminal

Now that models are downloaded, you can talk to them directly from PowerShell:

```powershell
# Interactive chat (type messages back and forth, like a chat app in the terminal)
# Type your question, press Enter. Type /bye or press Ctrl+D to exit.
ollama run qwen2.5-coder:32b

# One-shot question (asks one thing, prints the answer, then exits)
echo "Explain what a compute shader dispatch does" | ollama run qwen2.5-coder:32b

# Send a file's contents to the model and ask about it
Get-Content shader.frag | ollama run qwen2.5-coder:32b "Fix the compile error in this GLSL"
```

> **First run is slow:** The first time you run a model after a reboot, Ollama
> loads it into RAM (takes 10–30 seconds for large models). Subsequent prompts
> are fast because the model stays loaded per your `OLLAMA_KEEP_ALIVE` setting.

#### Step 5: Configure WSL2 Access

WSL2 (the Linux environment inside Windows) needs to reach Ollama running on the
Windows side. This is already handled automatically by the `platform/linux/env-local`
file that the bootstrap deploys — it detects the Windows host IP and sets up
helper functions.

After running `bootstrap/linux.sh`, verify from inside a WSL2 terminal:

```bash
# This checks if WSL2 can reach the Windows-side Ollama
curl http://$(grep -m1 nameserver /etc/resolv.conf | awk '{print $2}'):11434
# Expected output: "Ollama is running"

# If that works, the helper functions are ready:
ai "What is a signed distance field?"
codex "Write a GLSL SDF sphere function"
```

> **If it doesn't work:** Make sure you set `OLLAMA_HOST=0.0.0.0:11434` in
> Step 2 and restarted Ollama. The default (`127.0.0.1`) only allows connections
> from Windows itself, blocking WSL2.

#### Step 6: Create Custom Modelfiles (optional, do this later)

A "Modelfile" is a recipe that wraps an existing model with a custom personality/
instructions. Think of it as pre-loading a system prompt so you don't have to
type it every time.

```powershell
# Create a shader-focused assistant
# (this creates a file, then tells Ollama to register a new model variant from it)
@"
FROM qwen2.5-coder:32b
SYSTEM You are an expert graphics programmer specializing in GLSL, HLSL, SPIR-V, and Vulkan/DirectX 12 rendering pipelines. When writing shader code, always include comments explaining the math. Prefer modern shader model 6.x features when targeting HLSL. For GLSL, target version 450+ with Vulkan semantics.
PARAMETER temperature 0.3
PARAMETER num_ctx 8192
"@ | Set-Content "$env:TEMP\Modelfile.shader"

ollama create shader-expert -f "$env:TEMP\Modelfile.shader"
# This takes ~5 seconds — it's just saving a pointer to the base model + your instructions

# Now use it (it loads the same 32B model but with your graphics-focused system prompt)
ollama run shader-expert "Write a PBR metallic-roughness BRDF in GLSL"
```

```powershell
# Create a Blender Python scripting assistant
@"
FROM llama3.3:70b
SYSTEM You are an expert Blender 4.x Python API developer. You write bpy scripts for procedural geometry generation, shader node trees, and automation. Always use the modern Blender 4.x API conventions. Include error handling and type hints.
PARAMETER temperature 0.4
PARAMETER num_ctx 8192
"@ | Set-Content "$env:TEMP\Modelfile.blender"

ollama create blender-expert -f "$env:TEMP\Modelfile.blender"
```

> **`temperature`** controls randomness: 0.0 = deterministic (same answer every
> time), 1.0 = creative/varied. Use 0.2–0.4 for code, 0.7+ for brainstorming.
>
> **`num_ctx`** is the context window size — how much text the model can "see"
> at once (including your prompt + its response). 8192 tokens ≈ ~6000 words.

#### Step 7: API Usage (for scripts and integrations)

Ollama exposes a local HTTP API — this is how other tools (Continue.dev, Open
WebUI, your own scripts) talk to it programmatically. You don't
need to use this directly for day-to-day work, but it's useful to understand.

The API runs at `http://localhost:11434`. Everything stays on your machine —
zero internet connectivity required:

```bash
# Generate a response (streams tokens as they're generated)
curl http://localhost:11434/api/generate -d '{
  "model": "qwen2.5-coder:32b",
  "prompt": "Write a vertex shader that applies skeletal animation",
  "stream": true
}'

# Chat format (keeps conversation context between messages)
curl http://localhost:11434/api/chat -d '{
  "model": "qwen2.5-coder:32b",
  "messages": [
    {"role": "system", "content": "You are a graphics programming expert."},
    {"role": "user", "content": "Explain deferred vs forward rendering tradeoffs"}
  ]
}'

# /v1/ endpoint (used by tools like Continue.dev and LM Studio clients)
# Same protocol format that many AI tools expect — fully local, no internet
curl http://localhost:11434/v1/chat/completions -d '{
  "model": "qwen2.5-coder:32b",
  "messages": [{"role": "user", "content": "hello"}]
}'
```

---

### 7.3 LM Studio — Complete Setup Guide

LM Studio is a desktop application with a visual interface for:
- **Browsing and downloading models** (like an app store for AI models)
- **Chatting** with models in a familiar chat UI (like iMessage but with AI)
- **Running a local server** that other tools can connect to

It's separate from Ollama. You don't *need* both, but they serve different
purposes — Ollama is your always-on background engine; LM Studio is your
GUI for exploration and visual interaction.

#### Step 1: Install LM Studio

```powershell
winget install LMStudio.LMStudio
```

Or download from https://lmstudio.ai — run the installer.

Launch LM Studio from the Start menu. It will open a desktop window.

#### Step 2: First Launch — Configure Settings

1. **Open LM Studio**
2. Go to **Settings** (gear icon, bottom-left of the window):
   - **Models directory**: Where model files are stored on disk. Set to a drive
     with plenty of free space:
     - Desktop: needs 100+ GB free for full model set (e.g., `D:\lmstudio\models`)
     - Laptop: needs 60+ GB free
   - **GPU Offload**: Set to **Auto** — LM Studio will detect your NVIDIA GPU
     and use it when possible
   - **Context Length default**: Set to `8192` (how much text the model can process
     at once — 8192 is enough for most code tasks)
   - **Thread count** (how many CPU cores the model uses):
     - Desktop: `10` (leave 2 cores free for Windows and other apps)
     - Laptop: `6` (leave 2 cores free)

#### Step 3: Download Models

LM Studio has its own model browser. You can download the same models you
pulled in Ollama, or try different ones.

1. Click the **Search** tab (magnifying glass icon, left sidebar)
2. Type a model name in the search bar
3. You'll see multiple "variants" — these are different compression levels.
   **Pick the Q4_K_M variant** (best balance of size and quality).
4. Click the download button (↓) next to the variant

**Desktop (128 GB) — download these:**

| Type in search bar | Click this variant | Download size |
|---|---|---|
| `llama-3.3-70b` | `Q4_K_M` (look for uploader "bartowski") | ~40 GB |
| `Qwen2.5-Coder-32B-Instruct` | `Q4_K_M` | ~20 GB |
| `Qwen2.5-Coder-7B-Instruct` | `Q4_K_M` | ~5 GB |
| `DeepSeek-R1-Distill-Qwen-32B` | `Q4_K_M` | ~20 GB |
| `llava-v1.6-34b` | `Q4_K_M` | ~22 GB |

**Laptop (64 GB) — download these instead:**

| Type in search bar | Click this variant | Download size |
|---|---|---|
| `llama-3.3-70b` | `Q3_K_M` (more compressed, fits in 64 GB) | ~32 GB |
| `Qwen2.5-Coder-14B-Instruct` | `Q4_K_M` | ~9 GB |
| `Qwen2.5-Coder-7B-Instruct` | `Q4_K_M` | ~5 GB |
| `DeepSeek-R1-Distill-Qwen-14B` | `Q4_K_M` | ~9 GB |
| `llava-v1.6-13b` | `Q4_K_M` | ~8 GB |

Downloads happen in parallel — let them all run. You can use LM Studio while
downloading.

#### Step 4: Load and Chat with a Model

1. Click the **Chat** tab (💬 icon, left sidebar)
2. Click the **model selector dropdown** at the top center of the window
3. Select a downloaded model (e.g., `Qwen2.5-Coder-32B-Instruct Q4_K_M`)
4. A settings panel appears before loading — configure:
   - **GPU Layers** (how much of the model runs on your graphics card):
     - Desktop (if GPU has 24 GB VRAM): `Auto` or `All`
     - Laptop (RTX 3070, 8 GB VRAM):
       - For 7B models → `All` (entire model fits in GPU)
       - For 14B models → `20` (partial — rest uses CPU RAM)
       - For 70B models → `0` (too big for GPU, runs on CPU RAM only)
   - **Context Length**: `8192` for code work, `4096` for quick questions
5. Click **Load** — wait for the progress bar to complete (10–30 seconds)
6. Type your question in the text box at the bottom and press Enter

**Tips for shader/3D work:**
- Paste shader code directly and ask "fix the error" or "explain this"
- Use the **System Prompt** field (top of chat, expandable) to pre-load context:
  ```
  You are an expert graphics programmer. Respond with GLSL/HLSL code when asked
  for shader implementations. Always explain the math behind lighting calculations.
  ```
- Create multiple **Conversations** (left panel) — one per project or topic

#### Step 5: Enable the Local Server

LM Studio can also act as a server — just like Ollama — so other tools
(VS Code, your own scripts) can send it requests. This is useful if you want
to use a model in LM Studio as the backend for VS Code autocomplete.

This is fully offline. No internet connection required.

1. Click the **Local Server** tab (↔ icon, left sidebar)
2. Select which model to serve from the dropdown at the top
3. Configure:
   - **Port**: `1234` (leave as default)
   - **CORS**: Toggle **ON** (needed if you want browser-based tools to connect)
   - **GPU Layers**: Same guidelines as chat mode (Step 4)
4. Click **Start Server** (green button)

The server is now running at `http://localhost:1234`. Verify:
```powershell
# From PowerShell — check if it responds
curl http://localhost:1234/v1/models
# Expected: JSON listing the model name you loaded
```

From WSL2:
```bash
WIN_IP=$(grep -m1 nameserver /etc/resolv.conf | awk '{print $2}')
curl "http://${WIN_IP}:1234/v1/models"
```

> **Important:** The LM Studio server only runs while LM Studio is open.
> Unlike Ollama (which is always-on), you must manually launch LM Studio and
> start the server each time you want it. This is fine — use Ollama for
> always-on needs and LM Studio's server only when you specifically want it.

#### Step 6: Use LM Studio with VS Code / Continue.dev

In `~/.continue/config.json`, add LM Studio as a provider alongside Ollama:

```json
{
  "models": [
    {
      "title": "Qwen2.5-Coder 32B (Ollama)",
      "provider": "ollama",
      "model": "qwen2.5-coder:32b"
    },
    {
      "title": "LM Studio (whatever is loaded)",
      "provider": "lmstudio",
      "model": "loaded-model",
      "apiBase": "http://localhost:1234/v1"
    }
  ],
  "tabAutocompleteModel": {
    "title": "Qwen2.5-Coder 7B (Ollama - always running)",
    "provider": "ollama",
    "model": "qwen2.5-coder:7b"
  }
}
```

This lets you switch between Ollama (always-on background service) and LM Studio
(GUI-controlled, easy to swap models) within the same VS Code workflow.

#### Step 7: LM Studio vs Ollama — When to Use Which

| Scenario | Use | Why |
|---|---|---|
| Terminal one-liners, piping files | Ollama | Headless, always running, CLI-native |
| Browsing/downloading new models | LM Studio | Visual search, one-click download, shows quant options |
| Multi-turn chat with context | LM Studio | Better UI, conversation management, system prompts |
| VS Code autocomplete (always-on) | Ollama | Background service, never needs manual start |
| Experimenting with GPU layer settings | LM Studio | Visual slider, immediate feedback on VRAM usage |
| Scripted workflows / automation | Ollama | API is always available, no GUI dependency |
| Comparing model outputs side-by-side | LM Studio | Load model → chat → swap → compare |
| Serving to Open WebUI | Ollama | Docker integration, GPU passthrough, persistent |

**Recommended workflow:** Ollama runs 24/7 as your background inference engine.
LM Studio is opened on-demand when you want visual chat, need to download new
models, or want to experiment with different configurations.

---

### 7.4 Shared Model Storage (Avoiding Duplicate Downloads)

Ollama and LM Studio both download models in the same underlying format (GGUF).
By default they store them independently — meaning you could end up with two
copies of the same 40 GB model. Here are your options:

**Option A — Point LM Studio to Ollama's storage (recommended):**
1. Open LM Studio → Settings
2. Find "Model search paths" or "Additional model directories"
3. Add: `C:\Users\<your-username>\.ollama\models\blobs\`
4. LM Studio will now see models you've already pulled in Ollama

**Option B — Accept the duplication:**
If you have 2 TB+ NVMe storage, the ~40–60 GB overlap isn't worth the
hassle of managing. Just download in both tools independently.

---

### 7.5 Open WebUI (Browser-Based Chat Interface)

Open WebUI gives you a ChatGPT-like experience in your browser, backed by your
local Ollama models. It adds features like file uploads, conversation history,
and the ability to ask questions about uploaded documents (PDFs, code files).

**Prerequisites:** Docker Desktop must be installed and running (it's installed
by `bootstrap/windows.ps1`). Docker is a tool that runs apps in isolated
containers — think of it as a lightweight VM for server applications.

```powershell
# Open PowerShell and run this single command:
docker run -d -p 3000:8080 `
  --gpus all `
  --add-host=host.docker.internal:host-gateway `
  -v open-webui:/app/backend/data `
  --name open-webui --restart always `
  ghcr.io/open-webui/open-webui:cuda
```

> **What this does:** Downloads and starts Open WebUI in a container that
> auto-restarts on boot. The `--gpus all` flag gives it GPU access. The
> `--restart always` flag means it survives reboots.

**First-time setup:**
1. Open `http://localhost:3000` in your browser (Edge, Chrome, etc.)
2. Create an admin account — this is local-only, never leaves your machine,
   no email verification. Just pick a username and password.
3. Go to **Settings → Connections** (gear icon, top-right):
   - Set Ollama URL to: `http://host.docker.internal:11434`
   - Click **Verify** — should show a green checkmark ✓
4. Go back to the chat view — all your Ollama models now appear in the
   model dropdown at the top

**Now you can:**
- Chat with any of your downloaded models in a nice UI
- Upload shader source files and ask questions about them
- Upload RenderDoc frame exports (PNG screenshots) for visual analysis with llava
- Keep conversation history organized by project
- Upload PDF documentation and ask questions about it (RAG)

---

### 7.6 VS Code + Continue.dev (AI Autocomplete in Your Editor)

Continue.dev is a VS Code extension that adds AI-powered autocomplete and
chat directly inside your code editor. It connects to your local Ollama
(and optionally LM Studio) — no cloud, no subscription.

```powershell
# Install the extension from PowerShell:
code --install-extension Continue.continue
```

After installing, open VS Code. You'll see a Continue icon in the left sidebar.

**Configure it** by creating/editing `~/.continue/config.json`:
- On Windows, this is at `C:\Users\<you>\.continue\config.json`
- Create the `.continue` folder if it doesn't exist

```json
{
  "models": [
    {
      "title": "Qwen2.5-Coder 32B (Ollama)",
      "provider": "ollama",
      "model": "qwen2.5-coder:32b"
    },
    {
      "title": "Llama 3.3 70B (Ollama)",
      "provider": "ollama",
      "model": "llama3.3:70b"
    },
    {
      "title": "DeepSeek-R1 32B (Ollama)",
      "provider": "ollama",
      "model": "deepseek-r1:32b"
    },
    {
      "title": "LM Studio Active Model",
      "provider": "lmstudio",
      "model": "loaded-model",
      "apiBase": "http://localhost:1234/v1"
    }
  ],
  "tabAutocompleteModel": {
    "title": "Qwen2.5-Coder 7B (fast, GPU-resident)",
    "provider": "ollama",
    "model": "qwen2.5-coder:7b"
  },
  "contextProviders": [
    { "name": "code" },
    { "name": "docs" },
    { "name": "diff" },
    { "name": "terminal" },
    { "name": "open" }
  ]
}
```

On the **laptop tier**, change model names: `qwen2.5-coder:32b` → `qwen2.5-coder:14b`
and `llama3.3:70b` → `llama3.3:70b-q3_K_M`.

**How to use it in VS Code:**
- `Ctrl+Shift+L` → Opens the Continue chat panel (like a sidebar ChatGPT)
- `Ctrl+I` → Inline edit: highlight code, describe what to change, AI modifies it
- `Tab` → Accept an autocomplete suggestion (appears as you type, powered by the 7B model)
- Type `/edit` in the chat panel to request code changes applied directly to your open file

> **The 7B model stays loaded in GPU memory for instant autocomplete.** The
> larger models (32B, 70B) only load when you explicitly ask a question in
> the chat panel or use Ctrl+I.

---

### 7.7 Terminal LLM Access

From **PowerShell** (native Windows, Ollama):
```powershell
# Interactive chat
ollama run qwen2.5-coder:32b

# One-shot
ai "Explain the difference between SSAO and HBAO+"

# Pipe shader code
Get-Content shader.frag | ollama run qwen2.5-coder:32b "Fix the compile error"

# Use custom modelfile
ollama run shader-expert "Write a PBR BRDF in GLSL"
```

From **WSL2 zsh** (via `platform/linux/env-local` functions):
```bash
# One-shot via helper functions
ai "Explain the difference between SSAO and HBAO+"
codex "Write a GLSL SDF sphere function"

# Pipe files
cat shader.frag | codex "Fix the compile error in this GLSL"
spirv-dis vert.spv | codex "Explain what this SPIR-V does"

# Direct curl (useful in scripts)
curl -s http://$OLLAMA_HOST/api/generate -d '{
  "model": "qwen2.5-coder:32b",
  "prompt": "Write a Vulkan compute pipeline setup in C++",
  "stream": false
}' | python3 -c "import sys,json; print(json.load(sys.stdin)['response'])"
```

---

### 7.8 Startup Behavior Summary

| Component | Starts automatically? | How to access |
|---|---|---|
| Ollama | ✅ Windows service, auto-start on boot | `ollama run`, API at `:11434` |
| LM Studio | ❌ Launch manually when needed | GUI app, server at `:1234` when started |
| Open WebUI | ✅ Docker `--restart always` | Browser at `http://localhost:3000` |
| Continue.dev | ✅ VS Code extension, always active | `Ctrl+Shift+L` in VS Code |

**On a fresh boot, your LLM stack is:**
1. Ollama running (tray icon) — terminal access and API ready immediately
2. Open WebUI running (Docker) — browser chat ready immediately
3. Continue.dev active in VS Code — autocomplete ready when you open VS Code
4. LM Studio — launch on demand

---

## 8 — Full Workflow: From Zero to Working

### 8.1 On macOS (preparation — run once)

```bash
# 1. Run the generator to produce all platform files
chmod +x ~/bootstrap/generate.sh
~/bootstrap/generate.sh --tier desktop     # or: --tier laptop

# 2. Update shared files (remove Android/macOS-specific content)
#    See section 3 for what to move/delete

# 3. Update .zshrc sourcing loop (section 1.3)

# 4. Commit everything
config add platform/ bootstrap/ .aliases .functions .zshrc .exports
config commit -m "Add cross-platform dotfiles with platform isolation"
config push
```

### 8.2 On Windows (one-shot from zero)

```
Step 1: Open PowerShell as Administrator
Step 2: Download and run the Windows bootstrap:

    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/williammeger/dotfiles/main/bootstrap/windows.ps1" -OutFile "$env:TEMP\bootstrap.ps1"
    & "$env:TEMP\bootstrap.ps1" -Tier desktop

Step 3: Reboot (required for WSL2)

Step 4: Open WezTerm (launches into WSL2 automatically)

Step 5: Run the Linux bootstrap (first-time WSL2 setup):

    # Clone bootstrap via curl first (bare repo not yet present)
    curl -fsSL https://raw.githubusercontent.com/williammeger/dotfiles/main/bootstrap/linux.sh -o ~/bootstrap-linux.sh
    chmod +x ~/bootstrap-linux.sh
    ~/bootstrap-linux.sh --tier desktop
    rm ~/bootstrap-linux.sh

Step 6: Pull LLM models:

    ollama pull llama3.3:70b          # ~40 GB download
    ollama pull qwen2.5-coder:32b     # ~20 GB download
    ollama pull qwen2.5-coder:7b      # ~5 GB download

Step 7: Verify (from within WezTerm, which opens WSL2):

    tmux new -s verify        # should open 8-pane layout (your tmux config)
    config status             # should show clean working tree
    ai "hello"                # should get LLM response (uses env-local helper)
```

### 8.3 Laptop Variant

Same steps, replace `--tier desktop` with `--tier laptop` everywhere. The
differences are:
- `.wslconfig`: 16 GB memory cap instead of 32 GB
- Ollama: 2 concurrent models instead of 3
- Model selection: 14B models instead of 32B (see section 7.1)

---

## 9 — Verification Checklist

```bash
# ── Shell ──────────────────────────────────────────────────────────────────
echo $SHELL                  # → /usr/bin/zsh
echo $ZSH_THEME              # → lambda

# ── Dotfiles ───────────────────────────────────────────────────────────────
config status                # → clean
config sparse-checkout list  # → no macos dirs

# ── tmux ───────────────────────────────────────────────────────────────────
tmux new -s verify           # → opens 8-pane 4×2 layout (set-hook)

# ── vim ────────────────────────────────────────────────────────────────────
vim +PlugStatus +q           # → all plugins installed

# ── Tools ──────────────────────────────────────────────────────────────────
git --version && gh --version && mise --version

# ── Platform files ─────────────────────────────────────────────────────────
ls ~/platform/linux/         # → extra, aliases-local, env-local
cat ~/platform/linux/extra   # → Linux PATH, mise activation

# ── Graphics (run from PowerShell or cmd) ──────────────────────────────────
glslangValidator --version   # → Vulkan SDK present
dxc /help                    # → Windows SDK HLSL compiler

# ── LLM ────────────────────────────────────────────────────────────────────
ollama list                  # → shows pulled models
ai "hello"                   # → response from LLM via WSL2 bridge
curl http://localhost:3000   # → Open WebUI running (if Docker started)
```

---

## 10 — Platform Isolation Summary

| What | macOS gets | Windows/WSL2 gets | Neither gets |
|---|---|---|---|
| `.aliases` (shared) | ✅ | ✅ | |
| `.tmux.conf` | ✅ | ✅ (WSL2) | |
| `.vimrc` + `.vim/` | ✅ | ✅ | |
| `platform/macos/*` | ✅ | ❌ (sparse-checkout) | |
| `platform/linux/*` | ❌ (sparse-checkout) | ✅ | |
| `platform/windows/*` | ❌ (sparse-checkout) | ✅ | |
| `.bin/install.sh` | ✅ | ❌ (sparse-checkout) | |
| `bootstrap/windows.ps1` | ❌ | ✅ | |
| `bootstrap/linux.sh` | ❌ | ✅ | |
| Android SDK refs | ❌ (removed) | ❌ (removed) | ✅ deleted |
| `adb()`, `studio()` | ❌ (removed) | ❌ (removed) | ✅ deleted |
| `gradle-completion` | ❌ (removed) | ❌ (removed) | ✅ deleted |

---

## Appendix A — `.wslconfig` Reference

**Critical:** Windows defaults WSL2 memory to `min(50% RAM, 8 GB)`. On a
128 GB machine that means **only 8 GB** unless you override it.

| Setting | Desktop (128 GB) | Laptop (64 GB) |
|---|---|---|
| `memory` | 32GB | 16GB |
| `processors` | 12 | 8 |
| `swap` | 8GB | 4GB |
| `nestedVirtualization` | true | omitted |
| `autoMemoryReclaim` | gradual | gradual |
| `sparseVhd` | true | true |

**Rationale:** Give WSL2 enough for tmux + builds + shader CLI tools, but
leave the majority for native Windows (Ollama, engines, Blender all need
Windows-side RAM).

---

## Appendix B — File I/O Gotcha

Files on `/mnt/c/` (Windows filesystem accessed from WSL2) are 3–5× slower
than native ext4 inside WSL2.

**Rule:** Keep all source code and dotfiles inside `~/` (WSL2 ext4). Never
`cd /mnt/c/Users/.../Projects` for dev work. The only cross-filesystem
operations should be deploying configs (WezTerm, PowerShell profile) which
is a one-time copy, not ongoing I/O.

---

## Appendix C — GPU Considerations for LLM

Both Ollama and LM Studio automatically detect your NVIDIA GPU and use it.
"GPU offload" means putting part (or all) of a model in your graphics card's
dedicated memory (VRAM) instead of system RAM — this makes responses faster.

**Desktop (128 GB RAM — GPU TBD):**
- If you have a 24 GB VRAM GPU (e.g., RTX 4090): offload 30–40 layers of the
  70B model → dramatically faster responses
- If you have a 12 GB VRAM GPU (e.g., RTX 4070 Ti): the 7B model fits entirely;
  14B/32B get partial offload
- Ollama auto-detects and decides layer count; override with `OLLAMA_GPU_LAYERS`
  if you want manual control

**Laptop (64 GB RAM + RTX 3070 Laptop — 8 GB VRAM):**
- `qwen2.5-coder:7b` → fully offload to GPU (~5 GB fits in 8 GB VRAM, fastest possible)
- `qwen2.5-coder:14b` → partial offload (~20 layers on GPU, rest on CPU RAM)
- `llama3.3:70b-q3_K_M` → CPU-only (too large for 8 GB VRAM to help meaningfully)
- RenderDoc + Vulkan validation layers work natively on the 3070
- Game engines (Godot, UE5) render at full GPU speed — 8 GB VRAM is fine for dev

**Recommended Ollama strategy for the laptop:**
- Keep `qwen2.5-coder:7b` loaded on GPU at all times → instant autocomplete
- Run 14B/70B models on CPU RAM when needed (64 GB makes this comfortable)
- You won't see a spinner — 14B on 64 GB DDR5 responds in 2–5 seconds

Override GPU layer count (optional — Ollama usually picks well automatically):
```powershell
# Only set this if you want manual control. Delete the variable to go back to auto.
[Environment]::SetEnvironmentVariable("OLLAMA_GPU_LAYERS", "35", "User")

# To remove (return to auto-detection):
[Environment]::SetEnvironmentVariable("OLLAMA_GPU_LAYERS", $null, "User")
```
