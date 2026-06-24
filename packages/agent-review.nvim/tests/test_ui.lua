local ui = require("agent-review.ui")
local T = MiniTest.new_set()

local function temp_git_repo()
  local dir = vim.fn.fnamemodify(vim.fn.tempname(), ":p")
  vim.fn.mkdir(dir, "p")
  vim.fn.system({ "git", "-C", dir, "init", "-q" })
  return vim.uv.fs_realpath(dir)
end

T["_make_comment captures path, range, and snippet"] = function()
  local root = temp_git_repo()
  local file = root .. "/foo.txt"
  vim.fn.writefile({ "alpha", "beta", "gamma" }, file)

  local prev = vim.fn.getcwd()
  vim.fn.chdir(root)
  local buf = vim.fn.bufadd(file)
  vim.fn.bufload(buf)
  local c = ui._make_comment(buf, 2, 3, "a note")
  vim.fn.chdir(prev)

  MiniTest.expect.equality(c.file, "foo.txt")
  MiniTest.expect.equality(c.start_line, 2)
  MiniTest.expect.equality(c.end_line, 3)
  MiniTest.expect.equality(c.snippet, "beta\ngamma")
  MiniTest.expect.equality(c.body, "a note")
end

return T
