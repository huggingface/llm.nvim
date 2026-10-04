local completion = require("llm.completion")
local config = require("llm.config")

local M = {
  setup_done = false,
}

local function accept_suggestion(keys)
  return function()
    if not completion.suggestion then
      return vim.api.nvim_replace_termcodes(keys, true, true, true)
    end
    vim.schedule(completion.complete)
  end
end

local function dismiss_suggestion(keys)
  return function()
    if not completion.suggestion then
      return vim.api.nvim_replace_termcodes(keys, true, true, true)
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

  local accept_keymap = config.get().accept_keymap
  local dismiss_keymap = config.get().dismiss_keymap

  local accept_func = accept_suggestion(accept_keymap)
  local dismiss_func = dismiss_suggestion(dismiss_keymap)

  vim.keymap.set("i", accept_keymap, accept_func, { expr = true })
  vim.keymap.set("n", accept_keymap, accept_func, { expr = true })

  vim.keymap.set("i", dismiss_keymap, dismiss_func, { expr = true })
  vim.keymap.set("n", dismiss_keymap, dismiss_func, { expr = true })

  M.setup_done = true
end

return M
