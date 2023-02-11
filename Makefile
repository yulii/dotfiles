ATOM_PACKAGES_FILE := ./atom/packages.list
BREW_FILE := ./brew/Brewfile
MAX_PROCS := $(shell sysctl -n hw.ncpu | xargs -I{} expr {} - 1 || printf 1)

.PHONY: help

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

dump:  ## Export installed packages list
	brew bundle dump --file=$(BREW_FILE) --force

install:
	brew bundle --file=$(BREW_FILE)

upgrade:
	brew upgrade

list-brew-uses:  ## List all installed formulae along with the number of formulae being used.
	brew list | xargs -P$(MAX_PROCS) -I{} sh -c 'brew uses --installed {} | wc -l | xargs printf "%20s is used by %2d formulae.\n" {}'

setup:  ## Run initial setup only once!
	./configure.sh
