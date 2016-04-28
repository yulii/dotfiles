#!/bin/sh
set -eu

CWD=$(pwd)
SWD=$(cd $(dirname $0) && pwd)

# trap
trap 'echo -e "\nabort!" ; exit 1' 1 2 3 15

# go get -v github.com/yulii/dotfiles/src/dots
bundle config --global jobs `expr $(sysctl -n hw.ncpu) - 1`
