local render = require("agent-review.render")
local store = require("agent-review.store")
local T = MiniTest.new_set()

local function temp_git_repo()
  local dir = vim.fn.fnamemodify(vim.fn.tempname(), ":p")
  vim.fn.mkdir(dir, "p")
  vim.fn.system({ "git", "-C", dir, "init", "-q" })
  return vim.uv.fs_realpath(dir)
end

T["render places an extmark for an anchored comment"] = function()
  local root = temp_git_repo()
  local file = root .. "/foo.txt"
  vim.fn.writefile({ "alpha", "beta", "gamma" }, file)
  store.add(root, { file = "foo.txt", start_line = 2, end_line = 2, snippet = "beta", body = "look here" })

  local prev = vim.fn.getcwd()
  vim.fn.chdir(root)
  local buf = vim.fn.bufadd(file)
  vim.fn.bufload(buf)
  render.buffer(buf)
  local marks = vim.api.nvim_buf_get_extmarks(buf, render.ns, 0, -1, {})
  vim.fn.chdir(prev)

  MiniTest.expect.equality(#marks >= 1, true)
end

T["clear removes extmarks"] = function()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_extmark(buf, render.ns, 0, 0, { virt_lines = { { { "x" } } } })
  render.clear(buf)
  MiniTest.expect.equality(#vim.api.nvim_buf_get_extmarks(buf, render.ns, 0, -1, {}), 0)
end

return T
