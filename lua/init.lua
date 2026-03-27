local _2afile_2a = "/Users/fankainang/sources/gentlewind-nvim/fnl/init.fnl"
if (vim.fn.has("nvim-0.7.0") ~= 1) then
  local message = table.concat({"You are using an unsupported version of Neovim.", "", "Gentlewind nvim and many of its plugins require at least version 0.7.0 to work as expected.", "Consider updating if you run into issues.", "https://github.com/gentlewind-neovim/gentlewind-nvim/blob/main/docs/updating-neovim.md"}, "\n")
  vim.notify(message, vim.log.levels.ERROR)
else
end
local _2amodule_name_2a = "table: 0x0107e8c110"
local _2amodule_2a
do
  package.loaded[_2amodule_name_2a] = {}
  _2amodule_2a = package.loaded[_2amodule_name_2a]
end
local _2amodule_locals_2a
do
  _2amodule_2a["aniseed/locals"] = {}
  _2amodule_locals_2a = (_2amodule_2a)["aniseed/locals"]
end
local profiler = require("gentlewind.services.profiler")
profiler.start("framework|init.fnl")
local lazypath = (vim.fn.stdpath("data") .. "/lazy/lazy.nvim")
if not vim.loop.fs_stat(lazypath) then
  print("Bootstrapping lazy.nvim, please wait...")
  vim.fn.system({"git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath})
else
end
do end (vim.opt.rtp):prepend(lazypath)
vim.fn.mkdir(vim.fn.stdpath("data"), "p")
do end (vim.opt.runtimepath):append(vim.fn.stdpath("data"))
do
  local orig_create_augroup = vim.api.nvim_create_augroup
  local orig_set_hl = vim.api.nvim_set_hl
  local function sanitize_group_name(name)
    local name0
    if (type(name) == "string") then
      name0 = name
    else
      name0 = tostring(name)
    end
    local sanitized = string.gsub(name0, "[^%w_]", "_")
    return sanitized
  end
  local function _4_(name, opts)
    return orig_create_augroup(sanitize_group_name(name), opts)
  end
  vim.api.nvim_create_augroup = _4_
  vim.api.nvim_set_hl = orig_set_hl
end
require("gentlewind.core")
local function _5_()
  if (gentlewind.check_updates and gentlewind.core.updater) then
    return gentlewind.core.updater.check_updates(true)
  else
    return nil
  end
end
vim.defer_fn(_5_, 1)
profiler.stop("framework|init.fnl")
return _2amodule_2a