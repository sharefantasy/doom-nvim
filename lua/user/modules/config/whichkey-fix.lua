-- which-key修复配置
-- 解决描述不显示的问题

local M = {}

M.setup = function()
  -- 确保which-key可用
  local wk_avail, wk = pcall(require, "which-key")
  if not wk_avail then
    return
  end

  -- which-key v3: 避免使用已弃用的 opts（如 ignore_missing/hidden/triggers_blacklist/window 等），
  -- 否则会在启动时提示 “There are issues with your config ...”。
  -- 这里只保留必要且兼容的配置，避免覆盖 Gentlewind 内置的 whichkey 配置太多。
  wk.setup {
    preset = "modern",
    icons = {
      breadcrumb = "»",
      separator = "➜",
      group = "+",
    },
    win = {
      border = "rounded",
      padding = { 1, 2 },
      zindex = 1000,
    },
    layout = {
      width = { min = 20 },
      spacing = 3,
    },
    keys = {
      scroll_down = "<c-d>",
      scroll_up = "<c-u>",
    },
    disable = {
      ft = {},
      bt = {},
    },
  }
end

return M
