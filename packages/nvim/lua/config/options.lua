-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.opt.relativenumber = false

-- automatically run trusted .nvim.lua .nvimrc .exrc
-- :trust <file> to trust
-- :trust ++deny/++remove <file>
vim.opt.exrc = true

-- The default is { "lsp", { ".git", "lua" }, "cwd" }
-- this configures how varous "root dir" things work in LazyVim
--
-- I find the default configuration to be very annoying, especially when
-- working in a monorepo type of structure like binutils. I guess if I have to
-- work in larger monorepos this might need to be reevaluated. But for now,
-- just cwd as root.
vim.g.root_spec = { "cwd" }

-- https://gpanders.com/blog/whats-new-in-neovim-0-11/#virtual-lines
vim.o.winborder = "rounded"
vim.diagnostic.config({
  -- Use the default configuration
  virtual_lines = true,
})

-- Disable LazyVim format-on-save
vim.g.autoformat = false

-- NOTE: local_nvim is symlinked in from local-dotfiles to allow for local
-- system specific customizations
-- see: https://github.com/malleatus/shared_binutils/blob/master/global/src/bin/setup-local-dotfiles.rs
require("local_nvim.config.options")
