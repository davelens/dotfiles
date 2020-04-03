function quickfix#search_replace(string) abort
  let old_value = escape(a:string, '/')
  let new_value = escape(input('Replace '. shellescape(a:string) .' with: '), '/')

  if getqflist() != []
    cdo execute '%s/'.old_value.'/'.new_value.'/gc'
    cexpr [] " empty the quickfix list to prevent future replacement mishaps.
  else " because cdo does nothing when the quickfix list is empty
    execute '%s/'.old_value.'/'.new_value.'/gc'
  end

  wa
  ccl

  call cursor#restore_position()
endfunction
