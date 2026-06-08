# dotfiles

Personal system configuration files managed via a [bare git repo](https://www.atlassian.com/git/tutorials/dotfiles) — no symlinks required.

---

## New Machine Setup

### 1. Prerequisites

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### 2. Bootstrap

```sh
curl -fsSL https://raw.githubusercontent.com/williammeger/dotfiles/main/.bin/install.sh | bash
```

That's it. Reload your shell (`source ~/.zshrc`) and the `config` alias is available.

### Reset (start over)

If something went wrong and you need to re-run the bootstrap:

```sh
rm -rf ~/.cfg ~/.oh-my-zsh ~/.dotfiles-backup
curl -fsSL https://raw.githubusercontent.com/williammeger/dotfiles/main/.bin/install.sh | bash
```

### 3. Post-bootstrap: push credentials

The repo is public so cloning needs no auth. To push changes, authenticate
with your personal GitHub account:

```sh
brew install gh
gh auth login --hostname github.com    # log in as williammeger
gh auth setup-git
```

Verify:

```sh
config push --dry-run origin main
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