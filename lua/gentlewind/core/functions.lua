-- NOTE: Can't require "gentlewind.utils.logging" in the top level, because `gentlewind`
-- may not exist here.
local utils = require("gentlewind.utils")
local fs = require("gentlewind.utils.fs")
local system = require("gentlewind.core.system")
local is_module_enabled = utils.is_module_enabled

local functions = {}

-- Quit Neovim and dump all messages to gentlewind.log file.
-- @tparam bool dont_write If gentlewind shouldn't save before exiting
-- @tparam bool force If gentlewind should force the exiting
functions.quit_gentlewind = function(dont_write, force)
    local quit_cmd = ""
    if not dont_write then quit_cmd = "wa | " end
    if force then
        vim.cmd(quit_cmd .. "qa!")
    else
        vim.cmd(quit_cmd .. "q!")
    end
end

-- Open Gentlewind Nvim user manual and set extra options to buffer
functions.open_docs = function()
    -- NOTE: we aren't using the default Neovim way with ':h gentlewind' because of some bugs
    -- with the tags and Neovim overriding the filetype, causing some highlighting issues

    -- Get the documentation path
    local docs_path
    if fs.file_exists(string.format("%s/doc/gentlewind_nvim.norg", system.gentlewind_root)) then
        docs_path = string.format("%s/doc/gentlewind_nvim.norg", system.gentlewind_root)
    else
        docs_path = string.format("%s/doc/gentlewind_nvim.norg",
                                  system.gentlewind_configs_root)
    end

    -- Open the documentation in a split window
    vim.cmd(string.format("split %s", docs_path))
    -- Move cursor to table of contents section
    vim.api.nvim_buf_call(vim.fn.bufnr("gentlewind_nvim.norg"),
                          function() vim.fn.cursor({12, 1}) end)
    -- Set local documentation options
    vim.opt_local.modified = false
    vim.opt_local.modifiable = false
    vim.opt_local.signcolumn = "no"
    vim.opt_local.foldcolumn = "0"
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    vim.opt_local.colorcolumn = "0"
    vim.opt_local.shiftwidth = 2
    vim.opt_local.tabstop = 2
    vim.opt_local.conceallevel = 2
    vim.opt_local.concealcursor = "n"
    vim.opt_local.textwidth = 100
    vim.opt_local.rightleft = false
end

-- create_report creates a markdown report. It's meant to be used when a bug
-- occurs, useful for debugging issues.
functions.create_report = function()
    local log = require("gentlewind.utils.logging")
    local date = os.date("%Y-%m-%d %H:%M:%S")
    local created_report, err = xpcall(function()
        -- Get and save only the warning and error logs from today
        local today_logs = {}
        local gentlewind_logs = vim.split(fs.read_file(system.gentlewind_logs), "\n")
        for _, gentlewind_log in ipairs(gentlewind_logs) do
            local preinfo = gentlewind_log:match("%[(.+)%]")
            if preinfo ~= nil then
                local is_current_day =
                    preinfo:find(os.date("%a %d %b")) ~= nil and
                        preinfo:find(os.date("%Y")) ~= nil
                local error_or_warn = preinfo:find("ERROR ") or
                                          preinfo:find("WARN ")
                if error_or_warn and is_current_day then
                    table.insert(today_logs, gentlewind_log)
                end
            end
        end

        -- Get the neovim version
        local nvim_version_info = vim.version()
        local nvim_version = string.format("%d.%d.%d", nvim_version_info.major,
                                           nvim_version_info.minor,
                                           nvim_version_info.patch)
        if nvim_version_info.api_prerelease then
            nvim_version = nvim_version .. " (dev)"
        end

        -- Get the current OS and if the user is running Linux then get also the
        -- distribution name, e.g. Manjaro
        local user_os = vim.loop.os_uname().sysname
        if user_os == "Linux" then
            user_os =
                vim.trim( -- PRETTY_NAME="Distribution (Additional info)", e.g.
                --   PRETTY_NAME="Fedora 34 (KDE Plasma)"

                    vim.fn
                        .system(
                        'cat /etc/os-release | grep "^PRETTY_NAME" | sed ' ..
                            "'s/^PRETTY_NAME=\"//' | sed " .. "'s/\"//'"))
        end

        local report = string.format([[# Gentlewind Nvim crash report

> Report date: %s

## System and Gentlewind Nvim information

- **OS**: %s
- **Neovim version**: %s
- **Gentlewind Nvim information**:
  - **version**: %s
  - **`gentlewind_root` variable**: `%s`
  - **`gentlewind_configs_root` variable**: `%s`

### Begin error log dump

```
%s
```

### End log dump]],
      date,
      user_os,
      nvim_version,
      utils.gentlewind_version,
      system.gentlewind_root,
      system.gentlewind_configs_root,
      table.concat(today_logs, "\n")
    )
    fs.write_file(system.gentlewind_report, report, "w+")
    log.info("Report created at " .. system.gentlewind_report)
  end, function(err) log.error(debug.traceback(err)) end)

    if not created_report then
        log.error("Error while writing report. Traceback:\n" .. err)
    end
end

-- Toggle background="dark"|"light"
functions.toggle_background = function()
    local background = vim.go.background
    if background == "light" then
        vim.go.background = "dark"
    else
        vim.go.background = "light"
    end
    -- XXX: Should we "just print"? Maybe and info log?
    print(string.format("background=%s", vim.go.background))
end

-- Only define if lsp enabled, it only makes sense there.
if is_module_enabled("features", "lsp") then
    -- Toggle completion (by running cmp setup again).
    functions.toggle_completion = function()
        _gentlewind.cmp_enable = not _gentlewind.cmp_enable
        print(string.format("completion=%s", utils.bool2str(_gentlewind.cmp_enable)))
    end
end

-- Toggle signcolumn="auto"|"no"
functions.toggle_signcolumn = function()
    local signcolumn = vim.o.signcolumn
    if signcolumn == "no" then
        vim.opt.signcolumn = "auto"
    else
        vim.opt.signcolumn = "no"
    end
    print(string.format("signcolumn=%s", vim.opt.signcolumn))
end

-- Set the indent and tab related numbers.
-- Negative numbers mean tabstop -- Really though? Tabs?
functions.set_indent = function()
    local indent = tonumber(vim.fn.input(
                                "Set indent (>0 uses spaces, <0 uses tabs, 0 uses vim defaults): "))
    if not indent then indent = -8 end
    vim.opt.expandtab = indent > 0
    indent = math.abs(indent)
    vim.opt.tabstop = indent
    vim.opt.softtabstop = indent
    vim.opt.shiftwidth = indent
    print(string.format("indent=%d %s", indent,
                        vim.opt.expandtab and "spaces" or "tabs"))
end

-- Change the number display modes.
functions.change_number = function()
    local number = vim.opt.number
    local relativenumber = vim.opt.relativenumber
    if (number == false) and (relativenumber == false) then
        vim.opt.number = true
        vim.opt.relativenumber = false
    elseif (number == true) and (relativenumber == false) then
        vim.opt.number = false
        vim.opt.relativenumber = true
    elseif (number == false) and (relativenumber == true) then
        vim.opt.number = true
        vim.opt.relativenumber = true
    else -- (number == true) and (relativenumber == true) then
        vim.opt.number = false
        vim.opt.relativenumber = false
    end
    print("number=%s, relativenumber=%s", utils.bool2str(vim.opt.number),
          utils.bool2str(vim.opt.relativenumber))
end

-- Toggle spell.
functions.toggle_spell = function()
    vim.opt.spell = not vim.opt.spell
    print(string.format("spell=%s", utils.bool2str(vim.opt.spell)))
end

-- Toggle syntax/treesitter
functions.change_syntax = function()
    local parsers = require("nvim-treesitter.parsers")
    if parsers.has_parser() then
        if vim.opt.syntax then
            vim.cmd("TSBufDisable highlight")
            vim.cmd("syntax off")
        else
            vim.cmd("TSBufEnable highlight")
            vim.cmd("syntax on")
        end
        local state = utils.bool2str(vim.opt.syntax)
        print(string.format("syntax=%s, treesitter=%s", state, state))
    else
        if vim.o.syntax then
            vim.cmd("syntax off")
        else
            vim.cmd("syntax on")
        end
        local state = utils.bool2str(vim.opt.syntax)
        print(string.format("syntax=%s", state))
    end
end

-- Better folding function.
functions.sugar_folds = function()
    local start_line = vim.fn.getline(vim.v.foldstart):gsub("\t", ("\t"):rep(
                                                                vim.opt.tabstop:get()))
    return string.format("%s ... (%d lines)", start_line,
                         vim.v.foldend - vim.v.foldstart + 1)
end

--- Nukes the gentlewind install config, causes a fresh install on next boot.
---@param target string Options of what to nuke
functions.nuke = function(target)
    if target == nil or #target == 0 then
        vim.notify(
            "Warning, this command deletes lazy caches and causes a re-install of gentlewind-nvim on next launch.\n\n :GentlewindNuke plugins|cache|mason|all. \n\t `cache` - Clear lazy.lua\n\t `plugins` - Clear all installed plugins\n\t `mason` - Clear all Mason.nvim packages\n\t `all` - Delete all of the above.")
        return
    end

    local log = require("gentlewind.utils.logging")
    -- Delete lazy compiled
    if target == "all" or target == "cache" then
        os.remove(system.gentlewind_compile_path)
        log.info("GentlewindNuke: Deleting lazy compiled.")
    end

    if target == "all" or target == "plugins" then
        -- Delete all plugins
        local plugin_dir = fs.join_paths(vim.fn.stdpath("data"), "lazy")
        fs.rm_dir(plugin_dir)
        log.info(
            "GentlewindNuke: Deleting lazy plugins.  Gentlewind-nvim will re-install on next launch.")
    end

    if target == "all" or target == "mason" then
        local mason_dir = fs.join_paths(vim.fn.stdpath("data"), "mason")
        fs.rm_dir(mason_dir)
        log.info("GentlewindNuke: Deleting mason packages")
    end
end

return functions
