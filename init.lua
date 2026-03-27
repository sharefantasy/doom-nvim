-- Check if user is running Doom in a supported Neovim version before trying to load anything
pcall(function()
  if vim.loader and vim.fn.has("nvim-0.9") == 1 then
    vim.loader.enable()
  end
end)

-- Sanitize group names (augroup / highlight) to avoid E5248 on invalid characters
do
  local orig_create_augroup = vim.api.nvim_create_augroup
  local orig_create_autocmd = vim.api.nvim_create_autocmd
  local orig_clear_autocmds = vim.api.nvim_clear_autocmds
  local orig_set_hl = vim.api.nvim_set_hl
  local orig_nvim_command = vim.api.nvim_command
  local orig_cmd = vim.cmd
  local orig_exec2 = vim.api.nvim_exec2
  local orig_exec = vim.api.nvim_exec

  local function sanitize_group_name(name)
    if type(name) ~= "string" then
      name = tostring(name)
    end
    -- 仅允许字母/数字/下划线，兼容 Neovim 0.11 对 augroup 的限制
    local sanitized = name:gsub("[^%w_]", "_")
    return sanitized
  end

  vim.api.nvim_create_augroup = function(name, opts)
    return orig_create_augroup(sanitize_group_name(name), opts)
  end

  vim.api.nvim_create_autocmd = function(event, opts)
    if opts and type(opts.group) == "string" then
      local group_name = sanitize_group_name(opts.group)
      opts.group = orig_create_augroup(group_name, { clear = false })
    end
    return orig_create_autocmd(event, opts)
  end

  vim.api.nvim_clear_autocmds = function(opts)
    if opts and type(opts.group) == "string" then
      opts.group = sanitize_group_name(opts.group)
    end
    return orig_clear_autocmds(opts)
  end

  vim.api.nvim_set_hl = orig_set_hl

  local function sanitize_cmd_line(cmd)
    if type(cmd) ~= "string" then
      return cmd
    end
    local trimmed = cmd:gsub("^%s+", ""):gsub("%s+$", "")
    local lower = trimmed:lower()
    if lower:match("^augroup") then
      local tokens = {}
      for t in trimmed:gmatch("%S+") do
        table.insert(tokens, t)
      end
      if tokens[2] then
        tokens[2] = sanitize_group_name(tokens[2])
      end
      return table.concat(tokens, " ")
    end
    return cmd
  end

  local function sanitize_cmd(cmd)
    if type(cmd) ~= "string" then
      return cmd
    end
    if not cmd:find("\n") then
      return sanitize_cmd_line(cmd)
    end
    local lines = {}
    for line in cmd:gmatch("([^\n]*)\n?") do
      if line ~= "" then
        table.insert(lines, sanitize_cmd_line(line))
      else
        table.insert(lines, line)
      end
    end
    return table.concat(lines, "\n")
  end

  if orig_exec2 then
    vim.api.nvim_exec2 = function(cmd, opts)
      return orig_exec2(sanitize_cmd(cmd), opts)
    end
  end

  if orig_exec then
    vim.api.nvim_exec = function(cmd, output)
      return orig_exec(sanitize_cmd(cmd), output)
    end
  end

  vim.api.nvim_command = function(cmd)
    return orig_nvim_command(sanitize_cmd(cmd))
  end

  vim.cmd = setmetatable({}, {
    __call = function(_, cmd)
      if type(cmd) == "string" then
        return orig_nvim_command(sanitize_cmd(cmd))
      end
      return orig_cmd(cmd)
    end,
    __index = orig_cmd,
  })
end

-- Fastboot: 首屏只保证快捷键/基础交互，其余在事件循环开始后再加载
-- 通过 `DOOM_FASTBOOT=0` 可关闭
-- 为避免“先显示默认 UI → 再应用配置导致跳变”，当命令行带文件参数时默认自动关闭 fastboot
-- 如需强制开启（即使打开文件也延迟加载），设置 `DOOM_FASTBOOT_FORCE=1`
local fastboot = vim.env.DOOM_FASTBOOT
if fastboot == nil then
  fastboot = "1"
end
fastboot = fastboot ~= "0"

if fastboot and vim.env.DOOM_FASTBOOT_FORCE ~= "1" then
  local has_ui = #vim.api.nvim_list_uis() > 0
  local has_file_args = vim.fn.argc(-1) > 0
  if has_ui and has_file_args then
    fastboot = false
  end
end
vim.g.doom_fastboot = fastboot

-- Fastboot 模式下，禁用旧 packer 的 start 包自动加载（否则会在首屏阶段把一堆插件拉起来）
local data_site = vim.fn.stdpath("data") .. "/site"
local function strip_packpath_site()
  local parts = vim.split(vim.o.packpath, ",", { plain = true, trimempty = true })
  local out = {}
  for _, p in ipairs(parts) do
    if p ~= data_site then
      table.insert(out, p)
    end
  end
  vim.o.packpath = table.concat(out, ",")
end

-- 如果检测到遗留 packer 插件目录，移除 data_site 以避免旧插件干扰（如 gruvbox 版本冲突）
if vim.loop.fs_stat(data_site .. "/pack/packer/start") then
  strip_packpath_site()
end

if fastboot then
  -- 禁止启动期加载任何 runtimepath/plugin 脚本（加速首屏）
  vim.g._doom_saved_loadplugins = vim.o.loadplugins
  vim.o.loadplugins = false
  -- 不读写 shada（减少启动 I/O）；需要时让完整加载路径接管
  vim.g._doom_saved_shadafile = vim.o.shadafile
  vim.o.shadafile = "NONE"

  vim.g._doom_saved_shada = vim.o.shada
  vim.o.shada = ""

  strip_packpath_site()
end

if vim.fn.has "nvim-0.7.0" ~= 1 then
  local message = table.concat({
    "You are using an unsupported version of Neovim.",
    "",
    "Doom nvim and many of its plugins require at least version 0.7.0 to work as expected.",
    "Consider updating if you run into issues.",
    "https://github.com/doom-neovim/doom-nvim/blob/main/docs/updating-neovim.md",
  }, "\n")
  vim.notify(message, vim.log.levels.ERROR)
end

-- Preload lazy nvim
local lazypath = vim.fn.stdpath "data" .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system {
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  }
end
vim.opt.rtp:prepend(lazypath)

-- Makes sure ~/.local/share/nvim exists, to prevent problems with logging
vim.fn.mkdir(vim.fn.stdpath "data", "p")

-- NOTE: fastboot 相关设置已在文件顶部处理

local function load_doom()
  if vim.g._doom_framework_loaded then
    return
  end
  vim.g._doom_framework_loaded = true

  -- 恢复 fastboot 阶段关闭的选项，保证后续插件/状态正常
  if vim.g._doom_saved_loadplugins ~= nil then
    vim.o.loadplugins = vim.g._doom_saved_loadplugins
    vim.g._doom_saved_loadplugins = nil
  end
  if vim.g._doom_saved_shadafile ~= nil then
    vim.o.shadafile = vim.g._doom_saved_shadafile
    vim.g._doom_saved_shadafile = nil
  end
  if vim.g._doom_saved_shada ~= nil then
    vim.o.shada = vim.g._doom_saved_shada
    vim.g._doom_saved_shada = nil
  end

  require "doom.core"

  vim.defer_fn(function()
    -- Check for updates
    if doom.check_updates and doom.core.updater then
      doom.core.updater.check_updates(true)
    end
  end, 1)
end

if fastboot then
  vim.api.nvim_create_autocmd("VimEnter", {
    once = true,
    callback = function()
      -- 首屏只加载快捷键层：立即加载 doom.core（插件与 UI 会在内部延迟初始化）
      vim.defer_fn(load_doom, 0)
    end,
  })
else
  load_doom()
end

-- headless 模式没有 VimEnter/UI：保证脚本场景仍然加载完整配置
if fastboot and #vim.api.nvim_list_uis() == 0 then
  load_doom()
end
