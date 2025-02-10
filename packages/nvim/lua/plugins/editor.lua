return {
  -- file explorer
  {
    -- copied and modified from
    -- https://github.com/LazyVim/LazyVim/blob/v14.11.0/lua/lazyvim/plugins/extras/editor/snacks_explorer.lua
    --
    -- Swap `<leader>e` and `<leader>E` to make `e` do cwd instead of root dir
    "folke/snacks.nvim",
    optional = true,
    opts = { explorer = {} },
    keys = {
      {
        "<leader>fE",
        function()
          Snacks.explorer({ cwd = LazyVim.root() })
        end,
        desc = "Explorer Snacks (root dir)",
      },
      {
        "<leader>fe",
        function()
          Snacks.explorer()
        end,
        desc = "Explorer Snacks (cwd)",
      },
      { "<leader>e", "<leader>fe", desc = "Explorer Snacks (cwd)",      remap = true },
      { "<leader>E", "<leader>fE", desc = "Explorer Snacks (root dir)", remap = true },
    },
  },

  {
    -- copied and modified from
    -- https://github.com/LazyVim/LazyVim/blob/v14.8.0/lua/lazyvim/plugins/editor.lua#L22-L23
    -- make `<leader>e` always default to CWD
    "nvim-neo-tree/neo-tree.nvim",
    optional = true,
    cmd = "Neotree",
    keys = {
      { "<leader>e", "<leader>fE", desc = "Explorer NeoTree (cwd)",      remap = true },
      { "<leader>E", "<leader>fe", desc = "Explorer NeoTree (Root Dir)", remap = true },
    }
  }
}
