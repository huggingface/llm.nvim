---@class llm_config
local default_config = {
  api_token = nil,
  model = "bigcode/starcoderbase",
  tokens_to_clear = { "<|endoftext|>" },
  ---@class llm_config_query_params
  query_params = {
    max_new_tokens = 60,
    temperature = 0.2,
    top_p = 0.95,
    ---@type table|nil
    stop_tokens = nil,
  },
  ---@class llm_config_fim
  fim = {
    enabled = true,
    prefix = "<fim_prefix>",
    middle = "<fim_middle>",
    suffix = "<fim_suffix>",
  },
  debounce_ms = 150,
  accept_keymap = "<Tab>",
  dismiss_keymap = "<S-Tab>",
  tls_skip_verify_insecure = false,
  ---@class llm_config_lsp
  lsp = {
    bin_path = nil,
    version = "0.2.1",
  },
  tokenizer = nil,
  context_window = 8192,
}

local M = {
  config = nil,
}

local function get_token()
  local api_token = os.getenv("LLM_NVIM_API_TOKEN")
  if api_token == nil then
    local default_home = ""
    if vim.fn.has("win32") == 1 then
      default_home = os.getenv("USERPROFILE") .. "/.cache"
    else
      default_home = os.getenv("HOME") .. "/.cache"
    end
    local hf_cache_home = os.getenv("HF_HOME") or (default_home .. "/huggingface")
    local f = io.open(hf_cache_home .. "/token", "r")
    if not f then
      api_token = nil
    else
      api_token = string.gsub(f:read("*a"), "[\n\r]", "")
      f:close()
    end
  end
  return api_token
end

function M.setup(opts)
  if M.config then
    vim.notify("[LLM] config is already set", vim.log.levels.WARN)
    return M.config
  end

  local config = vim.tbl_deep_extend("force", default_config, opts or {})

  if config.api_token == nil then
    config.api_token = get_token()
  end

  M.config = config

  return M.config
end

function M.get()
  if not M.config then
    error("[LLM] not initialized")
  end

  return M.config
end

return M
