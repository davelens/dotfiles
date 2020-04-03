" vim-airline {
  " Automatic download of our Powerline font for vim-airline
  if has('mac') && empty(glob('~/Library/Fonts/DroidSansMonoForPowerlineNerdFontComplete.otf'))
    silent execute '! curl -fLo ~/Library/Fonts/DroidSansMonoForPowerlineNerdFontComplete.otf '. shellescape('https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/DroidSansMono/complete/Droid%20Sans%20Mono%20Nerd%20Font%20Complete.otf', 1)
  endif

  " allows airline to use the powerline font symbols through a patched font
  let g:airline_powerline_fonts = 1
  let g:airline#extensions#coc#enabled = 1
"}

" YouCompleteMe {
  let g:ycm_min_num_of_chars_for_completion = 4
  " C-P and C-N still work when emptying these, so why not?
  " Considering another plugin can have conflicting bindings, this is a sane setting.
  let g:ycm_key_list_select_completion=[]
  let g:ycm_key_list_previous_completion=[]
"}

" fzf {
  let g:fzf_action = {
    \ 'ctrl-s': 'split',
    \ 'ctrl-v': 'vsplit' }

  if filereadable('.gitignore')
    nnoremap <leader>t :GFiles --cached --others --exclude-standard<CR>
  else
    nnoremap <leader>t :FZF<CR>
  endif
"}

" ALE {
  let g:ale_fixers = {
  \   'javascript': ['eslint'],
  \   'ruby': ['rubocop']
  \}
"}

" Rg {
  " Use a preview window for searches made with ripgrep.
  " I do NOT use shellescape() around q-args because I want arguments like -t
  " to keep working as well.
  command! -bang -nargs=* Rg
    \ call fzf#vim#grep(
    \   'rg --column --line-number --no-heading --color=always --smart-case '.<q-args>, 1,
    \   <bang>0 ? fzf#vim#with_preview('right:50%')
    \     : fzf#vim#with_preview('up:40%', '?'),
    \   <bang>0)
"}

" vim-test / vim-dispatch {
  " strategies per granularity
  let test#strategy = {
    \ 'nearest': 'neovim',
    \ 'file':    'dispatch'
  \}

  " :TestFile mapping to Enter, with a fix for Enter in command-line mode.
  augroup conserve_cr_in_cli_mode
    au!
    " Reserves <CR> for running a file spec in any buffer with a defined FileType.
    au FileType * nnoremap <buffer> <CR> :TestFile<CR>
    " Unmaps <CR> when entering Command-Line Mode. Includes terminals.
    " This way I can keep using <CR> in q:
    au FileType vim silent! nunmap <buffer> <CR>
  augroup END

  " :TestSuite is cool, but it runs bin/rspec by default for all granularities.
  " I can't seem to figure out how to let nearest/file run bin/rspec, but have
  " the suite granularity run the more 'complete' `bundle exec rspec` to make up
  " for bad juju.
  "
  " Thankfully, vim-dispatch's :Make! ticks all my boxes:
  " [x] Performs a background dispatch
  " [x] Fills my quickfix with the triggered errors
  " [x] Does not use Spring, great for a clean test run.
  nnoremap <leader>T :Make!<CR>
  nnoremap <leader>f :TestNearest<CR>
"}

" Rails projections to be used with vim-{rails,projectionist} {
  let g:rails_gem_projections = {
  \  "factory_bot": {
  \    "spec/factories/*.rb": {
  \      "command":   "factory",
  \      "affinity":  "collection",
  \      "alternate": "app/models/{singular}.rb",
  \      "related":   "db/schema.rb#{}",
  \      "test":      "spec/models/{singular}_spec.rb",
  \      "template":  "FactoryBot.define do\n  factory :{singular} do\n  end\nend",
  \      "keywords":  "factory sequence"
  \    }
  \  },
  \  "draper": {
  \    "app/decorators/*_decorator.rb": {
  \      "command":   "decorator",
  \      "affinity":  "model",
  \      "test":      "spec/decorators/{}_spec.rb",
  \      "related":   "app/models/{}.rb",
  \      "template":  "class {camelcase|capitalize|colons}Decorator < Draper::Decorator\n  delegate_all\nend"
  \    }
  \  },
  \}
"}
