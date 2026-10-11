--[[
	InventoryUI
	Explorer: StarterPlayer > StarterPlayerScripts > HearthscaleClient > UI > InventoryUI (ModuleScript)

	The Bag: every item with its description. In gift mode (opened from
	Saffron's "I brought you something." choice) giftable items get a Give
	button; the server decides the reaction and returns her line.
]]

local Theme = require(script.Parent.Theme)
local Root = require(script.Parent.Root)
local Session = require(script.Parent.Parent.Controllers.Session)

local InventoryUI = {}
InventoryUI.hooks = {
	say = function(_speaker: string, _text: string, _emote: string?) end,
	toast = function(_text: string) end,
}

local panel
local giftTarget: string? = nil

local function sortedItems(state)
	local ids = {}
	for itemId, count in pairs(state.inv) do
		if count > 0 and Session.Content.Items[itemId] then
			table.insert(ids, itemId)
		end
	end
	table.sort(ids, function(a, b)
		local ia, ib = Session.Content.Items[a], Session.Content.Items[b]
		if (ia.quest == true) ~= (ib.quest == true) then
			return ia.quest == true
		end
		return ia.name < ib.name
	end)
	return ids
end

local function give(itemId: string)
	local npc = giftTarget
	if npc == nil then
		return
	end
	giftTarget = nil
	Root.close()
	local result = Session.request("gift", { npc = npc, item = itemId })
	if result.say then
		InventoryUI.hooks.say(result.say.speaker, result.say.text, result.say.emote)
	elseif not result.ok then
		InventoryUI.hooks.toast(
			result.reason == "tooFar" and "Get a little closer to give a gift." or "She can't take that right now."
		)
	end
end

local function render()
	local state = Session.state
	if state == nil then
		return
	end
	Root.clear(panel.body)
	panel.title.Text = giftTarget and ("Give a gift to " .. Session.Content.Characters[giftTarget].name) or "Bag"
	if giftTarget then
		Theme.label({
			Text = "Pick something she'd like. Hints: listen when she talks about herself, and ask Mabel.",
			TextColor3 = Theme.Colors.inkSoft,
			TextSizeBase = 16,
			LayoutOrder = 0,
			Parent = panel.body,
		})
	end
	local ids = sortedItems(state)
	if #ids == 0 then
		Theme.label({
			Text = "Your bag is empty. Explore Kettlewick!",
			TextSizeBase = 18,
			LayoutOrder = 1,
			Parent = panel.body,
		})
		return
	end
	for i, itemId in ipairs(ids) do
		local item = Session.Content.Items[itemId]
		local row = Theme.new("Frame", {
			Name = itemId,
			BackgroundColor3 = Theme.Colors.paperDark,
			Size = UDim2.new(1, -8, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			LayoutOrder = i,
			Parent = panel.body,
		}, { Theme.corner(12), Theme.padding(10) })
		local icon = Theme.label({
			Text = item.icon or "?",
			TextSizeBase = 34,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center,
			AutomaticSize = Enum.AutomaticSize.None,
			Size = UDim2.fromOffset(56, 56),
			Parent = row,
		})
		if item.image then
			icon.Text = ""
			Theme.new(
				"ImageLabel",
				{ BackgroundTransparency = 1, Image = item.image, Size = UDim2.fromScale(1, 1), Parent = icon }
			)
		end
		local text = Theme.new("Frame", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(66, 0),
			Size = UDim2.new(1, -(66 + (giftTarget and 120 or 0)), 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Parent = row,
		}, { Theme.list(2) })
		local count = state.inv[itemId] > 1 and ` ×{state.inv[itemId]}` or ""
		Theme.label({
			Text = item.name .. count .. (item.quest and "  (quest item)" or ""),
			Font = Theme.Fonts.title,
			TextColor3 = Theme.Colors.emberDark,
			TextSizeBase = 18,
			LayoutOrder = 1,
			Parent = text,
		})
		Theme.label({
			Text = item.description,
			TextColor3 = Theme.Colors.ink,
			TextSizeBase = 15,
			LayoutOrder = 2,
			Parent = text,
		})
		if giftTarget and item.giftable then
			local button = Theme.button({
				Text = "Give",
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.fromScale(1, 0.5),
				Size = UDim2.fromOffset(110, 44),
				TextSizeBase = 18,
				Parent = row,
			})
			button.Activated:Connect(function()
				give(itemId)
			end)
		end
	end
end

function InventoryUI.open()
	giftTarget = nil
	render()
	Root.open(panel)
end

function InventoryUI.openGift(npc: string)
	giftTarget = npc
	render()
	Root.open(panel, function()
		giftTarget = nil
	end)
end

function InventoryUI.toggle()
	Root.toggle(panel, InventoryUI.open)
end

function InventoryUI.init()
	panel = Root.makePanel("Bag", "Bag")
	Session.StateChanged:Connect(function()
		if Root.isOpen("Bag") then
			render()
		end
	end)
end

return InventoryUI
