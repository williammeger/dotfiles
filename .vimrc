
" Settings //////////////////////////////////

" Syntax highlighting {{{
set t_Co=256
set background=dark
syntax on
filetype on
colorscheme onedark
" }}}

" Setting things {{{
set ai "auto indent
set autoindent "carry over from previous line
set cursorline "higlight current line
set esckeys "allow cursors keys in insert mode
set expandtab "expanding tabs to spaces
set foldenable "enable folding
set foldlevel=0 "close all folds by default
set foldminlines=0 "allow folding single lines
set number "count the lines
set shiftwidth=2 "Indentations and tabs
set showtabline=2 "show tab bar
set si "smart indent
set tabstop=2 "1 tab == 2 spaces :)
set visualbell "otherwise its loudd
set nowrap "dont wrap lines
" }}}

" Key Remaps {{{
"command mode inverse tab
nnoremap <S-Tab> << 
" insert mode inverse tab
inoremap <S-Tab> <C-d>

" }}}

