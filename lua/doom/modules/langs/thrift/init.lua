local thrift = {}

thrift.settings = {
    --- Disables auto installing the treesitter
    --- @type boolean
    disable_treesitter = false,
    --- Treesitter grammars to install
    --- @type string|string[]
    treesitter_grammars = "thrift",

    --- Disables default LSP config
    --- @type boolean
    disable_lsp = false,
    --- Name of the language server
    --- @type string
    lsp_name = "thriftls",

    --- Disables null-ls formatting sources
    --- @type boolean
    disable_formatting = true,
    --- Mason.nvim package to auto install the formatter from
    --- @type string
    formatting_package = "thrift_format",
    --- String to access the null_ls diagnositcs provider
    --- @type string
    formatting_provider = "builtins.formatting.thrift_format",
    --- Function to configure null-ls formatter
    --- @type function|nil
    formatting_config = nil
}

local langs_utils = require("doom.modules.langs.utils")
thrift.autocmds = {
    {
        "FileType",
        "thrift",
        langs_utils.wrap_language_setup("thrift", function()
            if not thrift.settings.disable_lsp then
                langs_utils.use_lsp_mason(thrift.settings.lsp_name)
            end

            if not thrift.settings.disable_treesitter then
                langs_utils.use_tree_sitter(thrift.settings.treesitter_grammars)
            end

            if not thrift.settings.disable_formatting then
                langs_utils.use_null_ls(thrift.settings.formatting_package,
                                        thrift.settings.formatting_provider,
                                        thrift.settings.formatting_config)
            end
        end),
        once = true
    }
}
doom.use_package({"solarnz/thrift.vim"})

return thrift
