local T = MiniTest.new_set()

T["package loads"] = function()
  local ok = pcall(require, "agent-review")
  MiniTest.expect.equality(ok, true)
end

return T
