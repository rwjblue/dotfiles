local prompt_library = require("rwjblue.codecompanion.prompts")

return {
  {
    -- See https://github.com/Davidyz/VectorCode/blob/main/docs/neovim.md
    "Davidyz/VectorCode",
    version = "*",
    build = "pipx install --force vectorcode",
    dependencies = { "nvim-lua/plenary.nvim" },
    cmd = "VectorCode",
  },
  {
    "olimorris/codecompanion.nvim",
    cmd = { "CodeCompanion", "CodeCompanionActions", "CodeCompanionChat", "CodeCompanionCmd" },

    keys = {
      { "<leader>a", "", desc = "+ai", mode = { "n", "v" } },
      {
        "<leader>aa",
        "<cmd>CodeCompanionActions<cr>",
        mode = { "n", "v" },
        desc = "Prompt Actions (CodeCompanion)",
      },
      { "<leader>af", "<cmd>CodeCompanionChat Toggle<cr>", mode = { "n", "v" }, desc = "Toggle (CodeCompanion)" },
      { "<leader>ac", "<cmd>CodeCompanionChat Add<cr>", mode = "v", desc = "Add code to CodeCompanion" },
    },

    opts = function()
      return {

        -- Adapter configurations
        adapters = {
          opts = {
            -- only show adapters that I've configured
            show_defaults = false,
          },

          anthropic = function()
            return require("codecompanion.adapters").extend("anthropic", {
              env = { api_key = "AI_CLAUDE_API_KEY" },
            })
          end,

          xai = function()
            return require("codecompanion.adapters").extend("xai", {
              env = { api_key = "AI_GROK_API_KEY" },
            })
          end,

          openai = function()
            return require("codecompanion.adapters").extend("openai", {
              env = {
                -- I'd rather use this, but it prompt's SOO MUCH
                -- api_key = "cmd:op item get 'OpenAI - nvim Token' --vault 'Rob (Work)' --fields label='credential' --reveal",
                api_key = "AI_OPEN_AI_API_KEY",
              },
              schema = {
                model = {
                  -- NOTE: I don't have access to o3-mini in the API just yet,
                  -- keep checking status here (I'm current Tier 2):
                  -- https://help.openai.com/en/articles/10362446-api-access-to-o1-and-o3-mini
                  -- default = "o3-mini-2025-01-31"
                },
              },
            })
          end,

          copilot = {
            model = "claude-3.7-sonnet",
          },
        },

        -- Strategy configurations
        strategies = {
          chat = {
            adapter = "anthropic",

            slash_commands = {
              ["buffer"] = {
                opts = {
                  provider = "snacks",
                },
              },
              ["help"] = {
                opts = {
                  provider = "snacks",
                  max_lines = 1000,
                },
              },
              ["file"] = {
                opts = {
                  provider = "snacks",
                },
              },
              ["symbols"] = {
                opts = {
                  provider = "snacks",
                },
              },
              ["workspace"] = {
                opts = {
                  provider = "snacks",
                },
              },

              -- Custom slash commands
              codebase = require("vectorcode.integrations").codecompanion.chat.make_slash_command(),
            },

            tools = {
              vectorcode = {
                description = "Run VectorCode to retrieve the project context.",
                callback = require("vectorcode.integrations").codecompanion.chat.make_tool(),
              },
            },
          },
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
          },
        },

        prompt_library = prompt_library,
      }
    end,
  },

  {
    "saghen/blink.cmp",
    optional = true,
    opts = {
      sources = {
        per_filetype = {
          codecompanion = { "codecompanion" },
        },
      },
    },
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

      opts.sections = opts.sections or {}
      opts.sections.lualine_y = vim.list_extend(opts.sections.lualine_y or {}, {
        { LualineCodeCompanionSpinner },
      })

      return opts
    end,
  },
}
