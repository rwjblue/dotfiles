# Personal agent instructions

## Checkouts

- Reuse the current checkout unless I ask for an isolated one.
- When I ask for isolation, use `jj workspace add --colocate <destination>`
  in a Jujutsu-managed repo. Use a Git worktree if the repo only uses Git
  or jj is unavailable.

## Shell commands

- Prefix shell commands with `rtk` when it is available and no hook already
  applies it.
- Use `rtk proxy <command>` to get unfiltered output. RTK saves raw output in
  `~/.local/share/rtk/tee/`.
