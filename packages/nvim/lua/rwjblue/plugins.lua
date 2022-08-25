local M = {};

local is_headless = #vim.api.nvim_list_uis() == 0

local function check_or_install_packer()
  local install_path = vim.fn.stdpath('data') .. '/site/pack/packer/start/packer.nvim'
  if vim.fn.empty(vim.fn.glob(install_path)) > 0 then
    print('cloning packer.nvim')
    bootstrap = vim.fn.system({
      'git', 'clone', '--depth=1', 'https://github.com/wbthomason/packer.nvim', install_path
    })
    print(bootstrap)

    if vim.fn.empty(vim.fn.glob(install_path)) > 0 then
      error('Failed to install packer to "' .. install_path .. '"')
    end

    vim.cmd [[packadd packer.nvim]]
  end
end

check_or_install_packer()

local packer = require 'packer'
local util = require 'packer.util'
local snapshot_path = util.join_paths(vim.fn.stdpath('config'), 'plugins-dev.json')

packer.startup({
  function(use)
    use 'wbthomason/packer.nvim'
    use 'tpope/vim-sensible'
    use 'editorconfig/editorconfig-vim'
    use 'tpope/vim-fugitive'
    use 'tpope/vim-rhubarb' -- make fugitive understand github.com &co
    use 'tpope/vim-git'
    use 'tpope/vim-surround'
    use 'christoomey/vim-tmux-navigator'
    use 'airblade/vim-gitgutter'
    use 'wincent/terminus'
    use 'joshdick/onedark.vim'
    use 'kyazdani42/nvim-web-devicons'

    -- LSP related plugins
    use 'neovim/nvim-lspconfig'
    use 'folke/lsp-colors.nvim'

    -- Completion related plugins / setup
    use {
      'hrsh7th/nvim-cmp',
      config = function()
        local cmp = require('cmp')
        cmp.setup {
          -- snippet = { expand = function(args) vim.fn["UltiSnips#Anon"](args.body) end },
          mapping = {
            ['<c-l>'] = cmp.mapping.confirm({ select = true }),
            ['<c-c>'] = cmp.mapping.abort(),
            ['<c-n>'] = cmp.mapping.select_next_item(),
            ['<c-p>'] = cmp.mapping.select_prev_item(),
          },
          window = {
            completion = cmp.config.window.bordered(),
            documentation = cmp.config.window.bordered(),
          },
          sources = cmp.config.sources({
            { name = 'nvim_lsp' }, -- complete symbols (via LSP)
            { name = 'nvim_lsp_signature_help' }, -- signature completion
            { name = 'nvim_lua' }, -- lua nvim api completion (vim.lsp.* &c.)
            -- This is useful when there is no LSP, but with an LSP + snippets it's mostly noise
            -- { name = 'buffer' }, -- autocomplete keywords (&isk) in buffer
          })
        }

        cmp.setup.cmdline(':', {
          mapping = cmp.mapping.preset.cmdline({
            ['<c-l>'] = {
              c = function()
                if cmp.visible() then
                  cmp.confirm({ select = true })
                end
              end,
            }
          }),
          sources = cmp.config.sources({
            { name = 'cmdline' },
          })
        })

        -- see <https://github.com/hrsh7th/nvim-cmp#setup>
        --  can setup per filetype
        --    cmp.setup.filetype('myfiletype', {})
        --  can setup per custom LSP
      end
    }
    use 'hrsh7th/cmp-nvim-lsp'
    use 'hrsh7th/cmp-cmdline'
    use 'hrsh7th/cmp-nvim-lsp-signature-help'
    use 'hrsh7th/cmp-nvim-lua'
    use 'hrsh7th/cmp-nvim-lsp-document-symbol'

    use {
      'malleatus/common.nvim',
      config = function()
        require('malleatus').setup {}
        --
        -- Most basic setup is done by malleatus/common.nvim, but some overrides are needed
        --
        vim.o.relativenumber = false -- override default in malleatus/common.nvim
      end,
    }

    use {
      'kyazdani42/nvim-tree.lua',
      config = function()
        require'nvim-tree'.setup { }
      end
    }

    use {
      "folke/trouble.nvim",
      requires = "kyazdani42/nvim-web-devicons",
      config = function()
        require("trouble").setup {}
      end
    }

    use {
      'nvim-telescope/telescope.nvim',
      requires = {
        'nvim-lua/popup.nvim',
        'nvim-lua/plenary.nvim',
        'folke/trouble.nvim',
        'nvim-telescope/telescope-fzf-native.nvim'
      },
      config = function()
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

      end
    }
    use { 'nvim-telescope/telescope-fzf-native.nvim', run = 'make', requires = 'telescope.nvim' }

    use {
      'nvim-treesitter/nvim-treesitter',

      config = function()
        require'nvim-treesitter.configs'.setup {
          auto_install = true,

          highlight = {
            enable = true,

            -- currently `treesitter-markdown` doesn't support all syntax
            -- highlighting that we want (e.g. `**foo**` doesn't color that bolded
            -- text); this allows the older regexp based highlighting to work still
            additional_vim_regex_highlighting = { 'markdown' },
          },

          indent = {
            enable = true,
          },
        }
      end,

      run = function()
        -- do minor setup here to force sync installation of all plugins (this
        -- will happen in bootstrap + update)
        require'nvim-treesitter.configs'.setup {
          ensure_installed = 'all',
          sync_install = is_headless,
        }
      end,
    }
  end,
})

function M.take_snapshot(opts)
  opts = opts or { quit_on_install = is_headless }

  -- delete the existing snapshot so that we can write the new one without prompting
  vim.fn.system('rm ' .. snapshot_path)
  packer.snapshot(snapshot_path)

  vim.defer_fn(function()
    local cleanup_script_path = util.join_paths(vim.fn.stdpath('config'), 'scripts', 'cleanup-plugins-snapshot.js')

    vim.fn.system('node ' .. cleanup_script_path .. ' ' .. snapshot_path);

    if opts.quit_on_install then
      vim.cmd('quitall')
    end
  end, 5000)
end

local function install_compile_after_PackerComplete_hook(from, opts)
  vim.api.nvim_create_autocmd('User', {
    once = true,
    pattern = 'PackerComplete',
    callback = function()
      print('initial ' .. from .. ' complete, running `packer.clean()` to remove any unspecified dependencies')
      packer.clean()

      vim.api.nvim_create_autocmd('User', {
        once = true,
        pattern = 'PackerComplete',
        callback = function()
          vim.api.nvim_create_autocmd('User', {
            once = true,
            pattern = 'PackerCompileDone',
            callback = function()
              print('`packer.compile()` complete');

              if (opts.quit_on_install) then
                vim.cmd('quitall')
              end
            end
          })

          print('`packer.clean()` completed, running `packer.compile()` now')
          -- once installed, compile the plugins/packer_compiled.lua file
          packer.compile();
        end
     })
    end
  })
end

function M.update(opts)
  opts = opts or { quit_on_install = is_headless }

  -- autocmd User PackerComplete quitall
  vim.api.nvim_create_autocmd('User', {
    once = true,
    pattern = 'PackerComplete',
    callback = function()
      M.take_snapshot(opts)
    end,
  })

  print('running `packer.sync()`')
  packer.sync() -- Perform `PackerUpdate` and then `PackerCompile`
end

function M.install(opts)
  opts = opts or { quit_on_install = is_headless }

  -- autocmd User PackerComplete quitall
  vim.api.nvim_create_autocmd('User', {
    once = true,
    pattern = 'PackerComplete',
    callback = function()
      M.take_snapshot(opts)
    end,
  })

  -- setup the hook to run packer.compile(), but ensure it doesn't quit early
  -- since that should be done by `take_snapshot`
  install_compile_after_PackerComplete_hook('install', { quit_on_install = false })

  print('running `packer.install()`')
  packer.install() -- Perform `PackerUpdate` and then `PackerCompile`
end

function M.rollback(opts)
  opts = opts or { quit_on_install = is_headless }

  install_compile_after_PackerComplete_hook('rollback', opts)

  -- install from plugins-dev.json lockfile
  print('rolling plugin config back to ' .. snapshot_path)
  packer.rollback(snapshot_path)
end

M.bootstrap = M.rollback;

return M
