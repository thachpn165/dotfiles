return {
  "lukas-reineke/indent-blankline.nvim",
  main = "ibl",
  event = "BufReadPost",
  opts = {
    indent = {
      char = "│",
    },
    scope = {
      enabled = true,
      show_start = true,
      show_end = false,
    },
    exclude = {
      filetypes = { "help", "dashboard", "NvimTree", "lazy", "mason", "notify" },
    },
  },
}
