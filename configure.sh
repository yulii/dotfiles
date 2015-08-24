#!/bin/sh
set -eu

CWD=$(pwd)
SWD=$(cd $(dirname $0) && pwd)

# trap
trap 'echo -e "\nabort!" ; exit 1' 1 2 3 15

cd $HOME

ln -s $SWD/.gitconfig .gitconfig
ln -s $SWD/.vimrc     .vimrc
ln -s $SWD/.zshrc     .zshrc

exit 0
