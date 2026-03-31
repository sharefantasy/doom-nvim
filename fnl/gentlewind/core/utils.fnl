;; gentlewind.core.utils
;; 合并的服务层功能与通用工具函数

(local utils {})

;; ============================================
;; 日志工具
;; ============================================

(fn utils.log-info [msg]
  "记录信息日志"
  (vim.notify msg vim.log.levels.INFO))

(fn utils.log-warn [msg]
  "记录警告日志"
  (vim.notify msg vim.log.levels.WARN))

(fn utils.log-error [msg]
  "记录错误日志"
  (vim.notify msg vim.log.levels.ERROR))

;; ============================================
;; 安全加载工具
;; ============================================

(fn utils.safe_require [module-path]
  "安全地 require 模块，失败返回 nil"
  (let [result [(pcall require module-path)]
        ok (. result 1)
        res (. result 2)]
    (if ok res nil)))

(fn utils.safe_require_with_err [module-path]
  "安全地 require 模块，失败返回 nil 和错误信息"
  (let [result [(pcall require module-path)]
        ok (. result 1)
        res (. result 2)]
    (if ok
        res
        (do
          (vim.notify (.. "Failed to load module: " module-path) vim.log.levels.ERROR)
          nil))))

;; ============================================
;; Profiler (性能分析工具)
;; ============================================

(var start-times {})

(fn utils.start [label]
  "开始性能分析"
  (let [gw (rawget _G "gentlewind")]
    (when (and gw gw.profile)
      (tset start-times label (vim.loop.hrtime)))))

(fn utils.stop [label]
  "停止性能分析并输出"
  (let [gw (rawget _G "gentlewind")]
    (when (and gw gw.profile)
      (when (. start-times label)
        (local duration (/ (- (vim.loop.hrtime) (. start-times label)) 1000000))
        (print (.. "[PROFILE] " label ": " duration "ms"))
        (tset start-times label nil)))))

(fn utils.reset []
  "重置所有性能分析数据"
  (set start-times {}))

;; ============================================
;; Commands / Autocmds / Keymaps
;; ============================================

(fn utils.set_command [name callback opts]
  "创建用户命令"
  (vim.api.nvim_create_user_command name callback (or opts {})))

(fn utils.set_autocmd [event pattern callback opts]
  "创建自动命令"
  (local options (or opts {}))
  (tset options :pattern pattern)
  (tset options :callback callback)
  (vim.api.nvim_create_autocmd event options))

(fn utils.applyKeymaps [keymaps]
  "应用键绑定（依赖 nest.nvim）"
  (let [result [(pcall require :nest)]
        ok (. result 1)
        nest (. result 2)]
    (if ok
        ((. nest :applyKeymaps) keymaps)
        (do
          (local group (vim.api.nvim_create_augroup "GentlewindNestRetry" {:clear false}))
          (local retry (fn []
                         (let [result2 [(pcall require :nest)]
                               ok2 (. result2 1)
                               nest2 (. result2 2)]
                           (when ok2
                             ((. nest2 :applyKeymaps) keymaps)))))
          (vim.api.nvim_create_autocmd "User"
            {:pattern "LazyDone"
             :group group
             :once true
             :callback retry})))))

utils
