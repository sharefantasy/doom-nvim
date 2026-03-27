--  gentlewind.core.ui
--
--  Responsible for safely setting the colorscheme and falling back to `gentlewind-one`
--  if necessary.
local profiler = require("gentlewind.services.profiler")
local profile_message = ("framework|set colorscheme `%s`"):format(
                            gentlewind.colorscheme)

local utils = require("gentlewind.utils")
local log = require("gentlewind.utils.logging")

profiler.start(profile_message)

-- If the colorscheme was not found then fallback to defaults.
if not utils.is_empty(gentlewind.colorscheme) then
    local loaded_colorscheme = xpcall(function()
        vim.api.nvim_command("colorscheme " .. gentlewind.colorscheme)
    end, function(err)
        -- headless/fastboot 场景下 colorscheme 缺失很常见，不记录为 error 以免污染日志
        if #vim.api.nvim_list_uis() > 0 then
            log.error(debug.traceback(err))
        end
    end)

    if not loaded_colorscheme then
        if #vim.api.nvim_list_uis() > 0 then
            log.warn("Colorscheme '" .. gentlewind.colorscheme .. "' not found, falling back to gentlewind-one")
        end
        vim.api.nvim_command("colorscheme gentlewind-one")
    end
else
    log.warn("Forced default Gentlewind colorscheme")
    vim.api.nvim_command("colorscheme gentlewind-one")
end

-- Set gentlewind-one colorscheme settings
if gentlewind.colorscheme == "gentlewind-one" then
    require("colors.gentlewind-one").setup({
        cursor_coloring = gentlewind.gentlewind_one.cursor_coloring,
        terminal_colors = gentlewind.gentlewind_one.terminal_colors,
        italic_comments = gentlewind.gentlewind_one.italic_comments,
        enable_treesitter = gentlewind.gentlewind_one.enable_treesitter,
        transparent_background = gentlewind.gentlewind_one.transparent_background,
        pumblend = {
            enable = true,
            transparency_amount = gentlewind.complete_transparency
        },
        plugins_integrations = {
            neorg = true,
            barbar = false,
            bufferline = true,
            gitgutter = false,
            gitsigns = true,
            telescope = gentlewind.gentlewind_one.telescope_highlights,
            neogit = false,
            nvim_tree = true,
            dashboard = true,
            startify = false,
            whichkey = true,
            indent_blankline = true,
            vim_illuminate = true,
            lspsaga = false
        }
    })
end

profiler.stop(profile_message)
