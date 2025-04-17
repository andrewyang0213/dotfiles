-- Initialize Configuration
local wezterm = require("wezterm")
local config = wezterm.config_builder()
local opacity = 1
local transparent_bg = "rgba(22, 24, 26, " .. opacity .. ")"

--- Get the current operating system
--- @return "windows"| "linux" | "macos"
local function get_os()
	local bin_format = package.cpath:match("%p[\\|/]?%p(%a+)")
	if bin_format == "dll" then
		return "windows"
	elseif bin_format == "so" then
		return "linux"
	end

	return "macos"
end

local host_os = get_os()

wezterm.on("gui-startup", function(cmd)
	local screen = wezterm.gui.screens().active
	local ratio = 0.75
	local width, height = screen.width * ratio, screen.height * ratio
	local tab, pane, window = wezterm.mux.spawn_window({
		position = {
			x = (screen.width - width) / 2,
			y = (screen.height - height) / 2,
			origin = "ActiveScreen",
		},
	})
	window:gui_window():set_inner_size(width, height)
end)

-- Font Configuration
local emoji_font = "Segoe UI Emoji"
config.font = wezterm.font_with_fallback({
	{
		family = "JetBrainsMono Nerd Font",
		weight = "Regular",
	},
	emoji_font,
})
config.font_size = 10

-- Color Configuration
config.colors = require("cyberdream")
config.force_reverse_video_cursor = true

-- Window Configuration
config.initial_rows = 45
config.initial_cols = 180
config.window_decorations = "RESIZE"
config.window_background_opacity = opacity
config.window_background_image = wezterm.config_dir .. "/.config/wezterm/bg-blurred.png"
config.window_close_confirmation = "NeverPrompt"
config.win32_system_backdrop = "Acrylic"
config.tab_bar_at_bottom = true

-- Performance Settings
config.max_fps = 144
config.animation_fps = 60
config.cursor_blink_rate = 250

-- Tab Bar Configuration
config.enable_tab_bar = true
config.hide_tab_bar_if_only_one_tab = true
config.show_tab_index_in_tab_bar = false
config.use_fancy_tab_bar = false
config.colors.tab_bar = {
	background = config.window_background_image and "rgba(0, 0, 0, 0)" or transparent_bg,
	new_tab = { fg_color = config.colors.background, bg_color = config.colors.brights[6] },
	new_tab_hover = { fg_color = config.colors.background, bg_color = config.colors.foreground },
}

-- Tab Formatting
wezterm.on("format-tab-title", function(tab, _, _, _, hover)
	local background = config.colors.brights[1]
	local foreground = config.colors.foreground

	if tab.is_active then
		background = config.colors.brights[7]
		foreground = config.colors.background
	elseif hover then
		background = config.colors.brights[8]
		foreground = config.colors.background
	end

	local title = tostring(tab.tab_index + 1)
	return {
		{ Foreground = { Color = background } },
		{ Text = "█" },
		{ Background = { Color = background } },
		{ Foreground = { Color = foreground } },
		{ Text = title },
		{ Foreground = { Color = background } },
		{ Text = "█" },
	}
end)

-- Pane utilities
local function move_pane(key, direction)
	return {
		key = key,
		mods = "LEADER",
		action = wezterm.action.ActivatePaneDirection(direction),
	}
end

local function resize_pane(key, direction)
	return {
		key = key,
		action = wezterm.action.AdjustPaneSize({ direction, 3 }),
	}
end

config.key_tables = {
	resize_panes = {
		resize_pane("j", "Down"),
		resize_pane("k", "Up"),
		resize_pane("h", "Left"),
		resize_pane("l", "Right"),
	},
}

-- Set leader key as CTRL A
config.leader = { key = "a", mods = "CTRL", timeout_milliseconds = 2000 }

-- Keybindings
config.keys = {
	-- Paste from clipboard
	{ key = "v", mods = "CTRL", action = wezterm.action({ PasteFrom = "Clipboard" }) },
	-- Create new tab
	{
		key = "c",
		mods = "LEADER",
		action = wezterm.action.SpawnTab("CurrentPaneDomain"),
	},
	-- Go to next/previous tab
	{
		key = "n",
		mods = "LEADER",
		action = wezterm.action.ActivateTabRelative(1),
	},
	{
		key = "p",
		mods = "LEADER",
		action = wezterm.action.ActivateTabRelative(-1),
	},
	-- Vertical split
	{
		-- |
		key = "|",
		mods = "LEADER|SHIFT",
		action = wezterm.action.SplitPane({
			direction = "Right",
			size = { Percent = 50 },
		}),
	},
	-- Horizontal split
	{
		-- -
		key = "-",
		mods = "LEADER",
		action = wezterm.action.SplitPane({
			direction = "Down",
			size = { Percent = 50 },
		}),
	},
	-- Move between different panes (vim motions)
	move_pane("j", "Down"),
	move_pane("k", "Up"),
	move_pane("h", "Left"),
	move_pane("l", "Right"),
	{
		-- When we push LEADER + R...
		key = "r",
		mods = "LEADER",
		-- Activate the `resize_panes` keytable
		action = wezterm.action.ActivateKeyTable({
			name = "resize_panes",
			-- Ensures the keytable stays active after it handles its
			-- first keypress.
			one_shot = false,
			-- Deactivate the keytable after a timeout.
			timeout_milliseconds = 1000,
		}),
	},
	-- Close current pane
	{
		-- -
		key = "d",
		mods = "LEADER",
		action = wezterm.action.CloseCurrentPane({ confirm = false }),
	},
	-- Set CTRL A (CTRL A + CTRL A)
	{
		key = "a",
		-- When we're in leader mode _and_ CTRL + A is pressed...
		mods = "LEADER|CTRL",
		-- Actually send CTRL + A key to the terminal
		action = wezterm.action.SendKey({ key = "a", mods = "CTRL" }),
	},
}

-- Default Shell Configuration
config.default_prog = { "pwsh", "-NoLogo" }

-- OS-Specific Overrides
if host_os == "linux" then
	emoji_font = "Noto Color Emoji"
	config.default_prog = { "zsh" }
	config.front_end = "WebGpu"
	config.window_background_image = os.getenv("HOME") .. "/bg-blurred.png"
	config.window_decorations = nil -- use system decorations
end

return config
