local config = require("llm.config")
local fn = vim.fn
local json = vim.json
local utils = require("llm.utils")

local M = {}

local function build_inputs(before, after)
  local fim = config.get().fim
  if fim.enabled then
    return fim.prefix .. before .. fim.suffix .. after .. fim.middle
  else
    return before
  end
end

local function extract_generation(data)
  local decoded_json = json.decode(data[1])
  if decoded_json == nil then
    vim.notify("[LLM] error getting response from API", vim.log.levels.ERROR)
    return ""
  end
  if decoded_json.error ~= nil then
    vim.notify("[LLM] " .. decoded_json.error, vim.log.levels.ERROR)
    return ""
  end
  if #decoded_json > 0 then
    return decoded_json[1].generated_text
  else
    return decoded_json.generated_text
  end
end

local function build_payload(request)
  local params = config.get().query_params
  local request_body = {
    inputs = build_inputs(request.before, request.after),
    parameters = {
      max_new_tokens = params.max_new_tokens,
      temperature = params.temperature,
      do_sample = params.temperature > 0,
      top_p = params.top_p,
      -- return_full_text = false,
    },
  }
  if params.stop_tokens ~= nil then
    request_body.parameters.stop = params.stop_tokens
  end
  local f = assert(io.open(os.getenv("HOME") .. "/.tmp_llm_inputs.json", "w"))
  f:write(json.encode(request_body))
  f:close()
end

local function build_curl_options()
  local curl_options = ""
  local tls_skip_verify_insecure = config.get().tls_skip_verify_insecure
  if tls_skip_verify_insecure == true then
    curl_options = curl_options .. " --insecure "
  end
  return curl_options
end

local function get_authorization_header()
  local api_token = config.get().api_token
  if api_token == nil then
    return ""
  else
    return '-H "Authorization: Bearer ' .. api_token .. '" '
  end
end

function M.fetch_suggestion(request, callback)
  local query = 'curl "'
    .. utils.get_url()
    .. '" -H "Content-type: application/json" '
    .. get_authorization_header()
    .. "-d@"
    .. os.getenv("HOME")
    .. "/.tmp_llm_inputs.json"
    .. build_curl_options()
  build_payload(request)
  local row, col = utils.get_cursor_pos()
  return fn.jobstart(query, {
    stdout_buffered = true,
    on_stdout = function(jobid, data, event)
      if data[1] ~= "" then
        callback(extract_generation(data), row, col)
      end
    end,
  })
end

return M
