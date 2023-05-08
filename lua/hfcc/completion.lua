local api = vim.api
local fn = vim.fn
local hf = require("hfcc.hf")
local utils = require("hfcc.utils")
local M = {}

function M.complete()
  local before_table = api.nvim_buf_get_text(0, 0, 0, fn.line(".") - 1, fn.col(".") - 1, {})
  local before = table.concat(before_table, "\n")

  local after_table =
    api.nvim_buf_get_text(0, fn.line(".") - 1, fn.col(".") - 1, fn.line("$") - 1, fn.col("$,$") - 1, {})
  local after = table.concat(after_table, "\n")

  hf.fetch_suggestion({ before = before, after = after }, function(response)
    local lines = utils.split_str(response, "\n")
    local r, _ = unpack(vim.api.nvim_win_get_cursor(0))
    api.nvim_buf_set_lines(0, r - 1, r - 1, false, lines)
  end)
end

return M
