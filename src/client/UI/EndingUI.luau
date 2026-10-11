--[[
	EndingUI
	Explorer: StarterPlayer > StarterPlayerScripts > HearthscaleClient > UI > EndingUI (ModuleScript)

	Full-screen ending card: title, then the epilogue paragraphs chosen by
	the server from this playthrough's decisions. Afterwards the player can
	keep exploring the epilogue village or start a new story.
]]

local TweenService = game:GetService("TweenService")

local Theme = require(script.Parent.Theme)
local Root = require(script.Parent.Root)
local Session = require(script.Parent.Parent.Controllers.Session)
local Audio = require(script.Parent.Parent.Controllers.Audio)

local EndingUI = {}
EndingUI.hooks = { newStory = function() end }

local TONES = {
	romance = "A romance ending",
	friendship = "A friendship ending",
	bittersweet = "A bittersweet ending",
}

function EndingUI.show(ending, readOnly: boolean?)
	Session.setMode("cinematic", true)
	local reduce = Session.settings().reduceMotion
	local backdrop = Theme.new("Frame", {
		Name = "Ending",
		BackgroundColor3 = Color3.fromRGB(20, 14, 18),
		BackgroundTransparency = reduce and 0.05 or 1,
		Size = UDim2.fromScale(1, 1),
		Parent = Root.layers.cinematic,
	})
	local card = Theme.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.9, 0.86),
		BackgroundColor3 = Theme.Colors.paper,
		Parent = backdrop,
	}, {
		Theme.corner(20),
		Theme.stroke(Theme.Colors.gold, 4),
		Theme.new("UISizeConstraint", { MaxSize = Vector2.new(760, 640) }),
	})
	local scroll = Theme.new("ScrollingFrame", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(20, 16),
		Size = UDim2.new(1, -40, 1, -96),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		ScrollBarThickness = 8,
		Parent = card,
	}, { Theme.list(12) })
	Theme.label({
		Text = TONES[ending.tone] or "An ending",
		Font = Theme.Fonts.title,
		TextColor3 = Theme.Colors.inkSoft,
		TextSizeBase = 16,
		TextXAlignment = Enum.TextXAlignment.Center,
		LayoutOrder = 1,
		Parent = scroll,
	})
	Theme.label({
		Text = ending.title,
		Font = Theme.Fonts.title,
		TextColor3 = Theme.Colors.emberDark,
		TextSizeBase = 38,
		TextXAlignment = Enum.TextXAlignment.Center,
		LayoutOrder = 2,
		Parent = scroll,
	})
	for i, paragraph in ipairs(ending.paragraphs or {}) do
		Theme.label({ Text = paragraph, TextSizeBase = 19, LayoutOrder = 2 + i, Parent = scroll })
	end

	local buttons = Theme.new("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -16),
		Size = UDim2.new(1, -40, 0, 52),
		Parent = card,
	}, { Theme.list(12, true) })
	local function close()
		backdrop:Destroy()
		Session.setMode("cinematic", false)
	end
	local keep = Theme.button({
		Text = readOnly and "Close" or "Keep exploring",
		Size = UDim2.fromScale(0.48, 1),
		LayoutOrder = 1,
		Parent = buttons,
	})
	keep.Activated:Connect(close)
	if not readOnly then
		local again = Theme.button({
			Text = "Start a new story",
			BackgroundColor3 = Theme.Colors.panelSoft,
			Size = UDim2.fromScale(0.48, 1),
			LayoutOrder = 2,
			Parent = buttons,
		})
		local armed = false
		again.Activated:Connect(function()
			if not armed then
				armed = true
				again.Text = "Tap again to confirm"
				return
			end
			local result = Session.request("newStory", { confirm = true })
			if result.ok then
				close()
				EndingUI.hooks.newStory()
			end
		end)
		Audio.sfx("success")
	end
	if not reduce then
		TweenService:Create(backdrop, TweenInfo.new(1.2), { BackgroundTransparency = 0.05 }):Play()
	end
end

return EndingUI
