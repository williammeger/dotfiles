#!/bin/bash

# Load up other dotfiles ~/.aliases, etc

for file in ~/.{aliases,functions}; do
    [ -r "$file" ] && source "$file"
done
unset file

#set up the paths
export PATH=/usr/local/bin:$PATH

#colorize
export CLICOLOR=1
export LSCOLORS="exfxcxdxcxegedabagacad"

#make PS1 show git branches 
export PS1="\u@\h \[\033[32m\]\w\[\033[33m\]\$(parse_git_branch)\[\033[00m\] $ "
