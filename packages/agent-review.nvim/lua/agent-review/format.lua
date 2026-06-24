local M = {}

local MARKER = "<!%-%- agent%-review:v1 comment (.-) %-%->"

local function parse_attrs(s)
  local attrs = {}
  for key, value in s:gmatch("(%w+)=(%S+)") do
    attrs[key] = value
  end
  return attrs
end

---@param text string
---@return table[] comments
function M.decode(text)
  local lines = vim.split(text or "", "\n", { plain = true })
  local comments = {}
  local i = 1
  while i <= #lines do
    local attr_str = lines[i]:match(MARKER)
    if attr_str then
      local attrs = parse_attrs(attr_str)
      local comment = {
        id = tonumber(attrs.id),
        file = attrs.file,
        start_line = tonumber(attrs.start),
        end_line = tonumber(attrs["end"]),
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
      while lines[i] ~= nil and not lines[i]:match(MARKER) do
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
