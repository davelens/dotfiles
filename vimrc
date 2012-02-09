" enable Pathogen plugin manager
call pathogen#infect()
filetype plugin indent on

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

" Let the backspace behave
set backspace=indent,eol,start whichwrap+=<,>,[,]

"Default
set statusline=%-25.25(%<%t\ %m%r\%)line\ %l\ of\ %L\ col\ %c%V\ (%p%%)%=%{&ff},%{strlen(&fenc)?&fenc:''}%Y\ 
" MapCTRL+e and CTRL+a to respectively jump to end and start of line 
imap <C-e> <esc>$i<right>
imap <C-a> <esc>0i

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
