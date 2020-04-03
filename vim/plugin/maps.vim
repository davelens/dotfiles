" vim {
  " My thumbs never leave <Space> when typing, so it seems like the best choice.
  let mapleader = ' '

  " solarized comes with a toggle-background method.
  call togglebg#map("<F4>")

  " Giving this a go; ESC remapping in insert mode.
  " Less finger wrecking than C-[, and rare enough not to obstruct while typing.
  inoremap jk <Esc>
  nnoremap <leader>s <Esc>:w<CR>
  nnoremap <leader>x <Esc>:q!<CR>

  " Do not exit visual mode when shifting
  vnoremap > >gv
  vnoremap < <gv

  " Copy to/cut/paste from system clipboard
  map <C-y> "+y
  map <C-x> "+x
  map <C-M-p> "+p

  " Hop from method to method.
  nnoremap <c-n> ]]
  nnoremap <c-p> [[

  " Less finger wrecking window navigation.
  nnoremap <c-j> <c-w>j
  nnoremap <c-k> <c-w>k
  nnoremap <c-h> <c-w>h
  nnoremap <c-l> <c-w>l

  " Toggles search highlighting
  nnoremap <F3> :set hlsearch!<CR>
  " Easy paste/nopaste
  nnoremap <F5> :set paste<CR>
  nnoremap <F6> :set nopaste<CR>

  " Pretty format messy json files
  nnoremap <leader>json <Esc>:%!python -m json.tool<CR>

  " Underline current line
  nnoremap <Leader>= yypVr=
  nnoremap <Leader>- yypVr-

  " Buffer maps
  nnoremap <leader>n :call buffers#rename_file()<CR>
  nnoremap <silent> <leader>; :call buffers#append_semicolon()<CR>

  " Refactoring
  nnoremap <leader>iv :call refactor#inline_variable()<CR>
  vnoremap <leader>ev :call refactor#extract_variable()<CR>

  " Leader bindings
  nnoremap <leader>id :call buffers#get_vim_element_id()<CR>
"}

" (neo)vim's terminal {
  " The way into :terminal
  nnoremap <leader>b :Terminal<CR>
  " The way out of :terminal's insert mode.
  tnoremap <silent> <C-[> <C-\><C-n>
  " The way out of :terminal while in insert mode.
  tnoremap <leader>x <C-\><C-n>:q!<CR>
"}

" Custom text objects {
  " This enables stuff like like ci/, va*, di: and so on.
  " https://stackoverflow.com/questions/44108563/how-to-delete-or-yank-inside-slashes-and-asterisks/44109750#44109750
  " Thanks @romainl!
  for char in [ '_', '.', ':', ',', ';', '<bar>', '/', '<bslash>', '*', '+', '%', '-', '#' ]
    execute 'xnoremap i' . char . ' :<C-u>normal! T' . char . 'vt' . char . '<CR>'
    execute 'onoremap i' . char . ' :normal vi' . char . '<CR>'
    execute 'xnoremap a' . char . ' :<C-u>normal! F' . char . 'vf' . char . '<CR>'
    execute 'onoremap a' . char . ' :normal va' . char . '<CR>'
  endfor
"}

" fzf {
  if filereadable('.gitignore')
    nnoremap <leader>t :GFiles --cached --others --exclude-standard<CR>
  else
    nnoremap <leader>t :FZF<CR>
  endif
"}

" vim-test / vim-dispatch {
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

" ALE {
  nnoremap <leader>a<CR> :ALEFix<CR>
  " ALE feedback navigation for errors/warnings
  nnoremap <Leader>aj :ALENextWrap<CR>
  nnoremap <Leader>ak :ALEPreviousWrap<CR>
"}

" quickfix {
  " Performs a search/replace on the file positions in the active quickfix
  " window. Will fall back to a regular %s// when the quickfix is empty.
  " @k is set when calling a map using the rg#run method (like <leader>l)
  nnoremap <leader>sr :call quickfix#search_replace(@k)<CR>
"}

" Rg {
  " Rg searches for occurrences of the word under the cursor or a block selection.
  nnoremap <expr> <leader>l ':execute rg#run("Rg", "'. expand('<cword>') .'")<CR>'
  nnoremap <expr> <leader>L ':execute rg#run("Rg!", "'. expand('<cword>') .'")<CR>'
  vnoremap <leader>l "ky:execute rg#run('Rg', @k)<CR>
  vnoremap <leader>L "ky:execute rg#run('Rg!', @k)<CR>
  " I'm not sure how I can make a bang variant without repeating myself.
  " I'm guessing command! with <bang> and then map the command to the keys? :s
"}
