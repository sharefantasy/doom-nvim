-- Fennel符号修复 - 根本解决方案
-- 专门解决Fennel中Lua符号（vim, doom等）不可见的问题

local M = {}

-- 手动为Fennel文件添加全局变量声明
local function setup_fennel_globals()
  -- 定义Fennel中常用的Lua全局变量
  local fennel_globals = {
    -- 基本Lua函数
    "require", "module", "error", "print", "pairs", "ipairs", 
    "next", "type", "tonumber", "tostring", "pcall", "xpcall",
    
    -- Neovim全局变量
    "vim",
    
    -- Doom Nvim全局变量
    "doom", "_doom",
    
    -- Fennel特殊形式和函数
    "fn", "let", "when", "if", "each", "for", "while", "do", 
    "collect", "icollect", "accumulate", "values", "comment", 
    "hashfn", "lambda", "partial", "pick-args", "pick-values", 
    "doto", "->", "->>", "-?>", "-?>>", "..", "length",
    
    -- 其他常用函数
    "table", "string", "math", "os", "io", "debug", "package",
    "coroutine", "bit", "bit32", "jit", "utf8",
  }
  
  return fennel_globals
end

-- 配置neodev以支持Fennel
local function setup_neodev_for_fennel()
  local neodev_avail, neodev = pcall(require, "neodev")
  if not neodev_avail then
    return false
  end
  
  -- 基础neodev配置
  neodev.setup({
    library = {
      enabled = true,
      runtime = true,
      types = true,
      plugins = true,
    },
    setup_jsonls = true,
    lspconfig = false,
    pathStrict = true,
    filetypes = {"lua", "fennel"},
  })
  
  return true
end

-- 为特定LSP客户端添加全局变量
local function add_globals_to_lsp_client(client_id, globals)
  local client = vim.lsp.get_client_by_id(client_id)
  if not client then return end
  
  -- 为Lua和Fennel LSP添加全局变量
  if client.name == "lua_ls" or client.name == "fennel_ls" then
    local settings = client.config.settings or {}
    settings.diagnostics = settings.diagnostics or {}
    settings.diagnostics.globals = globals
    
    -- 工作区库配置
    settings.workspace = settings.workspace or {}
    settings.workspace.library = settings.workspace.library or {}
    
    -- 添加关键路径
    local library_paths = {
      vim.fn.expand("$VIMRUNTIME/lua"),
      vim.fn.expand("$VIMRUNTIME/lua/vim"),
      vim.fn.getcwd() .. "/lua",
      vim.fn.getcwd() .. "/fnl",
      vim.fn.stdpath("config") .. "/lua",
      vim.fn.stdpath("config") .. "/fnl",
    }
    
    for _, path in ipairs(library_paths) do
      settings.workspace.library[path] = true
    end
    
    -- 更新客户端配置
    client.config.settings = settings
    
    -- 通知LSP更新配置
    if client.notify then
      client.notify("workspace/didChangeConfiguration", { settings = settings })
    end
  end
end

-- 创建Fennel专用的LSP配置
local function setup_fennel_lsp()
  -- 检查fennel-ls是否可用
  local fennel_ls_avail = vim.fn.executable("fennel-ls") == 1
  if not fennel_ls_avail then
  end
  
  -- 配置fennel-ls
  if fennel_ls_avail then
    local configs = require("lspconfig.configs")
    if configs.fennel_ls then
      -- 增强fennel-ls配置
      local original_config = configs.fennel_ls.default_config
      original_config.settings = original_config.settings or {}
      original_config.settings.fennel = original_config.settings.fennel or {}
      original_config.settings.fennel.diagnostics = {
        globals = setup_fennel_globals()
      }
      original_config.settings.fennel.workspace = {
        library = {
          [vim.fn.expand("$VIMRUNTIME/lua")] = true,
          [vim.fn.expand("$VIMRUNTIME/lua/vim")] = true,
          [vim.fn.getcwd() .. "/lua"] = true,
          [vim.fn.getcwd() .. "/fnl"] = true,
        }
      }
    end
  end
end

-- 主设置函数
M.setup = function()
  -- 1. 配置neodev
  setup_neodev_for_fennel()
  
  -- 2. 配置LSP
  setup_fennel_lsp()
  
  -- 3. 创建自动命令
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "fennel",
    callback = function(args)
      local globals = setup_fennel_globals()
      
      -- 获取当前缓冲区的所有LSP客户端
      local clients = vim.lsp.get_active_clients({ bufnr = args.buf })
      for _, client in ipairs(clients) do
        add_globals_to_lsp_client(client.id, globals)
      end
      
      -- 如果没有fennel-ls，尝试启动lua_ls
      local has_fennel_ls = false
      for _, client in ipairs(clients) do
        if client.name == "fennel_ls" then
          has_fennel_ls = true
          break
        end
      end
      
      if not has_fennel_ls then
        -- 尝试启动lua_ls作为备选
        local lua_ls_avail, lua_ls = pcall(require, "lspconfig.lua_ls")
        if lua_ls_avail then
          lua_ls.setup({
            settings = {
              Lua = {
                diagnostics = {
                  globals = globals
                },
                workspace = {
                  library = {
                    [vim.fn.expand("$VIMRUNTIME/lua")] = true,
                    [vim.fn.expand("$VIMRUNTIME/lua/vim")] = true,
                    [vim.fn.getcwd() .. "/lua"] = true,
                    [vim.fn.getcwd() .. "/fnl"] = true,
                  }
                }
              }
            }
          })
          vim.lsp.buf_attach_client(args.buf, 0)
        end
      end
      
      -- 设置一些基本的Fennel键映射
      vim.b[args.buf].localleader = ","
    end,
    group = vim.api.nvim_create_augroup("FennelSymbolFix", { clear = true }),
    desc = "Fix Fennel symbol recognition",
  })
  
  -- 4. 创建测试命令
  vim.api.nvim_create_user_command("FennelTestSymbols", function()
    local bufnr = vim.api.nvim_get_current_buf()
    local ft = vim.bo[bufnr].filetype
    
    print("Current filetype: " .. ft)
    print("Testing symbol access...")
    
    -- 测试基本的符号访问
    local test_cases = {
      'vim.fn.expand "%"',
      'doom.features.lsp',
      'require("doom.utils")',
    }
    
    for _, test in ipairs(test_cases) do
      print("Test: " .. test)
      -- 这里可以添加实际的测试逻辑
    end
    
    -- 显示LSP状态
    local clients = vim.lsp.get_active_clients({ bufnr = bufnr })
    print("Active LSP clients:")
    for _, client in ipairs(clients) do
      print("  - " .. client.name)
      if client.config and client.config.settings then
        local globals = client.config.settings.diagnostics and 
                       client.config.settings.diagnostics.globals
        if globals then
          print("    Globals: " .. table.concat(globals, ", "))
        end
      end
    end
  end, { desc = "Test Fennel symbol access" })
  
  print("Fennel symbol fix setup complete!")
  print("Use :FennelTestSymbols to test symbol access")
end

return M
