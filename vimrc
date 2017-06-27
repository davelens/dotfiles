set nocompatible
filetype off

set rtp+=~/.vim/bundle/vundle/
call vundle#rc()

Plugin 'sjl/vitality.vim'
Plugin 'altercation/vim-colors-solarized'
Plugin 'Valloric/YouCompleteMe'
Plugin 'kien/ctrlp.vim'
Plugin 'scrooloose/nerdcommenter'
Plugin 'Townk/vim-autoclose'
Plugin 'shawncplus/phpcomplete.vim'
Plugin 'Dinduks/vim-holylight'
Plugin 'kana/vim-textobj-user'
Plugin 'nelstrom/vim-textobj-rubyblock'
Plugin 'tpope/vim-surround'
Plugin 'tpope/vim-repeat'
Plugin 'tpope/vim-endwise'
Plugin 'tpope/vim-rails'
Plugin 'tpope/vim-fugitive'
Plugin 'MarcWeber/vim-addon-mw-utils' " Snipmate dependency
Plugin 'tomtom/tlib_vim' " Snipmate dependency
Plugin 'garbas/vim-snipmate'
Plugin 'osyo-manga/vim-monster'
Plugin 'alvan/vim-closetag'
Plugin 'vim-airline/vim-airline'
Plugin 'vim-airline/vim-airline-themes'
Plugin 'mileszs/apidock.vim'
Plugin 'elixir-lang/vim-elixir'
Plugin 'kchmck/vim-coffee-script'

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
set smarttab

" Whitespace settings for specific types
au FileType php setlocal ts=2 sts=2 sw=2 noexpandtab

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

" Make Vim able to correctly edit crontabs without tempfile errors.
" More info: http://calebthompson.io/crontab-and-vim-sitting-in-a-tree
autocmd filetype crontab setlocal nobackup nowritebackup

" solarized options
let g:solarized_termtrans = 1
colorscheme solarized
set background=dark
" solarized comes with a toggle-background method.
call togglebg#map("<F4>")

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

" Giving this a go; ESC remapping in insert mode.
" Less finger wrecking than C-[, and rare enough not to obstruct while typing.
inoremap jk <Esc>

" Easy paste/nopaste
map <F5> :set paste<CR>
map <F6> :set nopaste<CR>

" Leader bindings
let mapleader = ' '
map <leader>s <ESC>:w<CR>
map <leader>i :call GetVimElementID()<CR>
map <leader>n :call RenameFile()<CR>
map <leader>f :call TestCurrentLine()<CR>
nmap <silent> <leader>; :call AppendSemiColon()<CR>
map <leader>g :call OpenGem()<CR>

" Filetype-specific mappings
autocmd FileType ruby map <leader>r :A<CR>
autocmd FileType php map <leader>r :! clear && phpunit --colors %<CR>

" Include matchit on runtime
runtime macros/matchit.vim

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Runs bin/rspec on the current line.
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! TestCurrentLine()
  let spec_line_number = line('.')
  if filereadable('spec/dummy/bin/rspec')
    exec ":!clear && spec/dummy/bin/rspec %:" . spec_line_number
  else
    exec ":!clear && bin/rspec %:" . spec_line_number
  endif
endfunction
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
" YouCompleteMe / Eclim configuration
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let g:EclimCompletionMethod = 'omnifunc'
let g:ycm_min_num_of_chars_for_completion = 4
" C-P and C-N still work when emptying these, so why not?
" Considering another plugin can have conflicting bindings, this is a sane setting.
let g:ycm_key_list_select_completion=[]
let g:ycm_key_list_previous_completion=[]

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" CtrlP configuration
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let g:ctrlp_map = '<leader>t'
let g:ctrlp_working_path_mode = 0
let g:ctrlp_custom_ignore = {
      \ 'dir': 'frontend/files$\|\.git$\|\.svn$\|compiled_templates$\|app/assets/images$\|tmp\|public/uploads$\|node_modules$\|_build$\|deps$\|priv/static$',
      \ }

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" closetag.vim configuration
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let g:closetag_filenames = "*.html,*.xhtml,*.html.erb,*.tpl"

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
" vim-airline configuration
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" allows airline to use the powerline font symbols through a patched font
let g:airline_powerline_fonts = 1

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" apidock.vim configuration
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" This change allows existing links to open in the default browser
let g:browser = 'open'

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

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Opens the specified gem's source code
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! OpenGem()
  let gem = input('Open which gem?: ')
  if gem != ''
    exec ':e `bundle show '. gem .'`'
    exec ':lcd %:p:h'
  endif
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Opens a split for each dirty file in git
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! OpenChangedFiles()
  only " Close all windows, unless they're modified
  let status = system('git status -s | grep "^ \?\(M\|A\|UU\)" | sed "s/^.\{3\}//"')
  let filenames = split(status, "\n")
  exec "edit " . filenames[0]
  for filename in filenames[1:]
    exec "sp " . filename
  endfor
endfunction
command! OpenChangedFiles :call OpenChangedFiles()

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" EXTRACT VARIABLE (SKETCHY)
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! ExtractVariable()
    let name = input("Variable name: ")
    if name == ''
        return
    endif
    " Enter visual mode (not sure why this is needed since we're already in
    " visual mode anyway)
    normal! gv

    " Replace selected text with the variable name
    exec "normal c" . name
    " Define the variable on the line above
    exec "normal! O" . name . " = "
    " Paste the original selected text to be the variable value
    normal! $p
endfunction
vnoremap <leader>rv :call ExtractVariable()<cr>

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Resizes the focused window to a ratio of your choice.
" The first argument determines the size you want your focused window to be.
" The second argument lets you choose to set it for horizontal or vertical
" splits.
"
" Example: AutoResizeWindowOnFocus(6, 'v') will resize in a ratio of 60/40,
" while AutoResizeWindowOnFocus(7, 'v') will resize in a ratio of 70/30.
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! AutoResizeWindowOnFocus(ratio, axis)
  if a:axis == 'h'
    let &winheight = &lines * a:ratio / 10
  else
    let &winwidth = &columns * a:ratio / 10
  end
endfunction
