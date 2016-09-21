#!/bin/sh
set -eu
set -x

CWD=$(pwd)
SWD=$(cd $(dirname $0) && pwd)

# trap
trap 'echo -e "\nabort!" ; exit 1' 1 2 3 15

# config {{{
BREW_FILE="$SWD/Brewfile"
# }}}

function brewdle_install() {
  cd $SWD && brew bundle
}

function brewdle_dump() {
  [ -f $BREW_FILE ] && rm $BREW_FILE
  brew bundle dump --file=$BREW_FILE
}

function brewdle_save() {
  git checkout master
  brewdle_dump
  git add $BREW_FILE && git commit -m 'update brew installed list' && git push
}

case "$1" in
  install) brewdle_install ;;
  dump)    brewdle_dump    ;;
  save)    brewdle_save    ;;
  *)       brewdle_install ;;
esac

exit 0

