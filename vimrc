set nocompatible
au!

" enable Pathogen plugin manager
call pathogen#infect()
filetype plugin indent on

" Remember undo's even when buffer has been in the background.
" Also allows for sending buffers to the background without saving...
set hidden
" ... this is where this comes in:
set autowrite
set autoread

set encoding=utf-8
set fileformat=unix
set linespace=0
set visualbell
set nocursorcolumn
set cursorline
set ignorecase
set smartcase
set incsearch
set laststatus=2
set foldclose=all
set foldmethod=marker

" Indentation and whitespace settings
set smartindent
set cindent
set autoindent
set shiftwidth=4
set softtabstop=4
set tabstop=4
set noexpandtab

" Whitespace settings for Ruby
autocmd FileType ruby setlocal ts=2 sts=2 sw=2 expandtab

" Auto-completion
set wildmode=longest,list,full
set wildmenu
set completeopt=preview,menu,longest

" AutoComplPop setting to trigger autocomplete after 4 typed, matching chars
let g:acp_behaviorKeywordLength = 4

" Not too long or we drop to a virtual stand still when editing
" large-all-on-one-line-code (like OOo xml files.)
set synmaxcol=512

" Run current testfile through phpunit
autocmd FileType php map <F5> :! clear && phpunit --colors %<cr>

" Let the backspace behave
set backspace=indent,eol,start whichwrap+=<,>,[,]

" statusline (active file, line+col position, file format+encoding+filetype
set statusline=%-25.25(%<%t\ %m%r\%)line\ %l\ of\ %L\ col\ %c%V\ (%p%%)%=%{&ff},%{strlen(&fenc)?&fenc:''}%Y\


" Do not exit visual mode when shifting
vnoremap > >gv
vnoremap < <gv

" Hop from method to method.
nmap <c-n> ]]
nmap <c-p> [[

" Add open lines without going to insert mode.
nmap <CR> o<ESC>
nmap <C-CR> O<ESC>

" Copy to/cut/paste from system clipboard
map <C-y> "+y
map <C-x> "+x
map <C-M-p> "+p

" Less finger wrecking window navigation.
nnoremap <c-j> <c-w>j
nnoremap <c-k> <c-w>k
nnoremap <c-h> <c-w>h
nnoremap <c-l> <c-w>l

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" When editing a file, always jump to the last known cursor position.
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
autocmd BufReadPost * if line("'\"") > 0 && line("'\"") <= line("$") | exe "normal g`\"" | endif

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Delete trailing whitespaces on saving a file
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
autocmd BufWritePre * :%s/\s\+$//e

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Rename the current file in your buffer
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! RenameFile()
	let old_name = expand('%')
	let new_name = input('New file name: ', expand('%'))
	if new_name != '' && new_name != old_name
		exec ':saveas ' . new_name
		exec ':silent !rm ' . old_name
		redraw!
	endif
endfunction
map <leader>n :call RenameFile()<cr>

" Disable the bloody visual bell
set t_vb=

" Set vim in 256 color-mode
set t_Co=256

" Use the railscasts colorscheme for ruby files
autocmd FileType ruby colorscheme railscasts

" Syntax coloring
colorscheme zenburn
syntax on
