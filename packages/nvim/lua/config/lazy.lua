local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

local function file_exists(path)
  return (vim.uv or vim.loop).fs_stat(path) ~= nil
end

if not file_exists(lazypath) then
  -- bootstrap lazy.nvim
  -- stylua: ignore
  vim.fn.system({ "git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", "--branch=stable",
    lazypath })
end
vim.opt.rtp:prepend(vim.env.LAZY or lazypath)

local non_rdev = not file_exists("/etc/rdev.conf")

local function is_buffer_in_git_subdir()
  local buf_path = vim.fn.bufname('%')
  return (buf_path:match('^%.git/') ~= nil) or (buf_path:match('/%.git/') ~= nil)
end

-- Don't attempt to install missing plugins or check for updates when editing a .git/ file, i.e.
-- when we're probably launched by git as part of a rebase or commit
local should_run_lazy_plugin_checks = not is_buffer_in_git_subdir()

require("lazy").setup({
  spec = {
    -- add LazyVim and import its plugins
    { "LazyVim/LazyVim", import = "lazyvim.plugins" },
    -- import any extras modules here

    -- disable copilot on rdev
    non_rdev and { import = "lazyvim.plugins.extras.coding.copilot" } or nil,
    non_rdev and { import = "plugins.extras.coding.avante" } or nil,
    -- non_rdev and { import = "plugins.extras.coding.codecompanion" } or nil,

    -- NOTE: this is mutually exclusive with codecompanion
    -- non_rdev and { import = "lazyvim.plugins.extras.coding.copilot-chat" } or nil,

    -- import/override with your plugins
    { import = "plugins" },
  },
  defaults = {
    -- By default, only LazyVim plugins will be lazy-loaded. Your custom plugins will load during startup.
    -- If you know what you're doing, you can set this to `true` to have all your custom plugins lazy-loaded by default.
    lazy = false,
    -- It's recommended to leave version=false for now, since a lot the plugin that support versioning,
    -- have outdated releases, which may break your Neovim install.
    version = false, -- always use the latest git commit
    -- version = "*", -- try installing the latest stable version for plugins that support semver
  },
  install = {
    missing = should_run_lazy_plugin_checks,
    colorscheme = { "tokyonight", "habamax" }
  },
  checker = {
    enabled = should_run_lazy_plugin_checks, -- automatically check for plugin updates
    frequency = 86400,                       -- check for updates once a day
  },
  performance = {
    rtp = {
      -- disable some rtp plugins
      disabled_plugins = {
        "gzip",
        -- "matchit",
        -- "matchparen",
        -- "netrwPlugin",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})
