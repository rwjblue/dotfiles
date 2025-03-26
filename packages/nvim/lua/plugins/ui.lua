-- this file is used for overrides to things in https://github.com/LazyVim/LazyVim/blob/v14.14.0/lua/lazyvim/plugins/ui.lua

return {
  {
    "akinsho/bufferline.nvim",
    event = "VeryLazy",
    keys = {
      -- disable
      { "<leader>bp", false, desc = "Toggle Pin" },
      { "<leader>bP", false, desc = "Delete Non-Pinned Buffers" },
      { "<leader>br", false, desc = "Delete Buffers to the Right" },
      { "<leader>bl", false, desc = "Delete Buffers to the Left" },
      { "[b", false, desc = "Prev Buffer" },
      { "]b", false, desc = "Next Buffer" },
      { "[B", false, desc = "Move buffer prev" },
      { "]B", false, desc = "Move buffer next" },

      -- preserve these two
      --{ "<S-h>", "<cmd>BufferLineCyclePrev<cr>", desc = "Prev Buffer" },
      --{ "<S-l>", "<cmd>BufferLineCycleNext<cr>", desc = "Next Buffer" },
    },
    opts = {
      options = {
        mode = "tabs",
        -- merge in a bunch of additional options from LazyVim
        -- https://github.com/LazyVim/LazyVim/blob/v14.14.0/lua/lazyvim/plugins/ui.lua#L20-L48
        indicator = {
          style = "underline",
        },
      },
    },
  },
}
