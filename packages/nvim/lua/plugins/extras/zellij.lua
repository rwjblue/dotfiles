-- Zellij Session Switcher
-- Provides Neovim integration for switching between Zellij sessions using snacks picker

---@class ZellijSession
---@field name string The name of the session
---@field created_at string|nil When the session was created (e.g., "2days 14h 54m 5s")
---@field is_current boolean Whether this is the currently active session
---@field is_exited boolean Whether this session has exited (needs resurrection)

-- Module setup - this will be available when required
local zellij = {}

--- Check if Zellij is installed and available
---@return boolean
function zellij.is_zellij_available()
  return vim.fn.executable("zellij") == 1
end

--- Check if we're currently running inside a Zellij session
---@return boolean
function zellij.is_inside_zellij()
  return vim.env.ZELLIJ ~= nil
end

--- Get list of all active Zellij sessions
---@return ZellijSession[] Array of session objects
function zellij.get_zellij_sessions()
  if not zellij.is_zellij_available() then
    vim.notify("Zellij is not installed", vim.log.levels.ERROR)
    return {}
  end

  local result = {}
  -- Use --no-formatting to get clean output without ANSI color codes
  local output = vim.fn.systemlist("zellij list-sessions --no-formatting")

  -- Check if the command failed
  if vim.v.shell_error ~= 0 then
    -- If no sessions are running, zellij returns an error
    -- This is normal, so we just return an empty list
    return {}
  end

  -- Parse the output
  -- Format: "session_name [Created Xdays Yh Zm Ws ago] (current)"
  --     or: "session_name [Created Xdays Yh Zm Ws ago] (EXITED - attach to resurrect)"
  for _, line in ipairs(output) do
    if line and line ~= "" then
      -- Extract session name (first word)
      local session_name = line:match("^(%S+)")
      if session_name then
        -- Check if this is the current session
        local is_current = line:match("%(current%)") ~= nil

        -- Check if this session has exited
        local is_exited = line:match("%(EXITED") ~= nil

        -- Try to extract creation time if present
        local created_at = line:match("%[Created ([^%]]+)%]")

        table.insert(result, {
          name = session_name,
          created_at = created_at,
          is_current = is_current,
          is_exited = is_exited,
        })
      end
    end
  end

  return result
end

--- Generate preview text for a Zellij session
---@param session_name string The name of the session
---@param is_current boolean Whether this is the current session
---@param is_exited boolean Whether this session has exited
---@return string Preview text
function zellij.get_session_preview(session_name, is_current, is_exited)
  local lines = {}

  table.insert(lines, "# Session: " .. session_name)
  table.insert(lines, "")

  if is_exited then
    table.insert(lines, "**Status:** ⚠️  EXITED - Attach to resurrect")
    table.insert(lines, "")
    table.insert(lines, "_This session has exited. Attaching will resurrect it with the previous layout shown below._")
  elseif is_current then
    table.insert(lines, "**Status:** Currently active session")
  else
    table.insert(lines, "**Status:** Background session")
  end
  table.insert(lines, "")

  -- Get the layout for this specific session
  -- Read from cached session-layout.kdl file that zellij maintains
  -- Note: If zellij changes this in future versions, we could fall back to: zellij action dump-layout
  
  -- Get cache directory from zellij setup
  local setup_output = vim.fn.systemlist("zellij setup --check 2>&1")
  local base_cache_dir = ""
  
  for _, line in ipairs(setup_output) do
    local cache_match = line:match("%[CACHE DIR%]: (.+)")
    if cache_match then
      base_cache_dir = cache_match
      break
    end
  end
  
  -- Find the versioned cache directory (e.g., 0.43.1)
  local cache_dir = ""
  if base_cache_dir ~= "" then
    local version_dirs = vim.fn.systemlist(string.format("ls -d %s/*/session_info 2>/dev/null | head -1 | sed 's|/session_info||'", vim.fn.shellescape(base_cache_dir)))
    if #version_dirs > 0 then
      cache_dir = version_dirs[1]
    end
  end
  
  -- Fallback if cache dir detection fails
  if cache_dir == "" then
    local version_output = vim.fn.systemlist("zellij --version 2>/dev/null")
    local version = version_output[1] and version_output[1]:match("zellij (%S+)") or "0.43.1"
    base_cache_dir = vim.fn.has("mac") == 1
      and vim.fn.expand("~/Library/Caches/org.Zellij-Contributors.Zellij")
      or vim.fn.expand("~/.cache/zellij")
    cache_dir = string.format("%s/%s", base_cache_dir, version)
  end
  
  local layout_file = string.format("%s/session_info/%s/session-layout.kdl", cache_dir, session_name)
  local layout_output = {}
  local file = io.open(layout_file, "r")
  if file then
    for line in file:lines() do
      table.insert(layout_output, line)
    end
    file:close()
  end
  
  if #layout_output > 0 then
    table.insert(lines, "## Tabs & Panes")
    table.insert(lines, "")

    -- Simple parsing: find tabs and count their direct child panes
    local tabs = {}
    local cwd = ""
    local in_real_tab = false
    local current_tab_start = 0

    -- Helper function to check if a pane is a plugin container
    -- Plugin panes have a child line with "plugin location="
    local function is_plugin_pane(line_index)
      if line_index + 1 <= #layout_output then
        local next_line = layout_output[line_index + 1]
        -- Check if the next line is indented more and contains plugin location
        if next_line:match("^            plugin location=") then
          return true
        end
      end
      return false
    end

    for i, line in ipairs(layout_output) do
      -- Get the first CWD we find
      if cwd == "" then
        local cwd_match = line:match('cwd "([^"]+)"')
        if cwd_match then
          cwd = cwd_match
        end
      end

      -- Skip everything after we hit swap layouts or templates
      if line:match("swap_tiled_layout") or line:match("swap_floating_layout") or line:match("new_tab_template") then
        break
      end

      -- Look for actual tabs (with names)
      local tab_name = line:match('tab name="([^"]+)"')
      if tab_name then
        -- Count panes from previous tab before starting new one
        if in_real_tab and current_tab_start > 0 and #tabs > 0 then
          local pane_count = 0
          -- Look at lines between tab start and current line
          for j = current_tab_start, i - 1 do
            local pane_line = layout_output[j]
            -- Match lines that start with exactly 8 spaces followed by "pane"
            -- Exclude plugin panes (those with a plugin location child)
            if pane_line:match("^        pane") and not is_plugin_pane(j) then
              pane_count = pane_count + 1
            end
          end
          tabs[#tabs].pane_count = pane_count
        end

        -- Start tracking new tab
        in_real_tab = true
        current_tab_start = i + 1
        table.insert(tabs, {
          name = tab_name,
          pane_count = 0,
          is_focused = line:match("focus=true") ~= nil,
          line_start = i,
        })
      end
    end

    -- Count panes for the last tab
    if in_real_tab and current_tab_start > 0 and #tabs > 0 then
      local pane_count = 0
      for j = current_tab_start, #layout_output do
        local pane_line = layout_output[j]
        if pane_line:match("swap_tiled_layout") or pane_line:match("swap_floating_layout") or pane_line:match("new_tab_template") then
          break
        end
        if pane_line:match("^        pane") and not is_plugin_pane(j) then
          pane_count = pane_count + 1
        end
      end
      tabs[#tabs].pane_count = pane_count
    end

    -- Display tabs with pane details
    if #tabs > 0 then
      for tab_idx, tab in ipairs(tabs) do
        local focus_indicator = tab.is_focused and " ←" or ""
        local pane_text = tab.pane_count == 1 and "1 pane" or string.format("%d panes", tab.pane_count)
        table.insert(lines, string.format("- **%s** (%s)%s", tab.name, pane_text, focus_indicator))

        -- Extract pane details for this tab
        if tab.pane_count > 0 then
          -- Calculate the range for this specific tab
          local tab_start = tab.line_start + 1  -- Start after the tab line itself
          local tab_end = tab_idx < #tabs and tabs[tab_idx + 1].line_start - 1 or #layout_output
          local pane_num = 0

          for j = tab_start, tab_end do
            if j > #layout_output then break end
            local pane_line = layout_output[j]

            if pane_line:match("swap_tiled_layout") or pane_line:match("swap_floating_layout") or pane_line:match("new_tab_template") then
              break
            end

            if pane_line:match("^        pane") and not is_plugin_pane(j) then
              pane_num = pane_num + 1

              -- Extract pane info
              local pane_cwd = pane_line:match('cwd "([^"]+)"')
              local pane_cmd = pane_line:match('command="([^"]+)"')
              local is_focused = pane_line:match("focus=true") ~= nil

              local pane_info = {}
              if pane_cmd then
                table.insert(pane_info, string.format("cmd: `%s`", pane_cmd))
              end
              if pane_cwd then
                table.insert(pane_info, string.format("dir: `%s`", pane_cwd))
              end

              if #pane_info > 0 then
                local focus_mark = is_focused and " [focused]" or ""
                table.insert(lines, string.format("  - Pane %d: %s%s", pane_num, table.concat(pane_info, ", "), focus_mark))
              end
            end
          end
        end
      end
    else
      table.insert(lines, "_No tabs found_")
    end

    if cwd and cwd ~= "" then
      table.insert(lines, "")
      table.insert(lines, "**Working Directory:** `" .. cwd .. "`")
    end
  else
    table.insert(lines, "_Unable to retrieve session layout_")
  end

  return table.concat(lines, "\n")
end

--- Switch to a specific Zellij session
---@param session_name string The name of the session to switch to
function zellij.switch_to_session(session_name)
  if not zellij.is_zellij_available() then
    vim.notify("Zellij is not installed", vim.log.levels.ERROR)
    return
  end

  if not zellij.is_inside_zellij() then
    vim.notify("Not running inside a Zellij session", vim.log.levels.WARN)
    return
  end

  -- Use zellij-switch plugin to switch sessions
  -- The payload after -- is passed to the plugin and parsed as shell words
  local result = vim.fn.system({
    "zellij",
    "pipe",
    "--plugin",
    "https://github.com/mostafaqanbaryan/zellij-switch/releases/download/0.2.1/zellij-switch.wasm",
    "--",
    string.format("--session %s", session_name),
  })

  if vim.v.shell_error == 0 then
    vim.notify(string.format("Switched to session: %s", session_name), vim.log.levels.INFO)
  else
    vim.notify(string.format("Failed to switch to session: %s", session_name), vim.log.levels.ERROR)
  end
end

--- Open snacks picker to select and switch to a Zellij session
function zellij.session_picker()
  if not zellij.is_zellij_available() then
    vim.notify("Zellij is not installed. Please install Zellij first.", vim.log.levels.ERROR)
    return
  end

  if not zellij.is_inside_zellij() then
    vim.notify("Not running inside a Zellij session. Start Zellij first.", vim.log.levels.WARN)
    return
  end

  local sessions = zellij.get_zellij_sessions()

  if #sessions == 0 then
    vim.notify("No Zellij sessions found", vim.log.levels.INFO)
    return
  end

  -- Open snacks picker with a custom finder
  require("snacks").picker.pick({
    finder = function()
      ---@type snacks.picker.finder.Item[]
      local items = {}

      -- Convert sessions to picker items
      for idx, session in ipairs(sessions) do
        local display_text = session.name

        -- Add creation time if available
        if session.created_at then
          display_text = display_text .. " (" .. session.created_at .. " ago)"
        end

        -- Mark session status with visual indicators
        if session.is_exited then
          display_text = "⚠ " .. display_text .. " [EXITED]"
        elseif session.is_current then
          display_text = "● " .. display_text .. " [current]"
        else
          display_text = "  " .. display_text
        end

        items[#items + 1] = {
          text = display_text,
          session_name = session.name,
          is_current = session.is_current,
          is_exited = session.is_exited,
          idx = idx,
          -- Add preview data
          preview = {
            text = zellij.get_session_preview(session.name, session.is_current, session.is_exited),
            ft = "markdown",
          },
        }
      end

      return items
    end,
    title = "Zellij Sessions",
    show_empty = true,
    preview = "preview", -- Use the preview field from items
    -- Custom format function to display just the text
    format = function(item)
      -- Use a consistent highlight - snacks will handle the selection highlighting
      return { { item.text } }
    end,
    -- Define actions for the picker
    actions = {
      confirm = function(picker, item)
        if item and item.session_name then
          picker:close()
          -- Small delay to ensure picker is fully closed before switching
          vim.defer_fn(function()
            zellij.switch_to_session(item.session_name)
          end, 50)
        end
      end,
    },
  })
end

-- Store the module in package.loaded so it's available immediately
package.loaded["plugins.extras.zellij"] = zellij

-- Return LazyVim plugin spec
return {
  {
    "folke/which-key.nvim",
    optional = true,
    opts = {
      spec = {
        { "<leader>z", group = "zellij" },
      },
    },
  },

  {
    "folke/snacks.nvim",
    optional = true,
    init = function()
      -- Create user command for easy access
      vim.api.nvim_create_user_command("ZellijSwitch", function()
        require("plugins.extras.zellij").session_picker()
      end, {
        desc = "Switch Zellij session",
      })
    end,
    keys = {
      {
        "<leader>zs",
        function()
          require("plugins.extras.zellij").session_picker()
        end,
        desc = "Zellij: Switch session",
      },
    },
  },
}
