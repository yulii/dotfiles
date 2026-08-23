#!/bin/sh
set -eu

CWD=$(pwd)
SWD=$(cd $(dirname $0) && pwd)

# trap
trap 'echo -e "\nabort!" ; exit 1' 1 2 3 15

( sh $SWD/init/link-dotfiles.sh )

# git-secrets
# templatedir is declared in .gitconfig but the hooks are not part of it.
# Install them once so new repositories pick them up on init/clone.

[ -d "$HOME/.git-templates/git-secrets/hooks" ] || \
  git secrets --install "$HOME/.git-templates/git-secrets"

# zsh

ZSH_PATH=$(which zsh)
USER_SHELL=$(dscl localhost -read Local/Default/Users/$USER UserShell | cut -d' ' -f2)

if ! grep $ZSH_PATH /etc/shells > /dev/null; then
  sudo -- sh -c "echo $ZSH_PATH >> /etc/shells"
fi

if [ $ZSH_PATH != $USER_SHELL ]; then
  chsh -s $(which zsh)
fi

# zsh -c "compaudit | xargs ls -ld"

exit 0
