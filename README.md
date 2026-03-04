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
mise run install              # Complete system setup - installs dependencies, builds utilities, configures dotfiles, and sets up Neovim
mise run binutils:install     # Build binutils and set up symlinks
mise run binutils:build       # Build shared_binutils and local binutils
mise run brew:install         # Install Homebrew and packages
mise run brew:update          # Update Brewfile with current packages and commit
mise run brew:upgrade         # Upgrade all Homebrew packages
mise run brew:cleanup         # Remove unused brew dependencies
mise run dot:install          # Link/copy dotfiles
mise run nvim:restore         # Restore Neovim plugins from lazy-lock.json
mise run nvim:update          # Update Neovim plugins and commit lock file
mise run nvim:commit          # Commit lazy-lock.json if changed
mise run shell:update         # Refresh shell startup cache and completions
mise run system:install       # Install all system dependencies
mise run tools:install        # Install mise-managed tools
mise run tools:update         # Update mise-managed tools
mise run tools:outdated       # List outdated tools
```

## Troubleshooting

To ensure Neovim supports strikethrough and undercurl support, follow [these instructions](https://wezfurlong.org/wezterm/faq.html#how-do-i-enable-undercurl-curly-underlines).

## Inspiration

This dotfiles repository was inspired by:

- [hjdivad/dotfiles](https://github.com/hjdivad/dotfiles)
- [dkarter/dotfiles](https://github.com/dkarter/dotfiles)
