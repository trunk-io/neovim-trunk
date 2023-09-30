-- verifies that this script is actually sourced
-- print("Hello world!")

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

require("lazy").setup({
	{
		-- recommended theme plugin
		"folke/tokyonight.nvim",
		lazy = false,
		priority = 1000,
		opts = {},
	},
	{
		"folke/trouble.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
	},
	{
		-- neovim-trunk plugin
		-- replace this with your own path to this repo
		dir = "/home/tyler/repos/neovim-trunk",
		lazy = false,
		config = {
			-- trunkPath = "/home/tyler/repos/trunk/bazel-bin/trunk/cli/cli",
			-- lspArgs = { "--log-file=/home/tyler/repos/neovim-trunk/lsp_new.log" },
			-- formatOnSave = true,
		},
		main = "trunk",
		dependencies = { "nvim-telescope/telescope.nvim", "nvim-lua/plenary.nvim" },
	},
})
