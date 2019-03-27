#!/bin/sh
set -eu

CWD=$(pwd)
SWD=$(cd $(dirname $0) && pwd)

# trap
trap 'echo -e "\nabort!" ; exit 1' 1 2 3 15

DOTFILES_PATH=$(dirname $SWD)

set -x

cd $HOME

ln -nfs $DOTFILES_PATH/.plex      .plex
ln -nfs $DOTFILES_PATH/.bundle    .bundle
ln -nfs $DOTFILES_PATH/.gemrc     .gemrc
ln -nfs $DOTFILES_PATH/.gitconfig .gitconfig
ln -nfs $DOTFILES_PATH/.npmrc     .npmrc
ln -nfs $DOTFILES_PATH/.vimrc     .vimrc
ln -nfs $DOTFILES_PATH/.zprofile  .zprofile
ln -nfs $DOTFILES_PATH/.zshrc     .zshrc

set +x

exit 0
