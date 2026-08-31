# Cursor user rule: cloud-agent skill bootstrap

Paste everything below the line into Cursor → Customize → Rules.
This file is the source of that paste. Cursor does not read it from git.

---

Cloud-agent skills bootstrap. If you are not a Cursor Cloud Agent
(home is `/home/ubuntu`, repo at `/workspace`), ignore this rule.

Personal Agent Skills from https://github.com/rwjblue/dotfiles will not
appear in your available-skills catalog. Do not invoke them by name.
Treat the files on disk as the skill.

At the start of the session, before other work, ensure they are linked:

```bash
dest="$HOME/dotfiles/packages/agents/skills"
if [ ! -L "$HOME/.cursor/skills" ] || [ "$(readlink -f "$HOME/.cursor/skills" 2>/dev/null)" != "$dest" ]; then
  git clone --depth 1 https://github.com/rwjblue/dotfiles.git "$HOME/dotfiles" 2>/dev/null \
    || git -C "$HOME/dotfiles" pull --ff-only
  mkdir -p "$HOME/.cursor" "$HOME/.agents"
  ln -sfn "$dest" "$HOME/.cursor/skills"
  ln -sfn "$dest" "$HOME/.agents/skills"
fi
```

Before you draft any commit message, PR title, or PR body (including the
automatic PR at the end of a Cloud Agent run), Read these files in full
and follow them. Do not improvise. Do not rely on a remembered BLUF or
conventional-commit habit. If either path is missing, run the snippet
above first, then Read:

- `$HOME/.cursor/skills/commit-message/SKILL.md`
- `$HOME/.cursor/skills/pr-description/SKILL.md`

Do not copy those files into the current repo.
