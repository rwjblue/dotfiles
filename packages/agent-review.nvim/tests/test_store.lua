local store = require("agent-review.store")
local T = MiniTest.new_set()

-- helper: make a temp git repo, return its realpath
local function temp_git_repo()
  local dir = vim.fn.fnamemodify(vim.fn.tempname(), ":p")
  vim.fn.mkdir(dir, "p")
  vim.fn.system({ "git", "-C", dir, "init", "-q" })
  return vim.uv.fs_realpath(dir)
end

T["repo_root resolves a git repo via cwd"] = function()
  local repo = temp_git_repo()
  local prev = vim.fn.getcwd()
  vim.fn.chdir(repo)
  local root = store.repo_root()
  vim.fn.chdir(prev)
  MiniTest.expect.equality(root ~= nil, true)
  MiniTest.expect.equality(vim.uv.fs_realpath(root), repo)
end

T["file_path is <root>/.agent-review/comments.md"] = function()
  MiniTest.expect.equality(store.file_path("/x"), "/x/.agent-review/comments.md")
end

return T
