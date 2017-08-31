" *******************************
" * gist 			*
" *******************************
let g:gist_clip_command = 'pbcopy'
let g:gist_detect_filetype = 1

" *******************************
" * ctrlp 			*
" *******************************
let g:ctrlp_custom_ignore = {
			\ 'dir':  '\.git$\|\.hg$\|\.svn$',
			\ 'file': '\.pyc$\|\.pyo$\|\.rbc$|\.rbo$\|\.class$\|\.o$\|\~$\',
			\ }
" If ag is available use it as filename list generator instead of 'find'
if executable("rg")
    set grepprg=rg\ --color=never
    let g:ctrlp_user_command = 'rg %s --files --color=never --glob ""'
endif

" *******************************
" * nerdtree 			*
" *******************************

" tell nerdtree to ignore compiled files
let NERDTreeIgnore=['\.pyc$', '\.pyo$', '\.rbc$', '\.rbo$', '\.class$', '\.o$', '\~$'] 
let NERDTreeHijackNetrw = 1

