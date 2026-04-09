local completion = require("llm.completion")
local config = require("llm.config")

local M = {
  setup_done = false,
}

local function accept_suggestion()
  if not completion.suggestion then
    return
  end
  vim.schedule(completion.complete)
end

local function dismiss_suggestion()
  if not completion.suggestion then
    return
  end
  vim.schedule(function()
    completion.cancel()
    completion.suggestion = nil
  end)
end

function M.setup()
  if M.setup_done then
    return
  end

  local keymap_modes = config.get().keymap_modes
  local accept_keymap = config.get().accept_keymap
  local dismiss_keymap = config.get().dismiss_keymap

  vim.keymap.set(keymap_modes, accept_keymap, accept_suggestion, { expr = true })
  vim.keymap.set(keymap_modes, dismiss_keymap, dismiss_suggestion, { expr = true })

  M.setup_done = true
end

return M
