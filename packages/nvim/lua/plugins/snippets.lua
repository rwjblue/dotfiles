vim.api.nvim_create_user_command("EditSnippets", function()
  require("luasnip.loaders").edit_snippet_files({})
end, { desc = "Edit snippets used in this buffer" })

local ft_group = vim.api.nvim_create_augroup("rwjblue_snippets", { clear = true })

vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  pattern = ".github/workflows/*.yml",
  group = ft_group,
  callback = function()
    require("luasnip").filetype_extend("yaml", { "github-workflow" })
  end,
})

vim.api.nvim_create_autocmd({ "BufRead" }, {
  pattern = "Cargo.toml",
  group = ft_group,
  callback = function()
    require("luasnip").filetype_extend("toml", { "cargo" })
  end,
})

return {
  -- disable (suggestion from @hjdivad)
  { "rafamadriz/friendly-snippets", enabled = false },

  {
    -- automatically inherits the default configuration from:
    --   https://github.com/LazyVim/LazyVim/blob/v10.9.1/lua/lazyvim/plugins/coding.lua#L3-L31
    "L3MON4D3/LuaSnip",

    -- ensure that the plugin is loaded if we open any `.snippets` files (enables syntax hihglighting)
    event = { "BufRead *.snippets" },
    config = function(_, opts)
      require("luasnip").setup(opts)

      -- automatically loads *.snippets files from the top level /snippets directory
      require("luasnip.loaders.from_snipmate").lazy_load()
      require("luasnip.loaders.from_lua").lazy_load()
    end,
  },
}
