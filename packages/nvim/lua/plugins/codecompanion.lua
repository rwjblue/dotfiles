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
    },
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
