ATOM_PACKAGES_FILE := ./atom/packages.list
BREW_FILE := ./brew/Brewfile
# sysctl is denied inside the Bash sandbox, so ask getconf instead.
MAX_PROCS := $(shell getconf _NPROCESSORS_ONLN | xargs -I{} expr {} - 1 || printf 1)
# The colima VM takes half of the processors and a quarter of the memory, no
# less than colima's default of 2. Each is empty when hostinfo changes format.
HOST_CPUS := $(shell hostinfo | awk '/^[0-9]+ processors are logically available\.$$/ {print $$1}')
HOST_MEMORY := $(shell hostinfo | awk '/^Primary memory available: [0-9.]+ gigabytes$$/ {print int($$4)}')
COLIMA_CPUS := $(shell awk -v n='$(HOST_CPUS)' 'BEGIN {m = int(n / 2); print (m < 2 ? 2 : m)}')
COLIMA_MEMORY := $(shell awk -v n='$(HOST_MEMORY)' 'BEGIN {m = int(n / 4); print (m < 2 ? 2 : m)}')

# test collides with the test/ directory, so every target is declared here.
.PHONY: help dump install cleanup-check colima-start upgrade test test-env \
  list-brew-uses setup

# [manual] marks a target to run in a terminal: it writes outside the Bash
# sandbox, so it fails when Claude Code runs it.
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

dump:  ## Export installed packages list
	brew bundle dump --file=$(BREW_FILE) --force

install:  ## [manual] Install packages listed in the Brewfile
	brew bundle --file=$(BREW_FILE)

cleanup-check:  ## Show packages not in Brewfile (dry run)
	brew bundle cleanup --file=$(BREW_FILE)

colima-start:  ## [manual] Start colima with restricted mounts, sized to the machine
	$(if $(HOST_CPUS),,$(error hostinfo has no processor count; set HOST_CPUS=<n>))
	$(if $(HOST_MEMORY),,$(error hostinfo has no memory size; set HOST_MEMORY=<GiB>))
	colima start --arch aarch64 --vm-type vz --vz-rosetta \
	  --cpus $(COLIMA_CPUS) --memory $(COLIMA_MEMORY) \
	  --mount $$HOME/projects:w

upgrade:  ## [manual] Upgrade installed packages
	brew upgrade

test:  ## Check the repository
	@sh test/repo.sh

test-env:  ## Check that this machine matches the repository
	@sh test/env.sh

list-brew-uses:  ## List all installed formulae along with the number of formulae being used.
	brew list | xargs -P$(MAX_PROCS) -I{} sh -c 'brew uses --installed {} | wc -l | xargs printf "%20s is used by %2d formulae.\n" {}'

setup:  ## [manual] Run initial setup only once!
	./configure.sh
