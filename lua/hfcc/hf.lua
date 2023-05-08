local config = require("hfcc.config")
local fn = vim.fn
local json = vim.json
local utils = require("hfcc.utils")
local M = {}

local function build_inputs(before, after)
  return "<fim_prefix>" .. before .. "<fim_suffix>" .. after .. "<fim_middle>"
end

local function extract_generation(data)
  local decoded_json = json.decode(data[1])
  if decoded_json == nil then
    vim.notify("[HFcc] error getting response from API", vim.log.levels.ERROR)
    return ""
  end
  if decoded_json.error ~= nil then
    vim.notify("[HFcc] " .. decoded_json.error, vim.log.levels.ERROR)
    return ""
  end
  local raw_generated_text = decoded_json[1].generated_text
  local after_fim_mid = utils.string_after_delim(raw_generated_text, "<fim_middle>")
  if after_fim_mid == nil then
    return ""
  end
  return utils.rstrip(after_fim_mid:gsub("<|endoftext|>", ""))
end

local function get_url()
  local model = config.get("model")
  if utils.startswith(model, "http://") or utils.startswith(model, "https://") then
    return model
  else
    return "https://api-inference.huggingface.co/models/" .. model
  end
end

M.fetch_suggestion = function(request, callback)
  local api_token = config.get("api_token")
  if api_token == "" then
    vim.notify("[HFcc] api token is empty, suggestion might not work", vim.log.levels.WARN)
  end
  local query =
      'curl "' .. get_url() .. '" \z
      -H "Content-type: application/json" \z
      -H "Authorization: Bearer ' .. api_token .. '" \z
      -d@/tmp/inputs.json'
  local request_body = {
    inputs = build_inputs(request.before, request.after)
  }
  local f = assert(io.open("/tmp/inputs.json", "w"))
  f:write(json.encode(request_body))
  f:close()
  local row, col = utils.get_cursor_pos()
  fn.jobstart(query, {
    on_stdout = function(jobid, data, event)
      if data[1] ~= "" then
        callback(extract_generation(data), row, col)
      end
    end,
  })
end

return M
