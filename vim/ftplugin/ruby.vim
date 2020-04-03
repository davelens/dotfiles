" Indentation and whitespace settings
setlocal smartindent
setlocal cindent
setlocal autoindent
setlocal shiftwidth=2
setlocal softtabstop=2
setlocal tabstop=2
setlocal expandtab
setlocal smarttab

nnoremap <buffer> <leader>a :A<CR>
nnoremap <buffer> <leader>r :R<CR>

" Method definition lookup. Same as <leader>l, but prefixes search string with "def "
nnoremap <expr> <leader>d ':execute rg#run("Rg -t ruby", "def '. expand('<cword>') .'")<CR>'
vnoremap <leader>d "ky:execute rg#run('Rg -t ruby ', "def ". @k)<CR>

" Convert "test = 3" to "let(:test) { 3 }"
nnoremap <leader>p :call refactor#rspec_promote_to_let()<CR>
