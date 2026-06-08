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

### 3. Post-bootstrap: push credentials

The bootstrap clones via HTTPS (read-only, no auth needed). To push changes,
set up SSH so the dotfiles remote always uses your personal GitHub credentials:

**Generate a personal SSH key:**

```sh
ssh-keygen -t ed25519 -C "williammeger" -f ~/.ssh/id_ed25519_personal -N ""
```

**Add it to your personal GitHub:**

```sh
pbcopy < ~/.ssh/id_ed25519_personal.pub
# Go to https://github.com/settings/keys → New SSH key → paste and save
```

**Add the host alias** (if not already delivered by dotfiles):

```sh
cat >> ~/.ssh/config << 'EOF'

Host github.com-personal
  HostName github.com
  AddKeysToAgent yes
  UseKeychain yes
  IdentityFile ~/.ssh/id_ed25519_personal
EOF
```

**Switch the dotfiles remote to SSH:**

```sh
config remote set-url origin git@github.com-personal:williammeger/dotfiles.git
```

**Verify:**

```sh
ssh -T git@github.com-personal
# → "Hi williammeger! You've successfully authenticated..."
```

### 4. Work GitHub setup

For work repos, authenticate with your work account separately:

```sh
brew install gh
gh auth login          # authenticate with work account (william-meger)
gh auth setup-git
```

This registers `gh` as the credential helper for `github.com`. Since dotfiles
use `github.com-personal` as the SSH host, the two never cross.

### 5. Git identity

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