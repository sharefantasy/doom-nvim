local sql = {}

sql.settings = {}

sql.packages = {
    ["dbee"] = {
        "kndndrj/nvim-dbee",
        dependencies = {"MunifTanjim/nui.nvim"},
        cmd = { "Dbee" },
        keys = { { "<leader>as", mode = "n" } },
        lazy = true,
        build = function()
            -- Install tries to automatically detect the install method.
            -- if it fails, try calling it with one of these parameters:
            --    "curl", "wget", "bitsadmin", "go"
            require("dbee").install()
        end
    }

    -- ["dadbod"] = {
    --   "kristijanhusak/vim-dadbod-ui",
    --   dependencies = {
    --     { "tpope/vim-dadbod",                     lazy = true },
    --     { "kristijanhusak/vim-dadbod-completion", ft = { "sql", "mysql", "plsql" }, lazy = true },
    --   },
    --   cmd = {
    --     "DBUI",
    --     "DBUIToggle",
    --     "DBUIAddConnection",
    --     "DBUIFindBuffer",
    --   },
    --   init = function()
    --     -- Your DBUI configuration
    --     vim.g.db_ui_use_nerd_fonts = 1
    --   end,
    --   lazy = true,
    -- },
}

sql.configs = {}
sql.configs["dbee"] = function()
    require("dbee").setup({
        sources = {
            require("dbee.sources").FileSource:new(
                "~/.sensitive/dbee_persistence.json")
        }
    })
end

sql.binds = {
    "<leader>",
    name = "+prefix",
    {
        {
            "a",
            name = "+application",
            {
                {
                    "s",
                    function()
                      local ok, lazy = pcall(require, "lazy")
                      if ok then
                        lazy.load { plugins = { "nvim-dbee" } }
                      end
                      require("dbee").toggle()
                    end,
                    name = "Open SQL Viewer"
                }
            }
        }
    }
}

return sql
