local utils = require("hfcc.utils")

---@class hfcc_config
local default_config = {
  api_token = "",
  model = "bigcode/starcoder",
}

local M = {
  config = nil,
}

function M.setup(opts)
  if M.config then
    vim.notify("[HFcc] config is already set", vim.log.levels.WARN)
    return M.config
  end

  local config = vim.tbl_deep_extend("force", default_config, opts or {})

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
