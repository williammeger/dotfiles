# Load up other dotfiles ~/.aliases, etc

for file in ~/.{extra,bash_prompt,exports-local,exports,aliases,functions,env-android,aliases-android}; do
    [ -r "$file" ] && source "$file"
done
unset file

#colorize
export GREP_OPTIONS='--color=auto' GREP_COLOR='1;32'
export CLICOLOR=1

# tuning `cd`'ing

# Case-insensitive globbing (used in pathname expansion)
shopt -s nocaseglob;

# Correct spelling errors in arguments supplied to cd
shopt -s cdspell;

# Autocorrect on directory names to match a glob.
shopt -s dirspell 2> /dev/null

# Turn on recursive globbing (enables ** to recurse all directories)
shopt -s globstar 2> /dev/null

# Completion

# Git AutoCompletion
if [ -f `brew --prefix`/etc/bash_completion ]; then
    . `brew --prefix`/etc/bash_completion
fi

# NVM
export NVM_DIR=~/.nvm
source ~/.nvm/nvm.sh
eval "$(rbenv init -)"

