-- which-key修复配置
-- 解决描述不显示的问题

local M = {}

M.setup = function()
  -- 确保which-key可用
  local wk_avail, wk = pcall(require, "which-key")
  if not wk_avail then
    return
  end
  
  -- 创建兼容的配置 - 使用新的格式
  local config = {
    preset = "modern",
    icons = {
      breadcrumb = "»", -- symbol used in the command line area that shows your active key combo
      separator = "➜", -- symbol used between a key and it's command
      group = "+", -- symbol prepended to a group
    },
    popup = {
      border = "rounded", -- none, single, double, rounded
      position = "bottom", -- bottom, top
      margin = { 1, 0, 1, 0 }, -- extra window margin [top, right, bottom, left]. When between 0 and 1, will be treated as a percentage of the screen size.
      padding = { 2, 2, 2, 2 }, -- extra window padding [top, right, bottom, left]
      winblend = 0, -- value between 0-100 0 for fully opaque and 100 for fully transparent
      zindex = 1000, -- positive value to position WhichKey above other floating windows.
    },
    layout = {
      height = { min = 4, max = 25 }, -- min and max height of the columns
      width = { min = 20, max = 50 }, -- min and max width of the columns
      spacing = 3, -- spacing between columns
      align = "left", -- align columns left, center or right
    },
    keys = {
      scroll_down = "<c-d>", -- binding to scroll down inside the popup
      scroll_up = "<c-u>", -- binding to scroll up inside the popup
      scroll_left = "<c-left>", -- binding to scroll left inside the popup
      scroll_right = "<c-right>", -- binding to scroll right inside the popup
      close = "<esc>", -- binding to close the popup
      toggle_group = "<space>", -- binding to toggle a group
      toggle_hidden = "<c-h>", -- binding to toggle hidden keymaps
    },
    ignore_missing = false, -- enable this to hide mappings for which you didn't specify a label
    hidden = { "<silent>", "<cmd>", "<Cmd>", "<CR>", "call", "lua", "^:", "^ " },
    show_help = true, -- show a help message in the command line for using WhichKey
    show_keys = true, -- show the currently pressed key and its label as a message in the command line
    triggers = "auto", -- automatically setup triggers
    -- triggers = {"<leader>"} -- or specify a list manually
    triggers_blacklist = {
      -- list of mode / prefixes that should never be hooked by WhichKey
      -- this is mostly relevant for key maps that start with a native binding
      -- most people should not need to change this
      i = { "j", "k" },
      v = { "j", "k" },
    },
    disable = {
      buftypes = {},
      filetypes = {},
    },
  }
  
  -- 应用配置
  wk.setup(config)
end

return M
