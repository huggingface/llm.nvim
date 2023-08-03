local completion = require("hfcc.completion")
local config = require("hfcc.config")
local keymaps = require("hfcc.keymaps")

local M = { setup_done = false }

local create_cmds = function()
  vim.api.nvim_create_user_command("HFccSuggestion", function()
    completion.complete_command()
  end, {})

  vim.api.nvim_create_user_command("HFccToggleAutoSuggest", function()
    completion.toggle_suggestion()
  end, {})
end

M.setup = function(opts)
  if M.setup_done then
    return
  end

  create_cmds()

  config.setup(opts)

  local api_token = config.get().api_token
  if api_token == nil then
    vim.notify("[HFcc] api token is empty, suggestion might not work", vim.log.levels.DEBUG)
  end

  completion.setup()
  completion.create_autocmds()

  keymaps.setup()

  M.setup_done = true
end

return M
