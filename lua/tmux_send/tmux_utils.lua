local config = require("tmux_send.config")
local utils = require("tmux_send.utils")
local notify = require("tmux_send.notify").notify

local M = {}

---@param shell_pid string|number
---@return string?
local function full_command_of_shell(shell_pid)
  ---@diagnostic disable-next-line: cast-local-type
  shell_pid = tonumber(shell_pid)
  if shell_pid == nil then
    notify("Invalid shell_pid", vim.log.levels.ERROR, { title = "tmux-send.nvim" })
    return nil
  end

  local ps_output = vim.fn.systemlist("ps -e -o ppid= -o command=")

  for _, line in ipairs(ps_output) do
    local ppid, command = line:match("^%s*(%d+)%s+(.+)$")
    ppid = tonumber(ppid)
    if ppid == nil then
      notify("Invalid ppid. This shouldn't happen.", vim.log.levels.ERROR, { title = "tmux-send.nvim" })
      return nil
    end

    if ppid == shell_pid then
      return command
    end
  end

  -- it's a shell
  return ""
end

---Returns full command executing from that pane, similar to:
---`tmux display -pt [pane identifier] '#{pane_current_command}'`
---But this script will return the full command.
---@param pane_identifier string e.g. (session:0.left or %2)
---@return string?
M.full_command_of_pane = function(pane_identifier)
  if vim.fn.executable("tmux") == 0 then
    notify("tmux command not found.", vim.log.levels.ERROR, { title = "tmux-send.nvim" })
    return nil
  end

  local list_pane = vim.fn.system("tmux list-panes -t '" .. pane_identifier .. "'")
  if vim.v.shell_error ~= 0 or list_pane == nil or list_pane == "" then
    notify(
      "Can't find the tmux pane using the identifier " .. pane_identifier,
      vim.log.levels.ERROR,
      { title = "tmux-send.nvim" }
    )
    return nil
  end

  -- `tmux display` doesn't match strictly and it will give you any pane if not found.
  local pane_pid = vim.fn.system("tmux display -pt '" .. pane_identifier .. "' '#{pane_pid}'")
  if vim.v.shell_error ~= 0 or pane_pid == nil or pane_pid == "" then
    notify(
      "Can't find the tmux pane using the identifier " .. pane_identifier,
      vim.log.levels.ERROR,
      { title = "tmux-send.nvim" }
    )
    return nil
  end

  return full_command_of_shell(pane_pid)
end

---@param pane_identifier string e.g. (session:0.left or %2)
---@return string?
M.short_command_of_panel = function(pane_identifier)
  if vim.fn.executable("tmux") == 0 then
    notify("tmux command not found.", vim.log.levels.ERROR, { title = "tmux-send.nvim" })
    return nil
  end

  local pane_short_command = vim.fn.system("tmux display -pt '" .. pane_identifier .. "' '#{pane_current_command}'")
  if vim.v.shell_error ~= 0 or pane_short_command == nil or pane_short_command == "" then
    notify("Can't find the tmux pane using the identifier " .. pane_identifier, "error", { title = "tmux-send.nvim" })
    return nil
  end

  return vim.trim(pane_short_command)
end

---Returns the program type of the pane.
---@param pane_identifier string e.g. (session:0.left or %2)
---@return string? 'shell', 'vim', 'ipython', 'others' or nil if no pane found.
M.program_type_of_pane = function(pane_identifier)
  local full_command = M.full_command_of_pane(pane_identifier)
  if full_command == nil then
    return nil
  end

  if full_command == "" then
    return "shell"
  end

  local short_command = M.short_command_of_panel(pane_identifier)
  if short_command == nil then
    return nil
  end

  if short_command == "vi" or short_command == "vim" or short_command == "nvim" then
    return "vim"
  end

  if string.match(full_command, "/ipython ") then
    return "ipython"
  end

  return "others"
end

---@class TmuxSend.AddBufferOptions
---@field strip_empty_lines boolean

---Add content to the Tmux buffer.
---Paste using C-a ]
---@param content string|string[]
---@param buffer_name string
---@param opts TmuxSend.AddBufferOptions
---@return string[]? content Content actually added to the buffer after processing, split by new lines. Nil if error.
M.add_buffer = function(content, buffer_name, opts)
  local split_content
  if type(content) == "table" then
    split_content = utils.list_strip_empty_lines(content)
  elseif type(content) == "string" then
    split_content = vim.split(content, "\n", { plain = true, trimempty = opts.strip_empty_lines })
  else
    notify("Invalid content type", vim.log.levels.ERROR, { title = "tmux-send.nvim" })
    return
  end

  if #split_content == 0 then
    -- If the content is empty, tmux may not update the buffer with an empty string.
    vim.fn.system("tmux set-buffer -b " .. buffer_name .. " '\n'")
  else
    vim.fn.system("tmux load-buffer -b " .. buffer_name .. " -", split_content)
  end

  return split_content
end

---@class TmuxSend.PasteToPaneOptions
---@field add_newline boolean If true, then add a new line (or two) at the end.
---@field target_program string? Only 'ipython' has a special case for now.

---Paste content to the targetPane and sets config.previous_pane.
---@param content string|string[]
---@param pane_identifier string
---@param opts TmuxSend.PasteToPaneOptions
---@return string? pasted_pane_name Pasted pane name or nil if no pane found.
M.paste_to_pane = function(content, pane_identifier, opts)
  local target_program = opts.target_program or "others"

  local list_pane = vim.fn.system("tmux list-panes -t '" .. pane_identifier .. "'")
  if vim.v.shell_error ~= 0 or list_pane == nil or list_pane == "" then
    notify(
      "Can't find the tmux pane using the identifier " .. pane_identifier,
      vim.log.levels.ERROR,
      { title = "tmux-send.nvim" }
    )
    return nil
  end

  local content_processed
  if target_program == "ipython" then
    content_processed = M.add_buffer(content, "tmux-send-nvim-temp", { strip_empty_lines = true })
  else
    content_processed = M.add_buffer(content, "tmux-send-nvim-temp", { strip_empty_lines = false })
  end

  vim.fn.system("tmux paste-buffer -t '" .. pane_identifier .. "' -b tmux-send-nvim-temp -p")

  if opts.add_newline then
    vim.fn.system("tmux send-keys -t '" .. pane_identifier .. "' " .. "Enter")
    if target_program == "ipython" and #content_processed > 1 then
      -- ipython needs two empty lines to execute the code.
      -- with an exception that it is a single line.
      vim.fn.system("tmux send-keys -t '" .. pane_identifier .. "' " .. "Enter")
    end
  end

  local pasted_pane_name = vim.trim(
    vim.fn.system("tmux display -pt '" .. pane_identifier .. "' '#{session_name}:#{window_index}.#{pane_index}'")
  )

  notify(
    "Pasted to tmux: " .. pasted_pane_name .. " (" .. target_program .. ")",
    vim.log.levels.INFO,
    { title = "tmux-send.nvim" }
  )

  config.previous_pane = pane_identifier
  return pasted_pane_name
end

---Returns the tmux pane identifier from v:count.
---If count < 10, then it will find the pane within the same window. (.1, .2, ...)
---If count >= 10, then it will find the window and pane with the index. (11 -> 1.1, 12 -> 1.2, 123 -> 12.3, ...)
---
---## Recommended tmux.conf settings
---```tmux
---# Set the base index for windows to 1 instead of 0.
---set -g base-index 1
--
---# Set the base index for panes to 1 instead of 0.
---setw -g pane-base-index 1
--
---# Show pane details.
---set -g pane-border-status top
---set -g pane-border-format ' .#P (#D) #{pane_current_command} '
---```
---@param count number
---@return string?
M.count_to_pane_id = function(count)
  if count == 0 then
    return config.previous_pane
  end

  local count_str = tostring(count)
  return count_str:sub(1, -2) .. "." .. count_str:sub(-1)
end

return M
