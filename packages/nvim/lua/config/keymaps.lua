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

-- slightly modified https://github.com/LazyVim/LazyVim/blob/v14.8.0/lua/lazyvim/config/keymaps.lua#L174-L178
-- in order to use `c-/` to open terminal in cwd (the default is
-- `LazyVim.root()` which doesn't always behave how I expect)
vim.keymap.set("n", "<c-/>", function() Snacks.terminal() end, { desc = "Terminal (cwd)" })
-- in certain terminal `<c-/>` is actually received by the terminal as `<c-_>`
vim.keymap.set("n", "<c-_>", function() Snacks.terminal() end, { desc = "which_key_ignore" })

-- remove the "move up" and "move down" keymaps added by LazyVim
-- https://github.com/LazyVim/LazyVim/blob/879e29504d43e9f178d967ecc34d482f902e5a91/lua/lazyvim/config/keymaps.lua#L26-L32
vim.keymap.del({ "n", "v", "i" }, "<a-j>")
vim.keymap.del({ "n", "v", "i" }, "<a-k>")

-- CMD+1, CMD+2, &c are all mapped to F1, F2, &c in wezterm config
-- this allows using CMD+<NUMBER> to change to the specific tab
vim.keymap.set({ 'n', 'i', 'v', 't' }, '<F1>', '<Cmd>tabnext 1<cr>',
  { noremap = true, silent = true, desc = "Go to tab 1" })
vim.keymap.set({ 'n', 'i', 'v', 't' }, '<F2>', '<Cmd>tabnext 2<cr>',
  { noremap = true, silent = true, desc = "Go to tab 2" })
vim.keymap.set({ 'n', 'i', 'v', 't' }, '<F3>', '<Cmd>tabnext 3<cr>',
  { noremap = true, silent = true, desc = "Go to tab 3" })
vim.keymap.set({ 'n', 'i', 'v', 't' }, '<F4>', '<Cmd>tabnext 4<cr>',
  { noremap = true, silent = true, desc = "Go to tab 4" })
vim.keymap.set({ 'n', 'i', 'v', 't' }, '<F5>', '<Cmd>tabnext 5<cr>',
  { noremap = true, silent = true, desc = "Go to tab 5" })
vim.keymap.set({ 'n', 'i', 'v', 't' }, '<F6>', '<Cmd>tabnext 6<cr>',
  { noremap = true, silent = true, desc = "Go to tab 6" })
vim.keymap.set({ 'n', 'i', 'v', 't' }, '<F7>', '<Cmd>tabnext 7<cr>',
  { noremap = true, silent = true, desc = "Go to tab 7" })
vim.keymap.set({ 'n', 'i', 'v', 't' }, '<F8>', '<Cmd>tabnext 8<cr>',
  { noremap = true, silent = true, desc = "Go to tab 8" })
vim.keymap.set({ 'n', 'i', 'v', 't' }, '<F9>', '<Cmd>tabnext 9<cr>',
  { noremap = true, silent = true, desc = "Go to tab 9" })

-- NOTE: local_config is symlinked in from local-dotfiles to allow for local
-- system specific customizations
-- see: https://github.com/malleatus/shared_binutils/blob/master/global/src/bin/setup-local-dotfiles.rs
require("local_config.config.keymaps")
