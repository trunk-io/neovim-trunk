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
- View and run commands from [Trunk Action](https://docs.trunk.io/actions) notifications

<img width="1076" alt="neovim" src="https://github.com/trunk-io/neovim-trunk/assets/42743566/f3a6c717-81d5-4058-bb56-a026b21ba980">

## Installation

`neovim-trunk` can be installed using your favorite Neovim plugin manager. We've included some
instructions below:

### Prerequisites

- Minimum Neovim version: `v0.9.2`
- Minimum Trunk CLI version: `1.16.3`
- Some commands require `sed` and `tee` to be in `PATH`
- Format on save timeout only works on UNIX and if coreutils `timeout` is in `PATH`

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
      -- formatOnSaveTimeout = 10, -- seconds
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

3. Call `:PlugInstall` to install and `:PlugStatus` to verify
4. Close and relaunch Neovim to start running Trunk

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
      -- formatOnSaveTimeout = 10, -- seconds
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
      -- formatOnSaveTimeout = 10, -- seconds
      -- lspArgs = {}
    }) end,
    branch = "v0.1.0",
  }
}
```

3. Add the line `lua require("init")` to your `init.vim` file (on UNIX `~/.config/nvim/init.vim`)

## Usage

1. Verify that [trunk](https://docs.trunk.io/cli) is in your PATH and you have run `trunk init` in
   your repo
2. Open a file in neovim `nvim <file>`
3. View inline diagnostic annotations
4. Run `:lua vim.lsp.buf.code_action()` on a highlighted section to view and apply autofixes
5. Format on save is enabled by default: make a change and write to buffer (`:w`) to autoformat the
   file

Other commands:

1. `:TrunkConfig` to open the repo `.trunk/trunk.yaml` file for editing
2. `:TrunkStatus` to review any linter failures
3. `:TrunkQuery` to view the list of linters that run on your current file
4. `:TrunkActions` to view any Trunk Actions that have generated notifications and run their
   commands as appropriate

## Configuration

The neovim extension can be configured as follows:

| Option              | Configures                                                               | Default |
| ------------------- | ------------------------------------------------------------------------ | ------- |
| trunkPath           | Where to find the Trunk CLI launcher of binary                           | "trunk" |
| lspArgs             | Optional arguments to append the Trunk LSP Server                        | {}      |
| formatOnSave        | Whether or not to autoformat file buffers when written                   | true    |
| formatOnSaveTimeout | The maximum amount of time to spend attempting to autoformat, in seconds | 10      |
| logLevel            | Verbosity of logs from the Neovim extension                              | "info"  |

(These settings can be changed after loading by calling `require("neovim-trunk").setup({})`)

## Notes

Unlike for VSCode, the Trunk Check Neovim Plugin does not currently provide any summary views for
diagnostics. If you'd like, you can use a plugin like
[Trouble](https://github.com/folke/trouble.nvim) to view aggregate code actions.

Please view our [docs][docs] for any additional Trunk setup instructions, as well as our
[plugins repo](https://github.com/trunk-io/plugins) for the up to date list of supported linters.

[slack]: https://slack.trunk.io
[docs]: https://docs.trunk.io
[vscode]: https://marketplace.visualstudio.com/items?itemName=Trunk.io
