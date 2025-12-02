print("Bubble spawner script started!")

-- === UI для сердечек ===
local player = game.Players.LocalPlayer
local stateFolder = player:FindFirstChild("GuiState") or Instance.new("Folder")
stateFolder.Name = "GuiState"
stateFolder.Parent = player

-- Score IntValue — глобальный счет игрока
local scoreValue = stateFolder:FindFirstChild("Score") 
if not scoreValue then
	scoreValue = Instance.new("IntValue") 
	scoreValue.Name = "Score"
	scoreValue.Value = 0
	scoreValue.Parent = stateFolder
end

local speedBoosterEnd = stateFolder:FindFirstChild("SpeedBoosterEnd") or Instance.new("NumberValue")
speedBoosterEnd.Name = "SpeedBoosterEnd"
speedBoosterEnd.Value = 0
speedBoosterEnd.Parent = stateFolder

local slowBoosterEnd = stateFolder:FindFirstChild("SlowBoosterEnd") or Instance.new("NumberValue")
slowBoosterEnd.Name = "SlowBoosterEnd"
slowBoosterEnd.Value = 0
slowBoosterEnd.Parent = stateFolder

local magnetBoosterEnd = stateFolder:FindFirstChild("MagnetBoosterEnd") or Instance.new("NumberValue")
magnetBoosterEnd.Name = "MagnetBoosterEnd"
magnetBoosterEnd.Value = 0
magnetBoosterEnd.Parent = stateFolder



local MainGui = player:WaitForChild("PlayerGui"):WaitForChild("MainGui")
local SideButtonsFrame = MainGui:WaitForChild("SideButtonsFrame")

-- === ЛОКАЛЬНЫЕ СОБЫТИЯ ДЛЯ UI ===
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local HeartLostEvent = RemoteEvents:WaitForChild("HeartLostEvent")
local GameOverEvent = RemoteEvents:WaitForChild("GameOverEvent")
local UpdateUI = RemoteEvents:WaitForChild("UpdateUI")
local isGameActive = false
-- === Игровая логика ===
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local PopEffectTemplate = ReplicatedStorage:WaitForChild("PopEffect")

local camera = workspace.CurrentCamera
local gameField = workspace:WaitForChild("GameField")
local cloudSpawners = workspace:WaitForChild("CloudSpawners")
local catchZones = workspace:WaitForChild("CatchZones")

local clouds = {
	cloudSpawners:WaitForChild("Cloud1"),
	cloudSpawners:WaitForChild("Cloud2"),
	cloudSpawners:WaitForChild("Cloud3"),
	cloudSpawners:WaitForChild("Cloud4")
}
local zones = {
	catchZones:WaitForChild("CatchZone1"),
	catchZones:WaitForChild("CatchZone2"),
	catchZones:WaitForChild("CatchZone3"),
	catchZones:WaitForChild("CatchZone4")
}

for _, cloud in ipairs(clouds) do
	if cloud:IsA("Model") then
		repeat task.wait(0.05) until cloud.PrimaryPart
	end
end
for _, zone in ipairs(zones) do
	if zone:IsA("Model") then
		repeat task.wait(0.05) until zone.PrimaryPart
	end
end

local function getXonScreenEdge(fraction)
	local ray = camera:ViewportPointToRay(fraction * camera.ViewportSize.X, camera.ViewportSize.Y / 2)
	local origin, dir = ray.Origin, ray.Direction
	local center = gameField.Position
	local Z = center.Z
	local cloudZOffset = 0
	local t = (Z + cloudZOffset - origin.Z) / dir.Z
	local pos = origin + dir * t
	return pos.X
end

local function PlaceCloudsAndZones()
	local center = gameField.Position
	local Y_top = 11
	local Y_bot = 4
	local Z = center.Z
	local cloudZOffset = 0
	local zoneYOffset12 = -3
	local zoneYOffset34 = -1
	local zoneXOffset = 6
	local edgeFrac = 0.15

	local leftX = getXonScreenEdge(edgeFrac)
	local rightX = getXonScreenEdge(1 - edgeFrac)

	local cloudPositions = {
		Vector3.new(leftX, center.Y + Y_top, Z + cloudZOffset),
		Vector3.new(rightX, center.Y + Y_top, Z + cloudZOffset),
		Vector3.new(leftX, center.Y + Y_bot, Z + cloudZOffset),
		Vector3.new(rightX, center.Y + Y_bot, Z + cloudZOffset)
	}

	local zonePositions = {
		cloudPositions[1] + Vector3.new(zoneXOffset+2, zoneYOffset12, 0),
		cloudPositions[2] + Vector3.new(-zoneXOffset-2, zoneYOffset12, 0),
		cloudPositions[3] + Vector3.new(zoneXOffset, zoneYOffset34, 0),
		cloudPositions[4] + Vector3.new(-zoneXOffset, zoneYOffset34, 0)
	}

	for i = 1, 4 do
		local rotation = CFrame.Angles(0, math.rad(180), 0)
		if i == 1 or i == 3 then
			clouds[i]:SetPrimaryPartCFrame(CFrame.new(cloudPositions[i]) * rotation)
		else
			clouds[i]:SetPrimaryPartCFrame(CFrame.new(cloudPositions[i]))
		end
		local rotationCatch = CFrame.Angles(0, math.rad(90), 0)
		zones[i]:SetPrimaryPartCFrame(CFrame.new(zonePositions[i]) * rotationCatch)
	end
end

PlaceCloudsAndZones()
camera:GetPropertyChangedSignal("ViewportSize"):Connect(PlaceCloudsAndZones)
game:GetService("RunService").RenderStepped:Connect(PlaceCloudsAndZones)

print("Проверяем Attachments в облаках и зонах")
while true do
	local ready = true
	for i = 1, 4 do
		if not clouds[i]:FindFirstChild("CloudSpawnPoint", true) then
			print("Нет CloudSpawnPoint в", clouds[i].Name)
			ready = false
		end
		if not zones[i]:FindFirstChild("CatchZoneCenter", true) then
			print("Нет CatchZoneCenter в", zones[i].Name)
			ready = false
		end
	end
	if ready then break end
	task.wait(0.2)
end
print("All Attachments found! Start bubbles...")

-- === КАТЕГОРИИ ПРЕДМЕТОВ ===
local BubbleItems = ReplicatedStorage:WaitForChild("BubbleItems")
local GoodFolder = BubbleItems:WaitForChild("Good")
local BadFolder = BubbleItems:WaitForChild("Bad")
local RareFolder = BubbleItems:WaitForChild("Rare")
local BoosterFolder = BubbleItems:WaitForChild("Boosters")
local CollectibleFolder = BubbleItems:WaitForChild("Collectibles")
local EmptyFolder = BubbleItems:WaitForChild("Empty")
local BubbleTemplate = ReplicatedStorage:WaitForChild("BubbleTemplate")
local bubblesFolder = workspace:WaitForChild("Bubbles")
local BoostTimeLabel = SideButtonsFrame:WaitForChild("BoostTime")

local bubbleCategoryColors = {
	Good = Color3.fromRGB(144, 238, 144),       -- зеленый
	Bad = Color3.fromRGB(255, 105, 97),         -- красный
	Rare = Color3.fromRGB(186, 85, 211),        -- фиолетовый
	Booster = Color3.fromRGB(255, 215, 0),      -- желтый/золотой
	Collectible = Color3.fromRGB(30, 144, 255), -- синий
	Empty = Color3.fromRGB(211, 211, 211),      -- серый (пустой)
	None = Color3.fromRGB(255, 255, 255),       -- белый по умолчанию
}
local bubbleToItemMap = {}

local distanceThreshold = 1 
local popThreshold = 1

-- ==== ИГРОВЫЕ ПЕРЕМЕННЫЕ ====
local spawnInterval = 2           
local normalSpawnInterval = 2   
local fastSpawnInterval = 1      
local speedMultiplier, magnetActive


local function resetVars()
	scoreValue.Value = 0
	speedMultiplier = 1
	magnetActive = false
	speedBoosterEnd.Value = 0
	magnetBoosterEnd.Value = 0
	slowBoosterEnd.Value	= 0
end

local function flashRingHighlight(catchZoneModel)
	local ringPart = catchZoneModel:FindFirstChildWhichIsA("BasePart")
	if not ringPart then return end
	local highlight = ringPart:FindFirstChild("RingHighlight")
	if not highlight then
		highlight = Instance.new("Highlight")
		highlight.Name = "RingHighlight"
		highlight.Parent = ringPart
		highlight.Adornee = ringPart
		highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	end
	highlight.FillColor = Color3.fromRGB(255, 255, 100)
	highlight.OutlineColor = Color3.fromRGB(255, 220, 50)
	highlight.FillTransparency = 0.35
	highlight.Enabled = true
	task.delay(0.4, function()
		if highlight then
			highlight.Enabled = false
		end
	end)
end

local function playPopEffect(position)
	local effect = PopEffectTemplate:Clone()
	effect.Parent = workspace
	effect.Position = position
	effect.Anchored = true

	local emitter = effect:FindFirstChildWhichIsA("ParticleEmitter")
	if emitter then
		emitter:Emit(12)
	end

	local sound = effect:FindFirstChildWhichIsA("Sound")
	if sound then
		sound:Play()
	end

	local tweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	local tween = TweenService:Create(effect, tweenInfo, {
		Size = effect.Size * 1.7,
		Transparency = 1
	})
	tween:Play()
	tween.Completed:Connect(function()
		effect:Destroy()
	end)
end

-- === ОБРАБОТКА ЛОПАНИЯ ПУЗЫРЯ ===
local function handleBubblePop(bubble)
	local meta = bubbleToItemMap[bubble]
	local itemType = bubble:GetAttribute("ItemType") or (meta and meta.type) or "None"

	if itemType == "Good" then
		scoreValue.Value = scoreValue.Value + 1
		print("+1 очко! Хороший предмет")
	elseif itemType == "Bad" then
		if scoreValue.Value > 0 then
			scoreValue.Value = scoreValue.Value - 1
		end
		HeartLostEvent:Fire()
		print("[BUBBLE] HeartLostEvent FIRED")
		print("-1 очко Плохой предмет")
	elseif itemType == "Rare" then
		scoreValue.Value = scoreValue.Value + 5
		print("+5 очков! Редкий предмет")
	elseif itemType == "Booster" then
		if meta and meta.item then
			local name = meta.item.Name:lower()
			if name:find("clock") then
				speedMultiplier = 0.5
				slowBoosterEnd.Value = tick() + 5
				print("БУСТЕР! Часики: скорость пузырей уменьшена на 5 сек")
			elseif name:find("magnet") then
				magnetActive = true
				magnetBoosterEnd.Value = tick() + 5
				print("БУСТЕР! Магнит: автосбор на 5 сек")
			elseif name:find("lightning") then
				speedMultiplier = 2
				speedBoosterEnd.Value = tick() + 5
				spawnInterval = fastSpawnInterval  
				print("БУСТЕР! Молния: скорость пузырей увеличена на 5 сек")
			end
		end
	elseif itemType == "Collectible" then
		local bonus = 10
		scoreValue.Value = scoreValue.Value + bonus

		print("Коллекционный предмет! +" .. bonus .. " очков")
	elseif itemType == "Empty" then
		print("Пустой пузырь, ничего не происходит")
	end
end

-- === popAndDestroyBubble — универсальная функция для уничтожения пузыря ===
local function popAndDestroyBubble(bubble, zoneIndex)
	if not bubble or not bubble.Parent then return end
	if bubble:GetAttribute("Handled") then return end
	bubble:SetAttribute("Handled", true)
	handleBubblePop(bubble)
	local shell = bubble:FindFirstChild("BubbleShell")
	if shell then playPopEffect(shell.Position) end
	bubble:Destroy()
	if zoneIndex then flashRingHighlight(zones[zoneIndex]) end
end

local chance_Empty = 15    -- % шанс пустого пузыря
local chance_Bad = 18      -- % плохой предмет
local chance_Rare = 2.5      -- % редкий предмет
local chance_Booster = 3   -- % бустер
local chance_Collectible = 0.1 -- % коллекционный
local function getRandomCollectible()
	local categories = CollectibleFolder:GetChildren()
	if #categories == 0 then return nil end
	local chosenCategory = categories[math.random(1, #categories)]
	local items = chosenCategory:GetChildren()
	if #items == 0 then return nil end

	return items[math.random(1, #items)], "Collectible"
end
-- === ВЫБОР ПРЕДМЕТА ДЛЯ ПУЗЫРЯ ===
local function chooseBubbleItem()
	local roll = math.random(1, 100)

	if roll <= chance_Empty then
		local empty = EmptyFolder:GetChildren()
		if #empty > 0 then
			return empty[math.random(1, #empty)], "Empty"
		end

	elseif roll <= chance_Empty + chance_Bad then
		local bads = BadFolder:GetChildren()
		if #bads > 0 then
			return bads[math.random(1, #bads)], "Bad"
		end

	elseif roll <= chance_Empty + chance_Bad + chance_Rare then
		local rares = RareFolder:GetChildren()
		if #rares > 0 then
			return rares[math.random(1, #rares)], "Rare"
		end

	elseif roll <= chance_Empty + chance_Bad + chance_Rare + chance_Booster then
		local boosters = BoosterFolder:GetChildren()
		if #boosters > 0 then
			return boosters[math.random(1, #boosters)], "Booster"
		end

	elseif roll <= chance_Empty + chance_Bad + chance_Rare + chance_Booster + chance_Collectible then
		local collectible, typeStr = getRandomCollectible()
		if collectible then
			return collectible, typeStr
		end

	else
		local goods = GoodFolder:GetChildren()
		if #goods > 0 then
			return goods[math.random(1, #goods)], "Good"
		end
	end

	return nil, "None"
end

-- === СПАВН ПУЗЫРЯ ===
local function spawnBubbleFromCloud(cloud, catchZone)
	local spawnAttachment = cloud:FindFirstChild("CloudSpawnPoint", true)
	local zoneAttachment = catchZone:FindFirstChild("CatchZoneCenter", true)
	if not (spawnAttachment and zoneAttachment) then
		warn("Нет CloudSpawnPoint или CatchZoneCenter", cloud, catchZone)
		return
	end

	local cloudPos = spawnAttachment.WorldPosition
	local zonePos = zoneAttachment.WorldPosition

	local bubble = BubbleTemplate:Clone()
	bubble.BubbleShell.CollisionGroup = "Bubbles"

	local chosenItem, itemType = chooseBubbleItem()
	local spawnedItem = nil
	if chosenItem then
		spawnedItem = chosenItem:Clone()
		spawnedItem.Parent = bubble
		if spawnedItem:IsA("BasePart") then
			spawnedItem.CFrame = bubble.BubbleShell.CFrame
			spawnedItem.Anchored = false
			spawnedItem.CanCollide = false
			spawnedItem.CollisionGroup = "Bubbles"
		end
	end
	bubbleToItemMap[bubble] = {item = spawnedItem, type = itemType}
	bubble:SetAttribute("ItemType", itemType)

	bubble.Parent = bubblesFolder
	local chosenColor = bubbleCategoryColors[itemType] or bubbleCategoryColors["None"]
	bubble.BubbleShell.Color = chosenColor
	bubble.BubbleShell.Anchored = false
	bubble:PivotTo(CFrame.new(cloudPos))

	local direction = (zonePos - cloudPos)
	if direction.Magnitude < 0.1 then
		direction = Vector3.new(0, 0, -1)
	else
		direction = direction.Unit
	end
	local speed = 2 * speedMultiplier
	local bv = Instance.new("BodyVelocity")
	bv.Velocity = direction * speed
	bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
	bv.Parent = bubble.BubbleShell

	task.delay(6, function()
		if bubble and bubble.Parent then
			if bubble:GetAttribute("HasBeenInZone") then
				local meta = bubbleToItemMap[bubble]
				local itemType = bubble:GetAttribute("ItemType") or (meta and meta.type) or "None"
				if itemType == "Good" then
					HeartLostEvent:Fire()
					print("[BUBBLE] HeartLostEvent FIRED")
					print("Штраф! Пропущен хороший пузырь (-1 жизнь)")
				else
					print("Пузырь исчез (но это не Good)")
				end
				if not bubble:GetAttribute("Handled") then
					bubble:SetAttribute("Handled", true)
					bubble:Destroy()
				end
			else
				print("Пузырь исчез (не долетел до зоны).")
				if not bubble:GetAttribute("Handled") then
					bubble:SetAttribute("Handled", true)
					bubble:Destroy()
				end
			end
		end
	end)
end

-- ЛОПАНИЕ ПО КЛАВИШАМ: ищем ближайший пузырь рядом с зоной (popThreshold)
local keyToZone = {
	Q = 1, -- CatchZone1 (верхний левый)
	E = 2, -- CatchZone2 (верхний правый)
	A = 3, -- CatchZone3 (нижний левый)
	D = 4, -- CatchZone4 (нижний правый),
}

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed or not isGameActive then return end
	local key = tostring(input.KeyCode):gsub("Enum.KeyCode.", "")
	local zoneIndex = keyToZone[key]
	if zoneIndex then
		local zoneAttachment = zones[zoneIndex]:FindFirstChild("CatchZoneCenter", true)
		if zoneAttachment then
			local nearestBubble = nil
			local minDist = math.huge
			for _, bubble in ipairs(bubblesFolder:GetChildren()) do
				local shell = bubble:FindFirstChild("BubbleShell")
				if shell then
					local dist = (shell.Position - zoneAttachment.WorldPosition).Magnitude
					if dist <= popThreshold and dist < minDist then
						nearestBubble = bubble
						minDist = dist
					end
				end
			end
			if nearestBubble and nearestBubble.Parent then
				if nearestBubble:GetAttribute("HasBeenInZone") then
					popAndDestroyBubble(nearestBubble, zoneIndex)
				end
			end
		end
	end
end)

local RunService = game:GetService("RunService")
RunService.Heartbeat:Connect(function(dt)
	if not isGameActive then return end

	if magnetActive then
		for i = 1, 4 do
			local zoneAttachment = zones[i]:FindFirstChild("CatchZoneCenter", true)
			if zoneAttachment then
				for _, bubble in ipairs(bubblesFolder:GetChildren()) do
					local shell = bubble:FindFirstChild("BubbleShell")
					if shell and bubble:GetAttribute("HasBeenInZone") then
						local dist = (shell.Position - zoneAttachment.WorldPosition).Magnitude
						if dist <= popThreshold then
							popAndDestroyBubble(bubble, i)
						end
					end
				end
			end
		end
	end

	for _, bubble in ipairs(bubblesFolder:GetChildren()) do
		local shell = bubble:FindFirstChild("BubbleShell")
		if shell then
			local x = shell:GetAttribute("SpinX") or 0
			local y = shell:GetAttribute("SpinY") or 0
			local z = shell:GetAttribute("SpinZ") or 0
			if x ~= 0 or y ~= 0 or z ~= 0 then
				shell.CFrame = shell.CFrame * CFrame.Angles(
					math.rad(x * dt),
					math.rad(y * dt),
					math.rad(z * dt)
				)
			end
		end
		local meta = bubbleToItemMap[bubble]
		if meta and meta.item and meta.item:IsA("BasePart") and shell then
			meta.item.CFrame = shell.CFrame * CFrame.Angles(0, math.rad(os.clock()*120%360), 0)
		end
	end

	for i = 1, 4 do
		local zoneAttachment = zones[i]:FindFirstChild("CatchZoneCenter", true)
		if zoneAttachment then
			for _, bubble in ipairs(bubblesFolder:GetChildren()) do
				local shell = bubble:FindFirstChild("BubbleShell")
				if shell then
					local dist = (shell.Position - zoneAttachment.WorldPosition).Magnitude
					if dist <= distanceThreshold then
						if not bubble:GetAttribute("HasBeenInZone") then
							bubble:SetAttribute("HasBeenInZone", true)
							flashRingHighlight(zones[i])
						end
					end
				end
			end
		end
	end
	local now = tick()
	if speedMultiplier > 1 and speedBoosterEnd.Value <= now then
		speedMultiplier = 1
		spawnInterval = normalSpawnInterval
	end
	if speedMultiplier < 1 and slowBoosterEnd.Value <= now then
		speedMultiplier = 1
	end
	if magnetActive and magnetBoosterEnd.Value <= now then
		magnetActive = false
	end

	local boostActive = false
	local boostLeft = 0
	local boostType = ""


	if speedBoosterEnd.Value > now then
		boostActive = true
		boostLeft = math.ceil(speedBoosterEnd.Value - now)
		boostType = "Скорость!"
	elseif slowBoosterEnd.Value > now then
		boostActive = true
		boostLeft = math.ceil(slowBoosterEnd.Value - now)
		boostType = "Медленно!"
	elseif magnetBoosterEnd.Value > now then
		boostActive = true
		boostLeft = math.ceil(magnetBoosterEnd.Value - now)
		boostType = "Магнит!"
	end
end)

local spawnThread 

local function clearAllBubbles()
	for _, b in ipairs(bubblesFolder:GetChildren()) do
		b:Destroy()
	end
end

local function startBubbleSpawn()
	if spawnThread then
		spawnThread:Disconnect()
	end
	isGameActive = true
	spawnThread = RunService.Heartbeat:Connect(function()
		spawnThread:Disconnect()
		task.spawn(function()
			while isGameActive do
				local i = math.random(1, 4)
				local cloud = clouds[i]
				local zone = zones[i]
				if cloud and zone then
					spawnBubbleFromCloud(cloud, zone)
				end
				task.wait(spawnInterval)
			end
			print("Game Over! (bubble spawner stopped)")
		end)
	end)
end

GameOverEvent.Event:Connect(function()
	print("[BUBBLE] GameOverEvent RECEIVED")
	isGameActive = false
end)
UpdateUI.Event:Connect(function(action)
	if action == "Restart" then
		resetVars()
		scoreValue.Value = 0
		clearAllBubbles()
		isGameActive = true
		startBubbleSpawn()
	end
end)

resetVars()
clearAllBubbles()
isGameActive = true
startBubbleSpawn()
