" enable Pathogen plugin manager
call pathogen#infect()
filetype plugin indent on

set nocompatible
set encoding=utf-8
set fileformat=unix
set linespace=0
set visualbell
set nocursorcolumn
set cursorline
set ignorecase
set smartcase
set incsearch
set wildmenu
set laststatus=2
set paste
set smartindent
set shiftwidth=4
set softtabstop=4
set tabstop=4
set noexpandtab

" Auto-completion
set wildmode=longest,list,full
set wildmenu

" Whitespace settings for Ruby
autocmd FileType ruby setlocal ts=2 sts=2 sw=2 expandtab

" Let the backspace behave
set backspace=indent,eol,start whichwrap+=<,>,[,]

"Default
set statusline=%-25.25(%<%t\ %m%r\%)line\ %l\ of\ %L\ col\ %c%V\ (%p%%)%=%{&ff},%{strlen(&fenc)?&fenc:''}%Y\ 

" When editing a file, always jump to the last known cursor position.
autocmd BufReadPost * if line("'\"") > 0 && line("'\"") <= line("$") | exe "normal g`\"" | endif

" Delete trailing whitespaces on saving a file
autocmd BufWritePre * :%s/\s\+$//e

" Do not exit visual mode when shifting
vnoremap > >gv
vnoremap < <gv

" Hop from method to method.
nmap <c-n> ]]
nmap <c-p> [[

" Add open lines without going to insert mode.
nmap <CR> o<ESC>
nmap <C-CR> O<ESC>

" Less finger wrecking window navigation.
nnoremap <c-j> <c-w>j
nnoremap <c-k> <c-w>k
nnoremap <c-h> <c-w>h
nnoremap <c-l> <c-w>l

set t_Co=256
colorscheme zenburn
syntax on
