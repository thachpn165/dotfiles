local wezterm = require("wezterm")
local utils = require("resurrect.utils")

local pub = {}
pub.max_nlines = 3500

local function compare_pane_by_coord(a, b)
  if a.left == b.left then
    return a.top < b.top
  end
  return a.left < b.left
end

local function is_right(root, pane)
  return root.left + root.width < pane.left
end

local function is_bottom(root, pane)
  return root.top + root.height < pane.top
end

local function pop_connected_bottom(root, panes)
  for i, pane in ipairs(panes) do
    if root.left == pane.left and root.top + root.height + 1 == pane.top then
      table.remove(panes, i)
      return pane
    end
  end
end

local function pop_connected_right(root, panes)
  for i, pane in ipairs(panes) do
    if root.top == pane.top and root.left + root.width + 1 == pane.left then
      table.remove(panes, i)
      return pane
    end
  end
end

local function insert_panes(root, panes)
  if root == nil then
    return nil
  end

  local domain = root.pane:get_domain_name()
  if not wezterm.mux.get_domain(domain):is_spawnable() then
    wezterm.log_warn("Domain " .. domain .. " is not spawnable")
    wezterm.emit("resurrect.error", "Domain " .. domain .. " is not spawnable")
  else
    root.domain = domain

    if not root.pane:get_current_working_dir() then
      root.cwd = ""
    else
      root.cwd = root.pane:get_current_working_dir().file_path
      if utils.is_windows then
        root.cwd = root.cwd:gsub("^/([a-zA-Z]):", "%1:")
      end
    end

    if domain == "local" then
      root.alt_screen_active = root.pane:is_alt_screen_active()
      if root.alt_screen_active then
        local process_info = root.pane:get_foreground_process_info()
        process_info.children = nil
        process_info.pid = nil
        process_info.ppid = nil
        root.process = process_info
      else
        local nlines = root.pane:get_dimensions().scrollback_rows
        if nlines > pub.max_nlines then
          nlines = pub.max_nlines
        end
        root.text = root.pane:get_lines_as_escapes(nlines)
      end
    end
  end

  root.pane = nil

  if #panes == 0 then
    return root
  end

  local right, bottom = {}, {}
  for _, pane in ipairs(panes) do
    -- Copy pane metadata before placing the same pane in multiple buckets.
    -- The upstream plugin mutates these tables during recursion, which can
    -- nil out `pane` in the second branch for L/T-shaped layouts.
    if is_right(root, pane) then
      table.insert(right, utils.deepcopy(pane))
    end
    if is_bottom(root, pane) then
      table.insert(bottom, utils.deepcopy(pane))
    end
  end

  if #right > 0 then
    local right_child = pop_connected_right(root, right)
    root.right = insert_panes(right_child, right)
  end

  if #bottom > 0 then
    local bottom_child = pop_connected_bottom(root, bottom)
    root.bottom = insert_panes(bottom_child, bottom)
  end

  return root
end

function pub.create_pane_tree(panes)
  table.sort(panes, compare_pane_by_coord)
  local root = table.remove(panes, 1)
  return insert_panes(root, panes)
end

function pub.map(pane_tree, f)
  if pane_tree == nil then
    return nil
  end

  pane_tree = f(pane_tree)
  if pane_tree.right then
    pub.map(pane_tree.right, f)
  end
  if pane_tree.bottom then
    pub.map(pane_tree.bottom, f)
  end

  return pane_tree
end

function pub.fold(pane_tree, acc, f)
  if pane_tree == nil then
    return acc
  end

  acc = f(acc, pane_tree)
  if pane_tree.right then
    acc = pub.fold(pane_tree.right, acc, f)
  end
  if pane_tree.bottom then
    acc = pub.fold(pane_tree.bottom, acc, f)
  end

  return acc
end

return pub
