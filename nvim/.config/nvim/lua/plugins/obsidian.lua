local function resolve_vault_path()
  local env_vault = vim.env.OBSIDIAN_VAULT
  local default_vault = vim.fn.expand("~/Library/Mobile Documents/iCloud~md~obsidian/Documents/Thach")
  return (env_vault and env_vault ~= "") and vim.fn.expand(env_vault) or default_vault
end

local function vault_exists()
  return (vim.uv or vim.loop).fs_stat(resolve_vault_path()) ~= nil
end

return {
  "epwalsh/obsidian.nvim",
  version = "*",
  enabled = function()
    return vault_exists()
  end,
  ft = { "markdown" },
  cmd = {
    "ObsidianOpen",
    "ObsidianNew",
    "ObsidianToday",
    "ObsidianYesterday",
    "ObsidianSearch",
    "ObsidianQuickSwitch",
    "ObsidianBacklinks",
    "ObsidianLinks",
    "ObsidianRename",
    "ObsidianPasteImg",
  },
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope.nvim",
    "hrsh7th/nvim-cmp",
  },
  keys = {
    { "<leader>oo", "<cmd>ObsidianOpen<cr>", desc = "Obsidian: Open in app" },
    { "<leader>on", "<cmd>ObsidianNew<cr>", desc = "Obsidian: New note" },
    {
      "<leader>oN",
      function()
        require("config.obsidian_folders").new_note_in_folder()
      end,
      desc = "Obsidian: New note in folder",
    },
    { "<leader>ot", "<cmd>ObsidianToday<cr>", desc = "Obsidian: Today" },
    { "<leader>oy", "<cmd>ObsidianYesterday<cr>", desc = "Obsidian: Yesterday" },
    { "<leader>os", "<cmd>ObsidianSearch<cr>", desc = "Obsidian: Search" },
    { "<leader>oq", "<cmd>ObsidianQuickSwitch<cr>", desc = "Obsidian: Quick switch" },
    { "<leader>ob", "<cmd>ObsidianBacklinks<cr>", desc = "Obsidian: Backlinks" },
    { "<leader>ol", "<cmd>ObsidianLinks<cr>", desc = "Obsidian: Links" },
    { "<leader>or", "<cmd>ObsidianRename<cr>", desc = "Obsidian: Rename note" },
    { "<leader>op", "<cmd>ObsidianPasteImg<cr>", desc = "Obsidian: Paste image" },
  },
  opts = function()
    local vault_path = resolve_vault_path()

    -- LazyVim can use blink.cmp instead of nvim-cmp; only enable obsidian.nvim's cmp integration
    -- when the "cmp" module is actually available.
    local has_cmp = pcall(require, "cmp")

    return {
      workspaces = {
        { name = "vault", path = vault_path },
      },
      picker = {
        name = "telescope.nvim",
      },
      completion = {
        nvim_cmp = has_cmp,
        min_chars = 2,
      },
      -- Keep note IDs readable and stable.
      note_id_func = function(title)
        if title ~= nil and title ~= "" then
          return title:gsub("%s+", "-"):gsub("[^%w%-_]", ""):lower()
        end
        return tostring(os.time())
      end,
      -- Use markdown links; works well in git.
      preferred_link_style = "markdown",
      follow_url_func = function(url)
        -- Use system opener if available; fallback to netrw.
        if vim.fn.has("mac") == 1 then
          vim.fn.jobstart({ "open", url }, { detach = true })
        elseif vim.fn.executable("xdg-open") == 1 then
          vim.fn.jobstart({ "xdg-open", url }, { detach = true })
        else
          vim.cmd("netrw#BrowseX(" .. vim.fn.string(url) .. ", 0)")
        end
      end,
      ui = {
        enable = true,
      },
    }
  end,
}
