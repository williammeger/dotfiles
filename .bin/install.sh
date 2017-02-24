#!/bin/bash
# awesome install script by Nicola Paolucci
# https://bitbucket.org/durdn/cfg

git clone --bare https://github.com/williammeger/dotfiles.git $HOME/.dotfiles
function config {
   /usr/local/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME $@
}
mkdir -p .dotfiles-backup
config checkout
if [ $? = 0 ]; then
  echo "Checked out config.";
  else
    echo "Backing up pre-existing dot files.";
    config checkout 2>&1 | egrep "\s+\." | awk {'print $1'} | xargs -I{} mv {} .dotfiles-backup/{}
fi;
config checkout
config config status.showUntrackedFiles no
