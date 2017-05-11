# Load up other dotfiles ~/.aliases, etc

for file in ~/.{extra,bash_prompt,exports,aliases,functions}; do
    [ -r "$file" ] && source "$file"
done
unset file

#colorize
export GREP_OPTIONS='--color=auto' GREP_COLOR='1;32'
export CLICOLOR=1
