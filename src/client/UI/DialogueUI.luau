--[[
	DialogueUI
	Explorer: StarterPlayer > StarterPlayerScripts > HearthscaleClient > UI > DialogueUI (ModuleScript)

	The conversation box. Shows one server-provided node at a time with a
	typewriter effect, then either a "continue" prompt or the choices.
	Controls: tap/click the box, Space/Enter or gamepad A to continue;
	tap a choice, press 1–4, or select with the D-pad + A. The ✕ button
	leaves a conversation (unfinished scenes don't count; you can replay them).
]]

local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")

local Theme = require(script.Parent.Theme)
local Root = require(script.Parent.Root)
local Session = require(script.Parent.Parent.Controllers.Session)
local Signal = require(Session.Shared.Util.Signal)
local Audio = require(script.Parent.Parent.Controllers.Audio)

local DialogueUI = {}
DialogueUI.Closed = Signal.new()

-- Injected by Main to avoid require cycles.
DialogueUI.hooks = {
	setExpression = function(_npc: string, _emote: string) end,
	focusCamera = function(_npc: string?) end,
	releaseCamera = function() end,
	lockMovement = function(_on: boolean) end,
	startActivity = function(_payload) end,
	openGift = function(_npc: string) end,
}

local SPEEDS = { slow = 28, normal = 50, fast = 110, instant = math.huge }

local box, nameplate, nameLabel, portrait, portraitLetter, textLabel, continueHint, choiceList, leaveButton
local active = false
local busy = false
local currentNpc: string? = nil
local currentNode = nil
local typingToken = 0
local typing = false
local onSayDone: (() -> ())? = nil
local sayMode = false

local function escape(text: string): string
	return (text:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"))
end

local function finishTyping()
	typingToken += 1
	typing = false
	textLabel.MaxVisibleGraphemes = -1
	continueHint.Visible = currentNode ~= nil and currentNode.canContinue == true or sayMode
	choiceList.Visible = currentNode ~= nil and currentNode.choices ~= nil
	if choiceList.Visible then
		local first = choiceList:FindFirstChild("Choice1")
		if first and UserInputService.GamepadEnabled then
			GuiService.SelectedObject = first
		end
	end
end

local function typeText(text: string)
	typingToken += 1
	local token = typingToken
	textLabel.Text = text
	local speed = SPEEDS[Session.settings().textSpeed or "normal"] or 50
	if Session.settings().reduceMotion then
		speed = math.huge
	end
	local total = utf8.len(textLabel.ContentText) or #textLabel.ContentText
	if speed == math.huge or total == 0 then
		finishTyping()
		return
	end
	typing = true
	continueHint.Visible = false
	choiceList.Visible = false
	textLabel.MaxVisibleGraphemes = 0
	task.spawn(function()
		local shown = 0
		local last = os.clock()
		while shown < total and token == typingToken do
			task.wait()
			local now = os.clock()
			shown = math.min(total, shown + (now - last) * speed)
			last = now
			textLabel.MaxVisibleGraphemes = math.floor(shown)
		end
		if token == typingToken then
			finishTyping()
		end
	end)
end

local function speakerColor(speaker: string): Color3
	local char = Session.Content.Characters[speaker]
	if char then
		return Theme.hex(char.color)
	end
	return speaker == "player" and Theme.Colors.teal or Theme.Colors.panelSoft
end

local function setPortrait(speaker: string)
	local char = Session.Content.Characters[speaker]
	local image = Session.Config.Portraits[speaker]
	portrait.Visible = speaker ~= "narrator"
	portrait.BackgroundColor3 = speakerColor(speaker)
	if image and image ~= "" then
		portrait.Image = string.find(image, "rbxassetid://", 1, true) and image or ("rbxassetid://" .. image)
		portraitLetter.Text = ""
	else
		portrait.Image = ""
		local name = char and char.name or (speaker == "player" and Theme.player().DisplayName or "?")
		portraitLetter.Text = string.upper(string.sub(name, 1, 1))
	end
end

local function clearChoices()
	for _, child in ipairs(choiceList:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
end

local handleResponse -- forward declaration

local function choose(index: number)
	if busy or currentNode == nil or currentNode.choices == nil or typing then
		return
	end
	local choice = currentNode.choices[index]
	if choice == nil or choice.locked then
		return
	end
	busy = true
	Audio.sfx("click")
	handleResponse(Session.request("choose", { index = index }))
end

local function buildChoices(choices)
	clearChoices()
	local keyboard = UserInputService.KeyboardEnabled and not UserInputService.TouchEnabled
	for i, choice in ipairs(choices) do
		local prefix = keyboard and `{i}. ` or ""
		local heart = choice.romance and (Theme.Icons.heart .. " ") or ""
		local button = Theme.button({
			Name = "Choice" .. i,
			Text = prefix .. heart .. choice.text,
			Font = Theme.Fonts.body,
			TextSizeBase = 18,
			TextXAlignment = Enum.TextXAlignment.Left,
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.new(1, 0, 0, 46),
			BackgroundColor3 = choice.locked and Theme.Colors.locked
				or (choice.romance and Theme.Colors.rose or Theme.Colors.panel),
			AutoButtonColor = not choice.locked,
			Selectable = not choice.locked,
			LayoutOrder = i,
			Parent = choiceList,
		})
		Theme.padding(10).Parent = button
		if choice.locked then
			button.TextColor3 = Color3.fromRGB(235, 230, 226)
		else
			button.Activated:Connect(function()
				choose(i)
			end)
		end
	end
end

local function showNode(node)
	currentNode = node
	local speaker = node.speaker
	nameplate.Visible = speaker ~= "narrator"
	nameplate.BackgroundColor3 = speakerColor(speaker)
	nameLabel.Text = node.speakerName or ""
	setPortrait(speaker)
	-- Expression goes to whoever is speaking, or the scene's NPC during narration.
	local face = (Session.Content.Characters[speaker] and speaker) or node.npc
	if face then
		DialogueUI.hooks.setExpression(face, node.emote or "neutral")
	end
	local text = escape(node.text or "")
	if speaker == "narrator" then
		text = "<i>" .. text .. "</i>"
	end
	if node.choices then
		buildChoices(node.choices)
	else
		clearChoices()
	end
	typeText(text)
end

local function open(npc: string?)
	active = true
	currentNpc = npc
	box.Visible = true
	Session.setMode("dialogue", true)
	DialogueUI.hooks.lockMovement(true)
	DialogueUI.hooks.focusCamera(npc)
end

local function close()
	if not active then
		return
	end
	active = false
	sayMode = false
	box.Visible = false
	currentNode = nil
	clearChoices()
	GuiService.SelectedObject = nil
	DialogueUI.hooks.releaseCamera()
	DialogueUI.hooks.lockMovement(false)
	if currentNpc then
		DialogueUI.hooks.setExpression(currentNpc, "neutral")
	end
	currentNpc = nil
	Session.setMode("dialogue", false)
	DialogueUI.Closed:Fire()
end

handleResponse = function(response)
	busy = false
	if response == nil or not response.ok then
		if response and response.node and not response.node.ended then
			showNode(response.node)
		else
			close()
		end
		return
	end
	local node = response.node
	if node == nil or node.ended then
		close()
		if response.activity then
			DialogueUI.hooks.startActivity(response.activity)
		elseif response.openGift then
			DialogueUI.hooks.openGift(response.openGift)
		end
		return
	end
	showNode(node)
end

local function advance()
	if not active or busy then
		return
	end
	if typing then
		finishTyping()
		return
	end
	if sayMode then
		local done = onSayDone
		onSayDone = nil
		close()
		if done then
			done()
		end
		return
	end
	if currentNode == nil or not currentNode.canContinue then
		return
	end
	busy = true
	Audio.sfx("click")
	handleResponse(Session.request("advance"))
end

local function leave()
	if not active or busy then
		return
	end
	if sayMode then
		advance()
		return
	end
	busy = true
	handleResponse(Session.request("leaveDialogue"))
	if active then
		close()
	end
end

-- Public -------------------------------------------------------------------
function DialogueUI.isOpen(): boolean
	return active
end

local REASONS = {
	tooFar = "You need to be a little closer.",
	absent = "They're not here right now.",
	nothingToSay = "They're busy at the moment.",
	busy = "Finish what you're doing first.",
	loading = "Still loading your story…",
	rateLimited = "Slow down a little!",
	network = "Couldn't reach the server. Try again.",
}

function DialogueUI.start(npc: string, toast: ((string) -> ())?)
	if active or busy or not Session.isFree() then
		return
	end
	busy = true
	local response = Session.request("talk", { npc = npc })
	busy = false
	if not response.ok then
		if toast then
			toast(REASONS[response.reason] or "Not right now.")
		end
		return
	end
	open(npc)
	handleResponse(response)
end

-- One-off line (gift reactions, activity results). Calls onDone when closed.
function DialogueUI.say(speaker: string, text: string, emote: string?, onDone: (() -> ())?)
	if active then
		close()
	end
	open(Session.Content.Characters[speaker] and speaker or nil)
	sayMode = true
	onSayDone = onDone
	local char = Session.Content.Characters[speaker]
	showNode({
		speaker = speaker,
		speakerName = char and char.name or "",
		npc = speaker,
		emote = emote or "neutral",
		text = text,
		canContinue = true,
	})
end

function DialogueUI.init()
	local layer = Root.layers.dialogue
	box = Theme.new("TextButton", {
		Name = "DialogueBox",
		Text = "",
		AutoButtonColor = false,
		Selectable = false,
		Visible = false,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -12),
		Size = UDim2.fromScale(0.94, 0.3),
		BackgroundColor3 = Theme.Colors.paper,
		Parent = layer,
	}, {
		Theme.corner(18),
		Theme.stroke(Theme.Colors.emberDark, 3),
		Theme.new("UISizeConstraint", { MaxSize = Vector2.new(980, 260), MinSize = Vector2.new(300, 150) }),
	})

	portrait = Theme.new("ImageLabel", {
		Name = "Portrait",
		BackgroundColor3 = Theme.Colors.ember,
		Size = UDim2.fromOffset(84, 84),
		Position = UDim2.fromOffset(16, 22),
		ScaleType = Enum.ScaleType.Crop,
		Parent = box,
	}, { Theme.corner(42), Theme.stroke(Theme.Colors.white, 3) })
	portraitLetter = Theme.label({
		Name = "Letter",
		Text = "",
		Font = Theme.Fonts.title,
		TextColor3 = Theme.Colors.white,
		TextSizeBase = 40,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
		AutomaticSize = Enum.AutomaticSize.None,
		Size = UDim2.fromScale(1, 1),
		Parent = portrait,
	})

	nameplate = Theme.new("Frame", {
		Name = "Nameplate",
		BackgroundColor3 = Theme.Colors.ember,
		Position = UDim2.fromOffset(112, -18),
		Size = UDim2.fromOffset(0, 36),
		AutomaticSize = Enum.AutomaticSize.X,
		Parent = box,
	}, { Theme.corner(10), Theme.padding(6) })
	nameLabel = Theme.label({
		Name = "Name",
		Text = "",
		Font = Theme.Fonts.title,
		TextColor3 = Theme.Colors.white,
		TextSizeBase = 20,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromScale(0, 1),
		TextYAlignment = Enum.TextYAlignment.Center,
		TextWrapped = false,
		Parent = nameplate,
	})

	textLabel = Theme.label({
		Name = "Text",
		Text = "",
		RichText = true,
		TextSizeBase = 21,
		AutomaticSize = Enum.AutomaticSize.None,
		Position = UDim2.fromOffset(112, 26),
		Size = UDim2.new(1, -132, 1, -46),
		Parent = box,
	})

	continueHint = Theme.label({
		Name = "Continue",
		Text = "▼",
		Font = Theme.Fonts.title,
		TextColor3 = Theme.Colors.emberDark,
		TextSizeBase = 20,
		TextXAlignment = Enum.TextXAlignment.Right,
		AutomaticSize = Enum.AutomaticSize.None,
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -16, 1, -8),
		Size = UDim2.fromOffset(40, 24),
		Visible = false,
		Parent = box,
	})

	leaveButton = Theme.button({
		Name = "Leave",
		Text = Theme.Icons.close,
		Size = UDim2.fromOffset(40, 40),
		Position = UDim2.new(1, -52, 0, 10),
		BackgroundColor3 = Theme.Colors.panelSoft,
		TextSizeBase = 18,
		Parent = box,
	})
	leaveButton.Activated:Connect(leave)

	choiceList = Theme.new("Frame", {
		Name = "Choices",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -8, 0, -26),
		Size = UDim2.fromScale(0.62, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Visible = false,
		Parent = box,
	}, { Theme.list(6), Theme.new("UISizeConstraint", { MinSize = Vector2.new(280, 0) }) })

	box.Activated:Connect(advance)

	ContextActionService:BindActionAtPriority(
		"HearthscaleDialogue",
		function(_name, inputState, input)
			if not active then
				return Enum.ContextActionResult.Pass
			end
			if inputState ~= Enum.UserInputState.Begin then
				return Enum.ContextActionResult.Sink
			end
			local key = input.KeyCode
			local digit = ({
				[Enum.KeyCode.One] = 1,
				[Enum.KeyCode.Two] = 2,
				[Enum.KeyCode.Three] = 3,
				[Enum.KeyCode.Four] = 4,
				[Enum.KeyCode.Five] = 5,
			})[key]
			if digit then
				choose(digit)
			elseif key == Enum.KeyCode.ButtonA and GuiService.SelectedObject and choiceList.Visible then
				return Enum.ContextActionResult.Pass -- let the selected choice button handle it
			elseif key == Enum.KeyCode.ButtonB then
				leave()
			else
				advance()
			end
			return Enum.ContextActionResult.Sink
		end,
		false,
		Enum.ContextActionPriority.High.Value,
		Enum.KeyCode.Space,
		Enum.KeyCode.Return,
		Enum.KeyCode.E,
		Enum.KeyCode.ButtonA,
		Enum.KeyCode.ButtonB,
		Enum.KeyCode.One,
		Enum.KeyCode.Two,
		Enum.KeyCode.Three,
		Enum.KeyCode.Four,
		Enum.KeyCode.Five
	)
end

return DialogueUI
