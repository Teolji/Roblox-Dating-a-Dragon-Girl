--[[
	IntroUI
	Explorer: StarterPlayer > StarterPlayerScripts > HearthscaleClient > UI > IntroUI (ModuleScript)

	Opening narration on a brand-new story (tap / press any key to skip
	ahead). Afterwards the waypoint points at Saffron.
]]

local ContextActionService = game:GetService("ContextActionService")
local TweenService = game:GetService("TweenService")

local Theme = require(script.Parent.Theme)
local Root = require(script.Parent.Root)
local Session = require(script.Parent.Parent.Controllers.Session)

local IntroUI = {}

local LINES = {
	"You were supposed to land in Port Avelline.",
	"The wind had other plans.",
	"So, it turns out, did a roof.",
	"CRASH.",
}

function IntroUI.play()
	Session.setMode("cinematic", true)
	local reduce = Session.settings().reduceMotion
	local screen = Theme.new("TextButton", {
		Name = "Intro",
		Text = "",
		AutoButtonColor = false,
		BackgroundColor3 = Color3.new(0, 0, 0),
		Size = UDim2.fromScale(1, 1),
		Parent = Root.layers.cinematic,
	})
	local text = Theme.label({
		Text = "",
		Font = Theme.Fonts.title,
		TextColor3 = Theme.Colors.gold,
		TextSizeBase = 34,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
		AutomaticSize = Enum.AutomaticSize.None,
		Size = UDim2.fromScale(1, 0.8),
		Parent = screen,
	})
	Theme.label({
		Text = `{Session.Config.GameTitle}`,
		Font = Theme.Fonts.title,
		TextColor3 = Theme.Colors.ember,
		TextSizeBase = 20,
		TextXAlignment = Enum.TextXAlignment.Center,
		AutomaticSize = Enum.AutomaticSize.None,
		Position = UDim2.fromScale(0, 0.85),
		Size = UDim2.new(1, 0, 0, 30),
		Parent = screen,
	})
	local advanceSignal = Instance.new("BindableEvent")
	screen.Activated:Connect(function()
		advanceSignal:Fire()
	end)
	ContextActionService:BindActionAtPriority(
		"HearthscaleIntro",
		function(_name, inputState)
			if inputState == Enum.UserInputState.Begin then
				advanceSignal:Fire()
			end
			return Enum.ContextActionResult.Sink
		end,
		false,
		Enum.ContextActionPriority.High.Value + 10,
		Enum.KeyCode.Space,
		Enum.KeyCode.Return,
		Enum.KeyCode.ButtonA
	)

	for _, line in ipairs(LINES) do
		text.Text = line
		text.TextTransparency = reduce and 0 or 1
		if not reduce then
			TweenService:Create(text, TweenInfo.new(0.6), { TextTransparency = 0 }):Play()
		end
		local fired = false
		local connection = advanceSignal.Event:Connect(function()
			fired = true
		end)
		local started = os.clock()
		while not fired and os.clock() - started < 2.6 do
			task.wait()
		end
		connection:Disconnect()
	end
	ContextActionService:UnbindAction("HearthscaleIntro")
	if not reduce then
		local fade = TweenService:Create(screen, TweenInfo.new(1), { BackgroundTransparency = 1 })
		TweenService:Create(text, TweenInfo.new(0.6), { TextTransparency = 1 }):Play()
		fade:Play()
		fade.Completed:Wait()
	end
	screen:Destroy()
	advanceSignal:Destroy()
	Session.setMode("cinematic", false)
	Session.request("setFlag", { flag = "intro_seen" })
end

return IntroUI
