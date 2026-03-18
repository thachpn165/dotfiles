return {
  "nvim-telescope/telescope.nvim",
  opts = {
    defaults = {
      -- Cấu hình thư mục loại trừ
      file_ignore_patterns = { "node_modules", "dist", ".git" },
    },
    pickers = {
      find_files = {
        -- Tìm kiếm cả file ẩn (bắt đầu bằng dấu .)
        hidden = true,
        -- Chỉ tìm trong thư mục hiện tại, không tìm trong các thư mục cha
        cwd_only = true,
      },
    },
  },
  keys = {
    -- Tùy chỉnh keymapping để tìm files chỉ trong thư mục hiện tại
    {
      "<leader>ff",
      function()
        require("telescope.builtin").find_files({ cwd = vim.fn.expand("%:p:h") })
      end,
      desc = "Find Files (Current Dir)",
    },
    -- Thêm keymapping mới để tìm trong thư mục dự án
    {
      "<leader>fp",
      function()
        require("telescope.builtin").find_files()
      end,
      desc = "Find Files (Project)",
    },
  },
}
