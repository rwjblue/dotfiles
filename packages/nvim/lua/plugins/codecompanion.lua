local prompt_library = require("rwjblue.codecompanion.prompts")

return {
  {
    "olimorris/codecompanion.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      "ravitemer/mcphub.nvim",
    },
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
                  default = "o3-mini-2025-01-31",
                },
              },
            })
          end,
          copilot = function()
            return require("codecompanion.adapters").extend("copilot", {
              schema = {
                model = {
                  default = "claude-3.7-sonnet",
                },
              },
            })
          end,
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
            },

            tools = {
              mcp = {
                description = "Call tools and resources from the MCP Servers",
                callback = function()
                  return require("mcphub.extensions.codecompanion")
                end,
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
