vim.api.nvim_create_user_command("EditSnippets", function()
  require("luasnip.loaders").edit_snippet_files({})
end, { desc = "Edit snippets used in this buffer" })

local ft_group = vim.api.nvim_create_augroup("rwjblue_snippets", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
  pattern = "snippets",
  group = ft_group, -- reuse your existing group
  callback = function()
    -- Use real tabs
    vim.opt_local.expandtab = false
    -- Set tab width
    vim.opt_local.tabstop = 8
    vim.opt_local.softtabstop = 0
    vim.opt_local.shiftwidth = 0 -- 0 means follow tabstop
    -- Show tabs visually
    vim.opt_local.list = true
    vim.opt_local.listchars = {
      tab = "··→",
    }
  end,
})

-- Configuration for LuaSnip Filetype Extensions
--
-- This configuration table defines a series of auto-commands to dynamically
-- extend filetypes with specific snippet collections based on the file
-- patterns. Each entry in the table specifies a unique setup for extending a
-- filetype with a targeted snippet collection when opening or creating files
-- that match a given pattern.
--
-- Structure of each configuration entry:
--
-- - `pattern`: A string representing the file pattern to match. This can
--   include specific filenames (e.g., "Cargo.toml") or patterns (e.g.,
--   ".github/workflows/*.yml") to target files within certain directories or
--   with certain extensions.
-- - `extend`: The filetype to be extended. This is the base filetype (e.g.,
--   "toml", "yaml") that LuaSnip will use to determine which set of snippets to
--   activate, in addition to the specific ones being added.
-- - `with`: The specific snippet collection to add to the filetype. This is
--   typically a custom snippet group name (e.g., "cargo", "github-workflow")
--   that corresponds to a set of snippets designed for particular use cases or
--   project structures.
--
-- To add or modify the auto-commands, simply adjust the entries in the
-- `extended_configs` table.
local extended_configs = {
  { pattern = "Cargo.toml", extend = "toml", with = "cargo" },
  { pattern = "*/.github/workflows/*.yml", extend = "yaml", with = "github-workflow" },

  -- Ensure `jj describe` also has access to `gitcommit.snippets`
  -- NOTE: `jj` filetype was renamed to `jjdescription` as of https://github.com/neovim/neovim/commit/b365036ab3f5e91439a5397ed0f32b651d60f08c
  -- so the `jj` mapping here can be removed once I've updated to a new enough version of NeoVim (probably 0.11?)
  { pattern = "*", extend = "jj", with = "gitcommit" },
  { pattern = "*", extend = "jjdescription", with = "gitcommit" },
}

for _, config in ipairs(extended_configs) do
  vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
    pattern = config.pattern,
    group = ft_group,
    callback = function()
      require("luasnip").filetype_extend(config.extend, { config.with })
    end,
  })
end

return {
  -- disable (suggestion from @hjdivad)
  { "rafamadriz/friendly-snippets", enabled = false },

  {
    -- I have the `luasnip` extra installed which automatically inherits the
    -- default configuration from: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/plugins/extras/coding/luasnip.lua
    "L3MON4D3/LuaSnip",

    -- ensure that the plugin is loaded if we open any `.snippets` files (enables syntax hihglighting)
    ft = "snippets",

    config = function(_, opts)
      require("luasnip").setup(opts)

      local snippet_paths = {
        vim.fn.stdpath("config") .. "/snippets",
        os.getenv("HOME") .. "/src/github/rwjblue/dotfiles/local-packages/nvim/snippets",
      }

      -- automatically loads *.snippets files from the top level /snippets directory
      require("luasnip.loaders.from_snipmate").lazy_load({ paths = snippet_paths })
      require("luasnip.loaders.from_lua").lazy_load({ paths = snippet_paths })
    end,
  },
}
