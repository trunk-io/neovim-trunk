---@diagnostic disable: need-check-nil

-- Config variables
local function is_win()
	return package.config:sub(1, 1) == "\\"
end

local trunkPath = is_win() and "trunk.ps1" or "trunk"
local appendArgs = {}
local formatOnSave = true
local formatOnSaveTimeout = 10

local function executionTrunkPath()
	if trunkPath:match(".ps1$") then
		return { "powershell", "-ExecutionPolicy", "ByPass", trunkPath }
	end
	return { trunkPath }
end

-- State tracking
local errors = {}
local failures = {}
local notifications = {}
local cliVersion = nil

local logger = require("log")
local math = require("math")
logger.info("Starting")

local function isempty(s)
	return s == nil or s == ""
end

local function findWorkspace()
	return vim.fs.dirname(vim.fs.find({ ".trunk", ".git" }, { upward = true })[1])
end

local function findConfig()
	local configDir = findWorkspace()
	logger.info("Found workspace", configDir)
	return configDir and configDir .. "/.trunk/trunk.yaml" or ".trunk/trunk.yaml"
end

local function trim(s)
	return s:match("^%s*(.-)%s*$")
end

local function getCliVersion()
	local possibleVersion = nil
	if
		pcall(function()
			local cmd = executionTrunkPath()
			table.insert(cmd, #cmd + 1, "version")
			logger.info("cli version command", table.concat(cmd, " "))
			local output = vim.fn.systemlist(cmd)
			possibleVersion = trim(output[#output])
			vim.version.parse(possibleVersion)
		end)
	then
		return possibleVersion
	else
		-- version is not parsable
		logger.warn("Received unparsable version string", possibleVersion)
		return nil
	end
end

local function checkCliVersion(requiredVersionString)
	local version = vim.version
	if cliVersion == nil then
		logger.info("nil CLI version")
		return false
	end
	local currentVersion = version.parse(cliVersion)
	local requiredVersion = version.parse(requiredVersionString)
	return not version.lt(currentVersion, requiredVersion)
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

	if #failure_elements > 0 then
		logger.info("Failures:", table.concat(failure_elements, ","))
	else
		logger.info("No failures")
		return
	end

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
			logger.info("file to open", fileToOpen)
			if is_win() then
				fileToOpen = fileToOpen:gsub("^file:///", "")
			else
				fileToOpen = fileToOpen:gsub("^file://", "")
			end
			fileToOpen = fileToOpen:gsub("%%3A", ":")
			logger.info("file to open", fileToOpen)
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
					local command = selection[1]:gsub("^trunk", table.concat(executionTrunkPath(), " "))
					-- Remove ANSI coloring from action messages
					vim.cmd(":!" .. command .. [[ | sed -e 's/\x1b\[[0-9;]*m//g']])
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
		if isempty(workspace) then
			print("Must be inside a Trunk workspace to run this command")
		else
			local relativePath = string.sub(currentPath, #workspace + 2)
			vim.cmd("!" .. table.concat(executionTrunkPath(), " ") .. " check query " .. relativePath)
		end
	end
end

-- LSP client lifetime control
local function connect()
	local cmd = executionTrunkPath()
	table.insert(cmd, "lsp-proxy")

	for _, e in pairs(appendArgs) do
		table.insert(cmd, e)
	end
	logger.debug("Launching " .. table.concat(cmd, " "))
	local workspace = findWorkspace()

	if not isempty(workspace) then
		return vim.lsp.start({
			name = "neovim-trunk",
			cmd = cmd,
			root_dir = workspace,
			init_options = {
				-- *** OFFICIAL VERSION OF PLUGIN IS IDENTIFIED HERE ***
				version = "0.1.0",
				clientType = "neovim",
				-- Based on version parsing here https://github.com/neovim/neovim/issues/23863
				clientVersion = vim.split(vim.fn.execute("version"), "\n")[3]:sub(6),
			},
			handlers = {
				-- We must identify handlers for the other events we will receive but don't handle.
				["$trunk/publishFileWatcherEvent"] = function(_err, _result, _ctx, _config)
					-- We don't handle file watcher events in neovim
				end,
				["$trunk/publishNotification"] = function(_err, result, _ctx, _config)
					logger.info("Action notification received")
					for _, v in pairs(result.notifications) do
						table.insert(notifications, v)
					end
				end,
				["$trunk/log.Error"] = function(err, result, ctx, config)
					-- TODO(Tyler): Clear and surface these in a meaningful way
					logger.error(err, result, ctx, config)
					table.insert(errors, ctx.params)
				end,
				["$trunk/publishFailures"] = function(_err, result, _ctx, _config)
					logger.info("Failure received")
					-- TODO(Tyler): Consider removing this print, it can sometimes be obtrusive.
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
				end,
			},
			-- custom callbacks for commands from code actions
			commands = {
				["trunk.checkEnable"] = function(command, _client_info, _command_str, _args)
					-- TODO(Tyler): Use non-ANSI mode
					vim.cmd(
						"!"
							.. table.concat(executionTrunkPath(), " ")
							.. " check enable "
							.. table.concat(command["arguments"])
							.. [[ | sed -e 's/\x1b\[[0-9;]*m//g']]
					)
				end,
				["trunk.checkDisable"] = function(command, _client_info, _command_str, _args)
					-- TODO(Tyler): Use non-ANSI mode
					vim.cmd(
						"!"
							.. table.concat(executionTrunkPath(), " ")
							.. " check disable "
							.. table.concat(command["arguments"])
							.. [[ | sed -e 's/\x1b\[[0-9;]*m//g']]
					)
				end,
				["trunk.openConfigFile"] = function(_command, _client_info, _command_str, _args)
					vim.cmd(":edit " .. findConfig())
				end,
			},
		})
	end
end

-- Startup, including attaching autocmds
local function start()
	cliVersion = getCliVersion()
	logger.info("Running on CLI version:", cliVersion)
	if cliVersion == nil then
		logger.error("nil CLI version")
		print(
			"The Trunk Neovim extension requires Trunk CLI version >= 1.17.0 - we could not determine your Trunk CLI version."
		)
		print("The extension will not run until you upgrade your CLI version.")
		print("Please run `trunk upgrade` to get the latest improvements and fixes for Neovim.")
		return
	end
	if cliVersion ~= "0.0.0-rc" then
		if not checkCliVersion("1.17.0") then
			logger.error("Trunk CLI version must be >= 1.17.0")
			print(
				"The Trunk Neovim extension requires Trunk CLI version >= 1.17.0 - you currently have "
					.. cliVersion
					.. "."
			)
			print("The extension will not run until you upgrade your CLI version.")
			print("Please run `trunk upgrade` to get the latest improvements and fixes for Neovim.")
			return
		end
		if not checkCliVersion("1.17.2-beta.5") then
			logger.warn("Trunk CLI version should be >= 1.17.2")
			print("Detected stale Trunk CLI version " .. cliVersion .. ".")
			print(" Please run `trunk upgrade` to get the latest improvements and fixes for Neovim.")
		end
	end
	logger.info("Setting up autocmds")
	local autocmd = vim.api.nvim_create_autocmd
	autocmd("FileType", {
		pattern = "*",
		callback = function()
			local bufname = vim.api.nvim_buf_get_name(0)
			logger.debug("Buffer filename: " .. bufname)
			local fs = vim.fs
			local findResult = fs.find(fs.basename(bufname), { path = fs.dirname(bufname) })
			-- Checks that the opened buffer actually exists and isn't a directory, else trunk crashes
			if #findResult == 0 or vim.fn.isdirectory(bufname) ~= 0 then
				return
			end
			logger.debug("Attaching to new buffer")
			-- This attaches the existing client since it is keyed by name
			local client = connect()
			if client ~= nil then
				vim.lsp.buf_attach_client(0, client)
			end
		end,
	})

	autocmd("BufWritePre", {
		pattern = "*",
		callback = function()
			if formatOnSave then
				-- TODO(Tyler): Get this working with vim.lsp.buf.format({ async = false })
				logger.debug("Running fmt on save callback")
				local cursor = vim.api.nvim_win_get_cursor(0)
				local filename = vim.api.nvim_buf_get_name(0)
				local workspace = findWorkspace()
				if is_win() then
					workspace = workspace:gsub("/", "\\")
				end
				-- if filename doesn't start with workspace
				if workspace == nil or filename:sub(1, #workspace) ~= workspace then
					return
				end

				local handle = io.popen("command -v timeout")
				local timeoutResult = handle:read("*a")
				handle:close()
				-- Stores current buffer in a temporary file in case trunk fmt fails so we don't overwrite the original buffer with an error message.
				local tmpFile = os.tmpname()
				local tmpFormattedFile = os.tmpname()
				local trunkFormatCmd = table.concat(executionTrunkPath(), " ") .. " format-stdin %:p"
				if checkCliVersion("1.17.2-beta.5") then
					logger.info("using --output-file")
					trunkFormatCmd = trunkFormatCmd .. " --output-file=" .. tmpFormattedFile
					if is_win() then
						trunkFormatCmd = "(" .. trunkFormatCmd .. ") >$null"
					else
						trunkFormatCmd = trunkFormatCmd .. " 1>/dev/null 2>/dev/null"
					end
				else
					trunkFormatCmd = trunkFormatCmd .. " > " .. tmpFormattedFile
				end
				local formatCommand = ""
				if is_win() then
					logger.debug("Formatting on Windows")
					-- TODO(Tyler): Handle carriage returns correctly here.
					-- NOTE(Tyler): Powershell does not have && and || so we must use cmd /c
					formatCommand = (
						':% ! cmd /c "tee '
						.. tmpFile
						.. " | "
						.. trunkFormatCmd
						.. " && cat "
						.. tmpFormattedFile
						.. " || cat "
						.. tmpFile
						.. '"'
					)
				elseif timeoutResult:len() == 0 then
					logger.debug("Formatting without timeout")
					formatCommand = (
						":% !tee "
						.. tmpFile
						.. " | "
						.. trunkFormatCmd
						.. " && cat "
						.. tmpFormattedFile
						.. " || cat "
						.. tmpFile
					)
				else
					logger.debug("Formatting with timeout")
					formatCommand = (
						":% !tee "
						.. tmpFile
						.. " | timeout "
						.. formatOnSaveTimeout
						.. " "
						.. trunkFormatCmd
						.. " && cat "
						.. tmpFormattedFile
						.. " || cat "
						.. tmpFile
					)
				end
				logger.debug("Format command: " .. formatCommand)
				vim.cmd(formatCommand)
				local line_count = vim.api.nvim_buf_line_count(0)
				os.remove(tmpFile)
				os.remove(tmpFormattedFile)
				vim.api.nvim_win_set_cursor(0, { math.min(cursor[1], line_count), cursor[2] })
			end
		end,
	})
end

-- Setup config variables
local function setup(opts)
	logger.info("Performing setup", opts)
	if not isempty(opts.logLevel) then
		logger.log_level = opts.logLevel
		logger.debug("Overrode loglevel with", opts.logLevel)
	end

	if not isempty(opts.trunkPath) then
		logger.debug("Overrode trunkPath with", opts.trunkPath)
		trunkPath = opts.trunkPath
	end

	if not isempty(opts.lspArgs) and #opts.lspArgs > 0 then
		logger.debug("Overrode lspArgs with", table.concat(opts.lspArgs, " "))
		appendArgs = opts.lspArgs
	end

	if not isempty(opts.formatOnSave) then
		logger.debug("Overrode formatOnSave with", opts.formatOnSave)
		formatOnSave = opts.formatOnSave
	end

	if not isempty(opts.formatOnSaveTimeout) then
		logger.debug("Overrode formatOnSaveTimeout with", opts.formatOnSaveTimeout)
		formatOnSave = opts.formatOnSaveTimeout
	end

	start()
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
