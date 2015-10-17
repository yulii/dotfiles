#!/bin/sh
set -eu

CWD=$(pwd)
SWD=$(cd $(dirname $0) && pwd)

# trap
trap 'echo -e "\nabort!" ; exit 1' 1 2 3 15

cd $HOME

ln -nfs $SWD/.plex      .plex
ln -nfs $SWD/.bundle    .bundle
ln -nfs $SWD/.gitconfig .gitconfig
ln -nfs $SWD/.vimrc     .vimrc
ln -nfs $SWD/.zprofile  .zprofile
ln -nfs $SWD/.zshrc     .zshrc

exit 0
