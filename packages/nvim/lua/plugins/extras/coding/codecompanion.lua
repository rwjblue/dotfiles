-- originally from https://github.com/LazyVim/LazyVim/pull/4268
return {
  {
    "olimorris/codecompanion.nvim",
    cmd = { "CodeCompanion", "CodeCompanionActions", "CodeCompanionChat" },

    opts = function()
      local options = require("codecompanion.config")
      local user = vim.env.USER or "User"

      options.strategies.chat.roles = {
        llm = "  CodeCompanion",
        user = "  " .. user:sub(1, 1):upper() .. user:sub(2),
      }

      options.strategies.chat.keymaps.close.modes = {
        n = "q",
        i = "<C-c>",
      }
      options.strategies.chat.keymaps.stop.modes.n = "<C-c>"
      -- the only change from the PR at the moment is below:
      --options.strategies.chat.keymaps.save.modes.n = "gS"
      options.strategies.chat.keymaps.send.modes.n = "gS"

      return options
    end,

    keys = {
      { "<leader>a",  "",                                  desc = "+ai",        mode = { "n", "v" } },
      { "<leader>aA", "<cmd>CodeCompanionActions<cr>",     mode = { "n", "v" }, desc = "Prompt Actions (CodeCompanion)" },
      { "<leader>aa", "<cmd>CodeCompanionChat Toggle<cr>", mode = { "n", "v" }, desc = "Toggle (CodeCompanion)" },
      { "<leader>ac", "<cmd>CodeCompanionChat Add<cr>",    mode = "v",          desc = "Add code to CodeCompanion" },
      { "<leader>ap", "<cmd>CodeCompanion<cr>",            mode = "n",          desc = "Inline prompt (CodeCompanion)" },
    },
  },

  -- Edgy integration
  {
    "folke/edgy.nvim",
    optional = true,
    opts = function(_, opts)
      opts.right = opts.right or {}
      table.insert(opts.right, {
        ft = "codecompanion",
        title = "CodeCompanion Chat",
        size = { width = 50 },
      })
    end,
  },
}
