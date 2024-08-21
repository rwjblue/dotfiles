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

-- floating terminal
-- slightly modified https://github.com/LazyVim/LazyVim/blob/v10.9.1/lua/lazyvim/config/keymaps.lua#L141-L146
-- in order to add a border to the floating terminal
local Util = require("lazyvim.util")
local lazyterm = function()
  Util.terminal(nil, {
    cwd = Util.root(),
    -- possible border options: https://github.com/folke/lazy.nvim/blob/v10.16.0/lua/lazy/view/float.lua#L12
    border = "rounded",
  })
end
vim.keymap.set("n", "<leader>ft", lazyterm, { desc = "Terminal (root dir)" })
vim.keymap.set("n", "<leader>fT", function()
  Util.terminal(nil, {
    border = "rounded",
  })
end, { desc = "Terminal (cwd)" })
vim.keymap.set("n", "<c-/>", lazyterm, { desc = "Terminal (root dir)" })
vim.keymap.set("n", "<c-_>", lazyterm, { desc = "which_key_ignore" })

-- remove the "move up" and "move down" keymaps added by LazyVim
-- https://github.com/LazyVim/LazyVim/blob/879e29504d43e9f178d967ecc34d482f902e5a91/lua/lazyvim/config/keymaps.lua#L26-L32
vim.keymap.del({ "n", "v", "i" }, "<a-j>")
vim.keymap.del({ "n", "v", "i" }, "<a-k>")

-- TODO: need to debug this more; it's not working as expected
vim.keymap.set({ 'n', 'i', 'v', 't' }, '<D-1>', '1gt', { noremap = true, silent = true, desc = "Go to tab 1" })
vim.keymap.set({ 'n', 'i', 'v', 't' }, '<D-2>', '2gt', { noremap = true, silent = true, desc = "Go to tab 2" })
vim.keymap.set({ 'n', 'i', 'v', 't' }, '<D-3>', '3gt', { noremap = true, silent = true, desc = "Go to tab 3" })
vim.keymap.set({ 'n', 'i', 'v', 't' }, '<D-4>', '4gt', { noremap = true, silent = true, desc = "Go to tab 4" })
vim.keymap.set({ 'n', 'i', 'v', 't' }, '<D-5>', '5gt', { noremap = true, silent = true, desc = "Go to tab 5" })
vim.keymap.set({ 'n', 'i', 'v', 't' }, '<D-6>', '6gt', { noremap = true, silent = true, desc = "Go to tab 6" })
vim.keymap.set({ 'n', 'i', 'v', 't' }, '<D-7>', '7gt', { noremap = true, silent = true, desc = "Go to tab 7" })
vim.keymap.set({ 'n', 'i', 'v', 't' }, '<D-8>', '8gt', { noremap = true, silent = true, desc = "Go to tab 8" })
vim.keymap.set({ 'n', 'i', 'v', 't' }, '<D-9>', '9gt', { noremap = true, silent = true, desc = "Go to tab 9" })
