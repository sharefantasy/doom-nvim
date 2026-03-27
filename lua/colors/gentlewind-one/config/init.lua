--- @class config
local config = {}

local configuration = {
    cursor_coloring = false,
    terminal_colors = false,
    italic_comments = false,
    enable_treesitter = false,
    transparent_background = false,
    pumblend = {enable = true, transparency_amount = 20},
    plugins_integrations = {
        neorg = false,
        barbar = false,
        bufferline = false,
        gitgutter = false,
        gitsigns = false,
        telescope = false,
        neogit = false,
        nvim_tree = false,
        dashboard = false,
        startify = false,
        whichkey = false,
        indent_blankline = false,
        lspsaga = false
    }
}

--- Get a configuration value
--- @param opt string
--- @return any
config.get = function(opt)
    if opt then return configuration[opt] end
    return configuration
end

--- Set user-defined configurations
--- @param user_configs table
--- @return table
config.set = function(user_configs)
    vim.validate({user_configs = {user_configs, "table"}})

    configuration = vim.tbl_deep_extend("force", configuration, user_configs)
    return configuration
end

return config
