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

" *******************************
" * nerdtree 			*
" *******************************

" tell nerdtree to ignore compiled files
let NERDTreeIgnore=['\.pyc$', '\.pyo$', '\.rbc$', '\.rbo$', '\.class$', '\.o$', '\~$'] 
let NERDTreeHijackNetrw = 1

let g:neocomplcache_enable_at_startup = 1
let g:neocomplcache_enable_smart_case = 1
let g:neocomplcache_enable_camel_case_completion = 1
let g:neocomplcache_enable_underbar_completion = 1
let g:neocomplcache_max_list = 15


