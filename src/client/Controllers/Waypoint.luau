--[[
	Waypoint
	Explorer: StarterPlayer > StarterPlayerScripts > HearthscaleClient > Controllers > Waypoint (ModuleScript)

	A floating marker toward whatever the current objective needs (an NPC at
	their current station, the nearest pickup, a location), with distance.
	Helps on small phone screens where signposts are hard to read.
	Toggle: Settings > "Objective marker".
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Session = require(script.Parent.Session)
local Objectives = require(script.Parent.Objectives)

local Waypoint = {}

local holder: Part
local gui: BillboardGui
local label: TextLabel
local targetPosition: Vector3? = nil
local targetName: string? = nil
local lastUpdate = 0

local function rootPosition(): Vector3?
	local character = Players.LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return root and (root :: BasePart).Position
end

function Waypoint.refresh()
	if Session.state == nil then
		return
	end
	targetPosition, targetName = Objectives.target(Session.state, rootPosition())
end

function Waypoint.init()
	holder = Instance.new("Part")
	holder.Name = "HearthscaleWaypoint"
	holder.Size = Vector3.new(0.2, 0.2, 0.2)
	holder.Transparency = 1
	holder.Anchored = true
	holder.CanCollide = false
	holder.CanQuery = false
	holder.CanTouch = false
	holder.Parent = workspace

	gui = Instance.new("BillboardGui")
	gui.Name = "Waypoint"
	gui.AlwaysOnTop = true
	gui.Size = UDim2.fromOffset(220, 40)
	gui.LightInfluence = 0
	gui.Adornee = holder
	gui.Parent = holder
	label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = Color3.fromRGB(255, 214, 120)
	label.TextStrokeTransparency = 0.3
	label.Parent = gui

	Session.StateChanged:Connect(Waypoint.refresh)
	Waypoint.refresh()

	RunService.Heartbeat:Connect(function()
		local now = os.clock()
		if now - lastUpdate > 2 then
			-- Re-pick "nearest pickup" targets as the player moves.
			lastUpdate = now
			Waypoint.refresh()
		end
		local position = rootPosition()
		local show = targetPosition ~= nil
			and position ~= nil
			and Session.isFree()
			and Session.settings().showWaypoint ~= false
		if show then
			local distance = ((targetPosition :: Vector3) - (position :: Vector3)).Magnitude
			show = distance > 14
			holder.Position = targetPosition :: Vector3
			label.Text = string.format("◆ %s · %dm", targetName or "Objective", math.floor(distance / 3.57))
		end
		gui.Enabled = show
	end)
end

return Waypoint
