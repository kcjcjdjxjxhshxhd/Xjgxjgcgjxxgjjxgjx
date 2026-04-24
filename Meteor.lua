--// FOSSIL METEOR RAIN (FULL FIXED - ALL SYSTEM STABLE)

--// SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

--// PLAYER
local player = Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local root = char:WaitForChild("HumanoidRootPart")

--// CAMERA
local camera = workspace.CurrentCamera

--// SETTINGS
local RADIUS = 500
local BLUE_RADIUS = 150
local MIN_SPEED = 80
local MAX_SPEED = 220
local SPAWN_DELAY = 2
local SUCK_RADIUS = 30
local DAMAGE_MULTIPLIER = 2
local IMPACT_SOUND_ID = "rbxassetid://136143551517353"
local ROLL_VFX_LIFETIME = 2
local ROLL_VFX_IMAGE = "rbxassetid://108570852046746" -- m Ã„â€˜Ã¡Â»â€¢i tuÃ¡Â»Â³ thÄ‚Â­ch
local FIRE_LIFETIME = 5
local FIRE_DAMAGE = 2
local LIGHTNING_MIN_SPEED = 70
local LIGHTNING_MAX_SPEED = 120

local SOUND_MIN_DISTANCE = 10
local SOUND_MAX_DISTANCE = 600

--// STATE
local meteors = {}
local purpleActive = false
local blueActive = false
local shakePower = 0
local lastGravityTick = 0 -- Ã¢ÂÂ±Ã¯Â¸Â cooldown damage
local toxicActive = false

task.spawn(function()
	while true do
		toxicActive = math.random() < 0.12-- 12% spawn
		task.wait(1)
	end
end)

local SoundService = game:GetService("SoundService")

-- ðŸ”¥ sound factory chá»‘ng rÃ¨ / chá»‘ng overlap
local function createImmuneSound(id, speed)
	local s = Instance.new("Sound")
	s.SoundId = id
	s.Volume = 10 -- ðŸ”Š FIX: volume 8 nhÆ° m yÃªu cáº§u
	s.PlaybackSpeed = speed or 1

	-- ðŸ›¡ï¸ chá»‘ng bá»‹ mÃ´i trÆ°á»ng áº£nh hÆ°á»Ÿng
	s.RollOffMode = Enum.RollOffMode.Linear
	s.EmitterSize = 0
	s.MaxDistance = math.huge

	-- ðŸ”Š chÆ¡i global
	s.Parent = SoundService

	return s
end

-- ðŸ”¥ chá»‰ cÃ²n 1 function duy nháº¥t
local function fah(speed)
	local sound = createImmuneSound("rbxassetid://140164168357890", speed)

	sound:Play()

	task.spawn(function()
		task.wait(7)
		if sound then
			sound:Destroy()
		end
	end)
end

local function safeRand(a, b)
	a = math.floor(a)
	b = math.floor(b)
	if b < a then
		a, b = b, a
	end
	if a == b then return a end
	return math.random(a, b)
end

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local function ShowImage(imageId)
	local player = Players.LocalPlayer

	-- GUI
	local gui = Instance.new("ScreenGui")
	gui.Parent = player:WaitForChild("PlayerGui")

	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 999
	gui.ResetOnSpawn = false

	local img = Instance.new("ImageLabel")
	img.Parent = gui

	img.Size = UDim2.new(1, 0, 1, 0)
	img.Position = UDim2.new(0, 0, 0, 0)

	img.BackgroundTransparency = 1
	img.Image = "rbxassetid://" .. tostring(imageId)

	img.ScaleType = Enum.ScaleType.Stretch
	img.ImageTransparency = 0
	img.ZIndex = 999

	-- fade out 4s
	local tween = TweenService:Create(
		img,
		TweenInfo.new(4, Enum.EasingStyle.Linear),
		{ ImageTransparency = 1 }
	)

	tween:Play()

	tween.Completed:Connect(function()
		gui:Destroy()
	end)
end

--// HITBOX
local function getHitbox(size)
	return size * 1.5
end

--// EVENTS
task.spawn(function()
	while true do
		purpleActive = math.random() < (math.random(10,30)/100)
		task.wait(10)
	end
end)

task.spawn(function()
	while true do
		blueActive = math.random() < (math.random(5,20)/100)
		task.wait(1)
	end
end)

local explosiveActive = false

task.spawn(function()
	while true do
		explosiveActive = math.random() < 0.15
		task.wait(1)
	end
end)

--// SHAKE
RunService.RenderStepped:Connect(function()
	if shakePower > 0 then
		local offset = Vector3.new(
			(math.random()-0.5)*shakePower,
			(math.random()-0.5)*shakePower,
			(math.random()-0.5)*shakePower
		)
		camera.CFrame = camera.CFrame * CFrame.new(offset)
		shakePower *= 0.85
	end
end)

local function triggerShake(pos,size)
	local dist = (root.Position-pos).Magnitude
	local radius = getHitbox(size)
	if dist > radius then return end

	local falloff = 1 - (dist/radius)
	local intensity = size*0.5 * falloff

	shakePower = math.max(shakePower,intensity)
end

--// RANDOM
local function randomSize()
	local s = math.random(5,40)
	return Vector3.new(s,s,s), s
end

local function randomDir()
	local v
	repeat
		v = Vector3.new(math.random(-100,100)/100,0,math.random(-100,100)/100)
	until v.Magnitude > 0.1
	return v.Unit
end

--// CREATE
local function createMeteor()
	local sizeVec,size = randomSize()
	local purple = purpleActive
	local blue = (not purple) and blueActive
	local explosive = (not purple and not blue) and explosiveActive
	local lightning = (not purple and not blue and not explosive) and (math.random() < 0.15)
local toxic = (not purple and not blue and not explosive and not lightning) and toxicActive

	-- Ä‘Å¸â€Â¥ SUPER NORMAL METEOR
	local isGiant = false
	if (not purple) and (not blue) then
		if math.random() < 0.2 then
			local bigSize = math.random(100,200)
			sizeVec = Vector3.new(bigSize,bigSize,bigSize)
			size = bigSize
			isGiant = true
		end
	end

	local p = Instance.new("Part")
	p.Shape = Enum.PartType.Ball
	p.Size = sizeVec
	p.Material = Enum.Material.Slate
	p.Color = Color3.fromRGB(80,50,30)
	p.Anchored = true
	p.CanCollide = false
	p.Parent = workspace

	-- Ä‘Å¸ÂÂ·Ã¯Â¸Â NAME
	if explosive then
	p.Name = "Explosive Meteor"
elseif blue then
	p.Name = "Rolling Meteor"
elseif purple then
	p.Name = "Gravity Meteor"
	elseif lightning then
	p.Name = "Lightning Meteor"
	elseif toxic then
	p.Name = "Toxic Meteor"
else
	p.Name = "Normal Meteor"
end

	local fire = Instance.new("Fire",p)
	fire.Size = size*1.5
	fire.Heat = size*2

	if purple then
		fire.Color = Color3.fromRGB(170,0,255)
		fire.SecondaryColor = Color3.fromRGB(255,0,255)
	elseif blue then
		fire.Color = Color3.fromRGB(0,170,255)
		fire.SecondaryColor = Color3.fromRGB(0,255,255)
	elseif explosive then
	fire.Color = Color3.fromRGB(255,0,0)
	fire.SecondaryColor = Color3.fromRGB(255,100,100)
	elseif lightning then
	fire.Color = Color3.fromRGB(255, 255, 100)
	fire.SecondaryColor = Color3.fromRGB(255, 200, 0)
	elseif toxic then
	fire.Color = Color3.fromRGB(0,255,0)
	fire.SecondaryColor = Color3.fromRGB(100,255,100)
	end

	-- Ä‘Å¸Å’Â«Ã¯Â¸Â SMOKE (NHÃ¡ÂºÂ¸ HÃ† N)
	local smoke = Instance.new("Smoke",p)
	smoke.Size = size
	smoke.Opacity = 0.2
	smoke.RiseVelocity = 2
	
	-- Ä‘Å¸â€Â¥ ORANGE SMOKE (VFX MÃ¡Â»ÂšI)
local orangeSmoke = Instance.new("Smoke", p)
orangeSmoke.Size = size
orangeSmoke.Opacity = 0.15 -- nhÃ¡ÂºÂ¹ hÃ†Â¡n khÄ‚Â³i chÄ‚Â­nh
orangeSmoke.RiseVelocity = 3 -- bay nhanh hÃ†Â¡n chÄ‚Âºt
orangeSmoke.Color = Color3.fromRGB(255, 140, 0) -- CAM CÃ¡Â»Â Ã„ÂÃ¡Â»ÂŠNH

if toxic then
	orangeSmoke.Color = Color3.fromRGB(0,255,0)
elseif purple then
	orangeSmoke.Color = Color3.fromRGB(170,0,255)
elseif blue then
	orangeSmoke.Color = Color3.fromRGB(0,170,255)
elseif explosive then
	orangeSmoke.Color = Color3.fromRGB(255,0,0)
elseif lightning then
	orangeSmoke.Color = Color3.fromRGB(255,255,100)
else
	orangeSmoke.Color = Color3.fromRGB(255,140,0)
end

	-- Ä‘Å¸â€™Â¡ LIGHT THEO LOÃ¡Âº I
	local light = Instance.new("PointLight",p)
	light.Range = size*2
	light.Brightness = size/5

	if purple then
		light.Color = Color3.fromRGB(170,0,255)
	elseif blue then
		light.Color = Color3.fromRGB(0,170,255)
	elseif explosive then
	light.Color = Color3.fromRGB(255,0,0)
	elseif toxic then
	light.Color = Color3.fromRGB(0,255,0)
	else
		light.Color = Color3.fromRGB(255,140,0)
	end

	return {
		part = p,
		size = size,
		purple = purple,
		blue = blue,
		giant = isGiant,
		vel = lightning and Vector3.new(
	math.random(-80,80),
	-math.random(LIGHTNING_MIN_SPEED, LIGHTNING_MAX_SPEED),
	math.random(-80,80)
) or Vector3.new(
	math.random(-80,80),
	-math.random(MIN_SPEED,MAX_SPEED),
	math.random(-80,80)
),
		landed = false,
		rolling = false,
		life = 0,
		rollCooldown = 0, 
		explosive = explosive,
explodeStage = 0, -- 0 = chÆ°a ná»•, 1 = Ä‘Ã£ ná»• láº§n 1
explodeTimer = 0, 
debrisSpawned = false, 
lightning = lightning,
lightningTriggered = false, 
toxic = toxic, 
fxDone = false
	}
end

--// DAMAGE
local function applyDamage(pos,size,isGiant)
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then return end

	local dist = (root.Position-pos).Magnitude
	local radius = getHitbox(size)
	if dist > radius then return end

	-- Ä‘Å¸â€™â‚¬ GIANT = ONE SHOT
	if isGiant then
		hum.Health = 0
		ShowImage(112158886382827)
	fah()
		return
	end

	-- Ä‘Å¸â€Â¥ DAMAGE THÃ†Â¯Ã¡Â»Å“NG
	local falloff = 1 - (dist/radius)
	local dmg = size * DAMAGE_MULTIPLIER * falloff
	dmg = math.max(dmg, size*0.6)

	hum:TakeDamage(dmg)
end

--// KNOCK
local function knock(pos,size)
	local dist = (root.Position-pos).Magnitude
	local radius = getHitbox(size)
	if dist > radius then return end

	local falloff = 1 - (dist/radius)
	local dir = (root.Position-pos).Unit

	local bv = Instance.new("BodyVelocity")
	bv.Velocity = dir*(size*10*falloff) + Vector3.new(0,size*3*falloff,0)
	bv.MaxForce = Vector3.new(1e5,1e5,1e5)
	bv.Parent = root

	Debris:AddItem(bv,0.25)
end

--// SOUND
local function playImpactSound(pos,size)
	local part = Instance.new("Part")
	part.Anchored = true
	part.Transparency = 1
	part.CanCollide = false
	part.Position = pos
	part.Parent = workspace

	local sound = Instance.new("Sound")
	sound.SoundId = IMPACT_SOUND_ID

	local n = math.clamp((size-5)/35,0,1)
	sound.Volume = 3 + (10-5)*(n^1.2)
	sound.PlaybackSpeed = 0.9 + n*0.6

	sound.RollOffMode = Enum.RollOffMode.Inverse
	sound.RollOffMinDistance = SOUND_MIN_DISTANCE
	sound.RollOffMaxDistance = SOUND_MAX_DISTANCE

	sound.Parent = part
	sound:Play()

	Debris:AddItem(part, sound.TimeLength+1)
end

local function playLightningSound(pos, size)

	local part = Instance.new("Part")
	part.Anchored = true
	part.Transparency = 1
	part.CanCollide = false
	part.Position = pos
	part.Parent = workspace

	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://139968319088532" -- âš¡ sound sÃ©t (m cÃ³ thá»ƒ Ä‘á»•i)
	
	-- ðŸ”Š chá»‰nh Ã¢m cho Ä‘Ã£ tai
	local n = math.clamp((size-5)/35,0,1)
	sound.Volume = 4 + 6*n
	sound.PlaybackSpeed = 0.9 + math.random()*0.3

	sound.RollOffMode = Enum.RollOffMode.Inverse
	sound.RollOffMinDistance = 20
	sound.RollOffMaxDistance = 350

	sound.Parent = part
	sound:Play()

	game:GetService("Debris"):AddItem(part, 3)
end

--// SUCK
local function suck(pos,size)
	local dist = (root.Position-pos).Magnitude
	if dist > SUCK_RADIUS then return end

	-- Ä‘Å¸â€™Â¨ HÄ‚ÂšT
	local dir = (pos-root.Position).Unit
	root.Velocity = dir*(size*8)

	-- Ä‘Å¸â€™â‚¬ DAMAGE (0.2s / 1 HP)
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum and hum.Health > 0 then
		if tick() - lastGravityTick >= 0.2 then
			lastGravityTick = tick()
			hum:TakeDamage(1)
		end
	end
end

local function spawnGiantFire(pos, size)
	-- Ä‘Å¸â€œÂ container giÃ¡Â»Â¯ toÄ‚ n bÃ¡Â»â„¢ lÃ¡Â»Â­a
	local folder = Instance.new("Folder")
	folder.Name = "GiantFireZone"
	folder.Parent = workspace

	-- Ä‘Å¸â€Â¥ tÃ¡ÂºÂ¡o nhiÃ¡Â»Âu Ã„â€˜iÃ¡Â»Æ’m lÃ¡Â»Â­a quanh vÄ‚Â¹ng nÃ¡Â»â€¢
	local count = math.floor(size / 8) + 10

	for i = 1, count do
		local offset = Vector3.new(
			math.random(-size, size),
			0,
			math.random(-size, size)
		)

		local p = Instance.new("Part")
		p.Anchored = true
		p.CanCollide = false
		p.Transparency = 1
		p.Size = Vector3.new(2, 2, 2)
		p.Position = pos + offset
		p.Parent = folder

		local fire = Instance.new("Fire")
		fire.Size = math.random(10, 20)
		fire.Heat = math.random(15, 30)
		fire.Parent = p
	end

	-- Ä‘Å¸â€™â‚¬ DAMAGE LOOP
	task.spawn(function()
		local startTime = tick()
		local lastTickDamage = 0

		while tick() - startTime < FIRE_LIFETIME do
			local char = player.Character
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			local rootPart = char and char:FindFirstChild("HumanoidRootPart")

			if hum and rootPart then
				local touching = false

				-- Ä‘Å¸â€Â check chÃ¡ÂºÂ¡m lÃ¡Â»Â­a
				for _, obj in ipairs(folder:GetChildren()) do
					if obj:IsA("BasePart") then
						if (obj.Position - rootPart.Position).Magnitude <= 4 then
							touching = true
							break
						end
					end
				end

				-- Ã¢ÂÂ±Ã¯Â¸Â damage 1s/lÃ¡ÂºÂ§n
				if touching then
					if tick() - lastTickDamage >= 1 then
						lastTickDamage = tick()
						hum:TakeDamage(FIRE_DAMAGE)
					end
				end
			end

			task.wait(0.2)
		end

		-- Ä‘Å¸Â§Â¹ cleanup toÄ‚ n bÃ¡Â»â„¢
		if folder and folder.Parent then
			folder:Destroy()
		end
	end)
end

local function spawnLightningFire(pos, beamSize)
	-- ðŸ“ container
	local folder = Instance.new("Folder")
	folder.Name = "LightningFire"
	folder.Parent = workspace

	-- ðŸ”¥ part giá»¯ lá»­a
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.Transparency = 1

	-- size phá»¥ thuá»™c beam
	local s = math.clamp(beamSize * 3, 4, 30)
	p.Size = Vector3.new(s, 2, s)
	p.Position = pos
	p.Parent = folder

	-- ðŸ”¥ fire
	local fire = Instance.new("Fire")
	fire.Size = beamSize * 4
	fire.Color = Color3.fromRGB(255, 255, 100)
	fire.SecondaryColor = Color3.fromRGB(255, 255, 0)
	fire.Heat = beamSize * 6
	fire.Parent = p

	-- ðŸ’¥ damage nháº¹ (tuá»³ m thÃ­ch giá»¯ hay bá»)
	task.spawn(function()
		local start = tick()
		local lastTick = 0

		while tick() - start < 10 do
			local char = player.Character
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			local rootPart = char and char:FindFirstChild("HumanoidRootPart")

			if hum and rootPart then
				if (rootPart.Position - p.Position).Magnitude <= s then
					if tick() - lastTick >= 1 then
						lastTick = tick()
						hum:TakeDamage(2)
					end
				end
			end

			task.wait(0.2)
		end

		if folder then
			folder:Destroy()
		end
	end)
end

local function spawnMeteorDebris(pos, size)
	size = math.max(1, math.floor(size or 10))

	local folder = Instance.new("Folder")
	folder.Name = "MeteorDebris"
	folder.Parent = workspace

	local parts = {}

	-- Ä‘Å¸â€Â¥ FIX: giÃ¡Â»â€ºi hÃ¡ÂºÂ¡n tÃ¡Â»â€˜i Ã„â€˜a 30 parts
	local count = math.floor(size * 1.5)
	count = math.clamp(count, 12, 30)

	local partSizeBase = math.clamp(size / 12, 1, 25)

	for i = 1, count do
		local p = Instance.new("Part")
		p.Shape = Enum.PartType.Block
		p.Material = Enum.Material.Slate
		p.Color = Color3.fromRGB(90, 70, 50)
		p.Anchored = false
		p.CanCollide = true

		local s = partSizeBase * (safeRand(50,120)/100)

-- Ä‘Å¸â€Â¥ clamp size tÃ¡Â»â€˜i Ã„â€˜a 30
s = math.clamp(s, 0.5, 30)

p.Size = Vector3.new(s, s, s)

		p.Position = pos + Vector3.new(
			safeRand(-size, size),
			safeRand(2, math.max(3, size/3)),
			safeRand(-size, size)
		)

		p.Parent = folder
		table.insert(parts, p)

		local force = math.clamp(size * 4, 80, 1500)

		local dir = Vector3.new(
			safeRand(-100,100)/100,
			safeRand(60,140)/100,
			safeRand(-100,100)/100
		).Unit

		local bv = Instance.new("BodyVelocity")
		bv.MaxForce = Vector3.new(1e6,1e6,1e6)
		bv.Velocity = dir * force
		bv.Parent = p

		game:GetService("Debris"):AddItem(bv, 0.25)
	end

	task.delay(5, function()
		for _, p in ipairs(parts) do
			if p and p.Parent then
				task.spawn(function()
					local fadeTime = math.random(2,4)

					local tween = TweenService:Create(p, TweenInfo.new(fadeTime), {
						Transparency = 1,
						Size = p.Size * math.random(20,60)/100
					})

					tween:Play()
					tween.Completed:Wait()
					if p then p:Destroy() end
				end)
			end
		end

		task.delay(5, function()
			if folder then folder:Destroy() end
		end)
	end)
end

local function spawnSlimeSplashFX(pos, size)

	-- ðŸ“¦ holder
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.Transparency = 1
	part.Size = Vector3.new(1,1,1)
	part.Position = pos
	part.Parent = workspace

	-- ðŸ’¦ SPLASH (báº¯n tÃ³e)
	local splash = Instance.new("ParticleEmitter")
	splash.Texture = "rbxassetid://243660364" -- ðŸ’¦ liquid splash
	splash.Rate = 0
	splash.Lifetime = NumberRange.new(0.4, 0.8)
	splash.Speed = NumberRange.new(size*1.5, size*3)
	splash.SpreadAngle = Vector2.new(360, 360)
	splash.Rotation = NumberRange.new(0,360)
	splash.RotSpeed = NumberRange.new(-180,180)
	splash.Size = NumberSequence.new({
	NumberSequenceKeypoint.new(0, size*0.3),
	NumberSequenceKeypoint.new(1, 0)
})
	splash.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 1)
	})
	splash.Color = ColorSequence.new(Color3.fromRGB(0,255,0))
	splash.Parent = part

	splash:Emit(math.clamp(size*3, 15, 60))

	-- ðŸŒ«ï¸ TOXIC MIST
	local mist = Instance.new("ParticleEmitter")
	mist.Texture = "rbxassetid://771221224" -- smoke má»m
	mist.Rate = 0
	mist.Lifetime = NumberRange.new(1.5, 3)
	mist.Speed = NumberRange.new(1, 3)
	mist.Size = NumberSequence.new(size*0.8)
	mist.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(1, 1)
	})
	mist.Color = ColorSequence.new(Color3.fromRGB(100,255,100))
	mist.Parent = part

	mist:Emit(math.clamp(size*2, 10, 40))

	-- âœ¨ GLOW FLASH
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(0,255,0)
	light.Range = size * 3
	light.Brightness = size * 2
	light.Parent = part

	-- ðŸ”» fade light
	task.spawn(function()
		for i = 1,10 do
			light.Brightness *= 0.6
			task.wait(0.05)
		end
	end)

	-- ðŸ§ª DROPLETS (giá»t nhá» bay ra)
	for i = 1, math.clamp(size/2, 5, 20) do
		local d = Instance.new("Part")
		d.Size = Vector3.new(0.5,0.5,0.5)
		d.Shape = Enum.PartType.Ball
		d.Material = Enum.Material.Neon
		d.Color = Color3.fromRGB(0,255,0)
		d.CanCollide = false
		d.Anchored = false
		d.Position = pos
		d.Parent = workspace

		local bv = Instance.new("BodyVelocity")
		bv.MaxForce = Vector3.new(1e5,1e5,1e5)
		bv.Velocity = Vector3.new(
			math.random(-50,50),
			math.random(20,80),
			math.random(-50,50)
		)
		bv.Parent = d

		game:GetService("Debris"):AddItem(bv, 0.2)

		task.delay(1, function()
			if d then
				local tween = TweenService:Create(d, TweenInfo.new(0.5), {
					Transparency = 1,
					Size = Vector3.new(0,0,0)
				})
				tween:Play()
				tween.Completed:Wait()
				d:Destroy()
			end
		end)
	end

	-- cleanup
	game:GetService("Debris"):AddItem(part, 4)
end

local function spawnToxicSlime(pos, size)

local base = math.clamp(math.floor(size / 6), 4, 20)
local count = math.random(base, base + 5)

for i = 1, count do

	task.spawn(function()

		-- ðŸŸ¢ slime bomb
		local slime = Instance.new("Part")
		slime.Shape = Enum.PartType.Ball
		slime.Material = Enum.Material.Neon
		slime.Color = Color3.fromRGB(0,255,0)
		slime.Transparency = 0.1
		slime.CanCollide = true
		slime.Anchored = false

		local scale = math.clamp(size * 0.25, 3, size * 0.8)
		slime.Size = Vector3.new(scale, scale, scale)

		-- spawn random quanh vÃ¹ng ná»•
		local offset = Vector3.new(
			math.random(-size, size),
			math.random(20, size),
			math.random(-size, size)
		)

		slime.Position = pos + offset
		slime.Parent = workspace

		-- ðŸ’¥ khi cháº¡m Ä‘áº¥t (KHÃ”NG DAMAGE)
		local touched = false

		slime.Touched:Connect(function(hit)
			if touched then return end
			if not hit or not hit:IsA("BasePart") then return end
			
			touched = true

			-- ðŸ“Œ dÃ­nh xuá»‘ng Ä‘áº¥t
			slime.Anchored = true
			slime.CanCollide = false

			-- â±ï¸ delay random (ná»• lá»‡ch nhau)
			local delayTime = 3 + math.random() * 3
			task.wait(delayTime)

			if not slime or not slime.Parent then return end

			local explodePos = slime.Position

			-- ðŸ’¦ FX
			spawnSlimeSplashFX(explodePos, scale)

			-- ðŸ”Š sound + debris
			playImpactSound(explodePos, scale)
			spawnMeteorDebris(explodePos, scale)

			-- ðŸ§¹ cleanup
			slime:Destroy()

		end)

		-- ðŸ”¥ fallback (náº¿u ko cháº¡m gÃ¬ váº«n ná»• + damage)
		task.delay(8, function()
			if slime and slime.Parent and not touched then

				slime.Anchored = true

				local explodePos = slime.Position

				-- ðŸ’¦ FX
				spawnSlimeSplashFX(explodePos, scale)

				-- ðŸ”Š sound + debris
				playImpactSound(explodePos, scale)
				spawnMeteorDebris(explodePos, scale)

				slime:Destroy()
			end
		end)

	end)

end

end

--// EXPLOSION
local function explosion(pos, size, isGiant)
	size = math.max(1, math.floor(size or 10)) -- Ä‘Å¸â€Â¥ chÃ¡Â»â€˜ng nil

	local ex = Instance.new("Explosion")
	ex.Position = pos
	ex.BlastRadius = size * 2
	ex.BlastPressure = 0
	ex.DestroyJointRadiusPercent = 0
	ex.Parent = workspace

	local p = Instance.new("Part")
	p.Shape = Enum.PartType.Ball
	p.Anchored = true
	p.CanCollide = false
	p.Material = Enum.Material.Neon
	p.Color = Color3.fromRGB(255,140,0)
	p.Size = Vector3.new(1,1,1)
	p.Position = pos
	p.Parent = workspace

	local s = size * 2
	local fadeTime = math.clamp(size / 40, 0.3, 2)

	local t = TweenService:Create(p, TweenInfo.new(fadeTime), {
		Size = Vector3.new(s,s,s),
		Transparency = 1
	})

	t:Play()
	t.Completed:Connect(function()
		if p then p:Destroy() end
	end)

	triggerShake(pos, size)
	knock(pos, size)
	playImpactSound(pos, size)
	applyDamage(pos, size, false)

	spawnMeteorDebris(pos, size)

	if isGiant then
		spawnGiantFire(pos, size)
	end
end

local function spawnGroundVFX(pos, size)
	-- Ä‘Å¸ÂŽÂ¯ PART giÃ¡Â»Â¯ GUI
	local holder = Instance.new("Part")
	holder.Anchored = true
	holder.CanCollide = false
	holder.Transparency = 1
	holder.Size = Vector3.new(size*2, 0.1, size*2) -- Ä‘Å¸â€Â¥ flat theo size
	holder.Position = pos + Vector3.new(0,0.05,0)
	holder.Parent = workspace

	-- Ä‘Å¸â€œÂº GUI (DÄ‚ÂN LÄ‚ÂŠN MÃ¡ÂºÂ¶T TRÄ‚ÂŠN)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Top
	gui.CanvasSize = Vector2.new(512,512)
	gui.Parent = holder

	local img = Instance.new("ImageLabel")
	img.Size = UDim2.fromScale(1,1)
	img.BackgroundTransparency = 1
	img.Image = "rbxassetid://108570852046746" -- Ä‘Å¸â€“Â¼Ã¯Â¸Â m tÃ¡Â»Â± thay
	img.ImageTransparency = 0
	img.Parent = gui

	-- Ä‘Å¸â€œÂ³ SHAKE lÄ‚Âºc spawn (giÃ¡Â»Â¯ nguyÄ‚Âªn logic)
	task.spawn(function()
		for i = 1,10 do
			img.Position = UDim2.new(0, math.random(-10,10), 0, math.random(-10,10))
			task.wait(0.03)
		end
		img.Position = UDim2.new(0,0,0,0)
	end)

	-- Ä‘Å¸Å’Â«Ã¯Â¸Â fade nhÃ¡ÂºÂ¹ ban Ã„â€˜Ã¡ÂºÂ§u
	local tween1 = TweenService:Create(img, TweenInfo.new(1), {
		ImageTransparency = 0.3
	})
	tween1:Play()

	-- Ã¢ÂÂ³ fade out theo size
	task.spawn(function()
		task.wait(4)

		local fadeTime = math.clamp(size/20, 1, 5)

		local tween2 = TweenService:Create(img, TweenInfo.new(fadeTime), {
			ImageTransparency = 1,
			Size = UDim2.new(1.2,0,1.2,0) -- Ä‘Å¸â€Â¥ phÄ‚Â³ng nhÃ¡ÂºÂ¹ ra
		})

		tween2:Play()
		tween2.Completed:Wait()

		holder:Destroy()
	end)
end

local function spawnLightningStrikes(pos, size)

	task.spawn(function()

		local startTime = tick()

		while tick() - startTime < 5 do -- sá»‘ng 5s
			
			task.wait(0.3) -- âš¡ má»—i 0.3s 1 tia
			
			local offset = Vector3.new(
				math.random(-size, size),
				0,
				math.random(-size, size)
			)

			local hitPos = pos + offset

			-- ATTACHMENTS
			local top = Instance.new("Part")
			top.Anchored = true
			top.CanCollide = false
			top.Transparency = 1
			top.Position = hitPos + Vector3.new(0, 120, 0)
			top.Parent = workspace

			local bottom = Instance.new("Part")
			bottom.Anchored = true
			bottom.CanCollide = false
			bottom.Transparency = 1
			bottom.Position = hitPos
			bottom.Parent = workspace

			local a0 = Instance.new("Attachment", top)
			local a1 = Instance.new("Attachment", bottom)

			local beam = Instance.new("Beam")
			beam.Attachment0 = a0
			beam.Attachment1 = a1

			-- ðŸ”¥ size beam (dÃ¹ng cho VFX luÃ´n)
			local beamSize = math.clamp(size * 0.25, 1.5, 12)
			beam.Width0 = beamSize
			beam.Width1 = beamSize

			beam.Color = ColorSequence.new{
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255,255,255)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(255,255,180))
			}

			beam.LightEmission = 1
			beam.Brightness = 4
			beam.Texture = "rbxassetid://446111271"
			beam.TextureSpeed = 3
			beam.TextureLength = 3
			beam.FaceCamera = true
			beam.Parent = top

			-- âš¡ flash nháº¹
			local flash = Instance.new("PointLight")
			flash.Color = Color3.fromRGB(255,255,200)
			flash.Brightness = size
			flash.Range = size * 3
			flash.Parent = bottom

			Debris:AddItem(flash, 0.08)

			-- ðŸ’¥ damage
			local dist = (root.Position - hitPos).Magnitude
			if dist < size then
				local hum = char:FindFirstChildOfClass("Humanoid")
				if hum then
					hum:TakeDamage(size * 1.2)
				end
			end

			-- ðŸ”¥ VFX Máº¶T Äáº¤T THEO BEAM (FIX CHUáº¨N)
			spawnGroundVFX(hitPos, beamSize * 2)
			-- ðŸ”¥ spawn lá»­a theo tia sÃ©t
spawnLightningFire(hitPos, beamSize)

			-- ðŸ”Š sound riÃªng
			playLightningSound(hitPos, size)

			-- cleanup
			task.delay(0.12, function()
				if top then top:Destroy() end
				if bottom then bottom:Destroy() end
			end)

		end

	end)
end

--// SPAWN
task.spawn(function()
	while true do
		if root then
			local m = createMeteor()
			local r = m.blue and BLUE_RADIUS or RADIUS

			m.part.Position = root.Position + Vector3.new(
				math.random(-r,r),
				math.random(300,600),
				math.random(-r,r)
			)

			table.insert(meteors,m)
		end
		task.wait(SPAWN_DELAY)
	end
end)

local function spawnRollVFX(pos, size, normal)
	-- Ä‘Å¸â€œÂ¦ part giÃ¡Â»Â¯ GUI
	local holder = Instance.new("Part")
	holder.Anchored = true
	holder.CanCollide = false
	holder.Transparency = 1
	holder.Size = Vector3.new(1,1,1)
	holder.Position = pos + normal * 0.05
	holder.Parent = workspace

	-- Ä‘Å¸â€œÂº surface GUI
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Top
	gui.AlwaysOnTop = false
	gui.LightInfluence = 1
	gui.CanvasSize = Vector2.new(256,256)
	gui.Parent = holder

	local img = Instance.new("ImageLabel")
	img.Size = UDim2.fromScale(1,1)
	img.BackgroundTransparency = 1
	img.Image = ROLL_VFX_IMAGE
	img.ImageTransparency = 0.2
	img.Rotation = math.random(0,360)
	img.Parent = gui

	-- Ä‘Å¸â€œÂ size theo meteor (clamp cho Ã¡Â»â€¢n)
	local scale = math.clamp(size * 0.8, 3, 40)
holder.Size = Vector3.new(scale, 0.1, scale)
gui.PixelsPerStud = 50

	-- Ä‘Å¸Å’Â«Ã¯Â¸Â fade out
	task.delay(ROLL_VFX_LIFETIME, function()
		local tween = TweenService:Create(img, TweenInfo.new(0.6), {
			ImageTransparency = 1,
			Size = UDim2.fromScale(1.3,1.3)
		})
		tween:Play()
		tween.Completed:Wait()
		holder:Destroy()
	end)
end

local function getVFXScale(size)
	return math.clamp(size / 20, 0.5, 5)
end

--// UPDATE
RunService.RenderStepped:Connect(function(dt)
	for i=#meteors,1,-1 do
		local d = meteors[i]
		local m = d.part

		if not m or not m.Parent then
			table.remove(meteors,i)
			continue
		end

		-- PURPLE
		-- PURPLE
if d.purple and d.landed then
	suck(m.Position,d.size)

	if not d.debrisSpawned then
		spawnMeteorDebris(m.Position, d.size)
		d.debrisSpawned = true
	end

	d.life += dt
	if d.life > 20 then
	-- ðŸ’¥ ná»• trÆ°á»›c khi cháº¿t
	explosion(m.Position, d.size, false)
	spawnMeteorDebris(m.Position, d.size)
	playImpactSound(m.Position, d.size)
	spawnGroundVFX(m.Position, d.size)
	knock(m.Position, d.size)
	triggerShake(m.Position, d.size)

	-- ðŸ§¹ destroy state
	m:Destroy()
	table.remove(meteors,i)
end
	continue
end
		
		-- ðŸ’£ EXPLOSIVE
if d.explosive and d.landed then
	
	d.explodeTimer -= dt
	
	if d.explodeTimer <= 0 then
		
		if d.explodeStage == 0 then
			-- ðŸ’¥ ná»• láº§n 1
			explosion(m.Position, d.size, false)
			playImpactSound(m.Position, d.size)

			-- ðŸ”» thu nhá»
			d.size *= 0.6
			m.Size = Vector3.new(d.size, d.size, d.size)

			-- update fire
			local fire = m:FindFirstChildOfClass("Fire")
			if fire then
				fire.Size = d.size * 1.5
				fire.Heat = d.size * 2
			end

			-- update light
			local light = m:FindFirstChildOfClass("PointLight")
			if light then
				light.Range = d.size * 2
				light.Brightness = d.size / 5
			end

			d.explodeStage = 1
			d.explodeTimer = math.random(2,5)

		else
			-- ðŸ’¥ ná»• láº§n cuá»‘i
			explosion(m.Position, d.size, false)
			playImpactSound(m.Position, d.size)

			m:Destroy()
			table.remove(meteors, i)
		end
	end

	continue
end

		-- BLUE
		if d.blue and d.landed then
			if not d.rolling then continue end
			
			-- Ä‘Å¸Å’â‚¬ ROLL VFX TRAIL
-- Ä‘Å¸Å’â‚¬ ROLL VFX TRAIL (1s / footprint)
if d.rolling then
	d.rollCooldown = (d.rollCooldown or 0) - dt

	if d.rollCooldown <= 0 then
		local velocity = m.AssemblyLinearVelocity

		if velocity.Magnitude > 2 then
			local ray = workspace:Raycast(m.Position, Vector3.new(0,-10,0))

			if ray then
				spawnRollVFX(ray.Position, d.size, ray.Normal)
			else
				spawnRollVFX(m.Position - Vector3.new(0,d.size/2,0), d.size, Vector3.new(0,1,0))
			end
		end

		-- Ã¢ÂÂ±Ã¯Â¸Â 1 giÄ‚Â¢y / footprint
		d.rollCooldown = 0.5
	end
end

			if (root.Position - m.Position).Magnitude < getHitbox(d.size) then
				knock(m.Position,d.size)
				triggerShake(m.Position,d.size)
				applyDamage(m.Position,d.size,d.giant)
				playImpactSound(m.Position,d.size)
			end

			if m.AssemblyLinearVelocity.Magnitude < 5 then
				m.AssemblyLinearVelocity += randomDir()*d.size*4
			end

			d.life += dt
			if d.life > 20 then
	-- ðŸ’¥ ná»• trÆ°á»›c khi cháº¿t
	explosion(m.Position, d.size, false)
	spawnMeteorDebris(m.Position, d.size)
	playImpactSound(m.Position, d.size)
	spawnGroundVFX(m.Position, d.size)
	knock(m.Position, d.size)
	triggerShake(m.Position, d.size)

	-- ðŸ§¹ destroy
	m:Destroy()
	table.remove(meteors,i)
end
			continue
		end

		-- FALL
		local result = workspace:Raycast(m.Position,d.vel.Unit*10)

		if result then
			m.Position = result.Position
			d.landed = true

			triggerShake(result.Position,d.size)
			knock(result.Position,d.size)
			playImpactSound(result.Position,d.size)
			applyDamage(result.Position,d.size,d.giant)
			spawnGroundVFX(result.Position, d.size)

			if d.blue then
				m.Anchored = false
				m.CanCollide = true
				
				spawnMeteorDebris(result.Position, d.size)

				local dir = randomDir()
				m.AssemblyLinearVelocity = dir*(d.size*6)
				m.AssemblyAngularVelocity = Vector3.new(
					math.random(-10,10),
					math.random(-10,10),
					math.random(-10,10)
				)

				d.rolling = true

			elseif d.explosive then
				spawnMeteorDebris(result.Position, d.size)
				playImpactSound(result.Position, d.size)

				d.explodeTimer = math.random(2,5)

			elseif d.lightning then
	
	if not d.lightningTriggered then
		d.lightningTriggered = true

		explosion(result.Position, d.size, false)
		spawnMeteorDebris(result.Position, d.size)
		playImpactSound(result.Position, d.size)
		spawnGroundVFX(result.Position, d.size)

		spawnLightningStrikes(result.Position, d.size)
	end

	m:Destroy()
	table.remove(meteors,i)
	
	elseif d.toxic and not d.fxDone then
    d.fxDone = true

	-- ðŸŸ¢ explosion xanh
	local ex = Instance.new("Explosion")
	ex.Position = result.Position
	ex.BlastRadius = d.size * 2
	ex.BlastPressure = 0
	ex.DestroyJointRadiusPercent = 0
	ex.Parent = workspace

	local p = Instance.new("Part")
	p.Shape = Enum.PartType.Ball
	p.Anchored = true
	p.CanCollide = false
	p.Material = Enum.Material.Neon
	p.Color = Color3.fromRGB(0,255,0) -- ðŸŸ¢ GREEN FIX
	p.Size = Vector3.new(1,1,1)
	p.Position = result.Position
	p.Parent = workspace

	local s = d.size * 2

	local t = TweenService:Create(p, TweenInfo.new(1), {
		Size = Vector3.new(s,s,s),
		Transparency = 1
	})

	t:Play()
	t.Completed:Connect(function()
		if p then p:Destroy() end
	end)

	triggerShake(result.Position, d.size)
	knock(result.Position, d.size)
	playImpactSound(result.Position, d.size)
	applyDamage(result.Position, d.size, false)

	spawnMeteorDebris(result.Position, d.size)
	spawnGroundVFX(result.Position, d.size)
	
	spawnSlimeSplashFX(result.Position, d.size * getVFXScale(d.size))

	-- â˜£ï¸ slime
	spawnToxicSlime(result.Position, d.size * getVFXScale(d.size))

	m:Destroy()
	table.remove(meteors,i)

elseif not d.purple then
	explosion(result.Position,d.size,d.giant)
	spawnMeteorDebris(result.Position, d.size)
	m:Destroy()
	table.remove(meteors,i)
			end

		else
			m.Position += d.vel*dt
		end
	end
end)

--// RESPAWN
player.CharacterAdded:Connect(function(c)
	char = c
	root = c:WaitForChild("HumanoidRootPart")
end)
