;; gentlewind.core.functions
;; Core utility functions for gentlewind-nvim

(local functions {})

(fn functions.sugar_folds []
  "Create sugar folds function for better fold display"
  (fn [txt]
    (local start-line-str (vim.fn.getline (vim.v.foldstart)))
    (local num-lines (.. (- vim.v.foldend vim.v.foldstart) " lines"))
    (.. start-line-str " " num-lines)))

{:sugar_folds functions.sugar_folds}
