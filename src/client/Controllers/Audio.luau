--[[
	Audio
	Explorer: StarterPlayer > StarterPlayerScripts > HearthscaleClient > Controllers > Audio (ModuleScript)

	Plays music and sound effects from Config.Audio. Every id ships EMPTY
	(placeholder) — the game is silent until you add audio you own or that
	is licensed for use (see docs/05-Assets.md). Empty ids are skipped.
]]

local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local Session = require(script.Parent.Session)

local Audio = {}

local sfxCache = {}
local musicSound: Sound? = nil
local currentTrack: string? = nil

local function assetId(id: string?): string?
	if id == nil or id == "" then
		return nil
	end
	if string.find(id, "rbxassetid://", 1, true) then
		return id
	end
	return "rbxassetid://" .. id
end

function Audio.sfx(name: string)
	local id = assetId(Session.Config.Audio.Sfx[name])
	if id == nil then
		return
	end
	local sound = sfxCache[name]
	if sound == nil then
		sound = Instance.new("Sound")
		sound.Name = "Sfx_" .. name
		sound.SoundId = id
		sound.Parent = SoundService
		sfxCache[name] = sound
	end
	sound.Volume = 0.6 * (Session.settings().sfx or 0.8)
	sound:Play()
end

function Audio.music(track: string?)
	if track == currentTrack then
		return
	end
	currentTrack = track
	local id = track and assetId(Session.Config.Audio.Music[track])
	local old = musicSound
	musicSound = nil
	if old then
		local fade = TweenService:Create(old, TweenInfo.new(1.5), { Volume = 0 })
		fade:Play()
		fade.Completed:Connect(function()
			old:Destroy()
		end)
	end
	if id then
		local sound = Instance.new("Sound")
		sound.Name = "Music"
		sound.SoundId = id
		sound.Looped = true
		sound.Volume = 0
		sound.Parent = SoundService
		sound:Play()
		TweenService:Create(sound, TweenInfo.new(1.5), { Volume = 0.5 * (Session.settings().music or 0.6) }):Play()
		musicSound = sound
	end
end

function Audio.applyVolume()
	if musicSound then
		musicSound.Volume = 0.5 * (Session.settings().music or 0.6)
	end
end

return Audio
