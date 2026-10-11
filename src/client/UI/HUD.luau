--[[
	HUD
	Explorer: StarterPlayer > StarterPlayerScripts > HearthscaleClient > UI > HUD (ModuleScript)

	Always-visible layer: current objective card (tap to open the journal),
	menu buttons sized for touch (with keyboard/gamepad hints on desktop),
	and the save-status indicator.
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Theme = require(script.Parent.Theme)
local Root = require(script.Parent.Root)
local Session = require(script.Parent.Parent.Controllers.Session)
local Objectives = require(script.Parent.Parent.Controllers.Objectives)

local HUD = {}

local objectiveCard, objectiveBody, chapterLabel, saveLabel, saveBanner
local buttons = {}

local function makeButton(icon: string, label: string, key: string, order: number, onActivate: () -> ())
	local holder = Theme.new("Frame", {
		Name = label,
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(64, 78),
		LayoutOrder = order,
	})
	local button = Theme.button({
		Name = "Button",
		Text = icon,
		Font = Theme.Fonts.title,
		TextSizeBase = 30,
		Size = UDim2.fromOffset(60, 60),
		BackgroundColor3 = Theme.Colors.panel,
		BackgroundTransparency = 0.15,
		Parent = holder,
	})
	Theme.stroke(Theme.Colors.gold, 2).Parent = button
	local caption = Theme.label({
		Name = "Caption",
		Text = label,
		Font = Theme.Fonts.title,
		TextColor3 = Theme.Colors.white,
		TextStrokeTransparency = 0.5,
		TextSizeBase = 13,
		TextXAlignment = Enum.TextXAlignment.Center,
		AutomaticSize = Enum.AutomaticSize.None,
		Size = UDim2.new(1, 0, 0, 16),
		Position = UDim2.fromOffset(0, 61),
		Parent = holder,
	})
	button.Activated:Connect(onActivate)
	buttons[label] = { button = button, caption = caption, key = key, label = label }
	return holder
end

local function refreshHints()
	local keyboard = UserInputService.KeyboardEnabled and not UserInputService.TouchEnabled
	for _, entry in pairs(buttons) do
		entry.caption.Text = keyboard and `{entry.label} [{entry.key}]` or entry.label
	end
end

function HUD.refresh()
	local state = Session.state
	if state == nil or objectiveBody == nil then
		return
	end
	local chapter = Session.Content.Chapters[state.chapter]
	chapterLabel.Text = chapter and `Chapter {state.chapter} · {chapter.title}` or ""
	if state.chapter >= #Session.Content.Chapters then
		chapterLabel.Text = "Epilogue"
	end
	Root.clear(objectiveBody)
	local info = Objectives.current(state)
	if info == nil then
		Theme.label({
			Text = state.ending and "Your story is complete. Explore, chat, or start a new story in Settings."
				or "Explore Kettlewick.",
			TextColor3 = Theme.Colors.white,
			TextSizeBase = 16,
			Parent = objectiveBody,
		})
		return
	end
	Theme.label({
		Text = info.title,
		Font = Theme.Fonts.title,
		TextColor3 = Theme.Colors.gold,
		TextSizeBase = 18,
		LayoutOrder = 1,
		Parent = objectiveBody,
	})
	Theme.label({
		Text = info.stepText,
		TextColor3 = Theme.Colors.white,
		TextSizeBase = 16,
		LayoutOrder = 2,
		Parent = objectiveBody,
	})
	for i, obj in ipairs(info.objectives) do
		local mark = obj.done and Theme.Icons.check or "•"
		local progress = obj.count > 1 and `  {obj.progress}/{obj.count}` or ""
		Theme.label({
			Text = `{mark} {obj.text}{progress}`,
			TextColor3 = obj.done and Theme.Colors.good or Color3.fromRGB(235, 225, 215),
			TextSizeBase = 15,
			LayoutOrder = 2 + i,
			Parent = objectiveBody,
		})
	end
end

local saveFadeToken = 0
function HUD.setSaveStatus(status: string, message: string?)
	saveFadeToken += 1
	local token = saveFadeToken
	saveBanner.Visible = false
	if status == "ok" then
		saveLabel.Text = Theme.Icons.check .. " Saved"
		saveLabel.TextTransparency = 0
		task.delay(2.5, function()
			if token == saveFadeToken then
				TweenService:Create(saveLabel, TweenInfo.new(0.6), { TextTransparency = 1 }):Play()
			end
		end)
	elseif status == "saving" then
		saveLabel.Text = "Saving…"
		saveLabel.TextTransparency = 0
	elseif status == "memory" then
		saveLabel.Text = "Studio test mode · not saved"
		saveLabel.TextTransparency = 0
	else -- failed / disabled
		saveLabel.Text = "⚠ Not saved"
		saveLabel.TextTransparency = 0
		saveBanner.Visible = true
		saveBanner.Text = message or "Saving is unavailable right now."
		if status == "failed" then
			task.delay(8, function()
				if token == saveFadeToken then
					saveBanner.Visible = false
				end
			end)
		end
	end
end

function HUD.init(actions: { journal: () -> (), bag: () -> (), bond: () -> (), settings: () -> () })
	local layer = Root.layers.hud

	objectiveCard = Theme.new("TextButton", {
		Name = "Objective",
		Text = "",
		AutoButtonColor = false,
		Selectable = false,
		BackgroundColor3 = Theme.Colors.panel,
		BackgroundTransparency = 0.25,
		Position = UDim2.fromOffset(12, 12),
		Size = UDim2.fromScale(0.34, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = layer,
	}, {
		Theme.corner(12),
		Theme.padding(10),
		Theme.new("UISizeConstraint", { MinSize = Vector2.new(230, 0), MaxSize = Vector2.new(420, 400) }),
		Theme.list(4),
	})
	chapterLabel = Theme.label({
		Name = "Chapter",
		Text = "",
		Font = Theme.Fonts.title,
		TextColor3 = Color3.fromRGB(230, 190, 160),
		TextSizeBase = 13,
		LayoutOrder = 0,
		Parent = objectiveCard,
	})
	objectiveBody = Theme.new("Frame", {
		Name = "Body",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 1,
		Parent = objectiveCard,
	}, { Theme.list(3) })
	objectiveCard.Activated:Connect(actions.journal)

	local column = Theme.new("Frame", {
		Name = "Buttons",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.45, 0),
		Size = UDim2.fromOffset(64, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = layer,
	}, { Theme.list(4) })
	makeButton(Theme.Icons.journal, "Journal", "J", 1, actions.journal).Parent = column
	makeButton(Theme.Icons.bag, "Bag", "B", 2, actions.bag).Parent = column
	makeButton(Theme.Icons.bond, "Bond", "K", 3, actions.bond).Parent = column
	makeButton(Theme.Icons.settings, "Settings", "P", 4, actions.settings).Parent = column

	saveLabel = Theme.label({
		Name = "SaveStatus",
		Text = "",
		Font = Theme.Fonts.title,
		TextColor3 = Theme.Colors.white,
		TextStrokeTransparency = 0.5,
		TextSizeBase = 14,
		TextXAlignment = Enum.TextXAlignment.Right,
		AutomaticSize = Enum.AutomaticSize.None,
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -12, 1, -8),
		Size = UDim2.fromOffset(260, 20),
		Parent = layer,
	})
	saveBanner = Theme.label({
		Name = "SaveBanner",
		Text = "",
		Visible = false,
		TextColor3 = Theme.Colors.white,
		BackgroundColor3 = Theme.Colors.bad,
		BackgroundTransparency = 0.1,
		TextSizeBase = 15,
		TextXAlignment = Enum.TextXAlignment.Center,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -34),
		Size = UDim2.fromScale(0.6, 0),
		Parent = layer,
	})
	Theme.corner(8).Parent = saveBanner
	Theme.padding(8).Parent = saveBanner

	refreshHints()
	UserInputService.LastInputTypeChanged:Connect(refreshHints)

	Session.StateChanged:Connect(HUD.refresh)
	Session.SaveStatus:Connect(HUD.setSaveStatus)
	Session.ModeChanged:Connect(function()
		layer.Enabled = not (Session.mode("dialogue") or Session.mode("cinematic") or Session.mode("minigame"))
	end)

	if Session.saveMode == "memory" then
		HUD.setSaveStatus("memory")
	elseif not Session.saveEnabled then
		HUD.setSaveStatus(
			"disabled",
			"We couldn't load your save, so progress from this visit won't be saved. Please rejoin later."
		)
	end
	HUD.refresh()
end

return HUD
