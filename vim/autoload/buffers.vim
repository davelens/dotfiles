" Strips all trailing whitespace (including blank lines), except for the
" filetypes specified.  I know ALE has fixers for removal of trailing lines +
" whitespace, but I don't know how to let it work on all filetypes except
" markdown.
function! buffers#strip_trailing_whitespace()
  if &ft =~ 'markdown\|diff' " Don't strip on these filetypes
    return
  endif
  %s/\s\+$//e
  %s/\($\n\s*\)\+\%$//e
endfunction

" Rename the current file in your buffer.
function! buffers#rename_file()
  let old_name = expand('%')
  let new_name = input('New file name: ', expand('%'))
  if new_name != '' && new_name != old_name
    execute ':saveas ' . new_name
    execute ':silent !rm ' . old_name
    redraw!
  endif
endfunction

" For programming languages using a semi colon at the end of statement.
" If there isn't one, append a semi colon to the end of the current line.
" Thanks @dubgeiser!
function! buffers#append_semicolon()
  if getline('.') !~ ';$'
    let save_cursor = getpos('.')
    execute("s/$/;/")
    call setpos('.', save_cursor)
  endif
endfunction

" Clean up and wipeout all hidden buffers.
function buffers#delete_hidden()
  let tpbl=[]
  call map(range(1, tabpagenr('$')), 'extend(tpbl, tabpagebuflist(v:val))')
  for buf in filter(range(1, bufnr('$')), 'bufexists(v:val) && index(tpbl, v:val)==-1')
      silent execute 'bwipeout' buf
  endfor
endfunction

" This shows the vim-ID of an item under the cursor position. This is used
" whilst developing colorschemes.
function! buffers#get_vim_element_id()
  :echo "hi<" . synIDattr(synID(line("."),col("."),1),"name") . '> trans<'
        \ . synIDattr(synID(line("."),col("."),0),"name") . "> lo<"
        \ . synIDattr(synIDtrans(synID(line("."),col("."),1)),"name") . ">"
endfunction
