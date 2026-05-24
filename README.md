# dotfiles

Personal system configuration files managed via a [bare git repo](https://www.atlassian.com/git/tutorials/dotfiles) — no symlinks required.

---

## New Machine Setup

### 1. Prerequisites

Install Homebrew first — it's required by several dotfiles at load time:

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### 2. Bootstrap

Run the install script directly:

```sh
curl -fsSL https://raw.githubusercontent.com/williammeger/dotfiles/main/.bin/install.sh | bash
```

Or manually:

```sh
# Prevent recursion issues
echo ".cfg" >> ~/.gitignore

# Clone bare repo
git clone --bare https://github.com/williammeger/dotfiles.git $HOME/.cfg

# Set up config alias for this session
alias config='/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME'

# Checkout files — backs up any conflicts to ~/.dotfiles-backup/
mkdir -p ~/.dotfiles-backup
config checkout 2>&1 | egrep "\s+\." | awk '{print $1}' | xargs -I{} mv {} ~/.dotfiles-backup/{}
config checkout

# Hide untracked files from config status
config config status.showUntrackedFiles no
```

### 3. Git identity

Set a per-repo git identity:

```sh
cat > ~/.gitconfig.personal << 'EOF'
[user]
    name = Your Name
    email = your@email.com
EOF

cat >> ~/.gitconfig << 'EOF'

[includeIf "gitdir:~/.cfg/"]
    path = ~/.gitconfig.personal
EOF
```

Verify:

```sh
config config user.email
```

---

## File Structure

| File | Purpose |
|---|---|
| `.aliases` | General shell aliases |
| `.exports` | Publicly safe environment exports |
| `.extra` | PATH construction, tool detection (Homebrew, VS Code, etc.) |
| `.functions` | Shell functions |
| `.bash_profile` | Bash entry point — sources all of the above |
| `.zshrc` | Zsh entry point (primary shell) — sources all of the above |
| `.gitconfig` | Global git config |
| `.gitconfig.personal` | Per-repo git identity override — **not tracked** |
| `.vimrc` / `.tmux.conf` | Editor and terminal multiplexer config |
| `.bin/install.sh` | Bootstrap script for new machines |

---

## Daily Workflow

The `config` alias wraps git for managing tracked dotfiles:

```sh
config status                  # see what's changed
config diff                    # review changes
config add ~/.aliases          # stage a file
config commit -m "feat: ..."   # commit
config push origin main        # push to remote
```

---

## Adding a New File to Tracking

```sh
config add ~/.newfile
config commit -m "track: add .newfile"
config push origin main
```

To stop tracking a file without deleting it locally:

```sh
config rm --cached ~/.filename
```