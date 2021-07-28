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

local paq = require('paq')

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
  {'neoclide/coc.nvim', branch='release'};
}

-- should we always install, or just have that be part of the instructions for installation?
-- paq.install()

-- Use comma as leader
vim.g.mapleader = ','

--
-- Basic Setup
--
vim.o.compatible = false            -- Use vim, no vi defaults
vim.o.number = true                 -- Show line numbers
vim.o.numberwidth = 3               -- Always use 3 characters for line number gutter
vim.o.ruler = true                  -- Show line and column number

vim.o.hidden = true                 -- allow buffer switching without saving
vim.o.history = 1000                -- Store a ton of history (default is 20)
vim.o.cursorline = true             -- highlight current line

vim.o.updatetime = 100              -- ensure GitGutter and other plugins can get updates quickly (when typing pauses)

-- ensure that `O` does not cause a crazy delay
vim.o.timeout = true
vim.o.timeoutlen = 1000
vim.o.ttimeoutlen = 100

vim.o.swapfile = false              -- disable generating swap files

vim.o.mouse = 'a'                   -- Allow resizing windows with the mouse

vim.o.clipboard = 'unnamed'

vim.o.undofile = true               -- enable undo tracking per-file

vim.o.lazyredraw = true             -- don't redraw while in macros

--
-- Whitespace
--
vim.o.wrap = false                  -- don't wrap lines
vim.o.tabstop = 2                   -- a tab is two spaces
vim.o.shiftwidth = 2                -- an autoindent (with <<) is two spaces
vim.o.expandtab = true              -- use spaces, not tabs

-- backspace through everything in insert mode
vim.opt.backspace = {
  'indent',
  'eol',
  'start'
}
vim.o.autoindent = true             -- automatically indent to the current level

-- Scrolling
vim.o.scrolloff=3                   -- minimum lines to keep above and below cursor

-- List chars
vim.o.list = true                   -- Show invisible characters

vim.opt.listchars = {
  tab = '▸ ',                       -- a tab should display as '▸ ', trailing whitespace as '.'
  trail = '.',                      -- show trailing spaces as dots
  eol = '¬',                        -- show eol as '¬'
  extends = '>',                    -- The character to show in the last column when wrap is
                                    -- off and the line continues beyond the right of the screen
  precedes = '<'                    -- The character to show in the last column when wrap is
}

--
-- Searching
--
vim.o.hlsearch = true               -- highlight matches
vim.o.incsearch = true              -- incremental searching
vim.o.ignorecase = true             -- searches are case insensitive...
vim.o.smartcase = true              -- ... unless they contain at least one capital letter

--
-- Wild settings
--
-- TODO: Investigate the precise meaning of these settings
-- set wildmode=list:longest,list:full

vim.opt.wildignore = {
  -- Disable output and VCS files
  '*.o',
  '*.out',
  '*.obj',
  '.git',
  '*.rbc',
  '*.rbo',
  '*.class',
  '.svn',
  '*.gem',

  -- Disable archive files
  '*.zip',
  '*.tar.gz',
  '*.tar.bz2',
  '*.rar',
  '*.tar.xz',

  -- Ignore bundler and sass cache
  '*/vendor/gems/*',
  '*/vendor/cache/*',
  '*/.bundle/*',
  '*/.sass-cache/*',

  -- Disable temp and backup files
  '*.swp',
  '*~',
  '._*',
  '/tmp/'
}
