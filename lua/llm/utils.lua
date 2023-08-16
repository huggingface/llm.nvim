local config = require("llm.config")
local M = {}

function M.dump_table(o)
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

function M.string_after_delim(str, delimiter)
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

function M.split_str(str, separator)
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

function M.rstrip(s)
  return string.gsub(s, "\n*$", "")
end

function M.startswith(str, begin)
  return str:sub(1, #begin) == begin
end

function M.get_cursor_pos()
  return unpack(vim.api.nvim_win_get_cursor(0))
end

function M.get_url()
  local model = os.getenv("LLM_NVIM_MODEL")
  if model == nil then
    model = config.get().model
  end
  if M.startswith(model, "http://") or M.startswith(model, "https://") then
    return model
  else
    return "https://api-inference.huggingface.co/models/" .. model
  end
end

return M
