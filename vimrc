" Map CTRL+e and CTRL+a to respectively jump to end and start of line
imap <C-e> <esc>$i<right>
imap <C-a> <esc>0i

" enable Pathogen plugin manager
call pathogen#infect()

syntax on

filetype plugin indent on
