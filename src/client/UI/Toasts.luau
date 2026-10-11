--[[
	Toasts
	Explorer: StarterPlayer > StarterPlayerScripts > HearthscaleClient > UI > Toasts (ModuleScript)

	Turns server notification records into short messages. Relationship
	changes are described in words by default ("Saffron trusts you a little
	more"); Settings > "Show exact numbers" adds the values. Milestones get a
	banner; new chapters get a full-screen title card.
]]

local TweenService = game:GetService("TweenService")

local Theme = require(script.Parent.Theme)
local Root = require(script.Parent.Root)
local Session = require(script.Parent.Parent.Controllers.Session)
local Audio = require(script.Parent.Parent.Controllers.Audio)

local Toasts = {}

local stack
local queueCount = 0

local STAT_WORDS = {
	trust = { up = "trusts you a little more", down = "seems hurt" },
	affinity = { up = "enjoyed that", down = "didn't enjoy that" },
	romance = { up = "♥ felt her heart skip", down = "seems less sure" },
	resolve = { up = "feels a little braver", down = "feels less sure of herself" },
}

function Toasts.show(text: string, color: Color3?, duration: number?)
	queueCount += 1
	local toast = Theme.label({
		Name = "Toast",
		Text = text,
		Font = Theme.Fonts.title,
		TextColor3 = Theme.Colors.white,
		BackgroundColor3 = color or Theme.Colors.panel,
		BackgroundTransparency = 0.1,
		TextSizeBase = 17,
		TextXAlignment = Enum.TextXAlignment.Center,
		Size = UDim2.fromScale(1, 0),
		LayoutOrder = queueCount,
		Parent = stack,
	})
	Theme.corner(10).Parent = toast
	Theme.padding(8).Parent = toast
	Audio.sfx("toast")
	task.delay(duration or 3.6, function()
		if toast.Parent then
			local tween =
				TweenService:Create(toast, TweenInfo.new(0.4), { TextTransparency = 1, BackgroundTransparency = 1 })
			tween:Play()
			tween.Completed:Wait()
			toast:Destroy()
		end
	end)
end

function Toasts.banner(title: string, subtitle: string)
	local frame = Theme.new("Frame", {
		Name = "Banner",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.16),
		Size = UDim2.fromScale(0.7, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Theme.Colors.paper,
		Parent = Root.layers.toasts,
	}, {
		Theme.corner(16),
		Theme.stroke(Theme.Colors.gold, 3),
		Theme.padding(14),
		Theme.list(4),
		Theme.new("UISizeConstraint", { MaxSize = Vector2.new(560, 300) }),
	})
	Theme.label({
		Text = title,
		Font = Theme.Fonts.title,
		TextColor3 = Theme.Colors.emberDark,
		TextSizeBase = 26,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = frame,
	})
	Theme.label({
		Text = subtitle,
		TextSizeBase = 17,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = frame,
	})
	Audio.sfx("milestone")
	task.delay(5, function()
		frame:Destroy()
	end)
end

function Toasts.chapterCard(number: number, title: string)
	local reduce = Session.settings().reduceMotion
	Session.setMode("cinematic", true)
	local card = Theme.new("Frame", {
		Name = "ChapterCard",
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = reduce and 0 or 1,
		Size = UDim2.fromScale(1, 1),
		Parent = Root.layers.cinematic,
	})
	local text = Theme.label({
		Text = number >= #Session.Content.Chapters and title or `Chapter {number}\n{title}`,
		Font = Theme.Fonts.title,
		TextColor3 = Theme.Colors.gold,
		TextSizeBase = 42,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
		AutomaticSize = Enum.AutomaticSize.None,
		Size = UDim2.fromScale(1, 1),
		TextTransparency = reduce and 0 or 1,
		Parent = card,
	})
	if not reduce then
		TweenService:Create(card, TweenInfo.new(0.6), { BackgroundTransparency = 0.05 }):Play()
		TweenService:Create(text, TweenInfo.new(0.8), { TextTransparency = 0 }):Play()
	end
	task.wait(2.4)
	if not reduce then
		TweenService:Create(card, TweenInfo.new(0.8), { BackgroundTransparency = 1 }):Play()
		local fade = TweenService:Create(text, TweenInfo.new(0.8), { TextTransparency = 1 })
		fade:Play()
		fade.Completed:Wait()
	end
	card:Destroy()
	Session.setMode("cinematic", false)
end

local function itemName(id: string): string
	local item = Session.Content.Items[id]
	return item and item.name or id
end

function Toasts.handle(events)
	local showNumbers = Session.settings().showNumbers
	local stats = {} -- merge deltas per stat
	local order = {}
	for _, e in ipairs(events) do
		if e.kind == "stat" then
			local key = e.npc .. ":" .. e.stat
			if stats[key] == nil then
				stats[key] = { npc = e.npc, stat = e.stat, delta = 0 }
				table.insert(order, key)
			end
			stats[key].delta += e.delta
		elseif e.kind == "item" then
			local name = itemName(e.item)
			Toasts.show(e.delta > 0 and `+{e.delta} {name}` or `{name} handed over`, Theme.Colors.panelSoft)
			if e.delta > 0 then
				Audio.sfx("pickup")
			end
		elseif e.kind == "questStarted" then
			local q = Session.Content.Quests[e.quest]
			Toasts.show(`New quest: {q.title}`, Theme.Colors.teal)
		elseif e.kind == "questStep" then
			Toasts.show("Objective complete", Theme.Colors.good)
		elseif e.kind == "objective" then
			if e.count > 1 then
				Toasts.show(`Progress {e.progress}/{e.count}`, Theme.Colors.panelSoft, 2)
			end
		elseif e.kind == "questComplete" then
			local q = Session.Content.Quests[e.quest]
			Toasts.show(`Quest complete: {q.title}`, Theme.Colors.good)
			Audio.sfx("questComplete")
		elseif e.kind == "milestone" then
			local m = Session.Content.MilestoneById[e.milestone]
			if m then
				Toasts.banner(`Milestone: {m.title}`, m.blurb or "")
			end
		elseif e.kind == "chapter" then
			local chapter = Session.Content.Chapters[e.chapter]
			if chapter and e.chapter < #Session.Content.Chapters then
				task.spawn(Toasts.chapterCard, e.chapter, chapter.title)
			end
		elseif e.kind == "toast" then
			Toasts.show(e.text)
		end
	end
	for _, key in ipairs(order) do
		local s = stats[key]
		if s.delta ~= 0 then
			local name = Session.Content.Characters[s.npc].name
			local words = STAT_WORDS[s.stat]
			local text = words and `{name} {s.delta > 0 and words.up or words.down}` or `{name}: {s.stat}`
			if showNumbers then
				local label = Session.Content.StatLabels[s.stat] or s.stat
				text ..= string.format("  (%s %+d)", label, s.delta)
			end
			local color = s.delta > 0 and (s.stat == "romance" and Theme.Colors.rose or Theme.Colors.ember)
				or Theme.Colors.bad
			Toasts.show(text, color)
		end
	end
end

function Toasts.init()
	stack = Theme.new("Frame", {
		Name = "ToastStack",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 10),
		Size = UDim2.fromScale(0.5, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Parent = Root.layers.toasts,
	}, {
		Theme.list(6),
		Theme.new("UISizeConstraint", { MinSize = Vector2.new(260, 0), MaxSize = Vector2.new(520, 600) }),
	})
	Session.Notified:Connect(Toasts.handle)
end

return Toasts
