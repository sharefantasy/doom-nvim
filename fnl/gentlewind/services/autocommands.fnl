;; gentlewind.services.autocommands
;; Autocommand management service for gentlewind-nvim

(local autocmds_service {})

(fn autocmds_service.set [event pattern callback opts]
  "Create an autocommand"
  (local options (or opts {}))
  (when (= (type callback) :string)
    (set options.command callback)
    (set options.callback nil))
  
  (vim.api.nvim_create_autocmd event (vim.tbl_extend "force"
                                                       {:pattern pattern
                                                        :callback callback}
                                                       options)))

{:set autocmds_service.set}
