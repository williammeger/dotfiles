#!/bin/bash
set -e

REPO="https://github.com/williammeger/dotfiles.git"
CFG_DIR="$HOME/.cfg"
BACKUP_DIR="$HOME/.dotfiles-backup"

function config {
  /usr/bin/git --git-dir="$CFG_DIR" --work-tree="$HOME" "$@"
}

# Preflight: Homebrew
if ! command -v brew &>/dev/null; then
  echo "⚠️  Homebrew not found. Install it first:"
  echo '    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
  exit 1
fi

# Preflight: avoid re-running on existing install
if [ -d "$CFG_DIR" ]; then
  echo "⚠️  $CFG_DIR already exists. To reinstall, remove it first: rm -rf $CFG_DIR"
  exit 1
fi

# Install oh-my-zsh (required before .zshrc is sourced)
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  echo "→ Installing oh-my-zsh..."
  RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# Ensure .cfg is ignored before cloning
grep -qxF ".cfg" "$HOME/.gitignore" 2>/dev/null || echo ".cfg" >> "$HOME/.gitignore"

# Clone
echo "→ Cloning dotfiles..."
git clone --bare "$REPO" "$CFG_DIR"

# Disable sparse-checkout (bare clone won't have the patterns file)
config config core.sparseCheckout false
config config core.sparseCheckoutCone false

# Attempt checkout — back up any conflicting files first
mkdir -p "$BACKUP_DIR"
if ! config checkout 2>/dev/null; then
  echo "→ Backing up conflicting files to $BACKUP_DIR..."
  config checkout 2>&1 | grep -E "^\s+" | awk '{print $1}' | while IFS= read -r file; do
    mkdir -p "$BACKUP_DIR/$(dirname "$file")"
    mv "$HOME/$file" "$BACKUP_DIR/$file" 2>/dev/null || true
  done
  config checkout
fi
config config status.showUntrackedFiles no

echo ""
echo "✅ Dotfiles installed."
[ -n "$CONFLICTS" ] && echo "   Pre-existing files backed up to: $BACKUP_DIR"
echo "   Reload your shell or run: source ~/.zshrc"
