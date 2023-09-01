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
	-- empty list of a named failure signifies failures have been resolved/cleared
	-- TODO: Add this clearing logic to the handler
	local failure_elements = {}
	local detail_array = {}
	local index = 1
	for name, fails in pairs(failures) do
		if #fails > 0 then
			-- TODO: This incorrectly only shows the first failure for a given linter. There may be multiple
			-- TODO: Don't depend on telescope being sourced
			table.insert(failure_elements, string.format("%d Failure %s: %s", index, name, fails[1].message))
			table.insert(detail_array, fails[1].detailPath)

			index = index + 1
		end
	end

	logger(table.concat(failure_elements, ","))

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

local function printNotifications()
	-- TODO: Don't unconditionally depend on telescope
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
				print("Trunk failure occurred. Run :TrunkStatus to view")
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
			local bufname = vim.api.nvim_buf_get_name(0)
			logger("buffer filename: " .. bufname)
			local fs = vim.fs
			local findResult = fs.find(fs.basename(bufname), { path = fs.dirname(bufname) })
			logger(table.concat(findResult, "\n"))
			-- checks that the opened buffer actually exists, else trunk crashes
			if #findResult == 0 then
				return
			end
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
				-- TODO: TYLER VERIFY PATH IS NOT NIL
				local cursor = vim.api.nvim_win_get_cursor(0)
				local bufname = vim.fs.basename(vim.api.nvim_buf_get_name(0))
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
end

local function actions()
	printNotifications()
end

local function checkQuery()
	local currentPath = vim.api.nvim_buf_get_name(0)
	if not isempty(currentPath) then
		local workspace = findWorkspace()
		-- TODO: Make this do a proper relative path transformation
		-- TODO: Make this return a value and print it rather than showing the execution
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

return {
	start = start,
	findConfig = findConfig,
	setup = setup,
	printStatus = printStatus,
	actions = actions,
	checkQuery = checkQuery,
}
