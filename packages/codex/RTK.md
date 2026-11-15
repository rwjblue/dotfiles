# RTK - Rust Token Killer

Run shell commands directly by default. Use RTK for supported commands when
their output is verbose and a summary is enough.

## Usage

```bash
# Use compressed output for a quick overview:
rtk git status
rtk git log --oneline -20

# Run commands directly when you need details or exact output:
git diff
rg -n 'pattern' src
```

If RTK prints a recovery path, use it to inspect the saved output. Otherwise,
rerun a read-only command directly if you need the original output.
