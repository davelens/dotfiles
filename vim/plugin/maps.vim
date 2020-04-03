nnoremap <leader><CR> <Plug>(ale_fix)

" Performs a search/replace on the file positions in the active quickfix
" window. Will fall back to a regular %s// when the quickfix is empty.
" @k is set when calling a map using the rg#run method (like <leader>l)
nnoremap <leader>sr :call quickfix#search_replace(@k)<CR>

" Rg searches for occurrences of the word under the cursor or a block selection.
nnoremap <expr> <leader>l ':execute rg#run("Rg", "'. expand('<cword>') .'")<CR>'
nnoremap <expr> <leader>L ':execute rg#run("Rg!", "'. expand('<cword>') .'")<CR>'
vnoremap <leader>l "ky:execute rg#run('Rg', @k)<CR>
vnoremap <leader>L "ky:execute rg#run('Rg!', @k)<CR>
" I'm not sure how I can make a bang variant without repeating myself.
" I'm guessing command! with <bang> and then map the command to the keys? :s
