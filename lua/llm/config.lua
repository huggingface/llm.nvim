---@class llm_config
local default_config = {
  api_token = nil,
  model = "bigcode/starcoder2-15b",
  backend = "huggingface",
  url = nil,
  tokens_to_clear = { "<|endoftext|>" },
  ---@class llm_config_request_body
  request_body = {
    parameters = {
      max_new_tokens = 60,
      temperature = 0.2,
      top_p = 0.95,
    },
  },
  ---@class llm_config_fim
  fim = {
    enabled = true,
    prefix = "<fim_prefix>",
    middle = "<fim_middle>",
    suffix = "<fim_suffix>",
  },
  debounce_ms = 150,
  keymap = {
    modes = { "i", "n" },
    accept = "<Tab>",
    dismiss = "<S-Tab>",
  },
  tls_skip_verify_insecure = false,
  ---@class llm_config_lsp
  lsp = {
    bin_path = nil,
    host = nil,
    port = nil,
    cmd_env = nil,
    version = "0.5.3",
  },
  tokenizer = nil,
  context_window = 1024,
  enable_suggestions_on_startup = true,
  ---@type string|table
  enable_suggestions_on_files = "*",
  disable_url_path_completion = false,
}

local default_request_bodies = {
  ollama = {
    options = {
      temperature = 0.2,
      top_p = 0.95,
    },
  },
  openai = {
    temperature = 0.2,
    top_p = 0.95,
  },
}

local M = {
  config = nil,
}

function M.get_token()
  local api_token = os.getenv("LLM_NVIM_HF_API_TOKEN")
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

  if config.backend ~= "huggingface" and config.backend ~= "tgi" then
    local def_req_body = default_request_bodies[config.backend] or {}
    if opts and opts.request_body ~= nil then
      config.request_body = vim.tbl_deep_extend("force", def_req_body, opts.request_body)
    else
      config.request_body = def_req_body
    end
  end

  if config.api_token == nil then
    config.api_token = M.get_token()
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
