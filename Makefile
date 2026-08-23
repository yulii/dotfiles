ATOM_PACKAGES_FILE := ./atom/packages.list
BREW_FILE := ./brew/Brewfile
MAX_PROCS := $(shell sysctl -n hw.ncpu | xargs -I{} expr {} - 1 || printf 1)

# test collides with the test/ directory, so every target is declared here.
.PHONY: help dump install cleanup-check colima-start upgrade test test-env \
  list-brew-uses setup

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

dump:  ## Export installed packages list
	brew bundle dump --file=$(BREW_FILE) --force

install:  ## Install packages listed in the Brewfile
	brew bundle --file=$(BREW_FILE)

cleanup-check:  ## Show packages not in Brewfile (dry run)
	brew bundle cleanup --file=$(BREW_FILE)

colima-start:  ## Start colima with restricted mounts
	colima start --arch aarch64 --vm-type vz --vz-rosetta \
	  --mount $$HOME/projects:w

upgrade:  ## Upgrade installed packages
	brew upgrade

test:  ## Check the repository
	@sh test/repo.sh

test-env:  ## Check that this machine matches the repository
	@sh test/env.sh

list-brew-uses:  ## List all installed formulae along with the number of formulae being used.
	brew list | xargs -P$(MAX_PROCS) -I{} sh -c 'brew uses --installed {} | wc -l | xargs printf "%20s is used by %2d formulae.\n" {}'

setup:  ## Run initial setup only once!
	./configure.sh
