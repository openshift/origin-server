" Some basic vim options to make it work better
set nocompatible
syntax on
filetype on
filetype plugin indent on

" Set tabbing options
autocmd FileType ruby,yaml setlocal expandtab autoindent shiftwidth=2 softtabstop=2
autocmd BufRead,BufNewFile *.pp setlocal tabstop=4 shiftwidth=4 expandtab list listchars=tab:>-,trail:.,extends:>
" Trim trailing whitespace from Ruby and Yaml files
autocmd BufWritePre *.rb,*.yml,*.yaml :%s/\s\+$//e

"flag problematic whitespace (trailing and spaces before tabs)
"Note you get the same by doing let c_space_errors=1 but
"this rule really applies to everything.
highlight RedundantSpaces term=standout ctermbg=red guibg=red
match RedundantSpaces /\s\+$\| \+\ze\t/ "\ze sets end of match so only spaces highlighted
