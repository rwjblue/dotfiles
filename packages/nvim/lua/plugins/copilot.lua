return {
  {
    -- FIXME: work around https://github.com/LazyVim/LazyVim/issues/5899
    -- Remove this whole section when the issue is resolved in LazyVim
    "zbirenbaum/copilot.lua",
    optional = true,
    opts = function()
      require("copilot.api").status = require("copilot.status")
    end,
  },
  {
    "CopilotC-Nvim/CopilotChat.nvim",
    optional = true,
    opts = {
      -- TODO: remove this when this is the default, it will likely be updated in LazyVim's extra soon
      model = "gpt-4o",

      -- configure the window to float with a reasonable size (basically behave like the floating terminal)
      window = {
        layout = "float",
        border = "rounded",
        width = 0.6,
        height = 0.6,
      },
    },
  },
}
