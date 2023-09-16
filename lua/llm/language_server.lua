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
    else
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
  local unzip_command = "gunzip " .. path .. ".gz"
  local chmod_command = "chmod +x " .. path

  fn.system(download_command)

  fn.system(unzip_command)

  fn.system(chmod_command)
end

local function download_llm_ls()
  local bin_path = config.get().lsp.bin_path
  if bin_path ~= nil and fn.filereadable(bin_path) == 1 then
    return bin_path
  end
  local bin_dir = vim.api.nvim_call_function("stdpath", { "data" }) .. "/llm_nvim/bin"
  fn.system("mkdir -p " .. bin_dir)
  local bin_name = build_binary_name()
  if bin_name == nil then
    return nil
  end
  local full_path = bin_dir .. "/" .. bin_name

  if fn.filereadable(full_path) == 0 then
    local url = build_url(bin_name)
    download_and_unzip(url, full_path)
    vim.notify("[LLM] succefully downloaded llm-ls", vim.log.levels.DEBUG)
  end
  return full_path
end

function M.cancel_request(request_id)
  lsp.get_client_by_id(M.client_id).cancel_request(request_id)
end

function M.extract_generation(response)
  if #response == 0 then
    return ""
  end
  local raw_generated_text = response[1].generated_text
  return raw_generated_text
end

function M.set_configuration() end

function M.get_completions(callback)
  if M.client_id == nil then
    return
  end

  local params = lsp.util.make_position_params()
  params.model = utils.get_model()
  params.model_eos = config.get().model_eos
  params.api_token = config.get().api_token
  params.request_params = config.get().query_params
  params.request_params.do_sample = config.get().query_params.temperature > 0
  params.fim = config.get().fim
  params.tokenizer_path = config.get().tokenizer_path
  params.context_window = config.get().context_window
  params.tls_skip_verify_insecure = config.get().tls_skip_verify_insecure

  local client = lsp.get_client_by_id(M.client_id)
  if client ~= nil then
    local status, request_id = client.request("llm-ls/getCompletions", params, callback, 0)

    if not status then
      vim.notify("[LLM] request to llm-ls failed", vim.log.levels.WARN)
    end

    return request_id
  else
    return nil
  end
end

function M.setup()
  if M.setup_done then
    return
  end

  local llm_ls_path = download_llm_ls()
  if llm_ls_path == nil then
    vim.notify("[LLM] failed to download llm-ls", vim.log.levels.ERROR)
    return
  end

  local client_id = lsp.start({
    name = "llm-ls",
    cmd = { llm_ls_path },
    root_dir = vim.fs.dirname(vim.fs.find({ ".git" }, { upward = true })[1]),
  })

  if client_id == nil then
    vim.notify("[LLM] Error starting llm-ls", vim.log.levels.ERROR)
  else
    local augroup = "llm.language_server"

    api.nvim_create_augroup(augroup, { clear = true })

    api.nvim_create_autocmd("BufEnter", {
      pattern = "*",
      callback = function(ev)
        if not lsp.buf_is_attached(ev.buf, client_id) then
          lsp.buf_attach_client(ev.buf, client_id)
        end
      end,
    })
    M.client_id = client_id
  end

  M.setup_done = true
end

return M
