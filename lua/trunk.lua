---@diagnostic disable: need-check-nil

local dlog = require("dlog")
local logger = dlog("trunk_logger")
-- run :DebugLogEnable * to enable logs

-- config variables
local trunkPath = "trunk"
local appendArgs = {}
local formatOnSave = true

-- state tracking
local errors = {}
local failures = {}
local notifications = {}

logger("starting")

local function isempty(s)
	return s == nil or s == ""
end

local function findWorkspace()
	return vim.fs.dirname(vim.fs.find({ ".trunk", ".git" }, { upward = true })[1])
end

local function printFailures()
	for name, fails in pairs(failures) do
		-- empty list signifies failures have been resolved/cleared
		-- TODO: Add this clearing logic to the handler
		if #fails > 0 then
			local messages = {}
			for _, f in pairs(fails) do
				table.insert(messages, f.message)
			end
			print(string.format("Failure %s: [%s]", name, table.concat(messages, ", ")))
		end
	end
end

local function printNotifications()
	for _, v in pairs(notifications) do
		print(string.format("%s:\n%s", v.title, v.message))
	end
end

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
		root_dir = findWorkspace(),
		init_options = {
			-- TODO: Use a correct version and allow lsp to be flexible
			version = "3.4.6",
		},
		handlers = {
			["$trunk/publishFileWatcherEvent"] = function(err, result, ctx, config)
				-- logger("file watcher event")
			end,
			["$trunk/publishNotification"] = function(err, result, ctx, config)
				logger("notif")
				for _, v in pairs(result.notifications) do
					table.insert(notifications, v)
				end
			end,
			["$trunk/log.Error"] = function(err, result, ctx, config)
				-- TODO: Clear these in a meaningful way
				-- TODO: Debug why this isn't writing errors
				logger(err, result, ctx, config)
				table.insert(errors, ctx.params)
				-- logger("log error (bad)")
			end,
			["$trunk/publishFailures"] = function(err, result, ctx, config)
				-- TODO: Clear these using the empty list rule
				logger("failure")
				failures[result.name] = result.failures
			end,
			["$/progress"] = function(err, result, ctx, config)
				-- TODO: Conditionally add a progress bar pane?
				-- logger("progress")
			end,
		},
	})
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

	autocmd("BufWritePre", {
		pattern = "*",
		callback = function()
			if formatOnSave then
				logger("fmt on save callback")
				local cursor = vim.api.nvim_win_get_cursor(0)
				vim.cmd(":% !" .. trunkPath .. " format-stdin %")
				vim.api.nvim_win_set_cursor(0, cursor)
			end
		end,
	})
end

local function findConfig()
	local configDir = findWorkspace()
	logger("found workspace", configDir)
	return configDir .. "/.trunk/trunk.yaml"
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
	if not isempty(opts.lspArgs) then
		formatOnSave = opts.lspArgs
	end
end

local function printStatus()
	-- TODO: Print errors
	printFailures()
	printNotifications()
end

local function checkQuery()
	local currentPath = vim.api.nvim_buf_get_name(0)
	if not isempty(currentPath) then
		local workspace = findWorkspace()
		-- TODO: Make this do a proper relative path transformation
		-- TODO: Make this return a value and print it
		local relativePath = string.sub(currentPath, #workspace + 2)
		vim.cmd("!" .. trunkPath .. " check query " .. relativePath)
	end
end

-- TODO: Make a picker or a hover for action notifications

return {
	start = start,
	findConfig = findConfig,
	setup = setup,
	printStatus = printStatus,
	checkQuery = checkQuery,
}
