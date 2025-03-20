# rwjblue/dotfiles

## install

```sh
./install
```

To force a re-install (clobbering existing files):

```sh
FORCE=true ./install
```

## Available Tasks

```console
task: Available tasks for this project:
* install:                Complete system setup - installs dependencies, builds utilities, configures dotfiles, and sets up Neovim
* binutils:install:       Build binutils and set up symlinks
* brew:cleanup:           Remove unused brew dependencies
* brew:install:           Install Homebrew and tools defined in Brewfile
* brew:update:            Update Brewfile with current brew packages and commit changes
* brew:upgrade:           Update Homebrew and upgrade all installed packages
* dotfiles:install:       Install dotfiles      (aliases: dot:install)
* nvim:commit:            Commits the lazy-lock.json file if changed
* nvim:restore:           Restores Neovim plugins to the state in lazy-lock.json
* nvim:update:            Updates Neovim plugins, CLI utils, and TreeSitter plugins
* shell:update:           Refreshes shell environment by updating startup cache and clearing completion cache
* system:install:         Install all system dependencies
```

## Troubleshooting

Test for undercurl with this command:

```sh
echo -e "\e[4:3mThis text has an undercurl\e[0m"
```

To ensure Neovim supports strikethrough and undercurl support, follow [these instructions](https://wezfurlong.org/wezterm/faq.html#how-do-i-enable-undercurl-curly-underlines).

## Inspiration

This repository was inspired by:

- [hjdivad/dotfiles](https://github.com/hjdivad/dotfiles)
- [dkarter/dotfiles](https://github.com/dkarter/dotfiles)

## New Machine Setup

1. Clone this repo - `git clone https://github.com/rwjblue/dotfiles.git ~/src/rwjblue/dotfiles`
2. Run `./install`
3. Alfred
   - Open
   - Register
   - Configure clipboard history
4. Install 1Password
   - Open
   - Register
   - Configure browser extension
5. Hammerspoon
   - Open
   - Open preferences
   - Enable accessibility
   - Enable "launch at startup"
6. Obsidian
   - Open
   - Configure sync
