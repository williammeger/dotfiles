#!/bin/bash

# Install command-line tools with homebrew

# use latest
brew update

# upgrade existing
brew upgrade

# editor
brew install vim --with-override-system-vi

# Bash 4
# Note: don’t forget to add `/usr/local/bin/bash` to `/etc/shells` before running `chsh`.
brew install bash

brew install bash-completion

brew install homebrew/completions/brew-cask-completion

# other useful binaries
brew install git
brew install node
brew install tree

# android tools
brew install android-platform-tools
brew install maven
brew install ant
brew install gradle
brew install pidcat #color dat logcat

# remove outdated versions from cellar
brew cleanup
