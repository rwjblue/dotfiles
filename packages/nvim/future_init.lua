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

-- *******************************
-- * status line                 *
-- *******************************
vim.o.laststatus=2                  -- always show status line

local function split(str, sep)
  local result = {}
  for s in  string.gmatch(str, "([^"..sep.."]+)") do
    table.insert(result, s)
  end

  return result
end

local function statusline()
  local directories = split(vim.fn.getcwd(), '/')
  local projectName = directories[#directories]

  local t = {
    '%<%f',                           -- Filename
    '%w%h%m%r',                       -- Options
    ' [%{&ff}/%Y]',                   -- filetype
    ' [' .. projectName .. ']',    -- current dir
    '%=%-14.(%l,%c%V%) %p%%',         -- Right aligned file nav info
  }

  return table.concat(t)
end

vim.opt.statusline = statusline()
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

function setup_terminal()
  vim.opt_local.winfixwidth = true
  vim.opt_local.number = false
  vim.opt_local.relativenumber = false

  vim.apia.nvim_command("vertical resize 100")
end

-- track https://github.com/neovim/neovim/pull/12378 for moving this to native lua
vim.api.nvim_exec([[
  " *******************************
  " * file type setup             *
  " *******************************

  " automatically trim whitespace for specific file types
  autocmd FileType ts,js,c,cpp,java,php,ruby,perl autocmd BufWritePre <buffer> :%s/\s\+$//e

  augroup coctls
    autocmd!
    " Setup formatexpr specified filetype(s).
    autocmd FileType javascript,typescript,json setl formatexpr=CocAction('formatSelected')

    " Update signature help on jump placeholder
    autocmd User CocJumpPlaceholder call CocActionAsync('showSignatureHelp')
  augroup end

  " Highlight the symbol and its references when holding the cursor.
  autocmd CursorHold * silent call CocActionAsync('highlight')

  " *******************************
  " * Terminal Setup              *
  " *******************************
  augroup TermExtra
    autocmd!
    " When switching to a term window, go to insert mode by default (this is
    " only pleasant when you also have window motions in terminal mode)
    autocmd BufEnter term://* start!
    autocmd TermOpen * call <SID>v:lua.setup_terminal() | start!
    autocmd TermClose * setlocal nowinfixwidth
    autocmd WinLeave term://* :checktime

    " working around the bug reported in https://github.com/neovim/neovim/issues/11072
    " specifically, scrolloff being set _within_ terminal mode causes "weird"
    " ghosting to occur in certain terminal UIs (e.g. nested nvim, htop,
    " anything with ncurses)
    autocmd TermEnter * setlocal scrolloff=0
    autocmd TermLeave * setlocal scrolloff=3
  augroup end

  augroup WindowManagement
    autocmd!

    " re-arrange windows on resize
    autocmd VimResized * wincmd =
  augroup end
]], false)
