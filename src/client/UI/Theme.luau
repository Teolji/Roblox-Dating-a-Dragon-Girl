--[[
	Theme
	Explorer: StarterPlayer > StarterPlayerScripts > HearthscaleClient > UI > Theme (ModuleScript)

	Colours, fonts and small builders shared by every screen. Text sizes are
	registered so they rescale live when the viewport or the player's UI
	scale setting changes (phones get readable text without overflowing).
	Icons are emoji PLACEHOLDERS — replace with image ids when art exists.
]]

local Players = game:GetService("Players")

local Theme = {}

Theme.Colors = {
	ink = Color3.fromRGB(58, 40, 34),
	inkSoft = Color3.fromRGB(110, 86, 74),
	paper = Color3.fromRGB(251, 243, 228),
	paperDark = Color3.fromRGB(238, 222, 196),
	panel = Color3.fromRGB(46, 34, 40),
	panelSoft = Color3.fromRGB(70, 54, 60),
	ember = Color3.fromRGB(232, 122, 58),
	emberDark = Color3.fromRGB(176, 78, 40),
	gold = Color3.fromRGB(240, 196, 98),
	teal = Color3.fromRGB(86, 168, 160),
	rose = Color3.fromRGB(222, 104, 128),
	good = Color3.fromRGB(110, 170, 96),
	bad = Color3.fromRGB(200, 82, 72),
	white = Color3.fromRGB(255, 255, 255),
	locked = Color3.fromRGB(150, 140, 136),
}

local function font(name: string, fallback: Enum.Font): Enum.Font
	local ok, result = pcall(function()
		return (Enum.Font :: any)[name]
	end)
	return if ok and result then result else fallback
end

Theme.Fonts = {
	title = font("FredokaOne", Enum.Font.SourceSansBold),
	body = font("Nunito", Enum.Font.SourceSans),
	bold = font("GothamBold", Enum.Font.SourceSansBold),
}

Theme.Icons = {
	journal = "📖",
	bag = "🎒",
	bond = "💛",
	settings = "⚙️",
	close = "✕",
	heart = "♥",
	check = "✓",
	cross = "✗",
}

-- Scaling -------------------------------------------------------------------
local userScale = 1
local registry = setmetatable({}, { __mode = "k" }) -- [TextObject] = base size

function Theme.factor(): number
	local camera = workspace.CurrentCamera
	local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
	local short = math.min(viewport.X, viewport.Y)
	return math.clamp(short / 720, 0.72, 1.3) * userScale
end

function Theme.size(base: number): number
	return math.floor(base * Theme.factor() + 0.5)
end

function Theme.bindText(object: TextLabel | TextButton, base: number)
	registry[object] = base
	object.TextSize = Theme.size(base)
end

function Theme.refresh()
	for object, base in pairs(registry) do
		if object.Parent then
			object.TextSize = Theme.size(base)
		end
	end
end

function Theme.setUserScale(scale: number)
	if math.abs(scale - userScale) > 0.001 then
		userScale = scale
		Theme.refresh()
	end
end

task.defer(function()
	local camera = workspace.CurrentCamera
	if camera then
		camera:GetPropertyChangedSignal("ViewportSize"):Connect(Theme.refresh)
	end
end)

-- Builders --------------------------------------------------------------------
function Theme.new(className: string, props: { [string]: any }?, children: { Instance }?): any
	local object = Instance.new(className)
	local parent = nil
	for key, value in pairs(props or {}) do
		if key == "Parent" then
			parent = value
		else
			(object :: any)[key] = value
		end
	end
	for _, child in ipairs(children or {}) do
		child.Parent = object
	end
	if parent then
		object.Parent = parent
	end
	return object
end

function Theme.corner(radius: number?): UICorner
	return Theme.new("UICorner", { CornerRadius = UDim.new(0, radius or 12) })
end

function Theme.stroke(color: Color3?, thickness: number?): UIStroke
	return Theme.new("UIStroke", {
		Color = color or Theme.Colors.emberDark,
		Thickness = thickness or 2,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end

function Theme.padding(px: number): UIPadding
	local u = UDim.new(0, px)
	return Theme.new("UIPadding", { PaddingTop = u, PaddingBottom = u, PaddingLeft = u, PaddingRight = u })
end

function Theme.list(padding: number?, horizontal: boolean?): UIListLayout
	return Theme.new("UIListLayout", {
		Padding = UDim.new(0, padding or 8),
		FillDirection = horizontal and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical,
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Left,
	})
end

function Theme.label(props: { [string]: any }): TextLabel
	local base = props.TextSizeBase or 20
	props.TextSizeBase = nil
	local merged = {
		BackgroundTransparency = 1,
		Font = Theme.Fonts.body,
		TextColor3 = Theme.Colors.ink,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.fromScale(1, 0),
		RichText = false,
	}
	for k, v in pairs(props) do
		merged[k] = v
	end
	local label = Theme.new("TextLabel", merged)
	Theme.bindText(label, base)
	return label
end

-- A large, touch-friendly button (min 44pt tall).
function Theme.button(props: { [string]: any }): TextButton
	local base = props.TextSizeBase or 20
	props.TextSizeBase = nil
	local merged = {
		AutoButtonColor = true,
		BackgroundColor3 = Theme.Colors.ember,
		TextColor3 = Theme.Colors.white,
		Font = Theme.Fonts.title,
		Size = UDim2.new(1, 0, 0, 48),
		TextWrapped = true,
		Selectable = true,
	}
	for k, v in pairs(props) do
		merged[k] = v
	end
	local button = Theme.new("TextButton", merged, { Theme.corner(10) })
	Theme.bindText(button, base)
	return button
end

function Theme.player(): Player
	return Players.LocalPlayer
end

function Theme.hex(hex: string?): Color3
	if type(hex) ~= "string" then
		return Theme.Colors.ember
	end
	local ok, color = pcall(Color3.fromHex, hex)
	return ok and color or Theme.Colors.ember
end

return Theme
