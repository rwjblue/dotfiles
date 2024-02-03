vim.api.nvim_create_user_command("EditSnippets", function()
  require("luasnip.loaders").edit_snippet_files({})
end, { desc = "Edit snippets used in this buffer" })

return {
  -- disable (suggestion from @hjdivad)
  { "rafamadriz/friendly-snippets", enabled = false },

  {
    "L3MON4D3/LuaSnip",
    config = function(_, opts)
      require("luasnip").setup(opts)

      local snippet_paths = { "~/.config/nvim/snippets" }
      require("luasnip.loaders.from_snipmate").lazy_load({
        paths = snippet_paths,
      })
      require("luasnip.loaders.from_lua").lazy_load({ paths = snippet_paths })
    end,
  },
}
