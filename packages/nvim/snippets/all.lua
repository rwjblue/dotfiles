-- see https://github.com/L3MON4D3/LuaSnip/blob/v2.3.0/Examples/snippets.lua#L194

local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local f = ls.function_node
local d = ls.dynamic_node
local sn = ls.snippet_node

return {
  s({
    trig = "@today",
    name = "Current date",
    dscr = "Insert current date in YYYY-MM-DD format",
  }, {
    t(""),
    f(function()
      return os.date("%Y-%m-%d")
    end)
  }),

  s({
    trig = "@now",
    name = "Current datetime",
    dscr = "Insert current date and time in YYYY-MM-DD HH:MM:SS format",
  }, {
    t(""),
    f(function()
      return os.date("%Y-%m-%d %H:%M:%S")
    end)
  })
}
