DEBUG = false

local function debug_print(...)
  if DEBUG then
    print(...)
  end
end

debug_print("starting")

local function connect()
  debug_print("connecting...")
  return vim.lsp.start({
    name = 'neovim-trunk',
    cmd = {'trunk', "lsp-proxy"},
    root_dir = vim.fs.dirname(
        vim.fs.find({ '.trunk', '.git' }, { upward = true })[1]
    ),
    init_options = {
      version = "3.4.6",
    },
    handlers = {
      ["$trunk/publishFileWatcherEvent"] = function (err, result, ctx, config)
        -- debug_print("file watcher event")
      end,
      ["$trunk/publishNotification"] = function (err, result, ctx, config)
        -- debug_print("notif")
      end,
      ["$trunk/log.Error"] = function (err, result, ctx, config)
        -- debug_print("log error (bad)")
      end,
      ["$trunk/publishFailure"] = function (err, result, ctx, config)
        -- debug_print("failure")
      end,
      ["$/progress"] = function (err, result, ctx, config)
        -- debug_print("failure")
      end,
    },
  })
end

local function run()
  debug_print("setting up autocmds")
  local autocmd = vim.api.nvim_create_autocmd
  autocmd("FileType", {
      pattern = "*",
      callback = function()
        debug_print("callback!")
          local client = connect()
          vim.lsp.buf_attach_client(0, client)
      end
  })
end

return {
  run = run
}