;; gentlewind.modules.core.treesitter
;; Treesitter module for gentlewind-nvim

(local treesitter {})

(set treesitter.packages
  {:nvim-treesitter {:repo "nvim-treesitter/nvim-treesitter"
                     :branch "main"
                     :build ":TSUpdate"
                     :config (fn []
                               ((. (require :nvim-treesitter) :setup) {}))}})

(set treesitter.configs {})
(set treesitter.settings {:show_compiler_warning_message false})

(fn collect-ts-grammars []
  (local want {})

  (fn add-one [g]
    (when (and g (not= g ""))
      (tset want g true)))

  (fn add-many [gs]
    (if (= (type gs) :string)
        (add-one gs)
        (= (type gs) :table)
        (each [_ x (ipairs gs)]
          (add-one x))))

  ;; from enabled language modules
  (when (and gentlewind gentlewind.modules gentlewind.modules.langs)
    (each [_ mod (pairs gentlewind.modules.langs)]
      (when (= (type mod) :table)
        (local s mod.settings)
        (when (and (= (type s) :table) (not s.disable_treesitter))
          (add-many s.treesitter_grammars)))))

  ;; from langs/utils registry
  (when (and gentlewind gentlewind._ts_grammars)
    (each [g _ (pairs gentlewind._ts_grammars)]
      (add-one g)))

  (local grammars [])
  (each [g _ (pairs want)]
    (table.insert grammars g))
  (table.sort grammars)
  grammars)

(fn ensure-ts-parsers []
  (local grammars (collect-ts-grammars))
  (when (> (# grammars) 0)
    (local supported (require :nvim-treesitter.parsers))
    (local cfg (require :nvim-treesitter.config))
    (local installed (cfg.get_installed))
    (local have {})
    (each [_ g (ipairs installed)]
      (tset have g true))
    (local missing [])
    (each [_ g (ipairs grammars)]
      (when (and (. supported [g]) (not (. have [g])))
        (table.insert missing g)))
    (when (> (# missing) 0)
      ((. (require :nvim-treesitter.install) :install) missing {:summary true}))))

(set treesitter.autocmds
  [{:User "GentlewindStarted"
    :once true
    :desc "Ensure Tree-sitter parsers are installed"
    :callback (fn []
                (let [(ok err) (pcall ensure-ts-parsers)]
                  (when (not ok)
                    (vim.notify (.. "Tree-sitter ensure_installed failed: " err) vim.log.levels.WARN))))}])
(set treesitter.cmds [])
(set treesitter.binds [])

{:packages treesitter.packages
 :configs treesitter.configs
 :settings treesitter.settings
 :autocmds treesitter.autocmds
 :cmds treesitter.cmds
 :binds treesitter.binds}
