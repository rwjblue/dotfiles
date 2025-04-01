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
          {
            name = "malleatus/vadnu",
            path = "~/src/github/malleatus/vadnu",
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
        name = "🪓hacks",
        windows = {
          {
            name = "tamjaweb",
            path = "~/src/github/malleatus/tamjaweb",
            command = "nvim",
          },
        },
      },
    },
  },
}
