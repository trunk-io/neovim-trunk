DEBUG = true

local function debug_print(...)
	if DEBUG then
		print(...)
	end
end

debug_print("starting")

local function connect()
	debug_print("connecting...")
	return vim.lsp.start({
		name = "neovim-trunk",
		-- TODO: TYLER MAKE THIS AN OPTION TO PASS IN
		cmd = { "/home/tyler/repos/trunk/bazel-bin/trunk/cli/cli", "lsp-proxy" },
		-- cmd = {'trunk', "lsp-proxy"},
		root_dir = vim.fs.dirname(vim.fs.find({ ".trunk", ".git" }, { upward = true })[1]),
		init_options = {
			version = "3.4.6",
		},
		handlers = {
			["$trunk/publishFileWatcherEvent"] = function(err, result, ctx, config)
				-- debug_print("file watcher event")
			end,
			["$trunk/publishNotification"] = function(err, result, ctx, config)
				-- debug_print("notif")
			end,
			["$trunk/log.Error"] = function(err, result, ctx, config)
				-- debug_print("log error (bad)")
			end,
			["$trunk/publishFailure"] = function(err, result, ctx, config)
				-- debug_print("failure")
			end,
			["$/progress"] = function(err, result, ctx, config)
				-- debug_print("failure")
			end,
		},
	})
end

-- TODO: TYLER CAN WE REMOVE THIS?
local function split(str, sep)
	local result = {}
	local regex = ("([^%s]+)"):format(sep)
	for each in str:gmatch(regex) do
		table.insert(result, each)
	end
	return result
end

local function start()
	debug_print("setting up autocmds")
	local autocmd = vim.api.nvim_create_autocmd
	autocmd("FileType", {
		pattern = "*",
		callback = function()
			debug_print("callback!")
			-- This attaches the existing client since it is keyed by name
			local client = connect()
			vim.lsp.buf_attach_client(0, client)
		end,
	})

	-- TODO: TYLER ONLY WORKS WITH FIRST OPENED FILE
	autocmd("BufWritePre", {
		pattern = "<buffer>",
		callback = function()
			debug_print("fmt on save callback")
			local cursor = vim.api.nvim_win_get_cursor(0)
			vim.cmd([[
        :% !trunk format-stdin %
      ]])
			vim.api.nvim_win_set_cursor(0, cursor)
		end,
	})
end

local function findConfig()
	local configDir = vim.fs.dirname(vim.fs.find({ ".trunk", ".git" }, { upward = true })[1])
	debug_print("calling config", configDir)
	return configDir .. "/.trunk/trunk.yaml"
end

return {
	start = start,
	findConfig = findConfig,
}
