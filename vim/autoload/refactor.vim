function refactor#rspec_promote_to_let() abort
  :normal! dd
  " :execute '?^\s*it\>'
  :normal! P
  :.s/\(\w\+\) = \(.*\)$/let(:\1) { \2 }/
  :normal ==
endfunction

" Taken from Gary Bernhardt's dotfiles.
" TODO: Possibly obsolete with ALE. Review.
function! refactor#inline_variable()
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
  execute '/\<' . @a . '\>'
  " Replace that occurence with the text we yanked
  execute ':.s/\<' . @a . '\>/' . escape(@b, "/")
  :let @a = l:tmp_a
  :let @b = l:tmp_b
endfunction

" Taken from Gary Bernhardt's dotfiles.
" TODO: Possibly obsolete with ALE. Review.
function! refactor#extract_variable()
  let name = input("Variable name: ")
  if name == ''
      return
  endif
  " Enter visual mode (not sure why this is needed since we're already in
  " visual mode anyway)
  normal! gv

  " Replace selected text with the variable name
  execute "normal c" . name
  " Define the variable on the line above
  execute "normal! O" . name . " = "
  " Paste the original selected text to be the variable value
  normal! $p
endfunction
