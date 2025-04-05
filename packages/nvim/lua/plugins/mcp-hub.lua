local group = vim.api.nvim_create_augroup("CodeCompanionHooks_MCPHub", {})

vim.api.nvim_create_autocmd({ "User" }, {
  pattern = "CodeCompanionChatCreated",
  group = group,
  callback = function(request)
    require("mcphub")
  end,
})

return {
  {
    "ravitemer/mcphub.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    cmd = "MCPHub",
    build = "mise up npm:mcp-hub@latest",
    config = function()
      require("mcphub").setup({
        port = 9090, -- Port for MCP Hub server
        config = vim.fn.expand("~/.config/mcp/servers.json"),

        -- Optional options
        on_ready = function(hub)
          -- Called when hub is ready
        end,
        on_error = function(err)
          -- Called on errors
        end,
        shutdown_delay = 0, -- Wait 0ms before shutting down server after last client exits
        log = {
          level = vim.log.levels.WARN,
          to_file = false,
          file_path = nil,
          prefix = "MCPHub",
        },
      })
    end,
  },
}
