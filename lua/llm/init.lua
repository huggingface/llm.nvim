local completion = require("llm.completion")
local config = require("llm.config")
local keymaps = require("llm.keymaps")
local llm_ls = require("llm.language_server")

local M = { setup_done = false }

local function create_cmds()
  vim.api.nvim_create_user_command("LLMToggleAutoSuggest", function()
    completion.toggle_suggestion()
  end, {})
end

function M.setup(opts)
  if M.setup_done then
    return
  end

  create_cmds()

  config.setup(opts)

  local api_token = config.get().api_token
  -- if api_token == nil then
  --   vim.notify("[LLM] api token is empty, suggestion might not work", vim.log.levels.DEBUG)
  -- end

  llm_ls.setup()

  completion.setup()
  completion.create_autocmds()

  keymaps.setup()

  M.setup_done = true
end

return M
