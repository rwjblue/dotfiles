-- originally from https://github.com/LazyVim/LazyVim/pull/4440
return {
  {
    "yetone/avante.nvim",
    event = "VeryLazy",
    opts = {
      hints = { enabled = false },
    },
    build = LazyVim.is_win() and "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false" or "make",
    behavior = {
      auto_suggestions = false, -- use copilot for auto_suggestions
    }
  },
  {
    "MeanderingProgrammer/render-markdown.nvim",
    optional = true,
    ft = function(_, ft)
      vim.list_extend(ft, { "Avante" })
    end,
    opts = function(_, opts)
      opts.file_types = vim.list_extend(opts.file_types or {}, { "Avante" })
    end,
  },
  {
    "folke/which-key.nvim",
    optional = true,
    opts = {
      spec = {
        { "<leader>a", group = "ai" },
      },
    },
  },
}
