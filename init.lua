-- Check if user is running Gentlewind in a supported Neovim version before trying to load anything
pcall(function()
  if vim.loader and vim.fn.has("nvim-0.9") == 1 then
    vim.loader.enable()
  end
end)

-- Add lua directory to package.path
local root_dir = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), " :p:h")
local lua_dir = root_dir .. "/lua"
if vim.fn.isdirectory(lua_dir) == 1 then
  package.path = package.path .. ";" .. lua_dir .. "/?.lua;" .. lua_dir .. "/?/init.lua"
  vim.opt.rtp:prepend(root_dir)
end

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

local function gentlewind_preflight()
  local function check(name)
    local ok, err = pcall(require, name)
    if not ok then
      vim.notify("[gentlewind preflight] failed: " .. name .. "\n" .. tostring(err), vim.log.levels.ERROR)
    end
    return ok
  end

  check("gentlewind.core.gentlewind_global")
  check("gentlewind.core.utils")
  check("gentlewind.utils")
  check("gentlewind.core.config")
  check("gentlewind.core.modules")
end

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

if vim.fn.has "nvim-0.7.0" ~= 1 then
  local message = table.concat({
    "You are using an unsupported version of Neovim.",
    "",
    "Gentlewind nvim and many of its plugins require at least version 0.7.0 to work as expected.",
    "Consider updating if you run into issues.",
    "https://github.com/gentlewind-neovim/gentlewind-nvim/blob/main/docs/updating-neovim.md",
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

local function load_gentlewind()
  if vim.g._gentlewind_framework_loaded then
    return
  end
  vim.g._gentlewind_framework_loaded = true

  gentlewind_preflight()

  require "gentlewind.core"

  vim.defer_fn(function()
    -- Check for updates
    local ok, updater = pcall(require, "gentlewind.modules.core.updater")
    if gentlewind and gentlewind.check_updates and ok and updater and updater.check_updates then
      updater.check_updates(true)
    end
  end, 1)
end

-- 直接加载完整配置（移除 fastboot 以避免 UI/插件延迟造成的跳变）
load_gentlewind()
