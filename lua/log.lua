-- Based on vlog github.com/tjdevries/vlog.nvim
-- MIT License

-- Copyright (c) 2020 TJ DeVries

-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:

-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.

-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.

local function findWorkspace()
	return vim.fs.dirname(vim.fs.find({ ".trunk", ".git" }, { upward = true })[1])
end

local function getOutFile()
	local log_dir = findWorkspace() and findWorkspace() .. "/.trunk/logs"
	if log_dir and vim.fn.isdirectory(log_dir) ~= 0 then
		return log_dir .. "/neovim.log"
	else
		return os.tmpname()
	end
end

-- User configuration section
local default_config = {
	-- Name of the plugin. Prepended to log messages
	plugin = "Trunk",

	-- Should print the output to neovim while running
	use_console = false,

	-- Should highlighting be used in console (using echohl)
	highlights = true,

	-- Should write to a file
	use_file = true,

	-- Default file to write
	out_file = getOutFile(),

	-- Any messages above this level will be logged.
	level = "info",

	-- Level configuration
	modes = {
		{ name = "trace", hl = "Comment" },
		{ name = "debug", hl = "Comment" },
		{ name = "info", hl = "None" },
		{ name = "warn", hl = "WarningMsg" },
		{ name = "error", hl = "ErrorMsg" },
		{ name = "fatal", hl = "ErrorMsg" },
	},

	-- Can limit the number of decimals displayed for floats
	float_precision = 0.01,
}

-- {{{ NO NEED TO CHANGE
local log = {}

local unpack = unpack or table.unpack

log.new = function(config, standalone)
	config = vim.tbl_deep_extend("force", default_config, config)

	local obj
	if standalone then
		obj = log
	else
		obj = {}
	end
	obj.log_level = config.level

	local logFile = io.open(config.out_file, "r")
	if logFile ~= nil then
		local origSize = logFile:seek("end")
		if origSize > 100000 then
			io.close(logFile)
			os.remove(config.out_file)
		else
			io.close(logFile)
		end
	end

	local levels = {}
	for i, v in ipairs(config.modes) do
		levels[v.name] = i
	end

	local round = function(x, increment)
		increment = increment or 1
		x = x / increment
		return (x > 0 and math.floor(x + 0.5) or math.ceil(x - 0.5)) * increment
	end

	local make_string = function(...)
		local t = {}
		for i = 1, select("#", ...) do
			local x = select(i, ...)

			if type(x) == "number" and config.float_precision then
				x = tostring(round(x, config.float_precision))
			elseif type(x) == "table" then
				x = vim.inspect(x)
			else
				x = tostring(x)
			end

			t[#t + 1] = x
		end
		return table.concat(t, " ")
	end

	local log_at_level = function(level, level_config, message_maker, ...)
		-- Return early if we're below the obj.log_level
		if level < levels[obj.log_level] then
			return
		end
		local nameupper = level_config.name:upper()

		local msg = message_maker(...)
		local info = debug.getinfo(2, "Sl")
		local lineinfo = info.short_src .. ":" .. info.currentline

		-- Output to console
		if config.use_console then
			local console_string = string.format("[%-6s%s] %s: %s", nameupper, os.date("%H:%M:%S"), lineinfo, msg)

			if config.highlights and level_config.hl then
				vim.cmd(string.format("echohl %s", level_config.hl))
			end

			local split_console = vim.split(console_string, "\n")
			for _, v in ipairs(split_console) do
				vim.cmd(string.format([[echom "[%s] %s"]], config.plugin, vim.fn.escape(v, '"')))
			end

			if config.highlights and level_config.hl then
				vim.cmd("echohl NONE")
			end
		end

		-- Output to log file
		if config.use_file then
			local fp = io.open(config.out_file, "a")
			local str = string.format("[%-6s%s] %s: %s\n", nameupper, os.date(), lineinfo, msg)
			fp:write(str)
			fp:close()
		end
	end

	for i, x in ipairs(config.modes) do
		obj[x.name] = function(...)
			return log_at_level(i, x, make_string, ...)
		end

		obj[("fmt_%s"):format(x.name)] = function()
			return log_at_level(i, x, function(...)
				local passed = { ... }
				local fmt = table.remove(passed, 1)
				local inspected = {}
				for _, v in ipairs(passed) do
					table.insert(inspected, vim.inspect(v))
				end
				return string.format(fmt, unpack(inspected))
			end)
		end
	end
end

log.new(default_config, true)
log["path"] = default_config.out_file
-- }}}

return log
