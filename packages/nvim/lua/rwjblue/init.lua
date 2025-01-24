local M = {}

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

return M
