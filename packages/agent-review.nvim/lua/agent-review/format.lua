local M = {}

-- A comment block begins with this marker, anchored at the start of a line.
-- `file` is captured non-greedily up to " start=", so paths may contain spaces.
local MARKER = "^<!%-%- agent%-review:v1 comment id=(%d+) file=(.-) start=(%d+) end=(%d+) %-%->"
-- Prefix that marks the start of the next comment block (used to terminate a body).
local MARKER_PREFIX = "^<!%-%- agent%-review:v1 comment "

---@param text string
---@return table[] comments
function M.decode(text)
  local lines = vim.split(text or "", "\n", { plain = true })
  local comments = {}
  local i = 1
  while i <= #lines do
    local id, file, s, e = lines[i]:match(MARKER)
    if id then
      local comment = {
        id = tonumber(id),
        file = file,
        start_line = tonumber(s),
        end_line = tonumber(e),
      }
      i = i + 1
      if lines[i] and lines[i]:match("^###%s") then
        i = i + 1
      end
      local snippet = {}
      while lines[i] and lines[i]:match("^> ") do
        table.insert(snippet, (lines[i]:gsub("^> ", "")))
        i = i + 1
      end
      comment.snippet = table.concat(snippet, "\n")
      if lines[i] == "" then i = i + 1 end
      local body = {}
      while lines[i] ~= nil and not lines[i]:match(MARKER_PREFIX) do
        table.insert(body, lines[i])
        i = i + 1
      end
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
    table.insert(out, c.body or "")
    table.insert(out, "")
  end
  return table.concat(out, "\n")
end

return M
