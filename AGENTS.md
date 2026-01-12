# Repository Guidelines

## Repository Purpose
- Public dotfiles repo to bootstrap and maintain a workstation (macOS/Linux).
- Keep reusable, non-sensitive config here; private or work-specific overrides live in `local-packages/`.

## Project Structure & Module Organization
- `install` is the primary setup entrypoint; it applies dotfiles and system deps.
- `Taskfile.dist.yml` and `taskfiles/*.yml` define `go-task` automation (e.g., `brew:*`, `nvim:*`, `system:*`).
- `Brewfile` captures Homebrew packages managed by tasks.
- `packages/` contains versioned tooling and editor configs (Neovim, Hammerspoon, binutils).
- `packages-dist/` holds generated config outputs.
- `~/src/github/malleatus/shared_binutils` provides shared task utilities (setup-local-dotfiles, symlink generation).

## Build, Test, and Development Commands
- `./install`: System setup (tools, dotfiles, Neovim). Use on a new machine.
- `FORCE=true ./install`: Reinstall and clobber existing files.
- `task -l`: List available tasks.
- `task install`: Run full multi-step setup via Taskfile.
- `task brew:install`: Install Homebrew and packages from `Brewfile`.
- `task nvim:restore`: Restore Neovim plugins to `packages/nvim/lazy-lock.json`.
- `task binutils:install`: Clone/build `shared_binutils`, build local binutils, set up symlinks.
- `task dotfiles:install`: Link/copy dotfiles and run local-dotfiles setup.

## Local Dotfiles Workflow
- `local-packages/` is a separate private repo; it is expected to exist alongside this repo.
- `task dotfiles:install` invokes `setup-local-dotfiles` (via `shared_binutils`) to wire in local overrides.
- Keep local-only or work-specific files out of this repo; put them in the local dotfiles repo.

## Coding Style & Naming Conventions
- Shell scripts target `zsh`; keep scripts in `scripts/` and name them descriptively (e.g., `setup-rdev-nvim.zsh`).
- Indentation is 2 spaces in YAML, Lua, and shell scripts; follow existing file style before introducing new rules.
- Task names use a `namespace:verb` pattern (e.g., `nvim:update`); add new tasks in the corresponding `taskfiles/*.yml`.

## Testing Guidelines
- No repo-wide test runner; validate changes by running the relevant task or script.

## Commit & Pull Request Guidelines
- This repo uses `jj` for source control; keep commits small and imperative.
- If you only change a single file, `scripts/commit_changed_file.sh` can commit it in one step.
- PRs should include a brief summary, the tasks/commands run, and user-impacting changes.

## Security & Configuration Notes
- This is a public repo: do not add private keys, secrets, or work-specific settings here.
- Put private or work-only config in `local-packages/` (a separate private repo) and keep this repo generic.
- These dotfiles modify shell startup, package installs, and editor state; review scripts before running.
