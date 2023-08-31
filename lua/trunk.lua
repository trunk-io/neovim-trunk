local api = vim.api
local buf, win

print("starting")

local function open_window()
  buf = api.nvim_create_buf(false, true) -- create new emtpy buffer

  api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')

  -- get dimensions
  local width = api.nvim_get_option("columns")
  local height = api.nvim_get_option("lines")

  -- calculate our floating window size
  local win_height = math.ceil(height * 1 - 4)
  local win_width = math.ceil(width * 0.8)

  -- and its starting position
  local row = math.ceil((height - win_height) / 2 - 1)
  local col = math.ceil((width - win_width) / 2)

  -- set some options
  local opts = {
    style = "minimal",
    relative = "editor",
    width = win_width,
    height = win_height,
    row = row,
    col = col
  }

  -- and finally create it with buffer attached
  win = api.nvim_open_win(buf, true, opts)
end

local function run()
  print("hi trunk")
  -- vim.lsp.handlers["textDocument/definition"] = my_custom_default_definition
  
  vim.lsp.start({
    name = 'neovim-trunk',
    cmd = {'/home/tyler/repos/trunk/bazel-bin/trunk/cli/cli', "lsp-proxy", "--log-file=/home/tyler/repos/neovim-trunk/lsp.log"},
    root_dir = "~/neovim-trunk",
    init_options = {
      version = "3.4.6",
    },
    handlers = {
      ["$trunk/publishFileWatcherEvent"] = function (err, result, ctx, config)
        -- print("file watcher event")
      end,
      ["$trunk/publishNotification"] = function (err, result, ctx, config)
        -- print("notif")
      end,
      ["$trunk/log.Error"] = function (err, result, ctx, config)
        -- print("log error (bad)")
      end,
      ["$trunk/publishFailure"] = function (err, result, ctx, config)
        -- print("failure")
      end,
      ["$/progress"] = function (err, result, ctx, config)
        -- print("failure")
      end,
    },
  })
  -- vim.fs.dirname(vim.fs.find({'pyproject.toml', 'setup.py'}, { upward = true })[1])

  -- :lua =vim.lsp.start({name="trunk", cmd={"trunk", "lsp-proxy", "--log-file=/home/tyler/re
-- pos/neovim-trunk/lsp.log"}, root_dir="/home/tyler/repos/neovim-tr
-- unk", init_options = { version = "3.4.6"}})

  -- open_window()
end

return {
  run = run
}