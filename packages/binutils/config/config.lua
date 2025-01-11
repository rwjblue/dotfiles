local function jujutsu_project(config)
  local result = {}
  -- Copy all existing properties
  for k, v in pairs(config) do
    result[k] = v
  end

  -- Handle command property specially
  if not config.command then
    result.command = 'export GIT_DIR="$PWD.jj/repo/store/git"'
  else
    local commands = {
      'export GIT_DIR="$PWD.jj/repo/store/git"',
    }

    if type(config.command) == "string" then
      table.insert(commands, config.command)
    else
      for _, cmd in ipairs(config.command) do
        table.insert(commands, cmd)
      end
    end

    result.command = commands
  end

  return result
end

---@type Config
return {
  crate_locations = {
    "~/src/rwjblue/dotfiles/binutils/crates/",
    "~/src/malleatus/shared_binutils"
  },
  shell_caching = {
    source = "~/src/rwjblue/dotfiles/shells/",
    destination = "~/src/rwjblue/dotfiles/shells/dist/"
  },
  tmux = {
    sessions = {
      {
        name = "✅ todos",
        windows = {
          {
            name = "todos"
          }
        }
      },
      {
        name = "dotfiles",
        windows = {
          {
            name = "dotvim",
            path = "~/src/rwjblue/dotvim",
            command = "nvim"
          },
          {
            name = "dotfiles",
            path = "~/src/rwjblue/dotfiles",
            command = "nvim"
          },
          {
            name = "binutils",
            path = "~/src/rwjblue/dotfiles/binutils",
            command = "nvim"
          },
          {
            name = "shared_binutils",
            path = "~/src/malleatus/shared_binutils",
            command = "nvim"
          },
        }
      },
      {
        name = "🦨work",
        windows = {
          {
            name = "sniff-gh-copilot-usage",
            path = "~/src/rwjblue/sniff-gh-copilot-usage",
          }
        }
      },
      {
        name = "🍐Jujutsu",
        windows = {
          jujutsu_project({
            name = "jj",
            path = "~/src/jj-vcs/jj/",
          }),
          jujutsu_project({
            name = "jj-gpc",
            path = "~/src/chriskrycho/jj-gpc/",
          }),
          jujutsu_project({
            name = "jj-notes",
            path = "~/src/rwjblue/jj-notes/",
            command = "nvim README.md"
          }),
        }
      },
    }
  }
}
