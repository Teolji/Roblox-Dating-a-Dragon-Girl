--[[
	PlaceholderRig
	Explorer: StarterPlayer > StarterPlayerScripts > HearthscaleClient > Controllers > PlaceholderRig (ModuleScript)

	PLACEHOLDER CHARACTER MODELS. Builds a stylised block figure from the
	`rig` colours in Content.Characters: dragons get horns, cheek and arm
	scales, a jointed tail and a smoke emitter; humans get hats, aprons or
	goggles. Faces are text-drawn expressions on the head.

	Joints are Motor6Ds named Waist, Neck, LeftShoulder, RightShoulder,
	LeftHip, RightHip, Tail1..TailN (Part0 = parent part), so Expressions can
	animate them. A real model placed at ReplicatedStorage.HearthscaleAssets.
	NPCs.<npcId> replaces this automatically (see docs/05-Assets.md).
]]

local Theme = require(script.Parent.Parent.UI.Theme)

local PlaceholderRig = {}

local function newPart(model: Model, name: string, size: Vector3, color: Color3, shape: Enum.PartType?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Anchored = false
	p.CastShadow = true
	if shape then
		p.Shape = shape
	end
	p.Parent = model
	return p
end

local function joint(name: string, part0: BasePart, part1: BasePart, c0: CFrame, c1: CFrame?): Motor6D
	local m = Instance.new("Motor6D")
	m.Name = name
	m.Part0 = part0
	m.Part1 = part1
	m.C0 = c0
	m.C1 = c1 or CFrame.new()
	m.Parent = part0
	return m
end

local function weld(part0: BasePart, part1: BasePart, c0: CFrame)
	local w = Instance.new("Weld")
	w.Part0 = part0
	w.Part1 = part1
	w.C0 = c0
	w.Parent = part0
end

local function faceGui(head: BasePart)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "Face"
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 60
	gui.LightInfluence = 0.6
	local eyes = Instance.new("TextLabel")
	eyes.Name = "Eyes"
	eyes.BackgroundTransparency = 1
	eyes.Size = UDim2.fromScale(1, 0.42)
	eyes.Position = UDim2.fromScale(0, 0.22)
	eyes.Font = Enum.Font.FredokaOne
	eyes.TextScaled = true
	eyes.TextColor3 = Color3.fromRGB(40, 28, 24)
	eyes.Text = "o   o"
	eyes.Parent = gui
	local mouth = Instance.new("TextLabel")
	mouth.Name = "Mouth"
	mouth.BackgroundTransparency = 1
	mouth.Size = UDim2.fromScale(0.5, 0.26)
	mouth.Position = UDim2.fromScale(0.25, 0.62)
	mouth.Font = Enum.Font.FredokaOne
	mouth.TextScaled = true
	mouth.TextColor3 = Color3.fromRGB(120, 50, 50)
	mouth.Text = "—"
	mouth.Parent = gui
	gui.Parent = head
end

local function nameTag(head: BasePart, name: string, title: string?)
	local gui = Instance.new("BillboardGui")
	gui.Name = "NameTag"
	gui.Size = UDim2.fromOffset(200, 46)
	gui.StudsOffset = Vector3.new(0, 2.6, 0)
	gui.MaxDistance = 70
	gui.LightInfluence = 0
	gui.Adornee = head
	local nameLabel = Instance.new("TextLabel")
	nameLabel.BackgroundTransparency = 1
	nameLabel.Size = UDim2.fromScale(1, 0.6)
	nameLabel.Font = Enum.Font.FredokaOne
	nameLabel.TextScaled = true
	nameLabel.TextColor3 = Color3.fromRGB(255, 244, 226)
	nameLabel.TextStrokeTransparency = 0.4
	nameLabel.Text = name
	nameLabel.Parent = gui
	local titleLabel = nameLabel:Clone()
	titleLabel.Size = UDim2.fromScale(1, 0.4)
	titleLabel.Position = UDim2.fromScale(0, 0.6)
	titleLabel.Text = title or ""
	titleLabel.TextColor3 = Color3.fromRGB(240, 210, 170)
	titleLabel.Parent = gui
	gui.Parent = head
	local marker = Instance.new("BillboardGui")
	marker.Name = "QuestMarker"
	marker.Size = UDim2.fromOffset(44, 44)
	marker.StudsOffset = Vector3.new(0, 4.6, 0)
	marker.AlwaysOnTop = true
	marker.MaxDistance = 250
	marker.LightInfluence = 0
	marker.Adornee = head
	marker.Enabled = false
	local mark = Instance.new("TextLabel")
	mark.BackgroundTransparency = 1
	mark.Size = UDim2.fromScale(1, 1)
	mark.Font = Enum.Font.FredokaOne
	mark.TextScaled = true
	mark.TextColor3 = Color3.fromRGB(255, 200, 80)
	mark.TextStrokeTransparency = 0.2
	mark.Text = "!"
	mark.Parent = marker
	marker.Parent = head
end

function PlaceholderRig.build(npcId: string, char): Model
	local spec = char.rig or {}
	local s = spec.height or 1
	local model = Instance.new("Model")
	model.Name = npcId

	local skin = Theme.hex(spec.skin)
	local outfit = Theme.hex(spec.outfit)
	local accent = Theme.hex(spec.accent)
	local hair = Theme.hex(spec.hair)
	local scales = Theme.hex(spec.scales or spec.skin)
	local horns = Theme.hex(spec.horns or spec.hair)

	local root = newPart(model, "Root", Vector3.new(2, 2, 1) * s, outfit)
	root.Transparency = 1
	root.Anchored = true
	model.PrimaryPart = root

	local torso = newPart(model, "Torso", Vector3.new(2.1, 2.3, 1.15) * s, outfit)
	joint("Waist", root, torso, CFrame.new(0, 1.15 * s, 0))
	local belt = newPart(model, "Belt", Vector3.new(2.2, 0.35, 1.25) * s, accent)
	weld(torso, belt, CFrame.new(0, -0.8 * s, 0))

	local head = newPart(model, "Head", Vector3.new(1.75, 1.75, 1.55) * s, skin)
	joint("Neck", torso, head, CFrame.new(0, 2.05 * s, 0))
	faceGui(head)
	local hairTop = newPart(model, "Hair", Vector3.new(1.85, 0.55, 1.65) * s, hair)
	weld(head, hairTop, CFrame.new(0, 0.75 * s, 0.05 * s))
	local hairBack = newPart(model, "HairBack", Vector3.new(1.85, 1.6, 0.4) * s, hair)
	weld(head, hairBack, CFrame.new(0, 0.05 * s, 0.75 * s))

	-- Blush (shown for flustered/tender)
	for _, side in ipairs({ -1, 1 }) do
		local blush = newPart(
			model,
			side < 0 and "BlushL" or "BlushR",
			Vector3.new(0.35, 0.18, 0.05) * s,
			Color3.fromRGB(240, 120, 130)
		)
		blush.Transparency = 1
		weld(head, blush, CFrame.new(side * 0.55 * s, -0.25 * s, -0.79 * s))
	end

	for _, side in ipairs({ -1, 1 }) do
		local arm = newPart(model, side < 0 and "LeftArm" or "RightArm", Vector3.new(0.75, 2.2, 0.75) * s, outfit)
		joint(
			side < 0 and "LeftShoulder" or "RightShoulder",
			torso,
			arm,
			CFrame.new(side * 1.45 * s, 0.85 * s, 0),
			CFrame.new(0, 0.85 * s, 0)
		)
		local hand = newPart(model, side < 0 and "LeftHand" or "RightHand", Vector3.new(0.6, 0.5, 0.6) * s, skin)
		weld(arm, hand, CFrame.new(0, -1.25 * s, 0))
		local leg =
			newPart(model, side < 0 and "LeftLeg" or "RightLeg", Vector3.new(0.9, 2.1, 0.9) * s, Theme.hex("#3A2E2A"))
		joint(
			side < 0 and "LeftHip" or "RightHip",
			root,
			leg,
			CFrame.new(side * 0.5 * s, 0, 0),
			CFrame.new(0, 1.05 * s, 0)
		)
	end

	if spec.kind == "dragon" then
		-- Horns: two angled cones built from wedges.
		for _, side in ipairs({ -1, 1 }) do
			local base = newPart(model, "Horn", Vector3.new(0.35, 1.1, 0.35) * s, horns)
			local tilt = spec.hornStyle == "sweep" and 55 or 30
			weld(
				head,
				base,
				CFrame.new(side * 0.55 * s, 1.05 * s, 0.25 * s) * CFrame.Angles(math.rad(20), 0, math.rad(-side * tilt))
			)
			local tip = newPart(model, "HornTip", Vector3.new(0.25, 0.8, 0.25) * s, horns)
			weld(
				base,
				tip,
				CFrame.new(0, 0.85 * s, 0) * CFrame.Angles(math.rad(spec.hornStyle == "curl" and -40 or -15), 0, 0)
			)
			-- Cheek scales
			local cheek = newPart(model, "CheekScale", Vector3.new(0.3, 0.3, 0.06) * s, scales)
			weld(head, cheek, CFrame.new(side * 0.7 * s, 0.05 * s, -0.79 * s) * CFrame.Angles(0, 0, math.rad(45)))
		end
		-- Forearm scales
		for _, armName in ipairs({ "LeftArm", "RightArm" }) do
			local arm = model:FindFirstChild(armName) :: BasePart
			local plate = newPart(model, "ArmScales", Vector3.new(0.8, 0.9, 0.8) * s, scales)
			weld(arm, plate, CFrame.new(0, -0.55 * s, 0))
		end
		-- Jointed tail
		local previous: BasePart = root
		local count = spec.tail or 4
		for i = 1, count do
			local size = (1 - (i - 1) / (count + 1)) * 0.9
			local segment = newPart(model, "Tail" .. i, Vector3.new(size, size, 1.4) * s, scales, Enum.PartType.Block)
			local c0 = if i == 1
				then CFrame.new(0, 0.6 * s, 0.6 * s) * CFrame.Angles(math.rad(25), 0, 0)
				else CFrame.new(0, 0, 0.65 * s)
			joint("Tail" .. i, previous, segment, c0, CFrame.new(0, 0, -0.65 * s))
			previous = segment
		end
		local tip = newPart(model, "TailTip", Vector3.new(0.5, 0.5, 0.5) * s, accent, Enum.PartType.Ball)
		weld(previous, tip, CFrame.new(0, 0, 0.75 * s))
		-- Smoke puffs from the nostrils (used by flustered/annoyed).
		local nose = Instance.new("Attachment")
		nose.Name = "Nose"
		nose.Position = Vector3.new(0, -0.2 * s, -0.8 * s)
		nose.Parent = head
		local smoke = Instance.new("ParticleEmitter")
		smoke.Name = "Smoke"
		smoke.Enabled = false
		smoke.Rate = 0
		smoke.Lifetime = NumberRange.new(0.8, 1.4)
		smoke.Speed = NumberRange.new(2, 4)
		smoke.SpreadAngle = Vector2.new(20, 20)
		smoke.Acceleration = Vector3.new(0, 3, 0)
		smoke.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1.4) })
		smoke.Transparency =
			NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1) })
		smoke.Color = ColorSequence.new(Color3.fromRGB(200, 196, 196))
		smoke.EmissionDirection = Enum.NormalId.Front
		smoke.Parent = nose
	end

	if spec.spectacles then
		local glasses = newPart(model, "Spectacles", Vector3.new(1.3, 0.3, 0.08) * s, Color3.fromRGB(40, 30, 28))
		glasses.Transparency = 0.2
		weld(head, glasses, CFrame.new(0, 0.2 * s, -0.8 * s))
	end
	if spec.cloak then
		local cloak = newPart(model, "Cloak", Vector3.new(2.6, 3.6, 0.25) * s, accent)
		weld(torso, cloak, CFrame.new(0, -0.4 * s, 0.7 * s))
	end
	if spec.apron then
		local apron = newPart(model, "Apron", Vector3.new(1.7, 2.6, 0.1) * s, accent)
		weld(torso, apron, CFrame.new(0, -0.4 * s, -0.62 * s))
	end
	if spec.topHat then
		local brim = newPart(model, "HatBrim", Vector3.new(2.2, 0.15, 2.0) * s, Color3.fromRGB(30, 30, 34))
		weld(head, brim, CFrame.new(0, 1.0 * s, 0))
		local crown = newPart(model, "HatCrown", Vector3.new(1.4, 1.5, 1.3) * s, Color3.fromRGB(30, 30, 34))
		weld(brim, crown, CFrame.new(0, 0.8 * s, 0))
		local band = newPart(model, "HatBand", Vector3.new(1.45, 0.25, 1.35) * s, accent)
		weld(crown, band, CFrame.new(0, -0.5 * s, 0))
	end
	if spec.goggles then
		local strap = newPart(model, "Goggles", Vector3.new(1.85, 0.35, 1.65) * s, accent)
		weld(head, strap, CFrame.new(0, 0.6 * s, 0))
	end

	nameTag(head, char.name, char.title)
	return model
end

-- Height from the root (hip joint) down to the feet, for ground placement.
function PlaceholderRig.hipHeight(char): number
	local s = (char.rig and char.rig.height) or 1
	return 2.1 * s
end

return PlaceholderRig
