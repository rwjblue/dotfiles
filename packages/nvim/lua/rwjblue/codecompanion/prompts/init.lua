--- Loads CodeCompanion prompt configurations from Lua files
--- Located in: `<config>/lua/rwjblue/codecompanion/prompts/*.lua`
---
--- Each prompt file should return a table with the CodeCompanion.PromptEntry structure:
---
--- ```lua
--- -- Example prompt file (commit.lua):
--- return {
---   name = "Generate a Commit Message",
---   description = "Generate a commit message",
---   strategy = "chat",
---   opts = {
---     index = 10,
---     is_default = true,
---     is_slash_cmd = true,
---     short_name = "commit",
---     auto_submit = true,
---   },
---   prompts = {
---     {
---       role = "user",
---       content = function() return "..." end,
---       opts = { contains_code = true }
---     }
---   }
--- }
--- ```
---
--- See https://codecompanion.olimorris.dev/extending/prompts.html for more details.
---
--- The function will use the following precedence for prompt keys:
--- 1. prompt.name
--- 2. prompt.description
--- 3. module filename (without extension)
---
--- @module "rwjblue.codecompanion.types"
--- @return CodeCompanion.PromptLibrary Table of prompts indexed by their keys
local function load_prompts()
  local prompts = {}
  local current_script = debug.getinfo(1, "S").source:sub(2)
  local prompt_path = vim.fn.fnamemodify(current_script, ":h")

  -- Get all .lua files in the prompts directory
  local files = vim.fn.glob(prompt_path .. "/*.lua", false, true)

  for _, file in ipairs(files) do
    if file ~= prompt_path .. "/init.lua" then
      local module_name = vim.fn.fnamemodify(file, ":t:r")
      --- @module "rwjblue.codecompanion.types"
      --- @type CodeCompanion.PromptEntry
      local prompt = require("rwjblue.codecompanion.prompts." .. module_name)

      if type(prompt) == "table" then
        -- Try prompt.name first
        local prompt_key = prompt.name

        -- Fall back to prompt.description if name isn't available
        if not prompt_key and prompt.description then
          prompt_key = prompt.description
        end

        -- Finally fall back to the module name if neither exists
        if not prompt_key then
          prompt_key = module_name
        end

        prompts[prompt_key] = prompt
      end
    end
  end

  return prompts
end


return load_prompts()
