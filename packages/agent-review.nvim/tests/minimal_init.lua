-- Self-bootstrapping mini.nvim harness so the package tests run standalone.
local root = vim.fn.fnamemodify(vim.fn.getcwd(), ":p")
local mini_path = vim.fs.joinpath(root, "deps", "mini.nvim")
if vim.fn.isdirectory(mini_path) == 0 then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/echasnovski/mini.nvim", mini_path,
  })
  if vim.v.shell_error ~= 0 then
    error("agent-review tests: failed to clone mini.nvim into " .. mini_path)
  end
end
vim.opt.rtp:prepend(root)       -- the plugin under test (require("agent-review.*"))
vim.opt.rtp:prepend(mini_path)  -- provides mini.test
require("mini.test").setup()
