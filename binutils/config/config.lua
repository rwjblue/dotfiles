local utils = require("utils")

---@type Config
return {
  crate_locations = {
    "~/src/rwjblue/dotfiles/binutils/",
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
            name = "common.nvim",
            path = "~/src/malleatus/common.nvim",
            command = "nvim"
          },
          {
            name = "dotfiles",
            path = "~/src/rwjblue/dotfiles",
            command = "nvim"
          },
          {
            name = "local-dotfiles",
            path = "~/src/workstuff/local-dotfiles",
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
          utils.jujutsu_project({
            name = "jj",
            path = "~/src/jj-vcs/jj",
          }),
          utils.jujutsu_project({
            name = "jj-gpc",
            path = "~/src/chriskrycho/jj-gpc",
          }),
          utils.jujutsu_project({
            name = "jj-notes",
            path = "~/src/rwjblue/jj-notes",
            command = "nvim README.md"
          }),
        }
      },
    }
  }
}
