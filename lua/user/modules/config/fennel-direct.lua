-- Fennel直接LSP配置 - 不依赖neodev
-- 专门解决Fennel中Lua符号不可见的问题

local M = {}

-- 手动为Fennel文件添加全局变量声明
local function get_fennel_globals()
  return {
    -- 基本Lua函数
    "require", "module", "error", "print", "pairs", "ipairs", 
    "next", "type", "tonumber", "tostring", "pcall", "xpcall",
    "assert", "load", "loadfile", "dofile", "getmetatable", "setmetatable",
    "rawget", "rawset", "rawequal", "select", "unpack", "ipairs",
    
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
end

-- 直接配置fennel-ls
local function setup_fennel_ls()
  local configs = require("lspconfig.configs")
  local util = require("lspconfig.util")
  
  -- 如果fennel_ls配置不存在，创建它
  if not configs.fennel_ls then
    configs.fennel_ls = {
      default_config = {
        cmd = {"fennel-ls"},
        filetypes = {"fennel"},
        root_dir = util.root_pattern(".git", "fnl"),
        settings = {
          fennel = {
            diagnostics = {
              globals = get_fennel_globals()
            },
            workspace = {
              library = {
                [vim.fn.expand("$VIMRUNTIME/lua")] = true,
                [vim.fn.expand("$VIMRUNTIME/lua/vim")] = true,
                [vim.fn.getcwd() .. "/lua"] = true,
                [vim.fn.getcwd() .. "/fnl"] = true,
                [vim.fn.stdpath("config") .. "/lua"] = true,
                [vim.fn.stdpath("config") .. "/fnl"] = true,
              },
              maxPreload = 10000,
              preloadFileSize = 1000,
              checkThirdParty = false,
            },
            completion = {
              enable = true,
              callSnippet = "Replace",
            },
            telemetry = {
              enable = false,
            }
          }
        }
      }
    }
  else
    -- 增强现有配置
    local config = configs.fennel_ls.default_config
    config.settings = config.settings or {}
    config.settings.fennel = config.settings.fennel or {}
    config.settings.fennel.diagnostics = {
      globals = get_fennel_globals()
    }
    config.settings.fennel.workspace = {
      library = {
        [vim.fn.expand("$VIMRUNTIME/lua")] = true,
        [vim.fn.expand("$VIMRUNTIME/lua/vim")] = true,
        [vim.fn.getcwd() .. "/lua"] = true,
        [vim.fn.getcwd() .. "/fnl"] = true,
        [vim.fn.stdpath("config") .. "/lua"] = true,
        [vim.fn.stdpath("config") .. "/fnl"] = true,
      }
    }
  end
  
  -- 启动fennel-ls
  local fennel_ls = require("lspconfig.fennel_ls")
  fennel_ls.setup({
    on_attach = function(client, bufnr)
      print("fennel-ls attached to buffer " .. bufnr)
      
      -- 设置缓冲区级别的全局变量
      vim.b[bufnr].fennel_globals = get_fennel_globals()
      
      -- 创建缓冲区命令
      vim.api.nvim_buf_create_user_command(bufnr, "FennelShowGlobals", function()
        local globals = get_fennel_globals()
        print("Available Fennel globals:")
        for i, global in ipairs(globals) do
          print(i .. ". " .. global)
        end
      end, { desc = "Show available Fennel globals" })
      
      -- 设置一些基本的映射
      vim.keymap.set("n", "K", vim.lsp.buf.hover, { buffer = bufnr, desc = "Show documentation" })
      vim.keymap.set("n", "gd", vim.lsp.buf.definition, { buffer = bufnr, desc = "Go to definition" })
      vim.keymap.set("n", "gr", vim.lsp.buf.references, { buffer = bufnr, desc = "Show references" })
    end,
    on_init = function(client)
      print("fennel-ls initialized")
      -- 确保设置全局变量
      local globals = get_fennel_globals()
      if client.config.settings and client.config.settings.fennel then
        client.config.settings.fennel.diagnostics = {
          globals = globals
        }
      end
    end,
    capabilities = require("cmp_nvim_lsp").default_capabilities(),
  })
  
  print("fennel-ls setup complete")
end

-- 配置lua_ls也为Fennel文件提供支持
local function setup_lua_ls_for_fennel()
  local lua_ls = require("lspconfig.lua_ls")
  
  lua_ls.setup({
    filetypes = {"lua", "fennel"}, -- 添加fennel支持
    on_attach = function(client, bufnr)
      if vim.bo[bufnr].filetype == "fennel" then
        print("lua_ls providing Fennel support for buffer " .. bufnr)
      end
    end,
    settings = {
      Lua = {
        runtime = {
          version = "LuaJIT",
          path = vim.split(package.path, ";"),
        },
        diagnostics = {
          enable = true,
          globals = get_fennel_globals(), -- 使用相同的全局变量列表
        },
        workspace = {
          library = {
            [vim.fn.expand("$VIMRUNTIME/lua")] = true,
            [vim.fn.expand("$VIMRUNTIME/lua/vim")] = true,
            [vim.fn.getcwd() .. "/lua"] = true,
            [vim.fn.getcwd() .. "/fnl"] = true,
            [vim.fn.stdpath("config") .. "/lua"] = true,
            [vim.fn.stdpath("config") .. "/fnl"] = true,
          },
          checkThirdParty = false,
          maxPreload = 10000,
          preloadFileSize = 1000,
        },
        completion = {
          enable = true,
          callSnippet = "Replace",
        },
        telemetry = {
          enable = false,
        }
      }
    }
  })
  
  print("lua_ls configured for Fennel support")
end

-- 创建测试命令
local function create_test_commands()
  vim.api.nvim_create_user_command("FennelTestSymbols", function()
    local bufnr = vim.api.nvim_get_current_buf()
    local ft = vim.bo[bufnr].filetype
    
    print("=== Fennel Symbol Test ===")
    print("Current filetype: " .. ft)
    
    -- 显示LSP客户端
    local clients = vim.lsp.get_active_clients({ bufnr = bufnr })
    print("Active LSP clients:")
    for _, client in ipairs(clients) do
      print("  - " .. client.name .. " (attached: " .. tostring(client.attached_buffers[bufnr] ~= nil) .. ")")
      if client.config and client.config.settings then
        local settings = client.config.settings
        if settings.fennel and settings.fennel.diagnostics then
          local globals = settings.fennel.diagnostics.globals
          if globals then
            print("    Fennel globals: " .. table.concat(globals, ", "))
          end
        elseif settings.Lua and settings.Lua.diagnostics then
          local globals = settings.Lua.diagnostics.globals
          if globals then
            print("    Lua globals: " .. table.concat(globals, ", "))
          end
        end
      end
    end
    
    -- 测试基本符号
    print("\nTesting basic symbols:")
    local test_symbols = {"vim", "doom", "require", "fn", "let"}
    for _, symbol in ipairs(test_symbols) do
      print("  - " .. symbol .. ": " .. (vim.fn.exists(symbol) == 1 and "exists" or "not found"))
    end
  end, { desc = "Test Fennel symbol access" })
  
  vim.api.nvim_create_user_command("FennelShowSetup", function()
    print("=== Fennel Setup Status ===")
    print("fennel-ls executable: " .. (vim.fn.executable("fennel-ls") == 1 and "available" or "not found"))
    print("lua_ls available: " .. tostring(pcall(require, "lspconfig.lua_ls")))
    
    local globals = get_fennel_globals()
    print("Configured globals count: " .. #globals)
    print("First 10 globals: " .. table.concat(vim.list_slice(globals, 1, 10), ", "))
  end, { desc = "Show Fennel setup status" })
end

-- 主设置函数
M.setup = function()
  print("Setting up direct Fennel LSP configuration...")
  
  -- 1. 设置fennel-ls
  setup_fennel_ls()
  
  -- 2. 设置lua_ls为Fennel提供支持
  setup_lua_ls_for_fennel()
  
  -- 3. 创建测试命令
  create_test_commands()
  
  -- 4. 创建自动命令确保Fennel文件得到支持
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "fennel",
    callback = function(args)
      print("Fennel file detected, ensuring LSP support...")
      
      -- 延迟启动LSP以确保配置已加载
      vim.defer_fn(function()
        local clients = vim.lsp.get_active_clients({ bufnr = args.buf })
        local has_fennel_support = false
        
        for _, client in ipairs(clients) do
          if client.name == "fennel_ls" or client.name == "lua_ls" then
            has_fennel_support = true
            break
          end
        end
        
        if not has_fennel_support then
          print("No Fennel LSP support found, attempting manual start...")
          -- 尝试手动启动fennel-ls
          vim.cmd("LspStart fennel_ls")
        end
      end, 100)
    end,
    group = vim.api.nvim_create_augroup("FennelDirectSetup", { clear = true }),
    desc = "Ensure Fennel LSP support",
  })
  
  print("Direct Fennel LSP setup complete!")
  print("Use :FennelTestSymbols to test symbol access")
  print("Use :FennelShowSetup to show setup status")
end

return M