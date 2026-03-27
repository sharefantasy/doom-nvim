;; gentlewind.core.modules
;; Finds and returns user's modules.lua file. Later executes enabled modules.

(local profiler (require :gentlewind.services.profiler))
(local utils (require :gentlewind.utils))
(local filename "modules.lua")

(local modules {})

;; Path cases:
;;   1. stdpath('config')/../gentlewind-nvim/modules.lua
;;   2. stdpath('config')/modules.lua
;;   3. <runtimepath>/gentlewind-nvim/modules.lua
(set modules.source (utils.find_config filename))

;; Merge core modules (can't be disabled) with user enabled modules
(local core_modules {:core ["gentlewind" "nest" "treesitter" "reloader" "updater"]})
(set modules.enabled_modules
      (vim.tbl_deep_extend "keep" core_modules (dofile modules.source)))

(local keymaps_service (require :gentlewind.services.keymaps))
(local commands_service (require :gentlewind.services.commands))
(local autocmds_service (require :gentlewind.services.autocommands))

;; Applies commands, autocommands, packages from enabled modules (modules.lua)
(fn modules.load_modules []
  (local logger (require :gentlewind.utils.logging))
  ;; Handle the Modules
  (each [section_name _ (pairs gentlewind.modules)]
    (each [module_name module (pairs (. gentlewind.modules section_name))]
      (when (not= (type module) :table)
        (print (.. "Error on module " module_name " type is " (type module) " val is " module)))
      
      (local profile_msg (.. "modules|init `" section_name "." module_name "`"))
      (profiler.start profile_msg)

      ;; Flag to continue enabling module
      (var should_enable_module true)

      ;; Check module has necessary dependencies
      (when module.requires_modules
        (each [_ dependent_module (ipairs module.requires_modules)]
          (local [dep_section_name dep_module_name] (vim.split dependent_module "%."))
          
          (when (not (. (. gentlewind.modules dep_section_name) dep_module_name))
            (set should_enable_module false)
            (logger.error
             (string.format "Gentlewind module %s.%s depends on a module that is not enabled %s.%s. Please enable the %s module."
                            section_name module_name dep_section_name dep_module_name dep_module_name)))))

      (when should_enable_module
        ;; Import dependencies with packer from module.packages
        (when module.packages
          (each [dependency_name packer_spec (pairs module.packages)]
            ;; Set packer_spec to configure function
            (when (and module.configs (. module.configs dependency_name))
              (set packer_spec.config (. module.configs dependency_name)))

            (local spec (vim.deepcopy packer_spec))

            ;; Normalize repo key to lazy-style spec
            (when (and (= (type spec) :table) (or (. spec :repo) (. spec "repo")) (not (. spec 1)))
              (local repo (or (. spec :repo) (. spec "repo")))
              (tset spec 1 repo)
              (tset spec :repo nil)
              (tset spec "repo" nil))

            ;; Set/unset frozen packer dependencies
            (when (= (type spec.commit) :table)
              ;; Commit can be a table of values, where the keys indicate
              ;; which neovim version is required.
              (set spec.commit (utils.pick_compatible_field spec.commit)))

            ;; Only pin dependencies if gentlewind.freeze_dependencies is true
            (set spec.pin (and spec.commit gentlewind.freeze_dependencies))

            ;; Save module spec to be initialised later
            (table.insert gentlewind.packages spec)))

        ;; Setup package autogroups
        (when module.autocmds
          (local autocmds (if (= (type module.autocmds) :function)
                              (module.autocmds)
                              module.autocmds))
          (each [_ autocmd_spec (ipairs autocmds)]
            (autocmds_service.set (unpack autocmd_spec))))

        (when module.cmds
          (each [_ cmd_spec (ipairs module.cmds)]
            (commands_service.set (unpack cmd_spec))))

        (when module.binds
          (keymaps_service.applyKeymaps
           (if (= (type module.binds) :function) (module.binds) module.binds))))
      (profiler.stop profile_msg))))

;; Applies user's commands, autocommands, packages from use_* helper functions
(fn modules.handle_user_config []
  ;; Handle extra user cmds
  (each [_ cmd_spec (pairs gentlewind.cmds)]
    (commands_service.set (unpack cmd_spec)))

  ;; Handle extra user autocmds
  (each [_ autocmd_spec (pairs gentlewind.autocmds)]
    (autocmds_service.set (unpack autocmd_spec)))

  ;; Handle extra user keybinds
  (each [_ keybinds (ipairs gentlewind.binds)]
    (keymaps_service.applyKeymaps keybinds)))

(fn modules.try_sync []
  (when modules._needs_sync
    (vim.api.nvim_create_autocmd "User" {:pattern "PackerComplete"
                                        :callback (fn []
                                                    (local logger (require :gentlewind.utils.logging))
                                                    (logger.error "Gentlewind-nvim has been installed.  Please restart gentlewind-nvim."))})))

(fn modules.handle_lazynvim []
  ((require :lazy).setup gentlewind.packages))

modules
