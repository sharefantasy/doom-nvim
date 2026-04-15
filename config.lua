-- 优先加载编译后的 Fennel 配置，失败时回退到 Lua 配置
local ok = pcall(require, "user.config")
if not ok then
  gentlewind.colorscheme = "gruvbox"
  if pcall(require, "gentlewind.modules.config.ui") then
    require("gentlewind.modules.config.ui").setup()
  end
end
