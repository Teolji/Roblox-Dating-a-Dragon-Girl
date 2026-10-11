--[[
	Root
	Explorer: StarterPlayer > StarterPlayerScripts > HearthscaleClient > UI > Root (ModuleScript)

	Creates the ScreenGuis (layered by DisplayOrder) and manages modal
	panels: only one menu panel is open at a time, it dims the world, and it
	closes with its ✕ button, a tap on the backdrop, the gamepad B button, or
	the same hotkey that opened it.
]]

local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")

local Theme = require(script.Parent.Theme)
local Session = require(script.Parent.Parent.Controllers.Session)

local Root = {}

Root.layers = {}
local openPanel = nil -- { name, frame, onClose }

local LAYERS = { hud = 1, dialogue = 5, panels = 10, minigame = 15, toasts = 20, cinematic = 30 }

function Root.init()
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	for name, order in pairs(LAYERS) do
		local gui = Theme.new("ScreenGui", {
			Name = "Hearthscale_" .. name,
			ResetOnSpawn = false,
			DisplayOrder = order,
			ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
			ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets,
			Parent = playerGui,
		})
		Root.layers[name] = gui
	end
end

-- Builds a standard modal panel: title bar, close button, scrolling body.
function Root.makePanel(name: string, title: string)
	local backdrop = Theme.new("TextButton", {
		Name = name,
		Text = "",
		AutoButtonColor = false,
		Selectable = false,
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.45,
		Size = UDim2.fromScale(1, 1),
		Visible = false,
		Parent = Root.layers.panels,
	})
	local frame = Theme.new("Frame", {
		Name = "Panel",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.92, 0.88),
		BackgroundColor3 = Theme.Colors.paper,
		Parent = backdrop,
	}, {
		Theme.corner(18),
		Theme.stroke(Theme.Colors.emberDark, 3),
		Theme.new("UISizeConstraint", { MaxSize = Vector2.new(820, 620) }),
	})
	-- Swallow clicks so they don't fall through to the backdrop.
	Theme.new("TextButton", {
		Name = "Blocker",
		Text = "",
		AutoButtonColor = false,
		Selectable = false,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 0,
		Parent = frame,
	})
	local titleLabel = Theme.label({
		Name = "Title",
		Text = title,
		Font = Theme.Fonts.title,
		TextColor3 = Theme.Colors.emberDark,
		TextSizeBase = 30,
		AutomaticSize = Enum.AutomaticSize.None,
		Size = UDim2.new(1, -90, 0, 44),
		Position = UDim2.fromOffset(20, 12),
		TextYAlignment = Enum.TextYAlignment.Center,
		TextWrapped = false,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = frame,
	})
	local close = Theme.button({
		Name = "Close",
		Text = Theme.Icons.close,
		Size = UDim2.fromOffset(48, 48),
		Position = UDim2.new(1, -60, 0, 10),
		BackgroundColor3 = Theme.Colors.emberDark,
		Parent = frame,
	})
	local tabs = Theme.new("Frame", {
		Name = "Tabs",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(16, 62),
		Size = UDim2.new(1, -32, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = frame,
	}, { Theme.list(8, true) })
	local body = Theme.new("ScrollingFrame", {
		Name = "Body",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(16, 70),
		Size = UDim2.new(1, -32, 1, -86),
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 8,
		ScrollBarImageColor3 = Theme.Colors.emberDark,
		Parent = frame,
	}, { Theme.list(10), Theme.padding(4) })

	local panel = { name = name, backdrop = backdrop, frame = frame, body = body, tabs = tabs, title = titleLabel }

	-- Make room for a tab row when tabs exist.
	tabs:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		local h = tabs.AbsoluteSize.Y
		body.Position = UDim2.fromOffset(16, 70 + (h > 0 and h + 8 or 0))
		body.Size = UDim2.new(1, -32, 1, -(86 + (h > 0 and h + 8 or 0)))
	end)

	close.Activated:Connect(function()
		Root.close()
	end)
	backdrop.Activated:Connect(function()
		Root.close()
	end)
	return panel
end

function Root.clear(container: Instance)
	for _, child in ipairs(container:GetChildren()) do
		if not child:IsA("UIListLayout") and not child:IsA("UIPadding") and not child:IsA("UIGridLayout") then
			child:Destroy()
		end
	end
end

function Root.isOpen(name: string?): boolean
	if name then
		return openPanel ~= nil and openPanel.name == name
	end
	return openPanel ~= nil
end

function Root.open(panel, onClose: (() -> ())?)
	if openPanel and openPanel ~= panel then
		Root.close()
	end
	openPanel = panel
	panel.onClose = onClose
	panel.backdrop.Visible = true
	Session.setMode("menu", true)
	local close = panel.frame:FindFirstChild("Close")
	if close and (GuiService:IsTenFootInterface() or game:GetService("UserInputService").GamepadEnabled) then
		GuiService.SelectedObject = close
	end
end

function Root.close()
	local panel = openPanel
	if panel == nil then
		return
	end
	openPanel = nil
	panel.backdrop.Visible = false
	Session.setMode("menu", false)
	GuiService.SelectedObject = nil
	if panel.onClose then
		panel.onClose()
	end
end

-- Toggle helper for hotkeys/HUD buttons.
function Root.toggle(panel, openFn: () -> ())
	if openPanel == panel then
		Root.close()
	elseif Session.mode("dialogue") or Session.mode("minigame") or Session.mode("cinematic") then
		return
	else
		openFn()
	end
end

return Root
