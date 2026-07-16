local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer

----------------------------------------------------------------
-- KEY SYSTEM CONFIGURATION
----------------------------------------------------------------
-- REPLACE THIS WITH YOUR ACTUAL GITHUB RAW URL
local KEYS_URL = "https://github.com/SOURVRDEV/BludClient/blob/main/keys.txt"

local validKeys = {}
local keyValidated = false
local usedKeys = {}
local keysLoaded = false
local loadError = nil

----------------------------------------------------------------
-- FETCH KEYS FROM GITHUB
----------------------------------------------------------------
local function fetchKeysFromGitHub()
	-- Check if HttpService is available
	if not HttpService then
		loadError = "HttpService not available"
		return false
	end
	
	local success, result = pcall(function()
		-- Set a timeout by using a simple request
		return HttpService:GetAsync(KEYS_URL, true) -- true = cache
	end)
	
	if success then
		-- Clear existing keys
		validKeys = {}
		
		-- Parse keys (one per line)
		for line in result:gmatch("[^\r\n]+") do
			local key = line:gsub("^%s*(.-)%s*$", "%1") -- Trim whitespace
			if key ~= "" and not key:match("^%-%-") and not key:match("^#") then
				-- Ignore empty lines, lua comments (--), and hash comments (#)
				table.insert(validKeys, key)
			end
		end
		
		if #validKeys == 0 then
			loadError = "No keys found in file"
			return false
		end
		
		keysLoaded = true
		loadError = nil
		return true
	else
		loadError = tostring(result)
		return false
	end
end

-- Debug function - call this to test your URL
local function testConnection()
	local success, result = pcall(function()
		return HttpService:GetAsync(KEYS_URL)
	end)
	
	if success then
		print("✅ Connection successful!")
		print("Response preview:", string.sub(result, 1, 100))
		return true
	else
		warn("❌ Connection failed:", result)
		return false
	end
end

----------------------------------------------------------------
-- SETTINGS
----------------------------------------------------------------
local settings = {
	highlightColor = Color3.fromRGB(255, 0, 0),
	outlineColor = Color3.fromRGB(255, 255, 0),
	flySpeed = 50,
	speedMultiplier = 2
}

----------------------------------------------------------------
-- KEY SYSTEM GUI
----------------------------------------------------------------
local keyGui = Instance.new("ScreenGui")
keyGui.Name = "KeySystemGui"
keyGui.ResetOnSpawn = false
keyGui.Parent = player:WaitForChild("PlayerGui")

local keyFrame = Instance.new("Frame")
keyFrame.Name = "KeyFrame"
keyFrame.Size = UDim2.new(0, 350, 0, 220)
keyFrame.Position = UDim2.new(0.5, -175, 0.5, -110)
keyFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
keyFrame.BorderSizePixel = 0
keyFrame.ZIndex = 10
keyFrame.Parent = keyGui

local keyFrameCorner = Instance.new("UICorner")
keyFrameCorner.CornerRadius = UDim.new(0, 12)
keyFrameCorner.Parent = keyFrame

local keyFrameStroke = Instance.new("UIStroke")
keyFrameStroke.Color = Color3.fromRGB(60, 60, 60)
keyFrameStroke.Thickness = 1.5
keyFrameStroke.Parent = keyFrame

-- Title
local keyTitle = Instance.new("TextLabel")
keyTitle.Name = "Title"
keyTitle.Size = UDim2.new(1, -20, 0, 40)
keyTitle.Position = UDim2.new(0, 10, 0, 15)
keyTitle.BackgroundTransparency = 1
keyTitle.Text = "Blud Client - Key System"
keyTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
keyTitle.TextScaled = true
keyTitle.Font = Enum.Font.GothamBold
keyTitle.ZIndex = 10
keyTitle.Parent = keyFrame

-- Subtitle
local keySubtitle = Instance.new("TextLabel")
keySubtitle.Name = "Subtitle"
keySubtitle.Size = UDim2.new(1, -20, 0, 20)
keySubtitle.Position = UDim2.new(0, 10, 0, 55)
keySubtitle.BackgroundTransparency = 1
keySubtitle.Text = "Enter your access key to continue"
keySubtitle.TextColor3 = Color3.fromRGB(180, 180, 180)
keySubtitle.TextScaled = true
keySubtitle.Font = Enum.Font.Gotham
keySubtitle.ZIndex = 10
keySubtitle.Parent = keyFrame

-- Key Input Box
local keyInputBox = Instance.new("TextBox")
keyInputBox.Name = "KeyInput"
keyInputBox.Size = UDim2.new(1, -40, 0, 45)
keyInputBox.Position = UDim2.new(0, 20, 0, 85)
keyInputBox.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
keyInputBox.Text = ""
keyInputBox.PlaceholderText = "Enter key here..."
keyInputBox.TextColor3 = Color3.fromRGB(255, 255, 255)
keyInputBox.PlaceholderColor3 = Color3.fromRGB(120, 120, 120)
keyInputBox.TextScaled = true
keyInputBox.Font = Enum.Font.Gotham
keyInputBox.ClearTextOnFocus = false
keyInputBox.ZIndex = 10
keyInputBox.Parent = keyFrame

local keyInputCorner = Instance.new("UICorner")
keyInputCorner.CornerRadius = UDim.new(0, 8)
keyInputCorner.Parent = keyInputBox

local keyInputStroke = Instance.new("UIStroke")
keyInputStroke.Color = Color3.fromRGB(80, 80, 80)
keyInputStroke.Thickness = 1
keyInputStroke.Parent = keyInputBox

-- Validate Button
local validateButton = Instance.new("TextButton")
validateButton.Name = "ValidateButton"
validateButton.Size = UDim2.new(1, -40, 0, 45)
validateButton.Position = UDim2.new(0, 20, 0, 140)
validateButton.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
validateButton.Text = "Validate Key"
validateButton.TextColor3 = Color3.fromRGB(255, 255, 255)
validateButton.TextScaled = true
validateButton.Font = Enum.Font.GothamBold
validateButton.AutoButtonColor = false
validateButton.ZIndex = 10
validateButton.Parent = keyFrame

local validateCorner = Instance.new("UICorner")
validateCorner.CornerRadius = UDim.new(0, 8)
validateCorner.Parent = validateButton

-- Status Label (larger for error messages)
local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "StatusLabel"
statusLabel.Size = UDim2.new(1, -20, 0, 40)
statusLabel.Position = UDim2.new(0, 10, 0, 190)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = ""
statusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
statusLabel.TextScaled = false
statusLabel.TextSize = 12
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextWrapped = true
statusLabel.ZIndex = 10
statusLabel.Parent = keyFrame

-- Loading Frame
local loadingFrame = Instance.new("Frame")
loadingFrame.Name = "LoadingFrame"
loadingFrame.Size = UDim2.new(0, 350, 0, 220)
loadingFrame.Position = UDim2.new(0.5, -175, 0.5, -110)
loadingFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
loadingFrame.BorderSizePixel = 0
loadingFrame.ZIndex = 20
loadingFrame.Visible = false
loadingFrame.Parent = keyGui

local loadingCorner = Instance.new("UICorner")
loadingCorner.CornerRadius = UDim.new(0, 12)
loadingCorner.Parent = loadingFrame

local loadingText = Instance.new("TextLabel")
loadingText.Size = UDim2.new(1, -20, 0, 60)
loadingText.Position = UDim2.new(0, 10, 0.5, -30)
loadingText.BackgroundTransparency = 1
loadingText.Text = "Connecting to server..."
loadingText.TextColor3 = Color3.fromRGB(255, 255, 255)
loadingText.TextScaled = true
loadingText.Font = Enum.Font.GothamBold
loadingText.ZIndex = 20
loadingText.Parent = loadingFrame

-- Button hover effects
local validateDefault = Color3.fromRGB(0, 120, 255)
local validateHover = Color3.fromRGB(0, 150, 255)
local validateClick = Color3.fromRGB(0, 100, 220)

validateButton.MouseEnter:Connect(function()
	TweenService:Create(validateButton, TweenInfo.new(0.15), {BackgroundColor3 = validateHover}):Play()
end)

validateButton.MouseLeave:Connect(function()
	TweenService:Create(validateButton, TweenInfo.new(0.15), {BackgroundColor3 = validateDefault}):Play()
end)

validateButton.MouseButton1Down:Connect(function()
	TweenService:Create(validateButton, TweenInfo.new(0.1), {BackgroundColor3 = validateClick}):Play()
end)

validateButton.MouseButton1Up:Connect(function()
	TweenService:Create(validateButton, TweenInfo.new(0.1), {BackgroundColor3 = validateHover}):Play()
end)

-- Validation Function
local function validateKey()
	local enteredKey = keyInputBox.Text:gsub("%s+", "")
	
	if enteredKey == "" then
		statusLabel.Text = "Please enter a key"
		statusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
		return
	end
	
	-- Show loading
	loadingFrame.Visible = true
	statusLabel.Text = ""
	
	-- Small delay to allow UI to update
	task.wait(0.1)
	
	-- Fetch keys if not loaded
	if not keysLoaded then
		local success = fetchKeysFromGitHub()
		loadingFrame.Visible = false
		
		if not success then
			-- Show detailed error
			if loadError:match("HTTP 403") then
				statusLabel.Text = "Error: HTTP Requests not enabled in game settings"
			elseif loadError:match("HTTP 404") then
				statusLabel.Text = "Error: Keys file not found. Check URL."
			elseif loadError:match("HttpRequests") or loadError:match("not enabled") then
				statusLabel.Text = "Error: Enable HTTP Requests in Game Settings > Security"
			elseif loadError:match("HttpService") then
				statusLabel.Text = "Error: HttpService not available"
			else
				statusLabel.Text = "Error: " .. string.sub(loadError, 1, 50)
			end
			statusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
			return
		end
	else
		loadingFrame.Visible = false
	end
	
	-- Check if key was already used
	if usedKeys[enteredKey] then
		statusLabel.Text = "Key already redeemed"
		statusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
		return
	end
	
	-- Check if key is valid
	local keyFound = false
	for _, validKey in ipairs(validKeys) do
		if enteredKey == validKey then
			keyFound = true
			usedKeys[enteredKey] = true
			break
		end
	end
	
	if keyFound then
		statusLabel.Text = "Key validated! Loading..."
		statusLabel.TextColor3 = Color3.fromRGB(80, 255, 80)
		
		TweenService:Create(keyFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
			Size = UDim2.new(0, 0, 0, 0),
			Position = UDim2.new(0.5, 0, 0.5, 0)
		}):Play()
		
		task.wait(0.5)
		keyGui:Destroy()
		keyValidated = true
		initializeBludClient()
	else
		statusLabel.Text = "Invalid key"
		statusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
		
		-- Shake animation
		local originalPos = keyFrame.Position
		for i = 1, 5 do
			keyFrame.Position = UDim2.new(originalPos.X.Scale, originalPos.X.Offset + 5, originalPos.Y.Scale, originalPos.Y.Offset)
			task.wait(0.03)
			keyFrame.Position = UDim2.new(originalPos.X.Scale, originalPos.X.Offset - 5, originalPos.Y.Scale, originalPos.Y.Offset)
			task.wait(0.03)
		end
		keyFrame.Position = originalPos
	end
end

validateButton.MouseButton1Click:Connect(validateKey)

keyInputBox.FocusLost:Connect(function(enterPressed)
	if enterPressed then
		validateKey()
	end
end)

-- Draggable function
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

makeDraggable(keyFrame, keyFrame)

-- Optional: Auto-test on load (uncomment to test)
-- task.spawn(function()
-- 	task.wait(2)
-- 	testConnection()
-- end)

----------------------------------------------------------------
-- MAIN BLUD CLIENT INITIALIZATION (your existing code)
----------------------------------------------------------------
function initializeBludClient()
	-- [Your existing Blud Client code here...]
	-- (Highlight, Fly, Speed Boost, GUI setup, etc.)
	
	-- Placeholder message since you have the full code
	print("Blud Client initialized!")
end
