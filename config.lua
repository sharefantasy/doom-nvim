-- 优先加载编译后的 Fennel 配置，失败时回退到 Lua 配置
local ok = pcall(require, "user.config")
if not ok then
  doom.colorscheme = "gruvbox"
  if pcall(require, "user.modules.config.ui") then
    require("user.modules.config.ui").setup()
  end
end
