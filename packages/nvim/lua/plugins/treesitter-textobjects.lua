return {
  "nvim-treesitter/nvim-treesitter-textobjects",
  config = function()
    require("nvim-treesitter.configs").setup({
      textobjects = {
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
    })
  end,
}
