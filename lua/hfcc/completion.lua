local api = vim.api
local config = require("hfcc.config")
local fn = vim.fn
local hf = require("hfcc.hf")
local utils = require("hfcc.utils")
local M = {}

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

function M.complete()
  local before_table = api.nvim_buf_get_text(0, 0, 0, fn.line(".") - 1, fn.col("."), {})
  local before = table.concat(before_table, "\n")
  local before_len = string.len(before)

  local after_table = api.nvim_buf_get_text(0, fn.line(".") - 1, fn.col("."), -1, -1, {})
  local after = table.concat(after_table, "\n")

  hf.fetch_suggestion({ before = before, after = after }, function(response, r, _)
    if response == "" then
      return
    end
    local lines = parse_response(before_len, response)
    if lines == nil then
      return
    end
    local lines_len = #lines
    local line = api.nvim_buf_get_lines(0, r - 1, r, false)[1]
    lines[1] = line .. lines[1]
    local row_offset = r + lines_len - 1
    local col_offset = string.len(lines[lines_len]) - 1
    api.nvim_buf_set_lines(0, r - 1, r, false, lines)
    api.nvim_win_set_cursor(0, { row_offset, col_offset })
  end)
end

return M
