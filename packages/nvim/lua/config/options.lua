-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.opt.relativenumber = false

if vim.fn.has("nvim-0.9.0") == 1 then
  -- automatically run trusted .nvim.lua .nvimrc .exrc
  -- :trust <file> to trust
  -- :trust ++deny/++remove <file>
  vim.opt.exrc = true
end
