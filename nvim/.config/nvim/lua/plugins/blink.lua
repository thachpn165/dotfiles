return {
  {
    "saghen/blink.cmp",
    optional = true,
    opts = function(_, opts)
      opts.cmdline = opts.cmdline or {}
      opts.cmdline.keymap = vim.tbl_deep_extend("force", opts.cmdline.keymap or {}, {
        -- With cmdline menu auto_show, Tab should accept the shown suggestion directly.
        ["<Tab>"] = { "show", "accept" },
      })
    end,
  },
}
