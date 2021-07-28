" since init.vim is the first file looked for, as we migrate to using all lua
" configuration we will need to slowly move things from this file (init.vim)
" into future_init.lua. The eventual goal is to remove init.vim all together,
" and rename `future_init.lua` into `init.lua`.
source ./future_init.lua

"if isdirectory('/opt/homebrew')
"  Plug '/opt/homebrew/opt/fzf' | Plug 'junegunn/fzf.vim'
"else
"  Plug '/usr/local/opt/fzf' | Plug 'junegunn/fzf.vim'
"endif


" Disable Ex mode from Q
nnoremap Q <nop>

" Prevent Vim from clobbering the scrollback buffer. See
" http://www.shallowsky.com/linux/noaltscreen.html
set t_ti= t_te=

" *** Plugin Config ***

" If rg is available use it as filename list generator instead of 'find'
if executable("rg")
    set grepprg=rg\ --color=never\ --glob
endif

" tell nerdtree to ignore compiled files
let NERDTreeIgnore=['\.pyc$', '\.pyo$', '\.rbc$', '\.rbo$', '\.class$', '\.o$', '\~$']
let NERDTreeHijackNetrw = 1

" Don't confirm  buffer deletes
let NERDTreeAutoDeleteBuffer=1

" setup strategy to be used by vim-test
let test#strategy = "neoterm"

" It's way more useful to see the diff against master than against the index
let g:gitgutter_diff_base = 'origin/master'
" Manually set the mappings we want
let g:gitgutter_map_keys = 0

" always show the sign column (prevents text from jumping leftward on the
" first change in a file
if exists('&signcolumn')  " Vim 7.4.2201
  set signcolumn=yes
else
  let g:gitgutter_sign_column_always = 1
endif

" Added configuration for christoomey/vim-tmux-navigator to allow
" Ctrl-H,J,K,L to work for moving in and out of terminals
tnoremap <silent> <c-h> <c-\><c-n>:TmuxNavigateLeft<cr>
tnoremap <silent> <c-j> <c-\><c-n>:TmuxNavigateDown<cr>
tnoremap <silent> <c-k> <c-\><c-n>:TmuxNavigateUp<cr>
tnoremap <silent> <c-l> <c-\><c-n>:TmuxNavigateRight<cr>
tnoremap <silent> <c-\> <c-\><c-n>:TmuxNavigatePrevious<cr>

" Put the fzf window to the right to not interfere with terminals on the right
let g:fzf_layout = {
\   'right': '~40%'
\}

" *******************************
" * key bindings 		            *
" *******************************
nmap <Leader>nt :NERDTreeToggle<CR>
nmap <Leader>nf :NERDTreeFind<CR>
nmap <leader>ne :call <SID>OpenNERDTree()<CR>

" fugitive bindings
nmap <Leader>gs :Gstatus<CR>
nmap <Leader>gd :Gdiff<CR>

" fzf.vim mappings
map <C-P> :GFiles<CR>
map <C-F> :Files<CR>
map <C-B> :Buffers <cr>


" GitGutter bindings
nmap <leader>hn :GitGutterNextHunk<CR>
nmap <Leader>hp :GitGutterPrevHunk<CR>
nmap <Leader>hu :GitGutterUndoHunk<CR>

" edit files from within current directory
cnoremap %% <C-R>=expand('%:h').'/'<cr>
map <leader>ew :e %%
map <leader>es :sp %%
map <leader>ev :vsp %%
map <leader>et :tabe %%

" Adjust viewports to the same size
map <Leader>= <C-w>=

" use :w!! to write to a file using sudo if you forgot to 'sudo vim file'
" (it will prompt for sudo password when writing)
cmap w!! %!sudo tee > /dev/null %

nnoremap <leader><leader> <c-^>

" pastetoggle (sane indentation on pastes)
set pastetoggle=<F12>

" visual shifting (does not exit Visual mode)
vnoremap < <gv
vnoremap > >gv

" Move row-wise instead of line-wise
nnoremap j gj
nnoremap k gk

" 'x is much easier to hit than `x and has more useful semantics: ie switching
" to the column of the mark as well as the row
nnoremap ' `

" No arrow keys
noremap <Up> <NOP>
noremap <Down> <NOP>
noremap <Left> <NOP>
noremap <Right> <NOP>
noremap <C-w><Up> <NOP>
noremap <C-w><Down> <NOP>
noremap <C-w><Left> <NOP>
noremap <C-w><Right> <NOP>

" coc.nvim
nmap <leader>gd <Plug>(coc-definition)
nmap <leader>gD <Plug>(coc-type-definition)
nmap <leader>gi <Plug>(coc-implementation)
nmap <leader>gr <Plug>(coc-references)
nmap <leader>rn <Plug>(coc-rename)

" Allow easier fixing linting errors
nmap <leader>f <Plug>(coc-codeaction)
nmap <leader>d :CocCommand eslint.executeAutofix<CR>


" Use K for show documentation in preview window
nnoremap <silent> K :call <SID>show_documentation()<CR>
function! s:show_documentation()
  if &filetype == 'vim'
    execute 'h '.expand('<cword>')
  else
    call CocAction('doHover')
  endif
endfunction

" Enable soft wrapping with `:Wrap`
" From: http://vimcasts.org/episodes/soft-wrapping-text/
"
command! -nargs=* SoftWrap set wrap linebreak nolist

" Use <CR> to clear text search, but unmap it when in the command window as
" <CR> there is used to run command
function s:install_enter_hook()
  nnoremap <CR> :nohl<CR>
endfunction

augroup EnterKeyManager
  autocmd!

  autocmd CmdwinEnter * nunmap <CR>
  autocmd CmdwinLeave * call s:install_enter_hook()
augroup end
call s:install_enter_hook()

" Remember last location in file, but not for commit messages.
" see :help last-position-jump
autocmd BufReadPost * if &filetype !~ '^git\c' && line("'\"") > 0 && line("'\"") <= line("$")
\| exe "normal! g`\"" | endif

function s:OpenNERDTree()
  let isFile = (&buftype == "") && (bufname() != "")

  if isFile
    let findCmd = "NERDTreeFind " . expand('%')
  endif

  " open a NERDTree in this window
  edit .

  " make this the implicit NERDTree buffer
  let t:NERDTreeBufName=bufname()

  if isFile
    exe findCmd
  endif
endfunction

" Useful neoterm mappings
"
let g:neoterm_autoinsert = 1
let g:neoterm_default_mod = ':botright'

" Window-motion out of terminals
tnoremap <C-w>h <C-\><C-n><C-w>h
tnoremap <C-w><C-h> <C-\><C-n><C-w>h
tnoremap <C-w>j <C-\><C-n><C-w>j
tnoremap <C-w><C-j> <C-\><C-n><C-w>j
tnoremap <C-w>k <C-\><C-n><C-w>k
tnoremap <C-w><C-k> <C-\><C-n><C-w>k
tnoremap <C-w>l <C-\><C-n><C-w>l
tnoremap <C-w><C-l> <C-\><C-n><C-w>l

" Enable exiting terminal mode with Esc
tnoremap <C-\><C-\> <C-\><C-n>

set termguicolors
colorscheme onedark

" Allow for project-specific .vimrc and .vim
if !(getcwd() == $HOME)
  if filereadable(".vimrc")
    source .vimrc
  endif
  set runtimepath+=./.vim
endif
