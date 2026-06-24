local M = {}

local function trim(s)
  return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function first_line(s)
  return (s:gsub("\n.*$", ""))
end

---@param lines string[] current buffer lines (1-based)
---@param comment table { start_line, snippet }
---@return table { status: "exact"|"moved"|"orphaned", line?: integer }
function M.resolve(lines, comment)
  -- a nil or empty snippet cannot be anchored
  local target = trim(first_line(comment.snippet or ""))
  if target == "" then
    return { status = "orphaned" }
  end
  local start = comment.start_line

  if start and lines[start] and trim(lines[start]) == target then
    return { status = "exact", line = start }
  end

  local best, best_dist
  for i, line in ipairs(lines) do
    if trim(line) == target then
      local dist = math.abs(i - (start or i))
      if not best_dist or dist < best_dist then
        best, best_dist = i, dist
      end
    end
  end
  if best then
    return { status = "moved", line = best }
  end
  return { status = "orphaned" }
end

return M
