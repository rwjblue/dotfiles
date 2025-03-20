-- see https://github.com/L3MON4D3/LuaSnip/blob/v2.3.0/Examples/snippets.lua#L194

local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local f = ls.function_node
local d = ls.dynamic_node
local sn = ls.snippet_node

local function is_neovim_config_repo()
  local cwd = vim.fn.getcwd()
  local target_path = vim.fn.expand("$HOME/src/github/rwjblue/dotvim")

  return cwd == target_path
end

return {
  s({
    trig = "update-plugins",
    show_condition = is_neovim_config_repo,
  }, {
    t("chore(plugins): Update lockfile "),
    f(function()
      return os.date("%Y-%m-%d %H:%M:%S")
    end),
  }, { condition = is_neovim_config_repo }),
}
