local utils = require("telescope.utils")
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local entry_display = require("telescope.pickers.entry_display")
local conf = require("telescope.config").values

local sys = utils.get_os_command_output

local tmux = {}

function tmux.get_tmux_panes()
  local result = {}
  local tmux_panes = sys({
    "tmux",
    "list-panes",
    "-a",
    "-F",
    "#{pane_id}⊱#{window_name}⊱#{session_name}",
  })
  for _, entry in ipairs(tmux_panes) do
    local partsIter = entry:gmatch("([^⊱]+)[⊱]?")
    local pane_id = partsIter()
    local window_name = partsIter()
    local session_name = partsIter()
    table.insert(result, { pane_id = pane_id, window_name = window_name, session_name = session_name })
  end
  return result
end

function tmux.goto_tmux_session(session_name, window_name)
  local matching_pane = nil
  for _, pane in ipairs(tmux.get_tmux_panes()) do
    if session_name == pane.session_name then
      if window_name == pane.window_name then
        matching_pane = pane
        break
      end
    end
  end

  if matching_pane then
    vim.api.nvim_command([[silent !tmux switch-client -t \\]] .. matching_pane.pane_id)
  else
    vim.api.nvim_err_writeln('Cannot find tmux pane "' .. tostring(session_name) .. ":" .. tostring(window_name) .. '"')
  end
end

local tmux_new_session_displayer = entry_display.create({
  separator = " ",
  items = {
    { remaining = true },
  },
})

local function tmux_session_display_name(path)
  if path == nil then
    return nil
  end

  return path
end

function tmux.new_tmux_session(options)
  local opts = vim.tbl_deep_extend("force", {}, options or {})

  -- TODO: opts.src local_src
  -- TODO: opts.src github
  -- TODO: opts.src github_stars
  -- TODO: opts.src ghe
  -- TODO: opts.src ghe_stars
  -- see https://github.com/nvim-telescope/telescope.nvim/blob/master/developers.md#introduction
  -- see https://github.com/nvim-telescope/telescope.nvim/blob/a3f17d3baf70df58b9d3544ea30abe52a7a832c2/lua/telescope/finders.lua#L161-L167
  local local_src = vim.fn.expand('~/src')
  local finder_opts = {
    entry_maker = function(entry)
      if entry == "" then
        return nil
      end

      local use_entry = entry:gsub(local_src .. "/", "")
      use_entry = use_entry:gsub("/$", "")

      return {
        full_path = entry,
        value = use_entry,
        ---@diagnostic disable-next-line: redefined-local
        display = function(entry)
          return tmux_new_session_displayer({
            tmux_session_display_name(entry.value),
          })
        end,
        ordinal = use_entry,
      }
    end,
  }
  local finder = finders.new_oneshot_job(
    { "fd", ".", "--type", "directory", "--min-depth", "2", "--max-depth", "3", local_src },
    finder_opts
  )

  pickers
      .new(options, {
        prompt_title = "~/src repo",
        finder = finder,
        sorter = conf.generic_sorter(opts),
        attach_mappings = function(
          prompt_bufnr --[[, map]]
        )
          actions.select_default:replace(function()
            actions.close(prompt_bufnr)
            local selection = action_state.get_selected_entry()
            local full_path = selection.full_path
            local display = selection.value
            local new_session_id = sys({ "tmux", "new-session", "-dP", "-s", display, "-F", "#{session_id}" })[1]
            sys({ "tmux", "rename-window", "-t", new_session_id, display })
            sys({ "tmux", "send-keys", "-t", new_session_id, "cd " .. full_path, "Enter" })
            sys({ "tmux", "send-keys", "-t", new_session_id, "nvim", "Enter" })
            sys({ "tmux", "switch-client", "-t", new_session_id })
          end)

          return true
        end,
      })
      :find()
end

function tmux.attach_tmux_mappings(prompt_bufnr, map)
  local function new_tmux_session()
    actions.close(prompt_bufnr)
    tmux.new_tmux_session({})
  end

  map("i", "<c-n>", new_tmux_session)
  map("n", "n", new_tmux_session)

  return true
end

return {
  { "camgraff/telescope-tmux.nvim" },

  {
    "folke/which-key.nvim",
    optional = true,
    opts = {
      defaults = {
        ["<leader>ts"] = { name = "+tmux session" },
      },
    },
  },

  ---@type LazySpec[]
  -- see https://github.com/nvim-telescope/telescope.nvim
  -- /Users/hjdivad/.local/share/nvim/lazy/LazyVim/lua/lazyvim/plugins/editor.lua
  {
    "nvim-telescope/telescope.nvim",
    keys = {
      -- TODO: this toggles sessions; do this in lua instead and toggle windows
      { "<leader>tst", "<Cmd>silent !tmux switch-client -l<cr>", desc = "tmux toggle" },
      {
        "<leader>tss",
        function()
          require("telescope").extensions.tmux.windows({
            -- Strip tmux format variables, although I would rather #{E:window_name} worked as expected
            entry_format = [=[#S: #{s/##\[[^]*]*\]//:window_name}]=],
            attach_mappings = tmux.attach_tmux_mappings,
          })
        end,
        desc = "tmux switch window",
      },
      {
        "<leader>tsn",
        function()
          tmux.new_tmux_session({})
        end,
        desc = "tmux new session",
      },
      {
        "<leader>tsd",
        function()
          tmux.goto_tmux_session("todos", "todos")
        end,
        desc = "tmux goto todos",
      },
    }
  }
}
