--[[
	SettingsUI
	Explorer: StarterPlayer > StarterPlayerScripts > HearthscaleClient > UI > SettingsUI (ModuleScript)

	Text speed, music/SFX volume, UI scale, accessibility toggles and
	"Start a new story" (keeps your endings gallery). Steppers and toggles
	instead of sliders so everything works with touch, mouse and gamepad.
	Changes are validated and saved by the server.
]]

local Theme = require(script.Parent.Theme)
local Root = require(script.Parent.Root)
local Session = require(script.Parent.Parent.Controllers.Session)

local SettingsUI = {}
SettingsUI.hooks = {
	applied = function(_settings) end,
	newStory = function() end,
}

local panel
local pending = nil
local sendToken = 0

local SPEED_ORDER = { "slow", "normal", "fast", "instant" }
local SPEED_NAMES = { slow = "Slow", normal = "Normal", fast = "Fast", instant = "Instant" }

local render -- forward

local function push(settings)
	pending = settings
	SettingsUI.hooks.applied(settings)
	sendToken += 1
	local token = sendToken
	task.delay(0.4, function()
		if token == sendToken and pending then
			Session.request("settings", { settings = pending })
			pending = nil
		end
	end)
end

local function current()
	local s = table.clone(Session.settings())
	if pending then
		for k, v in pairs(pending) do
			s[k] = v
		end
	end
	return s
end

local function row(order: number, title: string, description: string?)
	local frame = Theme.new("Frame", {
		BackgroundColor3 = Theme.Colors.paperDark,
		Size = UDim2.new(1, -8, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = order,
		Parent = panel.body,
	}, { Theme.corner(12), Theme.padding(10) })
	local text = Theme.new("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -200, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = frame,
	}, { Theme.list(2) })
	Theme.label({ Text = title, Font = Theme.Fonts.title, TextSizeBase = 18, LayoutOrder = 1, Parent = text })
	if description then
		Theme.label({
			Text = description,
			TextColor3 = Theme.Colors.inkSoft,
			TextSizeBase = 14,
			LayoutOrder = 2,
			Parent = text,
		})
	end
	local controls = Theme.new("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.fromScale(1, 0.5),
		Size = UDim2.fromOffset(190, 44),
		Parent = frame,
	})
	return controls
end

local function stepper(controls: Frame, valueText: string, onMinus: () -> (), onPlus: () -> ())
	local minus = Theme.button({ Text = "−", Size = UDim2.fromOffset(44, 44), Parent = controls })
	Theme.label({
		Text = valueText,
		Font = Theme.Fonts.title,
		TextSizeBase = 17,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
		AutomaticSize = Enum.AutomaticSize.None,
		Position = UDim2.fromOffset(48, 0),
		Size = UDim2.fromOffset(94, 44),
		Parent = controls,
	})
	local plus = Theme.button({
		Text = "+",
		Size = UDim2.fromOffset(44, 44),
		Position = UDim2.fromOffset(146, 0),
		Parent = controls,
	})
	minus.Activated:Connect(onMinus)
	plus.Activated:Connect(onPlus)
end

local function toggle(controls: Frame, on: boolean, onChange: (boolean) -> ())
	local button = Theme.button({
		Text = on and "On" or "Off",
		BackgroundColor3 = on and Theme.Colors.good or Theme.Colors.panelSoft,
		Size = UDim2.fromOffset(110, 44),
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Parent = controls,
	})
	button.Activated:Connect(function()
		onChange(not on)
	end)
end

local function set(key: string, value: any)
	local s = current()
	s[key] = value
	push(s)
	render()
end

render = function()
	Root.clear(panel.body)
	local s = current()

	local speedIndex = table.find(SPEED_ORDER, s.textSpeed) or 2
	stepper(row(1, "Text speed", "How fast dialogue appears."), SPEED_NAMES[SPEED_ORDER[speedIndex]], function()
		set("textSpeed", SPEED_ORDER[math.max(1, speedIndex - 1)])
	end, function()
		set("textSpeed", SPEED_ORDER[math.min(#SPEED_ORDER, speedIndex + 1)])
	end)

	for i, key in ipairs({ "music", "sfx" }) do
		local value = s[key] or 0
		stepper(
			row(1 + i, key == "music" and "Music volume" or "Sound effects"),
			`{math.floor(value * 100 + 0.5)}%`,
			function()
				set(key, math.max(0, math.floor((value - 0.1) * 10 + 0.5) / 10))
			end,
			function()
				set(key, math.min(1, math.floor((value + 0.1) * 10 + 0.5) / 10))
			end
		)
	end

	local scale = s.uiScale or 1
	stepper(
		row(4, "Interface size", "Make menus and text larger or smaller."),
		`{math.floor(scale * 100 + 0.5)}%`,
		function()
			set("uiScale", math.max(0.8, math.floor((scale - 0.1) * 10 + 0.5) / 10))
		end,
		function()
			set("uiScale", math.min(1.3, math.floor((scale + 0.1) * 10 + 0.5) / 10))
		end
	)

	toggle(
		row(5, "Objective marker", "Show a floating marker toward your current objective."),
		s.showWaypoint ~= false,
		function(v)
			set("showWaypoint", v)
		end
	)
	toggle(
		row(6, "Cinematic dialogue camera", "Frame characters during conversations."),
		s.cinematicCamera ~= false,
		function(v)
			set("cinematicCamera", v)
		end
	)
	toggle(
		row(7, "Reduce motion", "No camera moves, typewriter or bobbing effects."),
		s.reduceMotion == true,
		function(v)
			set("reduceMotion", v)
		end
	)
	toggle(
		row(8, "Show exact numbers", "Show relationship values in notifications and the Bond screen."),
		s.showNumbers == true,
		function(v)
			set("showNumbers", v)
		end
	)

	local state = Session.state
	local seen, total = 0, 0
	for _, ending in ipairs(Session.Content.Endings) do
		if not ending.romance or Session.Config.RomanceEnabled then
			total += 1
			if state and state.endingsSeen[ending.id] then
				seen += 1
			end
		end
	end
	local controls = row(
		20,
		"Start a new story",
		`Begin again from the crash landing. Endings found so far ({seen}/{total}) and settings are kept.`
	)
	local restart = Theme.button({
		Text = "New story",
		BackgroundColor3 = Theme.Colors.bad,
		Size = UDim2.fromOffset(150, 44),
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Parent = controls,
	})
	local armed = false
	restart.Activated:Connect(function()
		if not armed then
			armed = true
			restart.Text = "Tap to confirm"
			task.delay(4, function()
				if restart.Parent then
					armed = false
					restart.Text = "New story"
				end
			end)
			return
		end
		local result = Session.request("newStory", { confirm = true })
		if result.ok then
			Root.close()
			SettingsUI.hooks.newStory()
		end
	end)

	Theme.label({
		Text = `{Session.Config.GameTitle} · {Session.Config.RomanceEnabled and "Romance edition (18+)" or "Friendship edition"} · Your story and relationships are yours alone — other players in this server can't see or change them.`,
		TextColor3 = Theme.Colors.inkSoft,
		TextSizeBase = 13,
		LayoutOrder = 30,
		Parent = panel.body,
	})
end

function SettingsUI.open()
	render()
	Root.open(panel)
end

function SettingsUI.toggle()
	Root.toggle(panel, SettingsUI.open)
end

function SettingsUI.init()
	panel = Root.makePanel("Settings", "Settings")
end

return SettingsUI
