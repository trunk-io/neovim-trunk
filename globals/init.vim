call plug#begin()

Plug 'neovim/nvim-lspconfig'

call plug#end()

set number

lua require("config")
colorscheme tokyonight
