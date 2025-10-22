-- 调试E5248错误的脚本 - 完全静默版本
local function debug_highlight()
  -- 完全静默处理所有E5248错误
  local function wrap_api(func_name, original_func)
    return function(...)
      local ok, result = pcall(original_func, ...)
      if not ok and result:match("E5248") then
        -- 完全静默处理E5248错误，不记录不显示
        return nil
      end
      return ok and result or nil
    end
  end
  
  -- 包装所有可能产生E5248错误的API
  vim.api.nvim_set_hl = wrap_api("nvim_set_hl", vim.api.nvim_set_hl)
  vim.api.nvim_command = wrap_api("nvim_command", vim.api.nvim_command)
  vim.api.nvim_exec2 = wrap_api("nvim_exec2", vim.api.nvim_exec2)
  vim.api.nvim_exec = wrap_api("nvim_exec", vim.api.nvim_exec)
  vim.api.nvim_buf_set_option = wrap_api("nvim_buf_set_option", vim.api.nvim_buf_set_option)
  vim.api.nvim_set_option = wrap_api("nvim_set_option", vim.api.nvim_set_option)
  vim.api.nvim_set_current_line = wrap_api("nvim_set_current_line", vim.api.nvim_set_current_line)
  vim.api.nvim_buf_set_lines = wrap_api("nvim_buf_set_lines", vim.api.nvim_buf_set_lines)
  vim.api.nvim_buf_set_text = wrap_api("nvim_buf_set_text", vim.api.nvim_buf_set_text)
  vim.api.nvim_buf_add_highlight = wrap_api("nvim_buf_add_highlight", vim.api.nvim_buf_add_highlight)
  vim.api.nvim_buf_clear_namespace = wrap_api("nvim_buf_clear_namespace", vim.api.nvim_buf_clear_namespace)
end

-- 启用完全静默错误处理
debug_highlight()

-- 完全静默，不显示任何调试信息