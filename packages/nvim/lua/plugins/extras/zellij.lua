-- Zellij Session Switcher
-- Provides Neovim integration for switching between Zellij sessions using snacks picker

---@class ZellijSession
---@field name string The name of the session
---@field created_at string|nil When the session was created (e.g., "2days 14h 54m 5s")
---@field is_current boolean Whether this is the currently active session
---@field is_exited boolean Whether this session has exited (needs resurrection)

---@class ZellijSessionData
---@field name string Session name
---@field is_current boolean Whether this is the current session
---@field is_exited boolean Whether this session has exited
---@field tabs ZellijTab[] Array of tabs with pane details
---@field cwd string|nil Working directory

---@class ZellijTabItem
---@field session_name string Name of the session containing this tab
---@field tab_name string Name of the tab
---@field is_current_session boolean Whether this tab is in the current session
---@field is_focused_tab boolean Whether this tab is currently focused
---@field pane_count number Number of panes in the tab
---@field panes ZellijPaneInfo[]|nil Pane details for preview

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

--- Validate that Zellij is available and we're inside a session
---@return boolean is_valid True if environment is valid for Zellij operations
local function validate_zellij_environment()
  if not zellij.is_zellij_available() then
    vim.notify("Zellij is not installed. Install via: brew install zellij (macOS) or cargo install zellij", vim.log.levels.ERROR)
    return false
  end

  if not zellij.is_inside_zellij() then
    vim.notify("Not running inside a Zellij session. Start Zellij first with: zellij", vim.log.levels.WARN)
    return false
  end

  return true
end

--- Get list of all active Zellij sessions
---@return ZellijSession[] Array of session objects
function zellij.get_zellij_sessions()
  if not zellij.is_zellij_available() then
    vim.notify("Zellij is not installed. Install via: brew install zellij (macOS) or cargo install zellij", vim.log.levels.ERROR)
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

---@class ZellijTab
---@field name string Tab name
---@field pane_count number Number of panes in the tab
---@field is_focused boolean Whether this tab is focused
---@field line_start number Starting line in layout output
---@field panes ZellijPaneInfo[]|nil Optional array of pane details

---@class ZellijPaneInfo
---@field cmd string|nil Command running in the pane
---@field cwd string|nil Working directory of the pane
---@field is_focused boolean Whether this pane is focused

-- Cache for the zellij cache directory (only needs to be computed once)
local cached_cache_directory = nil

--- Get base cache directory from zellij setup output
---@return string|nil base_cache_dir The base cache directory or nil if not found
local function get_cache_from_setup()
  local setup_output = vim.fn.systemlist("zellij setup --check 2>&1")
  for _, line in ipairs(setup_output) do
    local cache_match = line:match("%[CACHE DIR%]: (.+)")
    if cache_match then
      return cache_match
    end
  end
  return nil
end

--- Find the versioned cache directory within base cache
---@param base_cache_dir string The base cache directory
---@return string|nil version_dir The versioned directory path or nil if not found
local function find_version_dir(base_cache_dir)
  if not base_cache_dir or base_cache_dir == "" then
    return nil
  end

  local version_dirs = vim.fn.systemlist(
    string.format("ls -d %s/*/session_info 2>/dev/null | head -1 | sed 's|/session_info||'",
    vim.fn.shellescape(base_cache_dir))
  )

  if #version_dirs > 0 then
    return version_dirs[1]
  end

  return nil
end

--- Construct fallback cache directory path
---@return string cache_dir Fallback cache directory path
local function get_fallback_cache_dir()
  local version_output = vim.fn.systemlist("zellij --version 2>/dev/null")
  local version = version_output[1] and version_output[1]:match("zellij (%S+)") or "0.43.1"

  local base_cache_dir = vim.fn.has("mac") == 1
    and vim.fn.expand("~/Library/Caches/org.Zellij-Contributors.Zellij")
    or vim.fn.expand("~/.cache/zellij")

  return string.format("%s/%s", base_cache_dir, version)
end

--- Get the zellij cache directory
---@return string cache_dir Path to the versioned cache directory
local function get_cache_directory()
  -- Return cached value if available
  if cached_cache_directory then
    return cached_cache_directory
  end

  -- Compute and cache the directory
  local base_cache_dir = get_cache_from_setup()

  if base_cache_dir then
    local cache_dir = find_version_dir(base_cache_dir)
    if cache_dir and cache_dir ~= "" then
      cached_cache_directory = cache_dir
      return cache_dir
    end
  end

  cached_cache_directory = get_fallback_cache_dir()
  return cached_cache_directory
end

--- Get the current session layout using zellij action dump-layout (real-time)
---@return string[] layout_lines Array of lines from the dumped layout
local function dump_current_layout()
  local output = vim.fn.systemlist("zellij action dump-layout")

  -- Check if the command failed
  if vim.v.shell_error ~= 0 then
    vim.notify("Failed to dump Zellij layout", vim.log.levels.WARN)
    return {}
  end

  return output
end

--- Read the session layout file from cache (may have stale focus state)
---@param session_name string Name of the session
---@return string[] layout_lines Array of lines from the layout file
local function read_session_layout(session_name)
  local cache_dir = get_cache_directory()
  local layout_file = string.format("%s/session_info/%s/session-layout.kdl", cache_dir, session_name)
  local layout_output = {}

  local file, err = io.open(layout_file, "r")
  if not file then
    vim.notify(
      string.format("Cannot read layout for session '%s': %s", session_name, err or "unknown error"),
      vim.log.levels.WARN
    )
    return layout_output
  end

  for line in file:lines() do
    table.insert(layout_output, line)
  end
  file:close()

  return layout_output
end

--- Check if a pane line represents a plugin pane
---@param layout_lines string[] All layout lines
---@param line_index number Index of the pane line to check
---@return boolean is_plugin True if this is a plugin pane
local function is_plugin_pane(layout_lines, line_index)
  if line_index + 1 <= #layout_lines then
    local next_line = layout_lines[line_index + 1]
    if next_line:match("^            plugin location=") then
      return true
    end
  end
  return false
end

--- Check if a line marks the end of the tab section
---@param line string The line to check
---@return boolean is_end True if this line marks the end
local function is_end_of_tabs(line)
  return line:match("swap_tiled_layout")
    or line:match("swap_floating_layout")
    or line:match("new_tab_template")
end

--- Count non-plugin panes in a line range
---@param layout_lines string[] All layout lines
---@param start_line number Starting line index
---@param end_line number Ending line index
---@return number pane_count Number of non-plugin panes
local function count_panes_in_range(layout_lines, start_line, end_line)
  local pane_count = 0
  for j = start_line, end_line do
    if j > #layout_lines then break end
    local pane_line = layout_lines[j]
    if is_end_of_tabs(pane_line) then
      break
    end
    if pane_line:match("^        pane") and not is_plugin_pane(layout_lines, j) then
      pane_count = pane_count + 1
    end
  end
  return pane_count
end

--- Extract tab metadata from layout lines (without pane counting)
---@param layout_lines string[] Layout file lines
---@return ZellijTab[] tabs Array of parsed tabs (pane_count will be 0)
---@return string cwd Working directory
local function extract_tabs(layout_lines)
  local tabs = {}
  local cwd = ""

  for i, line in ipairs(layout_lines) do
    -- Get the first CWD we find
    if cwd == "" then
      local cwd_match = line:match('cwd "([^"]+)"')
      if cwd_match then
        cwd = cwd_match
      end
    end

    -- Skip everything after we hit swap layouts or templates
    if is_end_of_tabs(line) then
      break
    end

    -- Look for actual tabs (with names)
    local tab_name = line:match('tab name="([^"]+)"')
    if tab_name then
      table.insert(tabs, {
        name = tab_name,
        pane_count = 0, -- Will be filled in later
        is_focused = line:match("focus=true") ~= nil,
        line_start = i,
      })
    end
  end

  return tabs, cwd
end

--- Parse tab information from layout lines
---@param layout_lines string[] Layout file lines
---@return ZellijTab[] tabs Array of parsed tabs
---@return string cwd Working directory
local function parse_tabs_from_layout(layout_lines)
  local tabs, cwd = extract_tabs(layout_lines)

  -- Count panes for each tab
  for i, tab in ipairs(tabs) do
    local start_line = tab.line_start + 1
    local end_line = i < #tabs and tabs[i + 1].line_start - 1 or #layout_lines
    tab.pane_count = count_panes_in_range(layout_lines, start_line, end_line)
  end

  return tabs, cwd
end

--- Extract pane details for a specific tab
---@param layout_lines string[] Layout file lines
---@param tabs ZellijTab[] All tabs
---@param tab_idx number Index of the current tab
---@return ZellijPaneInfo[] panes Array of pane information
local function extract_pane_details(layout_lines, tabs, tab_idx)
  local panes = {}
  local tab = tabs[tab_idx]
  local tab_start = tab.line_start + 1
  local tab_end = tab_idx < #tabs and tabs[tab_idx + 1].line_start - 1 or #layout_lines

  for j = tab_start, tab_end do
    if j > #layout_lines then break end
    local pane_line = layout_lines[j]

    if is_end_of_tabs(pane_line) then
      break
    end

    if pane_line:match("^        pane") and not is_plugin_pane(layout_lines, j) then
      local pane_cwd = pane_line:match('cwd "([^"]+)"')
      local pane_cmd = pane_line:match('command="([^"]+)"')
      local is_focused = pane_line:match("focus=true") ~= nil

      table.insert(panes, {
        cmd = pane_cmd,
        cwd = pane_cwd,
        is_focused = is_focused,
      })
    end
  end

  return panes
end

--- Generate preview header with session name and status
---@param session_name string The name of the session
---@param is_current boolean Whether this is the current session
---@param is_exited boolean Whether this session has exited
---@return string[] lines Header lines
local function generate_preview_header(session_name, is_current, is_exited)
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

  return lines
end

--- Get structured session data including tabs and panes
---@param session_name string The name of the session
---@param is_current boolean Whether this is the current session
---@param is_exited boolean Whether this session has exited
---@return ZellijSessionData Session data with tabs and panes
function zellij.get_session_data(session_name, is_current, is_exited)
  local layout_lines

  -- IMPORTANT: We use different data sources depending on whether this is the current session:
  --
  -- For CURRENT session:
  --   - Use `zellij action dump-layout` to get real-time, accurate state
  --   - This ensures tab focus indicators are correct (they reflect runtime state)
  --   - Critical for tab switching functionality where we need to know which tab is actually focused
  --
  -- For BACKGROUND/EXITED sessions:
  --   - Use cached layout files from ~/.cache/zellij/{version}/session_info/{session}/session-layout.kdl
  --   - Cached files preserve the layout from when the session was created/last saved
  --   - Focus indicators may be stale (show initial state, not current runtime state)
  --   - This is acceptable because we mainly need this for session resurrection
  --   - Resurrection restores the layout structure; runtime focus state isn't needed for exited sessions
  --
  -- This hybrid approach gives us:
  --   1. Accurate focus state for tab picker (always uses current session with dump-layout)
  --   2. Ability to resurrect exited sessions (uses cached layout files)
  --   3. Preview of background sessions without switching to them (uses cached layout files)
  if is_current then
    layout_lines = dump_current_layout()
  else
    layout_lines = read_session_layout(session_name)
  end

  local tabs, cwd = parse_tabs_from_layout(layout_lines)

  -- Enrich each tab with pane details
  for i, tab in ipairs(tabs) do
    tab.panes = extract_pane_details(layout_lines, tabs, i)
  end

  return {
    name = session_name,
    is_current = is_current,
    is_exited = is_exited,
    tabs = tabs,
    cwd = cwd,
  }
end

--- Get tabs from current session only
---@return ZellijTabItem[] Array of tab items from current session
function zellij.get_current_session_tabs()
  -- Get current session name from environment
  local session_name = vim.env.ZELLIJ_SESSION_NAME
  if not session_name then
    return {}
  end

  local session_data = zellij.get_session_data(session_name, true, false)
  local tabs = {}

  for _, tab in ipairs(session_data.tabs) do
    table.insert(tabs, {
      session_name = session_data.name,
      tab_name = tab.name,
      is_current_session = true,
      is_focused_tab = tab.is_focused,
      pane_count = tab.pane_count,
      panes = tab.panes,
    })
  end

  return tabs
end

--- Format session data into preview markdown text
---@param session_data ZellijSessionData The session data to format
---@return string Preview text in markdown format
local function format_session_preview(session_data)
  local lines = {}

  -- Add header
  local header_lines = generate_preview_header(session_data.name, session_data.is_current, session_data.is_exited)
  for _, line in ipairs(header_lines) do
    table.insert(lines, line)
  end

  -- Add tabs section
  if #session_data.tabs == 0 then
    table.insert(lines, "_Unable to retrieve session layout_")
  else
    table.insert(lines, "## Tabs & Panes")
    table.insert(lines, "")

    -- Format each tab with its panes
    for _, tab in ipairs(session_data.tabs) do
      local focus_indicator = tab.is_focused and " ←" or ""
      local pane_text = tab.pane_count == 1 and "1 pane" or string.format("%d panes", tab.pane_count)
      table.insert(lines, string.format("- **%s** (%s)%s", tab.name, pane_text, focus_indicator))

      -- Add pane details if available
      if tab.panes and #tab.panes > 0 then
        for pane_num, pane in ipairs(tab.panes) do
          local pane_info = {}
          if pane.cmd then
            table.insert(pane_info, string.format("cmd: `%s`", pane.cmd))
          end
          if pane.cwd then
            table.insert(pane_info, string.format("dir: `%s`", pane.cwd))
          end

          if #pane_info > 0 then
            local focus_mark = pane.is_focused and " [focused]" or ""
            table.insert(lines, string.format("  - Pane %d: %s%s", pane_num, table.concat(pane_info, ", "), focus_mark))
          end
        end
      end
    end

    if session_data.cwd and session_data.cwd ~= "" then
      table.insert(lines, "")
      table.insert(lines, "**Working Directory:** `" .. session_data.cwd .. "`")
    end
  end

  return table.concat(lines, "\n")
end

--- Generate preview text for a Zellij session
---@param session_name string The name of the session
---@param is_current boolean Whether this is the current session
---@param is_exited boolean Whether this session has exited
---@return string Preview text
function zellij.get_session_preview(session_name, is_current, is_exited)
  local session_data = zellij.get_session_data(session_name, is_current, is_exited)
  return format_session_preview(session_data)
end

--- Format tab item into preview markdown text
---@param tab_item ZellijTabItem The tab item to format
---@return string Preview text in markdown format
local function format_tab_preview(tab_item)
  local lines = {}

  -- Header
  table.insert(lines, "# Tab: " .. tab_item.tab_name)
  table.insert(lines, "")

  if tab_item.is_focused_tab then
    table.insert(lines, "**Status:** Currently focused tab")
  else
    table.insert(lines, "**Status:** Background tab")
  end
  table.insert(lines, "")

  -- Panes section
  table.insert(lines, "## Panes")
  table.insert(lines, "")

  if tab_item.panes and #tab_item.panes > 0 then
    local pane_text = tab_item.pane_count == 1 and "1 pane" or string.format("%d panes", tab_item.pane_count)
    table.insert(lines, string.format("**Pane count:** %s", pane_text))
    table.insert(lines, "")

    for pane_num, pane in ipairs(tab_item.panes) do
      local pane_info = {}
      if pane.cmd then
        table.insert(pane_info, string.format("cmd: `%s`", pane.cmd))
      end
      if pane.cwd then
        table.insert(pane_info, string.format("dir: `%s`", pane.cwd))
      end

      if #pane_info > 0 then
        local focus_mark = pane.is_focused and " [focused]" or ""
        table.insert(lines, string.format("- Pane %d: %s%s", pane_num, table.concat(pane_info, ", "), focus_mark))
      end
    end
  else
    table.insert(lines, "_No pane information available_")
  end

  return table.concat(lines, "\n")
end

--- Generate preview text for a Zellij tab
---@param tab_item ZellijTabItem The tab item to preview
---@return string Preview text
function zellij.get_tab_preview(tab_item)
  return format_tab_preview(tab_item)
end

--- Switch to a specific Zellij session
---@param session_name string The name of the session to switch to
function zellij.switch_to_session(session_name)
  if not validate_zellij_environment() then
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
    vim.notify(
      string.format("Failed to switch to session '%s'. Error: %s", session_name, vim.trim(result)),
      vim.log.levels.ERROR
    )
  end
end

--- Switch to a specific tab in the current session
---@param tab_name string The name of the tab to switch to
function zellij.switch_to_tab(tab_name)
  if not validate_zellij_environment() then
    return
  end

  local result = vim.fn.system({ "zellij", "action", "go-to-tab-name", tab_name })
  if vim.v.shell_error == 0 then
    vim.notify(string.format("Switched to tab: %s", tab_name), vim.log.levels.INFO)
  else
    vim.notify(
      string.format("Failed to switch to tab '%s'. Error: %s", tab_name, vim.trim(result)),
      vim.log.levels.ERROR
    )
  end
end

--- Open snacks picker to select and switch to a Zellij session
function zellij.session_picker()
  if not validate_zellij_environment() then
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
        }
      end

      return items
    end,
    title = "Zellij Sessions",
    show_empty = true,
    preview = function(ctx)
      if not ctx.item or not ctx.item.session_name then
        ctx.preview:notify("No session selected", "warn")
        return
      end

      ctx.preview:reset()
      local preview_text = zellij.get_session_preview(
        ctx.item.session_name,
        ctx.item.is_current,
        ctx.item.is_exited
      )
      local lines = vim.split(preview_text, "\n")
      ctx.preview:set_lines(lines)
      ctx.preview:highlight({ ft = "markdown" })
    end,
    format = function(item)
      return { { item.text } }
    end,
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

--- Open snacks picker to select and switch to a tab in current session
function zellij.tab_picker()
  if not validate_zellij_environment() then
    return
  end

  local current_tabs = zellij.get_current_session_tabs()

  if #current_tabs == 0 then
    vim.notify("No Zellij tabs found in current session", vim.log.levels.INFO)
    return
  end

  -- Open snacks picker with a custom finder
  require("snacks").picker.pick({
    finder = function()
      ---@type snacks.picker.finder.Item[]
      local items = {}

      -- Convert tabs to picker items
      for idx, tab in ipairs(current_tabs) do
        -- Format: "● tab [focused]" or "  tab"
        -- Using dump-layout gives us real-time focus state
        local prefix = tab.is_focused_tab and "● " or "  "
        local suffix = tab.is_focused_tab and " [focused]" or ""
        local display_text = string.format("%s%s%s", prefix, tab.tab_name, suffix)

        items[#items + 1] = {
          text = display_text,
          session_name = tab.session_name,
          tab_name = tab.tab_name,
          pane_count = tab.pane_count,
          panes = tab.panes,
          is_current_session = tab.is_current_session,
          is_focused_tab = tab.is_focused_tab,
          idx = idx,
        }
      end

      return items
    end,
    title = "Zellij Tabs (Current Session)",
    show_empty = true,
    -- Custom previewer function for lazy loading tab previews
    preview = function(ctx)
      if not ctx.item or not ctx.item.tab_name then
        ctx.preview:notify("No tab selected", "warn")
        return
      end

      ctx.preview:reset()
      ---@type ZellijTabItem
      local tab_item = ctx.item --[[@as ZellijTabItem]]
      local preview_text = zellij.get_tab_preview(tab_item)
      local lines = vim.split(preview_text, "\n")
      ctx.preview:set_lines(lines)
      ctx.preview:highlight({ ft = "markdown" })
    end,
    format = function(item)
      return { { item.text } }
    end,
    actions = {
      confirm = function(picker, item)
        if item and item.tab_name then
          picker:close()
          -- Small delay to ensure picker is fully closed before switching
          vim.defer_fn(function()
            zellij.switch_to_tab(item.tab_name)
          end, 50)
        end
      end,
    },
  })
end

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
    name = "extras.zellij",
    dir = vim.fn.stdpath("config") .. "/lua/plugins/extras",
    init = function()
      -- Setup user commands
      vim.api.nvim_create_user_command("ZellijSwitch", function()
        zellij.session_picker()
      end, {
        desc = "Switch Zellij session",
      })

      vim.api.nvim_create_user_command("ZellijTab", function()
        zellij.tab_picker()
      end, {
        desc = "Switch Zellij tab",
      })
    end,
    keys = {
      {
        "<leader>zs",
        function()
          zellij.session_picker()
        end,
        desc = "Zellij: Switch session",
      },
      {
        "<leader>zt",
        function()
          zellij.tab_picker()
        end,
        desc = "Zellij: Switch tab",
      },
    },
  },
}
