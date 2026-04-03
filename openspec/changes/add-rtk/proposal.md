## Why

AI coding sessions (Claude Code, Codex) consume significant tokens on raw shell output — verbose git logs, build traces, test output, and directory listings flood the context window with noise. RTK (Rust Token Killer) is a CLI proxy that compresses shell output before it reaches the agent, claiming 60-90% savings on Bash commands (net ~17-27% overall since built-in tools bypass Bash). Even conservative savings improve session longevity, reasoning quality, and cost. The tool is young (pre-1.0, ~10 weeks old) so we need a cautious, auditable integration that's easy to evaluate on updates and roll back if needed.

## What Changes

- Install RTK via Homebrew (`Brewfile`)
- Add RTK config (`packages/rtk/`) with conservative defaults: tee mode always-on, excluded commands for compilers/test runners
- Add Claude Code PreToolUse hook for transparent Bash command rewriting (managed in `packages/claude/`, not via `rtk init`)
- Add Codex AGENTS.md instructions for RTK prefixing (managed in `packages/codex/`, not via `rtk init`)
- Add a mise task (`rtk:audit`) to diff current RTK version behavior against a known-good baseline, making re-evaluation on updates straightforward
- Pin RTK version in Brewfile to avoid silent upgrades
- Add an RTK evaluation skill or spec that documents what to check when upgrading RTK versions

## Capabilities

### New Capabilities

- `rtk-integration`: Installation, configuration, and hook setup for RTK across Claude Code and Codex
- `rtk-evaluation`: Process and tooling for auditing RTK behavior on version upgrades — what to check, how to verify compression isn't hiding important output, and how to diff behavior between versions

### Modified Capabilities

_(none — this adds new config, doesn't change existing specs)_

## Impact

- **Brewfile**: New formula addition (pinned version)
- **packages/claude/**: New hook script, settings.json hook entry, RTK.md awareness doc
- **packages/codex/**: New AGENTS.md with RTK instructions
- **packages/rtk/**: New package directory with config.toml
- **mise/tasks/dot/install**: New symlink entries for RTK config and hook
- **mise/tasks/rtk/**: New task namespace for audit/evaluation tooling
- **Dependencies**: Requires `jq` (likely already installed) and `rtk` binary
