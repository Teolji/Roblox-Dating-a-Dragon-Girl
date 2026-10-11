--[[
	World
	Explorer: ReplicatedStorage > Hearthscale > Content > World (ModuleScript)

	Anchors: named world positions { x, y, z [, yawDegrees] }. Yaw is
	atan2(-dx, -dz) of the direction faced (0 = looking toward -Z).
	NPC anchors are feet positions. WorldBuilder creates
	an invisible Part for every anchor under Workspace.HearthscaleWorld.Anchors;
	if you build your own map, keep that folder and move the parts — the
	part positions then override these numbers.

	Collectibles: per-player pickups (each player sees only their own).
	Locations: areas that fire "reach:<id>" quest events.
]]

local Anchors = {
	Spawn = { -40, 0, 14, -90 },

	-- Keeping House (Saffron's Lost & Found), open front facing the square (+X)
	Saffron_Shop = { -64, 0, 0, -90 },
	Sort_Table = { -62, 0, 10, -90 },
	Hoard_Clue_1 = { -83, 3, -10 },
	Hoard_Clue_2 = { -76, 3, -13 },
	Hoard_Clue_3 = { -83, 3, 4 },
	Hoard_Lantern = { -83, 2, 11 },

	-- Village square
	Pim_Square = { 16, 0, -14, 131 },
	Saffron_Square = { -16, 0, 14, -49 },
	Lantern_Table = { -8, 0, 20, 0 },
	Cinderra_Square = { 14, 0, 10, 54 },

	-- Buildings around the square
	Mabel_Bakery = { -40, 0, -46, -139 },
	Pim_Hall = { 58, 0, 0, 90 },
	Wren_Workshop = { 48, 0, 48, 45 },

	-- Mirror Pond (south)
	Saffron_Pond = { -18, 0, 92, 180 },
	Pond_Dock = { -10, 0, 98 },
	Flowers_Pond = { 20, 1.5, 100 },

	-- Glowcap Woods (east)
	Glowcap_1 = { 125, 1.5, -20 },
	Glowcap_2 = { 150, 1.5, -35 },
	Glowcap_3 = { 175, 1.5, -5 },
	Glowcap_4 = { 190, 1.5, 30 },
	Glowcap_5 = { 160, 1.5, 45 },
	Glowcap_6 = { 130, 1.5, 30 },
	Mitten_Spot = { 185, 1.5, 55 },

	-- Old Bridge ruins (north-east, on the west cliff above the gorge)
	Saffron_Bridge = { 134, 12, -156, -90 },
	Bridge_Site = { 128, 12, -160 },

	-- Stargazer Hill (west). The hill is a sphere of radius 60 centred at
	-- (-160, -40, 60), so heights follow its surface.
	Saffron_Hill = { -160, 20, 60, -90 },
	Hill_Meadow = { -150, 18.9, 66 },
	Flowers_Hill = { -120, 6.2, 60 },
	Firefly_1 = { -142.8, 20.2, 65.3 },
	Firefly_2 = { -142.3, 17.1, 79.1 },
	Firefly_3 = { -152.7, 13.1, 92.2 },
	Firefly_4 = { -166.5, 18.8, 81.0 },
	Firefly_5 = { -182.0, 15.0, 80.4 },
	Firefly_6 = { -195.1, 11.0, 68.0 },
	Firefly_7 = { -179.1, 19.6, 54.1 },
	Firefly_8 = { -179.0, 16.1, 39.5 },
	Firefly_9 = { -167.5, 12.4, 26.8 },
	Firefly_10 = { -152.9, 18.0, 37.1 },
	Firefly_11 = { -137.3, 14.4, 38.9 },
	Firefly_12 = { -122.9, 9.4, 51.6 },

	-- Hearthpeak (north). Trail starts at (30, 0, -110) and climbs to y = 64.
	Frostbloom_Trail = { 34, 33.5, -225 },
	Summit_Center = { 30, 64, -362 },
	Saffron_Summit = { 22, 64, -372, 0 },
	Cinderra_Summit = { 40, 64, -374, 0 },
	Hearthflame = { 30, 64, -388 },
}

local Collectibles = {
	lost_mitten = {
		name = "Lost Mitten",
		anchor = "Mitten_Spot",
		when = { chapterMin = 2 },
		effects = { give = "lost_mitten" },
		text = "A red mitten, half-buried in leaves. Somebody misses this.",
		color = "#D9443A",
	},
	wildflowers_hill = {
		name = "Wildflowers",
		anchor = "Flowers_Hill",
		effects = { give = "wildflowers" },
		color = "#F2B5D4",
	},
	wildflowers_pond = {
		name = "Wildflowers",
		anchor = "Flowers_Pond",
		effects = { give = "wildflowers" },
		color = "#F2B5D4",
	},
	frostbloom_trail = {
		name = "Frostbloom",
		anchor = "Frostbloom_Trail",
		when = { chapterMin = 2 },
		effects = { give = "frostbloom" },
		text = "A pale flower glittering with frost, growing where the trail turns cold.",
		color = "#BFE6FF",
	},
	hoard_clue_1 = {
		name = "Yellow Tag",
		group = "hoard_clue",
		anchor = "Hoard_Clue_1",
		when = { questStep = { "q_lantern_hoard", "search" } },
		text = "A yellow tag in Saffron's handwriting: 'NOT under the spoons. Too obvious. — S.'",
		color = "#F2D04B",
	},
	hoard_clue_2 = {
		name = "Yellow Tag",
		group = "hoard_clue",
		anchor = "Hoard_Clue_2",
		when = { questStep = { "q_lantern_hoard", "search" } },
		text = "Another tag: 'NOT with the umbrellas. I would never do that to the umbrellas. — S.'",
		color = "#F2D04B",
	},
	hoard_clue_3 = {
		name = "Yellow Tag",
		group = "hoard_clue",
		anchor = "Hoard_Clue_3",
		when = { questStep = { "q_lantern_hoard", "search" } },
		text = "The last tag: 'Somewhere warm. Somewhere with the socks that lost their partners. You know why. — S.'",
		color = "#F2D04B",
	},
	warden_lantern_spot = {
		name = "Warden's Lantern",
		anchor = "Hoard_Lantern",
		when = { questStep = { "q_lantern_hoard", "find" } },
		effects = { give = "warden_lantern", flag = "found_lantern" },
		text = "Behind a crate of single socks: an iron lantern, wrapped in a blue blanket with moons on it.",
		color = "#FFB347",
	},
}

for i = 1, 6 do
	Collectibles["glowcap_" .. i] = {
		name = "Glowcap",
		group = "glowcap",
		anchor = "Glowcap_" .. i,
		when = { questStep = { "q_lanternfall", "glowcaps" } },
		effects = { give = "glowcap" },
		color = "#7FE3C4",
	}
end

local Locations = {
	old_bridge = { name = "Old Bridge Ruins", anchor = "Bridge_Site", radius = 30 },
	summit = { name = "Hearthpeak Summit", anchor = "Summit_Center", radius = 34 },
}

return {
	Anchors = Anchors,
	Collectibles = Collectibles,
	Locations = Locations,
}
