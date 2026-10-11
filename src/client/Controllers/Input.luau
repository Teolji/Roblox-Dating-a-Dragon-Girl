--[[
	Input
	Explorer: StarterPlayer > StarterPlayerScripts > HearthscaleClient > Controllers > Input (ModuleScript)

	Hotkeys (keyboard + gamepad) for menus and movement locking during
	dialogue and minigames. Touch players use the HUD buttons; Roblox's
	thumbstick/jump and ProximityPrompt tap targets work unchanged.

	Keyboard: J journal · B bag · K bond · P settings
	Gamepad:  DPadUp journal · DPadLeft bag · DPadRight bond · DPadDown settings
	(E / gamepad X talks via ProximityPrompt; I/O are left for camera zoom.)
]]

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")

local Session = require(script.Parent.Session)

local Input = {}

local controls = nil
local lockCount = 0

local function getControls()
	if controls == nil then
		local ok, result = pcall(function()
			local playerModule = Players.LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule", 5)
			return playerModule and require(playerModule):GetControls()
		end)
		controls = ok and result or false
	end
	return controls or nil
end

-- Reference-counted so overlapping UIs don't unlock each other.
function Input.lockMovement(on: boolean)
	lockCount = math.max(0, lockCount + (on and 1 or -1))
	local c = getControls()
	local locked = lockCount > 0
	if c then
		if locked then
			c:Disable()
		else
			c:Enable()
		end
	else
		local character = Players.LocalPlayer.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = locked and 0 or 16
		end
	end
end

function Input.bindMenus(actions: { [string]: () -> () })
	local map = {
		journal = { Enum.KeyCode.J, Enum.KeyCode.DPadUp },
		bag = { Enum.KeyCode.B, Enum.KeyCode.DPadLeft },
		bond = { Enum.KeyCode.K, Enum.KeyCode.DPadRight },
		settings = { Enum.KeyCode.P, Enum.KeyCode.DPadDown },
	}
	for name, keys in pairs(map) do
		ContextActionService:BindAction("Hearthscale_" .. name, function(_action, inputState)
			if
				inputState == Enum.UserInputState.Begin
				and not Session.mode("dialogue")
				and not Session.mode("minigame")
			then
				actions[name]()
				return Enum.ContextActionResult.Sink
			end
			return Enum.ContextActionResult.Pass
		end, false, table.unpack(keys))
	end
	ContextActionService:BindAction("Hearthscale_closeMenu", function(_action, inputState)
		if inputState == Enum.UserInputState.Begin and Session.mode("menu") then
			actions.close()
			return Enum.ContextActionResult.Sink
		end
		return Enum.ContextActionResult.Pass
	end, false, Enum.KeyCode.ButtonB)
end

return Input
