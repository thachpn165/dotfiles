require("hs.ipc")

-- ===========================================
-- Toggle WezTerm
-- ===========================================
local function focusedScreen()
	local focused = hs.window.focusedWindow()
	if focused then
		return focused:screen()
	end
	return hs.mouse.getCurrentScreen() or hs.screen.primaryScreen()
end

local function showWezTermOnFocusedScreen()
	local app = hs.application.find("WezTerm")
	if not app then
		hs.application.launchOrFocus("WezTerm")
		hs.timer.doAfter(0.2, function()
			local launched = hs.application.find("WezTerm")
			if not launched then
				return
			end
			local win = launched:mainWindow() or launched:focusedWindow()
			local screen = focusedScreen()
			if win and screen then
				win:moveToScreen(screen, false, true)
			end
			launched:activate()
		end)
		return
	end

	if app:isFrontmost() then
		app:hide()
		return
	end

	local win = app:mainWindow() or app:focusedWindow()
	local screen = focusedScreen()
	if win and screen then
		win:moveToScreen(screen, false, true)
	end
	app:activate()
end

hs.hotkey.bind({ "cmd" }, "j", function()
	local app = hs.application.find("WezTerm")
	if app and app:isFrontmost() then
		app:hide()
		return
	end
	showWezTermOnFocusedScreen()
end)

-- ===========================================
-- Window Tiling (Ctrl+Alt + arrows/keys)
-- ===========================================
local function moveWindow(fn)
	return function()
		local win = hs.window.focusedWindow()
		if not win then
			return
		end
		local screen = win:screen():frame()
		fn(win, screen)
	end
end

-- Ctrl+Alt+Left: snap left half
hs.hotkey.bind({ "ctrl", "alt" }, "left", moveWindow(function(win, s)
	win:setFrame({ x = s.x, y = s.y, w = s.w / 2, h = s.h })
end))

-- Ctrl+Alt+Right: snap right half
hs.hotkey.bind({ "ctrl", "alt" }, "right", moveWindow(function(win, s)
	win:setFrame({ x = s.x + s.w / 2, y = s.y, w = s.w / 2, h = s.h })
end))

-- Ctrl+Alt+Up: snap top half
hs.hotkey.bind({ "ctrl", "alt" }, "up", moveWindow(function(win, s)
	win:setFrame({ x = s.x, y = s.y, w = s.w, h = s.h / 2 })
end))

-- Ctrl+Alt+Down: snap bottom half
hs.hotkey.bind({ "ctrl", "alt" }, "down", moveWindow(function(win, s)
	win:setFrame({ x = s.x, y = s.y + s.h / 2, w = s.w, h = s.h / 2 })
end))

-- Ctrl+Alt+F: maximize
hs.hotkey.bind({ "ctrl", "alt" }, "f", moveWindow(function(win, s)
	win:setFrame(s)
end))

-- Ctrl+Alt+C: center (70% size)
hs.hotkey.bind({ "ctrl", "alt" }, "c", moveWindow(function(win, s)
	local w = s.w * 0.7
	local h = s.h * 0.7
	win:setFrame({ x = s.x + (s.w - w) / 2, y = s.y + (s.h - h) / 2, w = w, h = h })
end))

-- ===========================================
-- Auto-reload config on change
-- ===========================================
hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", function(files)
	hs.reload()
end):start()
