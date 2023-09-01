" Setup for vim-plug, another recommended plugin manager
call plug#begin()

call plug#end()

" Display line numbers
set number

" Load the config file, including plugins
lua require("config")
nnoremap <C-k> :lua vim.lsp.buf.code_action()<CR>
" Set color scheme and any other setup
colorscheme tokyonight