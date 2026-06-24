local store = require("agent-review.store")
local anchor = require("agent-review.anchor")

local M = {}

M.ns = vim.api.nvim_create_namespace("agent-review")

---@param root string
---@param bufname string absolute buffer path
---@return string|nil repo-relative path
local function rel_path(root, bufname)
  if bufname == "" then return nil end
  local prefix = root .. "/"
  if bufname:sub(1, #prefix) == prefix then
    return bufname:sub(#prefix + 1)
  end
  return nil
end

---@param bufnr? integer
function M.clear(bufnr)
  vim.api.nvim_buf_clear_namespace(bufnr or 0, M.ns, 0, -1)
end

---Resolve + render all comments for the buffer's file.
---@param bufnr? integer
function M.buffer(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local root = store.repo_root()
  if not root then return end
  local rel = rel_path(root, vim.api.nvim_buf_get_name(bufnr))
  if not rel then return end

  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  M.clear(bufnr)

  for _, c in ipairs(store.load(root)) do
    if c.file == rel then
      local res = anchor.resolve(lines, c)
      if res.line then
        local body_lines = vim.split(c.body, "\n", { plain = true })
        local tag = res.status == "moved" and " (moved)" or ""
        local virt = {}
        for idx, bl in ipairs(body_lines) do
          local text = (idx == 1)
              and string.format("💬 [%d]%s %s", c.id, tag, bl)
              or ("   " .. bl)
          table.insert(virt, { { text, "Comment" } })
        end
        vim.api.nvim_buf_set_extmark(bufnr, M.ns, res.line - 1, 0, {
          id = c.id,
          virt_lines = virt,
          sign_text = ">>",
          sign_hl_group = "Comment",
        })
      end
    end
  end
end

---Return the comment id of an agent-review extmark on the given 0-based row, or nil.
---@param bufnr integer
---@param row integer 0-based row
---@return integer|nil
function M.comment_id_at(bufnr, row)
  local marks = vim.api.nvim_buf_get_extmarks(bufnr, M.ns, { row, 0 }, { row, -1 }, {})
  if #marks > 0 then return marks[1][1] end
  return nil
end

return M
