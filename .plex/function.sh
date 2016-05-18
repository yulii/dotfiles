# Repository Management {{{

export PLEX_PROJECT_ROOT=$HOME
export PLEX_PROJECT_FIND_MAX_DEPTH=8
function find-projects() {
  find ${1:-$PLEX_PROJECT_ROOT} -name ".*" -type d -maxdepth $PLEX_PROJECT_FIND_MAX_DEPTH -prune -o -name ".git" -type d -maxdepth $PLEX_PROJECT_FIND_MAX_DEPTH | grep ".git$" | sed -e 's/\/.git$//'
}

alias sp='cd "$(find-projects | peco)"'

# }}}


function alpine() {
  echo "docker run -it --rm alpine:${1:-latest} /bin/sh"
  docker run -it --rm alpine:${1:-latest} /bin/sh
}
function centos() {
  echo "docker run -it --rm centos:${1:-latest} /bin/bash"
  docker run -it --rm centos:${1:-latest} /bin/bash
}
function ubuntu() {
  echo "docker run -it --rm ubuntu:${1:-latest} /bin/bash"
  docker run -it --rm ubuntu:${1:-latest} /bin/bash
}
