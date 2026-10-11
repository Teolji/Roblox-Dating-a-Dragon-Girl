--[[
	WorldAnchors
	Explorer: ReplicatedStorage > Hearthscale > WorldAnchors (ModuleScript)

	Resolves an anchor name to a CFrame. A Part with that name under
	Workspace > HearthscaleWorld > Anchors wins (so level designers can move
	things in Studio); otherwise the position from Content.World.Anchors is
	used. Server and client resolve identically, which keeps proximity checks
	and client-side NPC placement in agreement.
]]

local Config = require(script.Parent.Config)
local Content = require(script.Parent.Content)

local WorldAnchors = {}

local function anchorsFolder(): Instance?
	local world = workspace:FindFirstChild(Config.WorldFolderName)
	return world and world:FindFirstChild(Config.AnchorsFolderName)
end

function WorldAnchors.dataCFrame(name: string): CFrame?
	local a = Content.Anchors[name]
	if a == nil then
		return nil
	end
	local position = Vector3.new(a[1], a[2], a[3])
	return CFrame.new(position) * CFrame.Angles(0, math.rad(a[4] or 0), 0)
end

function WorldAnchors.get(name: string?): CFrame?
	if name == nil then
		return nil
	end
	local folder = anchorsFolder()
	local part = folder and folder:FindFirstChild(name)
	if part and part:IsA("BasePart") then
		return part.CFrame
	end
	return WorldAnchors.dataCFrame(name)
end

function WorldAnchors.position(name: string?): Vector3?
	local cf = WorldAnchors.get(name)
	return cf and cf.Position
end

return WorldAnchors
