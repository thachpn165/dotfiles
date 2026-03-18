return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = false,
    priority = 1000,
    opts = {
      flavour = "mocha",
      transparent_background = true,
      custom_highlights = function(C)
        -- Ensure fenced code blocks in markdown don't get "flattened" by raw-block highlights.
        -- Language injections (php/yaml/...) should remain readable.
        return {
          ["@markup.raw.block"] = { fg = C.text },
          ["@markup.raw.delimiter"] = { fg = C.overlay0 },
        }
      end,
      integrations = {
        cmp = true,
        gitsigns = true,
        treesitter = true,
        telescope = { enabled = true },
        which_key = true,
        nvimtree = true,
        noice = true,
        mini = { enabled = true },
        flash = true,
        mason = true,
        native_lsp = {
          enabled = true,
          underlines = {
            errors = { "undercurl" },
            hints = { "undercurl" },
            warnings = { "undercurl" },
            information = { "undercurl" },
          },
        },
      },
    },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "catppuccin",
    },
  },
}
