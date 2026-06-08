#!/bin/bash
set -e

REPO="https://github.com/williammeger/dotfiles.git"
CFG_DIR="$HOME/.cfg"

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

# Checkout (force overwrites any existing files)
echo "→ Checking out dotfiles..."
config checkout --force
config config status.showUntrackedFiles no

echo ""
echo "✅ Dotfiles installed."
echo "   Reload your shell or run: source ~/.zshrc"
