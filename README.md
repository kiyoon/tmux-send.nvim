# 🖥️👉🖥️ tmux-send.nvim

NeoVim plugin that lets you copy and paste to a different tmux pane.  
Or, you can just copy to the tmux buffer for later.

<img src="https://user-images.githubusercontent.com/12980409/205471326-27ef838a-c164-42a7-a576-2f5af3be95a8.gif" width="100%"/>

- For **interactive development**, similar to Jupyter Notebook. You can paste your code on a bash shell or an ipython interpreter.
- Detects vim/neovim and ipython running, and paste within an appropriate paste mode.

## Compatible Plugins

- It will detect [Nvim-Tree](https://github.com/nvim-tree/nvim-tree), [neo-tree](https://github.com/nvim-neo-tree/neo-tree.nvim), [oil.nvim](https://github.com/stevearc/oil.nvim) and copy-paste the file's absolute path.  
- It works great with [treemux](https://github.com/kiyoon/treemux) which shows Nvim-Tree within tmux! Make your terminal like an IDE.

## 🛠️ Installation

With lazy.nvim,

```lua
  {
    "kiyoon/tmux-send.nvim",
    keys = {
      {
        "-",
        function()
          require("tmux_send").send_to_pane()
          -- (Optional) exit visual mode after sending
          vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<esc>", true, false, true), "x", true)
        end,
        mode = { "n", "x" },
        desc = "Send to tmux pane",
      },
      {
        "_",
        function()
          require("tmux_send").send_to_pane({ add_newline = false })
          vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<esc>", true, false, true), "x", true)
        end,
        mode = { "n", "x" },
        desc = "Send to tmux pane (plain)",
      },
      {
        "<space>-",
        function()
          require("tmux_send").send_to_pane({ count_is_uid = true })
          vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<esc>", true, false, true), "x", true)
        end,
        mode = { "n", "x" },
        desc = "Send to tmux pane w/ pane uid",
      },
      {
        "<space>_",
        function()
          require("tmux_send").send_to_pane({ count_is_uid = true, add_newline = false })
          vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<esc>", true, false, true), "x", true)
        end,
        mode = { "n", "x" },
        desc = "Send to tmux pane w/ pane uid (plain)",
      },
      {
        "<C-_>",
        function()
          require("tmux_send").save_to_tmux_buffer()
          vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<esc>", true, false, true), "x", true)
        end,
        mode = { "n", "x" },
        desc = "Save to tmux buffer",
      },
    },
  },
```

1. All functions support normal (n) and visual (x) modes. Normal mode mappings will send a single line.
2. Choose pane with relative ID or unique ID (uid).
  - uid makes it possible to send over sessions.
  - For example, `5-` will paste selection (or current line) to the .5 pane.
  - `5<space>-` will paste selection (or current line) to the %5 pane.
  - Use `set -g pane-border-format "#D"` in the tmux.conf to see the pane unique identifier.
3. Choose window by giving number >= 10.
  - For example, `12-` will paste selection (or current line) to window 1 pane 2.
  - `123-` will paste selection (or current line) to window 12 pane 3.
4. Use `<C-_>` to copy into the tmux buffer. You can paste using `Prefix + ]`
5. Omitting the number (e.g. running `-`) will use the previous pane again.


### Recommended tmux.conf settings
```tmux
# Set the base index for windows to 1 instead of 0.
set -g base-index 1

# Set the base index for panes to 1 instead of 0.
setw -g pane-base-index 1

# Show pane details.
set -g pane-border-status top
set -g pane-border-format ' .#P (#D) #{pane_current_command} '
```

### Recommended Nvim-Tree settings

If using the example key bindings above, it is recommended to change Nvim-Tree's keybinding (remove '-' and use 'u' instead):

```lua
local function nvim_tree_on_attach(bufnr)
  local api = require "nvim-tree.api"
  api.config.mappings.default_on_attach(bufnr)

  local function opts(desc)
    return { desc = "nvim-tree: " .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
  end

  vim.keymap.set("n", "u", api.tree.change_root_to_parent, opts "Up")
  vim.keymap.set("n", "-", "", { buffer = bufnr })
  vim.keymap.del("n", "-", { buffer = bufnr })
end

require("nvim-tree").setup({
  on_attach = nvim_tree_on_attach,
  -- ...
})
```

### Recommended oil.nvim settings

If using the example key bindings above, it is recommended to change oil.nvim's keybinding (remove '-' and use 'U' instead):

```lua
require("oil").setup({
  keymaps = {
    -- ["-"] = "actions.parent",
    ["U"] = "actions.parent",
  },
})
```

## Related project
- [vim-slime](https://github.com/jpalardy/vim-slime)
  - Differences: vim-slime focuses on sending to REPL for development, whereas tmux-send.nvim is for more general purpose.
  - tmux-send.nvim can choose which pane to send, even in different windows, different session etc. 
  - tmux-send.nvim can detect the target pane's running program for a better experience (e.g. detects vim and paste in paste mode)
  - tmux-send.nvim does not rely on LSP so it's lighter. Just grab the exact part you need.
    - Tip: use [treesitter-textobjects](https://github.com/nvim-treesitter/nvim-treesitter-textobjects) to easily select function/class/if/loop etc.  
  - tmux-send.nvim can send [Nvim-Tree](https://github.com/nvim-tree/nvim-tree) (and others) files with absolute path to another pane.
- [vim-screenpaste](https://github.com/kiyoon/vim-screenpaste) if you're using screen.
