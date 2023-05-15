---@class hfcc_config
local default_config = {
  api_token = "",
  model = "bigcode/starcoder",
  ---@class hfcc_config_query_params
  query_params = {
    max_new_tokens = 60,
    temperature = 0.2,
    top_p = 0.95,
    stop_token = "<|endoftext|>",
  },
  ---@class hfcc_config_fim
  fim = {
    enabled = true,
    prefix = "<fim_prefix>",
    middle = "<fim_middle>",
    suffix = "<fim_suffix>",
  },
}

local M = {
  config = nil,
}

local function get_token()
  local api_token = os.getenv("HUGGING_FACE_HUB_TOKEN")
  if api_token == nil then
    local default_home = os.getenv("HOME") .. "/.cache"
    local hf_cache_home = os.getenv("HF_HOME") or (default_home .. "/huggingface")
    local f = io.open(hf_cache_home .. "/token", "r")
    if not f then
      api_token = ""
    else
      api_token = f:read("*a")
      f:close()
    end
  end
  return api_token
end

function M.setup(opts)
  if M.config then
    vim.notify("[HFcc] config is already set", vim.log.levels.WARN)
    return M.config
  end

  local config = vim.tbl_deep_extend("force", default_config, opts or {})

  if config.api_token == "" then
    config.api_token = get_token()
  end

  M.config = config

  return M.config
end

---@param key? string
function M.get(key)
  if not M.config then
    error("[HFcc] not initialized")
  end

  if key then
    return M.config[key]
  end

  return M.config
end

return M
