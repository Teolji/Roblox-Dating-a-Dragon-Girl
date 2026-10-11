--[[
	Server harness: runs the REAL server modules (DataService, GameService)
	under Lune with mocked Roblox services, so request validation, saving,
	session locks and leave/rejoin can be exercised without Studio.

	Mocks: game (GetService, JobId, BindToClose), Players, DataStoreService
	(JSON round-trips values like the real service; can inject failures),
	RunService, HttpService, workspace (empty: anchors fall back to data),
	remotes, and a deterministic task scheduler with a fake clock.
	Roblox datatypes (Vector3, CFrame) come from @lune/roblox.
]]

local roblox = require("@lune/roblox")
local serde = require("@lune/serde")

local Loader = require("./loader")

local Harness = {}
Harness.__index = Harness

local function jsonCopy(value)
	if value == nil then
		return nil
	end
	return serde.decode("json", serde.encode("json", value))
end

local function newSignal(h)
	local s = { handlers = {} }
	function s:Connect(fn)
		table.insert(self.handlers, fn)
		return {
			Disconnect = function() end,
		}
	end
	function s:Fire(...)
		for _, fn in ipairs(self.handlers) do
			h.task.spawn(fn, ...)
		end
	end
	return s
end

function Harness.newStore()
	local store = { data = {}, writes = 0, failUpdates = 0, failAll = false, calls = 0 }
	function store:UpdateAsync(key, transform)
		self.calls += 1
		if self.failAll or self.failUpdates > 0 then
			self.failUpdates = math.max(0, self.failUpdates - 1)
			error("mock DataStore: 503 Service Unavailable")
		end
		local result = transform(jsonCopy(self.data[key]))
		if result ~= nil then
			self.data[key] = jsonCopy(result)
			self.writes += 1
		end
		return result
	end
	function store:GetAsync(key)
		if self.failAll then
			error("mock DataStore: 503 Service Unavailable")
		end
		return jsonCopy(self.data[key])
	end
	return store
end

function Harness.new(options)
	options = options or {}
	local h = setmetatable({}, Harness)
	h.now = 1000
	h.queue = {}
	h.warnings = {}
	h.fired = {}
	h.statuses = {}
	h.store = options.store or Harness.newStore()

	-- Scheduler ------------------------------------------------------------
	local function resume(co, ...)
		local ok, err = coroutine.resume(co, ...)
		if not ok then
			error(debug.traceback(co, tostring(err)), 0)
		end
	end
	local function enqueue(co, at, args)
		table.insert(h.queue, { co = co, at = at, args = args })
	end
	local task = {}
	function task.spawn(fn, ...)
		local co = if type(fn) == "thread" then fn else coroutine.create(fn)
		resume(co, ...)
		return co
	end
	function task.defer(fn, ...)
		local co = coroutine.create(fn)
		enqueue(co, h.now, table.pack(...))
		return co
	end
	function task.delay(t, fn, ...)
		local co = coroutine.create(fn)
		enqueue(co, h.now + (t or 0), table.pack(...))
		return co
	end
	function task.wait(t)
		local co = coroutine.running()
		enqueue(co, h.now + math.max(t or 0, 0.001), nil)
		coroutine.yield()
		return t or 0
	end
	h.task = task

	local function popNext(limit: number?)
		table.sort(h.queue, function(a, b)
			return a.at < b.at
		end)
		local item = h.queue[1]
		if item == nil or (limit and item.at > limit) then
			return nil
		end
		table.remove(h.queue, 1)
		h.now = math.max(h.now, item.at)
		return item
	end
	local function runItem(item)
		if coroutine.status(item.co) == "suspended" then
			if item.args then
				resume(item.co, table.unpack(item.args, 1, item.args.n))
			else
				resume(item.co)
			end
		end
	end

	-- Runs fn as a task and advances fake time until it finishes.
	function h.run(fn, ...)
		local results
		local co = coroutine.create(function(...)
			results = table.pack(fn(...))
		end)
		resume(co, ...)
		local guard = 0
		while coroutine.status(co) ~= "dead" do
			guard += 1
			assert(guard < 200000, "harness: task never finished")
			local item = popNext(nil)
			assert(item, "harness: deadlock")
			runItem(item)
		end
		return table.unpack(results, 1, results.n)
	end

	-- Lets background loops (autosave, reach checks) run for `seconds`.
	function h.advance(seconds: number)
		local target = h.now + seconds
		while true do
			local item = popNext(target)
			if item == nil then
				break
			end
			runItem(item)
		end
		h.now = target
	end

	-- Roblox mocks ---------------------------------------------------------
	local Players = { list = {} }
	Players.PlayerRemoving = newSignal(h)
	Players.PlayerAdded = newSignal(h)
	function Players:GetPlayers()
		return table.clone(self.list)
	end
	local services = {
		Players = Players,
		DataStoreService = {
			GetDataStore = function()
				return h.store
			end,
		},
		RunService = {
			IsStudio = function()
				return options.studio == true
			end,
		},
		HttpService = {
			GenerateGUID = function()
				h.guidCount = (h.guidCount or 0) + 1
				return "guid-" .. h.guidCount
			end,
		},
		Lighting = {},
	}
	local game = { JobId = options.jobId or "server-A", closeHandlers = {} }
	function game:GetService(name)
		return assert(services[name], "no mock service " .. tostring(name))
	end
	function game:BindToClose(fn)
		table.insert(self.closeHandlers, fn)
	end
	h.game = game
	h.Players = Players

	local fakeOs = setmetatable({
		clock = function()
			return h.now
		end,
		time = function()
			return math.floor(h.now)
		end,
	}, { __index = os })

	local globals = {
		game = game,
		workspace = {
			FindFirstChild = function()
				return nil
			end,
		},
		task = task,
		os = fakeOs,
		Vector3 = roblox.Vector3,
		CFrame = roblox.CFrame,
		Random = {
			new = function()
				return {
					NextInteger = function(_, a, b)
						return math.random(a, b)
					end,
				}
			end,
		},
		warn = function(...)
			local parts = {}
			for i = 1, select("#", ...) do
				parts[i] = tostring((select(i, ...)))
			end
			table.insert(h.warnings, table.concat(parts, " "))
		end,
		print = function() end,
	}

	local roots, gameRequire = Loader.mountMany({
		{ path = "src/shared", name = "Hearthscale" },
		{ path = "src/server", name = "HearthscaleServer" },
	}, globals)
	local Shared = roots.Hearthscale
	local config = table.clone(gameRequire(Shared.Config))
	for k, v in pairs(options.config or {}) do
		config[k] = v
	end
	h.ctx = { content = gameRequire(Shared.Content), config = config, shared = Shared }
	h.WorldAnchors = gameRequire(Shared.WorldAnchors)
	h.Rules = gameRequire(Shared.Systems.Rules)
	h.DataService = gameRequire(roots.HearthscaleServer.Services.DataService)
	h.GameService = gameRequire(roots.HearthscaleServer.Services.GameService)

	local function remoteEvent(name)
		return {
			FireClient = function(_, player, ...)
				table.insert(h.fired, { name = name, player = player, args = table.pack(...) })
			end,
		}
	end
	h.remotes = {
		StateSync = remoteEvent("StateSync"),
		Notify = remoteEvent("Notify"),
		SaveStatus = remoteEvent("SaveStatus"),
		EndingShown = remoteEvent("EndingShown"),
		Request = {},
	}

	h.run(function()
		h.DataService.init(h.ctx, function(player, status, message)
			h.statuses[player] = h.statuses[player] or {}
			table.insert(h.statuses[player], { status = status, message = message })
		end)
		h.GameService.init(h.ctx, h.DataService, h.remotes)
	end)
	return h
end

-- Player helpers ------------------------------------------------------------
function Harness:join(userId: number)
	local root = { Position = self.WorldAnchors.position("Spawn") }
	local character = {
		FindFirstChild = function(_, name)
			if name == "HumanoidRootPart" then
				return root
			end
			return nil
		end,
	}
	local player = {
		UserId = userId,
		DisplayName = "Tester",
		Name = "Tester",
		Parent = self.Players,
		Character = character,
		root = root,
	}
	table.insert(self.Players.list, player)
	self.run(self.DataService.load, player)
	return player
end

function Harness:leave(player)
	player.Parent = nil
	local index = table.find(self.Players.list, player)
	if index then
		table.remove(self.Players.list, index)
	end
	self.run(function()
		for _, handler in ipairs(self.Players.PlayerRemoving.handlers) do
			handler(player)
		end
	end)
end

function Harness:moveTo(player, anchorName: string)
	player.root.Position = self.WorldAnchors.position(anchorName) + roblox.Vector3.new(2, 0, 1)
end

function Harness:request(player, action: string, args)
	return self.run(self.remotes.Request.OnServerInvoke, player, action, args)
end

function Harness:state(player)
	local profile = self.DataService.get(player)
	return profile and profile.state
end

-- Talks to an NPC and keeps choosing until the conversation ends.
-- `pick` decides each choice: function(node) -> index (default: first unlocked).
function Harness:converse(player, npc: string, pick)
	local response = self:request(player, "talk", { npc = npc })
	local guard = 0
	while response.ok and response.node and not response.node.ended do
		guard += 1
		assert(guard < 200, "conversation did not end")
		local node = response.node
		if node.choices then
			local index = pick and pick(node) or nil
			if index == nil then
				for _, choice in ipairs(node.choices) do
					if not choice.locked then
						index = choice.index
						break
					end
				end
			end
			response = self:request(player, "choose", { index = index })
		else
			response = self:request(player, "advance")
		end
	end
	return response
end

return Harness
