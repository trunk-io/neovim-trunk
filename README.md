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

### [lazy.nvim](https://github.com/folke/lazy.nvim)

1. Follow the [lazy.nvim install instructions](https://github.com/folke/lazy.nvim#-installation) to
   modify your `lua/config.lua` file (usually `~/.config/nvim/lua/config.lua`).
2. Add the line `lua require("config")` to your `init.vim` file (usually `~/.config/nvim/init.vim`).
3. Add the following setup to your `lua/config.lua` file:

```lua
require("lazy").setup({
	{
		"trunk-io/neovim-trunk",
		lazy = false,
		tag = "*",
		-- these are optional config arguments (defaults shown)
		config = {
			-- trunkPath = "trunk",
			-- lspArgs = {},
			-- formatOnSave = true,
		},
		main = "trunk",
		dependencies = {"nvim-telescope/telescope.nvim", "nvim-lua/plenary.nvim"}
	}
})
```

### [vim-plug](https://github.com/junegunn/vim-plug)

1. Install [vim-plug](https://github.com/junegunn/vim-plug#installation)
2. Add the following to your `init.vim` file (usually `~/.config/nvim/init.vim`)

```vim
call plug#begin()

" Required dependencies
Plug "nvim-telescope/telescope.nvim"
Plug "nvim-lua/plenary.nvim"

Plug "trunk-io/neovim-trunk", { "tag": "*" }

call plug#end()
```

2. Call `:PlugInstall` to install and `:PlugStatus` to verify
3. Close and relaunch Neovim to start running Trunk

_Note: Currently we do not support overriding configuration options using vim-plug._

### [packer.nvim](https://github.com/wbthomason/packer.nvim)

1. Follow the
   [packer.nvim install instructions](https://github.com/wbthomason/packer.nvim#quickstart) to
   modify your `lua/plugins.lua` file (usually `~/.config/nvim/lua/plugins.lua`).
2. Add the line `lua require("plugins")` to your init.vim file (usually `~/.config/nvim/init.vim`)
3. Add the following setup to your `lua/plugins.lua` file:

```lua
return require("packer").startup(function(use)
  use {
    "trunk-io/neovim-trunk",
    tag = "*",
    requires = {"nvim-telescope/telescope.nvim", "nvim-lua/plenary.nvim"},
		-- these are optional config arguments (defaults shown)
    config = function() require("trunk").setup({
      -- trunkPath = "trunk",
      -- formatOnSave = true,
      -- lspArgs = {},
			-- logLevel = "info"
    }) end
  }
end)
```

4. Call `:PackerSync` to install and :PackerStatus` to verify
5. Close and relaunch Neovim to start running Trunk

### [paq-nvim](https://github.com/savq/paq-nvim)

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
  trunkPath = "trunk",
  lspArgs = {},
  formatOnSave = true,
	logLevel = "info"
},
```

(or by calling `require("neovim-trunk").setup({})` with these options)

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
