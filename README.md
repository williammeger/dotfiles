# dotfiles

Personal system configuration files managed via a [bare git repo](https://www.atlassian.com/git/tutorials/dotfiles) — no symlinks required.

---

## New Machine Setup

### 1. Prerequisites

```sh
# Install Homebrew (required by several dotfiles at load time)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install GitHub CLI and authenticate (repo is private — this is required)
brew install gh
gh auth login
gh auth setup-git      # registers gh as the git credential helper
```

### 2. Bootstrap

Because the repo is private, raw `curl` from GitHub will 404 without auth.
After authenticating with `gh`, fetch and run the install script:

```sh
gh api repos/williammeger/dotfiles/contents/.bin/install.sh \
  --jq '.content' | base64 -d | bash
```

Or clone to a temp location and run locally:

```sh
git clone https://github.com/williammeger/dotfiles.git /tmp/dotfiles-bootstrap
bash /tmp/dotfiles-bootstrap/.bin/install.sh
rm -rf /tmp/dotfiles-bootstrap
```

### 3. Manual alternative

If you prefer to run the steps yourself:

```sh
echo ".cfg" >> ~/.gitignore

git clone --bare https://github.com/williammeger/dotfiles.git $HOME/.cfg

alias config='/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME'

mkdir -p ~/.dotfiles-backup
config checkout 2>&1 | egrep "\s+\." | awk '{print $1}' | xargs -I{} mv {} ~/.dotfiles-backup/{}
config checkout

config config status.showUntrackedFiles no
```

Then reload your shell:

```sh
source ~/.zshrc
```

### 4. Git identity

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