local api = vim.api
local augroup = "hfcc.suggestion"
local config = require("hfcc.config")
local fn = vim.fn
local hf = require("hfcc.hf")
local utils = require("hfcc.utils")
local M = {
  suggestion = nil,
  suggestion_enabled = true,
}

local function parse_response(prefix_len, response)
  local fim = config.get("fim")
  local stop_token = config.get("query_params").stop_token

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

  return before, after
end

local function new_cursor_pos(lines, row)
  local lines_len = #lines
  local row_offset = row + lines_len - 1
  local col_offset = string.len(lines[lines_len])
  if col_offset > 0 then
    col_offset = col_offset - 1
  end

  return row_offset, col_offset
end

function M.suggest()
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
    M.suggestion = lines
    local row_offset, col_offset = new_cursor_pos(lines, r)
    api.nvim_buf_set_lines(0, r - 1, r, false, lines)
    api.nvim_win_set_cursor(0, { row_offset, col_offset })
  end)
end

function M.complete()
  if M.suggestion ~= nil then
    local r, _ = utils.get_cursor_pos()
    local row_offset, col_offset = new_cursor_pos(M.suggestion, r)
    api.nvim_buf_set_lines(0, r - 1, r, false, M.suggestion)
    api.nvim_win_set_cursor(0, { row_offset, col_offset })
  end
end

function M.complete_command()
  local before, after = get_context()
  local before_len = string.len(before)

  hf.fetch_suggestion({ before = before, after = after }, function(response, r, _)
    if response == "" then
      return
    end
    print(response)
    local lines = parse_response(before_len, response)
    if lines == nil then
      return
    end
    local line = api.nvim_buf_get_lines(0, r - 1, r, false)[1]
    lines[1] = line .. lines[1]
    M.suggestion = lines
    local row_offset, col_offset = new_cursor_pos(lines, r)
    api.nvim_buf_set_lines(0, r - 1, r, false, lines)
    api.nvim_win_set_cursor(0, { row_offset, col_offset })
  end)
end

function M.clear() end

function M.should_complete()
  return M.suggestion_enabled
  -- and not vim.tbl_contains(config.get_config().exclude_filetypes, vim.bo.filetype)
  -- and consts.valid_end_of_line_regex:match_str(utils.end_of_line())
end

function M.toggle_suggestion()
  M.suggestion_enabled = not M.suggestion_enabled
  local state = M.suggestion_enabled and "on" or "off"
  vim.notify("[HFcc] Auto suggestions are " .. state, vim.log.levels.INFO)
end

function M.create_autocmds()
  vim.api.nvim_create_augroup(augroup, { clear = true })

  api.nvim_create_autocmd("InsertLeave", { pattern = "*", callback = M.clear })

  api.nvim_create_autocmd("CursorMovedI", {
    pattern = "*",
    callback = function()
      if M.should_complete() then
        M.suggest()
      else
        M.clear()
        M.suggestion = nil
      end
    end,
  })
end

return M
