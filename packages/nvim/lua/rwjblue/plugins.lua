local function check_or_install_paq()
  local paq_install_path = vim.fn.stdpath('data') .. '/site/pack/paqs/start/paq-nvim'
  if vim.fn.empty(vim.fn.glob(paq_install_path)) > 0 then
    print('cloning paq-nvim')
    print(vim.fn.system({
      'git', 'clone', '--depth=1', 'https://github.com/savq/paq-nvim.git', paq_install_path
    }))

    if vim.fn.empty(vim.fn.glob(paq_install_path)) > 0 then
      error('Failed to install paq to "' .. paq_install_path .. '"')
    end

    vim.cmd('packadd paq-nvim')
  end
end

local paq_config = {
  'savq/paq-nvim';
  'neovim/nvim-lspconfig';
  'tpope/vim-sensible';
  'editorconfig/editorconfig-vim';
  'tpope/vim-fugitive';
  'tpope/vim-rhubarb'; -- make fugitive understand github.com &co
  'tpope/vim-git';
  'tpope/vim-surround';
  'christoomey/vim-tmux-navigator';
  'airblade/vim-gitgutter';
  'wincent/terminus';
  'joshdick/onedark.vim';
  'kyazdani42/nvim-web-devicons';
  'kyazdani42/nvim-tree.lua',
  'folke/trouble.nvim';

  -- telescope deps
  'nvim-lua/popup.nvim';
  'nvim-lua/plenary.nvim';
  'nvim-telescope/telescope.nvim';
  { 'nvim-telescope/telescope-fzf-native.nvim', run = 'make' };

  { 'nvim-treesitter/nvim-treesitter' };
}

local function update(opts)
  opts = opts or { quit_on_install = false }

  check_or_install_paq()

  vim.api.nvim_create_autocmd('User', {
    once = true,
    pattern = 'PaqDoneSync',
    callback = function()
      -- ensure all treesitter grammars and whatnot are installed
      vim.cmd('TSUpdateSync all')

      if opts.quit_on_install then
        vim.cmd('quit')
      end
    end
  })

  local paq = require('paq')

  paq(paq_config)

  paq:sync() -- runs paq.clean(), paq.update(), paq.install()
end

local function bootstrap()
  update { quit_on_install = true }
end

return {
  update = update,
  bootstrap = bootstrap,
  paq_config = paq_config,
}
