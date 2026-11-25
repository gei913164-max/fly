-- Fly + Noclip + Speed + JumpPower + ESP + Menu (Stealth-версия)
-- Открой через executor (Delta, Fluxus, Codex и т.д.)
--
-- ВАЖНО: 100% защиты от бана не существует.
-- Этот скрипт делает движение плавным и менее заметным,
-- но серверный античит всё равно может детектить.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

-- ===================== НАСТРОЙКИ =====================

-- true = отключать чит при попытке кика
local AUTO_SAFE = true
-- Максимальная скорость полёта (чем ниже - тем безопаснее)
local MAX_SAFE_FLY_SPEED = 80
-- Задержка между вкл/выкл (сек) - имитация человеческой реакции
local TOGGLE_DELAY = 0.3

-- ===================== СОСТОЯНИЕ =====================

local flyEnabled = false
local flyVelocity = 60

local noclipEnabled = false
local speedEnabled = false
local walkSpeed = 24
local jumpPower = 100

local espEnabled = false
local espHighlights = {}

local lastToggle = 0

-- ===================== БЕЗОПАСНОСТЬ =====================

local function safeDisable()
	setFly(false)
	noclipEnabled = false
	speedEnabled = false
	applyStats()
	clearESP()
end

-- Детект попытки кика (Roblox кидает через Kick или разрыв соединения)
-- Ловим Kick через хук
local oldKick
oldKick = hookfunction(Instance.new("RemoteEvent").Kick or function() end, function(self, ...)
	if AUTO_SAFE then safeDisable() end
	return oldKick(self, ...)
end)

-- ===================== FLY =====================

local function getCharacter()
	return LocalPlayer.Character
end

local function setFly(on)
	flyEnabled = on
	local Character = getCharacter()
	if not Character then return end
	local Humanoid = Character:FindFirstChildOfClass("Humanoid")
	local RootPart = Character:FindFirstChild("HumanoidRootPart")
	if not Humanoid or not RootPart then return end

	if on then
		-- Ограничиваем скорость
		flyVelocity = math.clamp(flyVelocity, 20, MAX_SAFE_FLY_SPEED)
		Humanoid.PlatformStand = true
	else
		Humanoid.PlatformStand = false
		-- Мягкая посадка - не даём провалиться сквозь землю
		RootPart.Velocity = Vector3.new(0, -10, 0)
	end
end

local function startFlyLoop()
	RunService.Heartbeat:Connect(function()
		if not flyEnabled then return end

		local Character = getCharacter()
		if not Character then return end
		local Humanoid = Character:FindFirstChildOfClass("Humanoid")
		local RootPart = Character:FindFirstChild("HumanoidRootPart")
		if not Humanoid or not RootPart then return end

		-- Не летим если персонаж мёртв
		if Humanoid.Health <= 0 then
			setFly(false)
			return
		end

		local velocity = Vector3.new(0, 0, 0)

		if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
			velocity += Vector3.new(0, flyVelocity * 0.8, 0)
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
			velocity += Vector3.new(0, -flyVelocity * 0.8, 0)
		end

		local camera = workspace.CurrentCamera
		local cf = camera.CFrame
		local forward = cf.LookVector
		local right = cf.RightVector

		if UserInputService:IsKeyDown(Enum.KeyCode.W) then
			velocity += forward * flyVelocity * 0.9
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.S) then
			velocity += -forward * flyVelocity * 0.9
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.A) then
			velocity += -right * flyVelocity * 0.9
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.D) then
			velocity += right * flyVelocity * 0.9
		end

		-- Плавное применение скорости (lerp вместо резкого)
		local targetVel = velocity
		local currentVel = RootPart.Velocity
		local smoothVel = currentVel:Lerp(targetVel, 0.15)
		RootPart.Velocity = smoothVel
	end)
end

-- ===================== NOCLIP =====================

local function startNoclip()
	RunService.Stepped:Connect(function()
		if not noclipEnabled then return end
		local Character = getCharacter()
		if not Character then return end
		local Humanoid = Character:FindFirstChildOfClass("Humanoid")
		if not Humanoid or Humanoid.Health <= 0 then
			noclipEnabled = false
			return
		end
		for _, part in ipairs(Character:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CanCollide = false
			end
		end
	end)
end

-- ===================== SPEED / JUMP =====================

local function applyStats()
	local Character = getCharacter()
	if not Character then return end
	local Humanoid = Character:FindFirstChildOfClass("Humanoid")
	if not Humanoid then return end

	if speedEnabled then
		-- Ограничиваем WalkSpeed до безопасного значения
		Humanoid.WalkSpeed = math.clamp(walkSpeed, 16, 32)
	else
		Humanoid.WalkSpeed = 16
	end

	-- JumpPower оставляем стандартным или немного выше
	Humanoid.JumpPower = math.clamp(jumpPower, 50, 150)
	Humanoid.UseJumpPower = true
end

RunService.Heartbeat:Connect(function()
	applyStats()
end)

-- ===================== ESP =====================

local function clearESP()
	for player, highlight in pairs(espHighlights) do
		if highlight and highlight.Parent then
			highlight:Destroy()
		end
		espHighlights[player] = nil
	end
end

local function addESP(player)
	if player == LocalPlayer then return end
	if espHighlights[player] then return end
	local Character = player.Character
	if not Character then return end
	local Head = Character:FindFirstChild("Head")
	if not Head then return end

	local highlight = Instance.new("Highlight")
	highlight.FillColor = Color3.fromRGB(255, 50, 50)
	highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
	highlight.FillTransparency = 0.6
	highlight.OutlineTransparency = 0
	highlight.Adornee = Character
	highlight.Parent = Character

	espHighlights[player] = highlight
end

local function startESP()
	for _, player in ipairs(Players:GetPlayers()) do
		addESP(player)
	end

	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function()
			task.wait(0.5)
			if espEnabled then addESP(player) end
		end)
	end)

	Players.PlayerRemoving:Connect(function(player)
		if espHighlights[player] then
			espHighlights[player]:Destroy()
			espHighlights[player] = nil
		end
	end)
end

-- ===================== ГОРЯЧИЕ КЛАВИШИ (с задержкой) =====================

local function canToggle()
	local now = tick()
	if now - lastToggle < TOGGLE_DELAY then
		return false
	end
	lastToggle = now
	return true
end

UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	if not canToggle() then return end

	if input.KeyCode == Enum.KeyCode.F then
		setFly(not flyEnabled)
	elseif input.KeyCode == Enum.KeyCode.N then
		noclipEnabled = not noclipEnabled
	elseif input.KeyCode == Enum.KeyCode.V then
		espEnabled = not espEnabled
		if espEnabled then
			for _, p in ipairs(Players:GetPlayers()) do addESP(p) end
		else
			clearESP()
		end
	end
end)

-- ===================== МЕНЮ =====================

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "CheatMenu"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local Window = Instance.new("Frame")
Window.Name = "Window"
Window.Size = UDim2.new(0, 270, 0, 420)
Window.Position = UDim2.new(0.5, -135, 0.5, -210)
Window.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
Window.BorderSizePixel = 0
Window.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = Window

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
Title.Text = "Cheat Menu"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14
Title.Parent = Window

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 8)
TitleCorner.Parent = Title

-- Перетаскивание
local dragging = false
local dragInput, dragStart, startPos

Title.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStart = input.Position
		startPos = Window.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
		local delta = input.Position - dragStart
		Window.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)

-- Фабрика кнопок
local yPos = 45
local function makeButton(text, callback)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0.8, 0, 0, 32)
	btn.Position = UDim2.new(0.1, 0, 0, yPos)
	btn.BackgroundColor3 = Color3.fromRGB(60, 120, 200)
	btn.Text = text
	btn.TextColor3 = Color3.new(1, 1, 1)
	btn.Font = Enum.Font.Gotham
	btn.TextSize = 13
	btn.Parent = Window

	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 6)
	c.Parent = btn

	btn.MouseButton1Click:Connect(callback)
	yPos += 38
	return btn
end

-- Фабрика слайдеров
local function makeSlider(label, minVal, maxVal, default, callback)
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(0.8, 0, 0, 16)
	lbl.Position = UDim2.new(0.1, 0, 0, yPos)
	lbl.BackgroundTransparency = 1
	lbl.Text = label .. ": " .. default
	lbl.TextColor3 = Color3.new(1, 1, 1)
	lbl.Font = Enum.Font.Gotham
	lbl.TextSize = 12
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = Window
	yPos += 18

	local bg = Instance.new("Frame")
	bg.Size = UDim2.new(0.8, 0, 0, 8)
	bg.Position = UDim2.new(0.1, 0, 0, yPos)
	bg.BackgroundColor3 = Color3.fromRGB(55, 55, 65)
	bg.Parent = Window

	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(1, 0)
	c.Parent = bg

	local fill = Instance.new("Frame")
	fill.Size = UDim2.new((default - minVal) / (maxVal - minVal), 0, 1, 0)
	fill.BackgroundColor3 = Color3.fromRGB(60, 120, 200)
	fill.Parent = bg

	local fc = Instance.new("UICorner")
	fc.CornerRadius = UDim.new(1, 0)
	fc.Parent = fill

	local draggingSlider = false
	bg.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			draggingSlider = true
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			draggingSlider = false
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if draggingSlider and input.UserInputType == Enum.UserInputType.MouseMovement then
			local relX = math.clamp((input.Position.X - bg.AbsolutePosition.X) / bg.AbsoluteSize.X, 0, 1)
			fill.Size = UDim2.new(relX, 0, 1, 0)
			local val = math.floor(minVal + relX * (maxVal - minVal))
			lbl.Text = label .. ": " .. val
			callback(val)
		end
	end)

	yPos += 18
	return { label = lbl, fill = fill }
end

-- Кнопки
local flyBtn = makeButton("Fly: OFF", function()
	if canToggle() then
		setFly(not flyEnabled)
	end
end)

local noclipBtn = makeButton("Noclip: OFF", function()
	noclipEnabled = not noclipEnabled
	noclipBtn.Text = noclipEnabled and "Noclip: ON" or "Noclip: OFF"
end)

local speedBtn = makeButton("Speed Walk: OFF", function()
	speedEnabled = not speedEnabled
	speedBtn.Text = speedEnabled and "Speed Walk: ON" or "Speed Walk: OFF"
end)

local espBtn = makeButton("ESP: OFF", function()
	espEnabled = not espEnabled
	espBtn.Text = espEnabled and "ESP: ON" or "ESP: OFF"
	if espEnabled then
		for _, p in ipairs(Players:GetPlayers()) do addESP(p) end
	else
		clearESP()
	end
end)

local safeBtn = makeButton("Auto-Safe: ON", function()
	AUTO_SAFE = not AUTO_SAFE
	safeBtn.Text = AUTO_SAFE and "Auto-Safe: ON" or "Auto-Safe: OFF"
end)

makeButton("Land", function()
	setFly(false)
end)

-- Слайдеры (с безопасными лимитами)
makeSlider("Fly Speed", 20, MAX_SAFE_FLY_SPEED, 60, function(v)
	flyVelocity = v
end)

makeSlider("WalkSpeed", 16, 32, 24, function(v)
	walkSpeed = v
	if speedEnabled then applyStats() end
end)

makeSlider("JumpPower", 50, 150, 100, function(v)
	jumpPower = v
	applyStats()
end)

-- Обновление кнопок
RunService.Heartbeat:Connect(function()
	flyBtn.Text = flyEnabled and "Fly: ON" or "Fly: OFF"
	flyBtn.BackgroundColor3 = flyEnabled and Color3.fromRGB(40, 180, 90) or Color3.fromRGB(60, 120, 200)
end)

-- Авто-отключение при смерти
LocalPlayer.CharacterAdded:Connect(function(char)
	local humanoid = char:WaitForChild("Humanoid")
	humanoid.Died:Connect(function()
		safeDisable()
	end)
end)

-- Запуск
startFlyLoop()
startNoclip()
startESP()

print("[CheatMenu] Загружено (Stealth-режим)")
print("F - Fly | N - Noclip | V - ESP")
print("Совет: не летай слишком быстро, не используй в публичных серверах")
