# This is a work in progress - it is mostly feature complete, but missing docs and setup instructions

BETA DISCLAIMER HERE

## Overview

Explanation and comparison with VSCode

Screenshots

## Installation

`neovim-trunk` can be installed using your favorite plugin manager. We've included some instructions
below:

### Prerequisites

- Minimum Neovim version: `v0.9.2`
- Minimum Trunk CLI version: `1.6.3`
- Some commands require `sed` and `tee` to be in `PATH`.

<!-- TODO: TYLER MOVE THIS DOWN AND RESTRUCTURE -->

For all of the below installation methods:

- Create a file `lua/config.lua` in your nvim config folder (usually `~/.config/nvim/`).
- Add the line `lua require("config")` to your `init.vim` (usually `~/.config/nvim/init.vim`).

### No prior plugin manager (using [lazy.nvim](https://github.com/folke/lazy.nvim))

Paste the following into your `config.lua`:

```lua
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
		"trunk-io/neovim-trunk",
		lazy = false,
		tag = "v1",
		-- these are optional config arguments - these are their default values
		config = {
			-- trunkPath = "trunk",
			-- lspArgs = {},
			-- formatOnSave = true,
		},
	},
})
```

### [lazy.nvim](https://github.com/folke/lazy.nvim)

Add the following blob to your `require("lazy").setup` command:

```lua
{
	"trunk-io/neovim-trunk",
	lazy = false,
	tag = "v1",
	-- these are optional config arguments - these are their default values
	config = {
		-- trunkPath = "trunk",
		-- lspArgs = {},
		-- formatOnSave = true,
	},
},
```

### [vim-plug](https://github.com/junegunn/vim-plug)

1. After installing vim-plug, add the following to your `init.vim` (usually
   `~/.config/nvim/init.vim`)

```vim
call plug#begin()

" Required dependencies
Plug 'nvim-telescope/telescope.nvim'
Plug 'nvim-lua/plenary.nvim'

Plug 'trunk-io/neovim-trunk'

call plug#end()
```

2. Call `:PlugInstall` to install and `:PlugStatus` to verify
3. Close and relaunch Neovim to start running Trunk

_Note: Currently we do not support overriding configuration options using vim-plug._

## Usage

1. Verify that [trunk](https://docs.trunk.io/cli) is in the PATH and init'd in the repo
2. Open a file in neovim `nvim <file>`
3. View inline diagnostic annotations
4. Run `:lua vim.lsp.buf.code_action()` on a highlighted section to view and apply autofixes
5. Format on save is enabled by default: make a change and write to buffer (`:w`) to autoformat the
   file

Other commands:

1. `:TrunkConfig` to open the repo `.trunk/trunk.yaml` file for editing.
2. `:TrunkStatus` to render any failures or action notifications.
3. `:TrunkQuery` to view a list of linters that run on your current file.
4. `:TrunkActions` to view any Trunk Actions that have created notifications and run their commands
   as appropriate.

## Configuration

The neovim extension can be configured as follows:

```lua
config = {
  trunkPath = "/home/tyler/repos/trunk/bazel-bin/trunk/cli/cli",
  lspArgs = { "--log-file=/home/tyler/repos/neovim-trunk/lsp_new.log" },
  formatOnSave = true,
},
```

(or by calling `require("neovim-trunk").setup()` with these options)

## Notes

Debug logs are supported through the use of the
[smartpde/debuglog](https://github.com/smartpde/debuglog). Add a plugin source in your global setup,
run `require("debuglog").setup()`, and in nvim run `:DebugLogEnable *`

You can use [Trouble](https://github.com/folke/trouble.nvim) to view a summary of diagnostics

For future development, additional effort is needed for the following features:

- Robust logging to an output file
- Testing outside of a repo
- Init and auto-init
- Telemetry
- Better error handling and reporting
- A robust action pane
