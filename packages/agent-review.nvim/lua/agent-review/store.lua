local format = require("agent-review.format")

local M = {}

local function root_from_command(command, dir)
  if vim.fn.executable(command[1]) ~= 1 then return nil end
  local result = vim.system(command, { cwd = dir, text = true }):wait()
  if result.code ~= 0 or not result.stdout then return nil end
  local root = result.stdout:gsub("\n$", "")
  return root ~= "" and root or nil
end

---@param bufnr? integer Use the buffer's directory when it has a file name.
---@return string|nil absolute repo root, or nil if not in a repo
function M.repo_root(bufnr)
  local dir = vim.fn.getcwd()
  if bufnr then
    local name = vim.api.nvim_buf_get_name(bufnr)
    if name:match("^%a[%w+.-]*://") then return nil end
    if name ~= "" then
      for parent in vim.fs.parents(name) do
        local stat = vim.uv.fs_stat(parent)
        if stat and stat.type == "directory" then
          dir = parent
          break
        end
      end
    end
  end
  return root_from_command({ "jj", "root" }, dir)
    or root_from_command({ "git", "rev-parse", "--show-toplevel" }, dir)
end

---@param root string
---@param name string buffer name
---@return string|nil repo-relative file path
function M.relative_path(root, name)
  local prefix = root:gsub("/$", "") .. "/"
  if name:sub(1, #prefix) == prefix then
    return name:sub(#prefix + 1)
  end
  local dir = vim.fs.dirname(name)
  dir = dir and vim.uv.fs_realpath(dir)
  if dir then
    local resolved = vim.fs.joinpath(dir, vim.fs.basename(name))
    if resolved:sub(1, #prefix) == prefix then
      return resolved:sub(#prefix + 1)
    end
  end
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
---@param file? string restrict the update to this repo-relative path
---@return boolean found whether a comment with the given id was updated
function M.update(root, id, fields, file)
  local comments = M.load(root)
  local found = false
  for _, c in ipairs(comments) do
    if c.id == id and (not file or c.file == file) then
      for k, v in pairs(fields) do c[k] = v end
      found = true
    end
  end
  if found then M.save(root, comments) end
  return found
end

---@param root string
---@param id integer
---@param file? string restrict the deletion to this repo-relative path
---@return boolean found whether a comment with the given id was deleted
function M.delete(root, id, file)
  local comments = M.load(root)
  local kept = {}
  for _, c in ipairs(comments) do
    if c.id ~= id or (file and c.file ~= file) then table.insert(kept, c) end
  end
  if #kept == #comments then return false end
  M.save(root, kept)
  return true
end

---@param root string
function M.clear(root)
  M.save(root, {})
end

return M
