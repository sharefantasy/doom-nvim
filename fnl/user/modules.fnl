;; Example Fennel-based modules.lua for Doom Nvim
;; This replaces the traditional Lua modules.lua

{:features
 [;; Core features
  :lsp
  :telescope
  :whichkey
  
  ;; Optional features (uncomment to enable)
  ;; :explorer
  ;; :git
  ;; :gitsigns
  ;; :dashboard
  ;; :terminal
  ;; :autopairs
  ;; :comment
  ;; :colorizer
  ;; :illuminate
  ;; :indentlines
  ;; :minimap
  ;; :statusline
  ;; :tabline
  ;; :trouble
  ;; :zen
  ]
 
 :langs
 [;; Core languages
  :lua
  :fennel
  
  ;; Web development
  :javascript
  :typescript
  :html
  :css
  :vue
  :svelte
  :tailwindcss
  
  ;; Systems programming
  :rust
  :go
  :cc
  
  ;; Scripting
  :python
  :bash
  :fish
  
  ;; Data formats
  :json
  :yaml
  :toml
  
  ;; Documentation
  :markdown
  
  ;; Infrastructure
  :dockerfile
  :terraform
  
  ;; Databases
  :sql
  
  ;; Functional programming
  :haskell
  :clojure
  :ocaml
  
  ;; Game development
  :gdscript
  :glsl
  
  ;; Enterprise
  :java
  :kotlin
  :php
  :ruby
  :c_sharp
  
  ;; Other
  :nix
  :thrift
  ]}