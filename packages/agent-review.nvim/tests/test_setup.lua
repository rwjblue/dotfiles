local T = MiniTest.new_set()

T["setup registers user commands"] = function()
  require("agent-review").setup({})
  MiniTest.expect.equality(vim.fn.exists(":AgentReviewAdd"), 2)
  MiniTest.expect.equality(vim.fn.exists(":AgentReviewList"), 2)
  MiniTest.expect.equality(vim.fn.exists(":AgentReviewClear"), 2)
  MiniTest.expect.equality(vim.fn.exists(":AgentReviewEdit"), 2)
  MiniTest.expect.equality(vim.fn.exists(":AgentReviewDelete"), 2)
  MiniTest.expect.equality(vim.fn.exists(":AgentReviewReload"), 2)
end

T["setup merges custom keymap_prefix"] = function()
  local ar = require("agent-review")
  ar.setup({ keymap_prefix = "<leader>x" })
  MiniTest.expect.equality(ar.config.keymap_prefix, "<leader>x")
end

return T
