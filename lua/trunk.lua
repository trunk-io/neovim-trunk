---@diagnostic disable: need-check-nil

local dlog = require("dlog")

local logger = dlog("trunk_logger")
-- Run :DebugLogEnable * to enable logs

-- Config variables
local trunkPath = "trunk"
local appendArgs = {}
local formatOnSave = true

-- State tracking
local errors = {}
local failures = {}
local notifications = {}

logger("Starting Trunk plugin")

-- Utils
local function isempty(s)
	return s == nil or s == ""
end

local function findWorkspace()
	return vim.fs.dirname(vim.fs.find({ ".trunk", ".git" }, { upward = true })[1])
end

local function findConfig()
	local configDir = findWorkspace()
	logger("Found workspace", configDir)
	return configDir .. "/.trunk/trunk.yaml"
end

-- Handlers for user commands
local function printFailures()
	-- Empty list of a named failure signifies failures have been resolved/cleared
	local failure_elements = {}
	local detail_array = {}
	local index = 1
	for name, fails in pairs(failures) do
		for _, fail in pairs(fails) do
			table.insert(failure_elements, string.format("%d Failure %s: %s", index, name, fail.message))
			table.insert(detail_array, fail.detailPath)

			index = index + 1
		end
	end

	-- TODO: TYLER WE NEED A BETTER WAY TO RECORD LOGS SO USERS CAN REPORT THEM
	logger(table.concat(failure_elements, ","))

	-- TODO(Tyler): Don't unconditionally depend on telescope
	local picker = require("telescope.pickers")
	local finders = require("telescope.finders")
	local actions = require("telescope.actions")
	local action_state = require("telescope.actions.state")

	local attach_callback = function(prompt_bufnr, _)
		actions.select_default:replace(function()
			actions.close(prompt_bufnr)
			local selection = action_state.get_selected_entry()
			print(selection[1])
			local words = {}
			for word in selection[1]:gmatch("%w+") do
				table.insert(words, word)
			end

			local failure_index = tonumber(words[1])
			local fileToOpen = detail_array[failure_index]
			vim.cmd(":edit " .. fileToOpen)
		end)
		return true
	end

	if #failure_elements > 0 then
		picker
			.new({}, {
				prompt_title = "Failures",
				results_title = "Open failure contents",
				finder = finders.new_table({
					results = failure_elements,
				}),
				cwd = findWorkspace(),
				attach_mappings = attach_callback,
			})
			:find()
	else
		print("No failures")
	end
end

local function printActionNotifications()
	-- TODO(Tyler): Don't unconditionally depend on telescope
	local picker = require("telescope.pickers")
	local finders = require("telescope.finders")
	local actions = require("telescope.actions")
	local action_state = require("telescope.actions.state")
	for _, v in pairs(notifications) do
		-- This output is replaced with the picker
		print(string.format("%s:\n%s", v.title, v.message))

		if #v.commands > 0 then
			local commands = {}
			for _, command in pairs(v.commands) do
				table.insert(commands, command.run)
			end

			local attach_callback = function(prompt_bufnr, _)
				actions.select_default:replace(function()
					actions.close(prompt_bufnr)
					local selection = action_state.get_selected_entry()
					-- Remove ANSI coloring from action messages
					vim.cmd(":!" .. selection[1] .. [[ | sed -e 's/\x1b\[[0-9;]*m//g']])
				end)
				return true
			end

			picker
				.new({}, {
					prompt_title = v.title,
					results_title = "Commands",
					finder = finders.new_table({
						results = commands,
					}),
					cwd = findWorkspace(),
					attach_mappings = attach_callback,
				})
				:find()
		end
	end
end

local function checkQuery()
	local currentPath = vim.api.nvim_buf_get_name(0)
	if not isempty(currentPath) then
		local workspace = findWorkspace()
		-- TODO: TYLER Make this use the CLI output type
		local relativePath = string.sub(currentPath, #workspace + 2)
		vim.cmd(
			"!"
				.. trunkPath
				.. " check query "
				.. relativePath
				.. [[ | jq -c ".[0] | .linters" | sed s/,/,\ /g | tr -d '["]']]
		)
	end
end

-- LSP client lifetime control
local function connect()
	local cmd = { trunkPath, "lsp-proxy" }
	for _, e in pairs(appendArgs) do
		table.insert(cmd, e)
	end
	logger("Launching %s", table.concat(cmd, " "))

	return vim.lsp.start({
		name = "neovim-trunk",
		cmd = cmd,
		root_dir = findWorkspace(),
		init_options = {
			-- *** OFFICIAL VERSION OF PLUGIN IS IDENTIFIED HERE ***
			version = "0.1.0",
			-- Enum value for neovim
			client = 2,
			-- Based on version parsing here https://github.com/neovim/neovim/issues/23863
			clientVersion = vim.split(vim.fn.execute("version"), "\n")[3]:sub(6),
		},
		handlers = {
			-- We must identify handlers for the other events we will receive but don't handle.
			["$trunk/publishFileWatcherEvent"] = function(_err, _result, _ctx, _config)
				-- logger("file watcher event")
			end,
			["$trunk/publishNotification"] = function(_err, result, _ctx, _config)
				logger("Notif")
				for _, v in pairs(result.notifications) do
					table.insert(notifications, v)
				end
			end,
			["$trunk/log.Error"] = function(err, result, ctx, config)
				-- TODO(Tyler): Clear and surface these in a meaningful way
				logger(err, result, ctx, config)
				table.insert(errors, ctx.params)
			end,
			["$trunk/publishFailures"] = function(_err, result, _ctx, _config)
				logger("Failure received")
				-- Consider removing this print, it can sometimes be obtrusive.
				print("Trunk failure occurred. Run :TrunkStatus to view")
				if #result.failures > 0 then
					failures[result.name] = result.failures
				else
					-- This empty failure list is sent when the clear button in VSCode is hit.
					-- TODO(Tyler): Add in the ability to clear failures during a session.
					table.remove(failures, result.name)
				end
			end,
			["$/progress"] = function(_err, _result, _ctx, _config)
				-- TODO(Tyler): Conditionally add a progress bar pane?
				-- logger("progress")
			end,
		},
	})
end

-- Startup, including attaching autocmds
local function start()
	logger("Setting up autocmds")
	local autocmd = vim.api.nvim_create_autocmd
	autocmd("FileType", {
		pattern = "*",
		callback = function()
			local bufname = vim.api.nvim_buf_get_name(0)
			logger("Buffer filename: " .. bufname)
			local fs = vim.fs
			local findResult = fs.find(fs.basename(bufname), { path = fs.dirname(bufname) })
			logger(table.concat(findResult, "\n"))
			-- Checks that the opened buffer actually exists, else trunk crashes
			if #findResult == 0 then
				return
			end
			logger("Attaching to new buffer")
			-- This attaches the existing client since it is keyed by name
			local client = connect()
			vim.lsp.buf_attach_client(0, client)
		end,
	})

	autocmd("BufWritePre", {
		pattern = "*",
		callback = function()
			if formatOnSave then
				-- TODO(Tyler): Get this working with vim.lsp.buf.format({ async = false })
				logger("Fmt on save callback")
				local cursor = vim.api.nvim_win_get_cursor(0)
				local bufname = vim.fs.basename(vim.api.nvim_buf_get_name(0))
				-- Stores current buffer in a temporary file in case trunk fmt fails so we don't overwrite the original buffer with an error message.
				vim.cmd(
					":% !tee /tmp/.trunk-format-"
						.. bufname
						.. " | "
						.. trunkPath
						.. " format-stdin %:p || cat /tmp/.trunk-format-"
						.. bufname
				)
				vim.api.nvim_win_set_cursor(0, cursor)
			end
		end,
	})
end

-- Setup config variables
local function setup(opts)
	logger("Performing setup")
	trunkPath = opts.name
	if not isempty(opts.trunkPath) then
		trunkPath = opts.trunkPath
	end
	if not isempty(opts.lspArgs) then
		appendArgs = opts.lspArgs
	end
	if not isempty(opts.formatOnSave) then
		formatOnSave = opts.formatOnSave
	end
end

-- Lua handles for plugin commands and setup
return {
	start = start,
	findConfig = findConfig,
	setup = setup,
	printStatus = printFailures,
	actions = printActionNotifications,
	checkQuery = checkQuery,
}
