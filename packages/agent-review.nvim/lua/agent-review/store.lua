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

---@param root string
---@return table[]
function M.load(root)
  local f = io.open(M.file_path(root), "r")
  if not f then return {} end
  local text = f:read("*a")
  f:close()
  return format.decode(text)
end

---@param root string
---@param comments table[]
function M.save(root, comments)
  vim.fn.mkdir(M.dir(root), "p")
  local f, err = io.open(M.file_path(root), "w")
  if not f then
    error(("agent-review: cannot write %s: %s"):format(M.file_path(root), err), 2)
  end
  f:write(format.encode(comments))
  f:close()
end

local function next_id(comments)
  local max = 0
  for _, c in ipairs(comments) do
    if c.id and c.id > max then max = c.id end
  end
  return max + 1
end

---@param root string
---@param comment table comment without id
---@return table the stored comment (with id)
function M.add(root, comment)
  local comments = M.load(root)
  local stored = vim.tbl_extend("force", comment, { id = next_id(comments) })
  table.insert(comments, stored)
  M.save(root, comments)
  return stored
end

---@param root string
---@param id integer
---@param fields table
---@return boolean found whether a comment with the given id was updated
function M.update(root, id, fields)
  local comments = M.load(root)
  local found = false
  for _, c in ipairs(comments) do
    if c.id == id then
      for k, v in pairs(fields) do c[k] = v end
      found = true
    end
  end
  M.save(root, comments)
  return found
end

---@param root string
---@param id integer
function M.delete(root, id)
  local comments = M.load(root)
  local kept = {}
  for _, c in ipairs(comments) do
    if c.id ~= id then table.insert(kept, c) end
  end
  M.save(root, kept)
end

---@param root string
function M.clear(root)
  M.save(root, {})
end

return M
