;; gentlewind.utils
;; Utility functions for gentlewind-nvim

;; Safe require that returns nil if module not found instead of erroring
(fn safe_require [module-name]
  "Safely require a module, returning nil if not found"
  (local [ok result] (pcall require module-name))
  (if ok result nil))

;; Check if a module is enabled
(fn is_module_enabled [section module-name]
  "Check if a specific module is enabled"
  (and gentlewind.modules
       (. gentlewind.modules section)
       (. (. gentlewind.modules section) module-name)))

;; Find config file in various locations
(fn find_config [filename]
  "Find config file in various standard locations"
  (local config-dir (vim.fn.stdpath :config))
  (local data-dir (vim.fn.stdpath :data))
  
  (local search-paths [(.. config-dir "/" filename)
                       (.. config-dir "/../gentlewind-nvim/" filename)
                       (.. data-dir "/site/pack/packer/start/gentlewind-nvim/" filename)])
  
  (each [_ path (ipairs search-paths)]
    (when (= (vim.fn.filereadable path) 1)
      (lua :return path)))
  
  ;; Default to first path if none found
  (.. config-dir "/" filename))

;; Pick compatible field based on neovim version
(fn pick_compatible_field [version-table]
  "Pick the appropriate field from a version-dependent table"
  (local nvim-version (vim.version))
  (local major (. nvim-version :major))
  (local minor (. nvim-version :minor))
  
  ;; Check for exact version matches first
  (when (and (. version-table major) (. (. version-table major) minor))
    (lua :return (. (. version-table major) minor)))
  
  ;; Check for major version matches
  (when (. version-table major)
    (lua :return (. version-table major)))
  
  ;; Default to first available version
  (each [_ value (pairs version-table)]
    (lua :return value)))

;; Logging utilities
(local logging {})

(fn logging.info [message]
  "Log an info message"
  (vim.notify message vim.log.levels.INFO))

(fn logging.warn [message]
  "Log a warning message"
  (vim.notify message vim.log.levels.WARN))

(fn logging.error [message]
  "Log an error message"
  (vim.notify message vim.log.levels.ERROR))

(fn logging.debug [message]
  "Log a debug message"
  (when (= gentlewind.logging "debug")
    (vim.notify message vim.log.levels.DEBUG)))

{:safe_require safe_require
 :is_module_enabled is_module_enabled
 :find_config find_config
 :pick_compatible_field pick_compatible_field
 :logging logging}
