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
    }
  }
}
