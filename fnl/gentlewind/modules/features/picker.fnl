;; user.modules.features.picker
;; Snacks picker 统一入口（telescope 保留但不启用）

(local M {})

(fn snacks? []
  (let [packed [(pcall require :snacks)]
        ok (. packed 1)]
    ok))

(fn Snacks []
  (require :snacks))

(set M.packages
  {:snacks
   {:repo "folke/snacks.nvim"
    ;; 由于本框架会在启动期直接创建 keymap，Snacks 必须提前可用。
    :lazy false
    :priority 1000
    :config (fn []
              (pcall (fn []
                       ((. (Snacks) :setup)
                        {:picker {:enabled true}
                         ;; 体验增强组件（整体替换 telescope 并加强 UI）
                         :notifier {:enabled true}
                         :input {:enabled true}
                         :indent {:enabled true}
                         :statuscolumn {:enabled true}
                         :dashboard {:enabled true}
                         :explorer {:enabled true}
                         :terminal {:enabled true}
                         :lazygit {:enabled true}

                         ;; 其他常用增强（默认也打开，基本低侵入）
                         :bufdelete {:enabled true}
                         :toggle {:enabled true}
                         :scroll {:enabled true}
                         :scope {:enabled true}
                         :words {:enabled true}
                         :gitbrowse {:enabled true}
                         :zen {:enabled true}

                         ;; 避免引入额外依赖/平台限制：先不启用 image/gh
                         :image {:enabled false}
                         :gh {:enabled false}}))))}})

(fn call [f]
  (if (snacks?)
      (pcall f)
      (vim.notify "snacks.nvim 未加载（请确认已启用 features: picker）" vim.log.levels.WARN)))

;; =============================
;; nvim.sh picker (search + install + persist)
;; =============================

(local nvimsh-block-start ";; nvim.sh managed plugins (auto)")
(local nvimsh-block-end ";; end nvim.sh managed plugins")

(fn trim [s]
  (if (or (not s) (not= (type s) :string))
      ""
      (let [s (string.gsub s "^%s+" "")
            s (string.gsub s "%s+$" "")]
        s)))

(fn repo->name [repo]
  (let [repo (trim repo)
        packed [(pcall (fn [] (string.match repo "[^/]+$")))]
        ok (. packed 1)
        name (. packed 2)]
    (if (and ok name (not= name "")) name repo)))

(fn fennel-escape [s]
  (let [s (tostring (or s ""))
        s (string.gsub s "\\" "\\\\")
        s (string.gsub s "\"" "\\\"")]
    s))

(fn extra-fnl-path []
  (vim.fs.joinpath (vim.fn.stdpath "config") "fnl" "user" "extra.fnl"))

(fn ensure-nvimsh-block! [lines]
  (var start-idx nil)
  (var end-idx nil)
  (each [i line (ipairs lines)]
    (when (and (not start-idx) (= line nvimsh-block-start))
      (set start-idx i))
    (when (and (not end-idx) (= line nvimsh-block-end))
      (set end-idx i)))

  (when (or (not start-idx) (not end-idx) (>= start-idx end-idx))
    ;; 兜底：如果用户删了区块/顺序不对，就在文件末尾重建
    (when (and (> (# lines) 0) (not= (. lines (# lines)) ""))
      (table.insert lines ""))
    (table.insert lines nvimsh-block-start)
    (table.insert lines ";; - 由 picker 自动写入，请尽量不要手动编辑本区块")
    (table.insert lines ";; - 每行一个： (gentlewind.use_package {:repo \"owner/repo\"})")
    (table.insert lines nvimsh-block-end)
    (set end-idx (# lines))
    (set start-idx (- end-idx 3)))

  {:start start-idx :end end-idx})

(fn persist-plugin-to-extra! [repo]
  (let [path (extra-fnl-path)
        readable (= (vim.fn.filereadable path) 1)]
    ;; 兜底：extra.fnl 丢失时重建
    (when (not readable)
      (pcall
        (fn []
          (vim.fn.writefile
            [";; user.extra"
             ";;"
             ";; 由 nvim.sh picker 自动维护的额外插件列表。"
             ""
             nvimsh-block-start
             ";; - 由 picker 自动写入，请尽量不要手动编辑本区块"
             ";; - 每行一个： (gentlewind.use_package {:repo \"owner/repo\"})"
             nvimsh-block-end
             ""
             "{}"]
            path))))

    (let [packed [(pcall vim.fn.readfile path)]
          ok (. packed 1)
          lines (. packed 2)]
      (if (not ok)
          (vim.notify (.. "读取失败：" path) vim.log.levels.ERROR)
          (let [repo (trim repo)
                idxs (ensure-nvimsh-block! lines)
                start-idx (. idxs :start)
                end-idx (. idxs :end)
                needle (.. "\"" repo "\"")]
            (var exists false)
            (each [i line (ipairs lines)]
              (when (and (>= i start-idx) (<= i end-idx) (string.find line needle 1 true))
                (set exists true)))

            (if exists
                :ok
                (let [newline (.. "(gentlewind.use_package {:repo \"" (fennel-escape repo) "\"})")]
                  ;; insert before end marker
                  (table.insert lines end-idx newline)
                  (let [w [(pcall vim.fn.writefile lines path)]
                        w-ok (. w 1)]
                    (if w-ok
                        (vim.notify (.. "已写入：" repo " -> " path) vim.log.levels.INFO)
                        (vim.notify (.. "写入失败：" path) vim.log.levels.ERROR)))))))))

  )

(fn ensure-lazy-spec! [repo]
  (let [repo (trim repo)
        name (repo->name repo)
        packed [(pcall require :lazy)]
        ok (. packed 1)
        lazy (. packed 2)]
    (if (not ok)
        (do (vim.notify "lazy.nvim 未加载，无法安装" vim.log.levels.ERROR) nil)
        (let [Config (require :lazy.core.config)
              Plugin (require :lazy.core.plugin)
              opts (. Config :options)
              spec0 (. opts :spec)]
          (var spec spec0)

          ;; 1) 本次会话：先追加到 gentlewind.packages（保持一致）
          (pcall (fn [] (gentlewind.use_package {:repo repo})))

          ;; 2) 追加到 lazy 的 options.spec，并 reload 一次 plugins
          (when (not spec)
            (set spec [])
            (tset opts :spec spec))

          (var has false)
          (each [_ s (ipairs spec)]
            (when (= (type s) :string)
              (when (= s repo) (set has true)))
            (when (= (type s) :table)
              (let [r (or (. s 1) (. s :repo) (. s "repo"))]
                (when (= r repo) (set has true)))))

          (when (not has)
            (table.insert spec [repo]))

          ;; 重要：lazy 的 plugin 表需要重建，才能对新 spec 生效
          (pcall (fn [] (Plugin.load)))
          {:repo repo :name name :lazy lazy}))))

(fn lazy-install-and-load! [repo]
  (let [state (ensure-lazy-spec! repo)]
    (when state
      (persist-plugin-to-extra! (. state :repo))
      (let [name (. state :name)
            lazy (. state :lazy)]
        (vim.notify (.. "开始安装：" name) vim.log.levels.INFO)

        ;; install (wait=true 避免后续 load 失败)
        (let [packed [(pcall (fn []
                               ((. lazy :install) {:plugins [name] :wait true :show false})))]
              ok-install (. packed 1)]
          (when (not ok-install)
            (vim.notify (.. "安装失败：" name "（可手动执行 :Lazy install " name "）") vim.log.levels.ERROR)))

        ;; refresh state after install
        (pcall (fn [] ((. (require :lazy.core.plugin) :load))))

        ;; load now
        (let [packed2 [(pcall (fn [] ((. lazy :load) {:plugins [name]})))]
              ok-load (. packed2 1)]
          (if ok-load
              (vim.notify (.. "已安装并加载：" name) vim.log.levels.INFO)
              (vim.notify (.. "已安装但加载失败：" name "（可重启或 :Lazy load " name "）") vim.log.levels.WARN)))))))

(fn nvimsh-picker []
  (let [Snacks (Snacks)]
    ((. (. Snacks :picker) :pick)
     {:title "nvim.sh 插件"
      :prompt " "
      :live true
      :layout {:preset "vscode"}
      :show_delay 120
      :limit_live 200
      :preview "preview"
      :format (fn [item _]
                ;; 结构化显示：repo / ★stars / updated / desc
                (let [repo (or (. item :repo_full) (. item :text) "")
                      stars (tostring (or (. item :stars) ""))
                      updated (tostring (or (. item :updated) ""))
                      desc (tostring (or (. item :desc) ""))
                      line (.. repo "  ★" stars "  " updated)]
                  [{1 line 2 "Identifier"}
                   {1 (if (= desc "") "" (.. "\n" desc)) 2 "Comment"}]))
      :confirm (fn [picker item]
                 (pcall (fn [] ((. picker :close))))
                 (when item
                   (let [repo (. item :repo_full)]
                     (when (and repo (not= (trim repo) "") (not= (string.sub repo 1 1) "#"))
                       (lazy-install-and-load! repo)))))
      :finder (fn [opts ctx]
                ;; `opts.search` 是输入框内容；支持：
                ;; - 关键词：直接搜 /s/<kw>
                ;; - 标签：以 # 开头：#git => /t/git
                (let [q (trim (or (. opts :search) ""))
                      tag? (= (string.sub q 1 1) "#")
                      q2 (if tag? (trim (string.sub q 2)) q)
                      ;; 空输入不打 API，避免 /s 全量太大
                      should-fetch (or tag? (>= (# q2) 2))]
                  (if (not should-fetch)
                      []
                      (fn [cb]
                        (let [async (. ctx :async)
                              url (if tag?
                                      (if (= q2 "")
                                          "https://nvim.sh/t?format=json"
                                          (.. "https://nvim.sh/t/" (vim.uri_encode q2) "?format=json"))
                                      (.. "https://nvim.sh/s/" (vim.uri_encode q2) "?format=json"))
                              ]
                          (var result nil)
                          (vim.system ["curl" "-fsSL" url] {:text true}
                                      (fn [res]
                                        (set result res)
                                        (pcall (fn [] ((. async :resume))))))
                          ;; 等待请求完成（避免在非 async 上下文调用 cb）
                          ((. async :suspend))
                          (when (and result (= (. result :code) 0))
                            (let [decoded (vim.json.decode (or (. result :stdout) "{}"))]
                              (if tag?
                                  (if (= q2 "")
                                      ;; tag list
                                      (each [_ t (ipairs (or (. decoded :tags) []))]
                                        (cb {:text (.. "#" t)
                                             :repo_full (.. "#" t)
                                             :desc "tag"
                                             :stars ""
                                             :updated ""
                                             :preview {:text (.. "tag: #" t) :ft "markdown"}}))
                                      ;; tag search results
                                      (each [_ r (ipairs (or (. decoded :results) []))]
                                        (let [p (. r :plugin)
                                              user (or (. p :username) "")
                                              repo (or (. p :repo) "")
                                              full (if (and (not= user "") (not= repo "")) (.. user "/" repo) (or (. p :id) ""))
                                              stars (or (. p :stars) 0)
                                              updated (or (. p :updatedAt) "")
                                              desc (or (. p :description) "")
                                              link (or (. p :link) "")
                                              tags (or (. p :tags) [])]
                                          (when (not= full "")
                                            (cb {:text full
                                                 :repo_full full
                                                 :url link
                                                 :stars stars
                                                 :updated updated
                                                 :desc desc
                                                 :preview {:text (.. "# " full "\n\n" desc "\n\n" "- url: " link "\n" "- tags: " (table.concat tags ", "))
                                                           :ft "markdown"}})))))
                                  ;; keyword search results
                                  (each [_ r (ipairs (or (. decoded :results) []))]
                                    (let [p (. r :plugin)
                                          user (or (. p :username) "")
                                          repo (or (. p :repo) "")
                                          full (if (and (not= user "") (not= repo "")) (.. user "/" repo) (or (. p :id) ""))
                                          stars (or (. p :stars) 0)
                                          updated (or (. p :updatedAt) "")
                                          desc (or (. p :description) "")
                                          link (or (. p :link) "")
                                          tags (or (. p :tags) [])]
                                      (when (not= full "")
                                        (cb {:text full
                                             :repo_full full
                                             :url link
                                             :stars stars
                                             :updated updated
                                             :desc desc
                                             :preview {:text (.. "# " full "\n\n" desc "\n\n" "- url: " link "\n" "- tags: " (table.concat tags ", "))
                                                      :ft "markdown"}}))))))))))))})))

(set M.binds
  {:<leader>p {:name "+picker"
               :p {:desc "项目" :cmd (fn [] (call (fn [] ((. (. (Snacks) :picker) :projects)))))}
               :f {:desc "找文件" :cmd (fn [] (call (fn [] ((. (. (Snacks) :picker) :files)))))}
               :g {:desc "全文搜" :cmd (fn [] (call (fn [] ((. (. (Snacks) :picker) :grep)))))}
               :b {:desc "缓冲" :cmd (fn [] (call (fn [] ((. (. (Snacks) :picker) :buffers)))))}
               :h {:desc "帮助" :cmd (fn [] (call (fn [] ((. (. (Snacks) :picker) :help)))))}
               :k {:desc "键位" :cmd (fn [] (call (fn [] ((. (. (Snacks) :picker) :keymaps)))))}
               :c {:desc "命令" :cmd (fn [] (call (fn [] ((. (. (Snacks) :picker) :commands)))))}
               :s {:desc "Git 状态" :cmd (fn [] (call (fn [] ((. (. (Snacks) :picker) :git_status)))))}
               :B {:desc "Git 分支" :cmd (fn [] (call (fn [] ((. (. (Snacks) :picker) :git_branches)))))}
               :l {:desc "Git 日志" :cmd (fn [] (call (fn [] ((. (. (Snacks) :picker) :git_log)))))}
               :t {:desc "Picker 列表" :cmd (fn [] (call (fn [] ((. (. (Snacks) :picker) :pickers)))))}
               }
   :<leader>/ {:desc "全局搜索" :cmd (fn [] (call (fn [] ((. (. (Snacks) :picker) :grep)))))} })

;; nvim.sh 入口：放在 <leader>p 下
(tset M.binds :<leader>p :n {:desc "nvim.sh 插件" :cmd (fn [] (call nvimsh-picker))})

;; 常用工具入口（snacks 组件）
(tset M.binds :<leader>t
      {:name "+tools"
       :t {:desc "终端" :cmd (fn [] (call (fn [] ((. (Snacks) :terminal))))) }
       :g {:desc "LazyGit" :cmd (fn [] (call (fn [] ((. (Snacks) :lazygit))))) }
       :e {:desc "文件浏览" :cmd (fn [] (call (fn [] ((. (Snacks) :explorer))))) }})

(set M.configs {})
(set M.settings {})
(set M.autocmds [])
(set M.cmds [])

;; 命令：:Nvimsh
(tset M.cmds 1 ["Nvimsh" (fn [] (call nvimsh-picker)) {:desc "nvim.sh: 搜索并安装插件"}])

{:packages M.packages
 :configs M.configs
 :settings M.settings
 :autocmds M.autocmds
 :cmds M.cmds
 :binds M.binds}
