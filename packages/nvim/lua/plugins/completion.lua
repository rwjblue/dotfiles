return {
  {
    "saghen/blink.cmp",
    opts = {
      -- TODO: this enables experimental signature help support, but seems like
      -- that duplicates signature help (at least with rustacean)
      -- signature = { enabled = true }
    }
  },

  -- blink-emoji
  {
    "moyiz/blink-emoji.nvim",
  },
  {
    "saghen/blink.cmp",
    opts = {
      -- TODO: this enables experimental signature help support, but seems like
      -- that duplicates signature help (at least with rustacean)
      -- signature = { enabled = true }
      --
      sources = {
        default = {
          "emoji",
        },
        providers = {
          emoji = {
            module = "blink-emoji",
            name = "Emoji",
            score_offset = 15,        -- Tune by preference
            opts = { insert = true }, -- Insert emoji (default) or complete its name
          }
        }
      }
    }
  },
}
