local M = {}

local function get_vault_root()
  -- Try obsidian.nvim client first (most accurate).
  local ok, obsidian = pcall(require, "obsidian")
  if ok and obsidian and obsidian.get_client then
    local client_ok, client = pcall(obsidian.get_client)
    if client_ok and client and client.dir then
      return tostring(client.dir)
    end
  end

  -- Fallback: mirror our plugin default.
  local env_vault = vim.env.OBSIDIAN_VAULT
  local default_vault = vim.fn.expand("~/Library/Mobile Documents/iCloud~md~obsidian/Documents/Thach")
  return (env_vault and env_vault ~= "") and vim.fn.expand(env_vault) or default_vault
end

local function list_relative_dirs(root)
  local ignore = {
    [".obsidian"] = true,
    [".git"] = true,
    ["node_modules"] = true,
  }

  local out = { "" } -- allow picking vault root

  local function walk(abs_dir, rel_dir)
    for name, t in vim.fs.dir(abs_dir) do
      if t == "directory" and not ignore[name] then
        local child_rel = (rel_dir == "" and name) or (rel_dir .. "/" .. name)
        local child_abs = abs_dir .. "/" .. name
        table.insert(out, child_rel)
        walk(child_abs, child_rel)
      end
    end
  end

  walk(root, "")
  table.sort(out)
  return out
end

local function ensure_telescope()
  return pcall(require, "telescope.pickers")
end

function M.new_note_in_folder()
  local root = get_vault_root()
  if (vim.uv or vim.loop).fs_stat(root) == nil then
    vim.notify(("Obsidian vault not found: %s"):format(root), vim.log.levels.WARN)
    return
  end

  if not ensure_telescope() then
    vim.notify("telescope.nvim is required for folder picker", vim.log.levels.WARN)
    return
  end

  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")

  local dirs = list_relative_dirs(root)

  pickers
    .new({}, {
      prompt_title = "Obsidian Folder",
      finder = finders.new_table({
        results = dirs,
        entry_maker = function(rel)
          local label = (rel == "" and "/ (vault root)") or rel
          return { value = rel, display = label, ordinal = label }
        end,
      }),
      sorter = conf.generic_sorter({}),
      attach_mappings = function(prompt_bufnr)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local entry = action_state.get_selected_entry()
          local folder = (entry and entry.value) or ""

          vim.ui.input({ prompt = "Note name (optional .md): " }, function(note)
            if not note or note == "" then
              return
            end

            local path = folder ~= "" and (folder .. "/" .. note) or note
            vim.cmd("ObsidianNew " .. vim.fn.fnameescape(path))
          end)
        end)
        return true
      end,
    })
    :find()
end

return M

