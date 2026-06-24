local format = require("agent-review.format")

local M = {}

---@return string|nil absolute repo root, or nil if not in a repo
function M.repo_root()
  local out = vim.fn.systemlist({ "jj", "root" })
  if vim.v.shell_error == 0 and out[1] and out[1] ~= "" then
    return out[1]
  end
  out = vim.fn.systemlist({ "git", "rev-parse", "--show-toplevel" })
  if vim.v.shell_error == 0 and out[1] and out[1] ~= "" then
    return out[1]
  end
  return nil
end

---@param root string
---@return string
function M.dir(root)
  return vim.fs.joinpath(root, ".agent-review")
end

---@param root string
---@return string
function M.file_path(root)
  return vim.fs.joinpath(M.dir(root), "comments.md")
end

return M
