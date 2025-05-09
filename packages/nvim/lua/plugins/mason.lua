return {
  -- NOTE: pin mason related pcakges to ^1.x while the various LazyVim internal
  -- features are updated to support 2.x
  -- https://github.com/LazyVim/LazyVim/issues/6039
  -- https://github.com/LazyVim/LazyVim/pull/6053
  { "williamboman/mason.nvim", version = "^1.0.0" },
  { "williamboman/mason-lspconfig.nvim", version = "^1.0.0" },
  { "Zeioth/mason-extra-cmds", version = "^1.0.0" },

  {
    "williamboman/mason.nvim",
    -- adds MasonUpdateAll
    dependencies = { "Zeioth/mason-extra-cmds", opts = {} },

    cmd = {
      "Mason",
      "MasonInstall",
      "MasonUninstall",
      "MasonUninstallAll",
      "MasonLog",
      "MasonUpdate",
      "MasonUpdateAll", -- this cmd is provided by mason-extra-cmds
    },

    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, {
        -- add any additional tools here

        -- json
        "jq",
        "fixjson",

        --markdown
        "markdown-oxide",
      })
    end,
  },
}
