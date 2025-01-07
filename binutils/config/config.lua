local function jujutsu_project(config)
  return {
    name = config.name,
    path = config.path,
    command = {
      -- this looks odd, but $PWD always results in a trailing slash, so no
      -- need to include a second one
      'export GIT_DIR="$PWD.jj/repo/store/git"',
    },
  }
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
          }),
        }
      },
    }
  }
}
