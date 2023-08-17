local api = vim.api
local config = require("llm.config")
local lsp = vim.lsp
local utils = require("llm.utils")

local M = {
  setup_done = false,

  client_id = nil,
}

function M.cancel_request(request_id)
  lsp.get_client_by_id(M.client_id).cancel_request(request_id)
end

function M.extract_generation(response)
  if response == nil then
    vim.notify("[LLM] error getting response from llm-ls", vim.log.levels.ERROR)
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
  params.model = utils.get_url()
  params.api_token = config.get().api_token
  params.request_params = config.get().query_params
  params.request_params.do_sample = config.get().query_params.temperature > 0
  params.fim = config.get().fim

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
  if not config.get().lsp.enabled or M.setup_done then
    return
  end

  local client_id = lsp.start({
    name = "llm-ls",
    cmd = { config.get().lsp.bin_path },
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
