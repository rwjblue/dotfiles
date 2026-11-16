local ui = require("agent-review.ui")
local store = require("agent-review.store")
local render = require("agent-review.render")
local previous
local T = MiniTest.new_set({
  hooks = {
    pre_case = function()
      previous = { cwd = vim.fn.getcwd(), snacks = package.loaded.snacks }
      require("agent-review").setup({ keymap_prefix = "<leader>r" })
    end,
    post_case = function()
      vim.fn.chdir(previous.cwd)
      package.loaded.snacks = previous.snacks
    end,
  },
})

local function temp_git_repo()
  local dir = vim.fn.fnamemodify(vim.fn.tempname(), ":p")
  vim.fn.mkdir(dir, "p")
  vim.fn.system({ "git", "-C", dir, "init", "-q" })
  return vim.uv.fs_realpath(dir)
end

local function review_file(root, file, body)
  local path = vim.fs.joinpath(root, file)
  vim.fn.writefile({ "alpha", "beta", "gamma" }, path)
  if body then
    store.add(root, { file = file, start_line = 1, end_line = 1, snippet = "alpha", body = body })
  end
  return path
end

T["_make_comment captures path, range, and snippet"] = function()
  local root = temp_git_repo()
  local buf = vim.fn.bufadd(review_file(root, "foo.txt"))
  vim.fn.bufload(buf)
  local c = ui._make_comment(buf, 2, 3, "a note")

  MiniTest.expect.equality(c.file, "foo.txt")
  MiniTest.expect.equality(c.start_line, 2)
  MiniTest.expect.equality(c.end_line, 3)
  MiniTest.expect.equality(c.snippet, "beta\ngamma")
  MiniTest.expect.equality(c.body, "a note")
end

T["edit and delete use the buffer's repo when cwd differs"] = function()
  local first, second = temp_git_repo(), temp_git_repo()
  local path = review_file(first, "file.txt", "first")
  local second_path = review_file(second, "file.txt", "second")
  vim.fn.chdir(second)
  vim.cmd.edit(vim.fn.fnameescape(path))
  vim.api.nvim_win_set_cursor(0, { 1, 0 })
  MiniTest.expect.equality(render.comment_id_at(0, 0), 1)

  local confirm
  package.loaded.snacks = { input = function(_, callback) confirm = callback end }
  vim.cmd.AgentReviewEdit()
  vim.cmd.edit(vim.fn.fnameescape(second_path))
  confirm("edited")
  MiniTest.expect.equality(store.load(first)[1].body, "edited")
  MiniTest.expect.equality(store.load(second)[1].body, "second")

  vim.cmd.edit(vim.fn.fnameescape(path))
  vim.cmd.AgentReviewDelete()
  MiniTest.expect.equality(store.load(first), {})
  MiniTest.expect.equality(store.load(second)[1].body, "second")
end

T["a stale extmark cannot edit or delete a reused ID in another file"] = function()
  local root = temp_git_repo()
  vim.cmd.edit(vim.fn.fnameescape(review_file(root, "old.txt", "old")))
  vim.api.nvim_win_set_cursor(0, { 1, 0 })
  MiniTest.expect.equality(render.comment_id_at(0, 0), 1)
  store.clear(root)
  review_file(root, "new.txt", "new")
  package.loaded.snacks = { input = function() error("unexpected edit prompt") end }

  vim.cmd.AgentReviewEdit()
  -- Exercise delete with the same stale extmark after edit refreshed the buffer.
  vim.api.nvim_buf_set_extmark(0, render.ns, 0, 0, { id = 1 })
  vim.cmd.AgentReviewDelete()
  MiniTest.expect.equality(store.load(root)[1].body, "new")
end

T["Ex range and live backwards visual selection ignore previous marks"] = function()
  local root = temp_git_repo()
  vim.cmd.edit(vim.fn.fnameescape(review_file(root, "foo.txt")))
  package.loaded.snacks = { input = function(_, callback) callback("note") end }
  vim.api.nvim_buf_set_mark(0, "<", 1, 0, {})
  vim.api.nvim_buf_set_mark(0, ">", 1, 0, {})

  vim.cmd("2,3AgentReviewAdd")
  vim.api.nvim_win_set_cursor(0, { 3, 0 })
  local keys = vim.api.nvim_replace_termcodes("Vk<leader>rc<Esc>", true, false, true)
  vim.api.nvim_feedkeys(keys, "xt", false)

  local notes = store.load(root)
  MiniTest.expect.equality(#notes, 2)
  for _, note in ipairs(notes) do
    MiniTest.expect.equality({ note.start_line, note.end_line, note.snippet }, { 2, 3, "beta\ngamma" })
  end
end

T["clearing a batch removes marks from all its loaded buffers"] = function()
  local first, second = temp_git_repo(), temp_git_repo()
  local path = review_file(first, "one.txt", "one")
  local same_repo = vim.fn.bufadd(review_file(first, "two.txt", "two"))
  local other_repo = vim.fn.bufadd(review_file(second, "three.txt", "three"))
  vim.fn.bufload(same_repo)
  vim.fn.bufload(other_repo)
  vim.fn.chdir(second)
  vim.cmd.edit(vim.fn.fnameescape(path))
  MiniTest.expect.equality(render.comment_id_at(0, 0), 1)
  MiniTest.expect.equality(render.comment_id_at(same_repo, 0), 2)
  MiniTest.expect.equality(render.comment_id_at(other_repo, 0), 1)

  vim.cmd.AgentReviewClear()

  MiniTest.expect.equality(store.load(first), {})
  MiniTest.expect.equality(render.comment_id_at(0, 0), nil)
  MiniTest.expect.equality(render.comment_id_at(same_repo, 0), nil)
  MiniTest.expect.equality(render.comment_id_at(other_repo, 0), 1)
end

return T
