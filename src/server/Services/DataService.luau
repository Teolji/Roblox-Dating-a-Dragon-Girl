--[[
	DataService
	Explorer: ServerScriptService > HearthscaleServer > Services > DataService (ModuleScript)

	Per-player persistence with DataStoreService:
	  • Session locking: a save records { job = game.JobId, t = os.time() }.
	    Loads wait briefly for another server to release the lock, then take
	    it over. Saves only write while this server still owns the lock, so
	    a stale server can never overwrite newer progress.
	  • Retries with exponential backoff on every DataStore call.
	  • Autosave of changed profiles, save + release on leave, and a
	    BindToClose flush on shutdown.
	  • Graceful failure: if a save can't be loaded, the player can still play
	    but saving is disabled for that session (so an empty profile can never
	    overwrite their real one) and the client shows a clear warning.
	  • Studio without API access falls back to an in-memory store.

	Stored value: { v = SaveVersion, state = <SaveSchema state>, lock = {...}?, savedAt = os.time() }
]]

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local DataService = {}

DataService.profiles = {} :: { [Player]: any }
DataService.mode = "datastore" -- "datastore" | "memory"

local ctx, SaveSchema, Rules, Tables
local store
local onStatus: ((Player, string, string?) -> ())? = nil
local loadedCallbacks = {}

-- In-memory stand-in with the same UpdateAsync contract (Studio only).
local function memoryStore()
	local data = {}
	return {
		UpdateAsync = function(_self, key, transform)
			local current = data[key] and Tables.deepCopy(data[key])
			local result = transform(current)
			if result ~= nil then
				data[key] = Tables.deepCopy(result)
			end
			return result
		end,
	}
end

local function status(player: Player, kind: string, message: string?)
	if onStatus then
		onStatus(player, kind, message)
	end
end

local function keyFor(player: Player): string
	return ctx.config.DataStoreKeyPrefix .. tostring(player.UserId)
end

function DataService.init(context, statusCallback)
	ctx = context
	SaveSchema = require(ctx.shared.Systems.SaveSchema)
	Rules = require(ctx.shared.Systems.Rules)
	Tables = require(ctx.shared.Util.Tables)
	onStatus = statusCallback

	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(ctx.config.DataStoreName)
	end)
	if ok then
		store = result
	end

	-- In Studio, DataStores fail when the place is unpublished or API access
	-- is off. Fall back to memory so testing never stalls on retries.
	if RunService:IsStudio() and ctx.config.UseMemoryStoreWhenApiUnavailable then
		local probeOk, probeErr = pcall(function()
			assert(store, "no datastore")
			store:GetAsync("__probe")
		end)
		if not probeOk then
			warn(
				`[Hearthscale] DataStores unavailable in Studio ({probeErr}). Publish the place and enable `
					.. "Game Settings > Security > 'Enable Studio Access to API Services' to test real saving. "
					.. "Using an in-memory store for this session."
			)
			store = memoryStore()
			DataService.mode = "memory"
		end
	end
	if store == nil then
		warn("[Hearthscale] Could not open DataStore; saving disabled for this server.")
	end

	task.spawn(DataService._autosaveLoop)
	game:BindToClose(DataService._flushAll)
end

function DataService.onLoaded(callback: (Player, any) -> ())
	table.insert(loadedCallbacks, callback)
end

function DataService.get(player: Player)
	local profile = DataService.profiles[player]
	if profile and profile.loaded then
		return profile
	end
	return nil
end

local function tryLoad(key: string)
	local loadedState, lockedBy = nil, nil
	local ok, err = pcall(function()
		store:UpdateAsync(key, function(old)
			old = old or {}
			local lock = old.lock
			if
				type(lock) == "table"
				and lock.job ~= game.JobId
				and (os.time() - (tonumber(lock.t) or 0)) < ctx.config.SessionLockTimeout
			then
				lockedBy = lock.job
				return nil -- cancel: someone else owns the session
			end
			lockedBy = nil
			loadedState = old.state
			old.lock = { job = game.JobId, t = os.time() }
			return old
		end)
	end)
	return ok, err, loadedState, lockedBy
end

local function forceLock(key: string)
	local loadedState = nil
	local ok, err = pcall(function()
		store:UpdateAsync(key, function(old)
			old = old or {}
			loadedState = old.state
			old.lock = { job = game.JobId, t = os.time() }
			return old
		end)
	end)
	return ok, err, loadedState
end

function DataService.load(player: Player)
	local profile = {
		player = player,
		key = keyFor(player),
		loaded = false,
		saveEnabled = false,
		dirty = false,
		version = 0,
		savedVersion = 0,
		saving = false,
		lastSave = os.clock(),
		joinedAt = os.clock(),
		state = nil,
	}
	DataService.profiles[player] = profile

	local raw, loadedOk = nil, false
	if store then
		for attempt = 1, ctx.config.LoadAttempts do
			local ok, err, state, lockedBy = tryLoad(profile.key)
			if ok and lockedBy == nil then
				raw, loadedOk = state, true
				break
			elseif ok then
				-- Another server still holds this save (usually it is mid-way
				-- through saving after the player left it). Wait, then take over.
				status(player, "saving", "Fetching your save from your previous server…")
				if attempt >= 3 then
					local forcedOk, forcedErr, forcedState = forceLock(profile.key)
					if forcedOk then
						raw, loadedOk = forcedState, true
						break
					end
					warn(`[Hearthscale] force lock failed for {player.UserId}: {forcedErr}`)
				end
				task.wait(2 + attempt)
			else
				warn(`[Hearthscale] load attempt {attempt} failed for {player.UserId}: {err}`)
				task.wait(math.min(2 ^ attempt, 16))
			end
			if player.Parent == nil then
				break
			end
		end
	end

	if player.Parent == nil then
		-- Left while loading: hand the lock straight back.
		DataService.profiles[player] = nil
		if loadedOk then
			pcall(function()
				store:UpdateAsync(profile.key, function(old)
					if type(old) == "table" and type(old.lock) == "table" and old.lock.job == game.JobId then
						old.lock = nil
						return old
					end
					return nil
				end)
			end)
		end
		return nil
	end

	profile.state = SaveSchema.reconcile(raw, ctx)
	profile.saveEnabled = loadedOk
	Rules.ensureStarted(profile.state, ctx, {})
	profile.loaded = true

	if not loadedOk then
		status(
			player,
			"disabled",
			"We couldn't load your save, so progress from this visit won't be saved. Your existing save is safe — please rejoin later."
		)
	elseif DataService.mode == "memory" then
		status(player, "memory", "Studio test mode: progress is kept only until you stop the test.")
	else
		status(player, "ok", nil)
	end

	for _, callback in ipairs(loadedCallbacks) do
		task.spawn(callback, player, profile)
	end
	return profile
end

function DataService.markDirty(profile)
	profile.dirty = true
	profile.version += 1
end

function DataService.save(profile, release: boolean?): boolean
	if not profile.saveEnabled or store == nil then
		return false
	end
	if profile.saving then
		-- One save at a time per profile; the running save picks up the latest
		-- state on its next autosave tick (or the release below waits).
		local started = os.clock()
		while profile.saving and os.clock() - started < 30 do
			task.wait(0.25)
		end
	end
	profile.saving = true
	if release then
		status(profile.player, "saving", nil)
	end

	local now = os.clock()
	profile.state.meta.playSeconds += math.floor(now - (profile.lastPlayTick or profile.joinedAt))
	profile.lastPlayTick = now

	local snapshot = Tables.deepCopy(profile.state)
	local versionAtSnapshot = profile.version
	local success = false
	local lostLock = false

	for attempt = 1, ctx.config.SaveAttempts do
		local ok, err = pcall(function()
			store:UpdateAsync(profile.key, function(old)
				old = old or {}
				local lock = old.lock
				if type(lock) == "table" and lock.job ~= game.JobId then
					lostLock = true
					return nil
				end
				old.v = ctx.config.SaveVersion
				old.state = snapshot
				old.savedAt = os.time()
				if release then
					old.lock = nil
				else
					old.lock = { job = game.JobId, t = os.time() }
				end
				return old
			end)
		end)
		if ok then
			success = not lostLock
			break
		end
		warn(`[Hearthscale] save attempt {attempt} failed for {profile.player.UserId}: {err}`)
		if attempt < ctx.config.SaveAttempts then
			task.wait(math.min(2 ^ attempt, 8))
		end
	end

	profile.saving = false
	profile.lastSave = os.clock()
	if lostLock then
		-- Another server took this save over (the player joined elsewhere).
		profile.saveEnabled = false
		status(profile.player, "disabled", "Your save is now open on another server, so this one stopped saving.")
	elseif success then
		profile.savedVersion = versionAtSnapshot
		profile.dirty = profile.version ~= versionAtSnapshot
		status(profile.player, "ok", nil)
	else
		status(profile.player, "failed", "Couldn't reach Roblox's save service. We'll keep trying automatically.")
	end
	return success
end

function DataService.release(player: Player)
	local profile = DataService.profiles[player]
	if profile == nil then
		return
	end
	if profile.loaded then
		DataService.save(profile, true)
	end
	DataService.profiles[player] = nil
end

function DataService._autosaveLoop()
	while true do
		task.wait(10)
		for _, profile in pairs(DataService.profiles) do
			if profile.loaded and profile.saveEnabled and not profile.saving then
				local age = os.clock() - profile.lastSave
				-- Save changes on the interval; refresh the lock every 5 minutes regardless.
				if (profile.dirty and age >= ctx.config.AutosaveInterval) or age >= 300 then
					task.spawn(DataService.save, profile, false)
				end
			end
		end
	end
end

function DataService._flushAll()
	local pending = 0
	for player, profile in pairs(DataService.profiles) do
		if profile.loaded then
			pending += 1
			task.spawn(function()
				DataService.save(profile, true)
				DataService.profiles[player] = nil
				pending -= 1
			end)
		end
	end
	local started = os.clock()
	while pending > 0 and os.clock() - started < 25 do
		task.wait(0.2)
	end
end

Players.PlayerRemoving:Connect(DataService.release)

return DataService
