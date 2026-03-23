local python = {}
python.settings = {
  disable_treesitter = false,
  treesitter_grammars = "python",
  disable_lsp = false,
  lsp_name = "pyright",
  disable_formatting = false,
  formatting_package = "black",
  formatting_provider = "builtins.formatting.black",
  formatting_config = nil
}
python.packages = {}
python.configs = {}
local langs_utils = require("doom.modules.langs.utils")
python.autocmds = { {
  "FileType",
  "python",
  langs_utils.wrap_language_setup("python", function()
    if not python.settings.disable_lsp then
      langs_utils.use_lsp_mason(python.settings.lsp_name)
    end
    if not python.settings.disable_treesitter then
      langs_utils.use_tree_sitter(python.settings.treesitter_grammars)
    end
    if not python.settings.disable_formatting then
      langs_utils.use_null_ls(python.settings.formatting_package, python.settings.formatting_provider, python.settings.formatting_config)
    end
  end),
  once = true
} }
python.cmds = {}
python.binds = {}
return {
  packages = python.packages,
  configs = python.configs,
  settings = python.settings,
  autocmds = python.autocmds,
  cmds = python.cmds,
  binds = python.binds
}