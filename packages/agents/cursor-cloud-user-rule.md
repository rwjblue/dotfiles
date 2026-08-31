# Cursor user rule: cloud-agent skill bootstrap

Paste everything below the line into Cursor → Customize → Rules.
This file is the source of that paste. Cursor does not read it from git.

---

Cloud-agent skills bootstrap. If you are not a Cursor Cloud Agent
(home is `/home/ubuntu`, repo at `/workspace`), ignore this rule.

At the start of the session, before other work, ensure personal
Agent Skills from https://github.com/rwjblue/dotfiles are linked:

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

When writing a commit or PR, load `commit-message` and `pr-description`
from those skills. Do not copy them into the current repo.
