--[[
	SequenceGame
	Explorer: ...HearthscaleClient > UI > Minigames > SequenceGame (ModuleScript)

	Painting lantern runes: Saffron paints a pattern, then you repeat it.
	Patterns grow by one rune each round. Tap runes or press 1–4.
]]

local Theme = require(script.Parent.Parent.Theme)

local SequenceGame = {}

local GLYPHS = { Ember = "🔥", Leaf = "🍃", Star = "⭐", Wave = "🌊" }
local COLORS = {
	Color3.fromRGB(232, 110, 60),
	Color3.fromRGB(110, 170, 96),
	Color3.fromRGB(240, 196, 98),
	Color3.fromRGB(86, 150, 200),
}

function SequenceGame.run(container: Frame, payload, finish: (any) -> ())
	local public = payload.public
	local answers = {}
	local round = 1
	local input = {}
	local accepting = false
	local finished = false

	local status = Theme.label({
		Text = "",
		Font = Theme.Fonts.title,
		TextColor3 = Theme.Colors.emberDark,
		TextSizeBase = 22,
		TextXAlignment = Enum.TextXAlignment.Center,
		LayoutOrder = 1,
		Parent = container,
	})
	local progress = Theme.label({
		Text = "",
		TextSizeBase = 18,
		TextXAlignment = Enum.TextXAlignment.Center,
		LayoutOrder = 2,
		Parent = container,
	})
	local grid = Theme.new("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 3,
		Parent = container,
	}, {
		Theme.new("UIGridLayout", {
			CellSize = UDim2.new(0.25, -8, 0, 86),
			CellPadding = UDim2.fromOffset(8, 8),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})

	local buttons = {}
	local function complete()
		if not finished then
			finished = true
			finish(answers)
		end
	end

	local function flash(i: number, duration: number)
		local b = buttons[i]
		b.BackgroundColor3 = Theme.Colors.white
		b.TextColor3 = COLORS[i]
		task.wait(duration)
		b.BackgroundColor3 = COLORS[i]
		b.TextColor3 = Theme.Colors.white
	end

	local function playRound()
		local seq = public.rounds[round]
		accepting = false
		input = {}
		status.Text = `Round {round} of {#public.rounds} — watch Saffron paint…`
		progress.Text = ""
		task.wait(0.6)
		for _, symbol in ipairs(seq) do
			if finished then
				return
			end
			flash(symbol, 0.45)
			task.wait(0.18)
		end
		status.Text = "Your turn!"
		progress.Text = string.rep("○ ", #seq)
		accepting = true
	end

	local function press(i: number)
		if not accepting or finished or buttons[i] == nil then
			return
		end
		table.insert(input, i)
		local seq = public.rounds[round]
		progress.Text = string.rep("● ", #input) .. string.rep("○ ", #seq - #input)
		task.spawn(flash, i, 0.15)
		local wrong = input[#input] ~= seq[#input]
		if wrong or #input == #seq then
			accepting = false
			answers[round] = table.clone(input)
			status.Text = wrong and "The lantern says 'soup'. Next one!" or "Perfect runes!"
			task.delay(1, function()
				round += 1
				if round > #public.rounds then
					complete()
				else
					playRound()
				end
			end)
		end
	end

	for i, name in ipairs(public.symbols) do
		local b = Theme.button({
			Text = `{GLYPHS[name] or ""}\n{name}`,
			TextSizeBase = 18,
			BackgroundColor3 = COLORS[i] or Theme.Colors.ember,
			LayoutOrder = i,
			Parent = grid,
		})
		b.Activated:Connect(function()
			press(i)
		end)
		buttons[i] = b
	end

	task.spawn(playRound)
	task.spawn(function()
		local started = os.clock()
		while not finished do
			if public.timeLimit and os.clock() - started > public.timeLimit then
				complete()
			end
			task.wait(0.25)
		end
	end)
	return { key = press }
end

return SequenceGame
