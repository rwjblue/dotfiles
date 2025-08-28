--- Tab name management module
--- Provides functionality to set custom names for Neovim tabs
local M = {}

--- Table to store custom tab names
--- @type table<number, string>
M.tab_names = {
  [1] = "Default",
}

--- Formats a tab name with its number and custom name if available
--- @param tabnr number The tab handle
--- @return string formatted_name The formatted tab name
function M.format_tab_name(tabnr)
  local tab_num = vim.api.nvim_tabpage_get_number(tabnr)

  local custom_name = M.tab_names[tabnr]

  if custom_name then
    return tab_num .. " - " .. custom_name
  else
    return tostring(tab_num)
  end
end

--- Creates a new tab with a custom name
--- @param name string The name to assign to the new tab
--- @return number tabnr The handle of the newly created tab
function M.new_tab_with_name(name)
  vim.cmd("tabnew")
  local tabnr = vim.api.nvim_get_current_tabpage()
  M.tab_names[tabnr] = name

  return tabnr
end

--- Sets a name for the current tab
--- @param name string The name to assign to the current tab
--- @return number tabnr The handle of the current tab
function M.set_current_tab_name(name)
  local tabnr = vim.api.nvim_get_current_tabpage()
  M.tab_names[tabnr] = name
  return tabnr
end

--- Sets a name for a specific tab
--- @param tabnr number The tab handle
--- @param name string The name to assign to the tab
function M.set_tab_name(tabnr, name)
  M.tab_names[tabnr] = name
end

--- Gets the custom name of a tab
--- @param tabnr number The tab handle
--- @return string|nil name The custom name of the tab, or nil if no custom name exists
function M.get_tab_name(tabnr)
  return M.tab_names[tabnr]
end

--- Removes the custom name from the current tab
--- @return number tabnr The handle of the current tab
function M.remove_current_tab_name()
  local tabnr = vim.api.nvim_get_current_tabpage()
  M.tab_names[tabnr] = nil
  return tabnr
end

--- Closes the current tab and cleans up its name
function M.close_tab()
  local tabnr = vim.api.nvim_get_current_tabpage()
  M.tab_names[tabnr] = nil
  vim.cmd("tabclose")
end

--- Creates a new tab and prompts for a name
function M.new_tab_prompt()
  vim.ui.input({ prompt = "Tab name: " }, function(name)
    if name and name ~= "" then
      M.new_tab_with_name(name)
    else
      vim.cmd("tabnew")
    end
  end)
end

--- Prompts to rename the current tab
function M.rename_tab_prompt()
  local current_name = M.get_tab_name(vim.api.nvim_get_current_tabpage()) or ""
  vim.ui.input({ prompt = "Tab name: ", default = current_name }, function(name)
    if name and name ~= "" then
      M.set_current_tab_name(name)
    elseif name == "" then
      M.remove_current_tab_name()
    end
  end)
end

--- Creates a new tab with claude terminal
function M.new_claude_tab()
  M.new_tab_with_name("claude")
  vim.cmd("term claude")
end

--- Sets up Vim commands for tab management
function M.setup_commands()
  vim.api.nvim_create_user_command("TabNew", function(opts)
    if opts.args and opts.args ~= "" then
      M.new_tab_with_name(opts.args)
    elseif opts.bang then
      vim.cmd("tabnew")
    else
      M.new_tab_prompt()
    end
  end, { nargs = "?" })

  vim.api.nvim_create_user_command("TabRename", function(opts)
    if opts.args and opts.args ~= "" then
      M.set_current_tab_name(opts.args)
    else
      M.rename_tab_prompt()
    end
  end, { nargs = "?" })

  vim.api.nvim_create_user_command("TabClose", function()
    M.close_tab()
  end, {})

  vim.api.nvim_create_user_command("TabClearName", function()
    M.remove_current_tab_name()
  end, {})

  vim.api.nvim_create_user_command("TabClaude", function()
    M.new_claude_tab()
  end, {})
end

return M
