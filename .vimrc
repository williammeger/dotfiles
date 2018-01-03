
" Settings //////////////////////////////////

" Syntax highlighting {{{
  set t_Co=256
  set background=dark
  syntax on
  filetype on
  colorscheme zenburn 
" }}}

" Setting things {{{
  set ai "auto indent
  set autoindent "carry over from previous line
  set backspace=indent,eol,start
  set cursorline "higlight current line
  set esckeys "allow cursors keys in insert mode
  set encoding=utf-8
  set expandtab "expanding tabs to spaces
  set foldenable "enable folding
  set foldlevel=0 "close all folds by default
  set foldminlines=0 "allow folding single lines
  set history=1000 "longer history than default 20
  set laststatus=2 "always show status line
  set lazyredraw "only redraw when needed
  set noerrorbells "disable error bells
  set nostartofline "dont reset cursor to start of line
  set noshowmode "airline handles the rest
  set nowrap "dont wrap lines
  set number "count the lines
  set report=0 "show all changes
  set ruler "show the curser position
  set shiftwidth=2 "Indentations and tabs
  set shell=/bin/sh "use shell to execute commands
  set showtabline=2 "show tab bar
  set si "smart indent
  set splitright "new window right
  set splitbelow "new window below
  set tabstop=2 "1 tab == 2 spaces :)
  set ttyfast "send more chars
  set visualbell "otherwise its loudd
  set wildchar=<TAB> " Character for CLI expansion (TAB-completion)
  set wildignore+=.DS_Store
  set wildignore+=*.jpg,*.jpeg,*.gif,*.png,*.gif,*.psd,*.o,*.obj,*.min.js
  set wildignore+=*/bower_components/*,*/node_modules/*
  set wildignore+=*/smarty/*,*/vendor/*,*/.git/*,*/.hg/*,*/.svn/*,*/.sass-cache/*,*/log/*,*/tmp/*,*/build/*,*/ckeditor/*,*/doc/*,*/source_maps/*,*/dist/*
  set wildmenu "hitting TAB in command mode will show possible completions above command line
" }}}

" Key Remaps {{{
"command mode inverse tab
  nnoremap <S-Tab> << 
" insert mode inverse tab
  inoremap <S-Tab> <C-d>
" }}}

" Configuration //////////////////////////////////

" FastEscape {{{
" faster transition between modes
if ! has('gui_running')
  set ttimeoutlen=10
  augroup FastEscape
    autocmd!
    au InsertEnter * set timeoutlen=0
    au InsertLeave * set timeoutlen=1000
  augroup END
endif
" }}}

" faster scroll in viewport {{{
  nnoremap <C-e> 3<C-e>
  nnoremap <C-y> 3<C-y>
" }}}

" faster split resizing (+,-) {{{
  if bufwinnr(1)
    map + <C-w>+
    map - <C-m>-
  endif
" }}}

" better split resizing (Ctrl-j, Ctrl-k, Ctrl-h, Ctrl-l) {{{
  map <C-j> <C-W>j
  map <C-k> <C-W>k
  map <C-h> <C-W>h
  map <C-l> <C-W>l
" }}}

" yank from cursor to EOL {{{
  nnoremap Y y$
" }}}

" Plugin Configuration //////////////////////////////////

" Airline.vim {{{
augroup airline_config
  autocmd!
  let g:airline_powerline_fonts = 1
  let g:airline_enable_syntastic = 1
  let g:airline#extensions#tabline#buffer_nr_format = '%s '
  let g:airline#extensions#tabline#buffer_nr_show = 1
  let g:airline#extensions#tabline#enabled = 1
  let g:airline#extensions#tabline#fnamecollapse = 0
  let g:airline#extensions#tabline#fnamemod = ':t'
  let g:airline_theme='zenburn'
augroup END
" }}}

" NERD Commenter
 augroup nerd_commenter
  autocmd!
  let NERDSpaceDelims=1
  let NERDCompactSexyComs=1
augroup END
" }}}


" Plugins //////////////////////////////////

" Load plugins {{{
call plug#begin('~/.vim/plugged')

Plug 'ap/vim-css-color'
Plug 'bling/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'bling/vim-bufferline'
Plug 'junegunn/vim-easy-align'
Plug 'junegunn/vim-emoji'
Plug 'pangloss/vim-javascript'
Plug 'scrooloose/nerdcommenter'
Plug 'scrooloose/syntastic'
Plug 'tpope/vim-fugitive'

call plug#end()
" }}}
