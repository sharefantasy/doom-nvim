local M = {}

-- 搜索导航插件配置
M.setup = function()
  -- fzf - 模糊搜索
  gentlewind.use_package { "junegunn/fzf", build = ":call fzf#install()", cmd = { "FZF" } }

  -- fzfx.nvim - 增强模糊搜索
  gentlewind.use_package {
    "linrongbin16/fzfx.nvim",
    dependencies = { "junegunn/fzf" },
    event = "CmdlineEnter",
    config = function()
      require("fzfx").setup()
    end,
  }

  -- Hypersonic.nvim - 正则表达式工具
  gentlewind.use_package {
    "tomiis4/Hypersonic.nvim",
    event = "CmdlineEnter",
    cmd = "Hypersonic",
    config = function()
      require("hypersonic").setup {}
    end,
  }

  -- nvim-orgmode/orgmode - 组织模式
  gentlewind.use_package {
    "nvim-orgmode/orgmode",
    event = "VeryLazy",
    config = function()
      -- 不再手动设置treesitter，使用gentlewind的treesitter配置
      require("orgmode").setup {
        org_agenda_files = "~/orgfiles/**/*",
        org_default_notes_file = "~/orgfiles/refile.org",
      }
    end,
  }
end

return M
