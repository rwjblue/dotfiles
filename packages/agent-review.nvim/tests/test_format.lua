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

T["decode handles missing snippet"] = function()
  local text = table.concat({
    "<!-- agent-review:v1 comment id=3 file=README.md start=1 end=1 -->",
    "### README.md:1-1",
    "",
    "Whole-file note.",
  }, "\n")
  local c = format.decode(text)[1]
  MiniTest.expect.equality(c.snippet, "")
  MiniTest.expect.equality(c.body, "Whole-file note.")
end

T["decode handles missing body"] = function()
  local text = table.concat({
    "<!-- agent-review:v1 comment id=4 file=a.lua start=1 end=1 -->",
    "### a.lua:1",
    "> local x = 1",
  }, "\n")
  local c = format.decode(text)[1]
  MiniTest.expect.equality(c.snippet, "local x = 1")
  MiniTest.expect.equality(c.body, "")
end

return T
