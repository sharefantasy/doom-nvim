--  gentlewind.core.system
--
--  Evaluates and stores some filepaths for re-use arround the application.
--  Due to lua's `require` caching results are cached.
local system = {}
local stdpath = vim.fn.stdpath
local config_dir = stdpath("config"):match(".*[/\\]"):sub(1, -2)

system.sep = package.config:sub(1, 1)

-- The nvim root directory, works as a fallback for looking Gentlewind Nvim configurations
-- in case that gentlewind_configs_root directory does not exist.
system.gentlewind_root = stdpath("config")

-- The gentlewind-nvim configurations root directory.
system.gentlewind_configs_root = table.concat({config_dir, "gentlewind-nvim"}, system.sep)

local testdir = vim.loop.fs_opendir(system.gentlewind_configs_root)
if testdir then
    vim.loop.fs_closedir(testdir)
else
    system.gentlewind_configs_root = stdpath("config")
end

system.gentlewind_compile_path = vim.fn.stdpath("data") ..
                               "/plugin/packer_compiled.lua"

-- The gentlewind-nvim logs file path
system.gentlewind_logs = table.concat({stdpath("data"), "gentlewind.log"}, system.sep)

-- The gentlewind-nvim bug report file path
system.gentlewind_report = table.concat({stdpath("data"), "gentlewind_report.md"},
                                  system.sep)

-- The git workspace for gentlewind-nvim, e.g. 'git -C /home/JohnDoe/.config/nvim'
system.git_workspace = string.format("git -C %s ", system.gentlewind_root)

return system
