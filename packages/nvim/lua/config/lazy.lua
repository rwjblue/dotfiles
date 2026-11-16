local lazypath = vim.env.LAZY or (vim.fn.stdpath("data") .. "/lazy/lazy.nvim")

local function file_exists(path)
  return (vim.uv or vim.loop).fs_stat(path) ~= nil
end

if not file_exists(lazypath) then
  local result = vim
    .system({
      "git",
      "clone",
      "--filter=blob:none",
      "https://github.com/folke/lazy.nvim.git",
      "--branch=stable",
      lazypath,
    }, { text = true })
    :wait(120000)
  assert(result.code == 0, "Could not bootstrap lazy.nvim: " .. result.stderr)
end
vim.opt.rtp:prepend(lazypath)

local rwjblue = require("rwjblue")

local spec = {
  { "LazyVim/LazyVim", import = "lazyvim.plugins" },
  { import = "plugins" },
}

if rwjblue.maintaining_plugins then
  vim.list_extend(spec, {
    -- The parser pass waits for installation and updates itself.
    {
      "nvim-treesitter/nvim-treesitter",
      build = false,
      config = function(_, opts)
        require("nvim-treesitter").setup(opts)
      end,
    },
    -- Leave unpinned Mason tools to the editor's normal setup and commands.
    { "mason-org/mason.nvim", build = false },
  })
elseif rwjblue.has_local_plugins then
  -- local_nvim.plugins comes from the local dotfiles overlay.
  spec[#spec + 1] = { import = "local_nvim.plugins" }
end

require("lazy").setup({
  local_spec = not rwjblue.maintaining_plugins,
  spec = spec,
  headless = rwjblue.maintaining_plugins and { process = false, task = false, log = false } or nil,
  defaults = {
    -- By default, only LazyVim plugins will be lazy-loaded. Your custom plugins will load during startup.
    -- If you know what you're doing, you can set this to `true` to have all your custom plugins lazy-loaded by default.
    lazy = false,
    -- It's recommended to leave version=false for now, since a lot the plugin that support versioning,
    -- have outdated releases, which may break your Neovim install.
    version = false, -- always use the latest git commit
    -- version = "*", -- try installing the latest stable version for plugins that support semver
  },

  -- By default lazy.nvim will write a lockfile to
  -- ~/.config/nvim/lazy-lock.json, but if we have `local_nvim.plugins` we
  -- want to write the lockfile to `~/.config/nvim/local_nvim/lazy-lock.json`
  -- instead (so we don't fight with the "public" vs "private" lockfile).
  lockfile = rwjblue.get_lockfile_path(),

  install = {
    missing = rwjblue.should_run_lazy_plugin_checks,
    colorscheme = { "tokyonight", "habamax" },
  },
  checker = {
    enabled = not rwjblue.maintaining_plugins and rwjblue.should_run_lazy_plugin_checks,
    frequency = 86400, -- check for updates once a day
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
