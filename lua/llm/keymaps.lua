local completion = require("llm.completion")
local config = require("llm.config")

local M = {
  setup_done = false,
}

function M.accept_suggestion(passthru_keys)
  return function()
    if not completion.suggestion then
      return vim.api.nvim_replace_termcodes(passthru_keys, true, true, true)
    end
    vim.schedule(completion.complete)
  end
end

function M.dismiss_suggestion(passthru_keys)
  return function()
    if not completion.suggestion then
      return vim.api.nvim_replace_termcodes(passthru_keys, true, true, true)
    end
    vim.schedule(function()
      completion.cancel()
      completion.suggestion = nil
    end)
  end
end

function M.setup()
  if M.setup_done then
    return
  end

  -- Legacy field fallback
  if config.get().accept_keymap ~= nil then
    vim.notify("Using legacy keymap field. Use kemap.accept instead of accept_keymap", vim.log.levels.WARN)
    config.get().keymap.accept = config.get().accept_keymap
  end
  if config.get().dismiss_keymap ~= nil then
    vim.notify("Using legacy keymap field. Use kemap.dismiss instead of dismiss_keymap", vim.log.levels.WARN)
    config.get().keymap.dismiss = config.get().dismiss_keymap
  end

  local modes = config.get().keymap.modes

  local accept_keymap = config.get().keymap.accept
  local dismiss_keymap = config.get().keymap.dismiss

  if modes ~= nil and accept_keymap ~= nil then
    vim.keymap.set(
      modes,
      accept_keymap,
      M.accept_suggestion(accept_keymap),
      { desc = "Accept llm completion", expr = true, noremap = true }
    )
  end
  if modes ~= nil and dismiss_keymap ~= nil then
    vim.keymap.set(
      modes,
      dismiss_keymap,
      M.dismiss_suggestion(dismiss_keymap),
      { desc = "Dismiss llm completion", expr = true, noremap = true }
    )
  end

  M.setup_done = true
end

return M
