-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

local function augroup(name)
  return vim.api.nvim_create_augroup("rwjblue_" .. name, { clear = true })
end

vim.api.nvim_create_autocmd("FileType", {
  group = augroup("disable_session_persistence"),
  pattern = { "gitcommit", "jj", "jjdescription" },
  callback = function()
    require("persistence").stop()
  end,
})

-- TODO: Remove this (and the corresponding `after/syntax/jj.vim`) when NeoVim
-- is released including this: https://github.com/neovim/neovim/pull/31840
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("JJCustomSyntax"),
  pattern = { "jj" },
  callback = function()
    vim.cmd("runtime! after/syntax/jj.vim")
  end,
})

require("rwjblue.tabs").setup_commands()

vim.api.nvim_create_user_command("CopyRelativePath", function()
  -- Get path relative to current working directory
  local relative_path = vim.fn.expand("%:.")

  -- Copy to clipboard
  vim.fn.setreg("+", relative_path)
  vim.fn.setreg("*", relative_path)

  vim.notify("Copied relative path: " .. relative_path)
end, {
  desc = "Copy the relative path of the current buffer to the clipboard (relative to cwd)",
  bang = false,
  nargs = 0,
})

-- NOTE: local_nvim is symlinked in from local-dotfiles to allow for local
-- system specific customizations
-- see: https://github.com/malleatus/shared_binutils/blob/master/global/src/bin/setup-local-dotfiles.rs
require("local_nvim.config.autocmds")
