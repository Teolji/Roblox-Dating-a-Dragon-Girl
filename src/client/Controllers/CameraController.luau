--[[
	CameraController
	Explorer: StarterPlayer > StarterPlayerScripts > HearthscaleClient > Controllers > CameraController (ModuleScript)

	Frames the speaking NPC and the player during dialogue (over-the-shoulder),
	then hands control back. Respects Settings: "Cinematic camera" off or
	"Reduce motion" on keeps the normal camera.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Session = require(script.Parent.Session)
local NPCController = require(script.Parent.NPCController)

local CameraController = {}

local focused = false
local savedType: Enum.CameraType? = nil

function CameraController.focus(npcId: string?)
	local settings = Session.settings()
	local character = Players.LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if npcId and root then
		-- NPC turns to face the player regardless of camera settings.
		NPCController.lookAt(npcId, root.Position)
	end
	if npcId == nil or settings.cinematicCamera == false or settings.reduceMotion then
		return
	end
	local model = NPCController.model(npcId)
	local head = model and model:FindFirstChild("Head", true) :: BasePart?
	local camera = workspace.CurrentCamera
	if head == nil or root == nil or camera == nil then
		return
	end
	if not focused then
		savedType = camera.CameraType
	end
	focused = true
	camera.CameraType = Enum.CameraType.Scriptable
	local npcPos = head.Position
	local playerPos = root.Position + Vector3.new(0, 2, 0)
	local toNpc = (npcPos - playerPos)
	local flat = Vector3.new(toNpc.X, 0, toNpc.Z)
	if flat.Magnitude < 0.1 then
		flat = Vector3.new(0, 0, -1)
	end
	flat = flat.Unit
	local right = flat:Cross(Vector3.yAxis)
	local eye = playerPos - flat * 7 + right * 3.5 + Vector3.new(0, 2.5, 0)
	local goal = CFrame.lookAt(eye, npcPos - Vector3.new(0, 0.6, 0))
	TweenService:Create(camera, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { CFrame = goal })
		:Play()
end

function CameraController.release()
	for npcId in pairs(Session.Content.Characters) do
		NPCController.lookAt(npcId, nil)
	end
	if not focused then
		return
	end
	focused = false
	local camera = workspace.CurrentCamera
	if camera then
		camera.CameraType = savedType or Enum.CameraType.Custom
		local character = Players.LocalPlayer.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			camera.CameraSubject = humanoid
		end
	end
end

return CameraController
