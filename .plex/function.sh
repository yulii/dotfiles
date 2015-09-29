# Repository Management {{{

export PLEX_PROJECT_ROOT=$HOME
export PLEX_PROJECT_FIND_MAX_DEPTH=6
function find-projects() {
  find ${1:-$PLEX_PROJECT_ROOT} -name ".git" -type d -maxdepth $PLEX_PROJECT_FIND_MAX_DEPTH | sed -e 's/\/.git$//'
}

alias sp='cd "$(find-projects | peco)"'

# }}}
