---@class Config
---@field tmux Tmux|nil # Optional tmux configuration
---@field shell_caching ShellCache|nil # Optional shell caching configuration
---@field crate_locations string[]|nil # Optional list of crate locations

---@class ShellCache
---@field source string # Source path
---@field destination string # Destination path

---@class Tmux
---@field sessions Session[] # List of tmux sessions
---@field default_session string|nil # Default session name (optional)

---@class Session
---@field name string # Name of the session
---@field windows Window[] # List of windows in the session

---@class Window
---@field name string # Name of the window
---@field path string|nil # Working directory path (optional)
---@field command Command|nil # Command to run in the window (optional)
---@field env table<string, string>|nil # Environment variables (optional)
---@field linked_crates string[]|nil # Linked crates (optional)

---@alias Command string|string[] # A single command as a string or multiple commands as a list of strings

---@type Config
return {
  shell_caching = {
    source = "~/src/rwjblue/dotfiles/zsh/",
    destination = "~/src/rwjblue/dotfiles/zsh/dist/"
  },
  tmux = {
    sessions = {
      {
        name = "✅ todos",
        windows = {
          {
            name = "todos"
          }
        }
      },
      {
        name = "dotfiles",
        windows = {
          {
            name = "dotvim",
            path = "~/src/rwjblue/dotvim",
            command = "nvim"
          },
          {
            name = "dotfiles",
            path = "~/src/rwjblue/dotfiles",
            command = "nvim"
          },
          {
            name = "binutils",
            path = "~/src/rwjblue/dotfiles/binutils",
            command = "nvim"
          },
          {
            name = "shared_binutils",
            path = "~/src/malleatus/shared_binutils",
            command = "nvim"
          }
        }
      },
    }
  }
}
