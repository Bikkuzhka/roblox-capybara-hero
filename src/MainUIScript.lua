local player = game.Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local MAX_LIVES = 5

-- === Хранилище состояний в player ===
local stateFolder = player:WaitForChild("GuiState")
local scoreValue = stateFolder:FindFirstChild("Score")
if not scoreValue then
	scoreValue = Instance.new("IntValue")
	scoreValue.Name = "Score"
	scoreValue.Value = 0
	scoreValue.Parent = stateFolder
end

local livesValue = stateFolder:FindFirstChild("Lives")
if not livesValue then
	livesValue = Instance.new("IntValue")
	livesValue.Name = "Lives"
	livesValue.Value = MAX_LIVES
	livesValue.Parent = stateFolder
end

local speedBoosterEnd = stateFolder:FindFirstChild("SpeedBoosterEnd")
if not speedBoosterEnd then
	speedBoosterEnd = Instance.new("NumberValue")
	speedBoosterEnd.Name = "SpeedBoosterEnd"
	speedBoosterEnd.Value = 0
	speedBoosterEnd.Parent = stateFolder
end

local slowBoosterEnd = stateFolder:FindFirstChild("SlowBoosterEnd")
if not slowBoosterEnd then
	slowBoosterEnd = Instance.new("NumberValue")
	slowBoosterEnd.Name = "SlowBoosterEnd"
	slowBoosterEnd.Value = 0
	slowBoosterEnd.Parent = stateFolder
end

local magnetBoosterEnd = stateFolder:FindFirstChild("MagnetBoosterEnd")
if not magnetBoosterEnd then
	magnetBoosterEnd = Instance.new("NumberValue")
	magnetBoosterEnd.Name = "MagnetBoosterEnd"
	magnetBoosterEnd.Value = 0
	magnetBoosterEnd.Parent = stateFolder
end

local pulseTweenUp, pulseTweenDown
local isPulsing = false

local function getOrCreateBool(name, default)
	local v = stateFolder:FindFirstChild(name)
	if not v then
		v = Instance.new("BoolValue")
		v.Name = name
		v.Value = default
		v.Parent = stateFolder
	end
	return v
end
local finishVisible = getOrCreateBool("FinishBackgroundVisible", false)
local leaderboardVisible = getOrCreateBool("LeaderboardVisible", false)
local isGameOver = getOrCreateBool("IsGameOver", false)

-- === UI элементы ===
local MainGui = script.Parent
local SideButtonsFrame = MainGui:WaitForChild("SideButtonsFrame")
local ScoreLabel = SideButtonsFrame:WaitForChild("ScoreLabel")
ScoreLabel.Text = "Score: " .. tostring(scoreValue.Value)
scoreValue.Changed:Connect(function(val)
	print("[DEBUG] ScoreValue changed to:", val)
	ScoreLabel.Text = "Score: " .. tostring(val)
end)
local Hearts = {}
for i = 1, MAX_LIVES do
	Hearts[i] = SideButtonsFrame:WaitForChild("Heart" .. i)
end

local BoostTime = SideButtonsFrame:WaitForChild("BoostTime")
local FinishBackground = MainGui:WaitForChild("FinishBackground")
local GameOverBackground = FinishBackground:WaitForChild("GameOverBackground")
local finishrestartButton = GameOverBackground:WaitForChild("FinishRestartButton")
local finishScoreLabel = FinishBackground:WaitForChild("FinishScoreLabel")
local leaderboardButton = GameOverBackground:WaitForChild("LeaderboardButton")
local LeaderboardFrame = MainGui:WaitForChild("LeaderboardFrame")
local leaderboardList = LeaderboardFrame:WaitForChild("LeaderboardList")
local template = leaderboardList:WaitForChild("LeaderboardItemTemplate")
local closeButton = LeaderboardFrame:WaitForChild("CloseButton")


-- === Привязка UI к Value ===
local function bindBoolToVisible(flag, frame)
	frame.Visible = flag.Value
	flag.Changed:Connect(function(val) frame.Visible = val end)
	frame:GetPropertyChangedSignal("Visible"):Connect(function()
		if flag.Value ~= frame.Visible then
			flag.Value = frame.Visible
		end
	end)
end
bindBoolToVisible(finishVisible, FinishBackground)
bindBoolToVisible(leaderboardVisible, LeaderboardFrame)



-- === UI: Сердечки ===
local function showLives(currentLives)
	if isGameOver.Value or currentLives == 0 then
		for i = 1, MAX_LIVES do
			local heart = Hearts[i]
			if heart then				
				heart.Visible = false
				heart.ImageTransparency = 1
			end 
		end
		return
	end
	for i = 1, MAX_LIVES do
		local heart = Hearts[i]
		if heart then
			if i <= currentLives then
				heart.Visible = true
				heart.ImageTransparency = 0
			else
				heart.Visible = false
				heart.ImageTransparency = 1
			end
		end
	end
end

livesValue.Changed:Connect(showLives)
isGameOver.Changed:Connect(function() showLives(livesValue.Value) end)

showLives(livesValue.Value)

-- === Игровые события ===
local UpdateScore = RemoteEvents:WaitForChild("UpdateScore")
local HeartLostEvent = RemoteEvents:WaitForChild("HeartLostEvent")
local UpdateUI = RemoteEvents:WaitForChild("UpdateUI")
local GameOverEvent = RemoteEvents:WaitForChild("GameOverEvent")
local LocalScoreUpdate = RemoteEvents:WaitForChild("LocalScoreUpdate")
local GetLeaderboard = RemoteEvents:WaitForChild("GetLeaderboard")
local GameOver = RemoteEvents:WaitForChild("GameOver")


HeartLostEvent.Event:Connect(function()
	if isGameOver.Value then return end
	if livesValue.Value > 0 then
		livesValue.Value = math.max(0, livesValue.Value - 1)
		if livesValue.Value == 0 then
			GameOverEvent:Fire()
		end
	end
end)
-- === Leaderboard обработка ===
local function hideLeaderboardOnReset()
	leaderboardVisible.Value = false

end

local function updateLeaderboard()
	local top = GetLeaderboard:InvokeServer()
	for i, info in ipairs(top) do
		local item = template:Clone()
		item.Name = "Player_" .. tostring(i)
		item.PlayerName.Text = tostring(i)..". "..info.Name
		item.Score.Text = tostring(info.Score)
		item.Visible = true
		item.Parent = leaderboardList
	end
end

leaderboardButton.MouseButton1Click:Connect(function()
	updateLeaderboard()
	leaderboardVisible.Value = true
end)

closeButton.MouseButton1Click:Connect(function()
	leaderboardVisible.Value = false
	for _, child in ipairs(leaderboardList:GetChildren()) do
		if child:IsA("Frame") and child.Name ~= "LeaderboardItemTemplate" then
			child:Destroy()
		end
	end
end)

UpdateUI.Event:Connect(function(action, value)
	if action == "SetLives" and type(value) == "number" then
		livesValue.Value = math.clamp(value, 0, MAX_LIVES)
	elseif action == "Restart" then
		hideLeaderboardOnReset()
		isGameOver.Value = false
		finishVisible.Value = false
		ScoreLabel.Visible = true 
		finishScoreLabel.Text = "" 
		scoreValue.Value = 0
		leaderboardVisible.Value = false
		livesValue.Value = MAX_LIVES
	end
end)


GameOverEvent.Event:Connect(function()
	isGameOver.Value = true
	GameOver:FireServer(scoreValue.Value)
	UpdateScore:FireServer(scoreValue.Value)
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://1846269541"
	sound.Volume = 1
	sound.Parent = workspace
	sound:Play()
	sound.Ended:Connect(function()
		sound:Destroy()
	end)
	finishVisible.Value = true
	finishScoreLabel.Text = "Final Score: " .. tostring(scoreValue.Value) 
	finishrestartButton.Visible = true
	leaderboardButton.Visible = true
	ScoreLabel.Visible = false 

end)



LocalScoreUpdate.Event:Connect(function(score)
	ScoreLabel.Text = "Score: " .. tostring(score)
end)

finishrestartButton.MouseButton1Click:Connect(function()
	UpdateUI:Fire("Restart")
end)
local function updateUIOnStart()
	if isGameOver.Value then
		ScoreLabel.Visible = false
		FinishBackground.Visible = true
		finishScoreLabel.Text = "Final Score: " .. tostring(scoreValue.Value)
	else
		ScoreLabel.Visible = true
		FinishBackground.Visible = false
	end
end

updateUIOnStart()
isGameOver.Changed:Connect(function() updateUIOnStart() end)

local function updateBoostUI()
	local now = tick()
	local boostActive = false
	local boostLeft = 0
	local boostType = ""	
	local originalSize = BoostTime.Size
	local function startPulse()
		if isPulsing then return end
		isPulsing = true
		pulseTweenUp = TweenService:Create(BoostTime, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = originalSize * 1.1})
		pulseTweenDown = TweenService:Create(BoostTime, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = originalSize})

		pulseTweenUp.Completed:Connect(function()
			if isPulsing then pulseTweenDown:Play() end
		end)
		pulseTweenDown.Completed:Connect(function()
			if isPulsing then pulseTweenUp:Play() end
		end)

		pulseTweenUp:Play()
	end

	local function stopPulse()
		if isPulsing then
			isPulsing = false
			if pulseTweenUp then pulseTweenUp:Cancel() end
			if pulseTweenDown then pulseTweenDown:Cancel() end
			BoostTime.Size = originalSize
		end
	end

	if speedBoosterEnd.Value > now then
		boostActive = true
		boostLeft = math.ceil(speedBoosterEnd.Value - now)
		boostType = "Speed!"
	elseif slowBoosterEnd.Value > now then
		boostActive = true
		boostLeft = math.ceil(slowBoosterEnd.Value - now)
		boostType = "Slow!"
	elseif magnetBoosterEnd.Value > now then
		boostActive = true
		boostLeft = math.ceil(magnetBoosterEnd.Value - now)
		boostType = "Magnet!"
	end
	if boostActive then
		BoostTime.Visible = true		
		BoostTime.Text = boostType .. " " .. tostring(boostLeft)
		startPulse()
	else
		BoostTime.Visible = false
		stopPulse()
	end
end

game:GetService("RunService").RenderStepped:Connect(updateBoostUI)
speedBoosterEnd.Changed:Connect(updateBoostUI)
slowBoosterEnd.Changed:Connect(updateBoostUI)
magnetBoosterEnd.Changed:Connect(updateBoostUI)
