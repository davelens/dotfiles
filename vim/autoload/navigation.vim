"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Opens alternate files using alt, a CLI tool to help find the "alternate"
" path of a given path. The most prominent example of this is to find
" a related test/spec file in code files.
"
" Dependent on https://github.com/uptech/alt/
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Run a given vim command on the result of alt with a given file path.
function! navigation#alt(path, vim_command)
  let l:alternate = system("alt " . a:path)

  if empty(l:alternate)
    echo "No alternate file for " . a:path . " exists!"
  else
    execute a:vim_command . " " . l:alternate
  endif
endfunction
