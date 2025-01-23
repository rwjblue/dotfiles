return {
  {
    "saghen/blink.cmp",
    opts = {
      -- TODO: this enables experimental signature help support, but seems like
      -- that duplicates signature help (at least with rustacean)
      -- signature = { enabled = true }
      completion = {
        list = {
          selection = {
            -- When navigating items with <c-n>, <c-p>, just show the ghost
            -- text, don't actually insert changes until the selectdion is
            -- accepted
            auto_insert = false,
          },
        },
        menu = { border = "single" },
        documentation = { window = { border = "single" } },
      },
      signature = { window = { border = "single" } },
      sources = {
        providers = {
          lsp = {
            score_offset = 50,
          },

          snippets = {
            -- snippets should be a higher priority by default
            score_offset = 10,
          },

          buffer = {
            -- deprioritize buffer completions, mainly to always get them below
            -- snippet, lsp, &c
            score_offset = -100,
          },
        }
      }
    }
  },

  -- blink-emoji setup
  {
    "moyiz/blink-emoji.nvim",
  },
  {
    "saghen/blink.cmp",
    opts = {
      sources = {
        default = {
          "emoji",
        },
        providers = {
          emoji = {
            module = "blink-emoji",
            name = "Emoji",
            -- set emoji to have a slightly lower priority than other sources
            -- (completion in rust/typescript codebases should get lsp sourced
            -- results higher than emoji)
            score_offset = -10,
            opts = { insert = true }, -- Insert emoji (default) or complete its name
          }
        }
      }
    }
  },
}
