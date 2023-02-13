-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local function map(mode, lhs, rhs, opts)
  local options = { noremap = true }

  if opts then
    options = vim.tbl_extend("force", options, opts)
  end

  vim.api.nvim_set_keymap(mode, lhs, rhs, options)
end

-- allow Ctrl-H,J,K,L to work for moving in and out of terminals
-- copy the original keymaps from:key
-- https://github.com/LazyVim/LazyVim/blob/v1.6.0/lua/lazyvim/config/keymaps.lua#L20-L30 key
-- and add them for terminal mode

-- Move to window using the <ctrl> hjkl keys
map("t", "<C-h>", [[<C-\><C-n><C-w>h]], { desc = "Go to left window" })
map("t", "<C-j>", [[<C-\><C-n><C-w>j]], { desc = "Go to lower window" })
map("t", "<C-k>", [[<C-\><C-n><C-w>k]], { desc = "Go to upper window" })
map("t", "<C-l>", [[<C-\><C-n><C-w>l]], { desc = "Go to right window" })

-- Resize window using <ctrl> arrow keys
map("t", "<C-Up>", "<cmd>resize +2<cr>", { desc = "Increase window height" })
map("t", "<C-Down>", "<cmd>resize -2<cr>", { desc = "Decrease window height" })
map("t", "<C-Left>", "<cmd>vertical resize -2<cr>", { desc = "Decrease window width" })
map("t", "<C-Right>", "<cmd>vertical resize +2<cr>", { desc = "Increase window width" })

-- Enable exiting terminal mode with Esc
map("t", [[<C-\><C-\>]], [[<C-\><C-n>]])
