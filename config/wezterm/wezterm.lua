local wezterm = require("wezterm")
local config = {}

config.font = wezterm.font("HackGen Console NF")
config.font_size = 13
config.tab_bar_at_bottom = true
config.tab_max_width = 32
config.window_background_opacity = 1.00
config.window_decorations = "RESIZE | MACOS_FORCE_ENABLE_SHADOW"
config.macos_window_background_blur = 20
config.window_background_image = config.default_background_image
config.window_background_image_hsb = {
	brightness = 0.03,
}
config.initial_rows = 50
config.initial_cols = 160
config.audible_bell = "Disabled"

local act = require("wezterm").action
config.leader = { key = "b", mods = "CTRL", timeout_milliseconds = 1000 }
config.keys = {
	-- toggle zoom
	{
		mods = "LEADER",
		key = "z",
		action = wezterm.action.TogglePaneZoomState,
	},
	-- quick select
	{
		mods = "LEADER",
		key = "y",
		action = act.QuickSelect,
	},
	-- Select and copy entire visible contents
	{
		mods = "LEADER",
		key = "a",
		action = wezterm.action_callback(function(window, pane)
			local selected = pane:get_lines_as_text(pane:get_dimensions().scrollback_rows)
			window:copy_to_clipboard(selected, "Clipboard")
		end),
	},
	{ -- select url
		mods = "LEADER",
		key = "u",
		action = act.QuickSelectArgs({
			label = "open url",
			patterns = { "https?://\\S+" },
			action = wezterm.action_callback(function(window, pane)
				local url = window:get_selection_text_for_pane(pane)
				wezterm.open_with(url)
			end),
		}),
	},
	{ -- select word
		mods = "LEADER",
		key = "w",
		action = act.QuickSelectArgs({
			label = "select word",
			patterns = { "\\b\\w+\\b" },
			action = wezterm.action_callback(function(window, pane)
				local word = window:get_selection_text_for_pane(pane)
				window:copy_to_clipboard(word)
			end),
		}),
	},
	-- launcher
	{
		mods = "LEADER",
		key = "s",
		action = wezterm.action_callback(function(win, pane)
			local workspaces = {}
			for i, name in ipairs(wezterm.mux.get_workspace_names()) do
				table.insert(workspaces, {
					id = name,
					label = string.format("%d. %s", i, name),
				})
			end
			table.insert(workspaces, {
				id = "new_workspace",
				label = "+. create new workspace",
			})
			local current = wezterm.mux.get_active_workspace()
			win:perform_action(
				act.InputSelector({
					action = wezterm.action_callback(function(_, _, id, label)
						if not id and not label then
							wezterm.log_info("Workspace selection canceled")
						else
							if id == "new_workspace" then
								win:perform_action(
									act.PromptInputLine({
										description = "(wezterm) Set workspace title:",
										action = wezterm.action_callback(function(win, pane, line)
											if line then
												win:perform_action(act.SwitchToWorkspace({ name = line }), pane) -- workspace を移動
											end
										end),
									}),
									pane
								)
								return
							end
							win:perform_action(act.SwitchToWorkspace({ name = id }), pane)
						end
					end),
					title = string.format("Select workspace, current: %s", current),
					choices = workspaces,
					fuzzy = true,
					fuzzy_description = string.format("Select workspace: %s -> ", current),
				}),
				pane
			)
		end),
	},
	-- Rename workspace
	{
		mods = "LEADER",
		key = "r",
		action = act.PromptInputLine({
			description = "(wezterm) Set workspace title:",
			action = wezterm.action_callback(function(win, pane, line)
				if line then
					wezterm.mux.rename_workspace(wezterm.mux.get_active_workspace(), line)
				end
			end),
		}),
	},
	-- pane
	{
		key = "c",
		mods = "LEADER",
		action = wezterm.action.SpawnTab("CurrentPaneDomain"),
	},
	{
		key = "0",
		mods = "LEADER",
		action = wezterm.action.PaneSelect({ mode = "SwapWithActive" }),
	},
	{
		key = "\\",
		mods = "LEADER",
		action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }),
	},
	{
		key = "-",
		mods = "LEADER",
		action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }),
	},
	{
		key = "b",
		mods = "LEADER | CTRL",
		action = wezterm.action.PaneSelect,
	},
	{
		key = "h",
		mods = "LEADER",
		action = wezterm.action.ActivatePaneDirection("Left"),
	},
	{
		key = "j",
		mods = "LEADER",
		action = wezterm.action.ActivatePaneDirection("Down"),
	},
	{
		key = "k",
		mods = "LEADER",
		action = wezterm.action.ActivatePaneDirection("Up"),
	},
	{
		key = "l",
		mods = "LEADER",
		action = wezterm.action.ActivatePaneDirection("Right"),
	},
	{
		key = "e",
		mods = "LEADER | SHIFT",
		action = wezterm.action.SpawnCommandInNewWindow({
			args = { "nvim" },
			domain = "CurrentPaneDomain",
			set_environment_variables = {
				PATH = "/opt/homebrew/bin:" .. os.getenv("PATH"),
			},
		}),
	},
	{
		key = "o",
		mods = "LEADER",
		action = wezterm.action_callback(function(win, pane)
			win:set_config_overrides({
				window_background_opacity = 0.75,
				window_decorations = "RESIZE | MACOS_FORCE_ENABLE_SHADOW",
			})
		end),
	},
	{
		key = "o",
		mods = "LEADER | SHIFT",
		action = wezterm.action_callback(function(win, pane)
			win:set_config_overrides({
				window_background_opacity = 1.0,
				window_decorations = "RESIZE | MACOS_FORCE_ENABLE_SHADOW",
			})
		end),
	},
	{
		key = "[",
		mods = "LEADER",
		action = wezterm.action_callback(function(win, pane)
			local new_opacity = win:get_config_overrides().window_background_opacity - 0.02
			if new_opacity < 0.05 then
				new_opacity = 0.05
			end
			win:set_config_overrides({
				window_background_opacity = new_opacity,
				window_decorations = "RESIZE | MACOS_FORCE_ENABLE_SHADOW",
			})
		end),
	},
	{
		key = "]",
		mods = "LEADER",
		action = wezterm.action_callback(function(win, pane)
			local new_opacity = win:get_config_overrides().window_background_opacity + 0.02
			if new_opacity > 1.0 then
				new_opacity = 1.0
			end
			win:set_config_overrides({
				window_background_opacity = new_opacity,
				window_decorations = "RESIZE | MACOS_FORCE_ENABLE_SHADOW",
			})
		end),
	},
	{
		key = "Enter",
		mods = "SHIFT",
		action = wezterm.action.SendString("\n"),
	},
}

for i = 1, 8 do
	-- LEADER + number to move to that position
	table.insert(config.keys, {
		key = tostring(i),
		mods = "LEADER",
		action = wezterm.action.ActivateTab(i - 1),
	})
end

-- visual bell
config.visual_bell = {
	fade_in_function = "EaseIn",
	fade_in_duration_ms = 20,
	fade_out_function = "EaseOut",
	fade_out_duration_ms = 20,
}

-- mouse
config.mouse_bindings = {
	{
		event = { Down = { streak = 1, button = "Right" } },
		mods = "NONE",
		action = wezterm.action_callback(function(window, pane)
			local has_selection = window:get_selection_text_for_pane(pane) ~= ""
			if has_selection then
				window:perform_action(act.CopyTo("ClipboardAndPrimarySelection"), pane)
				window:perform_action(act.ClearSelection, pane)
			else
				window:perform_action(act({ PasteFrom = "Clipboard" }), pane)
			end
		end),
	},
}

local function split(str, ts)
	if ts == nil then
		return {}
	end

	local t = {}
	local i = 1
	for s in string.gmatch(str, "([^" .. ts .. "]+)") do
		if s ~= "" then
			t[i] = s
			i = i + 1
		end
	end

	return t
end

local function basename(str)
	local t = split(str, "/")
	if #t >= 3 then
		return t[#t - 1] .. "/" .. t[#t]
	elseif #t > 1 and t[#t - 1] ~= "file:" then
		return t[#t - 1] .. "/" .. t[#t]
	end
	if #t == 1 and t[1] == "file:" then
		return "/"
	end
	return "/" .. t[#t]
end

wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
	local pane = tab.active_pane
	if pane then
		local zoomed = ""
		if pane.is_zoomed == true then
			zoomed = utf8.char(0xf00e) .. " "
		end

		return {
			{
				Text = " " .. zoomed .. tostring(tab.tab_index + 1) .. ": " .. basename(
					tostring(pane.current_working_dir)
				) .. " ",
			},
		}
	end
end)

local canonical_solarized = require("canonical_solarized")
canonical_solarized.apply_to_config(config)
local theme = wezterm.plugin.require("https://github.com/neapsix/wezterm").main
config.colors = theme.colors()
config.window_frame = theme.window_frame()
config.use_fancy_tab_bar = false
return config
