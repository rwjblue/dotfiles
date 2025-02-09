-- see https://github.com/L3MON4D3/LuaSnip/blob/v2.3.0/Examples/snippets.lua#L194

local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local f = ls.function_node
local d = ls.dynamic_node
local sn = ls.snippet_node

local DEBUG = false

local function log(...)
  if DEBUG then
    local args = { ... }
    local str_args = {}
    for i, arg in ipairs(args) do
      str_args[i] = type(arg) == "table" and vim.inspect(arg) or tostring(arg)
    end
    vim.notify(table.concat(str_args, " "), vim.log.levels.DEBUG)
  end
end

local function get_node_version(filter_fn)
  log("Fetching Node.js version")
  local handle = io.popen('curl -s https://nodejs.org/dist/index.json')
  if not handle then
    log("Failed to open curl process for Node.js")
    return "ERROR"
  end

  local result = handle:read("*a")
  if not result then
    log("Failed to read curl response for Node.js")
    handle:close()
    return "ERROR"
  end
  handle:close()

  local success, decoded = pcall(vim.json.decode, result)
  if not success then
    log("Failed to decode Node.js JSON:", decoded)
    return "ERROR"
  end

  local release = filter_fn(decoded)
  if release then
    local version = release.version:gsub("v", ""):gsub("%s+", "")
    log("Found version:", version)
    return version
  end

  log("No version found")
  return "ERROR"
end

local function get_latest_node()
  return get_node_version(function(releases) return releases[1] end)
end

local function get_latest_node_lts()
  return get_node_version(function(releases)
    for _, release in ipairs(releases) do
      if release.lts then return release end
    end
  end)
end

local function get_latest_npm()
  log("Fetching latest npm version")
  local handle = io.popen('curl -s https://registry.npmjs.org/npm/latest')
  if not handle then
    log("Failed to open curl process for npm")
    return "ERROR"
  end

  local result = handle:read("*a")
  if not result then
    log("Failed to read curl response for npm")
    handle:close()
    return "ERROR"
  end
  handle:close()

  --log("Raw npm response:", result)
  local success, decoded = pcall(vim.json.decode, result)
  if not success then
    log("Failed to decode npm JSON:", decoded)
    return "ERROR"
  end

  local version = decoded.version:gsub("%s+", "")
  log("Found npm version:", version)
  return version
end

local function check_quotes()
  -- Get the current line and cursor position
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2]

  -- Check characters before and after cursor
  local before = line:sub(col, col)
  local after = line:sub(col + 1, col + 1)

  return {
    opening = before ~= '"',
    closing = after ~= '"'
  }
end

local function quote_wrapped_text(text)
  return f(function()
    local quotes = check_quotes()
    local prefix = quotes.opening and '"' or ''
    local suffix = quotes.closing and '"' or ''
    return prefix .. text .. suffix
  end)
end

return {
  s("package.json:volta-lts", {
    quote_wrapped_text('volta'),
    t(': {'),
    t({ '', '  "node": "' }),
    f(get_latest_node_lts),
    t({ '",', '  "npm": "' }),
    f(get_latest_npm),
    t({ '"', '}' }),
  }),
  s("package.json:volta-latest", {
    quote_wrapped_text('volta'),
    t(': {'),
    t({ '', '  "node": "' }),
    f(get_latest_node),
    t({ '",', '  "npm": "' }),
    f(get_latest_npm),
    t({ '"', '}' }),
  }),
}
