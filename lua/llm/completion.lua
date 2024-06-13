local api = vim.api
local augroup = "llm.suggestion"
local llm_ls = require("llm.language_server")
local config = require("llm.config")
local fn = vim.fn
local utils = require("llm.utils")

local M = {
  setup_done = false,

  hl_group = "LLMSuggestion",
  ns_id = api.nvim_create_namespace("llm.suggestion"),
  request_id = nil,
  shown_suggestion = nil,
  suggestion = nil,
  suggestions_enabled = true,
  timer = nil,
}

local function new_cursor_pos(lines, row)
  local lines_len = #lines
  local row_offset = row + lines_len - 1
  local col_offset = string.len(lines[lines_len])

  return row_offset, col_offset
end

local function stop_timer()
  if M.timer then
    fn.timer_stop(M.timer)
    M.timer = nil
  end
end

local function cancel_request()
  if M.request_id then
    llm_ls.cancel_request(M.request_id)
    M.request_id = nil
  end
end

local function clear_preview()
  api.nvim_buf_clear_namespace(0, M.ns_id, 0, -1)
end

function M.cancel()
  stop_timer()
  cancel_request()
  clear_preview()
end

function M.reject()
  M.cancel()
  if M.shown_suggestion ~= nil then
    llm_ls.reject_completion(M.shown_suggestion)
    M.shown_suggestion = nil
  end
end

function M.schedule()
  M.reject()

  M.timer = fn.timer_start(config.get().debounce_ms, function()
    if fn.mode() == "i" then
      M.lsp_suggest()
    end
  end)
end

function M.lsp_suggest()
  M.request_id = llm_ls.get_completions(function(err, result, context, _conf)
    if err ~= nil then
      vim.notify("[LLM] " .. err.message, vim.log.levels.ERROR)
      return
    end
    local completions = result.completions
    local generated_text = llm_ls.extract_generation(completions)
    local lines = utils.split_str(generated_text, "\n")
    if lines == nil then
      return
    end
    M.suggestion = lines
    local col = context.params.position.character
    local line = context.params.position.line
    local extmark = {
      virt_text_win_col = col,
      virt_text = { { lines[1], M.hl_group } },
    }
    if #lines > 1 then
      extmark.virt_lines = {}
      for i = 2, #lines do
        extmark.virt_lines[i - 1] = { { lines[i], M.hl_group } }
      end
    end
    api.nvim_buf_set_extmark(0, M.ns_id, line, col, extmark)
    M.shown_suggestion = result
  end)
end

function M.complete()
  M.cancel()

  if M.suggestion ~= nil then
    local r, c = utils.get_cursor_pos()
    local line = api.nvim_buf_get_lines(0, r - 1, r, false)[1]
    M.suggestion[1] = utils.insert_at(line, c + 1, M.suggestion[1])
    local row_offset, col_offset = new_cursor_pos(M.suggestion, r)
    api.nvim_buf_set_lines(0, r - 1, r, false, M.suggestion)
    api.nvim_win_set_cursor(0, { row_offset, col_offset })

    llm_ls.accept_completion(M.shown_suggestion)
    M.shown_suggestion = nil
    M.suggestion = nil
  end
end

function M.should_complete()
  return M.suggestions_enabled
end

function M.toggle_suggestion()
  M.suggestions_enabled = not M.suggestions_enabled
  local state = M.suggestions_enabled and "on" or "off"
  vim.notify("[LLM] Auto suggestions are " .. state, vim.log.levels.INFO)
end

function M.create_autocmds()
  api.nvim_create_augroup(augroup, { clear = true })

  api.nvim_create_autocmd("InsertLeave", { pattern = "*", callback = M.reject })

  api.nvim_create_autocmd("CursorMovedI", {
    pattern = config.get().enable_suggestions_on_files,
    callback = function()
      if M.should_complete() then
        M.schedule()
      else
        M.reject()
        M.suggestion = nil
      end
    end,
  })
end

function M.setup(suggestions_enabled)
  if M.setup_done then
    return
  end

  vim.api.nvim_command("highlight default link " .. M.hl_group .. " Comment")

  M.suggestions_enabled = suggestions_enabled
  M.setup_done = true
end

return M
