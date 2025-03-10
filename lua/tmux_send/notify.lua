local M = {}

---@param message string|string[]
---@param level integer
---@param opts table
M.notify = function(message, level, opts)
  if type(message) == "string" then
    vim.notify(message, level, opts)
  else
    vim.notify(table.concat(message, "\n"), level, opts)
  end
end

return M
