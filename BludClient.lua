local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

----------------------------------------------------------------
-- SETTINGS (editable via right-click popups)
----------------------------------------------------------------
local settings = {
	highlightColor = Color3.fromRGB(255, 0, 0),
	outlineColor = Color3.fromRGB(255, 255, 0),
	flySpeed = 50,
	speedMultiplier = 2
}

----------------------------------------------------------------
-- HIGHLIGHT TOGGLE
----------------------------------------------------------------
local highlightEnabled = false

local function applyHighlight(character)
	if not character then return end
	local existing = character:FindFirstChild("Highlight")
	if existing then existing:Destroy() end

	local highlight = Instance.new("Highlight")
	highlight.FillColor = settings.highlightColor
	highlight.OutlineColor = settings.outlineColor
	highlight.FillTransparency = 0.5
	highlight.Parent = character
end

local function removeHighlight(character)
	if not character then return end
	local existing = character:FindFirstChild("Highlight")
	if existing then existing:Destroy() end
end

local function refreshAllHighlights()
	for _, p in ipairs(Players:GetPlayers()) do
		if p.Character then
			if highlightEnabled then
				applyHighlight(p.Character)
			else
				removeHighlight(p.Character)
			end
		end
	end
end

local function toggleHighlights()
	highlightEnabled = not highlightEnabled
	refreshAllHighlights()
end

Players.PlayerAdded:Connect(function(p)
	p.CharacterAdded:Connect(function(character)
		if highlightEnabled then
			applyHighlight(character)
		end
	end)
end)

for _, p in ipairs(Players:GetPlayers()) do
	p.CharacterAdded:Connect(function(character)
		if highlightEnabled then
			applyHighlight(character)
		end
	end)
end

----------------------------------------------------------------
-- FLY FUNCTION
----------------------------------------------------------------
local flying = false
local bodyVelocity, bodyGyro, flyConnection
local keys = {w=false, a=false, s=false, d=false, space=false, shift=false}

local function startFly()
	local character = player.Character
	if not character then return end
	local hrp = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not hrp or not humanoid then return end

	flying = true
	humanoid.PlatformStand = true

	bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
	bodyVelocity.Velocity = Vector3.new(0, 0, 0)
	bodyVelocity.Parent = hrp

	bodyGyro = Instance.new("BodyGyro")
	bodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
	bodyGyro.P = 3000
	bodyGyro.Parent = hrp

	flyConnection = RunService.RenderStepped:Connect(function()
		local camera = workspace.CurrentCamera
		local moveVector = Vector3.new(0, 0, 0)

		if keys.w then moveVector += camera.CFrame.LookVector end
		if keys.s then moveVector -= camera.CFrame.LookVector end
		if keys.a then moveVector -= camera.CFrame.RightVector end
		if keys.d then moveVector += camera.CFrame.RightVector end
		if keys.space then moveVector += Vector3.new(0, 1, 0) end
		if keys.shift then moveVector -= Vector3.new(0, 1, 0) end

		if moveVector.Magnitude > 0 then
			moveVector = moveVector.Unit * settings.flySpeed
		end

		bodyVelocity.Velocity = moveVector
		bodyGyro.CFrame = camera.CFrame
	end)
end

local function stopFly()
	flying = false
	local character = player.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then humanoid.PlatformStand = false end
	end
	if bodyVelocity then bodyVelocity:Destroy() end
	if bodyGyro then bodyGyro:Destroy() end
	if flyConnection then flyConnection:Disconnect() end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.W then keys.w = true end
	if input.KeyCode == Enum.KeyCode.A then keys.a = true end
	if input.KeyCode == Enum.KeyCode.S then keys.s = true end
	if input.KeyCode == Enum.KeyCode.D then keys.d = true end
	if input.KeyCode == Enum.KeyCode.Space then keys.space = true end
	if input.KeyCode == Enum.KeyCode.LeftShift then keys.shift = true end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
	if input.KeyCode == Enum.KeyCode.W then keys.w = false end
	if input.KeyCode == Enum.KeyCode.A then keys.a = false end
	if input.KeyCode == Enum.KeyCode.S then keys.s = false end
	if input.KeyCode == Enum.KeyCode.D then keys.d = false end
	if input.KeyCode == Enum.KeyCode.Space then keys.space = false end
	if input.KeyCode == Enum.KeyCode.LeftShift then keys.shift = false end
end)

----------------------------------------------------------------
-- SPEED BOOST FUNCTION
----------------------------------------------------------------
local speedBoostEnabled = false
local baseWalkSpeed = 16 -- Roblox default

local function getHumanoid()
	local character = player.Character
	if not character then return nil end
	return character:FindFirstChildOfClass("Humanoid")
end

local function applySpeedBoost()
	local humanoid = getHumanoid()
	if humanoid then
		humanoid.WalkSpeed = baseWalkSpeed * settings.speedMultiplier
	end
end

local function removeSpeedBoost()
	local humanoid = getHumanoid()
	if humanoid then
		humanoid.WalkSpeed = baseWalkSpeed
	end
end

local function toggleSpeedBoost()
	speedBoostEnabled = not speedBoostEnabled
	if speedBoostEnabled then
		applySpeedBoost()
	else
		removeSpeedBoost()
	end
end

-- Reapply speed boost on respawn if it's still toggled on
player.CharacterAdded:Connect(function(character)
	local humanoid = character:WaitForChild("Humanoid")
	baseWalkSpeed = humanoid.WalkSpeed
	if speedBoostEnabled then
		humanoid.WalkSpeed = baseWalkSpeed * settings.speedMultiplier
	end
end)

if player.Character then
	local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		baseWalkSpeed = humanoid.WalkSpeed
	end
end

----------------------------------------------------------------
-- GUI SETUP
----------------------------------------------------------------
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "BludClientGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

----------------------------------------------------------------
-- MAIN FRAME
----------------------------------------------------------------
local frame = Instance.new("Frame")
frame.Name = "MainFrame"
frame.Size = UDim2.new(0, 220, 0, 245)
frame.Position = UDim2.new(0, 20, 0, 20)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
frame.BorderSizePixel = 0
frame.ZIndex = 2
frame.Parent = screenGui

local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 12)
frameCorner.Parent = frame

local frameStroke = Instance.new("UIStroke")
frameStroke.Color = Color3.fromRGB(60, 60, 60)
frameStroke.Thickness = 1.5
frameStroke.Parent = frame

local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 40)
titleBar.BackgroundTransparency = 1
titleBar.ZIndex = 2
titleBar.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -40, 1, 0)
title.Position = UDim2.new(0, 10, 0, 0)
title.BackgroundTransparency = 1
title.Text = "Blud Client"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextScaled = true
title.TextXAlignment = Enum.TextXAlignment.Left
title.Font = Enum.Font.GothamBold
title.ZIndex = 2
title.Parent = titleBar

local titleDivider = Instance.new("Frame")
titleDivider.Size = UDim2.new(1, -20, 0, 1)
titleDivider.Position = UDim2.new(0, 10, 0, 40)
titleDivider.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
titleDivider.BorderSizePixel = 0
titleDivider.ZIndex = 2
titleDivider.Parent = frame

local minimizeButton = Instance.new("TextButton")
minimizeButton.Size = UDim2.new(0, 24, 0, 24)
minimizeButton.Position = UDim2.new(1, -32, 0, 8)
minimizeButton.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
minimizeButton.Text = "-"
minimizeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
minimizeButton.TextScaled = true
minimizeButton.Font = Enum.Font.GothamBold
minimizeButton.AutoButtonColor = false
minimizeButton.ZIndex = 2
minimizeButton.Parent = titleBar

local minimizeCorner = Instance.new("UICorner")
minimizeCorner.CornerRadius = UDim.new(0, 6)
minimizeCorner.Parent = minimizeButton

local content = Instance.new("Frame")
content.Name = "Content"
content.Size = UDim2.new(1, -20, 0, 185)
content.Position = UDim2.new(0, 10, 0, 50)
content.BackgroundTransparency = 1
content.ZIndex = 2
content.Parent = frame

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 10)
layout.Parent = content

local function createButton(text, order)
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(1, 0, 0, 45)
	button.LayoutOrder = order
	button.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	button.Text = text
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.TextScaled = true
	button.Font = Enum.Font.GothamMedium
	button.AutoButtonColor = false
	button.ZIndex = 2
	button.Parent = content

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = button

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(80, 80, 80)
	stroke.Thickness = 1
	stroke.Parent = button

	local defaultColor = Color3.fromRGB(45, 45, 45)
	local hoverColor = Color3.fromRGB(65, 65, 65)
	local clickColor = Color3.fromRGB(90, 90, 90)

	local function tweenColor(color, duration)
		TweenService:Create(button, TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
			BackgroundColor3 = color
		}):Play()
	end

	local function tweenSize(size, duration)
		TweenService:Create(button, TweenInfo.new(duration, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = size
		}):Play()
	end

	button.MouseEnter:Connect(function() tweenColor(hoverColor, 0.15) end)
	button.MouseLeave:Connect(function() tweenColor(defaultColor, 0.15) end)
	button.MouseButton1Down:Connect(function()
		tweenColor(clickColor, 0.1)
		tweenSize(UDim2.new(1, -6, 0, 42), 0.1)
	end)
	button.MouseButton1Up:Connect(function()
		tweenColor(hoverColor, 0.15)
		tweenSize(UDim2.new(1, 0, 0, 45), 0.15)
	end)

	return button
end

local highlightButton = createButton("Highlight: OFF", 1)
highlightButton.MouseButton1Click:Connect(function()
	toggleHighlights()
	highlightButton.Text = highlightEnabled and "Highlight: ON" or "Highlight: OFF"
end)

local flyButton = createButton("Fly: OFF", 2)
flyButton.MouseButton1Click:Connect(function()
	if flying then
		stopFly()
		flyButton.Text = "Fly: OFF"
	else
		startFly()
		flyButton.Text = "Fly: ON"
	end
end)

local speedBoostButton = createButton("Speed Boost: OFF", 3)
speedBoostButton.MouseButton1Click:Connect(function()
	toggleSpeedBoost()
	speedBoostButton.Text = speedBoostEnabled and "Speed Boost: ON" or "Speed Boost: OFF"
end)

----------------------------------------------------------------
-- MINIMIZE LOGIC
----------------------------------------------------------------
local minimized = false
local expandedSize = UDim2.new(0, 220, 0, 245)
local minimizedSize = UDim2.new(0, 220, 0, 40)

minimizeButton.MouseButton1Click:Connect(function()
	minimized = not minimized
	content.Visible = not minimized
	minimizeButton.Text = minimized and "+" or "-"
	TweenService:Create(frame, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
		Size = minimized and minimizedSize or expandedSize
	}):Play()
end)

----------------------------------------------------------------
-- DRAGGING HELPER
----------------------------------------------------------------
local function makeDraggable(dragHandle, target)
	local dragging = false
	local dragInput, dragStart, startPos

	dragHandle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = target.Position

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	dragHandle.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			local delta = input.Position - dragStart
			target.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y
			)
		end
	end)
end

makeDraggable(titleBar, frame)

----------------------------------------------------------------
-- GENERIC SETTINGS POPUP CREATOR
----------------------------------------------------------------
-- rows: list of {label, default, callback}
local function createSettingsPopup(popupTitle, rows)
	local popup = Instance.new("Frame")
	popup.Name = popupTitle .. "Popup"
	popup.Size = UDim2.new(0, 200, 0, 40 + (#rows * 45) + 10)
	popup.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	popup.BorderSizePixel = 0
	popup.Visible = false
	popup.ZIndex = 5
	popup.Parent = screenGui

	local popupCorner = Instance.new("UICorner")
	popupCorner.CornerRadius = UDim.new(0, 12)
	popupCorner.Parent = popup

	local popupStroke = Instance.new("UIStroke")
	popupStroke.Color = Color3.fromRGB(60, 60, 60)
	popupStroke.Thickness = 1.5
	popupStroke.Parent = popup

	local popupTitleBar = Instance.new("Frame")
	popupTitleBar.Size = UDim2.new(1, 0, 0, 34)
	popupTitleBar.BackgroundTransparency = 1
	popupTitleBar.ZIndex = 5
	popupTitleBar.Parent = popup

	local popupTitleLabel = Instance.new("TextLabel")
	popupTitleLabel.Size = UDim2.new(1, -40, 1, 0)
	popupTitleLabel.Position = UDim2.new(0, 10, 0, 0)
	popupTitleLabel.BackgroundTransparency = 1
	popupTitleLabel.Text = popupTitle
	popupTitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	popupTitleLabel.TextScaled = true
	popupTitleLabel.TextXAlignment = Enum.TextXAlignment.Left
	popupTitleLabel.Font = Enum.Font.GothamBold
	popupTitleLabel.ZIndex = 5
	popupTitleLabel.Parent = popupTitleBar

	-- Close button
	local closeButton = Instance.new("TextButton")
	closeButton.Size = UDim2.new(0, 22, 0, 22)
	closeButton.Position = UDim2.new(1, -30, 0, 6)
	closeButton.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	closeButton.Text = "X"
	closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeButton.TextScaled = true
	closeButton.Font = Enum.Font.GothamBold
	closeButton.AutoButtonColor = false
	closeButton.ZIndex = 5
	closeButton.Parent = popupTitleBar

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 6)
	closeCorner.Parent = closeButton

	closeButton.MouseEnter:Connect(function()
		TweenService:Create(closeButton, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(150, 40, 40)}):Play()
	end)
	closeButton.MouseLeave:Connect(function()
		TweenService:Create(closeButton, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(45, 45, 45)}):Play()
	end)
	closeButton.MouseButton1Click:Connect(function()
		popup.Visible = false
	end)

	local popupDivider = Instance.new("Frame")
	popupDivider.Size = UDim2.new(1, -20, 0, 1)
	popupDivider.Position = UDim2.new(0, 10, 0, 34)
	popupDivider.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	popupDivider.BorderSizePixel = 0
	popupDivider.ZIndex = 5
	popupDivider.Parent = popup

	local popupContent = Instance.new("Frame")
	popupContent.Size = UDim2.new(1, -20, 1, -44)
	popupContent.Position = UDim2.new(0, 10, 0, 40)
	popupContent.BackgroundTransparency = 1
	popupContent.ZIndex = 5
	popupContent.Parent = popup

	local popupLayout = Instance.new("UIListLayout")
	popupLayout.Padding = UDim.new(0, 8)
	popupLayout.Parent = popupContent

	for i, rowData in ipairs(rows) do
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, 0, 0, 36)
		row.LayoutOrder = i
		row.BackgroundTransparency = 1
		row.ZIndex = 5
		row.Parent = popupContent

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(0.55, 0, 1, 0)
		label.BackgroundTransparency = 1
		label.Text = rowData.label
		label.TextColor3 = Color3.fromRGB(220, 220, 220)
		label.TextScaled = true
		label.Font = Enum.Font.Gotham
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.ZIndex = 5
		label.Parent = row

		local box = Instance.new("TextBox")
		box.Size = UDim2.new(0.45, -5, 1, -6)
		box.Position = UDim2.new(0.55, 5, 0, 3)
		box.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
		box.Text = tostring(rowData.default)
		box.TextColor3 = Color3.fromRGB(255, 255, 255)
		box.TextScaled = true
		box.Font = Enum.Font.Gotham
		box.ClearTextOnFocus = false
		box.ZIndex = 5
		box.Parent = row

		local boxCorner = Instance.new("UICorner")
		boxCorner.CornerRadius = UDim.new(0, 6)
		boxCorner.Parent = box

		box.FocusLost:Connect(function()
			local num = tonumber(box.Text)
			if num then
				num = math.clamp(num, rowData.min or 0, rowData.max or 10000)
				box.Text = tostring(num)
				rowData.callback(num)
			else
				box.Text = tostring(rowData.default)
			end
		end)
	end

	makeDraggable(popupTitleBar, popup)

	return popup
end

----------------------------------------------------------------
-- HIGHLIGHT SETTINGS POPUP
----------------------------------------------------------------
local highlightPopup = createSettingsPopup("Highlight Settings", {
	{
		label = "Fill R",
		default = math.floor(settings.highlightColor.R * 255),
		min = 0, max = 255,
		callback = function(val)
			settings.highlightColor = Color3.fromRGB(val, settings.highlightColor.G * 255, settings.highlightColor.B * 255)
			if highlightEnabled then refreshAllHighlights() end
		end
	},
	{
		label = "Fill G",
		default = math.floor(settings.highlightColor.G * 255),
		min = 0, max = 255,
		callback = function(val)
			settings.highlightColor = Color3.fromRGB(settings.highlightColor.R * 255, val, settings.highlightColor.B * 255)
			if highlightEnabled then refreshAllHighlights() end
		end
	},
	{
		label = "Fill B",
		default = math.floor(settings.highlightColor.B * 255),
		min = 0, max = 255,
		callback = function(val)
			settings.highlightColor = Color3.fromRGB(settings.highlightColor.R * 255, settings.highlightColor.G * 255, val)
			if highlightEnabled then refreshAllHighlights() end
		end
	},
	{
		label = "Outline R",
		default = math.floor(settings.outlineColor.R * 255),
		min = 0, max = 255,
		callback = function(val)
			settings.outlineColor = Color3.fromRGB(val, settings.outlineColor.G * 255, settings.outlineColor.B * 255)
			if highlightEnabled then refreshAllHighlights() end
		end
	},
	{
		label = "Outline G",
		default = math.floor(settings.outlineColor.G * 255),
		min = 0, max = 255,
		callback = function(val)
			settings.outlineColor = Color3.fromRGB(settings.outlineColor.R * 255, val, settings.outlineColor.B * 255)
			if highlightEnabled then refreshAllHighlights() end
		end
	},
	{
		label = "Outline B",
		default = math.floor(settings.outlineColor.B * 255),
		min = 0, max = 255,
		callback = function(val)
			settings.outlineColor = Color3.fromRGB(settings.outlineColor.R * 255, settings.outlineColor.G * 255, val)
			if highlightEnabled then refreshAllHighlights() end
		end
	}
})

----------------------------------------------------------------
-- FLY SETTINGS POPUP
----------------------------------------------------------------
local flyPopup = createSettingsPopup("Fly Settings", {
	{
		label = "Fly Speed",
		default = settings.flySpeed,
		min = 1, max = 500,
		callback = function(val)
			settings.flySpeed = val
		end
	}
})

----------------------------------------------------------------
-- SPEED BOOST SETTINGS POPUP
----------------------------------------------------------------
local speedPopup = createSettingsPopup("Speed Boost Settings", {
	{
		label = "Multiplier",
		default = settings.speedMultiplier,
		min = 0.1, max = 20,
		callback = function(val)
			settings.speedMultiplier = val
			if speedBoostEnabled then applySpeedBoost() end
		end
	}
})

----------------------------------------------------------------
-- RIGHT-CLICK HANDLERS TO OPEN POPUPS NEXT TO THEIR BUTTON
----------------------------------------------------------------
local allPopups = {highlightPopup, flyPopup, speedPopup}

local function openPopupNear(popup, button)
	-- Position popup to the right of the main frame, aligned with the button
	local absPos = frame.Position
	popup.Position = UDim2.new(0, absPos.X.Offset + 230, 0, absPos.Y.Offset + button.Position.Y.Offset + 50)
	popup.Visible = true
	-- Close all other popups
	for _, p in ipairs(allPopups) do
		if p ~= popup then
			p.Visible = false
		end
	end
end

highlightButton.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		openPopupNear(highlightPopup, highlightButton)
	end
end)

flyButton.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		openPopupNear(flyPopup, flyButton)
	end
end)

speedBoostButton.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		openPopupNear(speedPopup, speedBoostButton)
	end
end)
