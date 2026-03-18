return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}

      local function add(lang)
        -- LazyVim may set ensure_installed to "all"; only extend when it's a list.
        if type(opts.ensure_installed) == "table" then
          if not vim.tbl_contains(opts.ensure_installed, lang) then
            table.insert(opts.ensure_installed, lang)
          end
        end
      end

      -- Markdown + inline are required for proper fenced-code highlighting/injections.
      add("markdown")
      add("markdown_inline")

      -- Common fenced languages (installing parsers enables code block highlighting).
      add("bash")
      add("lua")
      add("json")
      add("yaml")
      add("toml")
      add("vim")
      add("regex")
      add("html")
      add("css")
      add("javascript")
      add("typescript")
      add("tsx")
      -- PHP can be either mixed PHP+HTML or PHP-only; install both + phpdoc for best results.
      add("php")
      add("php_only")
      add("phpdoc")
      add("python")
      add("go")

      opts.highlight = opts.highlight or {}
      opts.highlight.enable = true
    end,
  },
}
