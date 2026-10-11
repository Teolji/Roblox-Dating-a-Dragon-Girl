--[[
	MinigameHost
	Explorer: ...HearthscaleClient > UI > Minigames > MinigameHost (ModuleScript)

	Runs a server-issued activity session: intro card → game → submit →
	result card → partner's reaction line. Waits out the activity's minimum
	duration before submitting so quick players are never rejected.
	Keyboard: 1–4 for choices, Space/Enter for the main action;
	gamepad A for the main action.
]]

local ContextActionService = game:GetService("ContextActionService")

local Theme = require(script.Parent.Parent.Theme)
local Root = require(script.Parent.Parent.Root)
local Session = require(script.Parent.Parent.Parent.Controllers.Session)
local Audio = require(script.Parent.Parent.Parent.Controllers.Audio)

local Games = {
	sort = require(script.Parent.SortGame),
	timing = require(script.Parent.TimingGame),
	sequence = require(script.Parent.SequenceGame),
	collect = require(script.Parent.CollectGame),
}

local MinigameHost = {}
MinigameHost.hooks = {
	lockMovement = function(_on: boolean) end,
	say = function(_speaker: string, _text: string, _emote: string?, _onDone: (() -> ())?) end,
	startActivity = function(_payload) end,
}

local running = false

local function panel(compact: boolean)
	if compact then
		return Theme.new("Frame", {
			Name = "Minigame",
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, 10),
			Size = UDim2.fromScale(0.5, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundColor3 = Theme.Colors.panel,
			BackgroundTransparency = 0.15,
			Parent = Root.layers.minigame,
		}, {
			Theme.corner(14),
			Theme.padding(10),
			Theme.list(6),
			Theme.new("UISizeConstraint", { MinSize = Vector2.new(260, 0), MaxSize = Vector2.new(480, 200) }),
		})
	end
	local backdrop = Theme.new("Frame", {
		Name = "Minigame",
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.4,
		Size = UDim2.fromScale(1, 1),
		Parent = Root.layers.minigame,
	})
	local frame = Theme.new("Frame", {
		Name = "Panel",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.9, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Theme.Colors.paper,
		Parent = backdrop,
	}, {
		Theme.corner(18),
		Theme.stroke(Theme.Colors.emberDark, 3),
		Theme.padding(16),
		Theme.list(10),
		Theme.new("UISizeConstraint", { MaxSize = Vector2.new(640, 1000) }),
	})
	return frame, backdrop
end

local function waitForButton(button: TextButton)
	local event = Instance.new("BindableEvent")
	local c1 = button.Activated:Connect(function()
		event:Fire()
	end)
	event.Event:Wait()
	c1:Disconnect()
	event:Destroy()
end

function MinigameHost.start(payload)
	if running or payload == nil then
		return
	end
	running = true
	Session.setMode("minigame", true)
	local kindModule = Games[payload.kind]
	local def = Session.Content.Activities[payload.activity]
	local compact = kindModule.compact == true
	MinigameHost.hooks.lockMovement(not compact)

	-- Intro card
	local frame, backdrop = panel(false)
	Theme.label({
		Text = payload.name,
		Font = Theme.Fonts.title,
		TextColor3 = Theme.Colors.emberDark,
		TextSizeBase = 28,
		TextXAlignment = Enum.TextXAlignment.Center,
		LayoutOrder = 1,
		Parent = frame,
	})
	Theme.label({
		Text = payload.description or "",
		TextSizeBase = 18,
		TextXAlignment = Enum.TextXAlignment.Center,
		LayoutOrder = 2,
		Parent = frame,
	})
	local startButton = Theme.button({ Text = "Start", LayoutOrder = 3, Parent = frame })
	local cancelButton =
		Theme.button({ Text = "Not now", BackgroundColor3 = Theme.Colors.panelSoft, LayoutOrder = 4, Parent = frame })
	local cancelled = false
	cancelButton.Activated:Connect(function()
		cancelled = true
	end)
	local event = Instance.new("BindableEvent")
	startButton.Activated:Connect(function()
		event:Fire()
	end)
	cancelButton.Activated:Connect(function()
		event:Fire()
	end)
	event.Event:Wait()
	event:Destroy()
	backdrop:Destroy()
	if cancelled then
		Session.request("cancelActivity", { id = payload.id })
		MinigameHost.hooks.lockMovement(false)
		Session.setMode("minigame", false)
		running = false
		return
	end

	-- Game
	local container, gameBackdrop = panel(compact)
	if not compact then
		Theme.label({
			Text = payload.name,
			Font = Theme.Fonts.title,
			TextColor3 = Theme.Colors.emberDark,
			TextSizeBase = 24,
			TextXAlignment = Enum.TextXAlignment.Center,
			LayoutOrder = 0,
			Parent = container,
		})
	end
	local started = os.clock()
	local submission = nil
	local done = Instance.new("BindableEvent")
	local controls = kindModule.run(container, payload, function(result)
		submission = result
		done:Fire()
	end) or {}

	ContextActionService:BindActionAtPriority(
		"HearthscaleMinigame",
		function(_name, inputState, input)
			if inputState ~= Enum.UserInputState.Begin then
				return Enum.ContextActionResult.Sink
			end
			local digit = ({
				[Enum.KeyCode.One] = 1,
				[Enum.KeyCode.Two] = 2,
				[Enum.KeyCode.Three] = 3,
				[Enum.KeyCode.Four] = 4,
			})[input.KeyCode]
			if digit and controls.key then
				controls.key(digit)
				return Enum.ContextActionResult.Sink
			elseif not digit and controls.action and not compact then
				controls.action()
				return Enum.ContextActionResult.Sink
			end
			return Enum.ContextActionResult.Pass
		end,
		false,
		Enum.ContextActionPriority.High.Value,
		Enum.KeyCode.One,
		Enum.KeyCode.Two,
		Enum.KeyCode.Three,
		Enum.KeyCode.Four,
		Enum.KeyCode.Space,
		Enum.KeyCode.Return,
		Enum.KeyCode.ButtonA
	)

	if submission == nil then
		done.Event:Wait()
	end
	done:Destroy()
	ContextActionService:UnbindAction("HearthscaleMinigame")

	-- Never submit faster than the activity's minimum duration.
	local minimum = (def and def.minDuration or 0) + 0.3
	local elapsed = os.clock() - started
	if elapsed < minimum then
		task.wait(minimum - elapsed)
	end
	local response = Session.request("submitActivity", { id = payload.id, submission = submission });
	(gameBackdrop or container):Destroy()

	MinigameHost.hooks.lockMovement(false)
	Session.setMode("minigame", false)
	running = false

	if response.ok then
		local result = response.result
		local resultFrame, resultBackdrop = panel(false)
		Session.setMode("minigame", true)
		Theme.label({
			Text = result.tierLabel or "Done!",
			Font = Theme.Fonts.title,
			TextColor3 = Theme.Colors.emberDark,
			TextSizeBase = 30,
			TextXAlignment = Enum.TextXAlignment.Center,
			LayoutOrder = 1,
			Parent = resultFrame,
		})
		Theme.label({
			Text = `Score: {result.score} / {result.maxScore}`,
			TextSizeBase = 20,
			TextXAlignment = Enum.TextXAlignment.Center,
			LayoutOrder = 2,
			Parent = resultFrame,
		})
		local ok = Theme.button({ Text = "Continue", LayoutOrder = 3, Parent = resultFrame })
		Audio.sfx(result.score > 0 and "success" or "fail")
		waitForButton(ok)
		resultBackdrop:Destroy()
		Session.setMode("minigame", false)
		if result.line and def and def.partner then
			MinigameHost.hooks.say(def.partner, result.line.text, result.line.emote)
		end
		if response.activity then
			MinigameHost.hooks.startActivity(response.activity)
		end
	end
end

function MinigameHost.isRunning(): boolean
	return running
end

return MinigameHost
