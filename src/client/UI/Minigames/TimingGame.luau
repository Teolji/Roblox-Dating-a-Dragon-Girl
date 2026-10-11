--[[
	TimingGame
	Explorer: ...HearthscaleClient > UI > Minigames > TimingGame (ModuleScript)

	Fishing at Mirror Pond and the Hearthflame finale: a marker sweeps across
	a bar; press when it's inside the glowing zone. Tap the big button,
	anywhere on the bar, Space, or gamepad A. The server re-checks every stop
	position against the zones it generated.
]]

local RunService = game:GetService("RunService")

local Theme = require(script.Parent.Parent.Theme)

local TimingGame = {}

function TimingGame.run(container: Frame, payload, finish: (any) -> ())
	local public = payload.public
	local rounds = public.rounds
	local positions = {}
	local round = 1
	local roundStart = os.clock()
	local started = os.clock()
	local paused = false
	local finished = false
	local verb = payload.activity == "act_rekindle" and "BREATHE" or "REEL"

	Theme.label({
		Text = public.prompt or "Press when the marker is in the glowing zone!",
		TextSizeBase = 18,
		TextXAlignment = Enum.TextXAlignment.Center,
		LayoutOrder = 1,
		Parent = container,
	})
	local status = Theme.label({
		Text = "",
		Font = Theme.Fonts.title,
		TextColor3 = Theme.Colors.emberDark,
		TextSizeBase = 20,
		TextXAlignment = Enum.TextXAlignment.Center,
		LayoutOrder = 2,
		Parent = container,
	})
	local track = Theme.new("TextButton", {
		Text = "",
		AutoButtonColor = false,
		Selectable = false,
		BackgroundColor3 = Theme.Colors.panel,
		Size = UDim2.new(1, 0, 0, 64),
		LayoutOrder = 3,
		Parent = container,
	}, { Theme.corner(14) })
	local zone = Theme.new("Frame", {
		BackgroundColor3 = Theme.Colors.gold,
		AnchorPoint = Vector2.new(0.5, 0),
		Size = UDim2.fromScale(0.2, 1),
		Parent = track,
	}, { Theme.corner(10) })
	local marker = Theme.new("Frame", {
		BackgroundColor3 = Theme.Colors.white,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0, 0.5),
		Size = UDim2.new(0, 10, 1.3, 0),
		ZIndex = 3,
		Parent = track,
	}, { Theme.corner(5) })
	local button = Theme.button({
		Text = verb,
		TextSizeBase = 26,
		Size = UDim2.new(1, 0, 0, 72),
		LayoutOrder = 4,
		Parent = container,
	})

	local function position(): number
		local r = rounds[round]
		local cycle = ((os.clock() - roundStart) * r.speed) % 2
		return cycle <= 1 and cycle or 2 - cycle -- ping-pong 0..1
	end

	local function showRound()
		local r = rounds[round]
		zone.Position = UDim2.fromScale(r.center, 0)
		zone.Size = UDim2.fromScale(r.width, 1)
		status.Text = `Round {round} of {#rounds}`
		roundStart = os.clock()
	end

	local function complete()
		if not finished then
			finished = true
			finish(positions)
		end
	end

	local function press()
		if finished or paused then
			return
		end
		local p = position()
		local r = rounds[round]
		positions[round] = p
		local hit = math.abs(p - r.center) <= r.width / 2
		status.Text = hit and "Got it!" or "Missed…"
		zone.BackgroundColor3 = hit and Theme.Colors.good or Theme.Colors.bad
		paused = true
		task.delay(0.7, function()
			paused = false
			zone.BackgroundColor3 = Theme.Colors.gold
			round += 1
			if round > #rounds then
				complete()
			else
				showRound()
			end
		end)
	end

	button.Activated:Connect(press)
	track.Activated:Connect(press)
	showRound()

	local connection
	connection = RunService.RenderStepped:Connect(function()
		if finished then
			connection:Disconnect()
			return
		end
		if not paused then
			marker.Position = UDim2.fromScale(position(), 0.5)
		end
		if public.timeLimit and os.clock() - started > public.timeLimit then
			complete()
		end
	end)

	return { action = press }
end

return TimingGame
