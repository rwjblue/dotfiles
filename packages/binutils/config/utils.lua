local M = {}

---@param config Window
---@return Window
function M.jj_project(config)
  local result = {}
  -- Copy all existing properties
  for k, v in pairs(config) do
    result[k] = v
  end

  local commands = {}

  local path = assert(config.path, "path is required for jj_project")
  if path:sub(1, 1) == "~" then
    local home = assert(os.getenv("HOME"), "HOME environment variable not set")
    path = home .. path:sub(2)
  end
  local git_path = path .. "/.git"
  local git_dir_exists = io.open(git_path, "r") ~= nil

  -- When `jj` is in `--colocate` mode there is still a top level `.git`
  -- directory so we only need to add GIT_DIR if .git doesn't exist (which
  -- means we are **not** colocated)
  if not git_dir_exists then
    table.insert(commands, 'export GIT_DIR="$PWD/.jj/repo/store/git"')
  end

  -- Add JJ specific STARSHIP_CONFIG
  table.insert(commands, 'export STARSHIP_CONFIG="$HOME/.config/starship/jj.toml"')

  -- Add existing commands
  if config.command then
    if type(config.command) == "string" then
      table.insert(commands, config.command)
    else
      local commands_list = config.command
      ---@cast commands_list string[]
      for _, cmd in ipairs(commands_list) do
        table.insert(commands, cmd)
      end
    end
  end

  result.command = #commands > 1 and commands or commands[1]

  return result
end

---Deep extend tables: merge objects and concatenate arrays
---@param base table
---@param override table
---@return table
local function deep_extend(base, override)
  if type(override) ~= "table" or type(base) ~= "table" then
    return override
  end

  local is_array = #base > 0 or #override > 0
  if is_array then
    local result = {}
    -- copy base array
    for i = 1, #base do
      result[i] = base[i]
    end

    -- append override array
    for i = 1, #override do
      result[#result + 1] = override[i]
    end
    return result
  end

  local result = {}
  for k, v in pairs(base) do
    result[k] = v
  end

  for k, v in pairs(override) do
    if type(v) == "table" and type(result[k]) == "table" then
      result[k] = deep_extend(result[k], v)
    else
      result[k] = v
    end
  end

  return result
end

---Extend the base configuration with additional settings
---
---This function loads the base configuration from require("config") and extends it
---with the provided override configuration. For objects, it performs a deep merge
---of properties. For arrays, it concatenates the override array to the end of the
---base array.
---
---Example:
---```lua
---  -- Base config has: { tmux = { sessions = { {name = "dev"} } } }
---  extend_config({
---    tmux = {
---      sessions = { {name = "test"} }
---    }
---  })
---  -- Results in: { tmux = { sessions = { {name = "dev"}, {name = "test"} } } }
---```
---
---Note: There is currently no way to remove or filter out items from the base
---configuration. All operations are additive.
---
---@param override_config Config Configuration to extend the base with
---@return Config Extended configuration
function M.extend_config(override_config)
  local base_config = require("config")

  return deep_extend(base_config, override_config)
end

return M
