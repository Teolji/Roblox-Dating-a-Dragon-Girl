--[[
	CollectGame
	Explorer: ...HearthscaleClient > UI > Minigames > CollectGame (ModuleScript)

	Firefly catching on Stargazer Hill: glowing motes appear (locally) at the
	points the server picked; walk into them. Each catch is confirmed by the
	server against your real position. Finish early any time.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Theme = require(script.Parent.Parent.Theme)
local Session = require(script.Parent.Parent.Parent.Controllers.Session)
local WorldAnchors = require(Session.Shared.WorldAnchors)

local CollectGame = {}

CollectGame.compact = true -- the host shows a slim top bar instead of a panel

function CollectGame.run(container: Frame, payload, finish: (any) -> ())
	local public = payload.public
	local total = #public.points
	local caught = 0
	local finished = false
	local pending = {}
	local motes = {}
	local started = os.clock()

	local status = Theme.label({
		Text = "",
		Font = Theme.Fonts.title,
		TextColor3 = Theme.Colors.white,
		TextSizeBase = 20,
		TextXAlignment = Enum.TextXAlignment.Center,
		LayoutOrder = 1,
		Parent = container,
	})
	local done = Theme.button({ Text = "Finish", Size = UDim2.new(1, 0, 0, 44), LayoutOrder = 2, Parent = container })

	local folder = Instance.new("Folder")
	folder.Name = "HearthscaleFireflies"
	folder.Parent = workspace

	for i, anchor in ipairs(public.points) do
		local position = WorldAnchors.position(anchor)
		if position then
			local mote = Instance.new("Part")
			mote.Name = "Firefly"
			mote.Shape = Enum.PartType.Ball
			mote.Size = Vector3.new(0.9, 0.9, 0.9)
			mote.Material = Enum.Material.Neon
			mote.Color = Color3.fromRGB(230, 255, 140)
			mote.Anchored = true
			mote.CanCollide = false
			mote.CanQuery = false
			mote.Position = position
			local light = Instance.new("PointLight")
			light.Range = 10
			light.Brightness = 2
			light.Color = mote.Color
			light.Parent = mote
			mote.Parent = folder
			if not Session.settings().reduceMotion then
				TweenService:Create(
					mote,
					TweenInfo.new(1.2 + (i % 3) * 0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
					{ Position = position + Vector3.new(0, 1.2, 0) }
				):Play()
			end
			motes[i] = mote
		end
	end

	local function complete()
		if finished then
			return
		end
		finished = true
		folder:Destroy()
		finish({})
	end
	done.Activated:Connect(complete)

	local connection
	connection = RunService.Heartbeat:Connect(function()
		if finished then
			connection:Disconnect()
			return
		end
		local remaining = math.max(0, public.timeLimit - (os.clock() - started))
		status.Text = `{public.label or "Collected"}: {caught}/{total}   ·   {math.ceil(remaining)}s`
		if remaining <= 0 or caught >= total then
			complete()
			return
		end
		local character = Players.LocalPlayer.Character
		local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if root == nil then
			return
		end
		for i, mote in pairs(motes) do
			if not pending[i] and (mote.Position - root.Position).Magnitude < 7 then
				pending[i] = true
				task.spawn(function()
					local result = Session.request("activityCollect", { id = payload.id, index = i })
					if result.ok then
						caught = result.count or (caught + 1)
						mote:Destroy()
						motes[i] = nil
					else
						task.wait(1) -- brief cooldown before retrying this mote
						pending[i] = nil
					end
				end)
			end
		end
	end)
	return { action = complete }
end

return CollectGame
