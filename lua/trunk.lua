---@diagnostic disable: need-check-nil

local dlog = require("dlog")
local logger = dlog("trunk_logger")
-- run :DebugLogEnable * to enable logs

trunkPath = "trunk"
appendArgs = {}

logger("starting")

local function connect()
	logger("connecting...")
	local cmd = { trunkPath, "lsp-proxy" }
	for _, e in pairs(appendArgs) do
		table.insert(cmd, e)
	end
	logger("launching %s", table.concat(cmd, " "))

	return vim.lsp.start({
		name = "neovim-trunk",
		cmd = cmd,
		root_dir = vim.fs.dirname(vim.fs.find({ ".trunk", ".git" }, { upward = true })[1]),
		init_options = {
			version = "3.4.6",
		},
		handlers = {
			["$trunk/publishFileWatcherEvent"] = function(err, result, ctx, config)
				-- logger("file watcher event")
			end,
			["$trunk/publishNotification"] = function(err, result, ctx, config)
				-- logger("notif")
			end,
			["$trunk/log.Error"] = function(err, result, ctx, config)
				-- logger("log error (bad)")
			end,
			["$trunk/publishFailure"] = function(err, result, ctx, config)
				-- logger("failure")
			end,
			["$/progress"] = function(err, result, ctx, config)
				-- logger("failure")
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
	logger("setting up autocmds")
	local autocmd = vim.api.nvim_create_autocmd
	autocmd("FileType", {
		pattern = "*",
		callback = function()
			logger("callback!")
			-- This attaches the existing client since it is keyed by name
			local client = connect()
			vim.lsp.buf_attach_client(0, client)
		end,
	})

	-- TODO: TYLER ONLY WORKS WITH FIRST OPENED FILE
	autocmd("BufWritePre", {
		pattern = "<buffer>",
		callback = function()
			logger("fmt on save callback")
			local cursor = vim.api.nvim_win_get_cursor(0)
			vim.cmd([[:% !]] .. trunkPath .. [[ format-stdin %]])
			vim.api.nvim_win_set_cursor(0, cursor)
		end,
	})
end

local function findConfig()
	local configDir = vim.fs.dirname(vim.fs.find({ ".trunk", ".git" }, { upward = true })[1])
	logger("found workspace", configDir)
	return configDir .. "/.trunk/trunk.yaml"
end

local function isempty(s)
	return s == nil or s == ""
end

local function setup(opts)
	logger("performing setup")
	trunkPath = opts.name
	if not isempty(opts.trunkPath) then
		trunkPath = opts.trunkPath
	end
	if not isempty(opts.lspArgs) then
		appendArgs = opts.lspArgs
	end
end

return {
	start = start,
	findConfig = findConfig,
	setup = setup,
}
