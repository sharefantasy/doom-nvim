;; gentlewind.modules.langs.utils
;; Language utilities for gentlewind-nvim

(local utils {})

(fn utils.wrap_language_setup [lang callback]
  "Wrap language setup with proper error handling"
  (fn []
    (let [packed [(pcall callback)]
          ok (. packed 1)
          err (. packed 2)]
      (when (not ok)
        (vim.notify (.. "Error setting up " lang " language support: " err) vim.log.levels.ERROR)))))

(fn utils.use_lsp_mason [server-name]
  "Use LSP server via Mason"
  ;; 注意：不要在每次 FileType 时重复调用 mason-lspconfig.setup。
  ;; 这里改为：按需安装对应的 mason package（若缺失/未安装），并在安装成功后启用对应 LSP server。
  (let [(ok-mlsp mappings) (pcall require :mason-lspconfig.mappings)
        (ok-reg registry) (pcall require :mason-registry)]
    (when (and ok-mlsp ok-reg)
      (local map ((. mappings :get_mason_map)))
      (local pkg-name (or (. map.lspconfig_to_package server-name) server-name))

      (local enable-server
             (fn []
               ;; 确保该 server 的默认配置已注册（来自 nvim-lspconfig 的 runtime/lsp/*.lua）。
               (pcall vim.lsp.config server-name {})
               (pcall (fn [] (vim.lsp.enable [server-name])))))

      ;; 清理 bin 目录里指向 packages/<pkg-name> 的断链 symlink（如历史手工删除包目录导致）
      (let [data (vim.fn.stdpath "data")
            bin-dir (vim.fs.joinpath data "mason" "bin")
            needle (.. "/mason/packages/" pkg-name "/")
            fd (vim.loop.fs_scandir bin-dir)]
        (when fd
          (var name (vim.loop.fs_scandir_next fd))
          (while name
            (let [p (vim.fs.joinpath bin-dir name)
                  target (vim.loop.fs_readlink p)]
              (when (and target (string.find target needle 1 true))
                (let [abs-target (if (vim.startswith target "/")
                                     target
                                     (vim.fs.joinpath bin-dir target))]
                  (when (not (vim.loop.fs_stat abs-target))
                    (pcall vim.loop.fs_unlink p)))))
            (set name (vim.loop.fs_scandir_next fd)))))

      ;; 若 package 未安装则安装；安装成功后启用对应 LSP server。
      (let [packed [(pcall registry.get_package pkg-name)]
            ok (. packed 1)
            pkg (. packed 2)]
        (when ok
          (if (pkg:is_installed)
              (enable-server)
              (do
                (pkg:once "install:success" (fn [_receipt] (vim.schedule enable-server)))
                (pkg:once "install:failed" (fn [err]
                                              (vim.notify (.. "Mason 安装失败：" pkg-name " - " err)
                                                          vim.log.levels.ERROR)))
                (when (not (pkg:is_installing))
                  (local install (require :mason-lspconfig.install))
                  (install.install pkg)))))))))

(fn utils.use_tree_sitter [grammars]
  "Use tree-sitter grammar"
  (when (not gentlewind._ts_grammars)
    (tset gentlewind :_ts_grammars {}))
  (local list (if (= (type grammars) :string)
                 [grammars]
                 grammars))
  (when (= (type list) :table)
    (each [_ g (ipairs list)]
      (when (and g (not= g ""))
        (tset gentlewind._ts_grammars g true)))))

{:wrap_language_setup utils.wrap_language_setup
 :use_lsp_mason utils.use_lsp_mason
 :use_tree_sitter utils.use_tree_sitter
 }
