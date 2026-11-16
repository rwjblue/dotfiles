local ok, err = xpcall(function()
  vim.opt.rtp:prepend(vim.fn.getcwd())
  vim.opt.rtp:prepend(assert(vim.env.AGENT_REVIEW_TEST_MINI_PATH, "Run mise run agent-review:test"))
  local mini_test = require("mini.test")
  mini_test.setup()
  mini_test.run()
end, debug.traceback)

if not ok then
  vim.api.nvim_err_writeln(err)
  vim.cmd("cquit")
end
