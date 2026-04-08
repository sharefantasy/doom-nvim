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

(fn process-cmd-field [keymap-table]
  "处理键映射表中的 :cmd 字段，转换为 which-key 格式"
  (when keymap-table
    (each [key value (pairs keymap-table)]
      (when (= (type value) :table)
        (if (. value :cmd)
          ;; 有 :cmd 字段，转换格式
          (let [cmd (. value :cmd)
                desc (or (. value :desc) (. value :name))
                new-value (if desc {:desc desc} {})]
            (if (= (type cmd) :string)
              (tset new-value 1 cmd)
              (tset new-value 1 cmd))
            (tset keymap-table key new-value))
          ;; 没有 :cmd，递归处理子表
          (process-cmd-field value)))))
  keymap-table)

(fn utils.applyKeymaps [keymaps]
  "应用键绑定"
  (when keymaps
    (let [processed-keymaps (process-cmd-field (vim.deepcopy keymaps))
          result [(pcall require :which-key)]
          ok (. result 1)
          wk (. result 2)]
      (if ok
          (let [(ok2 err) (pcall #((. wk :register) processed-keymaps))]
            (when (not ok2)
              (utils.log-error (.. "Failed to apply keymaps: " err))))
          (do
            (local group (vim.api.nvim_create_augroup "GentlewindWhichKeyRetry" {:clear false}))
            (local retry (fn []
                           (let [result2 [(pcall require :which-key)]
                                 ok2 (. result2 1)
                                 wk2 (. result2 2)]
                             (when ok2
                               (let [(ok3 err) (pcall #((. wk2 :register) processed-keymaps))]
                                 (when (not ok3)
                                   (utils.log-error (.. "Failed to apply keymaps: " err))))))))
            (vim.api.nvim_create_autocmd "User"
              {:pattern "LazyDone"
               :group group
               :once true
               :callback retry}))))))

utils
