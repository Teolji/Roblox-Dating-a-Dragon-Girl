--[[
	Expressions
	Explorer: StarterPlayer > StarterPlayerScripts > HearthscaleClient > Controllers > Expressions (ModuleScript)

	Gives NPCs readable emotions without any uploaded animation assets:
	procedural tail sways/wags/droops, head tilts, breathing, smoke puffs,
	blush and a text-drawn face. If Config.Animations[npc][emote] holds an
	animation id and the model has an Animator, that animation plays as well
	(PLACEHOLDER ids ship empty).

	Saffron's tells: happy = fast wag; flustered = smoke + blush + curled
	tail; annoyed = smoke + slow tail thump; sad = drooped tail and head.
]]

local RunService = game:GetService("RunService")

local Session = require(script.Parent.Session)

local Expressions = {}

local EMOTES = {
	neutral = {
		eyes = "o   o",
		mouth = "—",
		tailAmp = 10,
		tailSpeed = 0.6,
		tailLift = 0,
		head = 0,
		roll = 0,
		bob = 0.04,
		arms = 3,
	},
	happy = {
		eyes = "^   ^",
		mouth = "\\_/",
		tailAmp = 28,
		tailSpeed = 2.4,
		tailLift = 10,
		head = 6,
		roll = 4,
		bob = 0.08,
		arms = 8,
	},
	laugh = {
		eyes = ">   <",
		mouth = "\\__/",
		tailAmp = 34,
		tailSpeed = 3.2,
		tailLift = 16,
		head = 14,
		roll = 0,
		bob = 0.14,
		arms = 12,
	},
	flustered = {
		eyes = "@   @",
		mouth = "~~~",
		tailAmp = 6,
		tailSpeed = 1.4,
		tailLift = -10,
		curl = 30,
		head = -6,
		roll = 8,
		bob = 0.05,
		arms = 4,
		blush = true,
		smoke = 10,
	},
	annoyed = {
		eyes = "-   -",
		mouth = "___",
		tailAmp = 5,
		tailSpeed = 0.5,
		tailLift = -18,
		thump = true,
		head = -4,
		roll = 0,
		bob = 0.02,
		arms = 0,
		smoke = 14,
	},
	sad = {
		eyes = ";   ;",
		mouth = "/^\\",
		tailAmp = 3,
		tailSpeed = 0.3,
		tailLift = -30,
		head = -14,
		roll = 0,
		bob = 0.02,
		arms = 0,
	},
	surprised = {
		eyes = "O   O",
		mouth = "o",
		tailAmp = 4,
		tailSpeed = 3,
		tailLift = 30,
		head = 8,
		roll = 0,
		bob = 0.03,
		arms = 10,
	},
	thoughtful = {
		eyes = "o   -",
		mouth = "~",
		tailAmp = 8,
		tailSpeed = 0.4,
		tailLift = 0,
		curl = 15,
		head = 4,
		roll = 10,
		bob = 0.03,
		arms = 2,
	},
	determined = {
		eyes = "o   o",
		mouth = "===",
		tailAmp = 6,
		tailSpeed = 0.8,
		tailLift = 12,
		head = 4,
		roll = 0,
		bob = 0.03,
		arms = 2,
	},
	smug = {
		eyes = "-   o",
		mouth = "\\_",
		tailAmp = 14,
		tailSpeed = 0.9,
		tailLift = 8,
		head = 8,
		roll = -6,
		bob = 0.04,
		arms = 3,
	},
	tender = {
		eyes = "^   ^",
		mouth = "\\_/",
		tailAmp = 10,
		tailSpeed = 0.7,
		tailLift = -4,
		curl = 20,
		head = -2,
		roll = 10,
		bob = 0.04,
		arms = 2,
		blush = true,
	},
}

local NUMERIC = { "tailAmp", "tailSpeed", "tailLift", "curl", "head", "roll", "bob", "arms" }

local rigs = {} -- [Model] = record

local function motorsOf(model: Model)
	local motors = {}
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("Motor6D") then
			motors[d.Name] = { motor = d, base = d.C0 }
		end
	end
	return motors
end

local function findAnimator(model: Model): Animator?
	return model:FindFirstChildWhichIsA("Animator", true)
end

function Expressions.attach(model: Model, npcId: string, placeholder: boolean)
	local record = {
		model = model,
		npc = npcId,
		placeholder = placeholder,
		motors = motorsOf(model),
		emote = "neutral",
		current = table.clone(EMOTES.neutral),
		seed = math.random() * 10,
		animator = findAnimator(model),
		tracks = {},
		playing = nil,
	}
	record.current.curl = 0
	rigs[model] = record
	Expressions.set(model, "neutral")
end

function Expressions.detach(model: Model)
	rigs[model] = nil
end

local function playAnimation(record, emote: string)
	local animator = record.animator
	if animator == nil then
		return
	end
	local ids = Session.Config.Animations[record.npc]
	local id = ids and ids[emote]
	if record.playing then
		record.playing:Stop(0.25)
		record.playing = nil
	end
	if id == nil or id == "" then
		return
	end
	local track = record.tracks[emote]
	if track == nil then
		local animation = Instance.new("Animation")
		animation.AnimationId = string.find(id, "rbxassetid://", 1, true) and id or ("rbxassetid://" .. id)
		local ok, loaded = pcall(function()
			return animator:LoadAnimation(animation)
		end)
		if not ok then
			return
		end
		track = loaded
		record.tracks[emote] = track
	end
	track:Play(0.25)
	record.playing = track
end

function Expressions.set(model: Model, emote: string)
	local record = rigs[model]
	if record == nil then
		return
	end
	local def = EMOTES[emote] or EMOTES.neutral
	record.emote = EMOTES[emote] and emote or "neutral"
	local head = model:FindFirstChild("Head")
	local face = head and head:FindFirstChild("Face")
	if face then
		local eyes = face:FindFirstChild("Eyes")
		local mouth = face:FindFirstChild("Mouth")
		if eyes then
			eyes.Text = def.eyes
		end
		if mouth then
			mouth.Text = def.mouth
		end
	end
	for _, name in ipairs({ "BlushL", "BlushR" }) do
		local blush = model:FindFirstChild(name)
		if blush and blush:IsA("BasePart") then
			blush.Transparency = def.blush and 0.15 or 1
		end
	end
	if def.smoke and head then
		local nose = head:FindFirstChild("Nose")
		local smoke = nose and nose:FindFirstChild("Smoke")
		if smoke and smoke:IsA("ParticleEmitter") then
			smoke:Emit(def.smoke)
		end
	end
	playAnimation(record, record.emote)
end

local function step(dt: number)
	local reduce = Session.settings().reduceMotion == true
	local now = os.clock()
	local blend = math.clamp(dt * 4, 0, 1)
	for model, record in pairs(rigs) do
		if model.Parent == nil then
			rigs[model] = nil
			continue
		end
		local target = EMOTES[record.emote]
		local c = record.current
		for _, key in ipairs(NUMERIC) do
			c[key] = (c[key] or 0) + ((target[key] or 0) - (c[key] or 0)) * blend
		end
		local amp = reduce and 0.2 or 1
		local t = now + record.seed
		local m = record.motors

		if m.Tail1 then
			local i = 1
			while m["Tail" .. i] do
				local entry = m["Tail" .. i]
				local phase = t * c.tailSpeed * math.pi * 2 - i * 0.7
				local yaw = math.sin(phase) * c.tailAmp * amp + c.curl * (i / 3)
				local pitch = c.tailLift / i
				if target.thump then
					pitch += math.max(0, math.sin(t * 2.2)) * -12 * amp
				end
				entry.motor.C0 = entry.base * CFrame.Angles(math.rad(pitch), math.rad(yaw), 0)
				i += 1
			end
		end

		if record.placeholder then
			if m.Waist then
				local bob = math.sin(t * math.pi) * c.bob * amp
				m.Waist.motor.C0 = m.Waist.base * CFrame.new(0, bob, 0)
			end
			if m.Neck then
				local nod = math.sin(t * 1.3) * 1.5 * amp
				m.Neck.motor.C0 = m.Neck.base * CFrame.Angles(math.rad(c.head + nod), 0, math.rad(c.roll))
			end
			for _, name in ipairs({ "LeftShoulder", "RightShoulder" }) do
				local entry = m[name]
				if entry then
					local side = name == "LeftShoulder" and 1 or -1
					local swing = math.sin(t * 1.8 + side) * c.arms * amp
					entry.motor.C0 = entry.base * CFrame.Angles(math.rad(swing), 0, math.rad(side * 4))
				end
			end
		end
	end
end

RunService.Heartbeat:Connect(step)

return Expressions
