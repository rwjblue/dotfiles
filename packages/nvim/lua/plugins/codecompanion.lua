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
  local prompt_path = vim.fn.stdpath("config") .. "/lua/rwjblue/codecompanion/prompts"

  -- Get all .lua files in the prompts directory
  local files = vim.fn.glob(prompt_path .. "/*.lua", false, true)

  for _, file in ipairs(files) do
    if file ~= prompt_path .. "/init.lua" then
      local module_name = vim.fn.fnamemodify(file, ":t:r")
      local ok, prompt = pcall(require, "rwjblue.codecompanion.prompts." .. module_name)

      if ok and type(prompt) == "table" then
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

return {
  {
    "olimorris/codecompanion.nvim",
    cmd = { "CodeCompanion", "CodeCompanionActions", "CodeCompanionChat", "CodeCompanionCmd" },

    keys = {
      { "<leader>a",  "",                                  desc = "+ai",        mode = { "n", "v" } },
      { "<leader>aA", "<cmd>CodeCompanionActions<cr>",     mode = { "n", "v" }, desc = "Prompt Actions (CodeCompanion)" },
      { "<leader>aa", "<cmd>CodeCompanionChat Toggle<cr>", mode = { "n", "v" }, desc = "Toggle (CodeCompanion)" },
      { "<leader>ac", "<cmd>CodeCompanionChat Add<cr>",    mode = "v",          desc = "Add code to CodeCompanion" },
      { "<leader>ap", "<cmd>CodeCompanion<cr>",            mode = "n",          desc = "Inline prompt (CodeCompanion)" },
    },

    opts = {
      -- Adapter configurations
      adapters = {
        anthropic = function()
          return require("codecompanion.adapters").extend("anthropic", {
            env = { api_key = "AI_CLAUDE_API_KEY" },
          })
        end,

        openai = function()
          return require("codecompanion.adapters").extend("openai", {
            env = {
              api_key = "cmd:op item get 'OpenAI - nvim Token' --vault 'Rob (Work)' --fields label='credential' --reveal",
            },
          })
        end,

        copilot = {
          model = "claude-3.5-sonnet"
        },
      },

      -- Strategy configurations
      strategies = {
        chat = { adapter = "anthropic" },
        inline = { adapter = "anthropic" },
        agent = { adapter = "anthropic" },
      },

      -- Display configurations
      display = {
        chat = {
          -- window = {
          --   layout = "float",
          --   border = "rounded",
          --   width = 0.6,
          --   height = 0.6,
          -- }
        }
      },

      prompt_library = load_prompts(),
    }
  },

  {
    "saghen/blink.cmp",
    optional = true,
    opts = {
      sources = {
        per_filetype = {
          codecompanion = { "codecompanion" },
        }
      },
    }
  },

  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      local LualineCodeCompanionSpinner = require("lualine.component"):extend()
      local spinner_symbols = {
        "⠋",
        "⠙",
        "⠹",
        "⠸",
        "⠼",
        "⠴",
        "⠦",
        "⠧",
        "⠇",
        "⠏",
      }

      function LualineCodeCompanionSpinner:init(options)
        LualineCodeCompanionSpinner.super.init(self, options)
        self.spinner_index = 1

        local group = vim.api.nvim_create_augroup("CodeCompanionHooks", {})

        vim.api.nvim_create_autocmd({ "User" }, {
          pattern = "CodeCompanionRequest*",
          group = group,
          callback = function(request)
            if request.match == "CodeCompanionRequestStarted" then
              self.processing = true
            elseif request.match == "CodeCompanionRequestFinished" then
              self.processing = false
            end
          end,
        })
      end

      -- Function that runs every time statusline is updated
      function LualineCodeCompanionSpinner:update_status()
        if self.processing then
          self.spinner_index = (self.spinner_index % #spinner_symbols) + 1
          return [[󰚩 ]] .. spinner_symbols[self.spinner_index]
        else
          return nil
        end
      end

      local default_opts = require("lualine").get_config()
      opts.sections = opts.sections or {}
      opts.sections.lualine_y = vim.list_extend(
        default_opts.sections.lualine_y or {},
        {
          { LualineCodeCompanionSpinner },
        }
      )
      return opts
    end,
  },
}
