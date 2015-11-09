#!/bin/sh
set -eu

CWD=$(pwd)
SWD=$(cd $(dirname $0) && pwd)

# trap
trap 'echo -e "\nabort!" ; exit 1' 1 2 3 15


apm install file-icons
apm install term2

# Auto-Complete
apm install autocomplete-paths

# Git
apm install git-plus
apm install git-control
apm install git-history

# Ruby
apm install ruby-slim
