return {
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
      }
    }
  }
}
