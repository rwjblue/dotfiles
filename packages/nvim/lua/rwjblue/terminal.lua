-- Auto-enter insert mode when opening/switching to terminal buffers
local M = {}

local function augroup(name)
  return vim.api.nvim_create_augroup("rwjblue_term_" .. name, { clear = true })
end

function M.setup_terminal_window()
  local win_id = vim.api.nvim_get_current_win()
  local win = vim.wo[win_id]

  win.number = false
  win.relativenumber = false
  vim.wo.foldmethod = 'manual'
end

function M.setup()
  local terminal_setup = augroup("terminal_setup")

  -- Auto-insert on terminal open/enter
  vim.api.nvim_create_autocmd({ "BufWinEnter", "TermOpen" }, {
    pattern = "term://*",
    group = terminal_setup,
    callback = function()
      vim.cmd("startinsert")
    end,
  })

  vim.api.nvim_create_autocmd({ "BufWinEnter" }, {
    pattern = "term://*",
    group = terminal_setup,
    callback = M.setup_terminal_window,
  })

  -- Auto-insert when switching to existing terminal
  vim.api.nvim_create_autocmd({ "WinEnter" }, {
    pattern = "term://*",
    group = terminal_setup,
    callback = function()
      vim.schedule(function()
        if vim.startswith(vim.api.nvim_buf_get_name(0), "term://") then
          vim.cmd("startinsert")
        end
      end)
    end,
  })

  vim.api.nvim_create_autocmd({ "TermOpen" }, {
    group = terminal_setup,
    callback = M.setup_terminal_window,
  })
end

return M