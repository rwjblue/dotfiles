return {
  {
    "olimorris/codecompanion.nvim",
    optional = true,
    opts = {
      strategies = {
        -- just makes it easier to test out for now (comparing apples to apples)
        adapter = "copilot",
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
