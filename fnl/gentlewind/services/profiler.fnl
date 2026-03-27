;; gentlewind.services.profiler
;; Performance profiling service for gentlewind-nvim

(local profiler {})
(var start-times {})

(fn profiler.start [label]
  "Start profiling a section"
  (when gentlewind.profile
    (tset start-times label (vim.loop.hrtime))))

(fn profiler.stop [label]
  "Stop profiling a section and log the duration"
  (when gentlewind.profile
    (when (. start-times label)
      (local duration (/ (- (vim.loop.hrtime) (. start-times label)) 1000000)) ; Convert to milliseconds
      (print (.. "[PROFILE] " label ": " duration "ms"))
      (tset start-times label nil))))

(fn profiler.reset []
  "Reset all profiling data"
  (set start-times {}))

{:start profiler.start
 :stop profiler.stop
 :reset profiler.reset}
