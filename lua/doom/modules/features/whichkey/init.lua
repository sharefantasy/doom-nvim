local whichkey = {}

whichkey.settings = {
    leader = " ",
    plugins = {
        marks = false,
        registers = false,
        presets = {
            operators = false,
            motions = true,
            text_objects = true,
            windows = true,
            nav = true,
            z = true,
            g = true
        }
    },
    icons = {breadcrumb = "»", separator = "➜", group = "+"},
    replace = {["<space>"] = "SPC", ["<cr>"] = "RET", ["<tab>"] = "TAB"},
    win = {padding = {0, 0, 0, 0}, border = doom.border_style},
    layout = {height = {min = 1, max = 10}, spacing = 3, align = "left"},
    show_help = true,
    triggers = {"<leader>"},
    defer = function(trigger) return trigger:find("<leader>") ~= nil end
}

whichkey.packages = {
  ["which-key.nvim"] = {
    "folke/which-key.nvim",
    keys = { "<leader>" },
  },
}

-- TODO: Not happy with how messy the integrations are.  Refactor!
whichkey.configs = {}
whichkey.configs["which-key.nvim"] = function()
    vim.g.mapleader = doom.features.whichkey.settings.leader

    local wk = require("which-key")

    wk.setup(doom.features.whichkey.settings)

    local get_whichkey_integration = function()
        --- @type NestIntegration
        local module = {}
        module.name = "whichkey"

        -- which-key v3: 使用 `wk.add(spec, opts)` 新格式，避免旧版 `register()` spec 触发告警
        -- spec 只用于 which-key 展示，不负责真正的 keymap 设置
        ---@type table<string, table[]>
        local specs = {}

        --- Handles each node of the nest keymap config (except the top level)
        --- @param node NestIntegrationNode
        --- @param node_settings NestSettings
        module.handler = function(node, node_settings)
            -- Only handle <leader> keys, which key needs a 'Name' field
            if node.lhs:find("<leader>") == nil or node.name == nil then
                return
            end

            for _, v in ipairs(vim.split(node_settings.mode or "n", "")) do
                if specs[v] == nil then specs[v] = {} end
                -- If this is a keymap group
                local rhs_type = type(node.rhs)
                if rhs_type == "table" then
                    table.insert(specs[v], { node.lhs, group = node.name })
                    -- If this is an actual keymap
                elseif rhs_type == "string" or rhs_type == "function" then
                    table.insert(specs[v], { node.lhs, desc = node.name })
                end
            end
        end

        module.on_complete = function()
            local wk = require("which-key")
            for mode, spec in pairs(specs) do
                if spec and #spec > 0 then
                    wk.add(spec, { mode = mode })
                end
            end
            specs = {}
        end

        return module
    end

    local keymaps_service = require("doom.services.keymaps")
    local whichkey_integration = get_whichkey_integration()
    for section_name, _ in pairs(doom.modules) do
        for _, module in pairs(doom[section_name]) do
            if module and module.binds then
                -- table.insert(all_keymaps, type(module.binds) == "function" and module.binds() or module.binds)
                keymaps_service.applyKeymaps(
                    type(module.binds) == "function" and module.binds() or
                        module.binds, nil, {whichkey_integration})
            end
        end
    end

    -- Add user keymaps to whichkey user keymaps
    if doom.binds and #doom.binds >= 1 then
        keymaps_service.applyKeymaps(doom.binds, nil, {whichkey_integration})
    end
end

return whichkey
