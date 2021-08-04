-- ensure https://github.com/savq/paq-nvim is installed
local paq_install_path = vim.fn.stdpath('data')..'/site/pack/paqs/start/paq-nvim'
if vim.fn.empty(vim.fn.glob(paq_install_path)) > 0 then
  print('cloning paq-nvim')
  vim.fn.system({ 'git', 'clone', '--depth=1', 'https://github.com/savq/paq-nvim.git', paq_install_path })
  vim.cmd('packadd paq-nvim')
end

local paq = require('paq')

paq {
  'savq/paq-nvim';
  'neovim/nvim-lspconfig';
  'tpope/vim-sensible';
  'editorconfig/editorconfig-vim';
  'tpope/vim-fugitive';
  'tpope/vim-git';
  'tpope/vim-surround';
  'christoomey/vim-tmux-navigator';
  'airblade/vim-gitgutter';
  'wincent/terminus';
  'joshdick/onedark.vim';

  -- telescope deps
  'nvim-lua/popup.nvim';
  'nvim-lua/plenary.nvim';
  'nvim-telescope/telescope.nvim';

  { 'nvim-treesitter/nvim-treesitter', branch = '0.5-compat', run = function() vim.cmd('TSUpdate') end }
}

paq.install()

local function on_installed()
  -- setup treesitter with local config
  require('treesitter');

  vim.cmd('TSUpdate')
end

-- check if packages are installed
local function isInstalled() 
  -- using treesitter here because:
  -- 1) it is the one we actually need a post-install for
  -- 2) it is the last package in the paq configuration above
  local package_path = vim.fn.stdpath('data')..'/site/pack/paqs/start/nvim-treesitter'
  if vim.fn.empty(vim.fn.glob(package_path)) then
    return true
  else
    return false
  end
end

local timer = vim.loop.new_timer()
local i = 0

-- Waits 1000ms, then repeats every 750ms until timer:close().
timer:start(1000, 750, vim.schedule_wrap(function()
  if isInstalled() then
    timer:close()

    on_installed()
  end

  -- wait up to 25 seconds
  if i > 25 then
    timer:close()
  end
  i = i + 1
end))
