" Clear existing syntax (including built-in jj syntax)
syntax clear

" TODO: Remove this file (and the corresponding autocmd in
" `lua/config/autocmds.lua`) when NeoVim is released including this:
" https://github.com/neovim/neovim/pull/31840

" The contents below is a lightly edited copy of
" https://github.com/neovim/neovim/blob/a8ace2c58a318552869462a36859aabf1cdfaa68/runtime/syntax/jjdescription.vim

" Vim syntax file
" Language:	jj description
" Maintainer:	Gregory Anders <greg@gpanders.com>
" Last Change:	2024 May 8

syn match jjAdded "A .*" contained
syn match jjRemoved "D .*" contained
syn match jjChanged "M .*" contained

syn region jjComment start="^JJ: " end="$" contains=jjAdded,jjRemoved,jjChanged

syn include @jjCommitDiff syntax/diff.vim
syn region jjCommitDiff start=/\%(^diff --\%(git\|cc\|combined\) \)\@=/ end=/^\%(diff --\|$\|@@\@!\|[^[:alnum:]\ +-]\S\@!\)\@=/ fold contains=@jjCommitDiff

hi def link jjComment Comment
hi def link jjAdded Added
hi def link jjRemoved Removed
hi def link jjChanged Changed
