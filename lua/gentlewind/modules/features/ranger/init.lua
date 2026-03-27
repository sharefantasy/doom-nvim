local ranger = {}

ranger.settings = {}

ranger.packages = {
  ["ranger.vim"] = {
    "francoiscabrol/ranger.vim",
    dependencies = {
      "rbgrouleff/bclose.vim"
    },
    lazy = true,
    cmd = {
      "Ranger",
      "RangerNewTab",
      "RangerWorkingDirectory",
      "RangerWorkingDirectoryNewTab",
    },
  },
}

ranger.configs = {}

ranger.binds = {
    { "<leader>", group = "prefix", {
        { "o", group = "open/close", { { "r", "<cmd>Ranger<CR>", desc = "Ranger" } } }
    }},
    { "-", "<cmd>Ranger<CR>", desc = "Ranger" }
}

return ranger
