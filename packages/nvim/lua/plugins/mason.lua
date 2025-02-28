return {
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
      })
    end,
  },
}
