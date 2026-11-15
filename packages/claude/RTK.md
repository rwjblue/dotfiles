# RTK - Rust Token Killer

The PreToolUse hook can rewrite supported Bash commands to use RTK for shorter
output. Claude Code still applies its own permission rules to the command.

## Bypassing Compression

Run commands directly by default. Use `rtk bypass <command>` when you need
exact output and the hook would otherwise rewrite the command.

## Full Output Recovery

If RTK prints a recovery path, use it to inspect the saved output. Otherwise,
use `rtk bypass` to rerun a read-only command and get its original output.

## Meta Commands

```bash
rtk gain              # Show token savings analytics
rtk gain --history    # Show command usage history with savings
rtk bypass git diff   # Show the original Git diff
```
