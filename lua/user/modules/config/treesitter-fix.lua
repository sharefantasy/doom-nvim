-- Treesitter重复安装修复
-- 防止每次打开文件都重新安装treesitter

local M = {}

-- 已安装语法的缓存
local installed_grammars = {}

-- 检查语法是否已安装
local function is_grammar_installed(lang)
  if installed_grammars[lang] ~= nil then
    return installed_grammars[lang]
  end
  
  local ok, parsers = pcall(require, "nvim-treesitter.parsers")
  if not ok then
    return false
  end
  
  -- 检查是否已安装
  local installed = parsers.has_parser(lang)
  installed_grammars[lang] = installed
  return installed
end

-- 获取已安装的语法列表
local function get_installed_grammars()
  local ok, parsers = pcall(require, "nvim-treesitter.parsers")
  if not ok then
    return {}
  end
  
  local installed = {}
  local configs = require("nvim-treesitter.configs")
  if configs and configs.get_ensure_installed_parsers then
    -- 使用treesitter的API获取已安装列表
    for _, lang in ipairs(configs.get_ensure_installed_parsers()) do
      installed[lang] = true
    end
  end
  
  return installed
end

-- 修复的treesitter安装函数
local function safe_ensure_installed(grammars)
  if type(grammars) == "string" then
    grammars = {grammars}
  end
  
  local to_install = {}
  
  for _, lang in ipairs(grammars) do
    if not is_grammar_installed(lang) then
      table.insert(to_install, lang)
    end
  end
  
  if #to_install > 0 then
    local install = require("nvim-treesitter.install")
    install.ensure_installed(to_install)
  end
end

-- 主设置函数
M.setup = function()
  -- 覆盖原有的treesitter安装函数
  local langs_utils = require("gentlewind.modules.langs.utils")
  local original_use_tree_sitter = langs_utils.use_tree_sitter
  
  langs_utils.use_tree_sitter = function(grammars)
    safe_ensure_installed(grammars)
  end
  
  -- 添加状态检查命令
  vim.api.nvim_create_user_command("TreesitterStatus", function()
    local ok, parsers = pcall(require, "nvim-treesitter.parsers")
    if not ok then
      print("Treesitter not available")
      return
    end
    
    local installed = get_installed_grammars()
    local count = 0
    for _ in pairs(installed) do
      count = count + 1
    end
    
    print(string.format("Treesitter status: %d grammars installed", count))
    
    -- 显示缓存状态
    local cache_count = 0
    for _ in pairs(installed_grammars) do
      cache_count = cache_count + 1
    end
    
    print(string.format("Cache status: %d grammars cached", cache_count))
  end, { desc = "Show treesitter installation status" })
  
  -- 添加清除缓存命令
  vim.api.nvim_create_user_command("TreesitterClearCache", function()
    installed_grammars = {}
    print("Treesitter cache cleared")
  end, { desc = "Clear treesitter installation cache" })
end

return M
