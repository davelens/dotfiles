set nocompatible " No one fully knows the dark magic made by this setting.

" Automatic install of vim-plug
if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin('~/.vim/bundle')
" Structured and colored vim status bar
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'

" These provide the `r` block motion in Ruby files.
Plug 'adelarsq/vim-matchit' " extended matching for %
Plug 'kana/vim-textobj-user' " allows for custom text object definitions
Plug 'nelstrom/vim-textobj-rubyblock'

" Snippets. # TODO: Replace all three with UltiSnips
Plug 'MarcWeber/vim-addon-mw-utils' " Snipmate dependency
Plug 'tomtom/tlib_vim' " Snipmate dependency
Plug 'garbas/vim-snipmate'

Plug 'sjl/vitality.vim' " FocusLost and FocusGained support
Plug 'altercation/vim-colors-solarized' " Pretty colors
Plug 'dense-analysis/ale' " Syntax checking, linting, refactoring through LSP
Plug 'preservim/nerdcommenter' " Comment toggles
Plug 'jiangmiao/auto-pairs' " Smart brackets, parens and quotes
Plug 'tpope/vim-surround' " Maps to manipulate brackets, parens, quotes,..
Plug 'tpope/vim-repeat' " Extended repeat functionality through `.`
Plug 'tpope/vim-endwise' " Smart end structures for blocks
Plug 'tpope/vim-rails' " Pandora's box with Rails workflow features
Plug 'tpope/vim-fugitive' " Git wrapper for vim
Plug 'tpope/vim-dispatch' " Async testing toolkit
Plug 'tpope/vim-bundler' " Maps to help browse gem source code
Plug 'tpope/vim-abolish' " Case coercions and language corrections
Plug 'tpope/vim-unimpaired' " Complementary maps for quickfix, lists, options
Plug 'elixir-editors/vim-elixir' " Pandora's box with Elixir workflow features
Plug 'slashmili/alchemist.vim' " Intellisense autocompletion for Elixir
Plug 'alvan/vim-closetag' " vim-endwise for HTML
Plug 'junegunn/fzf.vim' " Command-line fuzzy finder
Plug 'janko/vim-test' " Generic, configurable test-wrapper
Plug 'airblade/vim-localorie' " Maps and functions for Rails I18n interaction

if has('nvim')
  Plug 'neoclide/coc.nvim', {'branch': 'release'} " Intellisense autocompletion
else
  Plug 'Valloric/YouCompleteMe' " Buffer autocompletion
endif

" Adds the correct fzf binary to RTP
if has('mac')
  Plug '/usr/local/opt/fzf'
elseif has('unix')
  Plug '/home/linuxbrew/.linuxbrew/opt/fzf'
endif
call plug#end()

set hidden " Keeps buffers in the background when left behind.
set autowrite " Write file contents for writable buffers
set autoread " Load in changes made from *outside* vim.
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
set backspace=indent,eol,start whichwrap+=<,>,[,]
set directory=~/.vim/swp " The swapfile directory

" Indentation and whitespace defaults
set smartindent
set cindent
set autoindent
set shiftwidth=2
set softtabstop=2
set tabstop=2
set expandtab
set smarttab

" Auto-completion
set wildmode=longest,list,full
set wildmenu
set completeopt=menu,longest
set colorcolumn=80

if has('nvim')
  set icm=split " Enables real-time substitute previews. Nvim only.
endif

" The number of chars before syntax coloring fucks off.
" Setting this too high slows down files with a single, long line of code.
" (compiled js files, xml files,...)
set synmaxcol=512

" statusline: active file, line+col position, file format+encoding+filetype
" I'm using vim-airline, this is here as a fallback if for whatever reason I
" can't use plugins.
set statusline=%-25.25(%<%t\ %m%r\%)line\ %l\ of\ %L\ col\ %c%V\ %=%{&ff},%{strlen(&fenc)?&fenc:''}%Y
set t_vb= " Disable the bloody visual bell
set t_Co=256 " Set vim in 256 color-mode

" solarized options
let g:solarized_termtrans = 1
colorscheme solarized
set background=dark

" My thumbs never leave <Space> when typing, so it seems like the best choice.
let mapleader = ' '
