;; doom.core.ui
;; UI configuration and colorscheme setup for doom-nvim

(local ui {})

(fn ui.setup_colorscheme []
  "Setup the colorscheme"
  (when doom.colorscheme
    (vim.cmd (.. "colorscheme " doom.colorscheme))))

;; Setup UI on load
(ui.setup_colorscheme)