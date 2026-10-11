--[[
	WorldBuilder
	Explorer: ServerScriptService > HearthscaleServer > Services > WorldBuilder (ModuleScript)

	PLACEHOLDER WORLD. Builds a blockout of Kettlewick (village square,
	Keeping House, bakery, town hall, workshop, Mirror Pond, Glowcap Woods,
	Old Bridge ruins, Stargazer Hill and the Hearthpeak trail) out of plain
	parts, so the full story is playable before any art exists.

	If Workspace already contains a model/folder named Config.WorldFolderName
	(your real map), nothing is built — only missing anchor parts are added.
	To replace the blockout: run once, copy Workspace.HearthscaleWorld into
	your place file, edit freely, then keep it (the builder will skip it).

	Anchors live in a Model with ModelStreamingMode = Persistent so clients
	always have them even with StreamingEnabled.
]]

local Lighting = game:GetService("Lighting")

local WorldBuilder = {}

local Palette = {
	grass = Color3.fromRGB(122, 163, 86),
	path = Color3.fromRGB(170, 152, 120),
	cobble = Color3.fromRGB(156, 146, 132),
	wood = Color3.fromRGB(122, 84, 52),
	darkWood = Color3.fromRGB(78, 54, 36),
	plaster = Color3.fromRGB(239, 226, 200),
	roofRed = Color3.fromRGB(168, 72, 52),
	roofBlue = Color3.fromRGB(70, 96, 140),
	roofGreen = Color3.fromRGB(78, 120, 82),
	stone = Color3.fromRGB(128, 126, 122),
	rock = Color3.fromRGB(104, 98, 92),
	water = Color3.fromRGB(86, 152, 196),
	leaves = Color3.fromRGB(70, 122, 66),
	leavesDark = Color3.fromRGB(52, 96, 58),
	charcoal = Color3.fromRGB(40, 35, 33),
	lantern = Color3.fromRGB(255, 196, 110),
	snow = Color3.fromRGB(236, 240, 245),
	balloon = Color3.fromRGB(214, 86, 64),
	balloonStripe = Color3.fromRGB(240, 200, 90),
}

local worldFolder: Instance

local function part(props: { [string]: any }): BasePart
	local className = props.ClassName or "Part"
	local p = Instance.new(className) :: BasePart
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for key, value in pairs(props) do
		if key ~= "ClassName" and key ~= "Parent" then
			(p :: any)[key] = value
		end
	end
	p.Parent = props.Parent or worldFolder
	return p
end

local function group(name: string, parent: Instance?): Model
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = parent or worldFolder
	return m
end

-- Flat strip between two ground points.
local function pathStrip(a: Vector3, b: Vector3, width: number, parent: Instance, color: Color3?)
	local mid = (a + b) / 2
	local length = (b - a).Magnitude
	part({
		Name = "Path",
		Size = Vector3.new(width, 0.2, length + width * 0.5),
		CFrame = CFrame.lookAt(mid + Vector3.new(0, 0.05, 0), b + Vector3.new(0, 0.05, 0)),
		Material = Enum.Material.Slate,
		Color = color or Palette.path,
		Parent = parent,
	})
end

-- Walkable slab whose top surface runs from a to b.
local function ramp(a: Vector3, b: Vector3, width: number, parent: Instance)
	local thickness = 2
	local cf = CFrame.lookAt((a + b) / 2, b)
	cf = cf * CFrame.new(0, -thickness / 2, 0)
	part({
		Name = "Ramp",
		Size = Vector3.new(width, thickness, (b - a).Magnitude + 0.5),
		CFrame = cf,
		Material = Enum.Material.Slate,
		Color = Palette.path,
		Parent = parent,
	})
end

local function disc(center: Vector3, diameter: number, height: number, props)
	props = props or {}
	props.Shape = Enum.PartType.Cylinder
	props.Size = Vector3.new(height, diameter, diameter)
	props.CFrame = CFrame.new(center) * CFrame.Angles(0, 0, math.rad(90))
	return part(props)
end

local function label(adornee: BasePart, text: string, offset: number)
	local gui = Instance.new("BillboardGui")
	gui.Name = "AreaLabel"
	gui.Size = UDim2.fromOffset(260, 44)
	gui.StudsOffset = Vector3.new(0, offset, 0)
	gui.MaxDistance = 160
	gui.LightInfluence = 0
	gui.Adornee = adornee
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.Font = Enum.Font.FredokaOne
	t.TextScaled = true
	t.TextColor3 = Color3.fromRGB(255, 246, 228)
	t.TextStrokeTransparency = 0.4
	t.Text = text
	t.Parent = gui
	gui.Parent = adornee
end

local function signText(board: BasePart, text: string)
	for _, face in ipairs({ Enum.NormalId.Front, Enum.NormalId.Back }) do
		local gui = Instance.new("SurfaceGui")
		gui.Face = face
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 40
		gui.LightInfluence = 0.3
		local t = Instance.new("TextLabel")
		t.Size = UDim2.fromScale(1, 1)
		t.BackgroundTransparency = 1
		t.Font = Enum.Font.FredokaOne
		t.TextScaled = true
		t.TextColor3 = Color3.fromRGB(255, 240, 210)
		t.Text = text
		t.Parent = gui
		gui.Parent = board
	end
end

local function signpost(position: Vector3, facing: Vector3, text: string, parent: Instance)
	part({
		Name = "Post",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(7, 0.6, 0.6),
		CFrame = CFrame.new(position + Vector3.new(0, 3.5, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Material = Enum.Material.Wood,
		Color = Palette.darkWood,
		Parent = parent,
	})
	local boardPos = position + Vector3.new(0, 6, 0)
	local board = part({
		Name = "Sign",
		Size = Vector3.new(7, 1.6, 0.3),
		CFrame = CFrame.lookAt(boardPos, Vector3.new(facing.X, boardPos.Y, facing.Z)),
		Material = Enum.Material.WoodPlanks,
		Color = Palette.wood,
		Parent = parent,
	})
	signText(board, text)
end

local function tree(position: Vector3, scale: number, parent: Instance)
	local height = 10 * scale
	part({
		Name = "Trunk",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(height, 2 * scale, 2 * scale),
		CFrame = CFrame.new(position + Vector3.new(0, height / 2, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Material = Enum.Material.Wood,
		Color = Palette.darkWood,
		Parent = parent,
	})
	for i, offset in ipairs({ Vector3.new(0, 0, 0), Vector3.new(2, -2, 1), Vector3.new(-2, -1.5, -1) }) do
		local size = (12 - i * 1.5) * scale
		part({
			Name = "Leaves",
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(size, size, size),
			Position = position + Vector3.new(0, height + 2 * scale, 0) + offset * scale,
			Material = Enum.Material.Grass,
			Color = if i == 1 then Palette.leaves else Palette.leavesDark,
			CanCollide = false,
			Parent = parent,
		})
	end
end

local function lanternPost(position: Vector3, parent: Instance)
	part({
		Name = "LanternPost",
		Size = Vector3.new(0.6, 9, 0.6),
		Position = position + Vector3.new(0, 4.5, 0),
		Material = Enum.Material.Metal,
		Color = Palette.charcoal,
		Parent = parent,
	})
	local lamp = part({
		Name = "Lantern",
		Size = Vector3.new(1.4, 1.8, 1.4),
		Position = position + Vector3.new(0, 9.6, 0),
		Material = Enum.Material.Neon,
		Color = Palette.lantern,
		Parent = parent,
	})
	local light = Instance.new("PointLight")
	light.Range = 16
	light.Brightness = 1.2
	light.Color = Palette.lantern
	light.Parent = lamp
end

-- Simple building: four walls (door gap in the front), floor and roof.
-- `front` is the outward direction of the entrance: "+X", "-X", "+Z", "-Z".
local function building(spec)
	local m = group(spec.name)
	local c, w, d, h = spec.center, spec.width, spec.depth, spec.height
	local t = 1
	part({
		Name = "Floor",
		Size = Vector3.new(w, 0.4, d),
		Position = c + Vector3.new(0, 0.2, 0),
		Material = Enum.Material.WoodPlanks,
		Color = Palette.wood,
		Parent = m,
	})
	local walls = {
		["+X"] = { CFrame.new(c + Vector3.new(w / 2, h / 2, 0)), Vector3.new(t, h, d) },
		["-X"] = { CFrame.new(c + Vector3.new(-w / 2, h / 2, 0)), Vector3.new(t, h, d) },
		["+Z"] = { CFrame.new(c + Vector3.new(0, h / 2, d / 2)), Vector3.new(w, h, t) },
		["-Z"] = { CFrame.new(c + Vector3.new(0, h / 2, -d / 2)), Vector3.new(w, h, t) },
	}
	for side, wall in pairs(walls) do
		if side ~= spec.front then
			part({
				Name = "Wall",
				Size = wall[2],
				CFrame = wall[1],
				Material = spec.wallMaterial or Enum.Material.SmoothPlastic,
				Color = spec.wallColor or Palette.plaster,
				Parent = m,
			})
		elseif not spec.openFront then
			-- Front wall split around a doorway.
			local along = (side == "+X" or side == "-X") and "Z" or "X"
			local length = along == "Z" and d or w
			local doorWidth = 6
			local segment = (length - doorWidth) / 2
			for _, sign in ipairs({ -1, 1 }) do
				local offset = sign * (doorWidth / 2 + segment / 2)
				local pos = wall[1].Position + (along == "Z" and Vector3.new(0, 0, offset) or Vector3.new(offset, 0, 0))
				part({
					Name = "Wall",
					Size = along == "Z" and Vector3.new(t, h, segment) or Vector3.new(segment, h, t),
					Position = pos,
					Material = spec.wallMaterial or Enum.Material.SmoothPlastic,
					Color = spec.wallColor or Palette.plaster,
					Parent = m,
				})
			end
			local lintelPos = wall[1].Position + Vector3.new(0, h / 2 - 2, 0)
			part({
				Name = "Lintel",
				Size = along == "Z" and Vector3.new(t, 4, doorWidth) or Vector3.new(doorWidth, 4, t),
				Position = lintelPos,
				Material = spec.wallMaterial or Enum.Material.SmoothPlastic,
				Color = spec.wallColor or Palette.plaster,
				Parent = m,
			})
		end
	end
	-- Pitched roof from two slabs.
	local roofHeight = spec.roofHeight or 6
	local span = (spec.ridgeAlongX and d or w) / 2 + 1.5
	local slope = math.atan2(roofHeight, span)
	local slabLength = math.sqrt(span * span + roofHeight * roofHeight)
	for _, sign in ipairs({ -1, 1 }) do
		local cf
		if spec.ridgeAlongX then
			cf = CFrame.new(c + Vector3.new(0, h + roofHeight / 2, sign * span / 2)) * CFrame.Angles(sign * slope, 0, 0)
			part({
				Name = "Roof",
				Size = Vector3.new(w + 3, 0.8, slabLength),
				CFrame = cf,
				Material = Enum.Material.Slate,
				Color = spec.roofColor,
				Parent = m,
			})
		else
			cf = CFrame.new(c + Vector3.new(sign * span / 2, h + roofHeight / 2, 0))
				* CFrame.Angles(0, 0, -sign * slope)
			part({
				Name = "Roof",
				Size = Vector3.new(slabLength, 0.8, d + 3),
				CFrame = cf,
				Material = Enum.Material.Slate,
				Color = spec.roofColor,
				Parent = m,
			})
		end
	end
	local marker = part({
		Name = "LabelAnchor",
		Size = Vector3.new(1, 1, 1),
		Position = c + Vector3.new(0, h + roofHeight + 3, 0),
		Transparency = 1,
		CanCollide = false,
		CanQuery = false,
		Parent = m,
	})
	label(marker, spec.label, 0)
	return m
end

-- Areas ----------------------------------------------------------------------

local function buildGround()
	part({
		Name = "Ground",
		Size = Vector3.new(1000, 2, 1000),
		Position = Vector3.new(0, -1, 0),
		Material = Enum.Material.Grass,
		Color = Palette.grass,
	})
end

local function buildSquare()
	local m = group("VillageSquare")
	disc(Vector3.new(0, 0.1, 0), 76, 0.2, {
		Name = "Plaza",
		Material = Enum.Material.Cobblestone,
		Color = Palette.cobble,
		Parent = m,
	})
	disc(
		Vector3.new(0, 1, 0),
		14,
		2,
		{ Name = "FountainBase", Material = Enum.Material.Marble, Color = Palette.stone, Parent = m }
	)
	disc(Vector3.new(0, 2.05, 0), 12, 0.2, {
		Name = "FountainWater",
		Material = Enum.Material.Glass,
		Color = Palette.water,
		Transparency = 0.25,
		Parent = m,
	})
	part({
		Name = "FountainPillar",
		Size = Vector3.new(2, 5, 2),
		Position = Vector3.new(0, 4, 0),
		Material = Enum.Material.Marble,
		Color = Palette.stone,
		Parent = m,
	})
	for i = 0, 7 do
		local angle = i * math.pi / 4 + math.pi / 8
		lanternPost(Vector3.new(math.cos(angle) * 32, 0, math.sin(angle) * 32), m)
	end
	-- Lantern-painting table (Chapter 4 activity)
	part({
		Name = "LanternTable",
		Size = Vector3.new(8, 3, 4),
		Position = Vector3.new(-8, 1.5, 23),
		Material = Enum.Material.WoodPlanks,
		Color = Palette.wood,
		Parent = m,
	})
	-- Notice board
	local board = part({
		Name = "NoticeBoard",
		Size = Vector3.new(8, 5, 0.6),
		CFrame = CFrame.lookAt(Vector3.new(22, 4, -20), Vector3.new(0, 4, 0)),
		Material = Enum.Material.WoodPlanks,
		Color = Palette.wood,
		Parent = m,
	})
	signText(board, "LANTERNFALL FESTIVAL\nVolunteers wanted!")

	signpost(Vector3.new(26, 0, -30), Vector3.new(0, 0, 0), "Hearthpeak Trail", m)
	signpost(Vector3.new(38, 0, 12), Vector3.new(0, 0, 0), "Town Hall · Glowcap Woods", m)
	signpost(Vector3.new(-6, 0, 40), Vector3.new(0, 0, 0), "Mirror Pond", m)
	signpost(Vector3.new(-34, 0, 22), Vector3.new(0, 0, 0), "Keeping House · Stargazer Hill", m)
	signpost(Vector3.new(26, 0, 30), Vector3.new(0, 0, 0), "Lamplighter's Workshop", m)
	signpost(Vector3.new(-24, 0, -30), Vector3.new(0, 0, 0), "Crumb's Bakery", m)

	pathStrip(Vector3.new(-36, 0, 0), Vector3.new(-52, 0, 0), 10, m)
	pathStrip(Vector3.new(-22, 0, -28), Vector3.new(-40, 0, -50), 8, m)
	pathStrip(Vector3.new(36, 0, 0), Vector3.new(61, 0, 0), 10, m)
	pathStrip(Vector3.new(26, 0, 26), Vector3.new(46, 0, 46), 8, m)
	pathStrip(Vector3.new(0, 0, 38), Vector3.new(-12, 0, 90), 8, m)
	pathStrip(Vector3.new(40, 0, 18), Vector3.new(110, 0, 12), 8, m)
	pathStrip(Vector3.new(12, 0, -36), Vector3.new(30, 0, -108), 8, m)
	pathStrip(Vector3.new(130, 0, -30), Vector3.new(120, 0, -108), 8, m)
	pathStrip(Vector3.new(-30, 0, 22), Vector3.new(-100, 0, 42), 8, m)
	pathStrip(Vector3.new(-100, 0, 42), Vector3.new(-116, 0, 56), 8, m)

	part({
		Name = "SpawnMat",
		ClassName = "SpawnLocation",
		Size = Vector3.new(8, 0.4, 8),
		Position = Vector3.new(-40, 0.2, 14),
		Material = Enum.Material.Fabric,
		Color = Color3.fromRGB(178, 92, 70),
		Neutral = true,
		Duration = 0,
		Parent = m,
	})
end

local function buildKeepingHouse()
	local m = building({
		name = "KeepingHouse",
		label = "The Keeping House · Lost & Found",
		center = Vector3.new(-70, 0, 0),
		width = 36,
		depth = 30,
		height = 16,
		front = "+X",
		openFront = true,
		roofColor = Palette.roofRed,
		wallColor = Color3.fromRGB(233, 214, 178),
	})
	part({
		Name = "Counter",
		Size = Vector3.new(2, 4, 12),
		Position = Vector3.new(-59, 2, -2),
		Material = Enum.Material.WoodPlanks,
		Color = Palette.wood,
		Parent = m,
	})
	part({
		Name = "Ledger",
		Size = Vector3.new(1.6, 0.4, 2.2),
		Position = Vector3.new(-59, 4.2, -4),
		Material = Enum.Material.Fabric,
		Color = Color3.fromRGB(120, 40, 40),
		Parent = m,
	})
	part({
		Name = "SortingTable",
		Size = Vector3.new(5, 3, 7),
		Position = Vector3.new(-62, 1.5, 12),
		Material = Enum.Material.WoodPlanks,
		Color = Palette.wood,
		Parent = m,
	})
	-- Hoard shelves along the back wall, packed with colourful "lost things".
	local colors = {
		Color3.fromRGB(214, 86, 64),
		Color3.fromRGB(240, 200, 90),
		Color3.fromRGB(96, 150, 200),
		Color3.fromRGB(130, 180, 110),
		Color3.fromRGB(190, 120, 200),
	}
	local n = 0
	for _, z in ipairs({ -11, -3, 5, 12 }) do
		for level = 1, 3 do
			part({
				Name = "Shelf",
				Size = Vector3.new(3, 0.4, 6),
				Position = Vector3.new(-85.5, level * 3.6, z),
				Material = Enum.Material.Wood,
				Color = Palette.darkWood,
				Parent = m,
			})
			for k = -1, 1 do
				n += 1
				part({
					Name = "LostThing",
					Size = Vector3.new(1.2, 1.2 + (n % 3) * 0.4, 1.2),
					Position = Vector3.new(-85.5, level * 3.6 + 0.9, z + k * 1.8),
					Color = colors[(n % #colors) + 1],
					Parent = m,
				})
			end
		end
	end
	part({
		Name = "SideShelf",
		Size = Vector3.new(8, 0.4, 3),
		Position = Vector3.new(-76, 3.6, -13.5),
		Material = Enum.Material.Wood,
		Color = Palette.darkWood,
		Parent = m,
	})
	-- The player's crashed balloon on the roof (it went through!).
	part({
		Name = "Balloon",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(16, 16, 16),
		Position = Vector3.new(-74, 26, 3),
		Material = Enum.Material.Fabric,
		Color = Palette.balloon,
		Parent = m,
	})
	part({
		Name = "BalloonStripe",
		Size = Vector3.new(16.4, 3, 3),
		Position = Vector3.new(-74, 26, 3),
		Material = Enum.Material.Fabric,
		Color = Palette.balloonStripe,
		Parent = m,
	})
	part({
		Name = "Basket",
		Size = Vector3.new(5, 4, 5),
		CFrame = CFrame.new(-70, 19, 8) * CFrame.Angles(math.rad(15), 0, math.rad(-20)),
		Material = Enum.Material.WoodPlanks,
		Color = Color3.fromRGB(166, 124, 72),
		Parent = m,
	})
	part({
		Name = "Awning",
		Size = Vector3.new(6, 0.4, 32),
		CFrame = CFrame.new(-50, 13, 0) * CFrame.Angles(0, 0, math.rad(-15)),
		Material = Enum.Material.Fabric,
		Color = Color3.fromRGB(200, 120, 60),
		Parent = m,
	})
end

local function buildVillage()
	building({
		name = "Bakery",
		label = "Crumb's Bakery",
		center = Vector3.new(-40, 0, -62),
		width = 24,
		depth = 18,
		height = 14,
		front = "+Z",
		roofColor = Palette.roofRed,
		wallColor = Color3.fromRGB(242, 206, 190),
	})
	building({
		name = "TownHall",
		label = "Kettlewick Town Hall",
		center = Vector3.new(75, 0, 0),
		width = 28,
		depth = 24,
		height = 18,
		front = "-X",
		roofColor = Palette.roofBlue,
		wallColor = Color3.fromRGB(226, 222, 210),
		wallMaterial = Enum.Material.Brick,
		ridgeAlongX = true,
	})
	building({
		name = "Workshop",
		label = "Lamplighter's Workshop",
		center = Vector3.new(62, 0, 62),
		width = 22,
		depth = 20,
		height = 14,
		front = "-X",
		roofColor = Palette.roofGreen,
		wallColor = Color3.fromRGB(205, 190, 165),
	})
	local m = group("BalloonRepair")
	part({
		Name = "PatchedBalloon",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(14, 14, 14),
		Position = Vector3.new(84, 14, 44),
		Material = Enum.Material.Fabric,
		Color = Palette.balloon,
		Parent = m,
	})
	part({
		Name = "Scaffold",
		Size = Vector3.new(1, 12, 1),
		Position = Vector3.new(84, 6, 44),
		Material = Enum.Material.Wood,
		Color = Palette.darkWood,
		Parent = m,
	})
end

local function buildPond()
	local m = group("MirrorPond")
	disc(Vector3.new(-10, 0.15, 130), 68, 0.3, {
		Name = "Water",
		Material = Enum.Material.Glass,
		Color = Palette.water,
		Transparency = 0.2,
		CanCollide = false,
		Parent = m,
	})
	part({
		Name = "Dock",
		Size = Vector3.new(6, 0.6, 22),
		Position = Vector3.new(-10, 0.6, 104),
		Material = Enum.Material.WoodPlanks,
		Color = Palette.wood,
		Parent = m,
	})
	for i = 1, 14 do
		local angle = i / 14 * math.pi * 2
		part({
			Name = "Reed",
			Size = Vector3.new(0.4, 4, 0.4),
			Position = Vector3.new(-10 + math.cos(angle) * 35, 2, 130 + math.sin(angle) * 35),
			Material = Enum.Material.Grass,
			Color = Palette.leavesDark,
			CanCollide = false,
			Parent = m,
		})
	end
	label(
		part({
			Name = "LabelAnchor",
			Size = Vector3.new(1, 1, 1),
			Position = Vector3.new(-10, 10, 130),
			Transparency = 1,
			CanCollide = false,
			Parent = m,
		}),
		"Mirror Pond",
		0
	)
end

local function buildWoods()
	local m = group("GlowcapWoods")
	-- Deterministic scatter (same forest every time), clear of the glowcaps.
	local seed = 12345
	local function rand()
		seed = (seed * 16807) % 2147483647
		return seed / 2147483647
	end
	for _ = 1, 46 do
		local x, z = 105 + rand() * 100, -45 + rand() * 110
		local position = Vector3.new(x, 0, z)
		local clear = true
		for i = 1, 6 do
			local glowcap = ({ { 125, -20 }, { 150, -35 }, { 175, -5 }, { 190, 30 }, { 160, 45 }, { 130, 30 } })[i]
			if (Vector3.new(glowcap[1], 0, glowcap[2]) - position).Magnitude < 8 then
				clear = false
			end
		end
		if clear then
			tree(position, 0.8 + rand() * 0.6, m)
		end
	end
	label(
		part({
			Name = "LabelAnchor",
			Size = Vector3.new(1, 1, 1),
			Position = Vector3.new(150, 26, 10),
			Transparency = 1,
			CanCollide = false,
			Parent = m,
		}),
		"Glowcap Woods",
		0
	)
	signpost(Vector3.new(112, 0, -34), Vector3.new(130, 0, 0), "Old Bridge Ruins", m)
end

local function buildOldBridge()
	local m = group("OldBridge")
	for _, x in ipairs({ 120, 184 }) do
		part({
			Name = "Cliff",
			Size = Vector3.new(40, 12, 40),
			Position = Vector3.new(x, 6, -160),
			Material = Enum.Material.Rock,
			Color = Palette.rock,
			Parent = m,
		})
		part({
			Name = "CliffTop",
			Size = Vector3.new(40, 0.4, 40),
			Position = Vector3.new(x, 11.85, -160),
			Material = Enum.Material.Grass,
			Color = Palette.grass,
			Parent = m,
		})
	end
	part({
		Name = "River",
		Size = Vector3.new(24, 0.4, 160),
		Position = Vector3.new(152, 0.2, -160),
		Material = Enum.Material.Glass,
		Color = Palette.water,
		Transparency = 0.2,
		CanCollide = false,
		Parent = m,
	})
	ramp(Vector3.new(120, 0, -108), Vector3.new(120, 12.05, -140), 10, m)
	-- Charred bridge stubs reaching for each other across the gorge.
	for _, spec in ipairs({
		{ from = Vector3.new(140, 11.8, -158), to = Vector3.new(146, 10.8, -158) },
		{ from = Vector3.new(140, 11.8, -162), to = Vector3.new(145, 11.2, -162) },
		{ from = Vector3.new(164, 11.8, -158), to = Vector3.new(158, 10.6, -158) },
		{ from = Vector3.new(164, 11.8, -162), to = Vector3.new(159, 11.4, -162) },
	}) do
		part({
			Name = "BurntBeam",
			Size = Vector3.new(0.8, 0.8, (spec.to - spec.from).Magnitude),
			CFrame = CFrame.lookAt((spec.from + spec.to) / 2, spec.to),
			Material = Enum.Material.Wood,
			Color = Palette.charcoal,
			Parent = m,
		})
	end
	for _, x in ipairs({ 139, 165 }) do
		part({
			Name = "BridgePier",
			Size = Vector3.new(2, 4, 10),
			Position = Vector3.new(x, 13.8, -160),
			Material = Enum.Material.Cobblestone,
			Color = Color3.fromRGB(70, 64, 60),
			Parent = m,
		})
	end
	label(
		part({
			Name = "LabelAnchor",
			Size = Vector3.new(1, 1, 1),
			Position = Vector3.new(152, 26, -160),
			Transparency = 1,
			CanCollide = false,
			Parent = m,
		}),
		"Old Bridge Ruins",
		0
	)
end

local function buildHill()
	local m = group("StargazerHill")
	part({
		Name = "Hill",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(120, 120, 120),
		Position = Vector3.new(-160, -40, 60),
		Material = Enum.Material.Grass,
		Color = Color3.fromRGB(112, 156, 84),
		Parent = m,
	})
	part({
		Name = "Blanket",
		Size = Vector3.new(6, 0.2, 5),
		CFrame = CFrame.new(-156, 19.85, 64),
		Material = Enum.Material.Fabric,
		Color = Color3.fromRGB(64, 86, 150),
		CanCollide = false,
		Parent = m,
	})
	tree(Vector3.new(-170, 18.6, 52), 0.9, m)
	label(
		part({
			Name = "LabelAnchor",
			Size = Vector3.new(1, 1, 1),
			Position = Vector3.new(-160, 34, 60),
			Transparency = 1,
			CanCollide = false,
			Parent = m,
		}),
		"Stargazer Hill",
		0
	)
end

local function buildPeak()
	local m = group("Hearthpeak")
	local x = 30
	for i = 0, 7 do
		local z0 = -110 - 30 * i
		local y0 = 8 * i
		ramp(Vector3.new(x, y0, z0), Vector3.new(x, y0 + 8, z0 - 20), 14, m)
		part({
			Name = "Landing",
			Size = Vector3.new(14, 2, 10.5),
			Position = Vector3.new(x, y0 + 7, z0 - 25),
			Material = Enum.Material.Slate,
			Color = Palette.path,
			Parent = m,
		})
		if y0 > 0 then
			part({
				Name = "Support",
				Size = Vector3.new(18, y0, 30),
				Position = Vector3.new(x, y0 / 2 - 0.5, z0 - 15),
				Material = Enum.Material.Rock,
				Color = Palette.rock,
				Parent = m,
			})
		end
		if i >= 5 then
			part({
				Name = "Snow",
				Size = Vector3.new(14.2, 0.3, 10.6),
				Position = Vector3.new(x, y0 + 8.1, z0 - 25),
				Material = Enum.Material.Snow,
				Color = Palette.snow,
				CanCollide = false,
				Parent = m,
			})
		end
	end
	part({
		Name = "SummitBase",
		Size = Vector3.new(64, 62, 64),
		Position = Vector3.new(x, 31, -372),
		Material = Enum.Material.Rock,
		Color = Palette.rock,
		Parent = m,
	})
	part({
		Name = "SummitTop",
		Size = Vector3.new(64, 2, 64),
		Position = Vector3.new(x, 63, -372),
		Material = Enum.Material.Snow,
		Color = Palette.snow,
		Parent = m,
	})
	-- Mountain silhouette
	for _, spec in ipairs({
		{ Vector3.new(-55, 40, -330), Vector3.new(60, 80, 90), 20 },
		{ Vector3.new(115, 50, -350), Vector3.new(70, 100, 110), -15 },
		{ Vector3.new(30, 80, -440), Vector3.new(160, 160, 60), 0 },
	}) do
		part({
			Name = "Crag",
			Size = spec[2],
			CFrame = CFrame.new(spec[1]) * CFrame.Angles(0, math.rad(spec[3]), 0),
			Material = Enum.Material.Rock,
			Color = Color3.fromRGB(96, 92, 100),
			Parent = m,
		})
	end
	label(
		part({
			Name = "LabelAnchor",
			Size = Vector3.new(1, 1, 1),
			Position = Vector3.new(x, 0, -112),
			Transparency = 1,
			CanCollide = false,
			Parent = m,
		}),
		"Hearthpeak Trail",
		8
	)

	-- The beacon itself; the client dims or brightens it per player's story.
	local beacon = group("Beacon")
	beacon.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	disc(Vector3.new(x, 66, -388), 8, 4, {
		Name = "BrazierBase",
		Material = Enum.Material.Cobblestone,
		Color = Palette.stone,
		Parent = beacon,
	})
	disc(Vector3.new(x, 69, -388), 12, 2, {
		Name = "BrazierBowl",
		Material = Enum.Material.Metal,
		Color = Palette.charcoal,
		Parent = beacon,
	})
	local flame = part({
		Name = "Hearthflame",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(3, 3, 3),
		Position = Vector3.new(x, 71, -388),
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(255, 150, 60),
		CanCollide = false,
		Parent = beacon,
	})
	local fire = Instance.new("Fire")
	fire.Size = 4
	fire.Heat = 6
	fire.Parent = flame
	local light = Instance.new("PointLight")
	light.Range = 30
	light.Brightness = 2
	light.Color = Color3.fromRGB(255, 170, 90)
	light.Parent = flame
	beacon.PrimaryPart = flame
end

local function buildLighting()
	Lighting.ClockTime = 14
	Lighting.Brightness = 2
	Lighting.Ambient = Color3.fromRGB(90, 80, 72)
	Lighting.OutdoorAmbient = Color3.fromRGB(140, 128, 116)
	if Lighting:FindFirstChildOfClass("Atmosphere") == nil then
		local atmosphere = Instance.new("Atmosphere")
		atmosphere.Density = 0.28
		atmosphere.Haze = 1.2
		atmosphere.Color = Color3.fromRGB(255, 226, 190)
		atmosphere.Decay = Color3.fromRGB(120, 110, 140)
		atmosphere.Parent = Lighting
	end
	if Lighting:FindFirstChildOfClass("BloomEffect") == nil then
		local bloom = Instance.new("BloomEffect")
		bloom.Intensity = 0.4
		bloom.Size = 24
		bloom.Threshold = 1.6
		bloom.Parent = Lighting
	end
end

-- Anchors ------------------------------------------------------------------
local function ensureAnchors(world: Instance, ctx)
	local WorldAnchors = require(ctx.shared.WorldAnchors)
	local anchors = world:FindFirstChild(ctx.config.AnchorsFolderName)
	if anchors == nil then
		anchors = Instance.new("Model")
		anchors.Name = ctx.config.AnchorsFolderName
		anchors.Parent = world
	end
	if anchors:IsA("Model") then
		anchors.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	end
	for name in pairs(ctx.content.Anchors) do
		if anchors:FindFirstChild(name) == nil then
			part({
				Name = name,
				Size = Vector3.new(1, 1, 1),
				CFrame = WorldAnchors.dataCFrame(name),
				Transparency = 1,
				CanCollide = false,
				CanQuery = false,
				CanTouch = false,
				Parent = anchors,
			})
		end
	end
end

function WorldBuilder.build(ctx)
	local existing = workspace:FindFirstChild(ctx.config.WorldFolderName)
	if existing then
		ensureAnchors(existing, ctx)
		return existing
	end
	if not ctx.config.BuildPlaceholderWorld then
		local folder = Instance.new("Folder")
		folder.Name = ctx.config.WorldFolderName
		folder.Parent = workspace
		ensureAnchors(folder, ctx)
		return folder
	end
	worldFolder = Instance.new("Folder")
	worldFolder.Name = ctx.config.WorldFolderName

	buildGround()
	buildSquare()
	buildKeepingHouse()
	buildVillage()
	buildPond()
	buildWoods()
	buildOldBridge()
	buildHill()
	buildPeak()
	buildLighting()

	worldFolder.Parent = workspace
	ensureAnchors(worldFolder, ctx)

	-- Remove the default baseplate/spawn if the place still has them.
	for _, name in ipairs({ "Baseplate", "SpawnLocation" }) do
		local default = workspace:FindFirstChild(name)
		if default and default:IsA("BasePart") then
			default:Destroy()
		end
	end
	return worldFolder
end

return WorldBuilder
