-- Check if user is running Doom in a supported Neovim version before trying to load anything
pcall(function()
  if vim.loader and vim.fn.has("nvim-0.9") == 1 then
    vim.loader.enable()
  end
end)

-- Fastboot: 首屏只保证快捷键/基础交互，其余在事件循环开始后再加载
-- 通过 `DOOM_FASTBOOT=0` 可关闭
local fastboot = vim.env.DOOM_FASTBOOT
if fastboot == nil then
  fastboot = "1"
end
fastboot = fastboot ~= "0"
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
