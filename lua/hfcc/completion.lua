local api = vim.api
local augroup = "hfcc.suggestion"
local config = require("hfcc.config")
local fn = vim.fn
local hf = require("hfcc.hf")
local utils = require("hfcc.utils")

local M = {
  setup_done = false,

  fetch_job_id = nil,
  hl_group = "HFccSuggestion",
  ns_id = api.nvim_create_namespace("hfcc.suggestion"),
  suggestion = nil,
  suggestion_enabled = true,
  timer = nil,
}

local function parse_response(prefix_len, response)
  local fim = config.get().fim
  local stop_token = config.get().query_params.stop_token

  if fim.enabled then
    local after_fim_mid = utils.string_after_delim(response, "<fim_middle>")
    if after_fim_mid == nil then
      return nil
    end
    local clean_response = utils.rstrip(after_fim_mid:gsub(stop_token, ""))
    return utils.split_str(clean_response, "\n")
  else
    local prefix_removed = string.sub(response, prefix_len + 1)
    local clean_response = utils.rstrip(prefix_removed:gsub(stop_token, ""))
    return utils.split_str(clean_response, "\n")
  end
end

local function get_context()
  local before_table = api.nvim_buf_get_text(0, 0, 0, fn.line(".") - 1, fn.col("."), {})
  local before = table.concat(before_table, "\n")

  local after_table = api.nvim_buf_get_text(0, fn.line(".") - 1, fn.col("."), fn.line("$") - 1, fn.col("$"), {})
  local after = table.concat(after_table, "\n")

  if string.len(before) > config.get().max_context_before then
    before = string.sub(before, string.len(before) - config.get().max_context_before + 1, string.len(before))
  end

  if string.len(after) > config.get().max_context_after then
    after = string.sub(after, 0, config.get().max_context_after)
  end

  return before, after
end

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
  if M.fetch_job_id then
    fn.jobstop(M.fetch_job_id)
    M.fetch_job_id = nil
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

function M.schedule()
  M.cancel()

  M.timer = fn.timer_start(config.debounce_ms, function()
    if fn.mode() == "i" then
      M.suggest()
    end
  end)
end

function M.suggest()
  local before, after = get_context()
  local before_len = string.len(before)

  M.fetch_job_id = hf.fetch_suggestion({ before = before, after = after }, function(response, r, c)
    if response == "" then
      return
    end
    local lines = parse_response(before_len, response)
    if lines == nil then
      return
    end
    M.suggestion = lines
    local extmark = {
      virt_text_win_col = c,
      virt_text = { { lines[1], M.hl_group } },
    }
    if #lines > 1 then
      extmark.virt_lines = {}
      for i = 2, #lines do
        extmark.virt_lines[i - 1] = { { lines[i], M.hl_group } }
      end
    end
    api.nvim_buf_set_extmark(0, M.ns_id, r - 1, c - 1, extmark)
  end)
end

function M.complete()
  M.cancel()

  if M.suggestion ~= nil then
    local r, _ = utils.get_cursor_pos()
    local line = api.nvim_buf_get_lines(0, r - 1, r, false)[1]
    M.suggestion[1] = line .. M.suggestion[1]
    local row_offset, col_offset = new_cursor_pos(M.suggestion, r)
    api.nvim_buf_set_lines(0, r - 1, r, false, M.suggestion)
    api.nvim_win_set_cursor(0, { row_offset, col_offset })

    M.suggestion = nil
  end
end

function M.should_complete()
  return M.suggestion_enabled
end

function M.toggle_suggestion()
  M.suggestion_enabled = not M.suggestion_enabled
  local state = M.suggestion_enabled and "on" or "off"
  vim.notify("[HFcc] Auto suggestions are " .. state, vim.log.levels.INFO)
end

function M.create_autocmds()
  api.nvim_create_augroup(augroup, { clear = true })

  api.nvim_create_autocmd("InsertLeave", { pattern = "*", callback = M.cancel })

  api.nvim_create_autocmd("CursorMovedI", {
    pattern = "*",
    callback = function()
      if M.should_complete() then
        M.schedule()
      else
        M.cancel()
        M.suggestion = nil
      end
    end,
  })
end

function M.setup()
  if M.setup_done then
    return
  end

  vim.api.nvim_command("highlight default link " .. M.hl_group .. " Comment")

  M.setup_done = true
end

-- legacy
function M.complete_command()
  local before, after = get_context()
  local before_len = string.len(before)

  hf.fetch_suggestion({ before = before, after = after }, function(response, r, _)
    if response == "" then
      return
    end
    local lines = parse_response(before_len, response)
    if lines == nil then
      return
    end
    local line = api.nvim_buf_get_lines(0, r - 1, r, false)[1]
    lines[1] = line .. lines[1]
    local row_offset, col_offset = new_cursor_pos(lines, r)
    api.nvim_buf_set_lines(0, r - 1, r, false, lines)
    api.nvim_win_set_cursor(0, { row_offset, col_offset })
  end)
end

return M
