# rwjblue/dotfiles

## install

```sh
./install
```

Start with Git and curl available on `PATH`. On macOS, setup installs Homebrew and the packages in `Brewfile`. On Linux, install a C toolchain, Make, pkg-config, Neovim, the Tree-sitter CLI, unzip, Zsh, zoxide, and Atuin through your distribution or their upstream packages before running the installer. The installer checks for these commands before installing the remaining tools.

To force a re-install (replacing existing links):

```sh
FORCE=true ./install
```

Existing files and directories that get replaced are moved to `~/.local/state/dotfiles/backups/<timestamp>/`, keeping their path relative to `$HOME`. Clear them all with `rm -rf ~/.local/state/dotfiles/backups`.

`shared_binutils` must be checked out at `../../malleatus/shared_binutils` relative to this repo; `binutils:install` clones it there if it is missing.

## Available Tasks

Run `mise tasks` for the current list with descriptions. The main entry points:

```console
mise run install              # Complete system setup - installs dependencies, builds utilities, configures dotfiles, and sets up Neovim
mise run dot:install          # Link/copy dotfiles
mise run tools:update         # Upgrade mise-managed tools (install does not upgrade)
mise run brew:upgrade         # Upgrade all Homebrew packages
mise run brew:update          # Preview changes to the Brewfile
mise run nvim:update          # Update Neovim plugins and commit lock file
mise run skills:check         # Fail if an agent skill is duplicated across skill directories
mise run agent-review:test    # Run agent-review.nvim tests headless
```

Use `brew update` directly to refresh Homebrew's package metadata. Use the Brewfile preview to decide which installed packages belong in the shared manifest.

## Troubleshooting

To ensure Neovim supports strikethrough and undercurl support, follow [these instructions](https://wezfurlong.org/wezterm/faq.html#how-do-i-enable-undercurl-curly-underlines).

## Inspiration

This dotfiles repository was inspired by:

- [hjdivad/dotfiles](https://github.com/hjdivad/dotfiles)
- [dkarter/dotfiles](https://github.com/dkarter/dotfiles)
