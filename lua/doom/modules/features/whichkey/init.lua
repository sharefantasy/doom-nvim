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
        local function translate_label(name)
            if type(name) ~= "string" then
                return name
            end

            local prefix = ""
            local label = name
            if label:sub(1, 1) == "+" then
                prefix = "+"
                label = label:sub(2)
            end

            local lower = label:lower()
            local phrase_map = {
                ["split or join code block"] = "拆合块",
                ["split code block"] = "拆分块",
                ["join code block"] = "合并块",
            }
            for phrase, zh in pairs(phrase_map) do
                if lower:find(phrase, 1, true) then
                    return prefix .. zh
                end
            end

            local words = {}
            for w in lower:gsub("[/_-]+", " "):gmatch("%w+") do
                table.insert(words, w)
            end

            if #words == 0 then
                return name
            end

            local map = {
                application = "应用",
                buffer = "缓冲",
                buffers = "缓冲",
                breakpoint = "断点",
                code = "代码",
                comment = "注释",
                debug = "调试",
                diagnostics = "诊断",
                diff = "对比",
                explorer = "文件树",
                file = "文件",
                files = "文件",
                find = "搜索",
                git = "版本",
                help = "帮助",
                history = "历史",
                lsp = "LSP",
                markdown = "文档",
                join = "合并",
                split = "拆分",
                block = "块",
                quit = "退出",
                auto = "自动",
                autodetect = "自动",
                detect = "检测",
                nav = "导航",
                open = "打开",
                close = "关闭",
                prefix = "前缀",
                project = "项目",
                recent = "最近",
                repl = "REPL",
                search = "搜索",
                session = "会话",
                symbol = "符号",
                symbols = "符号",
                terminal = "终端",
                test = "测试",
                toggle = "切换",
                tree = "文件树",
                tweak = "调整",
                tweaks = "调整",
                window = "窗口",
            }

            local out = ""
            for _, w in ipairs(words) do
                local t = map[w]
                if not t then
                    return name
                end
                out = out .. t
            end

            if #out > 6 then
                out = out:sub(1, 6)
            end
            return prefix .. out
        end

        local function label_from_lhs(lhs)
            local key = lhs:match("<leader>(.+)$")
            if not key then
                return nil
            end

            local map = {
                a = "应用",
                b = "缓冲",
                c = "代码",
                d = "调试",
                D = "调试",
                f = "搜索",
                g = "版本",
                j = "合并",
                m = "文档",
                o = "打开",
                p = "项目",
                q = "退出",
                r = "REPL",
                s = "搜索",
                t = "调整",
                w = "窗口",
            }

            local label = map[key]
            if label then
                return "+" .. label
            end
            return nil
        end

        module.handler = function(node, node_settings)
            -- Only handle <leader> keys, which key needs a 'Name' field
            local raw_name = node.name or node.group
            if node.lhs:find("<leader>") == nil then
                return
            end

            local label = raw_name and translate_label(raw_name) or label_from_lhs(node.lhs)
            if not label then
                return
            end

            for _, v in ipairs(vim.split(node_settings.mode or "n", "")) do
                if specs[v] == nil then specs[v] = {} end
                -- If this is a keymap group
                local rhs_type = type(node.rhs)
                if rhs_type == "table" then
                    table.insert(specs[v], { node.lhs, group = label })
                    -- If this is an actual keymap
                elseif rhs_type == "string" or rhs_type == "function" then
                    table.insert(specs[v], { node.lhs, desc = label })
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
