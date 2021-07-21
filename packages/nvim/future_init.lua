local function file_exists(file)
  local f = io.open(file, 'r')
  if f == nil then
    return false
  else 
    io.close(f)
    return true
  end
end

local function shellExec(command)
  local file = io.popen(command, 'r')
  local output = file:read('*all')

  return output
end

local homedir = vim.loop.os_homedir()

-- ensure https://github.com/savq/paq-nvim is installed
if not file_exists(homedir .. '/.local/share/nvim/site/pack/paqs/start/paq-nvim/lua/paq.lua') then
  shellExec('git clone --depth=1 https://github.com/savq/paq-nvim.git ' .. homedir .. '/.local/share/nvim/site/pack/paqs/start/paq-nvim')
end

local paq = require("paq")

paq {
  'savq/paq-nvim';
  'neovim/nvim-lspconfig';
  'tpope/vim-sensible';
  'editorconfig/editorconfig-vim';
  'tpope/vim-fugitive';
  'tpope/vim-git';
  'tpope/vim-surround';
  'tpope/vim-repeat';
  'tpope/vim-unimpaired';
  'tpope/vim-rhubarb';
  'tpope/vim-obsession';
  'moll/vim-node';
  'mustache/vim-mustache-handlebars';
  'pangloss/vim-javascript';
  'elzr/vim-json';
  'plasticboy/vim-markdown';
  'leafgarland/typescript-vim';
  'cakebaker/scss-syntax.vim';
  'preservim/nerdtree';
  'sbdchd/neoformat';
  'jparise/vim-graphql';
  'christoomey/vim-tmux-navigator';
  'janko-m/vim-test';
  'cespare/vim-toml';
  'airblade/vim-gitgutter';
  'wincent/terminus';
  'joshdick/onedark.vim';

  -- want to get rid of this eventually, migrating to using internal lsp
  {"neoclide/coc.nvim", branch="release"};
}

paq.install()
