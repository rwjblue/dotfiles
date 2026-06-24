return {
  {
    "rwjblue/agent-review.nvim",
    dir = vim.fn.expand("~/src/github/rwjblue/dotfiles/packages/agent-review.nvim"),
    dependencies = { "folke/snacks.nvim" },
    event = "VeryLazy",
    opts = {},
  },
  {
    "folke/which-key.nvim",
    optional = true,
    opts = { spec = { { "<leader>r", group = "review" } } },
  },
}
