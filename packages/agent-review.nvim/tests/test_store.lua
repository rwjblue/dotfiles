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

local function temp_root()
  local dir = vim.fn.fnamemodify(vim.fn.tempname(), ":p")
  vim.fn.mkdir(dir, "p")
  return vim.uv.fs_realpath(dir)
end

T["load on missing file returns empty"] = function()
  MiniTest.expect.equality(store.load(temp_root()), {})
end

T["add allocates monotonic ids and persists"] = function()
  local root = temp_root()
  local a = store.add(root, { file = "f", start_line = 1, end_line = 1, snippet = "x", body = "one" })
  local b = store.add(root, { file = "f", start_line = 2, end_line = 2, snippet = "y", body = "two" })
  MiniTest.expect.equality(a.id, 1)
  MiniTest.expect.equality(b.id, 2)
  MiniTest.expect.equality(#store.load(root), 2)
end

T["update mutates a comment by id"] = function()
  local root = temp_root()
  store.add(root, { file = "f", start_line = 1, end_line = 1, snippet = "x", body = "old" })
  store.update(root, 1, { body = "new" })
  MiniTest.expect.equality(store.load(root)[1].body, "new")
end

T["delete removes a comment by id"] = function()
  local root = temp_root()
  store.add(root, { file = "f", start_line = 1, end_line = 1, snippet = "x", body = "one" })
  store.add(root, { file = "f", start_line = 2, end_line = 2, snippet = "y", body = "two" })
  store.delete(root, 1)
  local left = store.load(root)
  MiniTest.expect.equality(#left, 1)
  MiniTest.expect.equality(left[1].id, 2)
end

T["clear empties the batch"] = function()
  local root = temp_root()
  store.add(root, { file = "f", start_line = 1, end_line = 1, snippet = "x", body = "one" })
  store.clear(root)
  MiniTest.expect.equality(#store.load(root), 0)
end

T["update on unknown id is a no-op returning false"] = function()
  local root = temp_root()
  store.add(root, { file = "f", start_line = 1, end_line = 1, snippet = "x", body = "one" })
  local ok = store.update(root, 999, { body = "nope" })
  MiniTest.expect.equality(ok, false)
  MiniTest.expect.equality(store.load(root)[1].body, "one")
end

return T
