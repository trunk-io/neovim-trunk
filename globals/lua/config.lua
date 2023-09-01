-- verifies that this script is actually sourced
print("Hello world!")

-- set up lazypath for plugin loading
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({{
  -- recommended theme plugin
  "folke/tokyonight.nvim",
  lazy = false,
  priority = 1000,
  opts = {},
},
{
  -- neovim-trunk plugin
  -- replace this with your own path to this repo
  dir = "/home/tyler/repos/neovim-trunk",
  lazy = false,
  -- opts = {},
}})