return {
  "ziontee113/icon-picker.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  cmd = {
    "IconPickerNormal",
    "IconPickerYank",
    "IconPickerInsert",
  },
  config = function()
    require("icon-picker").setup({
      disable_legacy_commands = true,
    })
  end,
}

