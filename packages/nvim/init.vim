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

" Allow for project-specific .vimrc and .vim
if !(getcwd() == $HOME)
  if filereadable(".vimrc")
    source .vimrc
  endif
  set runtimepath+=./.vim
endif
