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

---@param s string
---@param index integer
---@return integer[]
M.str_widthindex = function(s, index)
  if index < 1 or #s < index then
    -- return full range if index is out of range
    return { 1, vim.api.nvim_strwidth(s) }
  end

  local ws, we, b = 0, 0, 1
  while b <= #s and b <= index do
    local ch = s:sub(b, b + vim.str_utf_end(s, b))
    local wch = vim.api.nvim_strwidth(ch)
    ws = we + 1
    we = ws + wch - 1
    b = b + vim.str_utf_end(s, b) + 1
  end

  return { ws, we }
end

---@param s string
---@param index integer
---@return integer[]
M.str_wbyteindex = function(s, index)
  if index < 1 or vim.api.nvim_strwidth(s) < index then
    -- return full range if index is out of range
    return { 1, #s }
  end

  local b, bs, be, w = 1, 0, 0, 0
  while b <= #s and w < index do
    bs = b
    be = bs + vim.str_utf_end(s, bs)
    local ch = s:sub(bs, be)
    local wch = vim.api.nvim_strwidth(ch)
    w = w + wch
    b = be + 1
  end

  return { bs, be }
end

return M
