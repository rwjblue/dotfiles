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
    { status = "exact", line = 4 }) -- exact wins: line 4 matches exactly
  MiniTest.expect.equality(
    anchor.resolve(lines, comment(3, "dup")),
    { status = "moved", line = 4 }) -- nearest to 3 is 4
end

T["orphaned when snippet not found in lines"] = function()
  MiniTest.expect.equality(
    anchor.resolve({ "a", "b" }, comment(1, "missing")),
    { status = "orphaned" })
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

T["moved: equal-distance ties resolve to lower index"] = function()
  local lines = { "dup", "x", "dup" } -- dup at 1 and 3, both distance 1 from start 2
  MiniTest.expect.equality(
    anchor.resolve(lines, comment(2, "dup")),
    { status = "moved", line = 1 })
end

return T
