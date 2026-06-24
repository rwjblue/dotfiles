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
---@param root? string repo root (defaults to store.repo_root())
---@return table|nil comment, string|nil err
function M._make_comment(bufnr, srow, erow, body, root)
  root = root or store.repo_root()
  if not root then return nil, "not in a repo" end
  local name = vim.api.nvim_buf_get_name(bufnr)
  if name == "" then return nil, "buffer has no name" end
  local prefix = root .. "/"
  if name:sub(1, #prefix) ~= prefix then return nil, "buffer not under repo root" end
  local rel = name:sub(#prefix + 1)
  local snippet_lines = vim.api.nvim_buf_get_lines(bufnr, srow - 1, erow, false)
  return {
    file = rel,
    start_line = srow,
    end_line = erow,
    snippet = table.concat(snippet_lines, "\n"),
    body = body,
  }
end

---Find the comment whose anchored line is at the cursor (current buffer).
---@return integer|nil id
local function comment_id_at_cursor()
  return render.comment_id_at(0, vim.api.nvim_win_get_cursor(0)[1] - 1)
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

---Add a comment on the current line.
function M.add()
  local row = vim.api.nvim_win_get_cursor(0)[1]
  local root = store.repo_root()
  if not root then return vim.notify("agent-review: not in a repo", vim.log.levels.WARN) end
  prompt(nil, function(body)
    if rejects_marker(body) then return end
    local c, err = M._make_comment(0, row, row, body, root)
    if not c then return vim.notify("agent-review: " .. err, vim.log.levels.WARN) end
    store.add(root, c)
    render.buffer(0)
  end)
end

---Add a comment spanning the last visual selection.
function M.add_visual()
  local srow = vim.fn.line("'<")
  local erow = vim.fn.line("'>")
  local root = store.repo_root()
  if not root then return vim.notify("agent-review: not in a repo", vim.log.levels.WARN) end
  prompt(nil, function(body)
    if rejects_marker(body) then return end
    local c, err = M._make_comment(0, srow, erow, body, root)
    if not c then return vim.notify("agent-review: " .. err, vim.log.levels.WARN) end
    store.add(root, c)
    render.buffer(0)
  end)
end

---Edit the comment under the cursor.
function M.edit()
  local id = comment_id_at_cursor()
  if not id then return vim.notify("agent-review: no comment here", vim.log.levels.INFO) end
  local root = store.repo_root()
  local existing
  for _, c in ipairs(store.load(root)) do
    if c.id == id then existing = c; break end
  end
  prompt(existing and existing.body, function(body)
    if rejects_marker(body) then return end
    store.update(root, id, { body = body })
    render.buffer(0)
  end)
end

---Delete the comment under the cursor.
function M.delete()
  local id = comment_id_at_cursor()
  if not id then return vim.notify("agent-review: no comment here", vim.log.levels.INFO) end
  store.delete(store.repo_root(), id)
  render.buffer(0)
end

---Open a snacks picker of all comments.
function M.list()
  local root = store.repo_root()
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
