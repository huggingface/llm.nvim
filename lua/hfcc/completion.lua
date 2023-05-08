local api = vim.api
local fn = vim.fn
local hf = require("hfcc.hf")
local utils = require("hfcc.utils")
local M = {}

function M.complete()
  local before_table = api.nvim_buf_get_text(0, 0, 0, fn.line(".") - 1, fn.col("."), {})
  local before = table.concat(before_table, "\n")

  local after_table = api.nvim_buf_get_text(0, fn.line(".") - 1, fn.col("."), -1, -1, {})
  local after = table.concat(after_table, "\n")

  hf.fetch_suggestion({ before = before, after = after }, function(response, r, _)
    local lines = utils.split_str(response, "\n")
    local line = api.nvim_buf_get_lines(0, r - 1, r, false)[1]
    lines[1] = line .. lines[1]
    api.nvim_buf_set_lines(0, r - 1, r, false, lines)
  end)
end

return M
