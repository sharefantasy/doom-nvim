;; doom.modules.langs.glsl
;; GLSL language support for doom-nvim

(local glsl {})

(glsl.settings
  {:disable_treesitter false
   :treesitter_grammars "glsl"
   :disable_lsp false
   :lsp_name "glsl_analyzer"
   :disable_formatting true
   :formatting_package nil
   :formatting_provider nil
   :formatting_config nil})

(glsl.packages {})
(glsl.configs {})

(local langs_utils (require :doom.modules.langs.utils))

(glsl.autocmds
  [{:FileType :glsl
    (langs_utils.wrap_language_setup "glsl" (fn []
                                              (when (not glsl.settings.disable_lsp)
                                                (langs_utils.use_lsp_mason glsl.settings.lsp_name))
                                              
                                              (when (not glsl.settings.disable_treesitter)
                                                (langs_utils.use_tree_sitter glsl.settings.treesitter_grammars))))
    :once true}])

(glsl.cmds [])
(glsl.binds [])

{: packages glsl.packages
 : configs glsl.configs
 : settings glsl.settings
 : autocmds glsl.autocmds
 : cmds glsl.cmds
 : binds glsl.binds}