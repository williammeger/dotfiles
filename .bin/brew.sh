#!/bin/bash

# Install command-line tools with homebrew

# use latest
brew update

# upgrade existing
brew upgrade

# editor
brew install vim --with-override-system-vi

# other useful binaries
brew install git
brew install node
brew install tree

brew install java

# android tools
brew install android-platform-tools
brew install maven
brew install ant
brew install gradle
brew install pidcat #color dat logcat

# remove outdated versions from cellar
brew cleanup
