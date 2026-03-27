local gentlewind_themes = {}

gentlewind_themes.settings = {}

gentlewind_themes.configs = {}

gentlewind_themes.packages = {
  ["gentlewind-themes.nvim"] = {
    "GustavoPrietoP/gentlewind-themes.nvim",
    event = "ColorScheme",
    lazy = true,
  },
}

return gentlewind_themes
