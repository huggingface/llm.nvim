local config = require("llm.config")
local M = {}

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

function M.trim(s)
  return string.gsub(s, "^%s*(.-)%s*$", "%1")
end

function M.startswith(str, begin)
  return str:sub(1, #begin) == begin
end

function M.get_cursor_pos()
  return unpack(vim.api.nvim_win_get_cursor(0))
end

function M.get_model()
  local model = os.getenv("LLM_NVIM_MODEL")
  if model == nil then
    model = config.get().model
  end
  return model
end

function M.get_url()
  local model = os.getenv("LLM_NVIM_URL")
  if model == nil then
    model = config.get().url
  end
  return model
end

function M.ends_with(str, ending)
  return ending == "" or string.sub(str, -string.len(ending)) == ending
end

function M.insert_at(dst, at, src)
  at = math.max(1, math.min(at, #dst + 1))

  local before = string.sub(dst, 1, at - 1)
  local after = string.sub(dst, at)

  local result = before .. src
  if not M.ends_with(src, after) then
    result = result .. after
  end

  return result
end

function M.execute_command(command)
  local handle = io.popen(command)
  if handle == nil then
    vim.notify("[LLM] error executing command: " .. command, vim.log.levels.ERROR)
    return nil
  end
  local result = M.trim(handle:read("*a"))
  handle:close()
  return result
end

return M
