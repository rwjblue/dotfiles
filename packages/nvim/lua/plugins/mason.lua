return {
  {
    "williamboman/mason.nvim",
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, {
        -- add any additional tools here

        -- json
        "jq",
        "fixjson",

        -- python
        "ruff-lsp",
        "pyright",
      })
    end,
  },
}
