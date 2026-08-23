#!/bin/sh
set -eu

SWD=$(cd "$(dirname "$0")" && pwd)

# trap
trap 'printf "\nabort!\n" ; exit 1' 1 2 3 15

DOTFILES_PATH=$(dirname "$SWD")

# init/links is the single list of what gets linked.
# test/repo.sh and test/env.sh read the same file.

# The || keeps the last entry when the file has no trailing newline.
while read -r src dst || [ -n "${src:-}" ]; do
  case "$src" in '' | '#'*) continue ;; esac
  mkdir -p "$(dirname "$HOME/$dst")"
  ln -nfs "$DOTFILES_PATH/$src" "$HOME/$dst"
  printf 'linked %s -> %s\n' "$dst" "$src"
done <"$SWD/links"

exit 0
