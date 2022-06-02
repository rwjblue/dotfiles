rwjblue = {} -- Namespace for functions in mappings, autocmds, etc

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

vim.o.grepprg = 'rg --vimgrep'      -- use rg as filename list generator instead of 'find'

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

--
-- *** Plugin Config ***
--

-- It's way more useful to see the diff against master than against the index
vim.g.gitgutter_diff_base = 'origin/master'

-- Manually set the mappings we want
vim.g.gitgutter_map_keys = 0

-- always show the sign column (prevents text from jumping leftward on the
-- first change in a file
vim.o.signcolumn = 'yes'

-- Useful neoterm mappings
vim.g.neoterm_autoinsert = 1
vim.g.neoterm_default_mod = ':botright'

vim.lsp.set_log_level("debug")

local function setup_language_servers()
  -- initial setup from https://jose-elias-alvarez.medium.com/configuring-neovims-lsp-client-for-typescript-development-5789d58ea9c
  local nvim_lsp = require('lspconfig');

  local on_attach = function(client, bufnr)
    local function map(mode, lhs, rhs, opts)
      local options = { noremap = true }

      if opts then
        options = vim.tbl_extend('force', options, opts)
      end

      vim.api.nvim_buf_set_keymap(bufnr, mode, lhs, rhs, options)
    end
    local function option(...) vim.api.nvim_buf_set_option(bufnr, ...) end

    --Enable completion triggered by <c-x><c-o>
    option('omnifunc', 'v:lua.vim.lsp.omnifunc')

    -- See `:help vim.lsp.*` for documentation on any of the below functions
    map('n', 'gD', '<Cmd>lua vim.lsp.buf.declaration()<CR>')
    map('n', 'gd', '<Cmd>lua vim.lsp.buf.definition()<CR>')
    map('n', 'K', '<Cmd>lua vim.lsp.buf.hover()<CR>')
    map('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>')
    map('n', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>')
    map('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>')
    map('n', '<space>D', '<cmd>lua vim.lsp.buf.type_definition()<CR>')
    map('n', '<space>r', '<cmd>lua vim.lsp.buf.rename()<CR>')
    map('n', '<space>a', '<cmd>lua vim.lsp.buf.code_action()<CR>')
    map('n', '<space>e', '<cmd>lua vim.lsp.diagnostic.show_line_diagnostics()<CR>')
    map("n", "<space>f", "<cmd>lua vim.lsp.buf.formatting()<CR>")
  end

  nvim_lsp.tsserver.setup {
    on_attach = on_attach,
  }
  nvim_lsp.rust_analyzer.setup {
    on_attach = on_attach,
    flags = {
      debounce_text_changes = 150,
    },
    settings = {
      ["rust-analyzer"] = {
        cargo = {
          allFeatures = true,
        },
      },
    },
  }

  local filetypes = {
    typescript = 'eslint',
    javascript = 'eslint',
  }

  local linters = {
    eslint = {
      sourceName = "eslint",
      command = "eslint", -- consider using https://github.com/mantoni/eslint_d.js/ to make this a bit faster...
      rootPatterns = { ".eslintrc.js", "package.json" },
      debounce = 100,
      args = {"--stdin", "--stdin-filename", "%filepath", "--format", "json"},
      parseJson = {
        errorsRoot = "[0].messages",
        line = "line",
        column = "column",
        endLine = "endLine",
        endColumn = "endColumn",
        message = "${message} [${ruleId}]",
        security = "severity"
      },
      securities = {[2] = "error", [1] = "warning"}
    }
  }

  local formatters = {
    prettier = { command = "prettier", args = {"--stdin-filepath", "%filepath"}}
  }

  local formatFiletypes = {
    typescript = "prettier",
  }

  nvim_lsp.diagnosticls.setup {
    on_attach = on_attach,
    filetypes = vim.tbl_keys(filetypes),
    init_options = {
      filetypes = filetypes,
      linters = linters,
      formatters = formatters,
      formatFiletypes = formatFiletypes
    }
  }

  vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(
    vim.lsp.diagnostic.on_publish_diagnostics, {
      virtual_text = true,
      signs = true,
      update_in_insert = true,
    }
  )
end

local function plugin_setup()
  setup_language_servers();

  -- kick off https://github.com/folke/trouble.nvim
  require("trouble").setup { }

  local trouble_provider_telescope = require("trouble.providers.telescope")

  local telescope = require('telescope');
  telescope.setup {
    defaults = {
      mappings = {
        i = { ["<c-t>"] = trouble_provider_telescope.open_with_trouble },
        n = { ["<c-t>"] = trouble_provider_telescope.open_with_trouble },
      },
    },
  }
  telescope.load_extension('fzf')

  require'nvim-treesitter.configs'.setup {
    ensure_installed = 'all',

    highlight = {
      enable = true
    }
  }

  -- kick off setup for https://github.com/kyazdani42/nvim-tree.lua
  require'nvim-tree'.setup { }
end

-- using pcall here to prevent an error when nvim-telescope / nvim-treesitter
-- isn't loaded (e.g. when installation of packages is required)
pcall(plugin_setup)

--
-- Mappings
--

local function map(mode, lhs, rhs, opts)
  local options = { noremap = true }

  if opts then
    options = vim.tbl_extend('force', options, opts)
  end

  vim.api.nvim_set_keymap(mode, lhs, rhs, options)
end

map('n', 'Q', '')          -- Disable Ex mode from Q

vim.keymap.set('n', '<leader><leader>', '<cmd>nohl | checktime<cr>', { desc = 'use ,, to clear highlights', })
vim.keymap.set('n', '<leader>nt', function() require('nvim-tree').toggle(true) end, { desc = 'now files (toggle nvim-tree)', })

-- Added configuration for christoomey/vim-tmux-navigator to allow
-- Ctrl-H,J,K,L to work for moving in and out of terminals
map('t', '<c-h>', [[<c-\><c-n>:TmuxNavigateLeft<cr>]], { silent = true })
map('t', '<c-j>', [[<c-\><c-n>:TmuxNavigateDown<cr>]], { silent = true })
map('t', '<c-k>', [[<c-\><c-n>:TmuxNavigateUp<cr>]], { silent = true })
map('t', '<c-l>', [[<c-\><c-n>:TmuxNavigateRight<cr>]], { silent = true })
map('t', [[<c-\>]], [[<c-\><c-n>:TmuxNavigatePrevious<cr>]], { silent = true })

-- fugitive bindings
map('n', '<Leader>gs', ':Gstatus<CR>')
map('n', '<Leader>gd', ':Gdiff<CR>')

-- Telescope finder mappings
map('', '<C-P>', [[<Cmd>lua require('telescope.builtin').git_files()<CR>]], { silent = true })
map('', '<C-F>', [[<Cmd>lua require('telescope.builtin').find_files()<CR>]], { silent = true })
map('', '<C-B>', [[<Cmd>lua require('telescope.builtin').buffers()<CR>]], { silent = true })

-- leader versions of the same finders
map('n', '<Leader>fg', [[<Cmd>lua require('telescope.builtin').git_files()<CR>]], { silent = true })
map('n', '<Leader>ff', [[<Cmd>lua require('telescope.builtin').find_files()<CR>]], { silent = true })
map('n', '<Leader>fb', [[<Cmd>lua require('telescope.builtin').buffers()<CR>]], { silent = true })
map('n', '<Leader>fr', [[<Cmd>lua require('telescope.builtin').live_grep()<CR>]], { silent = true })

-- Trouble mappings
map('n', '<Leader>xx', '<cmd>Trouble<cr>', { silent = true });
map('n', '<Leader>xw', '<cmd>Trouble lsp_workspace_diagnostics<cr>', { silent = true });
map('n', '<Leader>xd', '<cmd>Trouble lsp_document_diagnostics<cr>', { silent = true });

-- LSP Mappings
map('n', 'gR', '<cmd>Trouble lsp_references<cr>', { silent = true });

-- GitGutter bindings
map('n', '<leader>hn', ':GitGutterNextHunk<CR>')
map('n', '<Leader>hp', ':GitGutterPrevHunk<CR>')
map('n', '<Leader>hu', ':GitGutterUndoHunk<CR>')

-- Adjust viewports to the same size
map('n', '<Leader>=', '<C-w>=')

-- visual shifting (does not exit Visual mode)
map('v', '<', '<gv')
map('v', '>', '>gv')

-- Move row-wise instead of line-wise
map('n', 'j', 'gj')
map('n', 'k', 'gk')

-- 'x is much easier to hit than `x and has more useful semantics: ie switching
-- to the column of the mark as well as the row
map('n', '\'', '`')

-- No arrow keys
map('n', '<Up>', '')
map('n', '<Down>', '')
map('n', '<Left>', '')
map('n', '<Right>', '')
map('n', '<C-w><Up>', '')
map('n', '<C-w><Down>', '')
map('n', '<C-w><Left>', '')
map('n', '<C-w><Right>', '')

-- coc.nvim
--map('n', '<leader>gd', '<Plug>(coc-definition)')
--map('n', '<leader>gD', '<Plug>(coc-type-definition)')
--map('n', '<leader>gi', '<Plug>(coc-implementation)')
--map('n', '<leader>gr', '<Plug>(coc-references)')
--map('n', '<leader>rn', '<Plug>(coc-rename)')

-- Allow easier fixing linting errors
--map('n', '<leader>f', '<Plug>(coc-codeaction)')
--map('n', '<leader>d', ':CocCommand eslint.executeAutofix<CR>')


-- Window-motion out of terminals
map('t', '<C-w>h', [[<C-\><C-n><C-w>h]])
map('t', '<C-w><C-h>', [[<C-\><C-n><C-w>h]])
map('t', '<C-w>', [[<C-\><C-n><C-w>j]])
map('t', '<C-w><C-j>', [[<C-\><C-n><C-w>j]])
map('t', '<C-w>k', [[<C-\><C-n><C-w>k]])
map('t', '<C-w><C-k>', [[<C-\><C-n><C-w>k]])
map('t', '<C-w>l', [[<C-\><C-n><C-w>l]])
map('t', '<C-w><C-l>', [[<C-\><C-n><C-w>l]])

-- Enable exiting terminal mode with Esc
map('t', [[<C-\><C-\>]], [[<C-\><C-n>]])

-- use ,, to jump to last file
map('n', '<leader><leader>', '<c-^>')

-- has to be so that it can be invoked from the nvim_exec below
function rwjblue.setup_terminal()
  vim.opt_local.winfixwidth = true
  vim.opt_local.number = false
  vim.opt_local.relativenumber = false

  vim.api.nvim_command("vertical resize 100")
end

vim.o.termguicolors = true

-- silent! here in case onedark isn't loaded just yet
vim.cmd 'silent! colorscheme onedark'

-- track https://github.com/neovim/neovim/pull/12378 for moving this to native lua
vim.api.nvim_exec([[
  " *******************************
  " * file type setup             *
  " *******************************

  " automatically trim whitespace for specific file types
  autocmd FileType ts,js,c,cpp,java,php,ruby,perl autocmd BufWritePre <buffer> :%s/\s\+$//e

  " *******************************
  " * Terminal Setup              *
  " *******************************
  augroup TermExtra
    autocmd!
    " When switching to a term window, go to insert mode by default (this is
    " only pleasant when you also have window motions in terminal mode)
    autocmd BufEnter term://* start!
    autocmd TermOpen * call v:lua.rwjblue.setup_terminal() | start!
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

-- allow for project-specific .vimrc files
if vim.fn.getcwd() ~= vim.env.HOME then
  if vim.fn.empty(vim.fn.glob('.vimrc')) == 0 then
    vim.cmd('source .vimrc')
  end
  table.insert(vim.opt.runtimepath, './.vim')
end
