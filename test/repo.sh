#!/bin/sh
# Repository checks. Exit 0 means every check below actually ran.
set -eu

cd "$(dirname "$0")/.."

# Missing tooling is an environment fault, not a repository fault. Bail out
# before any check runs so that exit 0 never means "some checks were skipped".
for c in git jq shellcheck git-secrets; do
  command -v "$c" >/dev/null 2>&1 && continue
  printf 'ERROR  %s is not installed. Run: make install\n' "$c" >&2
  exit 1
done

fail=0
ng() { printf 'NG  %s\n' "$1"; fail=1; }
ok() { printf 'ok  %s\n' "$1"; }

# File lists go through temporary files so that a path with a space
# survives, and so the reading loops stay out of a subshell.
# An argument-less mktemp ignores TMPDIR on macOS and reaches for a path the
# Bash sandbox denies, so name the template under TMPDIR explicitly.
scripts=$(mktemp "${TMPDIR:-/tmp}/repo-scripts.XXXXXX")
tracked=$(mktemp "${TMPDIR:-/tmp}/repo-tracked.XXXXXX")
trap 'rm -f "$scripts" "$tracked"' EXIT

git ls-files '*.sh' >"$scripts"
git ls-files >"$tracked"

# Shell syntax
while IFS= read -r f; do
  if sh -n "$f" 2>/dev/null; then ok "syntax $f"; else ng "syntax $f"; fi
done <"$scripts"

# Static analysis
if xargs shellcheck -s sh <"$scripts"; then ok "shellcheck"; else ng "shellcheck"; fi

# Config files parse
if git config --list --file .gitconfig >/dev/null 2>&1; then
  ok ".gitconfig parses"
else
  ng ".gitconfig parses"
fi

if jq -e . claude/settings.json >/dev/null 2>&1; then
  ok "settings.json parses"
else
  ng "settings.json parses"
fi

# A missing trailing newline used to drop the last entry silently
if [ -z "$(tail -c1 init/links)" ]; then
  ok "init/links ends with a newline"
else
  ng "init/links has no trailing newline"
fi

# Every link source exists
linked=$(grep -vE '^(#|$)' init/links | cut -d' ' -f1)
for p in $linked; do
  if [ -e "$p" ]; then ok "link source $p"; else ng "link source missing: $p"; fi
done

# Every linkable file is linked
exempt="CLAUDE.md .gitallowed .gitattributes .gitignore Makefile README.md configure.sh"
for f in $(git ls-files | grep -v /) $(git ls-files 'claude/*'); do
  case " $exempt " in *" $f "*) continue ;; esac
  if printf '%s\n' "$linked" | grep -qx "$f"; then
    ok "linked $f"
  else
    ng "not listed in init/links: $f"
  fi
done

# Secret detection stays configured
n=$(git config --file .gitconfig --get-all secrets.patterns | wc -l | tr -d ' ')
if [ "$n" -ge 7 ]; then ok "secrets.patterns ($n)"; else ng "secrets.patterns shrank to $n"; fi

for e in .DS_Store .gitconfig.secret .secrets.env tmp/; do
  if grep -qx "$e" .gitignore; then ok "ignored $e"; else ng "missing from .gitignore: $e"; fi
done

# Every target shows up in make help
for t in $(grep -oE '^[a-zA-Z_-]+:' Makefile | tr -d ':'); do
  [ "$t" = "help" ] && continue
  if grep -qE "^$t:.*##" Makefile; then ok "documented $t"; else ng "no ## comment: $t"; fi
done

# Tracked files carry no secrets.
# The binary is a prerequisite, checked above. Its patterns come from .gitconfig
# and only take effect once linked, so an unconfigured git-secrets is a real NG.
if ! git secrets --list >/dev/null 2>&1; then
  ng "git secrets has no patterns (run: make setup)"
elif xargs git secrets --scan <"$tracked" >/dev/null 2>&1; then
  ok "no secrets in tracked files"
else
  ng "git secrets matched a tracked file"
fi

exit $fail
