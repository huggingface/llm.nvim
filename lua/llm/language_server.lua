local api = vim.api
local config = require("llm.config")
local fn = vim.fn
local loop = vim.loop
local lsp = vim.lsp
local utils = require("llm.utils")

local M = {
  setup_done = false,

  client_id = nil,
}

local function build_binary_name()
  local os_uname = loop.os_uname()
  local arch = os_uname.machine
  local os = os_uname.sysname

  local arch_map = {
    x86_64 = "x86_64",
    i686 = "i686",
    arm64 = "aarch64",
  }

  local os_map = {
    Linux = "unknown-linux-gnu",
    Darwin = "apple-darwin",
    Windows = "pc-windows-msvc",
  }

  if os == "Linux" then
    local linux_distribution = utils.execute_command("cat /etc/os-release | grep '^ID=' | cut -d '=' -f 2")

    if linux_distribution == "alpine" then
      os_map.Linux = "unknown-linux-musl"
    elseif linux_distribution == "raspbian" then
      arch_map.armv7l = "arm"
      os_map.Linux = "unknown-linux-gnueabihf"
      -- else
      -- Add mappings for other distributions as needed
    end
  end

  local arch_prefix = arch_map[arch]
  local os_suffix = os_map[os]

  if not arch_prefix or not os_suffix then
    vim.notify("[LLM] Unsupported architecture or OS: " .. arch .. " " .. os, vim.log.levels.ERROR)
    return nil
  end
  return "llm-ls-" .. arch_prefix .. "-" .. os_suffix
end

local function build_url(bin_name)
  return "https://github.com/huggingface/llm-ls/releases/download/"
    .. config.get().lsp.version
    .. "/"
    .. bin_name
    .. ".gz"
end

local function download_and_unzip(url, path)
  local download_command = "curl -L -o " .. path .. ".gz " .. url
  local unzip_command = "gunzip -c " .. path .. ".gz > " .. path
  local chmod_command = "chmod +x " .. path
  local clean_zip_command = "rm " .. path .. ".gz"

  fn.system(download_command)

  fn.system(unzip_command)

  fn.system(chmod_command)

  fn.system(clean_zip_command)
end

local function download_llm_ls()
  local bin_dir = vim.api.nvim_call_function("stdpath", { "data" }) .. "/llm_nvim/bin"
  fn.system("mkdir -p " .. bin_dir)
  local bin_name = build_binary_name()
  if bin_name == nil then
    return nil
  end
  local full_path = bin_dir .. "/" .. bin_name .. "-" .. config.get().lsp.version

  if fn.filereadable(full_path) == 0 then
    local url = build_url(bin_name)
    download_and_unzip(url, full_path)
    vim.notify("[LLM] successfully downloaded llm-ls", vim.log.levels.INFO)
  end
  return full_path
end

function M.cancel_request(request_id)
  local client = lsp.get_client_by_id(M.client_id)
  if client ~= nil then
    client.cancel_request(request_id)
  end
end

function M.extract_generation(response)
  if #response == 0 then
    return ""
  end
  local raw_generated_text = response[1].generated_text
  return raw_generated_text
end

function M.get_completions(callback)
  if M.client_id == nil then
    return
  end
  if not lsp.buf_is_attached(0, M.client_id) then
    return
  end

  local params = lsp.util.make_position_params()
  params.model = utils.get_model()
  params.backend = config.get().backend
  params.url = utils.get_url()
  params.requestBody = config.get().request_body
  params.tokensToClear = config.get().tokens_to_clear
  params.apiToken = config.get().api_token
  params.fim = config.get().fim
  local tokenizerConfig = config.get().tokenizer
  if tokenizerConfig ~= nil and tokenizerConfig.repository ~= nil and tokenizerConfig.api_token == nil then
    tokenizerConfig.api_token = config.get_token()
  end
  params.tokenizerConfig = tokenizerConfig
  params.contextWindow = config.get().context_window
  params.tlsSkipVerifyInsecure = config.get().tls_skip_verify_insecure
  params.ide = "neovim"
  params.disableUrlPathCompletion = config.get().disable_url_path_completion

  local client = lsp.get_client_by_id(M.client_id)
  if client ~= nil then
    local status, request_id = client.request("llm-ls/getCompletions", params, callback, 0)

    if not status then
      vim.notify("[LLM] request 'llm-ls/getCompletions' failed", vim.log.levels.WARN)
    end

    return request_id
  else
    return nil
  end
end

function M.accept_completion(completion_result)
  local params = {}
  params.requestId = completion_result.request_id
  params.acceptedCompletion = 0
  params.shownCompletions = { 0 }
  params.completions = completion_result.completions
  local client = lsp.get_client_by_id(M.client_id)
  if client ~= nil then
    local status, _ = client.request("llm-ls/acceptCompletion", params, function() end, 0)

    if not status then
      vim.notify("[LLM] request 'llm-ls/acceptCompletions' failed", vim.log.levels.WARN)
    end
  end
end

function M.reject_completion(completion_result)
  local params = {}
  params.requestId = completion_result.request_id
  params.shownCompletions = { 0 }
  local client = lsp.get_client_by_id(M.client_id)
  if client ~= nil then
    local status, _ = client.request("llm-ls/rejectCompletion", params, function() end, 0)

    if not status then
      vim.notify("[LLM] request 'llm-ls/rejectCompletions' failed", vim.log.levels.WARN)
    end
  end
end

function M.setup()
  if M.setup_done then
    return
  end

  local cmd
  local host = config.get().lsp.host
  local bin_path = config.get().lsp.bin_path or "llm-ls"

  if host == "localhost" then
    host = "127.0.0.1"
  end
  local port = config.get().lsp.port
  if host ~= nil and port ~= nil then
    cmd = lsp.rpc.connect(host, port)
  elseif fn.executable(bin_path) == 0 then
    local llm_ls_path = download_llm_ls()
    if llm_ls_path == nil then
      vim.notify("[LLM] failed to download llm-ls", vim.log.levels.ERROR)
      return
    end
    cmd = { llm_ls_path }
  else
    cmd = { bin_path }
  end

  local client_id = lsp.start_client({
    name = "llm-ls",
    cmd = cmd,
    cmd_env = config.get().lsp.cmd_env,
    root_dir = vim.fs.dirname(vim.fs.find({ ".git" }, { upward = true })[1]),
  })

  if client_id == nil then
    vim.notify("[LLM] Error starting llm-ls", vim.log.levels.ERROR)
  else
    local augroup = "llm.language_server"

    api.nvim_create_augroup(augroup, { clear = true })

    api.nvim_create_autocmd("BufEnter", {
      group = augroup,
      pattern = config.get().enable_suggestions_on_files,
      callback = function(ev)
        if not lsp.buf_is_attached(ev.buf, client_id) then
          lsp.buf_attach_client(ev.buf, client_id)
        end
      end,
    })
    M.client_id = client_id

    api.nvim_create_autocmd("VimLeavePre", {
      group = augroup,
      callback = function()
        lsp.stop_client(client_id)
      end,
    })
  end

  M.setup_done = true
end

return M
