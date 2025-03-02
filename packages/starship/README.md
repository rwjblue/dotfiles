# Starship Configuration

This directory contains modular Starship prompt configurations designed to
support both `jj` and `git` version control systems.

## Overview

These configuration files are processed by the `cache-shell-startup` tool and linked into `~/.config/starship/`. The system allows for easy switching between version control-specific configurations.

## Usage

By default, the system assumes `jj` is being used. When working in Git
repositories, override the configuration with:

```zsh
export STARSHIP_CONFIG="$HOME/.config/starship/git.toml"
```

## Build Process

These configuration files are compiled by the `cache-shell-startup` tool, which processes any commands embedded in the configurations (using `# CMD:` directives) and creates the final configurations in `packages-dist/starship/` which is symlinked into `~/.config/starship/`.
