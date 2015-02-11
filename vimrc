set nocompatible
filetype off

set rtp+=~/.vim/bundle/vundle/
call vundle#rc()

Bundle 'sjl/vitality.vim'
Bundle 'altercation/vim-colors-solarized'
Bundle 'Valloric/YouCompleteMe'
Bundle 'kien/ctrlp.vim'
Bundle 'scrooloose/nerdcommenter'
Bundle 'Townk/vim-autoclose'
Bundle 'shawncplus/phpcomplete.vim'
Bundle 'davelens/xmledit'
Bundle 'vim-ruby/vim-ruby'
Bundle 'msanders/snipmate.vim'
Bundle 'Dinduks/vim-holylight'
Bundle 'kana/vim-textobj-user'
Bundle 'nelstrom/vim-textobj-rubyblock'
Bundle 'tpope/vim-surround'
Bundle 'tpope/vim-repeat'
Bundle 'tpope/vim-endwise'
Bundle 'tpope/vim-rails'

filetype plugin indent on
syntax on

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
set shiftwidth=2
set softtabstop=2
set tabstop=2
set expandtab

" Whitespace settings for specific types
au FileType php setlocal ts=4 sts=4 sw=4 noexpandtab

" Auto-completion
set wildmode=longest,list,full
set wildmenu
set completeopt=preview,menu,longest
set colorcolumn=80

" Not too long or we drop to a virtual stand still when editing
" large-all-on-one-line-code (like OOo xml files.)
set synmaxcol=512

" Let the backspace behave
set backspace=indent,eol,start whichwrap+=<,>,[,]

" statusline (active file, line+col position, file format+encoding+filetype
set statusline=%-25.25(%<%t\ %m%r\%)line\ %l\ of\ %L\ col\ %c%V\ %=%{&ff},%{strlen(&fenc)?&fenc:''}%Y

" Disable the bloody visual bell
set t_vb=

" Set vim in 256 color-mode
set t_Co=256

" The swapfile directory
set directory=~/.vim/swp

" When editing a file, always jump to the last known cursor position.
au BufReadPost * if line("'\"") > 0 && line("'\"") <= line("$") | exe "normal g`\"" | endif

" Delete trailing whitespaces on saving a file
au BufWritePre * call StripTrailingWhitespace()

" Disable autoclose for ruby files so vim-endwise works again (temp. fix)
autocmd FileType html,xhtml,twig,smarty,ruby,eruby :let g:AutoCloseExpandEnterOn=""

" solarized options
let g:solarized_termtrans = 1
colorscheme solarized


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Various bindings
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Do not exit visual mode when shifting
vnoremap > >gv
vnoremap < <gv

" Hop from method to method.
nmap <c-n> ]]
nmap <c-p> [[

" Copy to/cut/paste from system clipboard
map <C-y> "+y
map <C-x> "+x
map <C-M-p> "+p

" Less finger wrecking window navigation.
nnoremap <c-j> <c-w>j
nnoremap <c-k> <c-w>k
nnoremap <c-h> <c-w>h
nnoremap <c-l> <c-w>l

" Leader bindings
let mapleader = ' '
map <leader>s <ESC>:w<CR>
map <leader>i :call GetVimElementID()<CR>
map <leader>n :call RenameFile()<CR>
map <F5> :set paste<CR>
map <F6> :set nopaste<CR>
nmap <silent> <leader>; :call AppendSemiColon()<CR>

" Filetype-specific mappings
autocmd FileType ruby map <leader>r :A<CR>
autocmd FileType php map <leader>r :! clear && phpunit --colors %<CR>

" Overwrite vim-holylight default of 1kk
let g:holylight_threshold = 800000

" Include matchit on runtime
runtime macros/matchit.vim

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Strips all trailing whitespace, except for the filetypes specified.
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! StripTrailingWhitespace()
    " Don't strip on these filetypes
    if &ft =~ 'markdown\|diff'
        return
    endif
    %s/\s\+$//e
endfunction

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" This shows the vim-ID of an item under the cursor position. This is used
" whilst developing colorschemes.
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! GetVimElementID()
	:echo "hi<" . synIDattr(synID(line("."),col("."),1),"name") . '> trans<'
	   \ . synIDattr(synID(line("."),col("."),0),"name") . "> lo<"
	   \ . synIDattr(synIDtrans(synID(line("."),col("."),1)),"name") . ">"
endfunction

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" AutoComplPop default + Eclim configuration.
" This contains user defined completion for PHP completion with Eclim.
" Note that if you do not have Eclim installed, this obviously won't work.
"
" I modified the example given in the Eclim docs:
" http://eclim.org/vim/code_completion.html#vim-code-completion
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let g:ycm_min_num_of_chars_for_completion = 4
let g:ycm_key_list_select_completion = ['<C-j>', '<C-k>']

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" CtrlP configuration
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let g:ctrlp_map = '<leader>t'
let g:ctrlp_working_path_mode = 0
let g:ctrlp_custom_ignore = {
	\ 'dir':  'frontend\/files$\|\.git$\|\.svn$\|vendor$\|\compiled_templates$\|\app/assets/images$\|tmp\|\public\/uploads$',
	\ }

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" When enabled, upon saving a file this refreshes the browser. I use this in
" a dual monitor setup, with my browser active in the second monitor.
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! SaveAndRefreshFirefox()
	w
	silent exec '!osascript ~/.dotfiles/osx/refresh-firefox.scpt'
	redraw!
endfunction

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

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" For programming languages using a semi colon at the end of statement.
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" If there isn't one, append a semi colon to the end of the current line.
function! AppendSemiColon()
    if getline('.') !~ ';$'
        let save_cursor = getpos('.')
        exec("s/$/;/")
        call setpos('.', save_cursor)
    endif
endfunction
