# Repository Guidelines

## Repository Purpose
- Public dotfiles repo to bootstrap and maintain a workstation (macOS/Linux).
- Keep reusable, non-sensitive config here; private or work-specific overrides live in `local-packages/`.

## Project Structure & Module Organization
- `install` is the primary setup entrypoint; it applies dotfiles and system deps.
- `mise/config.toml` and `mise/tasks/` define mise taskrunner automation (e.g., `brew:*`, `nvim:*`, `system:*`).
- `Brewfile` captures Homebrew packages managed by tasks.
- `packages/` contains versioned tooling and editor configs (Neovim, Hammerspoon, binutils).
- `packages-dist/` holds generated shell config outputs. It is gitignored and rebuilt by `binutils:cache-shell-startup` (run via `shell:update`); edit the sources in `packages/` instead.
- `~/src/github/malleatus/shared_binutils` provides shared task utilities (setup-local-dotfiles, symlink generation). Tasks read its location from `SHARED_BINUTILS_PATH` in `mise/config.toml`, which must match the path dependencies in `packages/binutils/Cargo.toml`.
- Agent skills live in `packages/agents/skills/` (shared by all tools). `packages/codex/skills/` is only for Codex-specific skills; `mise run skills:check` enforces no duplicates.

## Build, Test, and Development Commands
- `./install`: System setup (tools, dotfiles, Neovim). Use on a new machine.
- `FORCE=true ./install`: Reinstall, replacing existing links and moving existing files to `~/.local/state/dotfiles/backups/<timestamp>/`.
- `mise tasks`: List available tasks.
- `mise run install`: Run full multi-step setup.
- `mise run brew:install`: Install Homebrew and packages from `Brewfile`.
- `mise run nvim:restore`: Restore Neovim plugins to `packages/nvim/lazy-lock.json`.
- `mise run binutils:install`: Clone/build `shared_binutils`, build local binutils, set up symlinks.
- `mise run dot:install`: Link/copy dotfiles and run local-dotfiles setup.
- `mise run cursor:skills-sync`: Copy agent skills (including private ones from `local-packages/`) into Cursor's synced store for Cloud Agents. Rerun after editing skills; `dot:install` runs it too.

## Local Dotfiles Workflow
- `local-packages/` is a separate private repo; it is expected to exist alongside this repo.
- `mise run dot:install` invokes `setup-local-dotfiles` (via `shared_binutils`) to wire in local overrides.
- Keep local-only or work-specific files out of this repo; put them in the local dotfiles repo.

## Coding Style & Naming Conventions
- Mise tasks and `scripts/` are bash (`#!/usr/bin/env bash`, `set -euo pipefail`); name scripts descriptively (e.g., `commit_changed_file.sh`). Interactive shell config targets `zsh`.
- Indentation is 2 spaces in YAML, Lua, and shell scripts; follow existing file style before introducing new rules.
- Task names use a `namespace:verb` pattern (e.g., `nvim:update`); defined by directory structure under `mise/tasks/`.

## Testing Guidelines
- CI (`.github/workflows/ci.yml`) runs shellcheck at warning severity, `skills:check`, cargo fmt/clippy/test for `packages/binutils`, and `agent-review:test`.
- Beyond that, validate changes by running the relevant task or script.

## Commit & Pull Request Guidelines
- This repo uses `jj` for source control; keep commits small and imperative.
- If you only change a single file, `scripts/commit_changed_file.sh` can commit it in one step.
- PRs should include a brief summary, the tasks/commands run, and user-impacting changes.

commit-message-default: auto

## Security & Configuration Notes
- This is a public repo: do not add private keys, secrets, or work-specific settings here.
- Put private or work-only config in `local-packages/` (a separate private repo) and keep this repo generic.
- These dotfiles modify shell startup, package installs, and editor state; review scripts before running.
