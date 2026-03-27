;; gentlewind.core.ui
;; UI configuration and colorscheme setup for gentlewind-nvim

(local ui {})

(fn ui.setup_colorscheme []
  "Setup the colorscheme"
  (when gentlewind.colorscheme
    (vim.cmd (.. "colorscheme " gentlewind.colorscheme))))

;; Setup UI on load
(ui.setup_colorscheme)