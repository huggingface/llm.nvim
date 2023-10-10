local completion = require("llm.completion")
local config = require("llm.config")
local keymaps = require("llm.keymaps")
local llm_ls = require("llm.language_server")

local M = { setup_done = false }

local function create_cmds()
  vim.api.nvim_create_user_command("LLMToggleAutoSuggest", function()
    completion.toggle_suggestion()
  end, {})

  vim.api.nvim_create_user_command("LLMSuggestion", function()
    completion.lsp_suggest()
  end, {})
end

function M.setup(opts)
  if M.setup_done then
    return
  end

  create_cmds()

  config.setup(opts)

  llm_ls.setup()

  completion.setup(config.get().enable_suggestions_on_startup)
  completion.create_autocmds()

  keymaps.setup()

  M.setup_done = true
end

return M
