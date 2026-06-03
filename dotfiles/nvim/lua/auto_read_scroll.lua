local M = {}

function M.setup()
  -- Enable autoread for files changed on disk when buffer is unmodified
  vim.opt.autoread = true

  -- Use a dedicated augroup to avoid duplicate autocmds on reload
  local grp = vim.api.nvim_create_augroup("AutoReadScroll", { clear = true })

  -- Proactively check timestamps when returning to Neovim or idling
  vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI", "TermClose" }, {
    group = grp,
    callback = function()
      -- Triggers an autoread if the file changed and buffer has no unsaved edits
      pcall(vim.cmd.checktime)
    end,
  })

  -- Helper to snapshot buffer content for change detection
  local function snapshot_buf(buf)
    vim.b[buf].__ars_snapshot = vim.api.nvim_buf_get_lines(buf, 0, -1, true)
  end

  -- Take a snapshot after reads/writes so we can compare on external reloads
  vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost" }, {
    group = grp,
    callback = function(args)
      snapshot_buf(args.buf)
    end,
  })

  -- When a file was changed by an external process and reloaded, jump to first diff
  vim.api.nvim_create_autocmd("FileChangedShellPost", {
    group = grp,
    callback = function(args)
      local buf = args.buf
      local before = vim.b[buf].__ars_snapshot or {}
      local after = vim.api.nvim_buf_get_lines(buf, 0, -1, true)

      -- Find first differing line (1-based)
      local maxlen = math.max(#before, #after)
      local first_diff
      for i = 1, maxlen do
        if before[i] ~= after[i] then
          first_diff = i
          break
        end
      end

      -- Update snapshot to current content
      snapshot_buf(buf)

      if first_diff then
        local win = vim.fn.bufwinid(buf)
        if win ~= -1 then
          pcall(vim.api.nvim_win_set_cursor, win, { first_diff, 0 })
          pcall(vim.cmd.normal, "zz")
        end
        vim.notify("Buffer reloaded; jumped to first changed line: " .. first_diff, vim.log.levels.INFO)
      else
        vim.notify("Buffer reloaded; no line differences detected.", vim.log.levels.INFO)
      end
    end,
  })
end

return M
