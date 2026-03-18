return {
  "nvim-tree/nvim-tree.lua",
  dependencies = {
    "nvim-tree/nvim-web-devicons",
  },
  keys = {
    { "<leader>e", "<cmd>NvimTreeFindFileToggle<cr>", desc = "Toggle File Tree" },
  },
  opts = {
    filters = {
      dotfiles = false,
      custom = { ".DS_Store", "node_modules", ".git" },
    },
    view = {
      width = 35,
      side = "left",
    },
    renderer = {
      indent_markers = {
        enable = true,
      },
      icons = {
        show = {
          file = true,
          folder = true,
          folder_arrow = true,
          git = true,
        },
      },
    },
    git = {
      enable = true,
      ignore = false,
    },
    update_focused_file = {
      enable = true,
    },
  },
}
