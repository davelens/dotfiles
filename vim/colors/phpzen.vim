set background=dark
highlight clear
if exists("syntax on")
	syntax reset
endif
let g:colors_name="phpzen"
hi Normal guifg=#f6f3e8 guibg=#333333
hi Comment guifg=#666666 guibg=NONE
hi Constant guifg=#2ccd00 guibg=NONE
hi String guifg=#d8ff90 guibg=NONE
hi htmlTagName guifg=#a0d7ff guibg=NONE
hi Identifier guifg=#a0d7ff guibg=NONE
hi Statement guifg=#a0d7ff guibg=NONE
hi PreProc guifg=#a0d7ff guibg=NONE
hi Type guifg=#ffffaa guibg=NONE
hi Function guifg=#f6f6f6 guibg=NONE
hi Repeat guifg=#000000 guibg=NONE
hi Operator guifg=#f6f6f6 guibg=NONE
hi Error guibg=#ff0000 guifg=#ffffff
hi TODO guibg=#0011ff guifg=#ffffff
hi link character	constant
hi link number	constant
hi link boolean	constant
hi link Float		Number
hi link Conditional	Repeat
hi link Label		Statement
hi link Keyword	Statement
hi link Exception	Statement
hi link Include	PreProc
hi link Define	PreProc
hi link Macro		PreProc
hi link PreCondit	PreProc
hi link StorageClass	Type
hi link Structure	Type
hi link Typedef	Type
hi link htmlTag	Special
hi link Tag		Special
hi link SpecialChar	Special
hi link Delimiter	Special
hi link SpecialComment Special
hi link Debug		Special