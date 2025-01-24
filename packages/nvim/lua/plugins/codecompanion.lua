local rwjblue = require('rwjblue')
local fmt = string.format

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

      prompt_library = {
        ["Generate a Commit Message"] = {
          strategy = "chat",
          description = "Generate a commit message",
          opts = {
            index = 10,
            is_default = true,
            is_slash_cmd = true,
            short_name = "commit",
            auto_submit = true,
          },
          prompts = {
            {
              role = "user",
              content = function()
                return fmt(
                  [[You are an expert at following the Conventional Commit specification. Given the git diff listed below, please generate a commit message for me:

```diff
%s
```
]],
                  rwjblue.get_diff()
                )
              end,
              opts = {
                contains_code = true,
              },
            },
          },
        },
      },
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
}
