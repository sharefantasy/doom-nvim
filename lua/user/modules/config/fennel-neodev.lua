-- Fennel neodev增强配置
-- 专门解决Fennel中Lua符号不可见的问题

local M = {}

M.setup = function()
  -- 为Fennel文件类型专门配置neodev
  local neodev_avail, neodev = pcall(require, "neodev")
  if not neodev_avail then
    return
  end

  -- 配置neodev以支持Fennel文件
  neodev.setup({
    library = {
      enabled = true,
      runtime = true,    -- 运行时路径
      types = true,      -- 完整的类型签名和文档  
      plugins = true,    -- 已安装的插件
    },
    setup_jsonls = true,
    lspconfig = false,
    pathStrict = true,
    -- 关键：明确支持Fennel文件类型
    filetypes = {"lua", "fennel"},
    -- 增强的override函数
    override = function(root_dir, options)
      -- 为所有Fennel相关目录启用完整库支持
      if string.find(root_dir, "fnl") or string.find(root_dir, "fennel") or 
         string.find(root_dir, "gentlewind") or string.find(root_dir, "nvim") then
        options.library.enabled = true
        options.library.plugins = true  
        options.library.types = true
        options.library.runtime = true
      end
    end,
  })

  -- 创建专门的Fennel文件类型自动命令
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "fennel",
    callback = function(args)
      -- 确保neodev附加到当前缓冲区
      local neodev_lsp_avail, neodev_lsp = pcall(require, "neodev.lsp")
      if neodev_lsp_avail then
        neodev_lsp.attach()
      end

      -- 手动设置一些全局变量声明
      local clients = vim.lsp.get_active_clients({ bufnr = args.buf })
      for _, client in ipairs(clients) do
        if client.name == "fennel_ls" or client.name == "lua_ls" then
          -- 为LSP客户端添加全局变量
          local settings = client.config.settings or {}
          settings.diagnostics = settings.diagnostics or {}
          settings.diagnostics.globals = {
            "vim", "gentlewind", "_gentlewind", "require", "module", "fn", "let",
            "when", "if", "each", "for", "while", "do", "collect",
            "icollect", "accumulate", "values", "comment", "hashfn",
            "lambda", "partial", "pick-args", "pick-values", "doto",
            "->", "->>", "-?>", "-?>>", "..", "length", "..."
          }
          
          -- 工作区库路径
          settings.workspace = settings.workspace or {}
          settings.workspace.library = {
            [vim.fn.expand("$VIMRUNTIME/lua")] = true,
            [vim.fn.expand("$VIMRUNTIME/lua/vim")] = true,
            [vim.fn.getcwd() .. "/lua"] = true,
            [vim.fn.getcwd() .. "/fnl"] = true,
            [vim.fn.stdpath("config") .. "/lua"] = true,
            [vim.fn.stdpath("config") .. "/fnl"] = true,
          }
          
          print("Updated LSP settings for client: " .. client.name)
        end
      end
    end,
    group = vim.api.nvim_create_augroup("FennelNeodevSetup", { clear = true }),
    desc = "Setup neodev for Fennel files",
  })

  -- 创建测试命令
  vim.api.nvim_create_user_command("FennelTestSymbols", function()
    local bufnr = vim.api.nvim_get_current_buf()
    local clients = vim.lsp.get_active_clients({ bufnr = bufnr })
    
    print("Active LSP clients for current buffer:")
    for _, client in ipairs(clients) do
      print("  - " .. client.name .. " (attached: " .. tostring(client.attached_buffers[bufnr] ~= nil) .. ")")
      if client.config and client.config.settings then
        local globals = client.config.settings.diagnostics and client.config.settings.diagnostics.globals
        if globals then
          print("    Globals: " .. table.concat(globals, ", "))
        end
      end
    end
    
    -- 测试基本的vim访问
    local test_code = [[
;; 测试符号访问
(local message (.. "Hello from " vim.fn.expand "%"))
(when gentlewind.features.lsp
  (print "LSP is enabled"))
]]
    print("Test code for symbol validation:")
    print(test_code)
  end, { desc = "Test Fennel symbol access" })

  print("Fennel neodev enhancement loaded")
end

return M
