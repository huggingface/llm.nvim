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
  local generated_text = decoded_json[1].generated_text
  return utils.string_after_delim(generated_text, "<fim_middle>"):gsub("<|endoftext|>", "")
end

M.fetch_suggestion = function(request, callback)
  local api_token = config.get("api_token")
  if api_token == "" then
    vim.notify("[HFcc] api token is empty, suggestion might not work", vim.log.levels.WARN)
  end
  local query =
      'curl "https://api-inference.huggingface.co/models/bigcode/starcoder" \z
      -H "Content-type: application/json" \z
      -H "Authorization: Bearer ' .. api_token .. '" \z
      -d@/tmp/inputs.json'
  local inputs = '{"inputs": "' .. utils.json_encode(build_inputs(request.before, request.after)) .. '"}'
  local f = assert(io.open("/tmp/inputs.json", "w"))
  f:write(inputs)
  f:close()
  fn.jobstart(query, {
    on_stdout = function(jobid, data, event)
      if data[1] ~= "" then
        callback(extract_generation(data))
      end
    end,
  })
end

return M
