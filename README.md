## About
system configuration files
## Setup
Before cloning onto a new machine ensure that the following steps have been taken.

### Create alias

```shell
alias config='/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME'
```

### Ignore the config files dir
```shell
echo ".cfg" >> .gitignore
```
After the previous steps have been completed clone this repo by executing `install.sh`