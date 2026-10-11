--[[
	GameService
	Explorer: ServerScriptService > HearthscaleServer > Services > GameService (ModuleScript)

	The single authority for player actions. Every client request arrives on
	Remotes.Request, is rate-limited, validated (state, proximity, ownership,
	argument types) and applied with the shared Systems. Clients never send
	stat changes, rewards or quest progress — only intents ("talk to Saffron",
	"pick choice 2", "here are my minigame inputs").

	Per-player runtime (never saved): the active dialogue session (a private
	draft of the state), the active minigame session and a request bucket.
	While a dialogue is open, other state-changing requests are refused so the
	dialogue's draft can be committed safely.
]]

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local GameService = {}

local ctx, DataService, remotes
local Rules, Dialogue, Gifts, Activities, World, SaveSchema, WorldAnchors

local runtime: { [Player]: any } = {}
local random = Random.new()

local CLIENT_FLAGS = { intro_seen = true } -- cosmetic flags a client may set

-- Helpers ------------------------------------------------------------------
local function rt(player: Player)
	local r = runtime[player]
	if r == nil then
		r = { bucket = ctx.config.RequestBurst, bucketAt = os.clock() }
		runtime[player] = r
	end
	return r
end

local function allow(player: Player): boolean
	local r = rt(player)
	local now = os.clock()
	r.bucket = math.min(ctx.config.RequestBurst, r.bucket + (now - r.bucketAt) * ctx.config.RequestRefillPerSecond)
	r.bucketAt = now
	if r.bucket < 1 then
		return false
	end
	r.bucket -= 1
	return true
end

local function rootPosition(player: Player): Vector3?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return root and root.Position
end

local function near(player: Player, anchorName: string?, distance: number): boolean
	local position = rootPosition(player)
	local target = WorldAnchors.position(anchorName)
	if position == nil or target == nil then
		return false
	end
	return (position - target).Magnitude <= distance
end

local function endingPayload(state, endingId: string)
	local ending = Rules.endingById(ctx, endingId)
	return {
		id = endingId,
		title = ending.title,
		tone = ending.tone,
		paragraphs = Rules.endingText(state, ctx, endingId),
	}
end

-- Sends the state + notifications and returns follow-up actions.
local function commit(player: Player, profile, events)
	DataService.markDirty(profile)
	remotes.StateSync:FireClient(player, profile.state)
	local notes, followUps = {}, {}
	for _, e in ipairs(events) do
		if e.kind == "action" then
			table.insert(followUps, e)
		elseif e.kind == "ending" then
			rt(player).pendingEnding = endingPayload(profile.state, e.ending)
		else
			table.insert(notes, e)
		end
	end
	if #notes > 0 then
		remotes.Notify:FireClient(player, notes)
	end
	return followUps
end

local function flushEnding(player: Player)
	local r = rt(player)
	if r.pendingEnding then
		remotes.EndingShown:FireClient(player, r.pendingEnding)
		r.pendingEnding = nil
	end
end

local function startActivity(player: Player, profile, actId: string, fromWorld: boolean)
	local ok, why = Activities.canStart(profile.state, actId, ctx)
	if not ok then
		return nil, why
	end
	local def = ctx.content.Activities[actId]
	if fromWorld and (def.anchor == nil or not near(player, def.anchor, ctx.config.ActivityDistance)) then
		return nil, "tooFar"
	end
	local session = Activities.start(profile.state, actId, ctx, random:NextInteger(1, 2147483646))
	session.id = HttpService:GenerateGUID(false)
	session.startedAt = os.clock()
	rt(player).activity = session
	return {
		id = session.id,
		activity = actId,
		kind = session.kind,
		name = def.name,
		description = def.description,
		partner = def.partner,
		public = session.public,
	}
end

local function runFollowUps(player: Player, profile, followUps, response)
	for _, action in ipairs(followUps) do
		if action.action == "startActivity" then
			local payload = startActivity(player, profile, action.activity, false)
			if payload then
				response.activity = payload
			end
		elseif action.action == "openGift" then
			response.openGift = action.npc
		end
	end
end

local function finishDialogue(player: Player, profile, r)
	local session = r.dialogue
	profile.state = session.state -- commit the conversation's draft
	r.dialogue = nil
	local events = r.dialogueEvents
	r.dialogueEvents = nil
	local response = { ok = true, node = { ended = true } }
	runFollowUps(player, profile, commit(player, profile, events), response)
	flushEnding(player)
	return response
end

local function dialogueResponse(player: Player, profile, r)
	if r.dialogue.ended then
		return finishDialogue(player, profile, r)
	end
	return { ok = true, node = Dialogue.view(r.dialogue, ctx, player.DisplayName) }
end

local function isString(v, maxLen: number?): boolean
	return type(v) == "string" and #v <= (maxLen or 64)
end

-- Request handlers -----------------------------------------------------------
local Handlers = {}

Handlers.ready = function(_player, profile)
	return {
		ok = true,
		state = profile.state,
		romanceEnabled = ctx.config.RomanceEnabled,
		saveMode = DataService.mode,
		saveEnabled = profile.saveEnabled,
	}
end

Handlers.talk = function(player, profile, args, r)
	if not isString(args.npc) or ctx.content.Characters[args.npc] == nil then
		return { ok = false, reason = "badNpc" }
	end
	if r.activity then
		return { ok = false, reason = "busy" }
	end
	r.dialogue = nil -- a stale, unfinished dialogue is discarded
	local station = World.station(profile.state, args.npc, ctx)
	if station == nil then
		return { ok = false, reason = "absent" }
	end
	if not near(player, station, ctx.config.TalkDistance) then
		return { ok = false, reason = "tooFar" }
	end
	local convId = Dialogue.pick(profile.state, args.npc, ctx)
	if convId == nil then
		return { ok = false, reason = "nothingToSay" }
	end
	r.dialogueEvents = {}
	r.dialogue = Dialogue.begin(profile.state, convId, ctx, r.dialogueEvents)
	r.dialogueNpc = args.npc
	return dialogueResponse(player, profile, r)
end

Handlers.advance = function(player, profile, _args, r)
	if r.dialogue == nil then
		return { ok = false, reason = "noDialogue" }
	end
	local ok, why = Dialogue.advance(r.dialogue, ctx, r.dialogueEvents)
	if not ok then
		return { ok = false, reason = why, node = Dialogue.view(r.dialogue, ctx, player.DisplayName) }
	end
	return dialogueResponse(player, profile, r)
end

Handlers.choose = function(player, profile, args, r)
	if r.dialogue == nil then
		return { ok = false, reason = "noDialogue" }
	end
	local ok, why = Dialogue.choose(r.dialogue, args.index, ctx, r.dialogueEvents)
	if not ok then
		return { ok = false, reason = why, node = Dialogue.view(r.dialogue, ctx, player.DisplayName) }
	end
	return dialogueResponse(player, profile, r)
end

-- Closing the dialogue box: on the final line this counts as finishing the
-- conversation; anywhere else the draft is discarded.
Handlers.leaveDialogue = function(player, profile, _args, r)
	local session = r.dialogue
	if session == nil then
		return { ok = true }
	end
	if not session.ended and session.choices == nil then
		local view = Dialogue.view(session, ctx, player.DisplayName)
		if view.isLast then
			Dialogue.advance(session, ctx, r.dialogueEvents)
		end
	end
	if session.ended then
		return finishDialogue(player, profile, r)
	end
	r.dialogue = nil
	r.dialogueEvents = nil
	return { ok = true, discarded = true }
end

Handlers.gift = function(player, profile, args, r)
	if r.dialogue or r.activity then
		return { ok = false, reason = "busy" }
	end
	if not isString(args.npc) or not isString(args.item) then
		return { ok = false, reason = "badArgs" }
	end
	local station = World.station(profile.state, args.npc, ctx)
	if station == nil or not near(player, station, ctx.config.TalkDistance) then
		return { ok = false, reason = "tooFar" }
	end
	local events = {}
	local ok, result = Gifts.give(profile.state, args.npc, args.item, ctx, events)
	if ok then
		commit(player, profile, events)
	end
	return {
		ok = ok,
		reason = result.reason,
		say = result.text and { speaker = args.npc, text = result.text, emote = result.emote } or nil,
		tier = result.tier,
	}
end

Handlers.startActivity = function(player, profile, args, r)
	if r.dialogue or r.activity then
		return { ok = false, reason = "busy" }
	end
	if not isString(args.activity) then
		return { ok = false, reason = "badArgs" }
	end
	local payload, why = startActivity(player, profile, args.activity, true)
	if payload == nil then
		return { ok = false, reason = why }
	end
	return { ok = true, activity = payload }
end

Handlers.activityCollect = function(player, _profile, args, r)
	local session = r.activity
	if session == nil or session.id ~= args.id or session.kind ~= "collect" then
		return { ok = false, reason = "noSession" }
	end
	if type(args.index) ~= "number" then
		return { ok = false, reason = "badArgs" }
	end
	local anchor = session.secret.points[args.index]
	if anchor == nil or not near(player, anchor, ctx.config.CollectDistance) then
		return { ok = false, reason = "tooFar" }
	end
	local def = ctx.content.Activities[session.activity]
	if os.clock() - session.startedAt > (def.params.timeLimit or math.huge) + 5 then
		return { ok = false, reason = "timeUp" }
	end
	local collected = Activities.collect(session, args.index)
	local count = 0
	for _ in pairs(session.collected) do
		count += 1
	end
	return { ok = collected, count = count }
end

Handlers.submitActivity = function(player, profile, args, r)
	local session = r.activity
	if session == nil or session.id ~= args.id then
		return { ok = false, reason = "noSession" }
	end
	local events = {}
	local ok, result =
		Activities.finish(profile.state, session, args.submission, os.clock() - session.startedAt, ctx, events)
	if not ok then
		return { ok = false, reason = result }
	end
	r.activity = nil
	local response = { ok = true, result = result }
	runFollowUps(player, profile, commit(player, profile, events), response)
	flushEnding(player)
	return response
end

Handlers.cancelActivity = function(_player, _profile, args, r)
	if r.activity and r.activity.id == args.id then
		r.activity = nil
	end
	return { ok = true }
end

Handlers.collect = function(player, profile, args, r)
	if r.dialogue then
		return { ok = false, reason = "busy" }
	end
	if not isString(args.id) then
		return { ok = false, reason = "badArgs" }
	end
	local def = ctx.content.Collectibles[args.id]
	if def == nil or not World.collectibleAvailable(profile.state, args.id, ctx) then
		return { ok = false, reason = "unavailable" }
	end
	if not near(player, def.anchor, ctx.config.CollectDistance) then
		return { ok = false, reason = "tooFar" }
	end
	local events = {}
	World.collect(profile.state, args.id, ctx, events)
	commit(player, profile, events)
	return { ok = true, text = def.text, name = def.name }
end

Handlers.settings = function(player, profile, args, r)
	local settings = SaveSchema.validateSettings(args.settings, profile.state.settings)
	profile.state.settings = settings
	if r.dialogue then
		r.dialogue.state.settings = settings
	end
	DataService.markDirty(profile)
	remotes.StateSync:FireClient(player, profile.state)
	return { ok = true }
end

Handlers.setFlag = function(player, profile, args, r)
	if r.dialogue or not isString(args.flag) or not CLIENT_FLAGS[args.flag] then
		return { ok = false, reason = "badArgs" }
	end
	profile.state.flags[args.flag] = true
	DataService.markDirty(profile)
	remotes.StateSync:FireClient(player, profile.state)
	return { ok = true }
end

Handlers.endingText = function(_player, profile, args)
	if not isString(args.id) or not profile.state.endingsSeen[args.id] then
		return { ok = false, reason = "notSeen" }
	end
	return { ok = true, ending = endingPayload(profile.state, args.id) }
end

Handlers.newStory = function(player, profile, args, r)
	if args.confirm ~= true then
		return { ok = false, reason = "notConfirmed" }
	end
	r.dialogue, r.dialogueEvents, r.activity = nil, nil, nil
	profile.state = SaveSchema.newStory(profile.state, ctx)
	local events = Rules.ensureStarted(profile.state, ctx, {})
	commit(player, profile, events)
	return { ok = true, state = profile.state }
end

local function onRequest(player: Player, action: any, args: any)
	if not allow(player) then
		return { ok = false, reason = "rateLimited" }
	end
	if type(action) ~= "string" or Handlers[action] == nil then
		return { ok = false, reason = "badAction" }
	end
	if type(args) ~= "table" then
		args = {}
	end
	local profile = DataService.get(player)
	if profile == nil then
		return { ok = false, reason = "loading" }
	end
	local ok, result = pcall(Handlers[action], player, profile, args, rt(player))
	if not ok then
		warn(`[Hearthscale] {action} failed for {player.UserId}: {result}`)
		-- Never leave a half-applied dialogue around after an error.
		local r = rt(player)
		r.dialogue, r.dialogueEvents = nil, nil
		return { ok = false, reason = "serverError" }
	end
	return result
end

-- Location triggers ("reach:<id>" objectives), checked on the server.
local function reachLoop()
	while true do
		task.wait(1)
		for _, player in ipairs(Players:GetPlayers()) do
			local profile = DataService.get(player)
			local r = runtime[player]
			if profile and not (r and r.dialogue) then
				for _, locId in ipairs(World.pendingReaches(profile.state, ctx)) do
					local loc = ctx.content.Locations[locId]
					if near(player, loc.anchor, loc.radius or ctx.config.ReachDistanceDefault) then
						local events = {}
						if World.reach(profile.state, locId, ctx, events) then
							commit(player, profile, events)
						end
					end
				end
			end
		end
	end
end

function GameService.init(context, dataService, remoteTable)
	ctx, DataService, remotes = context, dataService, remoteTable
	local Systems = ctx.shared.Systems
	Rules = require(Systems.Rules)
	Dialogue = require(Systems.Dialogue)
	Gifts = require(Systems.Gifts)
	Activities = require(Systems.Activities)
	World = require(Systems.World)
	SaveSchema = require(Systems.SaveSchema)
	WorldAnchors = require(ctx.shared.WorldAnchors)

	remotes.Request.OnServerInvoke = onRequest

	DataService.onLoaded(function(player, profile)
		remotes.StateSync:FireClient(player, profile.state)
	end)

	Players.PlayerRemoving:Connect(function(player)
		runtime[player] = nil
	end)

	task.spawn(reachLoop)
end

return GameService
