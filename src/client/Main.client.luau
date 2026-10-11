--[[
	Main (client bootstrap)
	Explorer: StarterPlayer > StarterPlayerScripts > HearthscaleClient > Main (LocalScript)

	Waits for the player's story to load, then builds the UI and starts the
	local world (NPCs, pickups, waypoint, ambience). Modules talk to each
	other through the small hook tables wired up here.
]]

local StarterGui = game:GetService("StarterGui")

local Controllers = script.Parent:WaitForChild("Controllers")
local UI = script.Parent:WaitForChild("UI")

local Session = require(Controllers.Session)
local Audio = require(Controllers.Audio)
local Input = require(Controllers.Input)
local NPCController = require(Controllers.NPCController)
local CameraController = require(Controllers.CameraController)
local WorldObjects = require(Controllers.WorldObjects)
local Waypoint = require(Controllers.Waypoint)
local Ambience = require(Controllers.Ambience)

local Theme = require(UI.Theme)
local Root = require(UI.Root)
local HUD = require(UI.HUD)
local Toasts = require(UI.Toasts)
local DialogueUI = require(UI.DialogueUI)
local JournalUI = require(UI.JournalUI)
local InventoryUI = require(UI.InventoryUI)
local BondUI = require(UI.BondUI)
local SettingsUI = require(UI.SettingsUI)
local EndingUI = require(UI.EndingUI)
local IntroUI = require(UI.IntroUI)
local MinigameHost = require(UI.Minigames.MinigameHost)

-- The game has no tools; free the number keys for dialogue choices.
pcall(function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
end)

Root.init()
local loading = Theme.label({
	Text = "Loading your story…",
	Font = Theme.Fonts.title,
	TextColor3 = Theme.Colors.white,
	TextStrokeTransparency = 0.4,
	TextSizeBase = 24,
	TextXAlignment = Enum.TextXAlignment.Center,
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromScale(0.8, 0),
	Parent = Root.layers.cinematic,
})
Session.init()
loading:Destroy()
Theme.setUserScale(Session.settings().uiScale or 1)

-- Ending cards wait until conversations/minigames close.
local pendingEnding = nil
local function tryShowEnding()
	if pendingEnding and not DialogueUI.isOpen() and not MinigameHost.isRunning() then
		local ending = pendingEnding
		pendingEnding = nil
		task.wait(0.4)
		EndingUI.show(ending)
	end
end

local function startStoryIntroIfNeeded()
	local state = Session.state
	local arrival = state and state.quests.q_arrival
	if arrival and arrival.s == "active" and not state.flags.intro_seen then
		IntroUI.play()
	end
end

-- UI ------------------------------------------------------------------------
Toasts.init()
DialogueUI.init()
JournalUI.init()
InventoryUI.init()
BondUI.init()
SettingsUI.init()

HUD.init({
	journal = JournalUI.toggle,
	bag = InventoryUI.toggle,
	bond = BondUI.toggle,
	settings = SettingsUI.toggle,
})

DialogueUI.hooks = {
	setExpression = NPCController.setExpression,
	focusCamera = CameraController.focus,
	releaseCamera = CameraController.release,
	lockMovement = Input.lockMovement,
	startActivity = function(payload)
		task.spawn(MinigameHost.start, payload)
	end,
	openGift = InventoryUI.openGift,
}
InventoryUI.hooks = {
	say = function(speaker, text, emote)
		DialogueUI.say(speaker, text, emote)
	end,
	toast = Toasts.show,
}
MinigameHost.hooks = {
	lockMovement = Input.lockMovement,
	say = DialogueUI.say,
	startActivity = function(payload)
		task.spawn(MinigameHost.start, payload)
	end,
}
JournalUI.hooks = { showEnding = EndingUI.show }
SettingsUI.hooks = {
	applied = function(settings)
		Theme.setUserScale(settings.uiScale or 1)
		Audio.applyVolume()
	end,
	newStory = startStoryIntroIfNeeded,
}
EndingUI.hooks = { newStory = startStoryIntroIfNeeded }

Input.bindMenus({
	journal = JournalUI.toggle,
	bag = InventoryUI.toggle,
	bond = BondUI.toggle,
	settings = SettingsUI.toggle,
	close = Root.close,
})

-- World -----------------------------------------------------------------------
NPCController.init(function(npcId)
	DialogueUI.start(npcId, Toasts.show)
end)
WorldObjects.init({
	toast = Toasts.show,
	startActivity = function(payload)
		task.spawn(MinigameHost.start, payload)
	end,
})
Waypoint.init()
Ambience.init()

Session.EndingShown:Connect(function(ending)
	pendingEnding = ending
	tryShowEnding()
end)
DialogueUI.Closed:Connect(tryShowEnding)
Session.ModeChanged:Connect(function(name, on)
	if name == "minigame" and not on then
		tryShowEnding()
	end
end)
Session.StateChanged:Connect(function(state)
	Theme.setUserScale(state.settings and state.settings.uiScale or 1)
end)

startStoryIntroIfNeeded()
