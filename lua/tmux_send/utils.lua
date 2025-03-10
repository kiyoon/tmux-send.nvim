local M = {}

---@param lines string[]
---@return string[]
M.list_strip_empty_lines_beginning = function(lines)
  local i = 1
  while lines[i] == "" do
    i = i + 1
  end
  return vim.list_slice(lines, i)
end

---@param lines string[]
---@return string[]
M.list_strip_empty_lines_ending = function(lines)
  local i = #lines
  while lines[i] == "" do
    i = i - 1
  end
  return vim.list_slice(lines, 1, i)
end

---@param lines string[]
---@return string[]
M.list_strip_empty_lines = function(lines)
  return M.list_strip_empty_lines_ending(M.list_strip_empty_lines_beginning(lines))
end

return M
