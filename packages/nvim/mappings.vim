" *******************************
" * key bindings 		            *
" *******************************
map <Leader>n :NERDTreeToggle<CR>

" fugitive bindings
nmap <Leader>gs :Gstatus<CR>
nmap <Leader>gd :Gdiff<CR>

" ack 
map <C-F> :Ack<space>

" tabular
nmap <Leader>a= :Tabularize /=<CR>
vmap <Leader>a= :Tabularize /=<CR>
nmap <Leader>a> :Tabularize /=><CR>
vmap <Leader>a> :Tabularize /=><CR>
nmap <Leader>a: :Tabularize /:\zs<CR>
vmap <Leader>a: :Tabularize /:\zs<CR>

"CtrlP
map <Leader>b :CtrlPBuffer<CR>

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

" Toggle hlsearch with <leader>hs
nmap <leader>hs :set hlsearch! hlsearch?<CR>

" pastetoggle (sane indentation on pastes)
set pastetoggle=<F12>

" visual shifting (does not exit Visual mode)
vnoremap < <gv
vnoremap > >gv

" CTags
map <Leader>t :TagbarToggle<CR><CR>
map <Leader>rt :!ctags --extra=+f -R *<CR><CR>
