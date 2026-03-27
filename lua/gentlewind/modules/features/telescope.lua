local _2afile_2a = "/Users/fankainang/sources/gentlewind-nvim/fnl/gentlewind/modules/features/telescope.fnl"
local telescope = {}
local function _1_()
  local telescope0 = require("telescope")
  telescope0.setup({defaults = {mappings = {i = {["<C-d>"] = false, ["<C-u>"] = false}}}})
  return telescope0.load_extension("fzf")
end
local function _2_()
  _G.vim.fn.executable("make")
  return 1
end
telescope.packages = {telescope = {repo = "nvim-telescope/telescope.nvim", dependencies = {"nvim-lua/plenary.nvim", "nvim-telescope/telescope-fzf-native.nvim"}, config = _1_}, plenary = {repo = "nvim-lua/plenary.nvim"}, ["telescope-fzf-native"] = {repo = "nvim-telescope/telescope-fzf-native.nvim", build = "make", cond = _2_}}
telescope.configs = {}
telescope.settings = {telescope_buffer_ignore = {"term://*"}, telescope_files_ignore = {"%.jpg", "%.jpeg", "%.png", "%.svg", "%.otf", "%.ttf", "%.woff", "%.woff2", "%.gif", "%.mp4", "%.mp3", "%.m4a", "%.ogg", "%.flac", "%.pdf", "%.zip", "%.tar", "%.gz", "%.rar", "%.7z", "%.bz2", "%.xz", "%.deb", "%.rpm", "%.msi", "%.phar", "%.vsix", "%.apk", "%.dmg"}}
telescope.autocmds = {}
local function _3_(opts)
  return (require("telescope.builtin")).builtin[opts]
end
telescope.cmds = {{{"Telescope"}, _3_, {desc = "内置搜"}}}
local function _4_()
  return (require("telescope.builtin")).find_files
end
local function _5_()
  return (require("telescope.builtin")).recent_files
end
local function _6_()
  return (require("telescope.builtin")).live_grep
end
local function _7_()
  return (require("telescope.builtin")).buffers
end
local function _8_()
  return (require("telescope.builtin")).help_tags
end
telescope.binds = {n = {keybinds = {"<leader>f", {name = "+搜索"}, "<leader>ff", {desc = "找文件", cmd = _4_}, "<leader>fr", {desc = "最近", cmd = _5_}, "<leader>fg", {desc = "全文搜", cmd = _6_}, "<leader>fb", {desc = "缓冲", cmd = _7_}, "<leader>fh", {desc = "帮助", cmd = _8_}}}}
return {packages = telescope.packages, configs = telescope.configs, settings = telescope.settings, autocmds = telescope.autocmds, cmds = telescope.cmds, binds = telescope.binds}
