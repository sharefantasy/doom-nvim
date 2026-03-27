local _2afile_2a = "/Users/fankainang/sources/gentlewind-nvim/fnl/gentlewind/modules/langs/markdown.fnl"
local markdown = {}
markdown.settings = {treesitter_grammars = "markdown", lsp_name = "marksman", formatting_package = "prettier", formatting_provider = "builtins.formatting.prettier", formatting_config = nil, disable_formatting = false, disable_lsp = false, disable_treesitter = false}
local function _1_()
  return _G.vim.fn({"mkdp#util#install"})
end
local function _2_()
  _G.vim.g.mkdp_filetypes = {"markdown"}
  return nil
end
markdown.packages = {["markdown-preview"] = {repo = "iamcco/markdown-preview.nvim", build = _1_, config = _2_}}
markdown.configs = {}
markdown.autocmds = {}
local function _3_()
  return _G.vim.fn({"mkdp#util#start_preview"})
end
markdown.cmds = {{{"MarkdownPreview"}, _3_, {desc = "开预览"}}}
local function _4_()
  return _G.vim.fn({"mkdp#util#start_preview"})
end
local function _5_()
  return _G.vim.fn({"mkdp#util#stop_preview"})
end
markdown.binds = {n = {keybinds = {"<leader>m", {name = "+文档"}, "<leader>mp", {desc = "开预览", cmd = _4_}, "<leader>ms", {desc = "关预览", cmd = _5_}}}}
return {packages = markdown.packages, configs = markdown.configs, settings = markdown.settings, autocmds = markdown.autocmds, cmds = markdown.cmds, binds = markdown.binds}
