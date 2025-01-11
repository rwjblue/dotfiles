local M = {}

---@param config Window
---@return Window
function M.jujutsu_project(config)
  local result = {}
  -- Copy all existing properties
  for k, v in pairs(config) do
    result[k] = v
  end

  -- Handle command property specially
  if not config.command then
    result.command = 'export GIT_DIR="$PWD.jj/repo/store/git"'
  else
    local commands = {
      'export GIT_DIR="$PWD.jj/repo/store/git"',
    }

    if type(config.command) == "string" then
      table.insert(commands, config.command)
    else
      local commands_list = config.command
      -- SAFETY: this is required because apparently the type checking via `if
      -- type(...) == "string"` doesn't narrow in the LSP
      ---@cast commands_list string[]
      for _, cmd in ipairs(commands_list) do
        table.insert(commands, cmd)
      end
    end

    result.command = commands
  end

  return result
end

return M
