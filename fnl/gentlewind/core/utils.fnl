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

(fn keymaps-to-wk-spec [tree]
  "把 Gentlewind 的树形 binds 转成 which-key v3 (spec v2) 列表"
  (local out [])

  (fn abs-key? [k]
    (and (= (type k) :string) (= (string.sub k 1 1) "<")))

  (fn join-keys [prefix k]
    (if (abs-key? k)
        k
        (if (or (not prefix) (= prefix ""))
            k
            (.. prefix k))))

  (fn add-group [lhs v]
    (local rhs (or (. v :cmd) (. v 1)))
    ;; 有 rhs 的节点不要再生成 group，否则会和真实映射重复
    (when (not rhs)
      (var has-children false)
      (each [kk vv (pairs v)]
        (when (and (not has-children)
                   (= (type kk) :string)
                   (not= kk "cmd")
                   (not= kk "desc")
                   (not= kk "name")
                   (not= kk "group")
                   (= (type vv) :table))
          (set has-children true)))

      (when has-children
        (local name (or (. v :name) (. v :group)))
        (when (and name (= (type name) :string) (not= name ""))
          (local spec [lhs])
          (tset spec :group name)
          (table.insert out spec)))))

  (fn add-leaf [lhs v]
    (local rhs (or (. v :cmd) (. v 1)))
    (local desc (or (. v :desc) (. v :name)))
    (when rhs
      (local spec [lhs rhs])
      (when (and desc (= (type desc) :string) (not= desc ""))
        (tset spec :desc desc))
      (table.insert out spec)))

  (fn rec [prefix tbl]
    (when (= (type tbl) :table)
      (each [k v (pairs tbl)]
        (when (= (type k) :string)
          (local lhs (join-keys prefix k))
          (when (= (type v) :table)
            (add-group lhs v)
            (add-leaf lhs v)
            (rec lhs v))))))

  (rec "" tree)
  out)

(fn utils.applyKeymaps [keymaps]
  "应用键绑定"
  (when keymaps
    (local meta [])

    (fn meta-desc [lhs desc mode]
      (when (and desc (= (type desc) :string) (not= desc ""))
        (local spec [lhs])
        (tset spec :desc desc)
        (when mode (tset spec :mode mode))
        (table.insert meta spec)))

    (fn meta-group [lhs name mode]
      (when (and name (= (type name) :string) (not= name ""))
        (local spec [lhs])
        (tset spec :group name)
        (when mode (tset spec :mode mode))
        (table.insert meta spec)))

    (fn apply-one [spec]
      (when (= (type spec) :table)
        (local lhs (. spec 1))
        (local rhs (. spec 2))
        (when (= (type lhs) :string)
          (local mode (or (. spec :mode) "n"))
          (local opts {:silent (if (nil? (. spec :silent)) true (. spec :silent))
                       :noremap (if (nil? (. spec :noremap)) true (. spec :noremap))})
          (when (not (nil? (. spec :expr))) (tset opts :expr (. spec :expr)))
          (when (not (nil? (. spec :nowait))) (tset opts :nowait (. spec :nowait)))
          (when (not (nil? (. spec :remap))) (tset opts :remap (. spec :remap)))
          (when (not (nil? (. spec :buffer))) (tset opts :buffer (. spec :buffer)))
          (when (not (nil? (. spec :unique))) (tset opts :unique (. spec :unique)))
          (when (not (nil? (. spec :desc))) (tset opts :desc (. spec :desc)))

          (when rhs
            (vim.keymap.set mode lhs rhs opts))

          (meta-desc lhs (. spec :desc) mode))))

    (fn apply-tree [tree]
      (local wk (keymaps-to-wk-spec (vim.deepcopy tree)))
      (each [_ s (ipairs wk)]
        (local lhs (. s 1))
        (when (= (type lhs) :string)
          (when (. s :group)
            (meta-group lhs (. s :group) "n"))
          (when (. s :desc)
            (meta-desc lhs (. s :desc) "n"))))

      ;; 同时把 tree 里的叶子节点设置成真实 keymap（默认 n 模式）
      (fn rec [prefix tbl]
        (when (= (type tbl) :table)
          (each [k v (pairs tbl)]
            (when (= (type k) :string)
              (local lhs (if (and (= (type k) :string) (= (string.sub k 1 1) "<"))
                             k
                             (if (= prefix "") k (.. prefix k))))
              (when (= (type v) :table)
                (local rhs (or (. v :cmd) (. v 1)))
                (local desc (or (. v :desc) (. v :name)))
                (when rhs
                  (vim.keymap.set "n" lhs rhs {:silent true :noremap true :desc desc}))
                (rec lhs v))))))
      (rec "" tree))

    ;; 先设置真实 vim keymap
    (if (and (= (type keymaps) :table) (= (type (. keymaps 1)) :table) (= (type (. (. keymaps 1) 1)) :string))
        (each [_ s (ipairs keymaps)]
          (apply-one s))
        (if (and (= (type keymaps) :table) (= (type (. keymaps 1)) :string))
            (apply-one keymaps)
            (apply-tree keymaps)))

    ;; 再注册到 which-key（仅元数据，不重复创建 keymap）
    (when (> (# meta) 0)
      (let [result [(pcall require :which-key)]
            ok (. result 1)
            wk (. result 2)]
        (if ok
            (pcall #((. wk :add) meta))
            (do
              (local group (vim.api.nvim_create_augroup "GentlewindWhichKeyRetry" {:clear false}))
              (vim.api.nvim_create_autocmd "User"
                {:pattern "LazyDone"
                 :group group
                 :once true
                 :callback (fn []
                             (let [result2 [(pcall require :which-key)]
                                   ok2 (. result2 1)
                                   wk2 (. result2 2)]
                               (when ok2
                                 (pcall #((. wk2 :add) meta)))))})))))))

utils
