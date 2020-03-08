set nocompatible

" Automatic install of vim-plug
if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin('~/.vim/bundle')
Plug 'adelarsq/vim-matchit'
Plug 'sjl/vitality.vim'
Plug 'altercation/vim-colors-solarized'
Plug 'scrooloose/nerdcommenter'
Plug 'jiangmiao/auto-pairs'
Plug 'kana/vim-textobj-user'
Plug 'nelstrom/vim-textobj-rubyblock'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-repeat'
Plug 'tpope/vim-endwise'
Plug 'tpope/vim-rails'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-dispatch'
Plug 'elixir-editors/vim-elixir'
Plug 'slashmili/alchemist.vim' " Autocompletion for elixir projects
Plug 'MarcWeber/vim-addon-mw-utils' " Snipmate dependency
Plug 'tomtom/tlib_vim' " Snipmate dependency
Plug 'garbas/vim-snipmate'
Plug 'alvan/vim-closetag'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'dense-analysis/ale'
Plug 'junegunn/fzf.vim'

if has('nvim')
  Plug 'neoclide/coc.nvim', {'branch': 'release'}
else
  Plug 'Valloric/YouCompleteMe'
endif

if has('mac')
  Plug '/usr/local/opt/fzf'
elseif has('unix')
  Plug '~/.linuxbrew/opt/fzf'
endif

call plug#end()

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
set completeopt=menu,longest
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

" Close preview windows after autocomplete automatically
au CompleteDone * pclose

" Disable autoclose for ruby files so vim-endwise works again (temp. fix)
au FileType html,xhtml,twig,smarty,ruby,eruby :let g:AutoCloseExpandEnterOn=""

" Make Vim able to correctly edit crontabs without tempfile errors.
" More info: http://calebthompson.io/crontab-and-vim-sitting-in-a-tree
au FileType crontab setlocal nobackup nowritebackup

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

" ALE feedback navigation for errors/warnings
"nmap <silent> <C-k> <Plug>(ale_previous_wrap)
"nmap <silent> <C-j> <Plug>(ale_next_wrap)

" Giving this a go; ESC remapping in insert mode.
" Less finger wrecking than C-[, and rare enough not to obstruct while typing.
inoremap jk <Esc>

" Toggles search highlighting
nnoremap <F3> :set hlsearch!<CR>
" Easy paste/nopaste
nnoremap <F5> :set paste<CR>
nnoremap <F6> :set nopaste<CR>

" Leader bindings
let mapleader = ' '
map <leader>s <ESC>:w<CR>
map <leader>id :call GetVimElementID()<CR>
map <leader>n :call RenameFile()<CR>
map <leader>json <Esc>:%!python -m json.tool<CR>
nmap <silent> <leader>; :call AppendSemiColon()<CR>

" Filetype-specific mappings
au FileType ruby map <leader>r :call AltCommand(expand('%'), ':e')<CR>
au FileType ruby map <leader>g :call OpenGem()<CR>
au FileType elixir map <leader>r :call AltCommand(expand('%'), ':e')<cr>

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Opens alternate files using alt, a CLI tool to help find the "alternate"
" path of a given path. The most prominent example of this is to find
" a related test/spec file in code files.
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Run a given vim command on the results of alt from a given path.
" See usage below.
function! AltCommand(path, vim_command)
  let l:alternate = system("alt " . a:path)
  if empty(l:alternate)
    echo "No alternate file for " . a:path . " exists!"
  else
    exec a:vim_command . " " . l:alternate
  endif
endfunction

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Quickfix operations
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
nnoremap ]q :cprev<CR>
nnoremap [q :cnext<CR>

function! QSearchAndReplace(string)
  let old_value = escape(a:string, '<>[]?.')
  let new_value = input('Replace '. shellescape(old_value) .' with: ')
  cdo exe '%s/'.old_value.'/'.new_value.'/gc'
  ccl
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
  %s/\($\n\s*\)\+\%$//e
endfunction

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Global replacement of camelcase to snakecase.
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! ConvertCamelCaseToSnakeCase()
  let save_cursor = getpos('.')
    %s#\C\(\<\u[a-z0-9]\+\|[a-z0-9]\+\)\(\u\)#\l\1_\l\2#g
  call setpos('.', save_cursor)
endfunction
nnoremap <leader>_ :call ConvertCamelCaseToSnakeCase()<cr>

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
" YouCompleteMe configuration
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let g:ycm_min_num_of_chars_for_completion = 4
" C-P and C-N still work when emptying these, so why not?
" Considering another plugin can have conflicting bindings, this is a sane setting.
let g:ycm_key_list_select_completion=[]
let g:ycm_key_list_previous_completion=[]

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Rg configuration
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Use a preview window for searches made with ripgrep.
" I do NOT use shellescape() around q-args because I want arguments like -t
" to keep working as well.
command! -bang -nargs=* Rg
    \ call fzf#vim#grep(
    \   'rg --column --line-number --no-heading --color=always --smart-case '.<q-args>, 1,
    \   <bang>0 ? fzf#vim#with_preview('right:50%')
    \     : fzf#vim#with_preview('up:40%', '?'),
    \   <bang>0)

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" FZF configuration
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let g:fzf_action = {
  \ 'ctrl-t': 'tab split',
  \ 'ctrl-s': 'split',
  \ 'ctrl-v': 'vsplit' }

if filereadable('.gitignore')
  nnoremap <leader>t :GFiles --cached --others --exclude-standard<cr>
else
  nnoremap <leader>t :FZF<cr>
endif

"*****************
" FZF + Rg queries
"*****************

" Quickfix maps to be used in conjunction with Rg queries.
nmap <leader>k :call RgSearchAndReplace(@k)<CR>

" Lookup occurrences of the word under the cursor when pressing F8.
nnoremap <expr> <leader>l ':Rg '. expand('<cword>') .'<CR>'
vnoremap <leader>l "ky:exec SavePositionAndRg('Rg', @k)<CR>
vnoremap <leader>k "ky:exec SavePositionAndRg('Rg!', @k)<CR>

function! SanitizeRgArgument(string)
  return shellescape(escape(a:string, '()[]{}?.'))
endfunction

function! SavePositionAndRg(cmd, string)
  call setreg('l', expand('%'))
  call setreg('p', getpos('.'))

  exe a:cmd .' '. SanitizeRgArgument(a:string)
endfunction

function! RgSearchAndReplace(string)
  call QSearchAndReplace(a:string)

  if @l != ''
    exe 'b '. @l
    call setpos('.', @p)
  endif
endfunction

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
  silent exec '!osascript ~/.dotfiles/macos/refresh-firefox.scpt'
  redraw!
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" ALE configuration
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let g:ale_fixers = {
\   'javascript': ['eslint'],
\   'ruby': ['rubocop']
\}

nmap <leader><CR> <Plug>(ale_fix)

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" vim-airline configuration
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Automatic download of our Powerline font for vim-airline
if has('mac') && empty(glob('~/Library/Fonts/DroidSansMonoForPowerlineNerdFontComplete.otf'))
  silent exe '! curl -fLo ~/Library/Fonts/DroidSansMonoForPowerlineNerdFontComplete.otf '. shellescape('https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/DroidSansMono/complete/Droid%20Sans%20Mono%20Nerd%20Font%20Complete.otf', 1)
endif

" allows airline to use the powerline font symbols through a patched font
let g:airline_powerline_fonts = 1
let g:airline#extensions#coc#enabled = 1

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

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" PROMOTE VARIABLE TO RSPEC LET
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! PromoteToLet()
  :normal! dd
  " :exec '?^\s*it\>'
  :normal! P
  :.s/\(\w\+\) = \(.*\)$/let(:\1) { \2 }/
  :normal ==
endfunction
:command! PromoteToLet :call PromoteToLet()
:map <leader>p :PromoteToLet<cr>

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
" INLINE VARIABLE (SKETCHY)
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! InlineVariable()
    " Copy the variable under the cursor into the 'a' register
    :let l:tmp_a = @a
    :normal "ayiw
    " Delete variable and equals sign
    :normal 2daW
    " Delete the expression into the 'b' register
    :let l:tmp_b = @b
    :normal "bd$
    " Delete the remnants of the line
    :normal dd
    " Go to the end of the previous line so we can start our search for the
    " usage of the variable to replace. Doing '0' instead of 'k$' doesn't
    " work; I'm not sure why.
    normal k$
    " Find the next occurence of the variable
    exec '/\<' . @a . '\>'
    " Replace that occurence with the text we yanked
    exec ':.s/\<' . @a . '\>/' . escape(@b, "/")
    :let @a = l:tmp_a
    :let @b = l:tmp_b
endfunction
nnoremap <leader>iv :call InlineVariable()<cr>

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
vnoremap <leader>ev :call ExtractVariable()<cr>

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

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Running tests. Original code for Ruby taken from Gary Bernhardt, and slightly
" modified to support running tests in Rails engine projects and Elixir.
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
nnoremap <cr> :call RunTestFile()<cr>
nnoremap <leader>f :call RunNearestTest()<cr>
nnoremap <leader>T :call RunTests('')<cr>

function! RunTestFile(...)
  if a:0
    let command_suffix = a:1
  else
    let command_suffix = ""
  endif

  " If we're in a test/spec file, remember the filename. Otherwise, if no prior
  " tests have run, exit early.
  if match(expand("%"), '\(.feature\|_spec.rb\|.go\|_test.exs\)$') != -1
    echo command_suffix
    call SetTestFile(command_suffix)
  elseif !exists("t:grb_test_file")
    return
  end
  call RunTests(t:grb_test_file)
endfunction

function! RunNearestTest()
  let spec_line_number = line('.')
  call RunTestFile(":" . spec_line_number)
endfunction

function! SetTestFile(command_suffix)
  " Set the spec file that tests will be run for.
  let t:grb_test_file=@% . a:command_suffix
endfunction

function! RunTests(filename)
  " Write the file and run tests for the given filename
  if expand("%") != ""
    :silent! w
  end

  if &filetype == 'ruby' || &filetype == 'eruby'
    call RunRubyTests(a:filename)
  elseif &filetype == 'elixir'
    if a:filename == ''
      :!mix test
      return
    endif

    exec ":Dispatch mix test " . a:filename
  endif
endfunction

function! RubyTestCommand()
  if filereadable('spec/dummy/bin/rspec')
    return 'bin/spring stop && spec/dummy/bin/rspec'
  elseif filereadable('bin/rspec')
    return 'bin/rspec'
  elseif filereadable('Gemfile') && filereadable('bin/bundle')
    return 'bin/bundle exec rspec'
  elseif filereadable('Gemfile')
    return 'bundle exec rspec'
  else
    return 'rspec'
  endif
endfunction

function! RunRubyTests(filename)
  "let t:ruby_test_command=@ . RubyTestCommand()
  if a:filename == ''
    exe "silent !tmux send -t 5 '" . RubyTestCommand() . " " . a:filename . "' Enter"
  else
    exe "!" . RubyTestCommand() . " " . a:filename
  end
endfunction
