return {
  -- setup lspconfig for rwjblue/lsp-playground
  {
    "neovim/nvim-lspconfig",
    opts = {
      -- make sure mason installs the server
      servers = {
        lsp_playground = {},
      },
      setup = {
        lsp_playground = function(_, opts)
          local lspconfig = require("lspconfig")
          local configs = require("lspconfig.configs")
          local util = require("lspconfig.util")

          if not configs.lsp_playground then
            configs.lsp_playground = {
              default_config = {
                cmd = { "/Users/rwjblue/src/github/rwjblue/lsp-playground/target/debug/lsp-playground" },
                filetypes = { "lsp_playground" },
                root_dir = function(fname)
                  return util.find_git_ancestor(fname)
                end,
                settings = {},
              },
            }
          end

          lspconfig.lsp_playground.setup({})
          -- enable debug level logging
          vim.lsp.set_log_level("info")
        end,
      },
    },
  },
}
