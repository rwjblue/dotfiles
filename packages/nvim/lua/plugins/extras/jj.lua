-- Jujutsu Integration
-- Provides Neovim integration for jujutsu (jj) version control using snacks picker

local jj = {}

-- Cache for validation result (nil = not checked, true = valid, false = invalid)
local validation_cache = nil

--- Check if jj is installed and available
---@return boolean
function jj.is_jj_available()
  return vim.fn.executable("jj") == 1
end

--- Check if we're currently in a jj repository
---@return boolean
function jj.is_inside_jj_repo()
  local result = vim.fn.system({ "jj", "root" })
  return vim.v.shell_error == 0
end

--- Validate that jj is available and we're in a repository
--- Results are cached for the vim session
---@return boolean is_valid True if environment is valid for jj operations
local function validate_jj_environment()
  -- Return cached result if available
  if validation_cache ~= nil then
    return validation_cache
  end

  -- Perform validation and cache result
  if not jj.is_jj_available() then
    vim.notify("jj is not installed. Install via: brew install jj", vim.log.levels.ERROR)
    validation_cache = false
    return false
  end

  if not jj.is_inside_jj_repo() then
    vim.notify("Not in a jj repository", vim.log.levels.WARN)
    validation_cache = false
    return false
  end

  validation_cache = true
  return true
end

--- Get list of changed files on current branch
---@return string[] Array of file paths
function jj.get_branch_diff_files()
  if not validate_jj_environment() then
    return {}
  end

  local output = vim.fn.systemlist("jj branch-diff-files")

  -- Check if the command failed
  if vim.v.shell_error ~= 0 then
    vim.notify("Failed to get branch diff files", vim.log.levels.WARN)
    return {}
  end

  -- Filter out empty lines
  local files = {}
  for _, line in ipairs(output) do
    if line and line ~= "" then
      table.insert(files, line)
    end
  end

  return files
end

--- Get diff for a specific file
---@param file_path string The file to get diff for
---@return string[] Lines of the diff
function jj.get_file_diff(file_path)
  if not validate_jj_environment() then
    return {}
  end

  local output = vim.fn.systemlist({ "jj", "diff", file_path })

  -- Check if the command failed
  if vim.v.shell_error ~= 0 then
    return { "Failed to get diff for " .. file_path }
  end

  return output
end

--- Open snacks picker to select and open a changed file from the branch
function jj.branch_diff_picker()
  if not validate_jj_environment() then
    return
  end

  local files = jj.get_branch_diff_files()

  if #files == 0 then
    vim.notify("No changed files on current branch", vim.log.levels.INFO)
    return
  end

  -- Open snacks picker
  require("snacks").picker.pick({
    finder = function()
      ---@type snacks.picker.finder.Item[]
      local items = {}

      -- Convert files to picker items
      for idx, file in ipairs(files) do
        items[#items + 1] = {
          text = file,
          file_path = file,
          idx = idx,
        }
      end

      return items
    end,
    title = "JJ Branch Diff Files",
    show_empty = true,
    preview = function(ctx)
      if not ctx.item or not ctx.item.file_path then
        ctx.preview:notify("No file selected", "warn")
        return
      end

      ctx.preview:reset()
      local diff_lines = jj.get_file_diff(ctx.item.file_path)
      ctx.preview:set_lines(diff_lines)
      ctx.preview:highlight({ ft = "diff" })
    end,
    format = function(item)
      return { { item.text } }
    end,
    actions = {
      confirm = function(picker, item)
        if item and item.file_path then
          picker:close()
          vim.cmd("edit " .. vim.fn.fnameescape(item.file_path))
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
        { "<leader>j", group = "jujutsu" },
      },
    },
  },

  {
    name = "extras.jj",
    dir = vim.fn.stdpath("config") .. "/lua/plugins/extras",
    init = function()
      -- Setup user commands
      vim.api.nvim_create_user_command("JJBranchDiff", function()
        jj.branch_diff_picker()
      end, {
        desc = "Pick JJ branch diff file",
      })
    end,
    keys = {
      {
        "<leader>jd",
        function()
          jj.branch_diff_picker()
        end,
        desc = "JJ: Branch diff files",
      },
    },
  },
}
