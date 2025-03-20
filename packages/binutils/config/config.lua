local utils = require("utils")

---@type Config
return {
  crate_locations = {
    "~/src/github/rwjblue/dotfiles/packages/binutils/",
    "~/src/github/rwjblue/dotfiles/local-packages/binutils/",
    "~/src/github/malleatus/shared_binutils",
  },
  tmux = {
    default_session = "dotfiles",

    sessions = {
      {
        name = "✅ vadnu",
        windows = {
          {
            name = "vadnu",
            path = "~/src/vadnu",
            command = "nvim",
          },
        },
      },
      {
        name = "dotfiles",
        windows = {
          {
            name = "dotfiles",
            path = "~/src/github/rwjblue/dotfiles",
            command = "nvim",
          },
          {
            name = "common nvim",
            path = "~/src/github/malleatus/common.nvim",
            command = "nvim",
          },
          {
            name = "shared_binutils",
            path = "~/src/github/malleatus/shared_binutils",
            command = "nvim",
          },
        },
      },
      {
        name = "🦨work",
        windows = {
          {
            name = "sniff-gh-copilot-usage",
            path = "~/src/github/rwjblue/sniff-gh-copilot-usage",
          },
        },
      },
      {
        name = "🍐Jujutsu",
        windows = {
          utils.jj_project({
            name = "jj",
            path = "~/src/github/jj-vcs/jj",
          }),
          utils.jj_project({
            name = "jj-gpc",
            path = "~/src/github/chriskrycho/jj-gpc",
          }),
          utils.jj_project({
            name = "jj-notes",
            path = "~/src/github/rwjblue/jj-notes",
            command = "nvim README.md",
          }),
        },
      },
    },
  },
}
