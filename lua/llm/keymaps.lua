local completion = require("llm.completion")
local config = require("llm.config")

local M = {
  setup_done = false,
}

function M.setup()
  if M.setup_done then
    return
  end

  local accept_keymap = config.get().accept_keymap
  local dismiss_keymap = config.get().dismiss_keymap

  vim.keymap.set("i", accept_keymap, function()
    if not completion.suggestion then
      return
    end
    vim.schedule(completion.complete)
  end, { expr = true })

  vim.keymap.set("i", dismiss_keymap, function()
    if not completion.suggestion then
      return
    end
    vim.schedule(function()
      completion.cancel()
      completion.suggestion = nil
    end)
  end, { expr = true })

  M.setup_done = true
end

return M
