-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

local function augroup(name)
  return vim.api.nvim_create_augroup("rwjblue_" .. name, { clear = true })
end

vim.api.nvim_create_autocmd("FileType", {
  group = augroup("disable_session_persistence"),
  pattern = { "gitcommit" },
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

local terminal_setup = augroup("terminal_setup")

vim.api.nvim_create_autocmd({ "WinEnter", "BufWinEnter", "TermOpen" }, {
  group = terminal_setup,
  callback = function(args)
    if vim.startswith(vim.api.nvim_buf_get_name(args.buf), "term://") then
      vim.cmd("startinsert")
    end
  end,
})

vim.api.nvim_create_autocmd("TermOpen", {
  group = terminal_setup,
  callback = function()
    local win_id = vim.api.nvim_get_current_win()
    local win = vim.wo[win_id]

    win.number = false
    win.relativenumber = false
  end,
})

local function updatePluginLockFile()
  -- Check if lazy-lock.json has changes
  local hasChanges = os.execute("git diff --exit-code --quiet lazy-lock.json")

  -- If there are changes (hasChanges is false), then add and commit
  if hasChanges ~= 0 then
    -- Get current date and time
    local dateTime = os.date("%Y-%m-%d %H:%M:%S")

    -- Run Git commands to add and commit changes
    os.execute("git add lazy-lock.json > /dev/null 2>&1")
    os.execute('git commit --quiet -m "Update plugins ' .. dateTime .. '"')
  end
end

-- Create autocommands for LazyInstall and LazyUpdate events
vim.api.nvim_create_autocmd("User", {
  pattern = "LazyInstall",
  callback = updatePluginLockFile,
})

vim.api.nvim_create_autocmd("User", {
  pattern = "LazyUpdate",
  callback = updatePluginLockFile,
})
