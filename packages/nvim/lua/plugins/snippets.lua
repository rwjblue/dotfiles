vim.api.nvim_create_user_command("EditSnippets", function()
  require("luasnip.loaders").edit_snippet_files({})
end, { desc = "Edit snippets used in this buffer" })

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
