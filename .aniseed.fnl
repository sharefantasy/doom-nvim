;; Aniseed configuration for Doom Nvim
;; This file configures how Aniseed compiles Fennel to Lua

{:compile-path "lua"
 :fnl-path "fnl"
 :source-paths ["fnl"]
 :output-paths ["lua"]
 :compiler {:metadata true
            :useMetadata true
            :requireAsInclude false
            :moduleName "doom"
            :modulePrefix "doom"}}