-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.opt.relativenumber = false

-- automatically run trusted .nvim.lua .nvimrc .exrc
-- :trust <file> to trust
-- :trust ++deny/++remove <file>
vim.opt.exrc = true

-- NOTE: local_config is symlinked in from local-dotfiles to allow for local
-- system specific customizations
-- see: https://github.com/malleatus/shared_binutils/blob/master/global/src/bin/setup-local-dotfiles.rs
require("local_config.config.options")
