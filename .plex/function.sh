# Repository Management {{{

export PLEX_PROJECT_ROOT=$HOME
export PLEX_PROJECT_FIND_MAX_DEPTH=8
function find-projects() {
  find ${1:-$PLEX_PROJECT_ROOT} -name ".*" -type d -maxdepth $PLEX_PROJECT_FIND_MAX_DEPTH -prune -o -name ".git" -type d -maxdepth $PLEX_PROJECT_FIND_MAX_DEPTH | grep ".git$" | sed -e 's/\/.git$//'
}

alias sp='cd "$(find-projects | peco)"'

# }}}

