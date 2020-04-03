function rg#sanitize_argument(string) abort
  return shellescape(escape(a:string, '()[]{}?.$'))
endfunction

function rg#run(cmd, query) abort
  call cursor#remember_position()
  execute a:cmd .' '. rg#sanitize_argument(a:query)
endfunction
