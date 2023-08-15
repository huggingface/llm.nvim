local M = {}

M.dump_table = function(o)
  if type(o) == "table" then
    local s = "{ "
    for k, v in pairs(o) do
      if type(k) ~= "number" then
        k = '"' .. k .. '"'
      end
      s = s .. "[" .. k .. "] = " .. M.dump_table(v) .. ","
    end
    return s .. "} "
  else
    return tostring(o)
  end
end

M.string_after_delim = function(str, delimiter)
  local delimiter_index = string.find(str, delimiter, 1, true)
  local last_index = nil
  while delimiter_index do
    last_index = delimiter_index
    delimiter_index = string.find(str, delimiter, last_index + 1, true)
  end
  if last_index ~= nil then
    return string.sub(str, last_index + string.len(delimiter))
  else
    return nil
  end
end

M.split_str = function(str, separator)
  local parts = {}
  local start = 1
  local split_start, split_end = string.find(str, separator, start)

  while split_start do
    table.insert(parts, string.sub(str, start, split_start - 1))
    start = split_end + 1
    split_start, split_end = string.find(str, separator, start)
  end

  table.insert(parts, string.sub(str, start))
  return parts
end

M.rstrip = function(s)
  return string.gsub(s, "\n*$", "")
end

M.startswith = function(str, begin)
  return str:sub(1, #begin) == begin
end

M.get_cursor_pos = function()
  return unpack(vim.api.nvim_win_get_cursor(0))
end

return M
