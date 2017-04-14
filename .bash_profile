# Load up other dotfiles ~/.aliases, etc

for file in ~/.{extra,exports,aliases,functions}; do
    [ -r "$file" ] && source "$file"
done
unset file

#colorize
export TERM=xterm-256color
export GREP_OPTIONS='--color=auto' GREP_COLOR='1;32'
export CLICOLOR=1
#export LSCOLORS="exfxcxdxcxegedabagacad"

# Customizing PS1 for ssh sessions
# Parse_git_branch() defined in ~/.functions 

if [ "$SSH_CLIENT" ]; then text=" ssh-session"
    export PS1='\[\e[1;37m\]\u@\[\e[m\]\[\e[1;33m\]\h:\[\e[m\]\[\e[1;32m\]\w\[\e[m\]\[\e[1;31m\]${text}$\[\e[m\] '
else
    export PS1="\u@\h \[\033[32m\]\w\[\033[33m\]\$(parse_git_branch)\[\033[00m\] $ "
fi
