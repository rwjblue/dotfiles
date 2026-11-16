local store = require("agent-review.store")
local render = require("agent-review.render")

local M = {}

local function rejects_marker(body)
  if body:find("agent%-review:v1 comment") then
    vim.notify("agent-review: comment body cannot contain the agent-review marker", vim.log.levels.WARN)
    return true
  end
  return false
end

---Build a comment table from buffer state (reads the buffer).
---@param bufnr integer
---@param srow integer 1-based start row
---@param erow integer 1-based end row
---@param body string
---@param root? string repo root (defaults to the buffer's repo)
---@return table|nil comment, string|nil err
function M._make_comment(bufnr, srow, erow, body, root)
  local name = vim.api.nvim_buf_get_name(bufnr)
  if name == "" then return nil, "buffer has no name" end
  root = root or store.repo_root(bufnr)
  if not root then return nil, "not in a repo" end
  local rel = store.relative_path(root, name)
  if not rel then return nil, "buffer not under repo root" end
  local snippet_lines = vim.api.nvim_buf_get_lines(bufnr, srow - 1, erow, false)
  return {
    file = rel,
    start_line = srow,
    end_line = erow,
    snippet = table.concat(snippet_lines, "\n"),
    body = body,
  }
end

local function target_at_cursor(bufnr)
  local id = render.comment_id_at(bufnr, vim.api.nvim_win_get_cursor(0)[1] - 1)
  if not id then return end
  local root = store.repo_root(bufnr)
  local file = root and store.relative_path(root, vim.api.nvim_buf_get_name(bufnr))
  if file then return id, root, file end
end

local function no_comment_here()
  vim.notify("agent-review: no comment here", vim.log.levels.INFO)
end

local function prompt(default, cb)
  local ok, snacks = pcall(require, "snacks")
  if ok and snacks.input then
    snacks.input({ prompt = "Review comment", default = default or "" }, function(value)
      if value and value ~= "" then cb(value) end
    end)
  else
    local value = vim.fn.input("Review comment: ", default or "")
    if value ~= "" then cb(value) end
  end
end

---Add a comment spanning the given 1-based lines in the active buffer.
function M.add_range(srow, erow)
  local bufnr = vim.api.nvim_get_current_buf()
  local root = store.repo_root(bufnr)
  if not root then return vim.notify("agent-review: not in a repo", vim.log.levels.WARN) end
  local comment, err = M._make_comment(bufnr, srow, erow, "", root)
  if not comment then return vim.notify("agent-review: " .. err, vim.log.levels.WARN) end
  prompt(nil, function(body)
    if rejects_marker(body) then return end
    comment.body = body
    store.add(root, comment)
    render.buffer(bufnr)
  end)
end

---Add a comment on the current line.
function M.add()
  local row = vim.api.nvim_win_get_cursor(0)[1]
  M.add_range(row, row)
end

---Add a comment spanning the active visual selection.
function M.add_visual()
  local start = vim.fn.getpos("v")[2]
  local cursor = vim.api.nvim_win_get_cursor(0)[1]
  M.add_range(math.min(start, cursor), math.max(start, cursor))
end

---Edit the comment under the cursor.
function M.edit()
  local bufnr = vim.api.nvim_get_current_buf()
  local id, root, file = target_at_cursor(bufnr)
  if not id then return no_comment_here() end
  local existing
  for _, c in ipairs(store.load(root)) do
    if c.id == id and c.file == file then existing = c; break end
  end
  if not existing then
    render.buffer(bufnr)
    return no_comment_here()
  end
  prompt(existing.body, function(body)
    if rejects_marker(body) then return end
    local updated = store.update(root, id, { body = body }, file)
    render.buffer(bufnr)
    if not updated then no_comment_here() end
  end)
end

---Delete the comment under the cursor.
function M.delete()
  local bufnr = vim.api.nvim_get_current_buf()
  local id, root, file = target_at_cursor(bufnr)
  if not id then return no_comment_here() end
  local deleted = store.delete(root, id, file)
  render.buffer(bufnr)
  if not deleted then no_comment_here() end
end

---Open a snacks picker of all comments.
function M.list()
  local root = store.repo_root(0)
  if not root then return end
  local comments = store.load(root)
  local items = {}
  for _, c in ipairs(comments) do
    items[#items + 1] = {
      text = string.format("%s:%d  %s", c.file, c.start_line, vim.split(c.body, "\n")[1]),
      file = vim.fs.joinpath(root, c.file),
      pos = { c.start_line, 0 },
    }
  end
  require("snacks").picker.pick({
    title = "Agent Review Comments",
    items = items,
    format = function(item) return { { item.text } } end,
    confirm = function(picker, item)
      picker:close()
      if item then
        vim.cmd("edit " .. vim.fn.fnameescape(item.file))
        vim.api.nvim_win_set_cursor(0, item.pos)
      end
    end,
  })
end

---Jump to next/previous comment in the current buffer.
---@param dir 1|-1
local function jump(dir)
  local marks = vim.api.nvim_buf_get_extmarks(0, render.ns, 0, -1, {})
  if #marks == 0 then return end
  table.sort(marks, function(a, b) return a[2] < b[2] end)
  local cur = vim.api.nvim_win_get_cursor(0)[1] - 1
  local target
  if dir == 1 then
    for _, m in ipairs(marks) do if m[2] > cur then target = m[2]; break end end
    target = target or marks[1][2]
  else
    for i = #marks, 1, -1 do if marks[i][2] < cur then target = marks[i][2]; break end end
    target = target or marks[#marks][2]
  end
  vim.api.nvim_win_set_cursor(0, { target + 1, 0 })
end

function M.next() jump(1) end
function M.prev() jump(-1) end

return M
