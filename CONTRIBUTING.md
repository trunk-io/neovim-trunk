# Contributing Guidelines

Thanks for contributing to Trunk's Neovim plugin! Read on to learn more.

## Overview

The Trunk Check Neovim Plugin is in Beta with limited support. Please feel free to reach out to us
on [Slack](https://slack.trunk.io) if you encounter any issues, but note that we will be
prioritizing our work on the core [CLI](https://docs.trunk.io/cli) and
[VSCode extension](https://marketplace.visualstudio.com/items?itemName=Trunk.io).

## Local Development

To develop locally, follow the install instructions and then change the plugin path used by
[lazy.nvim](https://github.com/folke/lazy.nvim).

```lua
require("lazy").setup({
	{
		dir = "<path-to-repo>/neovim-trunk",
		lazy = false,
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

On Linux, we usually develop using the
[AppImage](https://github.com/neovim/neovim/wiki/Installing-Neovim#appimage-universal-linux-package)
installation.

Use [demo_data](demo_data) as a sandbox for testing the plugin.

## Code Overview

Neovim plugins are setup as follows:

- A `lua` directory containing any lua files for core functionality. Our `lua` directory contains:
  - [trunk.lua](lua/trunk.lua), which defines global state for the lifetime of the plugin, defines
    commands, and launches the Trunk LSP server.
  - [log.lua](lua/log.lua), which manages logging, which is written to `.trunk/logs/neovim.log` and
    is flushed periodically. When run from outside of a Trunk repo, this log is written to a
    tempfile.

These files interface with the built-in [Neovim LSP framework](https://neovim.io/doc/user/lsp.html)
to provide inline diagnostics and other features.
