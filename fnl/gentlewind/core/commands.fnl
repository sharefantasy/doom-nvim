;; gentlewind.core.commands
;; Core commands for gentlewind-nvim

(local commands (require :gentlewind.core.utils))

;; Gentlewind check updates command
(commands.set_command "GentlewindCheckUpdates"
              (fn []
                (local exists vim.fn.exists)
                (local has-cmd
                  (fn [name]
                    (> (exists (.. ":" name)) 0)))

                (local run-cmd
                  (fn [cmd-name cmdline]
                    (if (has-cmd cmd-name)
                        (let [(ok err) (pcall vim.cmd cmdline)]
                          (when (not ok)
                            (vim.notify (.. cmd-name " failed: " (tostring err)) vim.log.levels.ERROR)))
                        (vim.notify (.. "Command not found: " cmd-name) vim.log.levels.WARN))))

                ;; 约定：检查更新 = 插件更新 + mason registry 更新
                ;; - `:Lazy update`：更新 lazy.nvim 管理的插件
                ;; - `:MasonUpdate`：更新 Mason registry（工具/LS 安装源索引）
                (run-cmd "Lazy" "Lazy update")
                (run-cmd "MasonUpdate" "MasonUpdate"))
              {:desc "Run Lazy update + MasonUpdate"})

;; Gentlewind reload command
(commands.set_command "GentlewindReload"
              (fn []
                ;; NOTE: `luafile %` 只会重载当前 buffer 的文件。
                ;; 在 Agentic / Telescope 等特殊 buffer 中执行会直接报错。
                ;; 这里改为重载用户配置入口 `user.config`。
                (let [reload-mod
                      (fn [name]
                        (tset package.loaded name nil)
                        (pcall require name))]

                  (let [(ok err) (reload-mod "user.config")]
                    (if ok
                        (vim.notify "Gentlewind configuration reloaded (user.config)" vim.log.levels.INFO)
                        (vim.notify (.. "GentlewindReload failed: " (tostring err)) vim.log.levels.ERROR)))))
              {:desc "Reload Gentlewind configuration"})

;; Gentlewind version command
(commands.set_command "GentlewindVersion"
              (fn []
                (let [v (or (and gentlewind gentlewind.version) "unknown")]
                  (vim.notify (.. "Gentlewind Nvim v" v) vim.log.levels.INFO)))
              {:desc "Show Gentlewind Nvim version"})
