return {
  -- add catppuccin with fixed bufferline integration
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = false, -- make sure we load this during startup if it is your main colorscheme
    priority = 1000, -- make sure to load this before all the other start plugins
    opts = function(_, opts)
      -- Workaround lazyvim issue with catppuccin + bufferline:
      -- https://github.com/LazyVim/LazyVim/issues/6355
      local module = require("catppuccin.groups.integrations.bufferline")
      if module then
        module.get = module.get_theme
      end
      return vim.tbl_deep_extend("force", opts or {}, {
        flavour = "mocha", -- latte, frappe, macchiato, mocha
      })
    end,
  },

  -- add tokyonight
  { "folke/tokyonight.nvim" },

  -- add gruvbox
  { "ellisonleao/gruvbox.nvim" },

  -- Configure LazyVim to load catppuccin-mocha
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "catppuccin-mocha",
    },
  },
}
