--[[
	Items
	Explorer: ReplicatedStorage > Hearthscale > Content > Items (ModuleScript)

	icon: emoji placeholder shown in the inventory (PLACEHOLDER — swap for
	`image = "rbxassetid://..."` once icon art exists; the UI prefers image).
	quest = true items can't be gifted or dropped.
]]

return {
	rolling_pin = {
		name = "Mabel's Rolling Pin",
		description = "Floury and slightly dented. Stamped: PROPERTY OF MABEL — IF FOUND, I KNOW.",
		icon = "🥖",
		quest = true,
	},
	spectacles = {
		name = "Mayor's Spectacles",
		description = "Lenses thick enough to see next Tuesday.",
		icon = "👓",
		quest = true,
	},
	lamp_hook = {
		name = "Lamplighter's Hook",
		description = "A long brass hook for lighting the high lanterns.",
		icon = "🪝",
		quest = true,
	},
	sealed_letter = {
		name = "Letter Sealed in Wax",
		description = "Heavy paper. The seal shows a coiled dragon, and it is still warm.",
		icon = "✉️",
		quest = true,
	},
	warden_lantern = {
		name = "Warden's Lantern",
		description = "An old iron lantern, scorched along one side and polished with enormous care.",
		icon = "🏮",
		quest = true,
	},
	glowcap = {
		name = "Glowcap",
		description = "A softly glowing mushroom. Lantern fuel. Also, according to Saffron, a snack.",
		icon = "🍄",
		giftable = true,
	},
	honey_bun = {
		name = "Honey Bun",
		description = "Mabel's specialty. Sticky in a way that feels personal.",
		icon = "🍯",
		giftable = true,
	},
	smoked_ember_tea = {
		name = "Smoked Ember Tea",
		description = "Dark tea smoked over ember-pepper. Mabel's label says: FOR DRAGONS AND THE BRAVE.",
		icon = "🍵",
		giftable = true,
	},
	river_pebble = {
		name = "Smooth River Pebble",
		description = "Perfectly smooth, fished out of Mirror Pond.",
		icon = "🪨",
		giftable = true,
	},
	lost_mitten = {
		name = "Lost Mitten",
		description = "One red mitten. Its partner is out there somewhere, waiting.",
		icon = "🧤",
		giftable = true,
	},
	wildflowers = {
		name = "Wildflowers",
		description = "A cheerful handful from the meadow.",
		icon = "💐",
		giftable = true,
	},
	frostbloom = {
		name = "Frostbloom",
		description = "A flower that only grows in snow. Cold to the touch. Very cold.",
		icon = "❄️",
		giftable = true,
	},
	fire_starter = {
		name = "Fire Starter Kit",
		description = "Flint, steel and tinder. Mayor Pim insists it is 'for Miss Ignavarre's little problem'.",
		icon = "🔥",
		giftable = true,
	},
	star_chart = {
		name = "Star Chart",
		description = "Wren's hand-inked map of the autumn sky. The Dragon's Tail constellation is circled.",
		icon = "🗺️",
		giftable = true,
	},
}
