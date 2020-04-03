function cursor#remember_position() abort
  call setreg('l', expand('%')) " location
  call setreg('p', getpos('.')) " position
endfunction

function cursor#restore_position() abort
  if @l != '' && @p != ''
    execute 'b '. @l
    call setpos('.', @p)
  end
endfunction
