" Setup for vim-plug, another recommended plugin manager
call plug#begin()

call plug#end()

" Display line numbers
set number

" Load the config file, including plugins
lua require("config")

" Set color scheme and any other setup
colorscheme tokyonight