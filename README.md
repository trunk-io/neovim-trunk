# Trunk Check Neovim Plugin

[![docs](https://img.shields.io/badge/-docs-darkgreen?logo=readthedocs&logoColor=ffffff)][docs]
[![slack](https://img.shields.io/badge/-community-611f69?logo=slack)][slack]

**The Trunk Check Neovim Plugin is in Beta with limited support. If you encounter any issues, feel
free to reach out to us on [Slack][Slack] or make a PR directory. For more information, see
[CONTRIBUTING](CONTRIBUTING.md).**

## Overview

[Trunk Check](https://docs.trunk.io) runs 100+ tools to format, lint, static-analyze, and
security-check dozens of languages and config formats. It will autodetect the best tools to run for
your repo, then run them and provide results inline in Neovim. Compare to the [Trunk Check VSCode
Extension][vscode]. The Neovim plugin has the following capabilities:

- Render diagnostics and autofixes inline
- Format files on save
- Display the list of linters that run on each file
- View and run commands from [Trunk Actios](https://docs.trunk.io/actions) notifications

Screenshots

## Installation

`neovim-trunk` can be installed using your favorite Neovim plugin manager. We've included some
instructions below:

### Prerequisites

- Minimum Neovim version: `v0.9.2`
- Minimum Trunk CLI version: `1.16.3`
- Some commands require `sed` and `tee` to be in `PATH`.

### [lazy.nvim](https://github.com/folke/lazy.nvim)

1. Follow the [lazy.nvim install instructions](https://github.com/folke/lazy.nvim#-installation) to
   modify your `lua/config.lua` file (on UNIX `~/.config/nvim/lua/config.lua`)
2. Add the line `lua require("config")` to your `init.vim` file (on UNIX `~/.config/nvim/init.vim`)
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
			-- logLevel = "info"
		},
		main = "trunk",
		dependencies = {"nvim-telescope/telescope.nvim", "nvim-lua/plenary.nvim"}
	}
})
```

### [vim-plug](https://github.com/junegunn/vim-plug)

1. Install [vim-plug](https://github.com/junegunn/vim-plug#installation)
2. Add the following to your `init.vim` file (on UNIX `~/.config/nvim/init.vim`)

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
   modify your `lua/plugins.lua` file (on UNIX `~/.config/nvim/lua/plugins.lua`).
2. Add the line `lua require("plugins")` to your init.vim file (on UNIX `~/.config/nvim/init.vim`)
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

4. Call `:PackerSync` to install and ``:PackerStatus` to verify
5. Close and relaunch Neovim to start running Trunk

### [paq-nvim](https://github.com/savq/paq-nvim)

1. Install [paq-nvim](https://github.com/savq/paq-nvim#installation)
2. Add the following setup to your `lua/init.lua` (on UNIX `~/.config/nvim/lua/init.lua`) file:

```lua
require "paq" {
	-- Required dependencies
	"nvim-telescope/telescope.nvim",
  "nvim-lua/plenary.nvim",
  {
    "trunk-io/neovim-trunk",
    run = function() require("trunk").setup({
			-- these are optional config arguments (defaults shown)
      -- logLevel = "debug",
      -- trunkPath = "trunk",
      -- formatOnSave = false,
      -- lspArgs = {}
    }) end,
    branch = "v0.1.0",
  }
}
```

3. Add the line `lua require("init")` to your `init.vim` file (on UNIX `~/.config/nvim/init.vim`)

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

[slack]: https://slack.trunk.io
[docs]: https://docs.trunk.io
[vscode]: https://marketplace.visualstudio.com/items?itemName=Trunk.io
