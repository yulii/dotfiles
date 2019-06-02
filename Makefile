ATOM_PACKAGES_FILE = ./atom/packages.list
BREW_FILE = ./brew/Brewfile

dump:
	brew bundle dump --file=$(BREW_FILE) --force
	apm list --installed --bare > $(ATOM_PACKAGES_FILE)

install:
	brew bundle --file=$(BREW_FILE)
	apm install --packages-file $(ATOM_PACKAGES_FILE)

link:
	ls -d $(PWD)/.atom/* | xargs -I{} ln -nfs {} $(HOME)/.atom
