" Convert Ruby 1.8 hash rockets to 1.9 JSON style hashes.
" From: https://github.com/henrik/dotfiles/blob/master/vim/plugin/not_rocket.vim
" Based on https://github.com/hashrocket/dotmatrix/commit/6c77175adc19e94594e8f2d6ec29371f5539ceeb
command! -bar -range=% NotRocket execute '<line1>,<line2>s/:\(\w\+[?!]\?\)\s*=>/\1:/e' . (&gdefault ? '' : 'g')

command! CtrlPSetWorkingPathMode let g:ctrlp_working_path_mode = 'w'
