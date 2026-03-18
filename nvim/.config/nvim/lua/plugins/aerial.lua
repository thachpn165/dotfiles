return {
  "stevearc/aerial.nvim",
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "nvim-tree/nvim-web-devicons",
  },
  keys = {
    { "<leader>cs", "<cmd>AerialToggle<cr>", desc = "Toggle Code Outline" },
    { "[s", "<cmd>AerialPrev<cr>", desc = "Prev Symbol" },
    { "]s", "<cmd>AerialNext<cr>", desc = "Next Symbol" },
  },
  opts = {
    layout = {
      min_width = 30,
      default_direction = "right",
    },
    attach_mode = "global",
    filter_kind = false,
  },
}
