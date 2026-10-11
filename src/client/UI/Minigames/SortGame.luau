--[[
	SortGame
	Explorer: ...HearthscaleClient > UI > Minigames > SortGame (ModuleScript)

	"Cataloguing the Hoard": read each lost item's tag and pick its shelf.
	The correct shelves are never sent to the client — the server scores
	the picks afterwards — so Saffron comments without revealing answers.
]]

local Theme = require(script.Parent.Parent.Theme)

local SortGame = {}

local QUIPS = {
	"Hmm! Bold.",
	"Interesting choice.",
	"The umbrellas are watching.",
	"Ooh. Decisive.",
	"I'll allow it. Probably.",
	"Next!",
}

function SortGame.run(container: Frame, payload, finish: (any) -> ())
	local public = payload.public
	local picks = {}
	local index = 1
	local started = os.clock()
	local finished = false

	local header = Theme.label({
		Text = "",
		Font = Theme.Fonts.title,
		TextColor3 = Theme.Colors.emberDark,
		TextSizeBase = 20,
		LayoutOrder = 1,
		Parent = container,
	})
	local timer = Theme.new("Frame", {
		BackgroundColor3 = Theme.Colors.paperDark,
		Size = UDim2.new(1, 0, 0, 10),
		LayoutOrder = 2,
		Parent = container,
	}, { Theme.corner(5) })
	local timerFill = Theme.new(
		"Frame",
		{ BackgroundColor3 = Theme.Colors.ember, Size = UDim2.fromScale(1, 1), Parent = timer },
		{ Theme.corner(5) }
	)
	local cardFrame = Theme.new("Frame", {
		BackgroundColor3 = Theme.Colors.paperDark,
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 3,
		Parent = container,
	}, { Theme.corner(12), Theme.padding(14), Theme.list(4) })
	local itemName = Theme.label({
		Text = "",
		Font = Theme.Fonts.title,
		TextSizeBase = 26,
		TextXAlignment = Enum.TextXAlignment.Center,
		LayoutOrder = 1,
		Parent = cardFrame,
	})
	local flavor = Theme.label({
		Text = "",
		TextColor3 = Theme.Colors.inkSoft,
		TextSizeBase = 17,
		TextXAlignment = Enum.TextXAlignment.Center,
		LayoutOrder = 2,
		Parent = cardFrame,
	})
	local quip = Theme.label({
		Text = "Saffron: Read the tag, pick a shelf.",
		TextColor3 = Theme.Colors.emberDark,
		TextSizeBase = 16,
		TextXAlignment = Enum.TextXAlignment.Center,
		LayoutOrder = 4,
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
			CellSize = UDim2.new(0.5, -6, 0, 56),
			CellPadding = UDim2.fromOffset(8, 8),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})
	grid.LayoutOrder = 5

	local function show()
		local item = public.items[index]
		header.Text = `Item {index} of {#public.items}`
		itemName.Text = item.name
		flavor.Text = item.flavor or ""
	end

	local function complete()
		if finished then
			return
		end
		finished = true
		finish(picks)
	end

	local function pick(shelfIndex: number)
		if finished or public.shelves[shelfIndex] == nil then
			return
		end
		picks[index] = shelfIndex
		quip.Text = "Saffron: " .. QUIPS[math.random(1, #QUIPS)]
		index += 1
		if index > #public.items then
			complete()
		else
			show()
		end
	end

	for shelfIndex, shelfName in ipairs(public.shelves) do
		local label = shelfIndex <= 4 and `{shelfIndex}. {shelfName}` or shelfName
		local button = Theme.button({ Text = label, TextSizeBase = 19, LayoutOrder = shelfIndex, Parent = grid })
		button.Activated:Connect(function()
			pick(shelfIndex)
		end)
	end
	show()

	task.spawn(function()
		while not finished do
			local remaining = 1 - (os.clock() - started) / public.timeLimit
			timerFill.Size = UDim2.fromScale(math.clamp(remaining, 0, 1), 1)
			if remaining <= 0 then
				complete()
			end
			task.wait(0.1)
		end
	end)

	-- Number keys 1–4 pick a shelf.
	return { key = pick }
end

return SortGame
