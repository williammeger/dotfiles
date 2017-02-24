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

#git stuff
parse_git_branch() {
     git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
}
export PS1="\u@\h \[\033[32m\]\w\[\033[33m\]\$(parse_git_branch)\[\033[00m\] $ "
