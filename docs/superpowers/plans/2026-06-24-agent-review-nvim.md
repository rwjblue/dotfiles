# agent-review.nvim Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a standalone Neovim plugin (`packages/agent-review.nvim`) for authoring inline review comments on agent work locally, persisted to a stable `.agent-review/comments.md` at the repo root.

**Architecture:** Pure logic (`format`, `anchor`) is isolated from fs (`store`) and from nvim UI (`render`, `ui`), so the core round-trips and drift-resolves under unit test. Comments persist as one Markdown file that doubles as a clean agent brief; nvim re-anchors drifted comments by a stored text snippet. The plugin loads locally via a thin lazy spec pointing at the package by `dir`.

**Tech Stack:** Lua, Neovim (extmarks/virtual-lines), `mini.test` (self-bootstrapped via `mini.nvim`), `snacks.nvim` (input + picker), `jj`/`git` for repo-root resolution, `mise` task runner.

---

## File Structure

```
packages/agent-review.nvim/
├── lua/agent-review/
│   ├── format.lua    # pure: encode(comments)->string, decode(string)->comments
│   ├── anchor.lua    # pure: resolve(lines, comment)->{status,line}
│   ├── store.lua     # fs: repo_root, file_path, load/save/add/update/delete/clear
│   ├── render.lua    # extmark virtual-lines + signs for a buffer
│   ├── ui.lua        # authoring float/scratch, edit/delete, snacks list, navigate
│   └── init.lua      # setup(opts): config, commands, keymaps, autocmds
├── tests/
│   ├── minimal_init.lua
│   ├── test_format.lua
│   ├── test_anchor.lua
│   ├── test_store.lua
│   ├── test_render.lua
│   └── test_ui.lua
├── deps/             # gitignored; mini.nvim cloned here by the harness
├── .gitignore
└── README.md
packages/nvim/lua/plugins/agent-review.lua   # local lazy spec (dir=...)
mise/tasks/agent-review/test                 # headless test runner task
packages/git/gitignore_global                # add `.agent-review/`
```

**Comment model (locked — used by every task):**

```
Comment = {
  id         = integer,   -- stable within file, monotonic; targets edit/delete
  file       = string,    -- repo-root-relative path, forward slashes
  start_line = integer,   -- 1-based start line at authoring time
  end_line   = integer,   -- 1-based end line (== start_line for single line)
  snippet    = string,    -- quoted anchor block; may be multi-line ("\n"); anchor = first line
  body       = string,    -- markdown, may be multi-line
}
```

Note: the model uses `start_line`/`end_line` (the word `end` is a Lua keyword). The on-disk marker uses `start=`/`end=` attributes.

**Commit convention:** this repo uses `jj`. Each task ends with `jj commit -m "<msg>"`. Include the trailer line `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>` in every commit message.

---

## Task 1: Package scaffold + test harness

**Files:**
- Create: `packages/agent-review.nvim/lua/agent-review/init.lua`
- Create: `packages/agent-review.nvim/tests/minimal_init.lua`
- Create: `packages/agent-review.nvim/tests/test_smoke.lua`
- Create: `packages/agent-review.nvim/.gitignore`
- Create: `mise/tasks/agent-review/test`

- [ ] **Step 1: Create the `.gitignore`**

```
deps/
```

- [ ] **Step 2: Create the test harness `tests/minimal_init.lua`**

```lua
-- Self-bootstrapping mini.nvim harness so the package tests run standalone.
local root = vim.fn.fnamemodify(vim.fn.getcwd(), ":p")
local mini_path = root .. "deps/mini.nvim"
if vim.fn.isdirectory(mini_path) == 0 then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/echasnovski/mini.nvim", mini_path,
  })
end
vim.opt.rtp:prepend(root)       -- the plugin under test (require("agent-review.*"))
vim.opt.rtp:prepend(mini_path)  -- provides mini.test
require("mini.test").setup()
```

- [ ] **Step 3: Create a minimal `lua/agent-review/init.lua` stub**

```lua
local M = {}

function M.setup(_opts) end

return M
```

- [ ] **Step 4: Create `tests/test_smoke.lua`**

```lua
local T = MiniTest.new_set()

T["package loads"] = function()
  local ok = pcall(require, "agent-review")
  MiniTest.expect.equality(ok, true)
end

return T
```

- [ ] **Step 5: Create the mise task `mise/tasks/agent-review/test`**

```bash
#!/usr/bin/env bash
#MISE description="Run agent-review.nvim tests headless"
set -euo pipefail

cd "$MISE_PROJECT_ROOT/packages/agent-review.nvim"
nvim --headless --noplugin -u ./tests/minimal_init.lua -c "lua MiniTest.run()"
```

Then make it executable:

Run: `chmod +x mise/tasks/agent-review/test`

- [ ] **Step 6: Run the suite to verify the harness works**

Run: `mise run agent-review:test`
Expected: mini.nvim clones into `deps/` on first run, then PASS for "package loads" (green, exit 0).

- [ ] **Step 7: Commit**

```bash
jj commit -m "feat(agent-review): scaffold package and mini.test harness

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 2: `format.decode`

**Files:**
- Create: `packages/agent-review.nvim/lua/agent-review/format.lua`
- Create: `packages/agent-review.nvim/tests/test_format.lua`

- [ ] **Step 1: Write the failing test**

```lua
local format = require("agent-review.format")
local T = MiniTest.new_set()

T["decode parses a single comment"] = function()
  local text = table.concat({
    "<!-- agent-review:v1 -->",
    "# Agent review comments",
    "",
    "<!-- agent-review:v1 comment id=1 file=src/user.ts start=42 end=44 -->",
    "### src/user.ts:42-44",
    "> const result = await fetchUser(id)",
    "",
    "This needs a null check before `.name`.",
  }, "\n")

  local comments = format.decode(text)
  MiniTest.expect.equality(#comments, 1)
  local c = comments[1]
  MiniTest.expect.equality(c.id, 1)
  MiniTest.expect.equality(c.file, "src/user.ts")
  MiniTest.expect.equality(c.start_line, 42)
  MiniTest.expect.equality(c.end_line, 44)
  MiniTest.expect.equality(c.snippet, "const result = await fetchUser(id)")
  MiniTest.expect.equality(c.body, "This needs a null check before `.name`.")
end

T["decode parses multi-line snippet and body"] = function()
  local text = table.concat({
    "<!-- agent-review:v1 -->",
    "",
    "<!-- agent-review:v1 comment id=2 file=a.lua start=1 end=2 -->",
    "### a.lua:1-2",
    "> local x = 1",
    "> local y = 2",
    "",
    "first body line",
    "second body line",
  }, "\n")

  local c = format.decode(text)[1]
  MiniTest.expect.equality(c.snippet, "local x = 1\nlocal y = 2")
  MiniTest.expect.equality(c.body, "first body line\nsecond body line")
end

T["decode of empty/garbled input yields no comments"] = function()
  MiniTest.expect.equality(#format.decode(""), 0)
  MiniTest.expect.equality(#format.decode("just some text\nno markers"), 0)
end

return T
```

- [ ] **Step 2: Run test to verify it fails**

Run: `mise run agent-review:test`
Expected: FAIL — `module 'agent-review.format' not found`.

- [ ] **Step 3: Write the implementation (decode only)**

```lua
local M = {}

local MARKER = "<!%-%- agent%-review:v1 comment (.-) %-%->"

local function trim(s)
  return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function parse_attrs(s)
  local attrs = {}
  for key, value in s:gmatch("(%w+)=(%S+)") do
    attrs[key] = value
  end
  return attrs
end

---@param text string
---@return table[] comments
function M.decode(text)
  local lines = vim.split(text or "", "\n", { plain = true })
  local comments = {}
  local i = 1
  while i <= #lines do
    local attr_str = lines[i]:match(MARKER)
    if attr_str then
      local attrs = parse_attrs(attr_str)
      local comment = {
        id = tonumber(attrs.id),
        file = attrs.file,
        start_line = tonumber(attrs.start),
        end_line = tonumber(attrs["end"]),
      }
      i = i + 1
      -- optional `### ...` heading
      if lines[i] and lines[i]:match("^###%s") then
        i = i + 1
      end
      -- snippet: consecutive `> ` lines
      local snippet = {}
      while lines[i] and lines[i]:match("^> ") do
        table.insert(snippet, lines[i]:gsub("^> ", ""))
        i = i + 1
      end
      comment.snippet = table.concat(snippet, "\n")
      -- skip the single blank separator
      if lines[i] == "" then i = i + 1 end
      -- body: until next marker or EOF
      local body = {}
      while lines[i] ~= nil and not lines[i]:match(MARKER) do
        table.insert(body, lines[i])
        i = i + 1
      end
      -- trim trailing blank lines from body
      while #body > 0 and body[#body] == "" do
        table.remove(body)
      end
      comment.body = table.concat(body, "\n")
      table.insert(comments, comment)
    else
      i = i + 1
    end
  end
  return comments
end

return M
```

- [ ] **Step 4: Run test to verify it passes**

Run: `mise run agent-review:test`
Expected: PASS (all `test_format` + earlier tests green).

- [ ] **Step 5: Commit**

```bash
jj commit -m "feat(agent-review): add format.decode

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 3: `format.encode` + roundtrip

**Files:**
- Modify: `packages/agent-review.nvim/lua/agent-review/format.lua`
- Modify: `packages/agent-review.nvim/tests/test_format.lua`

- [ ] **Step 1: Add the failing tests**

```lua
T["encode then decode roundtrips"] = function()
  local comments = {
    {
      id = 1, file = "src/user.ts", start_line = 42, end_line = 44,
      snippet = "const result = await fetchUser(id)",
      body = "needs a null check",
    },
    {
      id = 2, file = "a.lua", start_line = 1, end_line = 2,
      snippet = "local x = 1\nlocal y = 2",
      body = "line one\nline two",
    },
  }
  local decoded = format.decode(format.encode(comments))
  MiniTest.expect.equality(decoded, comments)
end

T["encode emits the version header once"] = function()
  local out = format.encode({})
  MiniTest.expect.equality(out:match("^<!%-%- agent%-review:v1 %-%->") ~= nil, true)
end

T["encode single-line range uses :N heading, multi uses :N-M"] = function()
  local out = format.encode({
    { id = 1, file = "f", start_line = 5, end_line = 5, snippet = "x", body = "b" },
  })
  MiniTest.expect.equality(out:match("### f:5\n") ~= nil, true)
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `mise run agent-review:test`
Expected: FAIL — `attempt to call field 'encode' (a nil value)`.

- [ ] **Step 3: Implement `encode` (add to `format.lua` before `return M`)**

```lua
---@param comments table[]
---@return string
function M.encode(comments)
  local out = { "<!-- agent-review:v1 -->", "# Agent review comments", "" }
  for _, c in ipairs(comments) do
    local span = c.start_line == c.end_line
        and tostring(c.start_line)
        or (c.start_line .. "-" .. c.end_line)
    table.insert(out, string.format(
      "<!-- agent-review:v1 comment id=%d file=%s start=%d end=%d -->",
      c.id, c.file, c.start_line, c.end_line))
    table.insert(out, "### " .. c.file .. ":" .. span)
    for _, line in ipairs(vim.split(c.snippet or "", "\n", { plain = true })) do
      table.insert(out, "> " .. line)
    end
    table.insert(out, "")
    table.insert(out, c.body)
    table.insert(out, "")
  end
  return table.concat(out, "\n")
end
```

- [ ] **Step 4: Run test to verify it passes**

Run: `mise run agent-review:test`
Expected: PASS (roundtrip equality holds).

- [ ] **Step 5: Commit**

```bash
jj commit -m "feat(agent-review): add format.encode with roundtrip

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 4: `anchor.resolve` (drift handling)

**Files:**
- Create: `packages/agent-review.nvim/lua/agent-review/anchor.lua`
- Create: `packages/agent-review.nvim/tests/test_anchor.lua`

- [ ] **Step 1: Write the failing test**

```lua
local anchor = require("agent-review.anchor")
local T = MiniTest.new_set()

local function comment(start_line, snippet)
  return { start_line = start_line, snippet = snippet }
end

T["exact match at original line"] = function()
  local lines = { "a", "target", "c" }
  MiniTest.expect.equality(
    anchor.resolve(lines, comment(2, "target")),
    { status = "exact", line = 2 })
end

T["moved: finds nearest match when line drifted"] = function()
  local lines = { "x", "x", "target", "y" } -- now on line 3
  MiniTest.expect.equality(
    anchor.resolve(lines, comment(2, "target")),
    { status = "moved", line = 3 })
end

T["moved: picks occurrence nearest to original start"] = function()
  local lines = { "dup", "a", "b", "dup" }
  MiniTest.expect.equality(
    anchor.resolve(lines, comment(4, "dup")),
    { status = "moved", line = 4 }) -- exact wins here
  MiniTest.expect.equality(
    anchor.resolve(lines, comment(3, "dup")),
    { status = "moved", line = 4 }) -- nearest to 3 is 4
end

T["orphaned when snippet absent"] = function()
  MiniTest.expect.equality(
    anchor.resolve({ "a", "b" }, comment(1, "missing")),
    { status = "orphaned", line = vim.NIL == nil and nil or nil })
end

T["orphaned when snippet is empty"] = function()
  MiniTest.expect.equality(
    anchor.resolve({ "", "" }, comment(1, "")).status, "orphaned")
end

T["anchors on first line of a multi-line snippet"] = function()
  local lines = { "first", "second" }
  MiniTest.expect.equality(
    anchor.resolve(lines, comment(1, "first\nsecond")),
    { status = "exact", line = 1 })
end

return T
```

Note: the `orphaned` result is `{ status = "orphaned", line = nil }`; `MiniTest.expect.equality` compares tables structurally and a `nil` field is simply absent, so compare against `{ status = "orphaned" }` if a literal `nil` field reads awkwardly. Use this exact assertion in the absent-snippet case:

```lua
T["orphaned when snippet absent"] = function()
  MiniTest.expect.equality(
    anchor.resolve({ "a", "b" }, comment(1, "missing")),
    { status = "orphaned" })
end
```

(Replace the earlier `orphaned when snippet absent` block with this one.)

- [ ] **Step 2: Run test to verify it fails**

Run: `mise run agent-review:test`
Expected: FAIL — `module 'agent-review.anchor' not found`.

- [ ] **Step 3: Write the implementation**

```lua
local M = {}

local function trim(s)
  return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function first_line(s)
  return (s:gsub("\n.*$", ""))
end

---@param lines string[] current buffer lines (1-based)
---@param comment table { start_line, snippet }
---@return table { status: "exact"|"moved"|"orphaned", line?: integer }
function M.resolve(lines, comment)
  local target = trim(first_line(comment.snippet or ""))
  if target == "" then
    return { status = "orphaned" }
  end
  local start = comment.start_line

  if start and lines[start] and trim(lines[start]) == target then
    return { status = "exact", line = start }
  end

  local best, best_dist
  for i, line in ipairs(lines) do
    if trim(line) == target then
      local dist = math.abs(i - (start or i))
      if not best_dist or dist < best_dist then
        best, best_dist = i, dist
      end
    end
  end
  if best then
    return { status = "moved", line = best }
  end
  return { status = "orphaned" }
end

return M
```

- [ ] **Step 4: Run test to verify it passes**

Run: `mise run agent-review:test`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
jj commit -m "feat(agent-review): add anchor.resolve drift handling

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 5: `store` — repo root + paths

**Files:**
- Create: `packages/agent-review.nvim/lua/agent-review/store.lua`
- Create: `packages/agent-review.nvim/tests/test_store.lua`

- [ ] **Step 1: Write the failing test**

```lua
local store = require("agent-review.store")
local T = MiniTest.new_set()

-- helper: make a temp git repo, return its realpath
local function temp_git_repo()
  local dir = vim.fn.fnamemodify(vim.fn.tempname(), ":p")
  vim.fn.mkdir(dir, "p")
  vim.fn.system({ "git", "-C", dir, "init", "-q" })
  return vim.loop.fs_realpath(dir)
end

T["repo_root resolves a git repo via cwd"] = function()
  local repo = temp_git_repo()
  local prev = vim.fn.getcwd()
  vim.fn.chdir(repo)
  local got = vim.loop.fs_realpath(store.repo_root())
  vim.fn.chdir(prev)
  MiniTest.expect.equality(got, repo)
end

T["file_path is <root>/.agent-review/comments.md"] = function()
  MiniTest.expect.equality(store.file_path("/x"), "/x/.agent-review/comments.md")
end

return T
```

- [ ] **Step 2: Run test to verify it fails**

Run: `mise run agent-review:test`
Expected: FAIL — `module 'agent-review.store' not found`.

- [ ] **Step 3: Write the implementation (root + paths only)**

```lua
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
  return root .. "/.agent-review"
end

---@param root string
---@return string
function M.file_path(root)
  return M.dir(root) .. "/comments.md"
end

return M
```

(Note: `format` is required now for use in Task 6; keep the `require` at top.)

- [ ] **Step 4: Run test to verify it passes**

Run: `mise run agent-review:test`
Expected: PASS (the git fallback path is exercised; temp dirs are not jj repos).

- [ ] **Step 5: Commit**

```bash
jj commit -m "feat(agent-review): add store repo-root and path resolution

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 6: `store` — load/save/CRUD + id allocation

**Files:**
- Modify: `packages/agent-review.nvim/lua/agent-review/store.lua`
- Modify: `packages/agent-review.nvim/tests/test_store.lua`

- [ ] **Step 1: Add the failing tests**

```lua
local function temp_root()
  local dir = vim.fn.fnamemodify(vim.fn.tempname(), ":p")
  vim.fn.mkdir(dir, "p")
  return vim.loop.fs_realpath(dir)
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `mise run agent-review:test`
Expected: FAIL — `attempt to call field 'load' (a nil value)`.

- [ ] **Step 3: Implement load/save/CRUD (add to `store.lua` before `return M`)**

```lua
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
  local f = assert(io.open(M.file_path(root), "w"))
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
  comment.id = next_id(comments)
  table.insert(comments, comment)
  M.save(root, comments)
  return comment
end

---@param root string
---@param id integer
---@param fields table
function M.update(root, id, fields)
  local comments = M.load(root)
  for _, c in ipairs(comments) do
    if c.id == id then
      for k, v in pairs(fields) do c[k] = v end
    end
  end
  M.save(root, comments)
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
```

- [ ] **Step 4: Run test to verify it passes**

Run: `mise run agent-review:test`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
jj commit -m "feat(agent-review): add store load/save/CRUD with id allocation

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 7: `render` — inline virtual lines + signs

**Files:**
- Create: `packages/agent-review.nvim/lua/agent-review/render.lua`
- Create: `packages/agent-review.nvim/tests/test_render.lua`

- [ ] **Step 1: Write the smoke test**

```lua
local render = require("agent-review.render")
local store = require("agent-review.store")
local T = MiniTest.new_set()

local function temp_git_repo()
  local dir = vim.fn.fnamemodify(vim.fn.tempname(), ":p")
  vim.fn.mkdir(dir, "p")
  vim.fn.system({ "git", "-C", dir, "init", "-q" })
  return vim.loop.fs_realpath(dir)
end

T["render places an extmark for an anchored comment"] = function()
  local root = temp_git_repo()
  -- a file in the repo with known content
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `mise run agent-review:test`
Expected: FAIL — `module 'agent-review.render' not found`.

- [ ] **Step 3: Write the implementation**

```lua
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
          virt_lines = virt,
          sign_text = "💬",
          sign_hl_group = "Comment",
        })
      end
    end
  end
end

return M
```

- [ ] **Step 4: Run test to verify it passes**

Run: `mise run agent-review:test`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
jj commit -m "feat(agent-review): render inline virtual lines and signs

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 8: `ui` — authoring, edit/delete, list, navigate

**Files:**
- Create: `packages/agent-review.nvim/lua/agent-review/ui.lua`
- Create: `packages/agent-review.nvim/tests/test_ui.lua`

- [ ] **Step 1: Write the failing test (for the pure builder)**

```lua
local ui = require("agent-review.ui")
local T = MiniTest.new_set()

local function temp_git_repo()
  local dir = vim.fn.fnamemodify(vim.fn.tempname(), ":p")
  vim.fn.mkdir(dir, "p")
  vim.fn.system({ "git", "-C", dir, "init", "-q" })
  return vim.loop.fs_realpath(dir)
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `mise run agent-review:test`
Expected: FAIL — `module 'agent-review.ui' not found`.

- [ ] **Step 3: Write the implementation**

```lua
local store = require("agent-review.store")
local render = require("agent-review.render")

local M = {}

---Build a comment table from buffer state (pure-ish; reads the buffer).
---@param bufnr integer
---@param srow integer 1-based start row
---@param erow integer 1-based end row
---@param body string
---@return table|nil comment, string|nil err
function M._make_comment(bufnr, srow, erow, body)
  local root = store.repo_root()
  if not root then return nil, "not in a repo" end
  local name = vim.api.nvim_buf_get_name(bufnr)
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
  local marks = vim.api.nvim_buf_get_extmarks(0, render.ns, 0, -1, { details = true })
  local cur = vim.api.nvim_win_get_cursor(0)[1] - 1
  for _, m in ipairs(marks) do
    if m[2] == cur then
      -- recover id by matching the first virt_line text "💬 [<id>]"
      local text = m[4] and m[4].virt_lines and m[4].virt_lines[1]
          and m[4].virt_lines[1][1][1] or ""
      local id = text:match("%[(%d+)%]")
      if id then return tonumber(id) end
    end
  end
  return nil
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
  prompt(nil, function(body)
    local c, err = M._make_comment(0, row, row, body)
    if not c then return vim.notify("agent-review: " .. err, vim.log.levels.WARN) end
    store.add(store.repo_root(), c)
    render.buffer(0)
  end)
end

---Add a comment spanning the last visual selection.
function M.add_visual()
  local srow = vim.fn.line("'<")
  local erow = vim.fn.line("'>")
  prompt(nil, function(body)
    local c, err = M._make_comment(0, srow, erow, body)
    if not c then return vim.notify("agent-review: " .. err, vim.log.levels.WARN) end
    store.add(store.repo_root(), c)
    render.buffer(0)
  end)
end

---Edit the comment under the cursor.
function M.edit()
  local id = comment_id_at_cursor()
  if not id then return vim.notify("agent-review: no comment here", vim.log.levels.INFO) end
  local root = store.repo_root()
  local existing
  for _, c in ipairs(store.load(root)) do if c.id == id then existing = c end end
  prompt(existing and existing.body, function(body)
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

---Open a snacks picker of all comments (with an orphaned bucket).
function M.list()
  local root = store.repo_root()
  if not root then return end
  local comments = store.load(root)
  local items = {}
  for _, c in ipairs(comments) do
    items[#items + 1] = {
      text = string.format("%s:%d  %s", c.file, c.start_line, vim.split(c.body, "\n")[1]),
      file = root .. "/" .. c.file,
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
```

- [ ] **Step 4: Run test to verify it passes**

Run: `mise run agent-review:test`
Expected: PASS (`_make_comment` test green; interactive functions are exercised manually in Task 9).

- [ ] **Step 5: Commit**

```bash
jj commit -m "feat(agent-review): add authoring, edit/delete, list, navigation UI

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 9: `init.setup`, lazy spec, gitignore, README

**Files:**
- Modify: `packages/agent-review.nvim/lua/agent-review/init.lua`
- Create: `packages/agent-review.nvim/README.md`
- Create: `packages/nvim/lua/plugins/agent-review.lua`
- Modify: `packages/git/gitignore_global`

- [ ] **Step 1: Implement `init.lua` (replace the stub)**

```lua
local M = {}

M.config = {
  keymap_prefix = "<leader>r",
}

local function setup_commands()
  local ui = require("agent-review.ui")
  local render = require("agent-review.render")
  local store = require("agent-review.store")

  vim.api.nvim_create_user_command("AgentReviewAdd", function(o)
    if o.range > 0 then ui.add_visual() else ui.add() end
  end, { range = true, desc = "Add a review comment" })
  vim.api.nvim_create_user_command("AgentReviewEdit", ui.edit, { desc = "Edit comment under cursor" })
  vim.api.nvim_create_user_command("AgentReviewDelete", ui.delete, { desc = "Delete comment under cursor" })
  vim.api.nvim_create_user_command("AgentReviewList", ui.list, { desc = "List review comments" })
  vim.api.nvim_create_user_command("AgentReviewReload", function() render.buffer(0) end, { desc = "Re-render comments" })
  vim.api.nvim_create_user_command("AgentReviewClear", function()
    local root = store.repo_root()
    if root then store.clear(root); render.buffer(0) end
  end, { desc = "Clear the active review batch" })
end

local function setup_keymaps()
  local p = M.config.keymap_prefix
  local ui = require("agent-review.ui")
  vim.keymap.set("n", p .. "c", ui.add, { desc = "Review: add comment" })
  vim.keymap.set("x", p .. "c", ui.add_visual, { desc = "Review: add comment (range)" })
  vim.keymap.set("n", p .. "e", ui.edit, { desc = "Review: edit comment" })
  vim.keymap.set("n", p .. "d", ui.delete, { desc = "Review: delete comment" })
  vim.keymap.set("n", p .. "l", ui.list, { desc = "Review: list comments" })
  vim.keymap.set("n", p .. "r", function() require("agent-review.render").buffer(0) end, { desc = "Review: reload" })
  vim.keymap.set("n", "]r", ui.next, { desc = "Review: next comment" })
  vim.keymap.set("n", "[r", ui.prev, { desc = "Review: prev comment" })
end

local function setup_autocmds()
  local group = vim.api.nvim_create_augroup("agent_review_render", { clear = true })
  vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost" }, {
    group = group,
    callback = function(ev) require("agent-review.render").buffer(ev.buf) end,
  })
end

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})
  setup_commands()
  setup_keymaps()
  setup_autocmds()
end

return M
```

- [ ] **Step 2: Verify no `<leader>r` collision in LazyVim**

Run: `nvim --headless "+lua local ok=pcall(vim.fn.maparg, '<leader>r','n'); print(vim.fn.maparg('<leader>r','n'))" +qa`
Expected: prints empty (no existing top-level `<leader>r` mapping). If non-empty, change `keymap_prefix` default to `<leader>cr` and update the README; record the decision in the task notes.

- [ ] **Step 3: Create the local lazy spec `packages/nvim/lua/plugins/agent-review.lua`**

```lua
return {
  {
    "rwjblue/agent-review.nvim",
    dir = vim.fn.expand("~/src/github/rwjblue/dotfiles/packages/agent-review.nvim"),
    dependencies = { "folke/snacks.nvim" },
    event = "VeryLazy",
    opts = {},
  },
  {
    "folke/which-key.nvim",
    optional = true,
    opts = { spec = { { "<leader>r", group = "review" } } },
  },
}
```

- [ ] **Step 4: Add `.agent-review/` to the global gitignore**

Append to `packages/git/gitignore_global`:

```
# agent-review.nvim local review batches
.agent-review/
```

- [ ] **Step 5: Write `README.md`**

```markdown
# agent-review.nvim

Author inline review comments on an agent's work locally in Neovim, batched into
a single `.agent-review/comments.md` at the repo root that a tool-agnostic agent
skill (Claude Code / Codex) reads and addresses.

## Install (local, via this dotfiles repo)

Loaded by `packages/nvim/lua/plugins/agent-review.lua` as a `dir=` plugin.
Requires `snacks.nvim`.

## Keymaps (`<leader>r` group)

| Key | Action |
|-----|--------|
| `<leader>rc` | Add comment (normal: line; visual: range) |
| `<leader>re` | Edit comment under cursor |
| `<leader>rd` | Delete comment under cursor |
| `<leader>rl` | List all comments (snacks picker) |
| `<leader>rr` | Re-render comments |
| `]r` / `[r` | Next / previous comment |

`:AgentReviewClear` wipes the active batch (archiving is normally the agent skill's job).

## File format

See `docs/superpowers/specs/2026-06-24-agent-review-nvim-design.md`.

## Tests

`mise run agent-review:test`
```

- [ ] **Step 6: Run the full suite**

Run: `mise run agent-review:test`
Expected: PASS (all tests green).

- [ ] **Step 7: Manual smoke check (interactive)**

Run: `nvim` in a repo, open a tracked file, press `<leader>rc`, type a comment, confirm it renders as a virtual line below the cursor and that `.agent-review/comments.md` now contains the comment. Then `<leader>rl` lists it.

- [ ] **Step 8: Commit**

```bash
jj commit -m "feat(agent-review): wire setup, lazy spec, gitignore, README

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Self-Review Notes

- **Spec coverage:** format v1 (T2–3), drift exact/moved/orphaned (T4), stable file + CRUD + repo-root (T5–6), virtual-line render + signs + moved tag (T7), authoring/range/edit/delete/list/navigate (T8), keymaps/commands/autocmds + gitignore + lazy load (T9). Orphaned bucket in the list panel: T8 `list()` currently lists all comments by stored line; comments whose snippet can't be found still appear (by original line) — acceptable for v1, since `list()` shows every stored comment regardless of anchor status. A dedicated visual "Orphaned" section is deferred (noted as a v1 simplification).
- **Deferred (other specs):** the agent `SKILL.md` + symlink, SDK tests.
- **Type consistency:** `Comment` fields (`id`, `file`, `start_line`, `end_line`, `snippet`, `body`) and `render.ns` are used identically across `format`, `anchor`, `store`, `render`, `ui`.
