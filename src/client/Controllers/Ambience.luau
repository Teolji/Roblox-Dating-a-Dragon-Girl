--[[
	Ambience
	Explorer: StarterPlayer > StarterPlayerScripts > HearthscaleClient > Controllers > Ambience (ModuleScript)

	Per-player mood: time of day, the Hearthflame on the peak (guttering as
	the story advances, blazing once relit) and music track. All changes are
	local, so players in different chapters each see their own sky.
]]

local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local Session = require(script.Parent.Session)
local Audio = require(script.Parent.Audio)

local Ambience = {}

local flicker = 0.2
local flameProfile = { size = 3, range = 20, brightness = 1.5, color = Color3.fromRGB(255, 150, 60) }

local function questActive(state, questId: string): boolean
	local q = state.quests[questId]
	return q ~= nil and q.s == "active"
end

local function moodFor(state)
	local chapter = Session.Content.Chapters[state.chapter]
	local clock = chapter and chapter.timeOfDay or 14
	local music = "village"
	if state.ending then
		clock, music = 9, "ending"
	elseif questActive(state, "q_summit") then
		clock, music = 20.4, "finale"
	elseif questActive(state, "q_stargazing") then
		clock, music = 21.6, "night"
	elseif questActive(state, "q_lanterns") or questActive(state, "q_cinderra") then
		music = "tension"
	end
	return clock, music
end

local function flameFor(state)
	if state.ending == "two_flames" or state.ending == "kindred_sparks" then
		return { size = 14, range = 80, brightness = 4, color = Color3.fromRGB(255, 196, 90) }, 0.05
	elseif state.ending then
		return { size = 12, range = 70, brightness = 3.5, color = Color3.fromRGB(255, 120, 60) }, 0.05
	elseif state.chapter >= 5 then
		return { size = 1, range = 8, brightness = 0.6, color = Color3.fromRGB(255, 110, 50) }, 0.6
	elseif state.chapter >= 2 then
		return { size = 2, range = 14, brightness = 1, color = Color3.fromRGB(255, 140, 60) }, 0.45
	end
	return { size = 3, range = 20, brightness = 1.5, color = Color3.fromRGB(255, 150, 60) }, 0.2
end

local function beaconFlame(): BasePart?
	local world = workspace:FindFirstChild(Session.Config.WorldFolderName)
	local beacon = world and world:FindFirstChild("Beacon", true)
	local flame = beacon and beacon:FindFirstChild("Hearthflame")
	return flame and flame:IsA("BasePart") and flame or nil
end

function Ambience.refresh()
	local state = Session.state
	if state == nil then
		return
	end
	local clock, music = moodFor(state)
	if Session.settings().reduceMotion then
		Lighting.ClockTime = clock
	else
		TweenService:Create(Lighting, TweenInfo.new(3), { ClockTime = clock }):Play()
	end
	Audio.music(music)
	Audio.applyVolume()
	flameProfile, flicker = flameFor(state)
end

function Ambience.init()
	Session.StateChanged:Connect(Ambience.refresh)
	Ambience.refresh()
	task.spawn(function()
		while true do
			task.wait(0.12)
			local flame = beaconFlame()
			if flame then
				local jitter = 1 + (math.random() - 0.5) * flicker
				local fire = flame:FindFirstChildOfClass("Fire")
				local light = flame:FindFirstChildOfClass("PointLight")
				if fire then
					fire.Size = flameProfile.size * jitter
					fire.Color = flameProfile.color
				end
				if light then
					light.Range = flameProfile.range * jitter
					light.Brightness = flameProfile.brightness * jitter
					light.Color = flameProfile.color
				end
				flame.Color = flameProfile.color
			end
		end
	end)
end

return Ambience
