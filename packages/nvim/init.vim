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


" *** Plugin Config ***

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


" Put the fzf window to the right to not interfere with terminals on the right
let g:fzf_layout = {
\   'right': '~40%'
\}

" *******************************
" * key bindings 		            *
" *******************************

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

set termguicolors
colorscheme onedark

" Allow for project-specific .vimrc and .vim
if !(getcwd() == $HOME)
  if filereadable(".vimrc")
    source .vimrc
  endif
  set runtimepath+=./.vim
endif
