# RTK - Rust Token Killer

RTK is active. All Bash commands are automatically rewritten through RTK via a PreToolUse hook for token savings.

## Bypassing Compression

Use `rtk proxy <cmd>` to run a command without any filtering when you need full unfiltered output.

## Full Output Recovery

Raw output from all commands is saved to `~/.local/share/rtk/tee/`. Check there if compressed output seems incomplete.

## Meta Commands

```bash
rtk gain              # Show token savings analytics
rtk gain --history    # Show command usage history with savings
rtk proxy <cmd>       # Execute raw command without filtering
```
