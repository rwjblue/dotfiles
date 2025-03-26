local M = {}

--- Load TreeSitter query overrides from user-defined files
---
--- This function scans the `overrides/queries` directory within your Neovim
--- config directory and loads all TreeSitter query override files.
---
--- Required folder structure:
---   ~/.config/nvim/overrides/queries/<language>/<query_name>.scm
---
--- Example:
---   ~/.config/nvim/overrides/queries/lua/highlights.scm
---   ~/.config/nvim/overrides/queries/rust/injections.scm
---
--- @return nil
function M.load_ts_query_overrides()
  local config_dir = vim.fn.stdpath("config")
  local overrides_dir = config_dir .. "/overrides/queries"

  -- do nothing if the folder doesn't exist
  if vim.fn.isdirectory(overrides_dir) ~= 1 then
    return
  end

  local lang_dirs = vim.fn.glob(overrides_dir .. "/*", false, true)
  for _, lang_dir in ipairs(lang_dirs) do
    if vim.fn.isdirectory(lang_dir) == 1 then
      local lang = vim.fn.fnamemodify(lang_dir, ":t")

      -- Scan for query files
      local query_files = vim.fn.glob(lang_dir .. "/*.scm", false, true)
      for _, query_file in ipairs(query_files) do
        local query_name = vim.fn.fnamemodify(query_file, ":t:r") -- Remove path and extension

        -- Read query file content
        local file = io.open(query_file, "r")
        if file then
          local content = file:read("*all")
          file:close()

          -- Set the query
          vim.treesitter.query.set(lang, query_name, content)
          print(string.format("Loaded TreeSitter query override: %s.%s", lang, query_name))
        else
          vim.notify(string.format("Failed to read query file: %s", query_file), vim.log.levels.ERROR)
        end
      end
    end
  end
end

return M
