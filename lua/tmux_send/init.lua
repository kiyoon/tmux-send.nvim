local tmux_utils = require("tmux_send.tmux_utils")
local notify = require("tmux_send.notify").notify
local content_grabber = require("tmux_send.content_grabber")

local M = {}

---@class TmuxSend.SendOptions
---@field pane_identifier string? If specified, ignore the count and send to the specific pane.
---@field count_is_uid boolean? If true, the count is the unique pane identifier. e.g. 5- sends text to %5. If false, the count is the window and pane number. e.g. 5 sends text to .5, 15 sends to 1.5 (window 1, pane 5).
---@field add_newline boolean? If true, add a newline at the end of the content. Default is true.

---Send the content to the tmux pane.
---If the count is given, it sends to the specific pane.
---Otherwise, it sends to the previous pane which is not set yet.
---@param opts TmuxSend.SendOptions?
M.send_to_pane = function(opts)
  opts = opts or {}
  local add_newline = opts.add_newline == nil or opts.add_newline
  ---@cast add_newline boolean
  local count_is_uid = opts.count_is_uid == nil and false or opts.count_is_uid
  ---@cast count_is_uid boolean

  local target_pane
  if opts.pane_identifier ~= nil then
    target_pane = opts.pane_identifier
  else
    if not count_is_uid and (vim.env.TMUX == nil or vim.env.TMUX == "") then
      notify(
        "You are not in a tmux session. Use opts.count_is_uid = true. e.g. 5- sends text to %5.",
        vim.log.levels.ERROR({ title = "tmux-send.nvim" })
      )
      return
    end

    local count = vim.v.count
    if count_is_uid then
      target_pane = "%" .. count
    else
      target_pane = tmux_utils.count_to_pane_id(count)
      if target_pane == nil then
        notify({
          "Can't find the tmux pane using the identifier " .. count,
          "Use <number> + <keymap> to send to a specific pane, otherwise it sends to the previous pane which is not set yet.",
        }, vim.log.levels.ERROR, { title = "tmux-send.nvim" })
        return
      end
      ---@cast target_pane -?
    end
  end

  local target_program = tmux_utils.program_type_of_pane(target_pane)
  if target_program == nil then
    return
  end

  local content = content_grabber.smart_grab()

  tmux_utils.paste_to_pane(content, target_pane, { add_newline = add_newline, target_program = target_program })
end

M.save_to_tmux_buffer = function()
  local content = content_grabber.smart_grab()
  tmux_utils.add_buffer(content, "tmux-send-nvim", { strip_empty_lines = false })
end

return M
