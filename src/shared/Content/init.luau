--[[
	Content
	Explorer: ReplicatedStorage > Hearthscale > Content (ModuleScript)

	Loads every data module and builds lookup indexes. All game content —
	characters, dialogue, quests, items, activities, milestones, endings and
	world anchors — is data; the systems in ../Systems interpret it.
]]

local Story = require(script.Story)
local World = require(script.World)

local Content = {
	Characters = require(script.Characters),
	Items = require(script.Items),
	Quests = require(script.Quests),
	Activities = require(script.Activities),
	Milestones = require(script.Milestones),
	Endings = require(script.Endings),
	Conversations = require(script.Dialogue),

	Chapters = Story.Chapters,
	FestivalCountdown = Story.FestivalCountdown,
	NewGame = Story.NewGame,
	StoryRules = Story.StoryRules,
	StatLabels = Story.StatLabels,
	StatDescriptions = Story.StatDescriptions,
	FlagHints = Story.FlagHints,
	Notes = Story.Notes,

	Anchors = World.Anchors,
	Collectibles = World.Collectibles,
	Locations = World.Locations,
}

Content.MilestoneById = {}
for _, m in ipairs(Content.Milestones) do
	Content.MilestoneById[m.id] = m
end

Content.ConversationsByNpc = {}
for id, conversation in pairs(Content.Conversations) do
	local list = Content.ConversationsByNpc[conversation.npc]
	if list == nil then
		list = {}
		Content.ConversationsByNpc[conversation.npc] = list
	end
	table.insert(list, id)
end
for _, list in pairs(Content.ConversationsByNpc) do
	table.sort(list)
end

-- Quests in journal order.
Content.QuestOrder = {}
for id in pairs(Content.Quests) do
	table.insert(Content.QuestOrder, id)
end
table.sort(Content.QuestOrder, function(a, b)
	return (Content.Quests[a].order or 0) < (Content.Quests[b].order or 0)
end)

return Content
