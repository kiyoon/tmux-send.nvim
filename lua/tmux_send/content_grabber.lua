local M = {}

---Get the content of the visual/select mode selection.
---@return string[]
local function get_visual_selection()
  -- Get the start and end positions of the selection
  local _, ls, cs = unpack(vim.fn.getpos("v"))
  local _, le, ce = unpack(vim.fn.getpos("."))

  -- Ensure start position is before end position
  if ls > le or (ls == le and cs > ce) then
    ls, le = le, ls
    cs, ce = ce, cs
  end

  -- Get the lines in the selection
  local lines = vim.api.nvim_buf_get_lines(0, ls - 1, le, false)
  if #lines == 0 then
    return {}
  end

  local mode = vim.api.nvim_get_mode().mode

  if mode == "v" or mode == "vs" or mode == "s" then
    -- Adjust the columns to get correct substring
    lines[#lines] = string.sub(lines[#lines], 1, ce)
    lines[1] = string.sub(lines[1], cs)
  elseif vim.list_contains({ "CTRL-V", "\22", "CTRL-S" }, mode) then
    -- Visual block mode
    if ce < cs then
      cs, ce = ce, cs
    end
    for i, line in ipairs(lines) do
      lines[i] = string.sub(line, cs, ce)
    end
  end

  -- V, S mode: no further processing needed

  return lines
end

---Grab content based on the filetype, vim mode, etc.
---For example, if the filetype is NvimTree, then grab the full path of the file
---In select/visual mode, grab the selected text.
---In other modes, grab the line under the cursor.
---@return string[]
M.smart_grab = function()
  -- NvimTree is open. Get the file path instead of copying the content.
  if vim.bo.filetype == "NvimTree" then
    local nt_api = require("nvim-tree.api")
    local path = nt_api.tree.get_node_under_cursor().absolute_path
    if path == nil then
      local nt_nodes = nt_api.tree.get_nodes()
      path = nt_nodes.absolute_path -- root dir path
    end
    return { " '" .. path .. "'" }
  end

  local mode = vim.api.nvim_get_mode().mode
  -- \22 is the ASCII code for CTRL-V (^V)
  if vim.list_contains({ "v", "V", "vs", "Vs", "s", "S", "CTRL-V", "\22", "CTRL-S" }, mode) then
    return get_visual_selection()
  else
    return { vim.fn.getline(".") }
  end
end

return M
