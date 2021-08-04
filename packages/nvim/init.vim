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

