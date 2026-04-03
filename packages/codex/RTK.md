# RTK - Rust Token Killer

RTK compresses shell output for token savings. Prefix shell commands with `rtk` to get compressed output.

## Usage

```bash
# Instead of:
git status
git log --oneline -20

# Use:
rtk git status
rtk git log --oneline -20
```

## Bypassing Compression

Use `rtk proxy <cmd>` to run a command without filtering when you need full output.

## Full Output Recovery

Raw output is saved to `~/.local/share/rtk/tee/`. Check there if compressed output seems incomplete.
