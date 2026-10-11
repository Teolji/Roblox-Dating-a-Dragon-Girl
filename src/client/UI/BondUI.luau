--[[
	BondUI
	Explorer: StarterPlayer > StarterPlayerScripts > HearthscaleClient > UI > BondUI (ModuleScript)

	Relationship overview: current milestone, what each stat means, the
	milestone ladder with a checklist of what the next stage needs, and
	whether Saffron would welcome a gift right now.
]]

local Theme = require(script.Parent.Theme)
local Root = require(script.Parent.Root)
local Session = require(script.Parent.Parent.Controllers.Session)

local Conditions = require(Session.Shared.Systems.Conditions)
local Gifts = require(Session.Shared.Systems.Gifts)

local BondUI = {}

local panel

local STAT_COLORS = {
	trust = Theme.Colors.teal,
	affinity = Theme.Colors.ember,
	romance = Theme.Colors.rose,
	resolve = Theme.Colors.gold,
}

local function bar(parent: Instance, stat: string, value: number, max: number, order: number)
	local holder = Theme.new("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -8, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = order,
		Parent = parent,
	}, { Theme.list(4) })
	local labelText = Session.Content.StatLabels[stat]
	if Session.settings().showNumbers then
		labelText ..= `  {math.floor(value)}/{max}`
	end
	Theme.label({ Text = labelText, Font = Theme.Fonts.title, TextSizeBase = 18, LayoutOrder = 1, Parent = holder })
	local track = Theme.new("Frame", {
		BackgroundColor3 = Theme.Colors.paperDark,
		Size = UDim2.new(1, 0, 0, 16),
		LayoutOrder = 2,
		Parent = holder,
	}, { Theme.corner(8) })
	Theme.new("Frame", {
		BackgroundColor3 = STAT_COLORS[stat],
		Size = UDim2.fromScale(math.clamp(value / max, 0, 1), 1),
		Parent = track,
	}, { Theme.corner(8) })
	Theme.label({
		Text = Session.Content.StatDescriptions[stat],
		TextColor3 = Theme.Colors.inkSoft,
		TextSizeBase = 14,
		LayoutOrder = 3,
		Parent = holder,
	})
end

local function render()
	local state = Session.state
	if state == nil then
		return
	end
	local body = panel.body
	Root.clear(body)
	local rel = state.rel.saffron
	local char = Session.Content.Characters.saffron
	local milestone = Session.Content.MilestoneById[rel.milestone]

	local header = Theme.new("Frame", {
		BackgroundColor3 = Theme.Colors.paperDark,
		Size = UDim2.new(1, -8, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 1,
		Parent = body,
	}, { Theme.corner(14), Theme.padding(12) })
	local portrait = Theme.new("Frame", {
		BackgroundColor3 = Theme.hex(char.color),
		Size = UDim2.fromOffset(72, 72),
		Parent = header,
	}, { Theme.corner(36) })
	Theme.label({
		Text = "S",
		Font = Theme.Fonts.title,
		TextColor3 = Theme.Colors.white,
		TextSizeBase = 36,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
		AutomaticSize = Enum.AutomaticSize.None,
		Size = UDim2.fromScale(1, 1),
		Parent = portrait,
	})
	local info = Theme.new("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(86, 0),
		Size = UDim2.new(1, -86, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = header,
	}, { Theme.list(2) })
	Theme.label({
		Text = char.fullName,
		Font = Theme.Fonts.title,
		TextColor3 = Theme.Colors.emberDark,
		TextSizeBase = 22,
		LayoutOrder = 1,
		Parent = info,
	})
	Theme.label({
		Text = `You are: {milestone.title}`,
		Font = Theme.Fonts.title,
		TextSizeBase = 18,
		LayoutOrder = 2,
		Parent = info,
	})
	Theme.label({
		Text = milestone.blurb or "",
		TextColor3 = Theme.Colors.inkSoft,
		TextSizeBase = 15,
		LayoutOrder = 3,
		Parent = info,
	})
	Theme.label({ Text = `You call her: {milestone.callHer}`, TextSizeBase = 15, LayoutOrder = 4, Parent = info })

	local canGive, reason = Gifts.canGive(state, "saffron", Session.ctx)
	local giftText = canGive and "She'd welcome a gift right now."
		or (reason == "tooSoon" and "Gifts unlock once you're her Assistant Keeper.")
		or "Share another adventure before your next gift."
	Theme.label({ Text = "🎁 " .. giftText, TextSizeBase = 16, LayoutOrder = 2, Parent = body })

	local order = 3
	for _, stat in ipairs({ "trust", "affinity", "romance", "resolve" }) do
		if stat ~= "romance" or Session.Config.RomanceEnabled then
			local max = stat == "resolve" and Session.Config.ResolveMax or Session.Config.StatMax
			bar(body, stat, rel[stat] or 0, max, order)
			order += 1
		end
	end

	Theme.label({
		Text = "Milestones",
		Font = Theme.Fonts.title,
		TextColor3 = Theme.Colors.emberDark,
		TextSizeBase = 22,
		LayoutOrder = 20,
		Parent = body,
	})
	local rank = Conditions.milestoneRank(Session.ctx, rel.milestone)
	order = 21
	for _, m in ipairs(Session.Content.Milestones) do
		if not m.romance or Session.Config.RomanceEnabled then
			local reached = m.rank < rank or m.id == rel.milestone
			local isNext = m.rank == rank + 1
			local c = Theme.new("Frame", {
				BackgroundColor3 = reached and Color3.fromRGB(228, 238, 214) or Theme.Colors.paperDark,
				Size = UDim2.new(1, -8, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				LayoutOrder = order,
				Parent = body,
			}, { Theme.corner(10), Theme.padding(10), Theme.list(3) })
			order += 1
			local prefix = reached and (Theme.Icons.check .. " ") or (isNext and "→ " or "· ")
			Theme.label({
				Text = prefix .. m.title .. (m.romance and "  " .. Theme.Icons.heart or ""),
				Font = Theme.Fonts.title,
				TextColor3 = reached and Theme.Colors.good or Theme.Colors.ink,
				TextSizeBase = 18,
				LayoutOrder = 1,
				Parent = c,
			})
			if isNext and m.requires then
				for i, item in ipairs(Conditions.describe(m.requires, state, Session.ctx)) do
					Theme.label({
						Text = `{item.met and Theme.Icons.check or Theme.Icons.cross} {item.text}`,
						TextColor3 = item.met and Theme.Colors.good or Theme.Colors.inkSoft,
						TextSizeBase = 15,
						LayoutOrder = 1 + i,
						Parent = c,
					})
				end
				if m.unlocks then
					Theme.label({
						Text = "Unlocks: " .. m.unlocks,
						TextColor3 = Theme.Colors.inkSoft,
						TextSizeBase = 14,
						LayoutOrder = 50,
						Parent = c,
					})
				end
			end
		end
	end
	Theme.label({
		Text = "Saffron has her own boundaries and makes her own choices. Romance only grows once she's open to it — and she may choose friendship.",
		TextColor3 = Theme.Colors.inkSoft,
		TextSizeBase = 14,
		LayoutOrder = 100,
		Visible = Session.Config.RomanceEnabled,
		Parent = body,
	})
end

function BondUI.open()
	render()
	Root.open(panel)
end

function BondUI.toggle()
	Root.toggle(panel, BondUI.open)
end

function BondUI.init()
	panel = Root.makePanel("Bond", "Bond with Saffron")
	Session.StateChanged:Connect(function()
		if Root.isOpen("Bond") then
			render()
		end
	end)
end

return BondUI
