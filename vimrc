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

" Not too long or we drop to a virtual stand still when editing
" large-all-on-one-line-code (like OOo xml files.)
set synmaxcol=512

" Run current testfile through phpunit
autocmd FileType php map <F5> :! clear && phpunit --colors %<cr>

" Let the backspace behave
set backspace=indent,eol,start whichwrap+=<,>,[,]

" statusline (active file, line+col position, file format+encoding+filetype
set statusline=%-25.25(%<%t\ %m%r\%)line\ %l\ of\ %L\ col\ %c%V\ (%p%%)%=%{SyntasticStatuslineFlag()}\ %=%{&ff},%{strlen(&fenc)?&fenc:''}%Y\

" Syntastic should check syntax upon opening files
let g:syntastic_check_on_open=1

" Configure syntastic to provide syntax checks for php and ruby
let g:syntastic_mode_map = { 'mode': 'active',
\ 'active_filetypes': ['ruby', 'php'],
\ 'passive_filetypes': [] }

au FileType xhtml,xml,smarty so ~/.vim/bundle/html-autoclosetag/ftplugin/html_autoclosetag.vim

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

" Disable the bloody visual bell
set t_vb=

" Set vim in 256 color-mode
set t_Co=256

" The swapfile directory
set directory=~/.vim

" Use the railscasts colorscheme for ruby files
autocmd FileType ruby colorscheme railscasts
autocmd FileType eruby colorscheme railscasts

" When editing a file, always jump to the last known cursor position.
autocmd BufReadPost * if line("'\"") > 0 && line("'\"") <= line("$") | exe "normal g`\"" | endif

" Delete trailing whitespaces on saving a file
autocmd BufWritePre * :%s/\s\+$//e

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" AutoComplPop default + Eclim configuration.
" This contains user defined completion for PHP completion with Eclim.
" Note that if you do not have Eclim installed, this obviously won't work.
"
" I modified the example given in the Eclim docs:
" http://eclim.org/vim/code_completion.html#vim-code-completion
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" AutoComplPop setting to trigger default autocompletion after 4 typed, matching chars
let g:acp_behaviorKeywordLength = 4

let g:acp_behaviorPHPEclimLength = 4
let g:acp_behavior = {
    \ 'php': [
		\{
			\ 'meets'			: 'AutocompletePHPEclim',
			\ 'command'			: "\<c-x>\<c-u>",
			\ 'completefunc'	: 'eclim#php#complete#CodeComplete'
		\},
		\{
			\ 'meets'			: "AutocompletePHPKeywords",
			\ 'command'			: "\<c-x>\<c-p>",
			\ 'repeat'			: 0
		\}
	\]
\}

" This gives eclipse completion on $var-> and class::
function! AutocompletePHPEclim(context)
	if(a:context =~ '\k->\k\{0,}$' || a:context =~ '\(self\|parent\)::\k\{0,}$')
		return 1
	else
		return g:acp_behaviorPHPEclimLength >= 0 && (a:context =~ '\k::\k\{' . g:acp_behaviorPHPEclimLength . ',}$')
	endif
endfunction

" This providedes buffer completion on regular keywords/variables
function! AutocompletePHPKeywords(context)
	if(a:context =~ '\k\{' . g:acp_behaviorKeywordLength . ',}$')
		return 1
	endif
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" CtrlP configuration
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let g:ctrlp_map = '<leader>t'

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" When enabled, upon saving a file this refreshes the browser
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! SaveAndRefreshFirefox()
	w
	silent exec '!osascript ~/.dotfiles/osx/refresh-firefox.scpt'
	redraw!
endfunction

map <leader>w :call SaveAndRefreshFirefox()<cr>

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

autocmd FileType c,cc,cpp,css,java,javascript,lex,perl,php,sql,y
    \ nmap <silent> <Leader>; :call AppendSemiColon()<cr>


" Syntax coloring
colorscheme zenburn
syntax on
