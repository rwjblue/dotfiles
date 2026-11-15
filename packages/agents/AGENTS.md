# Personal agent instructions

## Checkouts

- Reuse the current checkout unless I ask for an isolated one.
- When I ask for isolation, use `jj workspace add --colocate <destination>`
  in a Jujutsu-managed repo. Use a Git worktree if the repo only uses Git
  or jj is unavailable.

## Shell commands

- Run shell commands directly by default. Use `rtk` for supported commands
  with noisy output when a summary is enough. Avoid wrapping commands a hook
  already rewrites.
- Use native commands when exact output matters, such as for scripts, diffs,
  and debugging. If a hook would rewrite the command, use
  `rtk bypass <command>`.
