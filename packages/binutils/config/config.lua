local utils = require("utils")

---@type Config
return {
  crate_locations = {
    "~/src/rwjblue/dotfiles/packages/binutils/",
    "~/src/malleatus/shared_binutils",
  },
  tmux = {
    sessions = {
      {
        name = "✅ todos",
        windows = {
          {
            name = "todos",
          },
        },
      },
      {
        name = "dotfiles",
        windows = {
          {
            name = "dotfiles",
            path = "~/src/rwjblue/dotfiles",
            command = "nvim",
          },
          {
            name = "common nvim",
            path = "~/src/malleatus/common.nvim",
            command = "nvim",
          },
          {
            name = "shared_binutils",
            path = "~/src/malleatus/shared_binutils",
            command = "nvim",
          },
        },
      },
      {
        name = "🦨work",
        windows = {
          {
            name = "sniff-gh-copilot-usage",
            path = "~/src/rwjblue/sniff-gh-copilot-usage",
          },
        },
      },
      {
        name = "🍐Jujutsu",
        windows = {
          utils.jj_project({
            name = "jj",
            path = "~/src/jj-vcs/jj",
          }),
          utils.jj_project({
            name = "jj-gpc",
            path = "~/src/chriskrycho/jj-gpc",
          }),
          utils.jj_project({
            name = "jj-notes",
            path = "~/src/rwjblue/jj-notes",
            command = "nvim README.md",
          }),
        },
      },
    },
  },
}
