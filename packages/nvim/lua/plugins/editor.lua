return {
  -- file explorer
  {
    "nvim-neo-tree/neo-tree.nvim",
    cmd = "Neotree",
    keys = {
      -- copied and modified from
      -- https://github.com/LazyVim/LazyVim/blob/v14.8.0/lua/lazyvim/plugins/editor.lua#L22-L23
      -- make `<leader>e` always default to CWD
      { "<leader>e", "<leader>fE", desc = "Explorer NeoTree (cwd)",      remap = true },
      { "<leader>E", "<leader>fe", desc = "Explorer NeoTree (Root Dir)", remap = true },
    }
  }
}
