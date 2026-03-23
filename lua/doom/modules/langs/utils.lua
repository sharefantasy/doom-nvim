local log = require "doom.utils.logging"
local profiler = require "doom.services.profiler"

local module = {}

--- Stores the unique null_ls sources
local registered_sources = {}

--- Registers a null_ls source only if it's unique
-- @tparam  source
module.use_null_ls_source = function(sources)
  local null_ls = require "null-ls"
  for _, source in ipairs(sources) do
    -- Generate a unique key from the name/methods
    local methods = type(source.method) == "string" and source.method or table.concat(source.method, " ")
    local key = source.name .. methods
    -- If it's unique, register it
    if not registered_sources[key] then
      registered_sources[key] = source
      null_ls.register(source)
    else
      log.warn(
        string.format("Attempted to register a duplicate null_ls source. ( %s with methods %s).", source.name, methods)
      )
    end
  end
end

---
---@param package_name string|nil Name of Mason.nvim package to install
---@param null_ls_path string Path of null-ls source i.e. `builtins.formatting.shfmt`
---@param configure_function function|nil optional configure function
---@language lua
--- ```lua
--- -- No mason.nvim package
--- langs_utils.use_null_ls(nil, "builtins.formatting.terrafmt")
--- -- Minimal
--- langs_utils.use_null_ls("stylua", "builtins.formatting.stylua")
--- -- Configure null_ls source
--- langs_utils.use_null_ls("shfmt", "builtins.formatting.shfmt", function(shfmt)
---   return shfmt.with({
---     extra_args = { "-i", "2", "-ci" },
---   })
--- end)
--- ```
module.use_null_ls = function(package_name, null_ls_path, configure_function)
  local profiler_msg = ("null_ls|setup `%s`"):format(null_ls_path)

  profiler.start(profiler_msg)
  if doom.features.linter then
    -- Check if null-ls is loaded and load it if not.
    local ok = pcall(require, "null-ls")
    if not ok then
      require("lazy").load { plugins = { "null-ls.nvim" } }
    end

    local start_null_ls = function()
      local null_ls = require "null-ls"
      local path = vim.split(null_ls_path, "%.", nil)
      if #path ~= 3 then
        log.error(
          ("Error setting up null-ls provider `%s`.\n\n  null_ls_path should have 3 segments i.e. `builtins.formatting.stylua"):format(
            null_ls_path
          )
        )
        return
      end
      local provider = null_ls[path[1]][path[2]][path[3]]

      if configure_function then
        provider = configure_function(provider)
      end

      module.use_null_ls_source { provider }
    end

    local on_error = function(_, message)
      log.error(("There was an error setting up null_ls provider `%s`. Reason: \n%s"):format(null_ls_path, message))
    end

    -- If auto_install module is enabled, try to install package before starting
    if doom.features.auto_install and package_name ~= nil then
      module.use_mason_package(package_name, start_null_ls, on_error)
    else
      vim.defer_fn(function()
        start_null_ls()
      end, 1)
    end
  end

  profiler.stop(profiler_msg)
end

--- Default error handler for use_mason_package utility function
---@param package_name string Name of the package that's being installed
---@param err_message string Reason for erroring out of installing mason package
local default_error_handler = function(package_name, err_message)
  error(("Error installing mason package `%s`.  Reason: \n%s "):format(package_name, err_message))
end

--- Installs a mason package and provides an on-ready handler
---@param package_name string|nil Name of mason.nvim package to install
---@param success_handler function
---@param error_handler function|nil
module.use_mason_package = function(package_name, success_handler, error_handler)
  local ok, mason = pcall(require, "mason-registry")
  if not ok then
    log.warn("mason-registry not available, skipping package installation for: " .. (package_name or "unknown"))
    -- 直接调用成功处理器，跳过mason安装
    vim.schedule(function()
      success_handler(nil)
    end)
    return
  end
  local on_err = error_handler or default_error_handler
  -- print("package_name", package_name)  -- 注释掉以避免E5248错误
  if package_name == nil then
    on_err("nil", "No package_name provided.")
    return
  end
  profiler.start("mason|using package " .. package_name)
  local ok, err = xpcall(function()
    local package = mason.get_package(package_name)
    if not package:is_installed() then
      -- If statusline enabled, push the package to the statusline state
      -- So we can provide feedback to user
      local statusline = doom.features.statusline
      if statusline then
        statusline.state.start_mason_package(package_name)
      end

      package:install()
      package:on("install:success", function(handle)
        -- Remove package from statusline state to hide it
        if statusline then
          statusline.state.finish_mason_package(package_name)
        end
        vim.schedule(function()
          success_handler(handle)
        end)
        profiler.stop("mason|using package " .. package_name)
      end)
      package:on("install:failed", function(pkg)
        -- Remove package from statusline state to hide it
        if statusline then
          statusline.state.finish_mason_package(package_name)
        end
        local err = "Mason.nvim install failed.  Reason:\n"
        if pkg and pkg.stdio and pkg.stdio.buffers and pkg.stdio.buffers.stderr then
          for _, line in ipairs(pkg.stdio.buffers.stderr) do
            err = err .. line
          end
        end

        vim.schedule(function()
          on_err(package_name, err)
        end)
        profiler.stop("mason|using package " .. package_name)
      end)
    else
      profiler.stop("mason|using package " .. package_name)
      -- Mason API 变更，get_handle 方法不存在，直接使用 package
      success_handler(package, package)
    end
  end, debug.traceback)
  if not ok then
    profiler.stop("mason|using package " .. package_name)
    on_err(package_name, "There was an unknown error when installing.  Reason: \n" .. err)
  end
end

--- Installs treesitter grammars
---@param grammars string|string[]
---
---@example
--- ```lua
--- langs_utils.use_tree_sitter("javascript")
--- langs_utils.use_tree_sitter({"c", "cpp"})
--- ````
module.use_tree_sitter = function(grammars)
  local install = require("nvim-treesitter.install")
  local parsers = require("nvim-treesitter.parsers")
  
  -- 标准化输入为table
  local grammar_list = type(grammars) == "table" and grammars or {grammars}
  
  -- 检查哪些语法需要安装
  local to_install = {}
  for _, lang in ipairs(grammar_list) do
    if not parsers.has_parser(lang) then
      table.insert(to_install, lang)
    end
  end
  
  -- 只安装未安装的语法
  if #to_install > 0 then
    install.ensure_installed(to_install)
  end
end

module.use_lsp_mason = function(lsp_name, options)
  local profiler_msg = ("lsp|setup `%s`"):format(lsp_name)
  profiler.start(profiler_msg)

  local utils = require "doom.utils"
  if not utils.is_module_enabled("features", "lsp") then
    return
  end

  -- 如果 nvim-lspconfig 被 lazy 加载，先确保它已进入 runtimepath
  pcall(function()
    local ok_lazy, lazy = pcall(require, "lazy")
    if ok_lazy then
      lazy.load { plugins = { "nvim-lspconfig" } }
    end
  end)

  local opts = options or {}
  local config_name = opts.name and opts.name or lsp_name
  
  -- 检查是否存在对应的LSP配置
  local lspconfig_ok, lspconfig = pcall(require, "lspconfig")
  if not lspconfig_ok then
    log.warn("lspconfig not available, skipping LSP setup for: " .. lsp_name)
    profiler.stop(profiler_msg)
    return
  end
  
  -- 检查是否存在对应的LSP配置
  local has_config = false

  -- 0) Neovim 0.11+ 新 API：如果用户通过 vim.lsp.config 自定义过，也认为存在
  if vim.lsp and vim.lsp.config and vim.lsp.config[config_name] then
    has_config = true
  end

  -- 1) 优先检查 lspconfig.configs（不会触发元方法，且是官方存储位置）
  if not has_config then
    local ok_configs, configs = pcall(require, "lspconfig.configs")
    if ok_configs and configs and configs[config_name] then
      has_config = true
    end
  end

  -- 2) 回退检查 lspconfig[server]（可能触发元方法加载 server 配置，避免 rawget 误判）
  if not has_config then
    local ok_server, server = pcall(function()
      return lspconfig[config_name]
    end)
    if ok_server and type(server) == "table" and (type(server.setup) == "function" or server.manager ~= nil) then
      has_config = true
    end
  end

  -- 3) 最后检查 mason-lspconfig 映射
  if not has_config then
    local mason_mappings_ok, mason_mappings = pcall(require, "mason-lspconfig.mappings.server")
    if mason_mappings_ok and mason_mappings.lspconfig_to_package and mason_mappings.lspconfig_to_package[config_name] then
      has_config = true
    end
  end
  
  if not has_config then
    log.warn("No LSP configuration found for: " .. (config_name or "unknown") .. ", skipping setup")
    profiler.stop(profiler_msg)
    -- 不要直接 return：在 nvim-lspconfig 的 0.11 兼容层下，这个检测可能出现假阴性。
  end

  -- Resolve the user config from `opts.config` if it's a function
  local user_config = nil
  if opts.config then
    user_config = type(opts.config) == "function" and opts.config() or opts.config
  end

  -- 如果系统 PATH 中没有该 LSP 二进制，但 mason 已安装，则自动使用 mason/bin 下的可执行文件
  -- 这样可以在不提前加载 mason-lspconfig 的情况下保持 LSP 可用。
  if (not user_config or user_config.cmd == nil) and vim.fn.executable(lsp_name) == 0 then
    local mason_cmd = vim.fn.stdpath("data") .. "/mason/bin/" .. lsp_name
    if vim.fn.executable(mason_cmd) == 1 then
      user_config = user_config or {}
      user_config.cmd = { mason_cmd }
    end
  end

  -- Combine default on_attach with provided on_attach
  local on_attach_functions = {}
  if user_config and user_config.on_attach then
    table.insert(on_attach_functions, user_config.on_attach)
  end

  local capabilities_config = {
    capabilities = module.get_capabilities(),
    on_attach = function(client)
      for _, handler in ipairs(on_attach_functions) do
        handler(client)
      end
    end,
  }

  -- Start server and bind to buffers
  local start_lsp = function()
    local final_config = vim.tbl_deep_extend("keep", user_config or {}, capabilities_config)
    
    -- 临时抑制弃用警告
    local original_deprecate = vim.deprecate
    vim.deprecate = function() end
    
    local success = false
    local error_msg = nil
    
    -- Neovim 0.11+：优先使用 vim.lsp.config/vim.lsp.enable，避免 nvim-lspconfig 的 framework 兼容层问题
    if vim.fn.has("nvim-0.11") == 1 and vim.lsp and vim.lsp.config and vim.lsp.enable and vim.lsp.start then
      local ok, _ = pcall(function()
        local base = {}
        local ok_cfg, cfg_mod = pcall(require, "lspconfig.configs." .. config_name)
        if ok_cfg and cfg_mod and type(cfg_mod.default_config) == "table" then
          base = cfg_mod.default_config
        end

        local merged = vim.tbl_deep_extend("force", vim.deepcopy(base), final_config)
        merged.name = config_name

        vim.lsp.config[config_name] = merged
        vim.lsp.enable(config_name)

        -- 立即绑定当前已打开的 buffers
        local fts = {}
        for _, ft in ipairs(merged.filetypes or {}) do
          fts[ft] = true
        end
        for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
          if vim.api.nvim_buf_is_loaded(bufnr) and fts[vim.bo[bufnr].filetype] then
            pcall(vim.lsp.start, merged, { bufnr = bufnr })
          end
        end
        success = true
      end)
      if ok and success then
        vim.deprecate = original_deprecate
        return
      end
    end
    
    -- 回退到 lspconfig API
    local lsp = require "lspconfig"
    local ok, err = pcall(function()
      local server = lsp[config_name]
      if server and server.setup then
        server.setup(final_config)
        success = true
      end
    end)
    if not ok then
      error_msg = err
    end
    
    -- 恢复原始的弃用函数
    vim.deprecate = original_deprecate
    
    if not success then
      log.warn(
        ("Cannot start LSP %s with config name %s. Reason: The LSP config does not exist, please create an issue so this can be resolved."):format(
          lsp_name,
          config_name
        )
      )
      if error_msg then
        log.warn(("LSP %s setup error: %s"):format(lsp_name, tostring(error_msg)))
      end
      return
    end
    
    -- 处理 buffer 绑定
    pcall(function()
      local lsp = require "lspconfig"
      local lsp_config_server = lsp[config_name]
      if lsp_config_server and lsp_config_server.manager then
        local buffer_handler = lsp_config_server.filetypes and lsp_config_server.manager.try_add_wrapper
          or lsp_config_server.manager.try_add
        for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
          buffer_handler(lsp_config_server.manager, bufnr)
        end
      end
    end)
  end

  -- Auto install if possible
  if utils.is_module_enabled("features", "auto_install") and not opts.no_installer then
    local ok = pcall(function()
      local lspconfig_to_package = require("mason-lspconfig").get_mappings().lspconfig_to_package
      if lspconfig_to_package and lspconfig_to_package[lsp_name] then
        module.use_mason_package(lspconfig_to_package[lsp_name], start_lsp)
      else
        start_lsp()
      end
    end)
    if not ok then
      -- mason-lspconfig 未加载/不可用时，不应阻塞 LSP 启动
      start_lsp()
    end
  else
    start_lsp()
  end

  profiler.stop(profiler_msg)
end

-- module.use_dap = function(config_name, settings)
--   local utils = require("doom.utils")
--   if utils.is_module_enabled("features", "dap") then
--     vim.defer_fn(function()
--       local dap = require("dap")
--       dap.configurations.python = {
--         {
--           type = "python",
--           request = "launch",
--           name = "Launch file",
--           program = "${file}",
--           pythonPath = function()
--             return "/usr/bin/python"
--           end,
--         },
--       }
--     end)
--   end
-- end

--- Get LSP capabilities for DOOM
module.get_capabilities = function()
  local capabilities = vim.lsp.protocol.make_client_capabilities()
  capabilities.textDocument.completion.completionItem.preselectSupport = true
  capabilities.textDocument.completion.completionItem.insertReplaceSupport = true
  capabilities.textDocument.completion.completionItem.labelDetailsSupport = true
  capabilities.textDocument.completion.completionItem.deprecatedSupport = true
  capabilities.textDocument.completion.completionItem.commitCharactersSupport = true
  capabilities.textDocument.completion.completionItem.tagSupport = {
    valueSet = { 1 },
  }
  capabilities.textDocument.completion.completionItem.snippetSupport = true
  capabilities.textDocument.completion.completionItem.resolveSupport = {
    properties = { "documentation", "detail", "additionalTextEdits" },
  }
  capabilities.textDocument.codeAction = {
    dynamicRegistration = false,
    codeActionLiteralSupport = {
      codeActionKind = {
        valueSet = {
          "",
          "quickfix",
          "refactor",
          "refactor.extract",
          "refactor.inline",
          "refactor.rewrite",
          "source",
          "source.organizeImports",
        },
      },
    },
  }

  return capabilities
end

--- Helper to wrap language setup functions with error handling + avoid raceconditions
---@param module_name string Name of module for error logging
---@param setup_fn function Function that sets up this language
---@return function Wrapped setup function
module.wrap_language_setup = function(module_name, setup_fn)
  local setup_language = function()
    vim.defer_fn(function()
      local ok, error = xpcall(setup_fn, debug.traceback)
      if not ok then
        log.error(("Error setting up language `%s`. \n%s"):format(module_name, error))
      end
    end, 1)
  end
  return setup_language
end

return module
