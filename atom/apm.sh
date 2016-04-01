#!/bin/sh
set -eu
set -x

CWD=$(pwd)
SWD=$(cd $(dirname $0) && pwd)

# trap
trap 'echo -e "\nabort!" ; exit 1' 1 2 3 15

# config {{{
PACKAGES_FILE="$SWD/packages.list"
# }}}

function apm_install() {
  cd $SWD && apm install --packages-file $PACKAGES_FILE
}

function apm_dump() {
  [ -f $PACKAGES_FILE ] && rm $PACKAGES_FILE
  apm list --installed --bare > $PACKAGES_FILE
}

function apm_save() {
  git checkout master
  apm_dump
  git add $PACKAGES_FILE && git commit -m 'update apm installed list' && git push
}

case "$1" in
  install) apm_install ;;
  dump)    apm_dump    ;;
  save)    apm_save    ;;
  *)       apm_install ;;
esac

exit 0

