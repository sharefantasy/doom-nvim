local treesitter = {}

treesitter.settings = {
  --- Checks if the user is using clang and tells them to use GCC if they are.
  --- @type boolean
  show_compiler_warning_message = true,

  treesitter = {
    highlight = { enable = true },
    incremental_selection = {
      enable = true,
      keymaps = {
        init_selection = "gnn",
        node_incremental = "grn",
        scope_incremental = "grc",
        node_decremental = "grm",
      },
    },
    indent = { enable = true },
    playground = { enable = true },
    context_commentstring = { enable = true },
    autotag = {
      enable = true,
      filetypes = {
        "html",
        "javascript",
        "javascriptreact",
        "typescript",
        "typescriptreact",
        "svelte",
        "vue",
        "markdown",
      },
    },
  },
}

treesitter.packages = {
  ["nvim-treesitter"] = {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
  },
  ["nvim-ts-context-commentstring"] = {
    "JoosepAlviste/nvim-ts-context-commentstring",
    -- after = "nvim-treesitter",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    event = "VeryLazy",
  },
  ["nvim-ts-autotag"] = {
    "windwp/nvim-ts-autotag",
    -- after = "nvim-treesitter",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    event = "VeryLazy",
  },
  ["treesj"] = {
    "Wansmer/treesj",
    keys = { "<space>m", "<space>j", "<space>s" },
    dependencies = { "nvim-treesitter/nvim-treesitter" },
  },
  ["tree-textobj"] = {
    "nvim-treesitter/nvim-treesitter-textobjects",
    after = "nvim-treesitter",
    requires = "nvim-treesitter/nvim-treesitter",
  },
  ["tree-textsub"] = {
    "RRethy/nvim-treesitter-textsubjects",
    after = "nvim-treesitter",
    requires = "nvim-treesitter/nvim-treesitter",
  },
}

treesitter.configs = {}
treesitter.configs["nvim-treesitter"] = function()
  local is_module_enabled = require("doom.utils").is_module_enabled
  require("nvim-treesitter.configs").setup(vim.tbl_deep_extend("force", doom.core.treesitter.settings.treesitter, {
    autopairs = { enable = is_module_enabled("features", "autopairs") },
  }))

  --  Check if user is using clang and notify that it has poor compatibility with treesitter
  --  WARN: 19/11/2021 | issues: #222, #246 clang compatibility could improve in future
  if doom.core.treesitter.settings.show_compiler_warning_message then
    vim.defer_fn(function()
      local log = require "doom.utils.logging"
      local utils = require "doom.utils"
      -- Matches logic from nvim-treesitter
      local compiler = utils.find_executable_in_path {
        vim.fn.getenv "CC",
        "cc",
        "gcc",
        "clang",
        "cl",
        "zig",
      }
      local version = vim.fn.systemlist(compiler .. (compiler == "cl" and "" or " --version"))[1]

      if version:match "clang" then
        log.warn(
          "doom-treesitter:  clang has poor compatibility compiling treesitter parsers.  We recommend using gcc, see issue #246 for details.  (https://github.com/doom-neovim/doom-nvim/issues/246)\n"
            .. "Add this line to your config.lua to hide this message.\n\n"
            .. "doom.core.treesitter.settings.show_compiler_warning_message = false"
        )
      end
    end, 1000)
  end
end
treesitter.configs["treesj"] = function()
  require("treesj").setup {--[[ your config ]]
  }
end

treesitter.configs["tree-textobj"] = function()
  require("nvim-treesitter.configs").setup {
    textobjects = {
      select = {
        enable = true,

        -- Automatically jump forward to textobj, similar to targets.vim
        lookahead = true,

        keymaps = {
          -- You can use the capture groups defined in textobjects.scm
          ["af"] = "@function.outer",
          ["if"] = "@function.inner",
          ["ac"] = "@class.outer",
          -- You can optionally set descriptions to the mappings (used in the desc parameter of
          -- nvim_buf_set_keymap) which plugins like which-key display
          ["ic"] = { query = "@class.inner", desc = "Select inner part of a class region" },
          -- You can also use captures from other query groups like `locals.scm`
          ["as"] = { query = "@scope", query_group = "locals", desc = "Select language scope" },
        },
        -- You can choose the select mode (default is charwise 'v')
        --
        -- Can also be a function which gets passed a table with the keys
        -- * query_string: eg '@function.inner'
        -- * method: eg 'v' or 'o'
        -- and should return the mode ('v', 'V', or '<c-v>') or a table
        -- mapping query_strings to modes.
        selection_modes = {
          ["@parameter.outer"] = "v", -- charwise
          ["@function.outer"] = "V", -- linewise
          ["@class.outer"] = "<c-v>", -- blockwise
        },
        -- If you set this to `true` (default is `false`) then any textobject is
        -- extended to include preceding or succeeding whitespace. Succeeding
        -- whitespace has priority in order to act similarly to eg the built-in
        -- `ap`.
        --
        -- Can also be a function which gets passed a table with the keys
        -- * query_string: eg '@function.inner'
        -- * selection_mode: eg 'v'
        -- and should return true of false
        include_surrounding_whitespace = true,
      },
    },
  }
end

treesitter.configs["tree-textsub"] = function()
  require("nvim-treesitter.configs").setup {
    textsubjects = {
      enable = true,
      prev_selection = ",", -- (Optional) keymap to select the previous selection
      keymaps = {
        ["."] = "textsubjects-smart",
        [";"] = "textsubjects-container-outer",
        ["i;"] = "textsubjects-container-inner",
      },
    },
  }
end

return treesitter
