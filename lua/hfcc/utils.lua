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
  local delimiter_index = string.find(str, delimiter)
  if delimiter_index ~= nil then
    return string.sub(str, delimiter_index + string.len(delimiter))
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

return M
