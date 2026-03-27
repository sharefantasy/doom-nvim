--[[
--  gentlewind.core
--
--  Entrypoint for the gentlewind-nvim framework.
--
--]] -- Disable vim builtins for faster startup time
local g = vim.g

g.loaded_gzip = 1
g.loaded_zip = 1
g.loaded_zipPlugin = 1
g.loaded_tar = 1
g.loaded_tarPlugin = 1

g.loaded_getscript = 1
g.loaded_getscriptPlugin = 1
g.loaded_vimball = 1
g.loaded_vimballPlugin = 1
g.loaded_2html_plugin = 1

g.loaded_matchit = 1
g.loaded_matchparen = 1
g.loaded_logiPat = 1
g.loaded_rrhelper = 1

local profiler = require("gentlewind.services.profiler")

-- Sets the `gentlewind` global object
profiler.start("framework|gentlewind.core.gentlewind_global")
require("gentlewind.core.gentlewind_global")
profiler.stop("framework|gentlewind.core.gentlewind_global")

profiler.start("framework|gentlewind.utils")
local utils = require("gentlewind.utils")
profiler.stop("framework|gentlewind.utils")

-- Boostraps the gentlewind-nvim framework, runs the user's `config.lua` file.
profiler.start("framework|gentlewind.core.config (setup + user)")
local config = utils.safe_require("gentlewind.core.config")
config.load()
profiler.stop("framework|gentlewind.core.config (setup + user)")
if not utils.is_module_enabled("features", "netrw") then
    g.loaded_netrw = 1
    g.loaded_netrwPlugin = 1
    g.loaded_netrwSettings = 1
    g.loaded_netrwFileHandlers = 1
end

-- Set some extra commands
utils.safe_require("gentlewind.core.commands")

profiler.start("framework|gentlewind.core.modules")
-- Load Gentlewind modules.
local modules = utils.safe_require("gentlewind.core.modules")
profiler.start("framework|init enabled modules")
modules.load_modules()
profiler.stop("framework|init enabled modules")
profiler.start("framework|user settings")
modules.handle_user_config()
profiler.stop("framework|user settings")
modules.try_sync()
profiler.stop("framework|gentlewind.core.modules")

local function load_plugins_and_ui()
  modules.handle_lazynvim()

  -- Load the colourscheme
  profiler.start("framework|gentlewind.core.ui")
  utils.safe_require("gentlewind.core.ui")
  profiler.stop("framework|gentlewind.core.ui")

  -- Execute autocommand for user to hook custom config into
  vim.api.nvim_exec_autocmds("User", { pattern = "GentlewindStarted" })
end

-- UI 也需要在首屏就绪：不再延迟插件与 UI 初始化
load_plugins_and_ui()

-- vim: fdm=marker
