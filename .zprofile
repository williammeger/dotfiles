
# Homebrew — must run before .zshrc so brew-installed tools are in PATH
if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi


# Added by Toolbox App
export PATH="$PATH:/Users/wiliammeger/Library/Application Support/JetBrains/Toolbox/scripts"


# Created by `pipx` on 2025-05-19 15:14:45
export PATH="$PATH:/Users/wiliammeger/.local/bin"
