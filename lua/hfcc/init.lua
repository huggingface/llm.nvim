local completion = require("hfcc.completion")
local config = require("hfcc.config")
local M = { setup_done = false }

local create_cmds = function()
  vim.api.nvim_create_user_command("HFccSuggestion", function()
    completion.complete()
  end, {})
end

M.setup = function(opts)
  if M.setup_done then
    return
  end

  create_cmds()

  config.setup(opts)

  M.setup_done = true
end

return M
