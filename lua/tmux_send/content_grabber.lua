local utils = require("tmux_send.utils")

local M = {}

---Get the content of the visual/select mode selection.
---@return string[]
local function get_visual_selection()
  local c_v = vim.api.nvim_replace_termcodes("<C-v>", true, true, true)
  local modes = { "v", "V", c_v }
  local mode = vim.fn.mode():sub(1, 1)
  if not vim.tbl_contains(modes, mode) then
    return {}
  end

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
  ce = math.min(ce, #lines[#lines])

  if mode == "v" or mode == "V" then
    if vim.fn.has("nvim-0.10") == 1 then
      ce = ce + vim.str_utf_end(lines[#lines], ce)
    end
    if mode == "v" then
      if #lines == 1 then
        return { string.sub(lines[1], cs, ce) }
      end
      lines[1] = string.sub(lines[1], cs)
      lines[#lines] = string.sub(lines[#lines], 1, ce)
    end
  else
    --  TODO: visual block: fix weird behavior when selection include end of line
    local csw = math.min(utils.str_widthindex(lines[1], cs)[1], utils.str_widthindex(lines[#lines], ce)[1])
    local cew = math.max(utils.str_widthindex(lines[1], cs)[2], utils.str_widthindex(lines[#lines], ce)[2])
    for i, line in ipairs(lines) do
      -- byte index for current line from width index
      local csl = utils.str_wbyteindex(line, csw)[1]
      local cel = utils.str_wbyteindex(line, cew)[2]
      if vim.fn.has("nvim-0.10") == 1 then
        csl = csl + vim.str_utf_start(line, csl)
        cel = cel + vim.str_utf_end(line, cel)
      end
      lines[i] = string.sub(line, csl, cel)
    end
  end

  -- local mode = vim.api.nvim_get_mode().mode
  --
  -- if mode == "v" or mode == "vs" or mode == "s" then
  --   -- Adjust the columns to get correct substring
  --   lines[#lines] = string.sub(lines[#lines], 1, ce)
  --   lines[1] = string.sub(lines[1], cs)
  -- elseif vim.list_contains({ "CTRL-V", "\22", "CTRL-S" }, mode) then
  --   -- Visual block mode
  --   if ce < cs then
  --     cs, ce = ce, cs
  --   end
  --   for i, line in ipairs(lines) do
  --     lines[i] = string.sub(line, cs, ce)
  --   end
  -- end
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
  elseif vim.bo.filetype == "neo-tree" then
    local node = require("neo-tree.sources.manager").get_state("filesystem").tree:get_node()
    if node.path ~= nil then
      return { " '" .. node.path .. "'" }
    end

    -- if you are on a message like (2 hidden items), then return empty
    return {}
  elseif vim.bo.filetype == "oil" then
    local oil = require("oil")
    local entry = oil.get_cursor_entry()
    if entry == nil then
      return {}
    end

    local path = oil.get_current_dir() .. entry.name
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
