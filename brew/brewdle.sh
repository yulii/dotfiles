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
  cd $SWD && brew brewdle
}

function brewdle_dump() {
 [ -f $BREW_FILE ] && rm $BREW_FILE
 brew brewdle dump --file=$BREW_FILE
}

case "$1" in
  install) brewdle_install ;;
  dump)    brewdle_dump    ;;
  *)       brewdle_install ;;
esac

exit 0

