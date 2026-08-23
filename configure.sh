#!/bin/sh
set -eu

SWD=$(cd "$(dirname "$0")" && pwd)

# trap
trap 'printf "\nabort!\n" ; exit 1' 1 2 3 15

( sh "$SWD"/init/link-dotfiles.sh )

# git-secrets
# templatedir is declared in .gitconfig but the hooks are not part of it.
# Install them once so new repositories pick them up on init/clone.

[ -d "$HOME/.git-templates/git-secrets/hooks" ] || \
  git secrets --install "$HOME/.git-templates/git-secrets"

# The template only fires at init/clone. This repository was cloned before the
# template existed, so it needs the hooks installed directly. -f makes it idempotent.

git secrets --install -f "$SWD" > /dev/null

# zsh

ZSH_PATH=$(which zsh)
USER_SHELL=$(dscl localhost -read Local/Default/Users/"$USER" UserShell | cut -d' ' -f2)

if ! grep "$ZSH_PATH" /etc/shells > /dev/null; then
  sudo -- sh -c "echo $ZSH_PATH >> /etc/shells"
fi

if [ "$ZSH_PATH" != "$USER_SHELL" ]; then
  chsh -s "$ZSH_PATH"
fi

# zsh -c "compaudit | xargs ls -ld"

exit 0
