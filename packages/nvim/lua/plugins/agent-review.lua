local config_init = vim.uv.fs_realpath(vim.fn.stdpath("config") .. "/init.lua")
local packages_dir = vim.fs.dirname(vim.fs.dirname(config_init))

return {
  {
    "rwjblue/agent-review.nvim",
    dir = packages_dir .. "/agent-review.nvim",
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
