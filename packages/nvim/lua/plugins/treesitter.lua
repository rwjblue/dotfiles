return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, {
        -- add any additional parsers here
        "diff",
        "dockerfile",
        "dot",
        "git_rebase",
        "gitattributes",
        "gitcommit",
        "gitignore",
        "graphql",
        "hcl",
        "http",
        "jq",
        "make",
        "mermaid",
      })
    end,
    config = function(_, opts)
      -- LazyVim handles the main treesitter setup, we just add our custom query overrides
      local overrides = require("rwjblue.overrides")
      overrides.load_ts_query_overrides()
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    opts = {
      lsp_interop = {
        enable = true,
        border = "none",
        floating_preview_opts = {},
        peek_definition_code = {
          ["<leader>cp"] = "@function.outer",
          ["<leader>cP"] = "@class.outer",
        },
      },
    },
  },
}
