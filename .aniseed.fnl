;; Aniseed configuration for Gentlewind Nvim
;; This file configures how Aniseed compiles Fennel to Lua

{:compile-path "lua"
 :fnl-path "fnl"
 :source-paths ["fnl"]
 :output-paths ["lua"]
 :compiler {:metadata true
            :useMetadata true
            :requireAsInclude false
            :moduleName "gentlewind"
            :modulePrefix "gentlewind"}}