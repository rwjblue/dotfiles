return {
  {
    "ravitemer/mcphub.nvim",

    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    cmd = "MCPHub",
    build = "mise up npm:mcp-hub@latest",
    opts = {
      cmd = vim.fn.expand("~/.local/share/mise/shims/mcp-hub"),
      config = vim.fn.expand("~/.config/mcp/servers.json"),
      native_servers = {
        ["mcp-go"] = require("mcp_servers.mcp_go"),
      },
    },
  },
}
