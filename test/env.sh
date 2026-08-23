#!/bin/sh
# Host checks. These read $HOME, so CI cannot run them.
set -eu

cd "$(dirname "$0")/.."
DOTFILES_PATH=$(pwd)

fail=0
ng() { printf 'NG  %s\n' "$1"; fail=1; }
ok() { printf 'ok  %s\n' "$1"; }

# Links point back to this repository
# The || keeps the last entry when the file has no trailing newline.
while read -r src dst || [ -n "${src:-}" ]; do
  case "$src" in '' | '#'*) continue ;; esac
  actual=$(readlink "$HOME/$dst" 2>/dev/null || true)
  if [ "$actual" = "$DOTFILES_PATH/$src" ]; then
    ok "link $dst"
  else
    ng "link $dst -> ${actual:-not a symlink}"
  fi
done <init/links

# git-secrets template is declared and present
d=$(git config --type=path --get init.templatedir 2>/dev/null || true)
case "$d" in
  "") ng "init.templatedir is not set" ;;
  *)
    if [ -d "$d/hooks" ]; then ok "templatedir $d"; else ng "templatedir declared but missing: $d"; fi
    ;;
esac

# Hooks come from the template alone. Nothing may redirect them away.
h=$(git config --get core.hooksPath 2>/dev/null || true)
if [ -z "$h" ]; then ok "core.hooksPath unset"; else ng "core.hooksPath overrides the template: $h"; fi

# The template only fires at init/clone, so confirm this clone actually got them
for h in pre-commit commit-msg prepare-commit-msg; do
  if [ ! -x ".git/hooks/$h" ]; then
    ng "hook $h missing (run: git secrets --install -f .)"
  elif grep -q 'git secrets' ".git/hooks/$h"; then
    ok "hook $h"
  else
    ng "hook $h does not call git secrets"
  fi
done

# Brewfile matches the machine
if brew bundle check --file=./brew/Brewfile >/dev/null 2>&1; then
  ok "Brewfile in sync"
else
  ng "Brewfile drifted from the machine"
fi

exit $fail
