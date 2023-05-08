local M = {}

local escape_char_map = {
  ["\\"] = "\\\\",
  ['"'] = '\\"',
  ["\b"] = "\\b",
  ["\f"] = "\\f",
  ["\n"] = "\\n",
  ["\r"] = "\\r",
  ["\t"] = "\\t",
}

local function escape_char(c)
  return escape_char_map[c] or string.format("\\u%04x", c:byte())
end

M.json_encode = function(str)
  return str:gsub('[%z\1-\31\\"]', escape_char)
end

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

return M
