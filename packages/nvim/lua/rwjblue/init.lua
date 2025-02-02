local M = {}

---Check if the current buffer path is within a specific subdirectory
---@param subdir string The subdirectory name to check for (e.g. ".git", "node_modules")
---@return boolean True if the buffer path starts with or contains the subdirectory
function M.is_buffer_in_subdir(subdir)
  local buf_path = vim.fn.bufname('%')
  -- Escape special pattern characters
  local escaped_subdir = subdir:gsub('%.', '%%.')
  -- Check if path starts with subdir/ or contains /subdir/
  return (buf_path:match('^' .. escaped_subdir .. '/') ~= nil) or
      (buf_path:match('/' .. escaped_subdir .. '/') ~= nil)
end

--- Checks if the current buffer has a commit related filetype
---@return boolean
local function is_git_related_filetype()
  local ft = vim.bo.filetype
  return ft == 'gitcommit' or ft == 'jj' or ft == 'jjdescribe'
end

--- Don't attempt to install missing plugins or check for updates when making a commit
---@type boolean whether to run lazy plugin checks for the current buffer
M.should_run_lazy_plugin_checks = not is_git_related_filetype()

--- Determines the appropriate path for the lazy.nvim lockfile
---
--- If local config plugins exist (in local_config.plugins), the lockfile will
--- be stored in local_config/lazy-lock.json Otherwise, it will be stored in
--- the default location (lazy-lock.json).
---
--- @return string The full path to the lazy-lock.json file
function M.get_lockfile_path()
  local Util = require("lazy.util")
  local mods = {}
  Util.lsmod("local_config.plugins", function(modname, modpath)
    mods[#mods + 1] = modname
  end)

  if #mods > 0 then
    return vim.fn.stdpath("config") .. "/local_config/lazy-lock.json"
  else
    return vim.fn.stdpath("config") .. "/lazy-lock.json"
  end
end

function M.get_diff()
  -- Check if we're in a jj repo by running `jj root`
  local jj_root = vim.fn.system("jj root 2>/dev/null")
  local is_jj_repo = vim.v.shell_error == 0

  if is_jj_repo then
    return vim.fn.system("jj diff --git")
  else
    return vim.fn.system("git diff --no-ext-diff --staged")
  end
end

function M.commit_lockfile()
  -- TODO: this needs to be updated to work for jujutsu
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

function M.setup_auto_commit_for_lockfile()
  -- Create autocommands for LazyInstall and LazyUpdate events
  -- TODO: bring this back if/when we have a better idea of what to do in Jujutsu
  vim.api.nvim_create_autocmd("User", {
    pattern = "LazyInstall",
    callback = M.commit_lockfile,
  })

  vim.api.nvim_create_autocmd("User", {
    pattern = "LazyUpdate",
    callback = M.commit_lockfile,
  })
end

return M
