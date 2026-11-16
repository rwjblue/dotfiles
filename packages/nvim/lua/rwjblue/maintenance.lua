local function check_plugins(plugins)
  for name, plugin in pairs(plugins) do
    for _, task in ipairs(plugin._.tasks or {}) do
      if task:has_errors() then
        error(("lazy.nvim %s failed for %s:\n%s"):format(task.name, name, task:output()))
      end
    end
  end
end

local function checkouts()
  local commits = {}
  local git = require("lazy.manage.git")
  local plugins = require("lazy.core.config").plugins
  check_plugins(plugins)
  for name, plugin in pairs(plugins) do
    if plugin.url and not plugin._.is_local then
      local info = git.info(plugin.dir)
      assert(info and info.commit, "Plugin is missing: " .. name)
      commits[name] = info.commit
    end
  end
  return commits
end

local function read_lockfile(path)
  return vim.json.decode(table.concat(vim.fn.readfile(path), "\n"))
end

local function verify_lockfile(lock)
  for name, commit in pairs(checkouts()) do
    assert(lock[name] and commit == lock[name].commit, "Could not verify locked commit for " .. name)
  end
end

local function restore()
  local lock = read_lockfile(vim.env.DOTFILES_NVIM_LOCK_SNAPSHOT)
  local drifted = {}
  for name, commit in pairs(checkouts()) do
    assert(lock[name], "Public lockfile has no entry for " .. name)
    if commit ~= lock[name].commit then
      drifted[#drifted + 1] = name
    end
  end
  if #drifted > 0 then
    -- Lazy may rewrite the staged lockfile as startup discovers plugin dependencies.
    -- Restore against the original pins rather than the ones written during startup.
    local manager_lock = require("lazy.manage.lock")
    manager_lock.load()
    manager_lock.lock = vim.deepcopy(lock)
    require("lazy.manage").restore({ plugins = drifted, wait = true, show = false })
  end
  verify_lockfile(lock)
end

local function update()
  checkouts()
  require("lazy.manage").update({ wait = true, show = false })
  checkouts()
end

local function parsers()
  local lockfile = vim.env.DOTFILES_NVIM_MAINTENANCE == "restore" and vim.env.DOTFILES_NVIM_LOCK_SNAPSHOT
    or require("lazy.core.config").options.lockfile
  verify_lockfile(read_lockfile(lockfile))
  local treesitter = require("nvim-treesitter")
  local ensure_installed = LazyVim.opts("nvim-treesitter").ensure_installed
  assert(treesitter.install(ensure_installed, { summary = true }):wait(300000), "Tree-sitter parser install failed")
  assert(treesitter.update(nil, { summary = true }):wait(300000), "Tree-sitter parser update failed")
end

local actions = { restore = restore, update = update, parsers = parsers }

local M = {}

function M.run(action)
  local ok, err = xpcall(function()
    assert(require("rwjblue").maintaining_plugins and package.loaded["lazy.core.config"], "Public Neovim setup failed")
    assert(vim.v.errmsg == "", vim.v.errmsg)
    actions[action]()
    if action ~= "parsers" then
      local runner = require("lazy.manage").clean({ wait = true, show = false })
      check_plugins(runner._plugins)
    end
    assert(vim.v.errmsg == "", vim.v.errmsg)
  end, debug.traceback)

  if not ok then
    io.stderr:write(err .. "\n")
    vim.cmd("cquit 1")
  end
  vim.cmd("qall!")
end

return M
