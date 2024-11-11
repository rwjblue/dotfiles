-- this is meant to be the userland config for the codecompanion extra
-- that is still in PR stage:
--    https://github.com/LazyVim/LazyVim/pull/4268
--
-- This will remain even after that PR lands
return {
  {
    "olimorris/codecompanion.nvim",
    optional = true,
    opts = {
      log_level = "DEBUG",
      adapters = {
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
      strategies = {
        -- just makes it easier to test out for now (comparing apples to apples)
        chat = {
          adapter = "openai",
        },
        inline = {
          adapter = "copilot",
        },
        agent = {
          adapter = "openai",
        },
      },
      display = {
        chat = {
          window = {
            layout = "float",
            border = "rounded",
            width = 0.6,
            height = 0.6,
          }
        }
      }
    }
  }
}
