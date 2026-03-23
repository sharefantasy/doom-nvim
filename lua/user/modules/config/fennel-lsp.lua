-- Fennel LSP增强配置
-- 用于改善Fennel中Lua符号的可见性和补全

local M = {}

M.setup = function()
  -- 配置Fennel LSP以增强Lua符号支持
  if doom.langs.fennel and not doom.langs.fennel.settings.disable_lsp then
    -- 增强的Fennel LSP配置
    local enhanced_fennel_config = {
      settings = {
        fennel = {
          -- 工作空间配置
          workspace = {
            library = {
              -- Neovim运行时路径
              [vim.fn.expand("$VIMRUNTIME/lua")] = true,
              [vim.fn.expand("$VIMRUNTIME/lua/vim")] = true,
              [vim.fn.expand("$VIMRUNTIME/lua/vim/lsp")] = true,
              -- 项目路径
              [vim.fn.getcwd() .. "/lua"] = true,
              [vim.fn.getcwd() .. "/fnl"] = true,
              -- Doom Nvim路径
              [vim.fn.stdpath("config") .. "/lua"] = true,
              [vim.fn.stdpath("config") .. "/fnl"] = true,
            },
            -- 预加载设置
            maxPreload = 20000,
            preloadFileSize = 5000,
            -- 允许第三方库
            checkThirdParty = false,
          },
          -- 诊断配置
          diagnostics = {
            enable = true,
            -- 全局变量
            globals = {
              "vim", "doom", "_doom", "...",
              -- Fennel特殊变量
              "require", "module", "fn", "let", "when", "if", "each", "for",
              "while", "do", "collect", "icollect", "accumulate", "values",
              "comment", "hashfn", "lambda", "partial", "pick-args", "pick-values",
              "doto", "->", "->>", "-?>", "-?>>", "..", "length", "..",
            },
            -- 禁用的诊断
            disable = {
              "lowercase-global", "undefined-global", "unused-local", 
              "unused-var", "trailing-space"
            },
          },
          -- 补全配置
          completion = {
            enable = true,
            callSnippet = "Replace",
            showWord = "Disable",
            workspaceWord = true,
            keywordSnippet = "Replace",
          },
          -- 格式化配置
          format = {
            enable = true,
            defaultConfig = {
              indent_style = "space",
              indent_size = "2",
            },
          },
          -- 运行时配置
          runtime = {
            version = "LuaJIT",
            path = {
              "?.lua",
              "?/init.lua",
              "lua/?.lua",
              "lua/?/init.lua",
            },
            pathStrict = true,
            special = {
              vim = "vim",
              doom = "doom",
            },
          },
          -- 语义令牌配置
          semantic = {
            enable = true,
            annotation = true,
            variable = true,
            keyword = true,
          },
          -- 提示配置
          hint = {
            enable = true,
            arrayIndex = "Enable",
            await = true,
            paramName = "All",
            paramType = true,
            semicolon = "All",
            setType = true,
          },
        },
      },
    }
    
    -- 合并到Fennel配置中
    doom.langs.fennel.settings.lsp_config = enhanced_fennel_config
  end

  -- 配置neodev以增强Fennel中的Lua符号访问
  local neodev_config = {
    library = {
      enabled = true,
      runtime = true,      -- 运行时路径
      types = true,        -- 完整的类型签名和文档
      plugins = true,      -- 已安装的插件
      vim_reg = true,      -- vim正则表达式支持
    },
    setup_jsonls = true,
    lspconfig = false,
    pathStrict = true,
    -- 支持Fennel文件类型
    filetypes = {"lua", "fennel"},
    -- 增强的override函数
    override = function(root_dir, options)
      -- 为Fennel项目启用增强的库支持
      if string.find(root_dir, "fnl") or string.find(root_dir, "fennel") then
        options.library.enabled = true
        options.library.plugins = true
        options.library.types = true
        options.library.runtime = true
        options.library.vim_reg = true
      end
      
      -- 为Doom Nvim配置启用完整支持
      if string.find(root_dir, "doom%-nvim") or string.find(root_dir, "doom") then
        options.library.enabled = true
        options.library.plugins = true
        options.library.types = true
        options.library.runtime = true
      end
    end,
  }
  
  -- 如果neodev可用，应用配置
  local neodev_ok, neodev = pcall(require, "neodev")
  if neodev_ok then
    neodev.setup(neodev_config)
  end

  -- 配置treesitter以增强语法高亮和符号识别
  local ts_config = {
    ensure_installed = {"fennel", "lua"},
    highlight = {
      enable = true,
      additional_vim_regex_highlighting = false,
    },
    indent = {
      enable = true,
    },
    incremental_selection = {
      enable = true,
      keymaps = {
        init_selection = "gnn",
        node_incremental = "grn",
        scope_incremental = "grc",
        node_decremental = "grm",
      },
    },
  }
  
  local ts_ok, ts = pcall(require, "nvim-treesitter.configs")
  if ts_ok then
    ts.setup(ts_config)
  end

  -- 设置Fennel特定的键映射
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "fennel",
    callback = function()
      -- 设置localleader
      vim.b.localleader = ","
      
      -- 评估当前表单
      vim.keymap.set("n", "<localleader>ef", function()
        require("conjure.eval").eval_current_form()
      end, { buffer = true, desc = "Evaluate current form" })
      
      -- 评估当前缓冲区
      vim.keymap.set("n", "<localleader>eb", function()
        require("conjure.eval").eval_buffer()
      end, { buffer = true, desc = "Evaluate buffer" })
      
      -- 文档查找
      vim.keymap.set("n", "K", function()
        local word = vim.fn.expand("<cword>")
        if word then
          vim.lsp.buf.hover()
        end
      end, { buffer = true, desc = "Show documentation" })
    end,
  })

end

return M
