#!/bin/bash
#set -e
#set -u
#set -x

CWD=`pwd`
SWD=`(cd \`dirname $0\` && pwd)`


cd $HOME

ln -s $SWD/.zshrc .zshrc
