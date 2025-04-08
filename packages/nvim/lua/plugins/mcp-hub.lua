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
    opts = {
      port = 9090, -- Port for MCP Hub server
      cmd = vim.fn.expand("~/.local/share/mise/shims/mcp-hub"),
      config = vim.fn.expand("~/.config/mcp/servers.json"),
      shutdown_delay = 0, -- Wait 0ms before shutting down server after last client exits
      log = {
        level = vim.log.levels.WARN,
        to_file = false,
        file_path = nil,
        prefix = "MCPHub",
      },
    },
  },
}
