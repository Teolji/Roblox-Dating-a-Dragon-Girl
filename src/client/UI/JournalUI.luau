--[[
	JournalUI
	Explorer: StarterPlayer > StarterPlayerScripts > HearthscaleClient > UI > JournalUI (ModuleScript)

	Quest journal with four tabs: Quests (active objectives + completed),
	Story (chapter summaries), Saffron (what you've learned about her and her
	gift reactions) and Endings (gallery; re-read endings you've reached).
]]

local Theme = require(script.Parent.Theme)
local Root = require(script.Parent.Root)
local Session = require(script.Parent.Parent.Controllers.Session)
local Objectives = require(script.Parent.Parent.Controllers.Objectives)

local JournalUI = {}
JournalUI.hooks = { showEnding = function(_ending) end }

local panel
local currentTab = "quests"
local tabButtons = {}

local function card(parent: Instance, order: number): Frame
	return Theme.new("Frame", {
		BackgroundColor3 = Theme.Colors.paperDark,
		Size = UDim2.new(1, -8, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = order,
		Parent = parent,
	}, { Theme.corner(12), Theme.padding(12), Theme.list(4) })
end

local function heading(parent: Instance, text: string, order: number)
	Theme.label({
		Text = text,
		Font = Theme.Fonts.title,
		TextColor3 = Theme.Colors.emberDark,
		TextSizeBase = 22,
		LayoutOrder = order,
		Parent = parent,
	})
end

local function line(parent: Instance, text: string, order: number, color: Color3?, size: number?)
	return Theme.label({
		Text = text,
		TextColor3 = color or Theme.Colors.ink,
		TextSizeBase = size or 18,
		LayoutOrder = order,
		Parent = parent,
	})
end

local Tabs = {}

Tabs.quests = function(body, state)
	local active = Objectives.activeQuests(state)
	heading(body, "Active", 1)
	if #active == 0 then
		line(body, "Nothing pressing. Kettlewick is yours to wander.", 2, Theme.Colors.inkSoft)
	end
	for i, questId in ipairs(active) do
		local info = Objectives.describe(state, questId)
		local c = card(body, 1 + i)
		line(c, info.title, 1, Theme.Colors.emberDark, 20).Font = Theme.Fonts.title
		line(c, info.summary, 2, Theme.Colors.inkSoft, 16)
		line(c, "→ " .. info.stepText, 3, Theme.Colors.ink, 18)
		for j, obj in ipairs(info.objectives) do
			local progress = obj.count > 1 and `  ({obj.progress}/{obj.count})` or ""
			line(
				c,
				`{obj.done and Theme.Icons.check or "•"} {obj.text}{progress}`,
				3 + j,
				obj.done and Theme.Colors.good or Theme.Colors.ink,
				17
			)
		end
	end
	local done = {}
	for _, questId in ipairs(Session.Content.QuestOrder) do
		local q = state.quests[questId]
		if q and q.s == "complete" then
			table.insert(done, Session.Content.Quests[questId].title)
		end
	end
	heading(body, "Completed", 100)
	line(
		body,
		#done > 0 and (Theme.Icons.check .. " " .. table.concat(done, "\n" .. Theme.Icons.check .. " ")) or "None yet.",
		101,
		Theme.Colors.inkSoft,
		17
	)
end

Tabs.story = function(body, state)
	heading(body, "Your story so far", 1)
	for i = 1, math.min(state.chapter, #Session.Content.Chapters) do
		local chapter = Session.Content.Chapters[i]
		local c = card(body, 1 + i)
		local title = i >= #Session.Content.Chapters and chapter.title or `Chapter {i}: {chapter.title}`
		line(c, title, 1, Theme.Colors.emberDark, 20).Font = Theme.Fonts.title
		line(c, chapter.summary, 2, Theme.Colors.ink, 17)
	end
end

Tabs.saffron = function(body, state)
	local char = Session.Content.Characters.saffron
	heading(body, char.fullName .. " — " .. char.title, 1)
	local known = {}
	for _, note in ipairs(Session.Content.Notes) do
		if state.flags[note.flag] then
			table.insert(known, "• " .. note.text)
		end
	end
	line(
		body,
		#known > 0 and table.concat(known, "\n") or "You've only just met. Talk to her.",
		2,
		Theme.Colors.ink,
		17
	)
	heading(body, "Gifts you've given", 10)
	local gifts = {}
	local rel = state.rel.saffron
	local tierWords =
		{ loved = "Loved", liked = "Liked", neutral = "Polite thanks", disliked = "Disliked", hated = "Upset her" }
	for itemId, times in pairs(rel and rel.gifts or {}) do
		if times > 0 then
			local tier = char.gifts.tiers[itemId] or "neutral"
			table.insert(gifts, `• {Session.Content.Items[itemId].name}: {tierWords[tier]}`)
		end
	end
	table.sort(gifts)
	line(
		body,
		#gifts > 0 and table.concat(gifts, "\n")
			or "None yet. One gift per adventure — she likes a story behind them.",
		11,
		Theme.Colors.ink,
		17
	)
end

Tabs.endings = function(body, state)
	heading(body, "Endings discovered", 1)
	local order = 2
	for _, ending in ipairs(Session.Content.Endings) do
		if not ending.romance or Session.Config.RomanceEnabled then
			local c = card(body, order)
			order += 1
			if state.endingsSeen[ending.id] then
				line(c, ending.title, 1, Theme.Colors.emberDark, 20).Font = Theme.Fonts.title
				local read = Theme.button({
					Text = "Read again",
					Size = UDim2.fromOffset(160, 40),
					TextSizeBase = 16,
					LayoutOrder = 2,
					Parent = c,
				})
				read.Activated:Connect(function()
					local result = Session.request("endingText", { id = ending.id })
					if result.ok then
						Root.close()
						JournalUI.hooks.showEnding(result.ending, true)
					end
				end)
			else
				line(c, "??? — not yet discovered", 1, Theme.Colors.inkSoft, 18)
			end
		end
	end
end

local function render()
	local state = Session.state
	if state == nil or panel == nil then
		return
	end
	Root.clear(panel.body)
	for name, button in pairs(tabButtons) do
		button.BackgroundColor3 = name == currentTab and Theme.Colors.ember or Theme.Colors.panelSoft
	end
	Tabs[currentTab](panel.body, state)
end

function JournalUI.open(tab: string?)
	currentTab = tab or currentTab
	render()
	Root.open(panel)
end

function JournalUI.toggle()
	Root.toggle(panel, function()
		JournalUI.open()
	end)
end

function JournalUI.init()
	panel = Root.makePanel("Journal", "Journal")
	for i, def in ipairs({
		{ "quests", "Quests" },
		{ "story", "Story" },
		{ "saffron", "Saffron" },
		{ "endings", "Endings" },
	}) do
		local button = Theme.button({
			Name = def[1],
			Text = def[2],
			Size = UDim2.fromOffset(120, 40),
			TextSizeBase = 17,
			LayoutOrder = i,
			Parent = panel.tabs,
		})
		button.Activated:Connect(function()
			currentTab = def[1]
			render()
		end)
		tabButtons[def[1]] = button
	end
	Session.StateChanged:Connect(function()
		if Root.isOpen("Journal") then
			render()
		end
	end)
end

return JournalUI
