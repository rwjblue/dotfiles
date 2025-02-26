return {
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      -- Define your formatters
      formatters_by_ft = {
        lua = { "stylua" },
        -- disable python formatter, which will force conform.nvim to fallback to ruff instead
        python = {},
        json = { "fixjson" },
        javascript = { { "prettierd", "prettier" } },
      },
      -- Customize formatters
      formatters = {
        shfmt = {
          prepend_args = { "-i", "2" },
        },
      },
    },
  }
}
