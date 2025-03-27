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
        name_formatter = function(buf)
          return require("rwjblue.tabs").format_tab_name(buf.tabnr)
        end,
      },
    },
  },
  {
    -- TODO: Remove this once https://github.com/folke/noice.nvim/issues/1082
    -- is resolved
    "folke/noice.nvim",
    opts = {
      views = {
        cmdline_popup = {
          border = { style = "none" },
        },
      },
    },
  },
}
