return {
  "keaising/im-select.nvim",
  event = "VeryLazy",
  opts = {
    default_im_select = "com.apple.keylayout.ABC",
    default_command = "im-select",
    set_default_events = { "VimEnter", "InsertLeave", "CmdlineEnter", "CmdlineLeave" },
    set_previous_events = { "InsertEnter" },
  },
  config = function(_, opts)
    local ok, im_select = pcall(require, "im_select")
    if not ok then
      return
    end

    im_select.setup(opts)

    local function switch_to_default_im()
      local cmd = opts.default_command or "im-select"
      local im = opts.default_im_select or "com.apple.keylayout.ABC"
      if vim.fn.executable(cmd) == 0 then
        return
      end
      -- Use async job so we don't block typing.
      vim.fn.jobstart({ cmd, im }, { detach = true })
    end

    local function switch_to_default_im_sync()
      local cmd = opts.default_command or "im-select"
      local im = opts.default_im_select or "com.apple.keylayout.ABC"
      if vim.fn.executable(cmd) == 0 then
        return
      end
      -- For command-line entry we need immediate switch, not async.
      pcall(vim.fn.system, { cmd, im })
    end

    -- Extra guard: ensure IME is in English when entering Normal/Visual/Operator-pending.
    -- This helps avoid Vietnamese IME composing leader sequences like "oo" -> "ô".
    vim.api.nvim_create_autocmd("ModeChanged", {
      group = vim.api.nvim_create_augroup("ime_normal_mode", { clear = true }),
      callback = function()
        local new_mode = (vim.v.event and vim.v.event.new_mode) or vim.api.nvim_get_mode().mode
        local m = new_mode:sub(1, 1)
        if m == "n" or m == "v" or m == "o" or m == "c" then
          switch_to_default_im()
        end
      end,
    })

    -- Also switch on leader press, in case you were already in Normal/Visual with IME on.
    local leader = vim.g.mapleader or " "
    local ns = vim.api.nvim_create_namespace("ime_leader_guard")
    vim.on_key(function(ch)
      if ch ~= leader then
        return
      end
      local mode = vim.api.nvim_get_mode().mode:sub(1, 1)
      if mode == "n" or mode == "v" or mode == "o" then
        switch_to_default_im()
      end
    end, ns)

    -- Force IME switch before entering cmdline/search so first key isn't converted (e.g. w -> ư).
    local map_opts = { expr = true, silent = true, desc = "Enter cmdline with English IME" }
    vim.keymap.set({ "n", "x", "o" }, ":", function()
      switch_to_default_im_sync()
      return ":"
    end, map_opts)
    vim.keymap.set({ "n", "x", "o" }, "/", function()
      switch_to_default_im_sync()
      return "/"
    end, map_opts)
    vim.keymap.set({ "n", "x", "o" }, "?", function()
      switch_to_default_im_sync()
      return "?"
    end, map_opts)
  end,
}
