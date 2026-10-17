-- AUTO-GENERATED oleh tools/bundle.js — JANGAN edit manual.
-- Edit modul-nya langsung, terus run `node tools/bundle.js`.
-- 44 modul, di-generate 2026-10-17T00:58:34.592Z
return {
	["app.lua"] = [=[
--[[ app.lua — init akhir garden: default tab Inventory + auto-resume automation. ]]
return function(ctx)
	local CFG = ctx.CFG
	local pages = ctx.ui.pages
	local tabBtns = ctx.ui.tabBtns
	local C = ctx.C

	-- toast "loaded" di pojok kanan bawah
	pcall(function()
		local host = (gethui and gethui()) or game:GetService("CoreGui")
		local old = host:FindFirstChild("AHNotif"); if old then old:Destroy() end
		local sg = Instance.new("ScreenGui")
		sg.Name = "AHNotif"; sg.ResetOnSpawn = false; sg.IgnoreGuiInset = true; sg.DisplayOrder = 9999; sg.Parent = host
		local f = Instance.new("Frame")
		f.AnchorPoint = Vector2.new(1, 1)
		f.Position = UDim2.new(1, 280, 1, -20)     -- mulai di luar layar (buat slide-in)
		f.Size = UDim2.fromOffset(250, 62)
		f.BackgroundColor3 = C.panel or Color3.fromRGB(24, 26, 31)
		f.BorderSizePixel = 0; f.Parent = sg
		local cr = Instance.new("UICorner"); cr.CornerRadius = UDim.new(0, 12); cr.Parent = f
		local strk = Instance.new("UIStroke"); strk.Color = C.acc; strk.Thickness = 1.5; strk.Transparency = 0.2; strk.Parent = f
		local pad = Instance.new("UIPadding"); pad.PaddingLeft = UDim.new(0, 14); pad.PaddingTop = UDim.new(0, 10); pad.Parent = f
		local title = Instance.new("TextLabel")
		title.BackgroundTransparency = 1; title.Size = UDim2.new(1, -14, 0, 18)
		title.Font = Enum.Font.FredokaOne; title.TextSize = 16; title.TextXAlignment = Enum.TextXAlignment.Left
		title.RichText = true; title.Text = '✦ CeszParadiseHub <font color="#ff3287">Garden</font>'
		title.TextColor3 = C.txt; title.Parent = f
		local body = Instance.new("TextLabel")
		body.BackgroundTransparency = 1; body.Size = UDim2.new(1, -14, 0, 16); body.Position = UDim2.fromOffset(0, 24)
		body.Font = Enum.Font.Ubuntu; body.TextSize = 13
		local initFps = math.clamp(math.round(workspace:GetRealPhysicsFPS() or 60), 1, 999)
		body.Text = ("Loaded successfully ✦  |  %d FPS"):format(initFps); body.TextColor3 = C.accSoft; body.Parent = f
		local TS = game:GetService("TweenService")
		TS:Create(f, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = UDim2.new(1, -20, 1, -20) }):Play()
		task.delay(3, function()
			pcall(function()
				TS:Create(f, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Position = UDim2.new(1, 280, 1, -20) }):Play()
				task.wait(0.45); sg:Destroy()
			end)
		end)
	end)

	-- default tab = Inventory
	local function selectTab(name)
		for n, p in pairs(pages) do p.Visible = (n == name) end
		for n, b in pairs(tabBtns) do
			if b.setActive then
				b.setActive(n == name)
			else
				b.btn.BackgroundTransparency = (n == name) and 0.85 or 1
				b.btn.TextColor3 = (n == name) and C.txt or C.sub
				b.line.Visible = (n == name)
			end
		end
	end
	selectTab("Inventory")

	ctx.log("CeszParadiseHub Garden dimuat.")
	ctx.setStatus("idle")

	-- Anti-AFK: reset timer idle Roblox (kick ~20 menit) tiap Idled fire, via VirtualUser.
	pcall(function()
		local VirtualUser = game:GetService("VirtualUser")
		ctx.LP.Idled:Connect(function()
			pcall(function()
				VirtualUser:CaptureController()
				VirtualUser:ClickButton2(Vector2.new())
			end)
			ctx.log("Anti-AFK: reset idle timer.")
		end)
		ctx.log("Anti-AFK aktif.")
	end)

	------------------------------------------------------------------ Auto-Reconnect (on Disconnect)
	-- Kalau ke-kick / DC / error (dialog Roblox muncul) -> otomatis rejoin ke game yg sama,
	-- lalu hub di-load ulang di server baru (via queue_on_teleport). Ikut branch aktif.
	pcall(function()
		local GuiService = game:GetService("GuiService")
		local TeleportService = game:GetService("TeleportService")
		local branch = (getgenv and getgenv().GAG_BRANCH) or _G.GAG_BRANCH or "main"
		local RECON = ("if getgenv then getgenv().GAG_BRANCH=%q end;loadstring(game:HttpGet('https://raw.githubusercontent.com/milmscr/iniapa/%s/cobainaja/init.lua'))()"):format(branch, branch)
		local reconnecting = false
		local function reconnect()
			if reconnecting or CFG.autoReconnect == false then return end -- cek toggle real-time
			reconnecting = true
			ctx.log("Ke-DC/kick terdeteksi — auto reconnect...")
			local q = queue_on_teleport or queueonteleport or (syn and syn.queue_on_teleport)
			if q then pcall(function() q(RECON) end) end
			task.wait(3)
			pcall(function() TeleportService:Teleport(game.PlaceId, ctx.LP) end)
			-- fallback: kalau teleport gagal (place instance), coba matchmaking biasa
			task.wait(8)
			pcall(function() TeleportService:Teleport(game.PlaceId, ctx.LP) end)
		end
		GuiService.ErrorMessageChanged:Connect(reconnect)
		ctx.log("Auto-Reconnect (anti-DC) aktif.")
	end)

	-- auto-resume ESP label kalau sebelumnya aktif
	if CFG.espEnabled and ctx.startEsp then
		ctx.startEsp()
		ctx.log("Auto-resume: ESP Label ON.")
	end
	if CFG.espInvEnabled and ctx.startEspInv then
		ctx.startEspInv()
		ctx.log("Auto-resume: ESP Base Weight (Inventory) ON.")
	end
	if CFG.noclipEnabled and ctx.setNoclip then ctx.setNoclip(true); ctx.log("Auto-resume: Noclip ON.") end
	if CFG.walkSpeedEnabled and ctx.setWalkSpeed then ctx.setWalkSpeed(true); ctx.log("Auto-resume: Walk Speed ON.") end
	if CFG.infJumpEnabled and ctx.setInfJump then ctx.setInfJump(true); ctx.log("Auto-resume: Infinity Jump ON.") end
	if CFG.hideMyPlants and ctx.setHidePlants then ctx.setHidePlants("mine", true); ctx.log("Auto-resume: Hide My Plants ON.") end
	if CFG.hideOtherPlants and ctx.setHidePlants then ctx.setHidePlants("other", true); ctx.log("Auto-resume: Hide Other Plants ON.") end
	if CFG.autoRemoveWebFx and ctx.setAutoRemoveWeb then ctx.setAutoRemoveWeb(true); ctx.log("Auto-resume: Auto Remove Web FX ON.") end
	if CFG.perfMode and CFG.perfMode ~= "off" and ctx.setPerfMode then ctx.setPerfMode(CFG.perfMode); ctx.log("Auto-resume: Performance Mode = " .. tostring(CFG.perfMode)) end
	if CFG.disable3d and ctx.setDisable3d then ctx.setDisable3d(true); ctx.log("Auto-resume: Disable 3D ON.") end

	-- pre-warm harga Premium Shop di background (ditunda biar ga rebutan sama init).
	if ctx.premiumPrewarm then
		task.delay(6, function() if ctx.alive() then ctx.premiumPrewarm() end end)
	end

	-- auto-resume Auto Reclaimer kalau sebelumnya aktif
	if CFG.reclaimEnabled and ctx.startReclaim then
		ctx.startReclaim()
		ctx.log("Auto-resume: Auto Reclaimer ON.")
	end

	-- auto-resume Auto Plants kalau sebelumnya aktif
	if CFG.plantSeedEnabled and ctx.startPlant then
		ctx.startPlant()
		ctx.log("Auto-resume: Auto Plants ON.")
	end

	-- auto-resume Auto Sprinkler + Shovel Sprinkler
	if CFG.sprinklerEnabled and ctx.startSprinkler then
		ctx.startSprinkler()
		ctx.log("Auto-resume: Auto Sprinkler ON.")
	end
	if CFG.shovelSprinklerEnabled and ctx.startShovelSprinkler then
		ctx.startShovelSprinkler()
		ctx.log("Auto-resume: Auto Shovel Sprinkler ON.")
	end

	-- auto-resume Auto Reconnect (biar loop rejoin lanjut tiap masuk server)
	if CFG.reconnectEnabled and ctx.startReconnect then
		ctx.startReconnect()
		ctx.log("Auto-resume: Auto Reconnect ON.")
	end

	-- auto-resume PNP kalau sebelumnya aktif (V1 polling / V2 event-driven, mutually exclusive)
	if CFG.pnpEnabled and ctx.startPnpV1 then
		task.wait(1)
		ctx.startPnpV1()
		ctx.log("Auto-resume: PNP V1 ON.")
	elseif CFG.pnpV2Enabled and ctx.startPnpV2 then
		task.wait(1)
		ctx.startPnpV2()
		ctx.log("Auto-resume: PNP V2 ON.")
	end

	-- auto-resume kalau sebelumnya aktif
	if CFG.tradeEnabled or CFG.tradeTicketEnabled then
		task.wait(1.5)
		ctx.state.completed = 0
		ctx.startTrade("ticket")
		if ctx.refreshTradeStatus then ctx.refreshTradeStatus() end
		ctx.log("Auto-resume: automation trade (ticket) ON.")
	elseif CFG.tradeGiftEnabled then
		task.wait(1.5)
		ctx.state.completed = 0
		ctx.startTrade("gift")
		if ctx.refreshGiftStatus then ctx.refreshGiftStatus() end
		ctx.log("Auto-resume: automation trade (gift) ON.")
	end

	-- auto-resume Leveling kalau sebelumnya aktif
	if CFG.levelingEnabled and ctx.startLeveling then
		task.wait(2.0)
		ctx.startLeveling()
		ctx.log("Auto-resume: Leveling ON.")
	end

	-- auto-resume Leveling V2 kalau sebelumnya aktif
	if CFG.levelingV2Enabled and ctx.startLevelingV2 then
		task.wait(2.0)
		ctx.startLevelingV2()
		ctx.log("Auto-resume: Leveling V2 ON.")
	end

	-- auto-resume Auto Hatch kalau sebelumnya aktif
	if CFG.hatchEnabled and ctx.startHatch then
		task.wait(2.0)
		ctx.startHatch()
		ctx.log("Auto-resume: Auto Hatch ON.")
	end

	-- auto-resume Egg Rejoin Watcher kalau sebelumnya aktif
	if (CFG.hatchRejoinMinusEnabled or CFG.hatchRejoinPlusEnabled) and ctx.startEggMinusWatcher then
		ctx.startEggMinusWatcher()
		ctx.log("Auto-resume: Egg Rejoin Watcher ON.")
	end

	-- auto-resume Auto Favourite Pets kalau sebelumnya aktif
	if CFG.autoFavorite and ctx.startAutoFavorite then
		ctx.startAutoFavorite()
		ctx.log("Auto-resume: Auto Favourite ON.")
	end

	-- auto-resume Growth kalau sebelumnya aktif
	if CFG.growthEnabled and ctx.startGrowth then
		task.wait(2.0)
		ctx.startGrowth()
		ctx.log("Auto-resume: Growth ON.")
	end

	-- auto-resume Mutation kalau sebelumnya aktif
	if CFG.mutationEnabled and ctx.startMutation then
		task.wait(2.5)
		ctx.startMutation()
		ctx.log("Auto-resume: Mutation ON.")
	end

	-- auto-resume Elephant kalau sebelumnya aktif
	if CFG.elephantEnabled and ctx.startElephant then
		task.wait(2.5)
		ctx.startElephant()
		ctx.log("Auto-resume: Elephant ON.")
	end

	if CFG.elephantV2Enabled and ctx.startElephantV2 then
		task.wait(2.5)
		ctx.startElephantV2()
		ctx.log("Auto-resume: Elephant V2 ON.")
	end

	-- auto-resume Boost Pet kalau sebelumnya aktif
	if CFG.boostEnabled and ctx.startBoostPet then
		task.wait(2.5)
		ctx.startBoostPet()
		ctx.log("Auto-resume: Boost Pet ON.")
	end

	-- auto-resume Cleanse kalau sebelumnya aktif
	if CFG.cleanseEnabled and ctx.startCleanse then
		task.wait(2.5)
		ctx.startCleanse()
		ctx.log("Auto-resume: Cleanse ON.")
	end

	-- auto-resume Beanstalk Event kalau sebelumnya aktif
	if ctx.beanstalkAnyOn and ctx.beanstalkAnyOn() and ctx.startBeanstalk then
		task.wait(2.5)
		ctx.startBeanstalk()
		ctx.log("Auto-resume: Beanstalk Event ON.")
	end

	-- auto-resume Shop (buy seed/egg/gear)
	if CFG.buySeedEnabled and ctx.startBuySeed then ctx.startBuySeed(); ctx.log("Auto-resume: Buy Seed ON.") end
	if CFG.buyEggEnabled and ctx.startBuyEgg then ctx.startBuyEgg(); ctx.log("Auto-resume: Buy Egg ON.") end
	if CFG.buyGearEnabled and ctx.startBuyGear then ctx.startBuyGear(); ctx.log("Auto-resume: Buy Gear ON.") end
	if ctx.merchantAnyOn and ctx.merchantAnyOn() and ctx.startBuyMerchant then ctx.startBuyMerchant(); ctx.log("Auto-resume: Buy Merchant ON.") end
	if CFG.merchantAutoOpenUI and ctx.startAutoOpenUI then ctx.startAutoOpenUI(); ctx.log("Auto-resume: Merchant Auto Open UI ON.") end
	if CFG.waterEnabled and ctx.startWater then ctx.startWater(); ctx.log("Auto-resume: Auto Water ON.") end
	if CFG.shovelTreeEnabled and ctx.startShovelTree then ctx.startShovelTree(); ctx.log("Auto-resume: Auto Shovel Tree ON.") end
	if CFG.shovelFruitEnabled and ctx.startShovelFruit then ctx.startShovelFruit(); ctx.log("Auto-resume: Auto Shovel Fruit ON.") end
	if (CFG.collectWlFruitEnabled or CFG.collectWlMutEnabled or CFG.collectCombEnabled) and ctx.startCollect then
		ctx.startCollect(); ctx.log("Auto-resume: Auto Collect ON.")
	end
	if (CFG.favEnabled or CFG.unfavEnabled) and ctx.startFavorite then
		ctx.startFavorite(); ctx.log("Auto-resume: Auto Favorite ON.")
	end
	if CFG.beanstalkClaimEnabled and ctx.startBeanstalkClaim then ctx.startBeanstalkClaim(); ctx.log("Auto-resume: Beanstalk Claim Reward ON.") end
	if CFG.beanstalkHopEnabled and ctx.startBeanstalkHop then task.wait(3); ctx.startBeanstalkHop(); ctx.log("Auto-resume: Beanstalk Auto Hop ON.") end
	if CFG.buyBeanstalkShopEnabled and ctx.startBuyBeanstalkShop then ctx.startBuyBeanstalkShop(); ctx.log("Auto-resume: Buy Beanstalk Shop ON.") end
end
]=],
	["modules/core/config.lua"] = [=[
--[[ config.lua — CFG default + persist/load state JSON (garden). ]]
return function(ctx)
	local HttpService = ctx.Services.HttpService
	local Players = ctx.Services.Players or game:GetService("Players")

	-- 1. Pastikan LocalPlayer dan UserId sudah siap (hindari nil)
	local localPlayer = Players.LocalPlayer
	while not localPlayer do
		Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
		localPlayer = Players.LocalPlayer
	end
	local userId = localPlayer.UserId

	local CFG = {
		-- Automation Trade (Ticket)
		targetPlayer   = "",      -- nama player tujuan
		petTypes       = {},      -- set: {["Fire Wisp"]=true}; kosong = semua non-favorite
		weightFilter   = 0,       -- 0=off | +N = minimal Nkg | -N = maksimal Nkg
		ageFilter      = 0,       -- 0=off | +N = minimal age N | -N = maksimal age N
		petsPerTrade   = 12,
		totalTrades    = 14,
		autoUnfavorite = false,
		tradeEnabled   = false,   -- Enable Automation Trade (Ticket)
		tradeTicketEnabled = false,

		-- Automation Trade (Gift)
		giftTargetPlayer     = "",
		giftPetTypes         = {},
		giftWeightFilter     = 0,
		giftAgeFilter        = 0,
		giftPetsPerBatch     = 12,
		giftTotalGifts       = 100,
		giftAutoUnfavorite   = false,
		tradeGiftEnabled     = false,

		-- ===== Auto Hatch + Auto Sell =====
		hatchEnabled    = false,
		autoSellEnabled = false,
		-- teams (set uuid pet)
		hatchCoreTeam   = {},  -- team default/idle
		hatchHatchTeam  = {},  -- team saat hatch (recovery + speed)
		hatchBrontoTeam = {},  -- team bronto (hatch speed)
		hatchSellTeam   = {},  -- team saat jual (boost harga)
		-- egg config
		hatchEggName    = "Rare Egg", -- egg yg di-place & di-hatch
		hatchMaxPlaced  = 8,          -- target egg ke-place di garden
		hatchPlacePattern = "Grid",   -- pola taro egg: "Grid" (rapih) / "Random" (sebar acak)
		hatchTeamDelay  = 5.5,        -- detik tunggu abis swap team sebelum hatch
		hatchWebhookUrl   = "",       -- webhook Discord buat Hatch Alert (bronto)
		hatchAlertEnabled = false,    -- kirim alert pas pet masuk filter bronto
		hatchRejoinMinusEnabled   = false, -- Auto rejoin kalau egg minus
		hatchRejoinMinusThreshold = 20,    -- Threshold jumlah minus untuk trigger rejoin (misal: 20 -> <= -20)
		hatchRejoinPlusEnabled    = false, -- Auto rejoin kalau egg bertambah (plus)
		hatchRejoinPlusThreshold  = 20,    -- Threshold jumlah plus untuk trigger rejoin (misal: 20 -> >= +20)
		-- bronto config: egg yg pending pet-nya cocok -> hatch pakai Bronto team (+30% berat)
		brontoSpecialPets    = {},   -- set "Pet - Egg" (special: wajib bronto)
		brontoSpecialWeight  = 0,    -- special cuma kalau weight > ini (0 = ga difilter)
		brontoUniversalTypes = {},   -- set tipe pet buat aturan universal (kosong = semua)
		brontoUniversalWeight = 0,   -- pakai bronto kalau weight > ini (0 = off)
		brontoSkipSpecial    = false,-- jangan hatch special pet sama sekali
		brontoTeamDelay      = 5.5,  -- detik tunggu abis swap team sebelum hatch bronto
		-- sell config (filter = DIJUAL; sisanya difavoritin biar aman)
		sellPetTypes       = {},   -- set tipe pet yg dijual
		sellWeightThreshold = 5,   -- jual kalau BaseWeight < ini
		sellAgeThreshold    = 3,   -- jual kalau Age/Level < ini
		sellSpecialTypes    = {},  -- pet spesial (jual by weight)
		sellSpecialWeight   = 10,  -- 0=off
		sellMode   = "Cycle",      -- Cycle | Backpack
		sellStyle  = "All at Once",
		sellEveryNCycles = 1,
		sellWhenReach    = 100,    -- jual kalau backpack pet >= ini
		sellTeamDelay    = 5.5,    -- detik tunggu abis swap team sebelum jual
		autoBoostBeforeSell = false,
		hatchCoreEquipDelay   = 0,
		hatchCoreUnequipDelay = 1,
		hatchBrontoEquipDelay = 0,
		hatchBrontoUnequipDelay = 1,
		hatchTeamEquipDelay   = 0,
		hatchTeamUnequipDelay = 1,
		hatchSellEquipDelay   = 0,
		hatchSellUnequipDelay = 1,
		hatchSellList         = {}, -- { [petName] = { kg = 3, action = "SELL"|"KEEP" } }
		autoUnfavoritePets    = false,
		unfavoritePetTypes    = {},
		tradeMethod           = "ticket", -- "ticket" | "gift"

		-- Automation Accept
		acceptGifts   = false,
		acceptTrades  = false,

		-- Automation Favourite Pets (placeholder)
		autoFavorite      = false,
		favoritePetTypes  = {},

		-- PNP (Pick & Place) pet
		pnpPetTypes = {},     -- (lama) filter per-tipe; kosong = semua equipped
		-- PnP V1 (polling)
		pnpUuids    = {},     -- filter per-UUID pet equipped; kosong = semua equipped
		pickupDelay = 0.3,    -- jeda setelah place sebelum siklus berikutnya
		equipDelay  = 1e-20,  -- jeda antara unequip -> equip (1E-20 = near-zero instant)
		pnpScanInterval = 0.05, -- jeda antar-scan loop PNP (makin kecil = makin sering cek)
		pnpEnabled  = false,
		-- PnP V2 (event-driven, config terpisah dari V1)
		pnpV2Uuids       = {},
		pnpV2PickupDelay = 0.05,
		pnpV2EquipDelay  = 0.03,
		pnpV2ScanInterval = 0.05,
		pnpV2Enabled     = false,
		espEnabled  = false, -- label melayang (ESP) pet+egg di dunia
		espInvEnabled = false, -- ESP base weight di tiap slot pet inventory
		espInvMode  = "age",   -- tampilan ESP inv: "age" (base+age) / "max" (base+max@500)
		noclipEnabled    = false, -- Player: tembus tembok
		walkSpeedEnabled = false, -- Player: pakai custom walk speed
		walkSpeed        = 16,    -- Player: walk speed custom (default 16)
		infJumpEnabled   = false, -- Player: lompat tak terbatas di udara
		hideMyPlants     = false, -- Perf: sembunyiin plant kebun sendiri
		hideOtherPlants  = false, -- Perf: sembunyiin plant kebun lain
		autoRemoveWebFx  = false, -- Perf: auto hapus efek spider web
		perfMode         = "off", -- Perf: off / low / extreme
		disable3d        = false, -- Perf: matiin 3D rendering
		premiumItem      = "",     -- Premium Shop: key item terpilih (DevProductIds)
		premiumPay       = "robux",-- Premium Shop: robux / token

		-- Automation Leveling
		levelingTeamUuids   = {},
		levelingPetTypes    = {},
		levelingTargetLevel = 500,
		levelingMaxPets     = 2,
		levelingEnabled     = false,

		-- Automation Leveling V2 (2 phase)
		levelingV2PetTypes = {},
		levelingV2P1Team   = {},
		levelingV2P1Target = 40,
		levelingV2P1Max    = 3,
		levelingV2P2Team   = {},
		levelingV2P2Target = 500,
		levelingV2P2Max    = 1,
		levelingV2Enabled  = false,

		-- Growth (pipeline: Elephant -> Mutation -> Leveling, batch per-step, config TERPISAH)
		growthEnabled      = false,
		growthPetTypes     = {},                                                    -- target default (dipakai step yg per-step-nya kosong)
		growthFlow         = { "elephant", "mutation", "leveling" }, -- urutan Step 1/2/3
		-- target pet PER-METHOD (kalau kosong -> fallback ke growthPetTypes)
		growthPetTypesElephant = {},
		growthPetTypesMutation = {},
		growthPetTypesLeveling = {},
		-- step Elephant
		growthElephantTeam   = {},
		growthElephantWeight = 5.5,
		growthElephantMax    = 2,
		-- step Mutation (aura)
		growthMutationTeam    = {},
		growthMutationTargets = {},   -- target mutasi (mis. Ember/Nightmare/Rainbow)
		growthMutationMax     = 2,
		-- step Leveling (2 phase)
		growthLevP1Team   = {},
		growthLevP1Target = 40,
		growthLevP1Max    = 3,
		growthLevP2Team   = {},
		growthLevP2Target = 500,
		growthLevP2Max    = 1,

		-- Automation Mutation
		mutationExpTeam       = {},
		mutationBoostTeam     = {},
		mutationPhoenixTeam   = {},
		mutationTargetTypes   = {},
		mutationTargetMutations = {},
		mutationTargetAge     = 50,
		mutationDelayAutoClaim = 0.5,
		mutationEnabled       = false,

		-- Automation Shop (buy seed/egg/gear)
		buySeedNames   = {},
		buySeedEnabled = false,
		buyEggNames    = {},
		buyEggEnabled  = false,
		buyGearNames   = {},
		buyGearEnabled = false,

		-- Automation Merchant (Traveling Merchant auto-buy) — toggle bisa nyala barengan (union)
		merchantBuyEnabled = false,    -- Auto Buy Merchant: beli item terpilih (per-merchant)
		merchantBuyAll     = false,    -- Auto Buy All: beli semua item ada stock
		merchantBuyBest    = false,    -- Auto Buy Best: beli 1 item termahal ada stock
		merchantItems      = {},       -- selection PER-MERCHANT/EVENT: { [id] = {item=true} }
		merchantUiShop     = "",       -- Open UI: event shop yang mau dibuka UI-nya
		merchantAutoOpenUI = false,    -- Open UI: jaga UI shop terpilih tetap kebuka

		-- Automation Water (siram plant terpilih pakai Watering Can / Water_RE)
		waterFruitNames = {},
		waterEnabled    = false,
		waterDelay      = 1,

		-- Automation Shovel (hapus plant / fruit via Remove_Item)
		shovelTreeNames    = {},
		shovelTreeEnabled  = false,
		shovelTreeDelay    = 0,
		shovelFruitNames    = {},
		shovelFruitMuts     = {},
		shovelFruitVariants = {},
		shovelFruitMode     = ">= (berat minimal)",
		shovelFruitWeight   = 0,
		shovelFruitEnabled  = false,
		shovelFruitDelay    = 0,

		-- Automation Collection (harvest fruit via Crops.Collect)
		collectDelay          = 0,
		collectStopIfFull     = false,
		collectAutoSellIfFull = false,
		collectWlFruitNames   = {},
		collectWlFruitEnabled = false,
		collectWlMutNames     = {},
		collectWlMutEnabled   = false,
		collectCombFruitNames = {},
		collectCombMutNames   = {},
		collectCombVariants   = {},
		collectCombMode       = ">= (berat minimal)",
		collectCombWeight     = 0,
		collectCombEnabled    = false,

		-- Automation Favorite (favorite/unfavorite fruit via Favorite Tool)
		favFruitNames = {},
		favMutNames   = {},
		favMode       = ">= (berat minimal)",
		favWeight     = 0,
		favDelay      = 1,
		favEnabled    = false,
		unfavEnabled  = false,

		-- Automation Reclaimer (Farm): reclaim plant terpilih pakai tool Reclaimer
		reclaimPlantNames = {},
		reclaimEnabled    = false,
		reclaimSpeed      = 0.15,

		-- Automation Plants (Farm): tanam seed dari inventory
		plantSeedNames   = {},
		plantPosition    = "Random",
		plantDelay       = 0,
		plantSeedEnabled = false,

		-- Automation Sprinkler (Farm): pasang + shovel sprinkler
		sprinklerNames        = {},
		sprinklerPlantNames   = {},
		sprinklerPosition     = "Random",
		sprinklerDelay        = 0,
		sprinklerEnabled      = false,
		shovelSprinklerNames  = {},
		shovelSprinklerDelay  = 0,
		shovelSprinklerEnabled = false,

		-- Auto-Reconnect (Misc): auto rejoin kalau ke-kick / disconnect (seperti di Trade)
		autoReconnect     = true,

		-- Automation Reconnect (Misc): auto rejoin tiap interval
		reconnectEnabled  = false,
		reconnectInterval = 5,   -- menit

		-- Automation Cleanse Mutation (mutasi via aura + cleanse)
		cleanseTeamUuids     = {},   -- Pet Team for Mutation (aura pemberi mutasi)
		cleansePetTypes      = {},   -- Pet Types for Mutation (target)
		cleanseKeepMutations = {},   -- Mutations to Keep (won't cleanse)
		cleanseMaxPets       = 2,    -- Max Pets in Garden (target)
		cleanseEnabled       = false,

		-- Automation Boost Pet
		boostPetUuids  = {},
		boostItemNames = {},
		boostEnabled   = false,

		-- Automation Elephant (V1)
		elephantTeamUuids   = {},
		elephantPetTypes    = {},
		elephantTargetWeight = 5.5,
		elephantMaxPets     = 2,
		elephantEnabled     = false,
		-- Elephant V2: swap gajah keluar-masuk saat target hit level 40 (barengan PNP)
		elephantV2Team      = {},   -- sumber pet Switch (team standby di garden)
		elephantV2Types     = {},   -- tipe pet target yg dipantau levelnya
		elephantV2Weight    = 5.5,  -- berat max target sebelum dilepas
		elephantV2MaxPets   = 3,    -- jumlah pet target aktif barengan
		elephantV2Gajah     = "",   -- uuid pet gajah (booster berat)
		elephantV2Switch    = "",   -- uuid pet team yg ditukar sama gajah
		elephantV2Level     = 40,   -- ambang level target buat masukin gajah
		elephantV2Interval  = 0.1,  -- interval baca level (detik)
		elephantV2Enabled   = false,

		-- Automation Event: Beanstalk (NPC Jack) — feed plant sesuai craving trait
		beanstalkPlantEnabled   = false, -- auto tanam seed craving
		beanstalkCollectEnabled = false, -- auto panen fruit craving
		beanstalkSubmitEnabled  = false, -- auto setor produce craving ke beanstalk
		beanstalkClaimEnabled   = false, -- auto claim reward beanstalk (reward point aktif)
		beanstalkAutoSellEnabled= false, -- backpack mentok (trait salah) -> jual SEMUA backpack
		beanstalkHopEnabled     = false, -- auto hop server sampai nemu beanstalk growth < 900
		beanstalkPlantCount     = 20,    -- target jumlah tanam per siklus
		beanstalkDelay          = 0.2,   -- jeda antar aksi (detik)
		buyBeanstalkShopNames   = {},    -- item Beanstalk Event Shop (Goliath's Goods/Friends Deals)
		buyBeanstalkShopEnabled = false,

		-- webhook (opsional)
		webhookUrl     = "",
		webhookEnabled = false,
	}

	-- Setiap clone punya file terpisah (contoh: garden_state_12345.json)
	local STATE_FILE = "garden_state_" .. tostring(userId) .. ".json"

	-- 1. Simpan langsung ke file akun ini saja
	local function persistState()
		pcall(function()
			if type(writefile) == "function" then
				writefile(STATE_FILE, HttpService:JSONEncode(CFG))
			end
		end)
	end

	-- 2. Muat langsung dari file akun ini saja
	local function loadState()
		if type(isfile) == "function" and isfile(STATE_FILE) then
			local ok, data = pcall(function()
				return HttpService:JSONDecode(readfile(STATE_FILE))
			end)
			if ok and type(data) == "table" then
				return data
			end
		end
		return nil
	end

	do
		local st = loadState()
		if st then
			CFG.targetPlayer   = st.targetPlayer or ""
			CFG.petTypes       = (type(st.petTypes) == "table") and st.petTypes or {}
			CFG.weightFilter   = tonumber(st.weightFilter) or 0
			CFG.ageFilter      = tonumber(st.ageFilter) or 0
			CFG.petsPerTrade   = tonumber(st.petsPerTrade) or 12
			CFG.totalTrades    = tonumber(st.totalTrades) or 14
			CFG.autoUnfavorite = st.autoUnfavorite or false
			CFG.tradeEnabled   = st.tradeEnabled or false
			CFG.tradeTicketEnabled = st.tradeTicketEnabled or st.tradeEnabled or false

			CFG.giftTargetPlayer     = st.giftTargetPlayer or ""
			CFG.giftPetTypes         = (type(st.giftPetTypes) == "table") and st.giftPetTypes or {}
			CFG.giftWeightFilter     = tonumber(st.giftWeightFilter) or 0
			CFG.giftAgeFilter        = tonumber(st.giftAgeFilter) or 0
			CFG.giftPetsPerBatch     = tonumber(st.giftPetsPerBatch) or 12
			CFG.giftTotalGifts       = tonumber(st.giftTotalGifts) or 100
			CFG.giftAutoUnfavorite   = st.giftAutoUnfavorite or false
			CFG.tradeGiftEnabled     = st.tradeGiftEnabled or false
			-- Auto Hatch + Auto Sell
			CFG.hatchEnabled    = st.hatchEnabled or false
			CFG.autoSellEnabled = st.autoSellEnabled or false
			local function tbl(v) return (type(v) == "table") and v or {} end
			CFG.hatchCoreTeam   = tbl(st.hatchCoreTeam)
			CFG.hatchHatchTeam  = tbl(st.hatchHatchTeam)
			CFG.hatchBrontoTeam = tbl(st.hatchBrontoTeam)
			CFG.hatchSellTeam   = tbl(st.hatchSellTeam)
			CFG.hatchEggName    = st.hatchEggName or "Rare Egg"
			CFG.hatchMaxPlaced  = tonumber(st.hatchMaxPlaced) or 8
			CFG.hatchPlacePattern = st.hatchPlacePattern or "Grid"
			CFG.hatchTeamDelay  = tonumber(st.hatchTeamDelay) or 5.5
			CFG.hatchSpeed      = tonumber(st.hatchSpeed) or 0
			CFG.hatchWebhookUrl   = st.hatchWebhookUrl or ""
			CFG.hatchAlertEnabled = st.hatchAlertEnabled or false
			CFG.hatchRejoinMinusEnabled   = st.hatchRejoinMinusEnabled or false
			CFG.hatchRejoinMinusThreshold = tonumber(st.hatchRejoinMinusThreshold) or 20
			CFG.hatchRejoinPlusEnabled    = st.hatchRejoinPlusEnabled or false
			CFG.hatchRejoinPlusThreshold  = tonumber(st.hatchRejoinPlusThreshold) or 20
			CFG.brontoSpecialPets    = tbl(st.brontoSpecialPets)
			CFG.brontoSpecialWeight  = tonumber(st.brontoSpecialWeight) or 0
			CFG.brontoUniversalTypes = tbl(st.brontoUniversalTypes)
			CFG.brontoUniversalWeight = tonumber(st.brontoUniversalWeight) or 0
			CFG.brontoSkipSpecial    = st.brontoSkipSpecial or false
			CFG.brontoTeamDelay      = tonumber(st.brontoTeamDelay) or 5.5
			CFG.sellPetTypes    = tbl(st.sellPetTypes)
			CFG.sellWeightThreshold = tonumber(st.sellWeightThreshold) or 5
			CFG.sellAgeThreshold    = tonumber(st.sellAgeThreshold) or 3
			CFG.sellSpecialTypes    = tbl(st.sellSpecialTypes)
			CFG.sellSpecialWeight   = tonumber(st.sellSpecialWeight) or 10
			CFG.sellMode   = st.sellMode or "Cycle"
			CFG.sellStyle  = st.sellStyle or "All at Once"
			CFG.sellEveryNCycles = tonumber(st.sellEveryNCycles) or 1
			CFG.sellWhenReach    = tonumber(st.sellWhenReach) or 100
			CFG.sellTeamDelay    = tonumber(st.sellTeamDelay) or 5.5
			CFG.autoBoostBeforeSell = st.autoBoostBeforeSell or false
			CFG.hatchCoreEquipDelay   = tonumber(st.hatchCoreEquipDelay) or 0
			CFG.hatchCoreUnequipDelay = tonumber(st.hatchCoreUnequipDelay) or 1
			CFG.hatchBrontoEquipDelay = tonumber(st.hatchBrontoEquipDelay) or 0
			CFG.hatchBrontoUnequipDelay = tonumber(st.hatchBrontoUnequipDelay) or 1
			CFG.hatchTeamEquipDelay   = tonumber(st.hatchTeamEquipDelay) or 0
			CFG.hatchTeamUnequipDelay = tonumber(st.hatchTeamUnequipDelay) or 1
			CFG.hatchSellEquipDelay   = tonumber(st.hatchSellEquipDelay) or 0
			CFG.hatchSellUnequipDelay = tonumber(st.hatchSellUnequipDelay) or 1
			CFG.hatchSellList         = tbl(st.hatchSellList)
			CFG.autoUnfavoritePets    = st.autoUnfavoritePets or false
			CFG.unfavoritePetTypes    = tbl(st.unfavoritePetTypes)
			CFG.tradeMethod           = st.tradeMethod or "ticket"
			CFG.acceptGifts    = st.acceptGifts or false
			CFG.acceptTrades   = st.acceptTrades or false
			CFG.autoFavorite   = st.autoFavorite or false
			CFG.favoritePetTypes = (type(st.favoritePetTypes) == "table") and st.favoritePetTypes or {}
			CFG.pnpPetTypes = (type(st.pnpPetTypes) == "table") and st.pnpPetTypes or {}
			CFG.pnpUuids    = (type(st.pnpUuids) == "table") and st.pnpUuids or {}
			CFG.pickupDelay = tonumber(st.pickupDelay) or 0.3
			CFG.equipDelay  = tonumber(st.equipDelay) or 1e-20
			CFG.pnpScanInterval = tonumber(st.pnpScanInterval) or 0.05
			CFG.pnpEnabled  = st.pnpEnabled or false
			CFG.pnpV2Uuids       = (type(st.pnpV2Uuids) == "table") and st.pnpV2Uuids or {}
			CFG.pnpV2PickupDelay = tonumber(st.pnpV2PickupDelay) or 0.05
			CFG.pnpV2EquipDelay  = tonumber(st.pnpV2EquipDelay) or 0.03
			CFG.pnpV2ScanInterval = tonumber(st.pnpV2ScanInterval) or 0.05
			CFG.pnpV2Enabled     = st.pnpV2Enabled or false
			CFG.espEnabled = st.espEnabled or false
			CFG.espInvEnabled = st.espInvEnabled or false
			CFG.espInvMode = st.espInvMode or "age"
			CFG.noclipEnabled = st.noclipEnabled or false
			CFG.walkSpeedEnabled = st.walkSpeedEnabled or false
			CFG.walkSpeed = tonumber(st.walkSpeed) or 16
			CFG.infJumpEnabled = st.infJumpEnabled or false
			CFG.hideMyPlants = st.hideMyPlants or false
			CFG.hideOtherPlants = st.hideOtherPlants or false
			CFG.autoRemoveWebFx = st.autoRemoveWebFx or false
			CFG.perfMode = st.perfMode or "off"
			CFG.disable3d = st.disable3d or false
			CFG.premiumItem = st.premiumItem or ""
			CFG.premiumPay = st.premiumPay or "robux"
			
			CFG.levelingTeamUuids   = (type(st.levelingTeamUuids) == "table") and st.levelingTeamUuids or {}
			CFG.levelingPetTypes    = (type(st.levelingPetTypes) == "table") and st.levelingPetTypes or {}
			CFG.levelingTargetLevel = tonumber(st.levelingTargetLevel) or 500
			CFG.levelingMaxPets     = tonumber(st.levelingMaxPets) or 2
			CFG.levelingEnabled     = st.levelingEnabled or false

			-- Leveling V2
			CFG.levelingV2PetTypes = (type(st.levelingV2PetTypes) == "table") and st.levelingV2PetTypes or {}
			CFG.levelingV2P1Team   = (type(st.levelingV2P1Team) == "table") and st.levelingV2P1Team or {}
			CFG.levelingV2P1Target = tonumber(st.levelingV2P1Target) or 40
			CFG.levelingV2P1Max    = tonumber(st.levelingV2P1Max) or 3
			CFG.levelingV2P2Team   = (type(st.levelingV2P2Team) == "table") and st.levelingV2P2Team or {}
			CFG.levelingV2P2Target = tonumber(st.levelingV2P2Target) or 500
			CFG.levelingV2P2Max    = tonumber(st.levelingV2P2Max) or 1
			CFG.levelingV2Enabled  = st.levelingV2Enabled or false

			-- Growth
			CFG.growthEnabled  = st.growthEnabled or false
			CFG.growthPetTypes = (type(st.growthPetTypes) == "table") and st.growthPetTypes or {}
			CFG.growthPetTypesElephant = (type(st.growthPetTypesElephant) == "table") and st.growthPetTypesElephant or {}
			CFG.growthPetTypesMutation = (type(st.growthPetTypesMutation) == "table") and st.growthPetTypesMutation or {}
			CFG.growthPetTypesLeveling = (type(st.growthPetTypesLeveling) == "table") and st.growthPetTypesLeveling or {}
			CFG.growthFlow     = (type(st.growthFlow) == "table") and st.growthFlow or { "elephant", "mutation", "leveling" }
			CFG.growthElephantTeam   = (type(st.growthElephantTeam) == "table") and st.growthElephantTeam or {}
			CFG.growthElephantWeight = tonumber(st.growthElephantWeight) or 5.5
			CFG.growthElephantMax    = tonumber(st.growthElephantMax) or 2
			CFG.growthMutationTeam    = (type(st.growthMutationTeam) == "table") and st.growthMutationTeam or {}
			CFG.growthMutationTargets = (type(st.growthMutationTargets) == "table") and st.growthMutationTargets or {}
			CFG.growthMutationMax     = tonumber(st.growthMutationMax) or 2
			CFG.growthLevP1Team   = (type(st.growthLevP1Team) == "table") and st.growthLevP1Team or {}
			CFG.growthLevP1Target = tonumber(st.growthLevP1Target) or 40
			CFG.growthLevP1Max    = tonumber(st.growthLevP1Max) or 3
			CFG.growthLevP2Team   = (type(st.growthLevP2Team) == "table") and st.growthLevP2Team or {}
			CFG.growthLevP2Target = tonumber(st.growthLevP2Target) or 500
			CFG.growthLevP2Max    = tonumber(st.growthLevP2Max) or 1

			-- Automation Mutation
			CFG.mutationExpTeam       = (type(st.mutationExpTeam) == "table") and st.mutationExpTeam or {}
			CFG.mutationBoostTeam     = (type(st.mutationBoostTeam) == "table") and st.mutationBoostTeam or {}
			CFG.mutationPhoenixTeam   = (type(st.mutationPhoenixTeam) == "table") and st.mutationPhoenixTeam or {}
			CFG.mutationTargetTypes   = (type(st.mutationTargetTypes) == "table") and st.mutationTargetTypes or {}
			CFG.mutationTargetMutations = (type(st.mutationTargetMutations) == "table") and st.mutationTargetMutations or {}
			CFG.mutationTargetAge     = tonumber(st.mutationTargetAge) or 50
			CFG.mutationDelayAutoClaim = tonumber(st.mutationDelayAutoClaim) or 0.5
			CFG.mutationEnabled       = st.mutationEnabled or false

			CFG.buySeedNames   = (type(st.buySeedNames) == "table") and st.buySeedNames or {}
			CFG.buySeedEnabled = st.buySeedEnabled or false
			CFG.buyEggNames    = (type(st.buyEggNames) == "table") and st.buyEggNames or {}
			CFG.buyEggEnabled  = st.buyEggEnabled or false
			CFG.buyGearNames   = (type(st.buyGearNames) == "table") and st.buyGearNames or {}
			CFG.buyGearEnabled = st.buyGearEnabled or false

			CFG.merchantBuyEnabled = st.merchantBuyEnabled or false
			CFG.merchantBuyAll     = st.merchantBuyAll or false
			CFG.merchantBuyBest    = st.merchantBuyBest or false
			CFG.merchantItems      = (type(st.merchantItems) == "table") and st.merchantItems or {}
			CFG.merchantUiShop     = st.merchantUiShop or ""
			CFG.merchantAutoOpenUI = st.merchantAutoOpenUI or false

			CFG.waterFruitNames = (type(st.waterFruitNames) == "table") and st.waterFruitNames or {}
			CFG.waterEnabled    = st.waterEnabled or false
			CFG.waterDelay      = tonumber(st.waterDelay) or 1

			CFG.shovelTreeNames    = (type(st.shovelTreeNames) == "table") and st.shovelTreeNames or {}
			CFG.shovelTreeEnabled  = st.shovelTreeEnabled or false
			CFG.shovelTreeDelay    = tonumber(st.shovelTreeDelay) or 0
			CFG.shovelFruitNames    = (type(st.shovelFruitNames) == "table") and st.shovelFruitNames or {}
			CFG.shovelFruitMuts     = (type(st.shovelFruitMuts) == "table") and st.shovelFruitMuts or {}
			CFG.shovelFruitVariants = (type(st.shovelFruitVariants) == "table") and st.shovelFruitVariants or {}
			CFG.shovelFruitMode     = st.shovelFruitMode or ">= (berat minimal)"
			CFG.shovelFruitWeight   = tonumber(st.shovelFruitWeight) or 0
			CFG.shovelFruitEnabled  = st.shovelFruitEnabled or false
			CFG.shovelFruitDelay    = tonumber(st.shovelFruitDelay) or 0

			CFG.collectDelay          = tonumber(st.collectDelay) or 0
			CFG.collectStopIfFull     = st.collectStopIfFull or false
			CFG.collectAutoSellIfFull = st.collectAutoSellIfFull or false
			CFG.collectWlFruitNames   = (type(st.collectWlFruitNames) == "table") and st.collectWlFruitNames or {}
			CFG.collectWlFruitEnabled = st.collectWlFruitEnabled or false
			CFG.collectWlMutNames     = (type(st.collectWlMutNames) == "table") and st.collectWlMutNames or {}
			CFG.collectWlMutEnabled   = st.collectWlMutEnabled or false
			CFG.collectCombFruitNames = (type(st.collectCombFruitNames) == "table") and st.collectCombFruitNames or {}
			CFG.collectCombMutNames   = (type(st.collectCombMutNames) == "table") and st.collectCombMutNames or {}
			CFG.collectCombVariants   = (type(st.collectCombVariants) == "table") and st.collectCombVariants or {}
			CFG.collectCombMode       = st.collectCombMode or ">= (berat minimal)"
			CFG.collectCombWeight     = tonumber(st.collectCombWeight) or 0
			CFG.collectCombEnabled    = st.collectCombEnabled or false

			CFG.favFruitNames = (type(st.favFruitNames) == "table") and st.favFruitNames or {}
			CFG.favMutNames   = (type(st.favMutNames) == "table") and st.favMutNames or {}
			CFG.favMode       = st.favMode or ">= (berat minimal)"
			CFG.favWeight     = tonumber(st.favWeight) or 0
			CFG.favDelay      = tonumber(st.favDelay) or 1
			CFG.favEnabled    = st.favEnabled or false
			CFG.unfavEnabled  = st.unfavEnabled or false

			CFG.reclaimPlantNames = (type(st.reclaimPlantNames) == "table") and st.reclaimPlantNames or {}
			CFG.reclaimEnabled    = st.reclaimEnabled or false
			CFG.reclaimSpeed      = tonumber(st.reclaimSpeed) or 0.15
			CFG.plantSeedNames   = (type(st.plantSeedNames) == "table") and st.plantSeedNames or {}
			CFG.plantPosition    = (st.plantPosition == "Player Position") and "Player Position" or "Random"
			CFG.plantDelay       = tonumber(st.plantDelay) or 0
			CFG.plantSeedEnabled = st.plantSeedEnabled or false
			CFG.sprinklerNames        = (type(st.sprinklerNames) == "table") and st.sprinklerNames or {}
			CFG.sprinklerPlantNames   = (type(st.sprinklerPlantNames) == "table") and st.sprinklerPlantNames or {}
			CFG.sprinklerPosition     = (st.sprinklerPosition == "Player Position") and "Player Position" or "Random"
			CFG.sprinklerDelay        = tonumber(st.sprinklerDelay) or 0
			CFG.sprinklerEnabled      = st.sprinklerEnabled or false
			CFG.shovelSprinklerNames  = (type(st.shovelSprinklerNames) == "table") and st.shovelSprinklerNames or {}
			CFG.shovelSprinklerDelay  = tonumber(st.shovelSprinklerDelay) or 0
			CFG.shovelSprinklerEnabled = st.shovelSprinklerEnabled or false
			if st.autoReconnect ~= nil then CFG.autoReconnect = st.autoReconnect end
			CFG.reconnectEnabled  = st.reconnectEnabled or false
			CFG.reconnectInterval = tonumber(st.reconnectInterval) or 5

			CFG.cleanseTeamUuids     = (type(st.cleanseTeamUuids) == "table") and st.cleanseTeamUuids or {}
			CFG.cleansePetTypes      = (type(st.cleansePetTypes) == "table") and st.cleansePetTypes or {}
			CFG.cleanseKeepMutations = (type(st.cleanseKeepMutations) == "table") and st.cleanseKeepMutations or {}
			CFG.cleanseMaxPets       = tonumber(st.cleanseMaxPets) or 2
			CFG.cleanseEnabled       = st.cleanseEnabled or false

			CFG.boostPetUuids  = (type(st.boostPetUuids) == "table") and st.boostPetUuids or {}
			CFG.boostItemNames = (type(st.boostItemNames) == "table") and st.boostItemNames or {}
			CFG.boostEnabled   = st.boostEnabled or false

			CFG.elephantTeamUuids   = (type(st.elephantTeamUuids) == "table") and st.elephantTeamUuids or {}
			CFG.elephantPetTypes    = (type(st.elephantPetTypes) == "table") and st.elephantPetTypes or {}
			CFG.elephantTargetWeight = tonumber(st.elephantTargetWeight) or 5.5
			CFG.elephantMaxPets     = tonumber(st.elephantMaxPets) or 2
			CFG.elephantEnabled     = st.elephantEnabled or false
			CFG.elephantV2Team      = (type(st.elephantV2Team) == "table") and st.elephantV2Team or {}
			CFG.elephantV2Types     = (type(st.elephantV2Types) == "table") and st.elephantV2Types or {}
			CFG.elephantV2Weight    = tonumber(st.elephantV2Weight) or 5.5
			CFG.elephantV2MaxPets   = tonumber(st.elephantV2MaxPets) or 3
			CFG.elephantV2Gajah     = (type(st.elephantV2Gajah) == "string") and st.elephantV2Gajah or ""
			CFG.elephantV2Switch    = (type(st.elephantV2Switch) == "string") and st.elephantV2Switch or ""
			CFG.elephantV2Level     = tonumber(st.elephantV2Level) or 40
			CFG.elephantV2Interval  = tonumber(st.elephantV2Interval) or 0.1
			CFG.elephantV2Enabled   = st.elephantV2Enabled or false

			CFG.beanstalkPlantEnabled   = st.beanstalkPlantEnabled or false
			CFG.beanstalkCollectEnabled = st.beanstalkCollectEnabled or false
			CFG.beanstalkSubmitEnabled  = st.beanstalkSubmitEnabled or false
			CFG.beanstalkClaimEnabled   = st.beanstalkClaimEnabled or false
			CFG.beanstalkAutoSellEnabled= st.beanstalkAutoSellEnabled or false
			CFG.beanstalkHopEnabled     = st.beanstalkHopEnabled or false
			CFG.beanstalkPlantCount     = tonumber(st.beanstalkPlantCount) or 20
			CFG.beanstalkDelay          = tonumber(st.beanstalkDelay) or 0.2
			CFG.buyBeanstalkShopNames   = (type(st.buyBeanstalkShopNames) == "table") and st.buyBeanstalkShopNames or {}
			CFG.buyBeanstalkShopEnabled = st.buyBeanstalkShopEnabled or false

			CFG.webhookUrl     = st.webhookUrl or ""
			CFG.webhookEnabled = st.webhookEnabled or false
		end
	end

	ctx.CFG = CFG
	ctx.persistState = persistState
end]=],
	["modules/core/registry.lua"] = [=[
--[[ registry.lua — opsi dropdown pet type & mutation. ]]
return function(ctx)
	local PetEggs   = ctx.deps.PetEggs
	local EnumToMut = ctx.deps.EnumToMut

	-- Daftar pet type unik (nama saja, tanpa egg) untuk filter trade.
	-- + peta pet->egg (buat label "Pet - Egg" di filter sell).
	local PET_OPTIONS = {}
	local petEggMap = {}   -- petType -> eggName (egg pertama yg punya pet ini)
	do
		local seen = {}
		for eggName, egg in pairs(PetEggs) do
			local items = egg.RarityData and egg.RarityData.Items
			if items then
				-- skip egg catch-all/admin (mis. "Fake Egg" isi 431 pet) dari peta pet->egg
				local cnt = 0; for _ in pairs(items) do cnt = cnt + 1 end
				local realEgg = eggName ~= "Fake Egg" and cnt <= 40
				for petName in pairs(items) do
					local s = tostring(petName):match("([^/]+)$") or tostring(petName)
					if not tostring(petName):match("^Egg/") and not seen[s] then
						seen[s] = true
						PET_OPTIONS[#PET_OPTIONS + 1] = s
					end
					if realEgg and not petEggMap[s] then petEggMap[s] = eggName end
				end
			end
		end
		table.sort(PET_OPTIONS)
	end

	-- Opsi filter sell: "Pet - Egg". Label = value (dipakai sbg key filter).
	local PET_EGG_OPTIONS = {}
	for _, pt in ipairs(PET_OPTIONS) do
		local egg = petEggMap[pt]
		PET_EGG_OPTIONS[#PET_EGG_OPTIONS + 1] = egg and (pt .. " - " .. egg) or pt
	end
	local function petEggLabel(pt)
		local egg = petEggMap[pt]
		return egg and (pt .. " - " .. egg) or pt
	end

	-- CUMA pet yang punya egg asli (format "Pet - Egg"). Buat filter yang wajib ada egg-nya
	-- (Special Pets, Universal, Pet to Sell) — pet tanpa egg tidak ditampilkan.
	local PET_EGG_ONLY = {}
	for _, pt in ipairs(PET_OPTIONS) do
		if petEggMap[pt] then PET_EGG_ONLY[#PET_EGG_ONLY + 1] = pt .. " - " .. petEggMap[pt] end
	end

	local MUT_OPTIONS, seenMut = { "None" }, { None = true }
	for _, name in pairs(EnumToMut) do
		if name ~= "Normal" and not seenMut[name] then
			seenMut[name] = true
			MUT_OPTIONS[#MUT_OPTIONS + 1] = name
		end
	end
	table.sort(MUT_OPTIONS)

	-- Mutasi yang bisa dari mesin: MachineMutationTypes (base) + Level500MutationTypes (500 only).
	local MACHINE_MUT_OPTIONS = { "None" }
	do
		local ok, MutReg = pcall(function()
			return require(game:GetService("ReplicatedStorage").Data.PetRegistry.PetMutationRegistry)
		end)
		local names, seen = {}, {}
		if ok and MutReg then
			for _, src in ipairs({ MutReg.MachineMutationTypes, MutReg.Level500MutationTypes }) do
				if type(src) == "table" then
					for name in pairs(src) do
						local n = tostring(name)
						if not seen[n] then seen[n] = true; names[#names + 1] = n end
					end
				end
			end
			-- Ice Golem-exclusive dari Mutation Machine (via passive Cold Gears): ada di
			-- PetMutationRegistry tapi bukan di MachineMutationTypes/Level500 -> tambah manual.
			for _, n in ipairs({ "ChristmasRally", "JollyDecorator", "MerryNursery", "GiantGolem" }) do
				local pmr = MutReg.PetMutationRegistry
				if type(pmr) == "table" and pmr[n] and not seen[n] then
					seen[n] = true; names[#names + 1] = n
				end
			end
		end
		if #names > 0 then
			table.sort(names)
			for _, n in ipairs(names) do MACHINE_MUT_OPTIONS[#MACHINE_MUT_OPTIONS + 1] = n end
		else
			MACHINE_MUT_OPTIONS = MUT_OPTIONS -- fallback: semua mutasi
		end
	end

	local function mutDisplay(code)
		if code == nil or code == "" or code == "m" or code == "None" or code == "Normal" then return "None" end
		return EnumToMut[code] or code
	end

	ctx.reg = {
		PET_OPTIONS = PET_OPTIONS,
		PET_EGG_OPTIONS = PET_EGG_OPTIONS,
		PET_EGG_ONLY = PET_EGG_ONLY,
		petEggLabel = petEggLabel,
		MUT_OPTIONS = MUT_OPTIONS,
		MACHINE_MUT_OPTIONS = MACHINE_MUT_OPTIONS,
		mutDisplay = mutDisplay,
	}
end
]=],
	["modules/core/services.lua"] = [=[
--[[ services.lua — services + deps game (garden). ]]
return function(ctx)
	local Players     = game:GetService("Players")
	local RS          = game:GetService("ReplicatedStorage")
	local HttpService = game:GetService("HttpService")
	local UserInputService = game:GetService("UserInputService")

	if not game:IsLoaded() then game.Loaded:Wait() end
	repeat task.wait() until Players.LocalPlayer

	ctx.Services = {
		Players = Players, RS = RS, HttpService = HttpService, UserInputService = UserInputService,
	}
	ctx.LP = Players.LocalPlayer

	local DataService = require(RS.Modules.DataService)
	local PetEggs     = require(RS.Data.PetRegistry.PetEggs)
	local MutReg      = require(RS.Data.PetRegistry.PetMutationRegistry)
	local okPU, PU    = pcall(require, RS.Modules.PetServices.PetUtilities)

	-- TradingController singleton (buat baca state trade aktif)
	local okTC, TradingController = pcall(require, RS.Modules.TradeControllers.TradingController)

	local TradeEvents = RS.GameEvents.TradeEvents

	ctx.deps = {
		DataService      = DataService,
		PetEggs          = PetEggs,
		MutReg           = MutReg,
		EnumToMut        = MutReg.EnumToPetMutation,
		TradingController = okTC and TradingController or nil,

		TradeEvents   = TradeEvents,
		SendRequest   = TradeEvents.SendRequest,
		RespondRequest = TradeEvents.RespondRequest,
		AddItem       = TradeEvents.AddItem,
		RemoveItem    = TradeEvents.RemoveItem,
		Accept        = TradeEvents.Accept,
		Confirm       = TradeEvents.Confirm,
		Decline       = TradeEvents.Decline,
		FavoriteItem  = RS.GameEvents:FindFirstChild("Favorite_Item"),
		Gift          = RS.GameEvents:FindFirstChild("Gift"),
		-- Gift pet langsung (beda dari trade): GiftPet masuk, AcceptPetGift buat terima.
		GiftPet       = RS.GameEvents:FindFirstChild("GiftPet"),
		AcceptPetGift = RS.GameEvents:FindFirstChild("AcceptPetGift"),
		-- PNP (pick & place): PetsService("UnequipPet",uuid) / ("EquipPet",uuid,cframeStr)
		PetsService   = RS.GameEvents:FindFirstChild("PetsService"),
		PU            = okPU and PU or nil,
		-- cooldown skill: PetCooldownsUpdated(uuid, {{Time=,Passive=},...})
		PetCooldownsUpdated = RS.GameEvents:FindFirstChild("PetCooldownsUpdated"),
	}
end
]=],
	["modules/core/webhook.lua"] = [=[
--[[ sender.lua — Helper kirim webhook Discord dengan bypass proxy. ]]
local HttpService = game:GetService("HttpService")

local function sendWebhook(url, payload, ctx)
	if not url or url == "" then return end

	-- Trim leading and trailing whitespace
	local cleanUrl = url:match("^%s*(.-)%s*$")
	if not cleanUrl or cleanUrl == "" then return end

	-- Nama & avatar pengirim webhook (override default). Semua notif tampil "CeszParadiseHub".
	if type(payload) == "table" then
		if not payload.username then payload.username = "CeszParadise" end
		if not payload.avatar_url then payload.avatar_url = "https://raw.githubusercontent.com/milmscr/iniapa/main/cobainaja/Logo/logo_icon.png" end
	end
	
	-- Gunakan proxy jika menggunakan HttpService standard karena Discord memblokir Roblox UA
	local proxiedUrl = cleanUrl:gsub("discord.com/api/webhooks/", "webhook.lewis.es/api/webhooks/")
	proxiedUrl = proxiedUrl:gsub("discordapp.com/api/webhooks/", "webhook.lewis.es/api/webhooks/")
	
	local jsonPayload = HttpService:JSONEncode(payload)

	-- Kirim di thread TERPISAH (fire-and-forget) supaya request HTTP yg blocking
	-- (~100-500ms) TIDAK nge-freeze loop automation yg manggil -> cegah stutter.
	task.spawn(function()
	local sent = false
	local reqErr = ""

	-- 1. Coba gunakan executor HTTP request (client-side, bypass blocks)
	-- Mendukung baik key uppercase maupun lowercase untuk menjamin kompatibilitas 100% executor
	local reqFn = (syn and syn.request) or (http and http.request) or http_request or request
	if reqFn then
		local success, res = pcall(function()
			return reqFn({
				Url = cleanUrl,
				url = cleanUrl,
				Method = "POST",
				method = "POST",
				Headers = {
					["Content-Type"] = "application/json",
					["content-type"] = "application/json"
				},
				headers = {
					["Content-Type"] = "application/json",
					["content-type"] = "application/json"
				},
				Body = jsonPayload,
				body = jsonPayload
			})
		end)
		if success and res then
			if res.StatusCode == 200 or res.StatusCode == 204 then
				sent = true
			else
				reqErr = "StatusCode: " .. tostring(res.StatusCode) .. " - " .. tostring(res.Body or "No response body")
			end
		else
			reqErr = tostring(res or "Unknown executor request error")
		end
	else
		reqErr = "Executor tidak memiliki fungsi request/http_request"
	end

	-- 2. Fallback ke HttpService:PostAsync (menggunakan proxy) jika executor request gagal atau tidak tersedia
	if not sent then
		local success, err = pcall(function()
			HttpService:PostAsync(proxiedUrl, jsonPayload, Enum.HttpContentType.ApplicationJson)
		end)
		if success then
			sent = true
		else
			local errMsg = "Fallback failed: " .. tostring(err) .. " | Exec error: " .. reqErr
			warn("[AllegiaanGarden Webhook] " .. errMsg)
			if ctx and ctx.log then
				ctx.log("[Webhook Error] " .. errMsg)
			end
		end
	end
	end)
end

return sendWebhook
]=],
	["modules/elephant/automation_elephant_v1.lua"] = [=[
--[[ elephant.lua — Automation Elephant (V1).
     Sama seperti Leveling, tapi patokan = BERAT (PetData.BaseWeight, KG), bukan Level.
     Passive elephant numbuhin berat pet target; kalau pet sudah mencapai Target Weight
     (mis. 5.5 KG = max), dicabut dan diganti pet target lain yang belum max. ]]
return function(ctx)
	local DataService = ctx.deps.DataService
	local PetsService = ctx.deps.PetsService
	local CFG         = ctx.CFG
	local LP          = ctx.LP
	local RS          = game:GetService("ReplicatedStorage")

	local function farmCenter()
		local GetFarm = require(RS.Modules.GetFarm)
		local farm = GetFarm and GetFarm(LP)
		local pa = farm and farm:FindFirstChild("PetArea")
		if pa then return pa.Position end
		local char = LP.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		return hrp and hrp.Position or nil
	end

	local slotOf, nextSlot = {}, 0
	local GRID_COLS, GRID_SP = 6, 3
	local function getPos(uuid)
		if not slotOf[uuid] then slotOf[uuid] = nextSlot; nextSlot = nextSlot + 1 end
		local center = farmCenter()
		if not center then return nil end
		local i = slotOf[uuid]
		local col = i % GRID_COLS
		local row = math.floor(i / GRID_COLS)
		local offX = (col - (GRID_COLS - 1) / 2) * GRID_SP
		local offZ = (row - 1) * GRID_SP
		return center + Vector3.new(offX, 0, offZ)
	end

	ctx.state.elephantStatus = "Idle"

	-- Ringkasan statistik untuk UI Status
	function ctx.getElephantSummary()
		local ok, d = pcall(function() return DataService:GetData() end)
		local inv = ok and d and d.PetsData and d.PetsData.PetInventory and d.PetsData.PetInventory.Data or {}

		local teamCount = 0
		for _ in pairs(CFG.elephantTeamUuids) do teamCount = teamCount + 1 end

		local typesList = {}
		for k in pairs(CFG.elephantPetTypes) do table.insert(typesList, k) end
		table.sort(typesList)
		local typesStr = #typesList > 0 and table.concat(typesList, ", ") or "None"

		local readyCount, maxKgCount = 0, 0
		local targetW = CFG.elephantTargetWeight or 5.5

		for _, v in pairs(inv) do
			local pt = v.PetType
			if CFG.elephantPetTypes[pt] then
				local pd = v.PetData or {}
				local w = pd.BaseWeight or 0
				if not pd.IsFavorite then
					if w < targetW then readyCount = readyCount + 1 else maxKgCount = maxKgCount + 1 end
				end
			end
		end

		return {
			status = CFG.elephantEnabled and "ACTIVE" or "STOPPED",
			team = string.format("%d pets", teamCount),
			types = typesStr,
			ready = string.format("%d pets", readyCount),
			maxKg = string.format("%d pets", maxKgCount),
			maxTarget = string.format("%d pets", CFG.elephantMaxPets or 2),
			targetWeight = string.format("%.1f KG", targetW),
		}
	end

	local function checkElephant()
		local ok, d = pcall(function() return DataService:GetData() end)
		if not ok or not d then return end
		local petsData = d.PetsData
		if not petsData then return end
		local eq = petsData.EquippedPets or {}
		local inv = petsData.PetInventory and petsData.PetInventory.Data or {}

		local teamSet = CFG.elephantTeamUuids or {}
		local targetTypes = CFG.elephantPetTypes or {}
		local targetW = CFG.elephantTargetWeight or 5.5
		local maxPets = CFG.elephantMaxPets or 2

		-- Lacak equip lokal (kebal delay replikasi)
		local localEq, localEqCount = {}, 0
		for _, uuid in ipairs(eq) do localEq[uuid] = true; localEqCount = localEqCount + 1 end

		-- A. FIRST RUN: cabut semua pet aktif
		if ctx.state.elephantFirstRun then
			ctx.state.elephantFirstRun = false
			if #eq > 0 then
				ctx.state.elephantStatus = "Resetting garden..."
				for _, uuid in ipairs(eq) do
					pcall(function() PetsService:FireServer("UnequipPet", uuid) end)
					localEq[uuid] = nil; localEqCount = localEqCount - 1
					task.wait(0.25)
				end
			end
		end

		-- B. PERSISTENSI TEAM: pasang lagi pet team yang kecabut
		for uuid, _ in pairs(teamSet) do
			if not localEq[uuid] then
				ctx.state.elephantStatus = "Re-equipping team..."
				local pos = getPos(uuid)
				if pos then
					pcall(function() PetsService:FireServer("EquipPet", uuid, CFrame.new(pos)) end)
					localEq[uuid] = true; localEqCount = localEqCount + 1
					task.wait(0.3)
				end
			end
		end

		-- C. KLASIFIKASI pet target yang di-equip (by BaseWeight)
		local currentGrowing = {}  -- weight < target
		local finishedMax = {}     -- weight >= target
		local otherEquipped = {}
		for uuid, _ in pairs(localEq) do
			if not teamSet[uuid] then
				local pInfo = inv[uuid]
				local pt = pInfo and pInfo.PetType
				local pd = pInfo and pInfo.PetData or {}
				local w = pd.BaseWeight or 0
				if targetTypes[pt] then
					if w < targetW then
						table.insert(currentGrowing, uuid)
						-- catat waktu mulai growing (buat Duration di webhook per-pet)
						ctx.state.elephantStartTime = ctx.state.elephantStartTime or {}
						if not ctx.state.elephantStartTime[uuid] then
							ctx.state.elephantStartTime[uuid] = os.time()
						end
					else table.insert(finishedMax, uuid) end
				else
					table.insert(otherEquipped, uuid)
				end
			end
		end

		-- D. LEPAS pet yang sudah MAX KG (+ webhook agregat + kartu per-pet)
		for _, uuid in ipairs(finishedMax) do
			local pInfo = inv[uuid]
			local pd = pInfo and pInfo.PetData or {}
			local pt = pInfo and pInfo.PetType or "?"
			local w = pd.BaseWeight or 0
			-- Durasi: dari mulai growing sampai sekarang; nil kalau start ga kecatat (mis. reload)
			local duration
			if ctx.state.elephantStartTime and ctx.state.elephantStartTime[uuid] then
				duration = os.time() - ctx.state.elephantStartTime[uuid]
				ctx.state.elephantStartTime[uuid] = nil
			end
			pcall(function() PetsService:FireServer("UnequipPet", uuid) end)
			localEq[uuid] = nil; localEqCount = localEqCount - 1
			if ctx.webhookElephant then
				if ctx.webhookElephant.onFinished then
					pcall(function() ctx.webhookElephant.onFinished(ctx, pt, w) end)
				end
				if ctx.webhookElephant.sendFinished then
					pcall(function() ctx.webhookElephant.sendFinished(ctx, pt, w, pd.MutationType, pd.Level or 0, duration) end)
				end
			end
			task.wait(0.25)
		end

		-- E. TAMBAH pet baru dari inventory (BaseWeight terendah dulu)
		local needed = maxPets - #currentGrowing
		if needed > 0 then
			local pool = {}
			for uuid, v in pairs(inv) do
				local pt = v.PetType
				local pd = v.PetData or {}
				local w = pd.BaseWeight or 0
				if not localEq[uuid] and targetTypes[pt] and w < targetW and not pd.IsFavorite then
					table.insert(pool, { uuid = uuid, weight = w })
				end
			end
			table.sort(pool, function(a, b) return a.weight < b.weight end)

			for i = 1, math.min(needed, #pool) do
				local target = pool[i]
				local pos = getPos(target.uuid)
				if pos then
					if localEqCount >= 15 and #otherEquipped > 0 then
						local toRemove = table.remove(otherEquipped)
						pcall(function() PetsService:FireServer("UnequipPet", toRemove) end)
						localEq[toRemove] = nil; localEqCount = localEqCount - 1
						task.wait(0.25)
					end
					pcall(function() PetsService:FireServer("EquipPet", target.uuid, CFrame.new(pos)) end)
					localEq[target.uuid] = true; localEqCount = localEqCount + 1
					table.insert(currentGrowing, target.uuid)
					ctx.state.elephantStartTime = ctx.state.elephantStartTime or {}
					ctx.state.elephantStartTime[target.uuid] = os.time()
					task.wait(0.3)
				end
			end
		end

		ctx.state.elephantStatus = string.format("Elephant: %d/%d aktif", #currentGrowing, maxPets)
	end

	local function elephantLoop()
		ctx.state.elephantId = (ctx.state.elephantId or 0) + 1
		local myId = ctx.state.elephantId
		ctx.elevate()
		ctx.state.elephantFirstRun = true

		-- Webhook saat enable (sama seperti leveling: cukup URL keisi, sender cek URL sendiri)
		task.spawn(function()
			if ctx.webhookElephant then
				pcall(function() ctx.webhookElephant.sendEnabled(ctx) end)
			end
		end)

		while CFG.elephantEnabled and ctx.alive() and ctx.state.elephantId == myId do
			pcall(checkElephant)
			task.wait(3.0)
		end
		ctx.state.elephantStatus = "Idle"
	end

	function ctx.startElephant()
		if ctx.cancelClearGarden then ctx.cancelClearGarden() end -- batalkan clear tertunda dari fitur lain
		ctx.state.elephantCfgOverride = nil -- webhook elephant pakai config standalone (bukan Growth)
		ctx.state.elephantWebhookPost = nil -- standalone: edit pesan (bukan POST tiap selesai)
		task.spawn(elephantLoop)
	end

	-- Matikan: hentikan loop lalu CABUT SEMUA pet dari garden sampai kosong total.
	function ctx.stopElephant()
		ctx.state.elephantId = (ctx.state.elephantId or 0) + 1 -- invalidate loop yang jalan
		task.spawn(function()
			ctx.state.elephantStatus = "Clearing garden..."
			task.wait(0.3)
			for _ = 1, 30 do
				local ok, d = pcall(function() return DataService:GetData() end)
				local eq = ok and d and d.PetsData and d.PetsData.EquippedPets or {}
				if #eq == 0 then break end
				for _, uuid in ipairs(eq) do
					pcall(function() PetsService:FireServer("UnequipPet", uuid) end)
					task.wait(0.2)
				end
				task.wait(0.4)
			end
			ctx.state.elephantStatus = "Idle (garden kosong)"
		end)
	end
end
]=],
	["modules/elephant/automation_elephant_v2.lua"] = [=[
--[[ elephant_v2.lua — Automation Elephant V2.
     Sama seperti V1 (equip team + rotasi pet target by BaseWeight, lepas pas
     capai Target Weight, jaga Max Target Pets aktif), TAPI plus swap GAJAH:
     gajah normalnya di luar garden; begitu ada target >= Trigger Level (mis. 40)
     gajah di-swap MASUK nuker 1 pet Switch (tanpa delay), keluar lagi pas ga ada
     target di level itu. Leveling target dilakukan PNP (jalan barengan).

     2 loop terpisah:
       - rotationLoop: pelan (~1.5s) — jaga team + rotasi target (ala V1).
       - swapLoop: cepat (0.1s) — cuma swap gajah <-> switch. ]]
return function(ctx)
	local DataService = ctx.deps.DataService
	local PetsService = ctx.deps.PetsService
	local CFG = ctx.CFG
	local LP  = ctx.LP
	local RS  = game:GetService("ReplicatedStorage")

	local function farmCenter()
		local ok, GetFarm = pcall(function() return require(RS.Modules.GetFarm) end)
		local farm = ok and GetFarm and GetFarm(LP)
		local pa = farm and farm:FindFirstChild("PetArea")
		if pa then return pa.Position end
		local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
		return hrp and hrp.Position or nil
	end
	local slotOf, nextSlot = {}, 0
	local function getPos(uuid)
		if not slotOf[uuid] then slotOf[uuid] = nextSlot; nextSlot = nextSlot + 1 end
		local c = farmCenter(); if not c then return nil end
		local i = slotOf[uuid]
		return c + Vector3.new(((i % 6) - 2.5) * 3, 0, (math.floor(i / 6) - 1) * 3)
	end

	local function snapshot()
		local ok, d = pcall(function() return DataService:GetData() end)
		if not ok or not d or not d.PetsData then return nil, nil end
		return d.PetsData.EquippedPets or {}, (d.PetsData.PetInventory and d.PetsData.PetInventory.Data) or {}
	end
	local function isEquipped(eq, uuid)
		if not uuid or uuid == "" or not eq then return false end
		for _, u in ipairs(eq) do if u == uuid then return true end end
		return false
	end

	----------------------------------------------------- STATUS
	function ctx.getElephantV2Summary()
		local _, inv = snapshot()
		inv = inv or {}
		local teamCount = 0
		for _ in pairs(CFG.elephantV2Team or {}) do teamCount = teamCount + 1 end
		local typesList = {}
		for k in pairs(CFG.elephantV2Types or {}) do table.insert(typesList, k) end
		table.sort(typesList)
		local targetW = CFG.elephantV2Weight or 5.5
		local readyCount, maxKgCount = 0, 0
		for _, v in pairs(inv) do
			if CFG.elephantV2Types[v.PetType] then
				local pd = v.PetData or {}
				if not pd.IsFavorite then
					if (pd.BaseWeight or 0) < targetW then readyCount = readyCount + 1 else maxKgCount = maxKgCount + 1 end
				end
			end
		end
		return {
			status = CFG.elephantV2Enabled and "ACTIVE" or "STOPPED",
			info   = ctx.state.elephantV2Status or "Idle",
			team   = string.format("%d pets", teamCount),
			types  = #typesList > 0 and table.concat(typesList, ", ") or "None",
			ready  = string.format("%d pets", readyCount),
			maxKg  = string.format("%d pets", maxKgCount),
			maxTarget = string.format("%d pets", CFG.elephantV2MaxPets or 3),
			targetWeight = string.format("%.1f KG", targetW),
			gajah  = ctx.elephantV2Label(CFG.elephantV2Gajah),
			switch = ctx.elephantV2Label(CFG.elephantV2Switch),
			level  = tostring(CFG.elephantV2Level or 40),
		}
	end

	----------------------------------------------------- ROTASI (ala V1)
	-- absentSince[uuid] = os.clock() sejak pet TERAKHIR kali kebaca ga ke-equip. Dipakai di
	-- reserved mode: elephant cuma re-equip pet yg absent >= 5 detik (biar ga ngerebut PnP yg
	-- cuma unequip sebentar pas pickup). Reset ke nil begitu pet kebaca ke-equip lagi.
	local absentSince = {}
	local ABSENT_GRACE = 5 -- detik
	local function absentLongEnough(uuid)
		absentSince[uuid] = absentSince[uuid] or os.clock()
		return (os.clock() - absentSince[uuid]) >= ABSENT_GRACE
	end
	local function checkRotation()
		local eq, inv = snapshot()
		if not eq then return end
		local teamSet = CFG.elephantV2Team or {}
		local targetTypes = CFG.elephantV2Types or {}
		local targetW = CFG.elephantV2Weight or 5.5
		local maxPets = CFG.elephantV2MaxPets or 3
		local gajah, switch = CFG.elephantV2Gajah, CFG.elephantV2Switch
		local gajahIn = isEquipped(eq, gajah)

		-- A. FIRST RUN (pas enable): reset garden dulu — TAPI di mode reserved (switch kosong)
		--    reset-all DILEWATI biar pet PnP yg lagi jalan ga ke-wipe. Langsung lanjut naruh team.
		local reserved = (switch == nil or switch == "")
		if ctx.state.elephantV2FirstRun then
			ctx.state.elephantV2FirstRun = false
			if not reserved and #eq > 0 then
				ctx.state.elephantV2Status = "Reset garden (cabut semua pet)..."
				for _, uuid in ipairs(eq) do
					pcall(function() PetsService:FireServer("UnequipPet", uuid) end)
					task.wait(0.2)
				end
				return
			end
			-- reserved: jangan reset, lanjut ke penempatan team di bawah
		end

		local localEq, localEqCount = {}, 0
		for _, uuid in ipairs(eq) do localEq[uuid] = true; localEqCount = localEqCount + 1 end
		-- pet yg lagi ke-equip -> reset timer absent-nya (dia lagi ada)
		for uuid in pairs(localEq) do absentSince[uuid] = nil end

		-- B. PERSISTENSI TEAM: pasang lagi team yg kecabut (skip gajah; skip switch pas gajah in).
		--    RESERVED mode: cuma re-equip kalau udah absent >= 5s -> ga ngerebut PnP yg unequip
		--    sebentar pas pickup (PnP bakal balikin sendiri jauh sebelum 5s).
		for uuid in pairs(teamSet) do
			if uuid ~= gajah and not (gajahIn and uuid == switch) then
				if not localEq[uuid] then
					if (not reserved) or absentLongEnough(uuid) then
						local pos = getPos(uuid)
						if pos then
							pcall(function() PetsService:FireServer("EquipPet", uuid, CFrame.new(pos)) end)
							localEq[uuid] = true; localEqCount = localEqCount + 1
							absentSince[uuid] = nil
							task.wait(0.25)
						end
					end
				end
			end
		end

		-- C. KLASIFIKASI target equipped by BaseWeight (jangan sentuh team & gajah)
		local currentGrowing, finishedMax = {}, {}
		for uuid in pairs(localEq) do
			if not teamSet[uuid] and uuid ~= gajah then
				local pInfo = inv[uuid]
				local pd = pInfo and pInfo.PetData or {}
				local pt = pInfo and pInfo.PetType
				if pt and targetTypes[pt] then
					if (pd.BaseWeight or 0) < targetW then table.insert(currentGrowing, uuid)
					else table.insert(finishedMax, uuid) end
				end
			end
		end

		-- D. LEPAS target yang sudah MAX KG
		for _, uuid in ipairs(finishedMax) do
			pcall(function() PetsService:FireServer("UnequipPet", uuid) end)
			localEq[uuid] = nil; localEqCount = localEqCount - 1
			task.wait(0.2)
		end

		-- E. TAMBAH target baru (BaseWeight terendah dulu) sampai maxPets
		local needed = maxPets - #currentGrowing
		if needed > 0 then
			local pool = {}
			for uuid, v in pairs(inv) do
				local pd = v.PetData or {}
				if not localEq[uuid] and targetTypes[v.PetType] and (pd.BaseWeight or 0) < targetW and not pd.IsFavorite then
					table.insert(pool, { uuid = uuid, weight = pd.BaseWeight or 0 })
				end
			end
			table.sort(pool, function(a, b) return a.weight < b.weight end)
			for i = 1, math.min(needed, #pool) do
				local uuid = pool[i].uuid
				-- RESERVED: skip pet yg baru aja absent (<5s) -> kemungkinan cuma lagi di-PnP
				-- (unequip sebentar). Cuma tambahin yg beneran nganggur/absent lama.
				if (not reserved) or absentLongEnough(uuid) then
					local pos = getPos(uuid)
					if pos then
						pcall(function() PetsService:FireServer("EquipPet", uuid, CFrame.new(pos)) end)
						localEq[uuid] = true; localEqCount = localEqCount + 1
						absentSince[uuid] = nil
						table.insert(currentGrowing, uuid)
						task.wait(0.3)
					end
				end
			end
		end
	end

	----------------------------------------------------- SWAP GAJAH (cepat)
	-- Cuma trigger kalau ada target yang LAGI KE-EQUIP, masih growing (weight < target),
	-- dan level >= ambang. Pet maxed / yang cuma nganggur di inventory TIDAK dihitung.
	local function anyTargetReady(eq, inv)
		local types = CFG.elephantV2Types or {}
		local thr = CFG.elephantV2Level or 40
		local targetW = CFG.elephantV2Weight or 5.5
		for _, u in ipairs(eq) do
			local v = inv[u]
			if v and types[v.PetType] then
				local pd = v.PetData or {}
				if (pd.BaseWeight or 0) < targetW and (pd.Level or 0) >= thr then return true end
			end
		end
		return false
	end
	local function eqCount(eq) return eq and #eq or 0 end

	-- Masukin GAJAH dengan AMAN: gajah HANYA boleh nuker SWITCH, atau pakai slot yang
	-- beneran kosong. Kalau Switch lagi ga ke-equip DAN garden penuh -> SKIP (biar
	-- ga bump pet lain sembarangan). Ini kunci: slot bebas WAJIB dari switch dulu.
	local function swapInGajah(gajah, switch)
		local eq = snapshot()
		if isEquipped(eq, gajah) then return true end
		local pos = farmCenter()
		if isEquipped(eq, switch) then
			-- cabut switch, TUNGGU beneran kecabut (slot bebas), baru masukin gajah
			pcall(function() PetsService:FireServer("UnequipPet", switch) end)
			for _ = 1, 8 do
				task.wait(0.04)
				eq = snapshot()
				if not isEquipped(eq, switch) then break end
			end
			if isEquipped(eq, switch) then return false end -- gagal cabut switch, jangan equip
		elseif eqCount(eq) >= 8 then
			return false -- switch ga ada & garden penuh -> jangan bump pet lain
		end
		-- slot dijamin ada (dari switch / emang kosong)
		if pos then pcall(function() PetsService:FireServer("EquipPet", gajah, CFrame.new(pos)) end) end
		for _ = 1, 3 do task.wait(0.06); if isEquipped(snapshot(), gajah) then return true end end
		return false
	end

	-- Keluarin GAJAH: cabut gajah, balikin SWITCH ke slot yang bebas.
	local function swapOutGajah(gajah, switch)
		local eq = snapshot()
		if not isEquipped(eq, gajah) then return true end
		local pos = farmCenter()
		pcall(function() PetsService:FireServer("UnequipPet", gajah) end)
		for _ = 1, 8 do
			task.wait(0.04)
			eq = snapshot()
			if not isEquipped(eq, gajah) then break end
		end
		-- reserved mode (switch kosong): slot dibiarin kosong, JANGAN equip apa2 (biar PnP aman)
		if switch and switch ~= "" and pos then pcall(function() PetsService:FireServer("EquipPet", switch, CFrame.new(pos)) end) end
		return true
	end

	-- Cari 1 pet target yang lagi ke-equip, tipe cocok, weight < target, level >= ambang.
	-- Return uuid + BaseWeight-nya. Dipakai buat mode reserved (boost by 0.1kg).
	local function getReadyTarget(eq, inv)
		local types = CFG.elephantV2Types or {}
		local thr = CFG.elephantV2Level or 40
		local targetW = CFG.elephantV2Weight or 5.5
		for _, u in ipairs(eq) do
			local v = inv[u]
			if v and types[v.PetType] then
				local pd = v.PetData or {}
				if (pd.BaseWeight or 0) < targetW and (pd.Level or 0) >= thr then return u, (pd.BaseWeight or 0) end
			end
		end
		return nil
	end
	local function baseWOf(inv, uuid)
		local v = inv and inv[uuid]; local pd = v and v.PetData
		return pd and (pd.BaseWeight or 0) or nil
	end

	local function rotationLoop(myId)
		while CFG.elephantV2Enabled and ctx.alive() and ctx.state.elephantV2Id == myId do
			-- Rotasi TETAP jalan (naruh team + rotasi target). Yang dimatiin cuma reset-all pas
			-- reserved (di checkRotation) biar pet PnP ga ke-wipe.
			pcall(checkRotation)
			task.wait(1.5)
		end
	end

	local function swapLoop(myId)
		while CFG.elephantV2Enabled and ctx.alive() and ctx.state.elephantV2Id == myId do
			local gajah, switch = CFG.elephantV2Gajah, CFG.elephantV2Switch
			local reserved = (switch == nil or switch == "")
			if gajah == "" or gajah == nil then
				ctx.state.elephantV2Status = "Pilih Gajah dulu"
				task.wait(1)
			else
				local eq, inv = snapshot()
				if eq then
					local gajahIn = isEquipped(eq, gajah)
					if reserved then
						-- ===== MODE RESERVED: gajah masuk pas ada target lvl 40, keluar pas target +0.1kg =====
						local tUuid = getReadyTarget(eq, inv)
						if not tUuid then
							if gajahIn then
								swapOutGajah(gajah, switch)
								ctx.state.elephantV2TargetUuid = nil
								ctx.state.elephantV2Status = "Standby (ga ada target lvl " .. tostring(CFG.elephantV2Level or 40) .. ")"
							else
								ctx.state.elephantV2Status = "Standby (nunggu target lvl " .. tostring(CFG.elephantV2Level or 40) .. ")"
							end
						else
							if not gajahIn then
								-- masuk pakai slot kosong yang kamu reserve; catat berat target saat masuk
								if swapInGajah(gajah, switch) then
									ctx.state.elephantV2TargetUuid = tUuid
									ctx.state.elephantV2TargetW0 = baseWOf(inv, tUuid)
									ctx.state.elephantV2Status = "Gajah MASUK (boost target)"
								end
							else
								-- gajah in: cek target yg ditrack udah naik 0.1kg? kalau ya -> keluar
								local trackU = ctx.state.elephantV2TargetUuid
								local w0 = ctx.state.elephantV2TargetW0
								local wc = trackU and baseWOf(inv, trackU) or nil
								if (not trackU) or (not wc) or (w0 and wc >= w0 + 0.1) then
									swapOutGajah(gajah, switch)
									ctx.state.elephantV2TargetUuid = nil
									ctx.state.elephantV2Status = "Gajah keluar (target +0.1kg)"
								else
									ctx.state.elephantV2Status = ("Boost... (+%.2f/0.10 kg)"):format(math.max(0, wc - (w0 or wc)))
								end
							end
						end
					else
						-- ===== MODE NORMAL (pakai switch): perilaku lama =====
						local ready = anyTargetReady(eq, inv)
						if ready and not gajahIn then
							swapInGajah(gajah, switch)
							ctx.state.elephantV2Status = "Gajah MASUK (target lvl " .. tostring(CFG.elephantV2Level or 40) .. ")"
						elseif not ready and gajahIn then
							swapOutGajah(gajah, switch)
							ctx.state.elephantV2Status = "Standby (gajah keluar)"
						else
							ctx.state.elephantV2Status = gajahIn and "Gajah aktif" or "Standby"
						end
					end
				end
				task.wait(CFG.elephantV2Interval or 0.1)
			end
		end
	end

	function ctx.startElephantV2()
		ctx.state.elephantV2Id = (ctx.state.elephantV2Id or 0) + 1
		local myId = ctx.state.elephantV2Id
		ctx.state.elephantV2FirstRun = true -- pas enable: reset garden dulu (cabut semua)
		ctx.elevate()
		task.spawn(function() rotationLoop(myId) end)
		task.spawn(function() swapLoop(myId) end)
	end
	function ctx.stopElephantV2()
		ctx.state.elephantV2Id = (ctx.state.elephantV2Id or 0) + 1
		ctx.state.elephantV2FirstRun = false
		ctx.state.elephantV2TargetUuid = nil
		local switch = CFG.elephantV2Switch
		local reserved = (switch == nil or switch == "")
		if reserved then
			-- MODE RESERVED: CUMA cabut gajah, JANGAN sentuh pet lain (PnP tetep aman jalan)
			ctx.state.elephantV2Status = "Cabut gajah..."
			task.spawn(function()
				local gajah = CFG.elephantV2Gajah
				for _ = 1, 5 do
					local eq = snapshot()
					if not eq or not isEquipped(eq, gajah) then break end
					pcall(function() PetsService:FireServer("UnequipPet", gajah) end)
					task.wait(0.12)
				end
				ctx.state.elephantV2Status = "Idle (gajah keluar, PnP jalan terus)"
			end)
			return
		end
		ctx.state.elephantV2Status = "Cabut semua pet (bersihin garden)..."
		-- Cabut SEMUA pet aktif di garden sampai bener2 bersih (multi-pass, kebal delay replikasi)
		task.spawn(function()
			for _ = 1, 5 do
				local eq = snapshot()
				if not eq or #eq == 0 then break end
				for _, uuid in ipairs(eq) do
					pcall(function() PetsService:FireServer("UnequipPet", uuid) end)
					task.wait(0.12)
				end
				task.wait(0.2)
			end
			ctx.state.elephantV2Status = "Idle (garden bersih)"
		end)
	end

	----------------------------------------------------- UI helpers
	local function petLabel(uuid)
		if not uuid or uuid == "" then return "Select" end
		local _, inv = snapshot()
		local v = inv and inv[uuid]
		if not v then return "#" .. tostring(uuid):sub(2, 5) end
		local pd = v.PetData or {}
		local mut = pd.MutationType
		local mutName = (mut and ctx.reg and ctx.reg.mutDisplay) and ctx.reg.mutDisplay(mut) or mut
		local pre = (mut and mut ~= "" and mut ~= "Normal") and (tostring(mutName) .. " ") or ""
		return ("%s%s | Age %s | #%s"):format(pre, v.PetType or "?", tostring(pd.Level or 0), tostring(uuid):sub(2, 5))
	end
	ctx.elephantV2Label = petLabel

	function ctx.elephantV2GajahOptions()
		local out = { { name = "", display = "\u{274C} Kosongkan" } }
		for _, o in ipairs(ctx.inventoryPetOptions and ctx.inventoryPetOptions() or {}) do
			out[#out + 1] = { name = o.value, display = o.display }
		end
		return out
	end
	function ctx.elephantV2SwitchOptions()
		-- Opsi Kosongkan di paling atas (buat mode reserved: slot dibiarin kosong).
		-- Tampilin SEMUA pet inventory (bukan cuma team) biar pilihan selalu keliatan.
		local out = { { name = "", display = "\u{274C} Kosongkan (reserved slot)" } }
		for _, o in ipairs(ctx.inventoryPetOptions and ctx.inventoryPetOptions() or {}) do
			out[#out + 1] = { name = o.value, display = o.display }
		end
		return out
	end
end
]=],
	["modules/elephant/webhook.lua"] = [=[
--[[ webhook/elephant.lua — Discord webhook untuk Automation Elephant.
     Konsep:
       - sendEnabled: kirim 1 pesan (Boosting Statistics KOSONG), tangkap message id.
       - onFinished:  tiap pet target selesai (>= max KG), tambah ke tally lalu
                      EDIT pesan yang sama (boosting stats keisi bertahap).
     Pakai executor request() langsung (POST ?wait=true buat dapat id, PATCH buat edit). ]]
local HttpService = game:GetService("HttpService")
local elephantWebhook = {}

local USERNAME = "CeszParadise"
local AVATAR = "https://raw.githubusercontent.com/milmscr/iniapa/main/cobainaja/Logo/logo_icon.png"

local function bracketLabel(w)
	local lo = math.floor(w * 10) / 10
	return string.format("%.2f-%.2f KG", lo + 0.01, lo + 0.09)
end

-- Format durasi detik -> "Xh Ym Zs" / "Xm Ys" / "Ys". nil/false -> "-" (start ga kecatat).
local function fmtDuration(sec)
	if sec == nil then return "-" end
	sec = math.max(0, math.floor(tonumber(sec) or 0))
	if sec >= 3600 then return string.format("%dh %dm %ds", math.floor(sec / 3600), math.floor((sec % 3600) / 60), sec % 60) end
	if sec >= 60 then return string.format("%dm %ds", math.floor(sec / 60), sec % 60) end
	return string.format("%ds", sec)
end

local function reqFn()
	return (syn and syn.request) or (http and http.request) or http_request or request
end

-- Sumber config: override Growth (ctx.state.elephantCfgOverride) kalau ada, else CFG standalone.
local function ecfg(ctx)
	local o = ctx.state and ctx.state.elephantCfgOverride
	if o then return o.team or {}, o.types or {}, o.weight or 5.5 end
	local CFG = ctx.CFG
	return CFG.elephantTeamUuids or {}, CFG.elephantPetTypes or {}, CFG.elephantTargetWeight or 5.5
end

-- Scan inventory live: pisah pet target jadi 'selesai' (>= target KG) dan 'sisa' (< target KG).
-- Yang selesai dikelompokkan per type + bracket berat (byType), plus total maxCount.
-- Sumber angka Boosting Statistics & Pets at Max KG = SEMUA pet target yang sudah max di data,
-- bukan cuma yang selesai selama sesi ini (tahan reload / re-enable).
local function scanTargets(ctx)
	local ok, d = pcall(function() return ctx.deps.DataService:GetData() end)
	local inv = ok and d and d.PetsData and d.PetsData.PetInventory and d.PetsData.PetInventory.Data or {}
	local _, tt, tw = ecfg(ctx)
	local byType, maxCount, remains = {}, 0, 0
	for _, v in pairs(inv) do
		if v.PetType and tt[v.PetType] and not (v.PetData or {}).IsFavorite then
			local w = (v.PetData or {}).BaseWeight or 0
			if w < tw then
				remains = remains + 1
			else
				maxCount = maxCount + 1
				local bt = byType[v.PetType]
				if not bt then bt = { total = 0, brackets = {}, order = {} }; byType[v.PetType] = bt end
				bt.total = bt.total + 1
				local lbl = bracketLabel(w)
				if not bt.brackets[lbl] then bt.brackets[lbl] = 0; bt.order[#bt.order + 1] = lbl end
				bt.brackets[lbl] = bt.brackets[lbl] + 1
			end
		end
	end
	return byType, maxCount, remains
end

local function buildPayload(ctx)
	local base = ctx.state.elephantBase or {}
	local byType, maxCount, remains = scanTargets(ctx)

	local typeKeys = {}
	for t in pairs(byType) do typeKeys[#typeKeys + 1] = t end
	table.sort(typeKeys)
	local lines = {}
	for _, t in ipairs(typeKeys) do
		local bt = byType[t]
		lines[#lines + 1] = string.format("**%s:** %d", t, bt.total)
		table.sort(bt.order)
		for _, lbl in ipairs(bt.order) do
			lines[#lines + 1] = string.format("\226\128\162 %s (%s): %d", t, lbl, bt.brackets[lbl])
		end
	end
	local boostText = #lines > 0 and table.concat(lines, "\n") or "*Belum ada pet selesai*"

	local desc = string.format(
		"**Profile :**\n> \240\159\145\164 Username : ||%s||\n\n" ..
		"**Teams :**\n> Elephant Team: `%s`\n\n" ..
		"**Target Types :**\n> `%s`\n\n" ..
		"**Boosting Statistics :**\n%s\n\n" ..
		"**Pets at Max KG :** `%d`\n" ..
		"**Remains Queue :** `%d`",
		ctx.LP.Name, base.teamText or "None", base.typesText or "None",
		boostText, maxCount, remains)
	if #desc > 4000 then desc = desc:sub(1, 3980) .. "\n... (truncated)" end

	return {
		username = USERNAME,
		avatar_url = AVATAR,
		embeds = {
			{
				title = "\240\159\147\138 Growth \226\128\162 Elephant Statistics",
				color = 3066993,
				description = desc,
				footer = { text = os.date("%B %d | %I:%M %p"), icon_url = "https://raw.githubusercontent.com/milmscr/iniapa/main/cobainaja/Logo/logo_icon.png" },
			}
		}
	}
end

-- Kirim saat enable: reset tally, kirim pesan (boosting kosong), simpan message id.
function elephantWebhook.sendEnabled(ctx)
	local CFG = ctx.CFG
	if not CFG.webhookUrl or CFG.webhookUrl == "" then return end

	-- base info (team + target types)
	local ok, d = pcall(function() return ctx.deps.DataService:GetData() end)
	local inv = ok and d and d.PetsData and d.PetsData.PetInventory and d.PetsData.PetInventory.Data or {}
	local teamSet, typesSet = ecfg(ctx)
	local teamCount, teamOrder = {}, {}
	for uuid in pairs(teamSet) do
		local v = inv[uuid]
		if v then
			local pt = v.PetType or "?"
			local mut = v.PetData and v.PetData.MutationType
			local mutName = (mut and ctx.reg and ctx.reg.mutDisplay) and ctx.reg.mutDisplay(mut) or mut
			local disp = (mut and mut ~= "" and mut ~= "Normal") and (tostring(mutName) .. " " .. pt) or pt
			if not teamCount[disp] then teamCount[disp] = 0; teamOrder[#teamOrder + 1] = disp end
			teamCount[disp] = teamCount[disp] + 1
		end
	end
	table.sort(teamOrder)
	local teamParts = {}
	for _, disp in ipairs(teamOrder) do teamParts[#teamParts + 1] = teamCount[disp] .. " " .. disp end

	local typesList = {}
	for t in pairs(typesSet) do typesList[#typesList + 1] = t end
	table.sort(typesList)

	ctx.state.elephantBase = {
		teamText = #teamParts > 0 and table.concat(teamParts, ", ") or "None",
		typesText = #typesList > 0 and table.concat(typesList, ", ") or "None",
	}
	ctx.state.elephantTally = { byType = {}, maxCount = 0 }
	ctx.state.elephantMsgId = nil

	-- POST ?wait=true buat dapat message id
	local f = reqFn()
	if not f then return end
	local url = CFG.webhookUrl
	local sep = url:find("?", 1, true) and "&" or "?"
	local body = HttpService:JSONEncode(buildPayload(ctx))
	local okReq, res = pcall(function()
		return f({
			Url = url .. sep .. "wait=true", Method = "POST",
			Headers = { ["Content-Type"] = "application/json" }, Body = body,
		})
	end)
	if okReq and res and res.Body then
		local okj, data = pcall(function() return HttpService:JSONDecode(res.Body) end)
		if okj and type(data) == "table" and data.id then
			ctx.state.elephantMsgId = tostring(data.id)
		end
	end
end

-- Tiap pet target selesai (>= max KG): kirim/EDIT pesan. Angka dihitung live dari
-- data di buildPayload (scanTargets), jadi tidak perlu tally manual lagi.
function elephantWebhook.onFinished(ctx, petType, weight)
	local CFG = ctx.CFG
	if not CFG.webhookUrl or CFG.webhookUrl == "" then return end

	-- Mode POST (Growth: kirim pesan baru tiap pet selesai) ATAU edit pesan (standalone).
	local f = reqFn()
	if not f then return end
	local body = HttpService:JSONEncode(buildPayload(ctx))
	local postMode = ctx.state and ctx.state.elephantWebhookPost
	-- Request HTTP di thread terpisah (non-blocking) biar ga nge-freeze loop automation
	task.spawn(function()
		if ctx.state.elephantMsgId and not postMode then
			pcall(function()
				f({
					Url = CFG.webhookUrl .. "/messages/" .. ctx.state.elephantMsgId, Method = "PATCH",
					Headers = { ["Content-Type"] = "application/json" }, Body = body,
				})
			end)
		elseif ctx.sendWebhook then
			pcall(function() ctx.sendWebhook(CFG.webhookUrl, HttpService:JSONDecode(body), ctx) end)
		end
	end)
end

-- Kartu PER-PET saat 1 pet capai Max KG. Dikirim TIAP pet beres (pesan baru),
-- pelengkap statistik agregat. durationSec = nil -> "Duration: -" (start ga kecatat).
function elephantWebhook.sendFinished(ctx, petType, weight, mutation, age, durationSec)
	local CFG = ctx.CFG
	if not CFG.webhookUrl or CFG.webhookUrl == "" then return end
	local mutDisplay = (ctx.reg and ctx.reg.mutDisplay and ctx.reg.mutDisplay(mutation)) or mutation or "None"
	local _, _, remains = scanTargets(ctx)

	local payload = {
		username = USERNAME,
		avatar_url = AVATAR,
		embeds = {
			{
				title = "\240\159\144\152 Growth \226\128\162 Elephant", -- 🐘
				color = 3066993, -- Green
				fields = {
					{
						name = "Profile :",
						value = string.format("> Username : ||%s||", ctx.LP.Name),
						inline = false
					},
					{
						name = "Max KG Reached",
						value = string.format(
							"> Pet Type: `%s`\n" ..
							"> Mutation: `%s`\n" ..
							"> Weight: `%.2f KG`\n" ..
							"> Age: `%s`\n" ..
							"> Duration: `%s`\n" ..
							"> Remains Queue: `%s`",
							tostring(petType or "?"),
							tostring(mutDisplay),
							tonumber(weight) or 0,
							tostring(age or "-"),
							fmtDuration(durationSec),
							tostring(remains)
						),
						inline = false
					}
				},
				footer = {
					text = os.date("%B %d | %I:%M %p"),
					icon_url = "https://raw.githubusercontent.com/milmscr/iniapa/main/cobainaja/Logo/logo_icon.png"
				}
			}
		}
	}
	if ctx.sendWebhook then ctx.sendWebhook(CFG.webhookUrl, payload, ctx) end
end

return elephantWebhook
]=],
	["modules/event/automation_beanstalk_hop.lua"] = [=[
--[[ automation_beanstalk_hop.lua — Auto Server Hop (Beanstalk).
     Tujuan: nyari server yg beanstalk growth-nya BELUM 900 biar bisa terus kontribusi & dapat reward.
     BATASAN: growth = state runtime server, API daftar server Roblox cuma kasih player count,
     JADI ga bisa tau growth sebelum join. Cara kerja: JOIN -> cek growth -> kalau >=900 (penuh/CD)
     hop ke server lain; kalau < 900 STAY & farm (biar toggle plant/collect/submit/claim yg kerja).
     Begitu growth server ini nyampe 900, hop lagi. Tanpa batas hop (sampai nemu yg < 900).

     Teknis: http request (server list) + TeleportToPlaceInstance(jobId) + queueonteleport (re-run hub).
     Config: CFG.beanstalkHopEnabled. Fungsi: ctx.startBeanstalkHop / ctx.stopBeanstalkHop.
]]
return function(ctx)
	local LP  = ctx.LP
	local CFG = ctx.CFG
	local TeleportService = game:GetService("TeleportService")
	local HttpService     = game:GetService("HttpService")
	local function setStatus(s) ctx.setStatus(s) end
	local branch = (getgenv and getgenv().GAG_BRANCH) or _G.GAG_BRANCH or "main"

	-- ref Teleport di-cache biar bypass hook __namecall anti-teleport
	local TeleportFn = TeleportService.Teleport

	-- queue loader hub biar auto jalan lagi abis pindah server (branch dijaga)
	local function queueLoader()
		local q = (syn and syn.queue_on_teleport) or queue_on_teleport
			or (fluxus and fluxus.queue_on_teleport) or (getgenv and getgenv().queue_on_teleport)
		if q then
			local cmd = ('if getgenv then getgenv().GAG_BRANCH=%q end loadstring(game:HttpGet("https://raw.githubusercontent.com/Tirta71/ScriptMarketGAG/%s/GAGSeller/init.lua"))()'):format(branch, branch)
			pcall(function() q(cmd) end)
		end
	end

	local function httpReq()
		return http_request or request or (syn and syn.request) or (http and http.request)
	end

	-- daftar jobId server publik yg masih ada room, exclude server sekarang (max 3 halaman)
	local function fetchServers()
		local req = httpReq(); if not req then return {} end
		local out, cursor = {}, ""
		for _ = 1, 3 do
			local url = ("https://games.roblox.com/v1/games/%d/servers/Public?limit=100&sortOrder=Desc"):format(game.PlaceId)
			if cursor ~= "" then url = url .. "&cursor=" .. cursor end
			local ok, resp = pcall(function() return req({ Url = url, Method = "GET" }) end)
			if not ok or type(resp) ~= "table" or resp.StatusCode ~= 200 then break end
			local ok2, data = pcall(function() return HttpService:JSONDecode(resp.Body) end)
			if not ok2 or type(data) ~= "table" then break end
			for _, s in ipairs(data.data or {}) do
				if s.id ~= game.JobId and (tonumber(s.playing) or 0) < (tonumber(s.maxPlayers) or 0) then
					out[#out + 1] = s.id
				end
			end
			cursor = data.nextPageCursor
			if not cursor or cursor == "" then break end
		end
		return out
	end

	-- pindah ke server lain (acak dari daftar). Fallback: Teleport random kalau daftar kosong/gagal.
	-- Cek CFG.beanstalkHopEnabled di tiap tahap: kalau user matiin di tengah proses (mis. pas
	-- ambil daftar server), langsung batal SEBELUM teleport -> matiin selalu aman & instan.
	local function hop()
		if not CFG.beanstalkHopEnabled then return false end
		queueLoader()
		task.wait(0.4)
		if not CFG.beanstalkHopEnabled then return false end
		local servers = fetchServers()
		if not CFG.beanstalkHopEnabled then return false end
		-- shuffle
		for i = #servers, 2, -1 do local j = math.random(1, i); servers[i], servers[j] = servers[j], servers[i] end
		for _, jobId in ipairs(servers) do
			if not CFG.beanstalkHopEnabled then return false end
			local ok = pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, jobId, LP) end)
			if ok then return true end
			task.wait(0.3)
		end
		if not CFG.beanstalkHopEnabled then return false end
		-- fallback: server random (bisa kebetulan sama, tapi lebih baik drpd stuck)
		pcall(function() TeleportFn(TeleportService, game.PlaceId, LP) end)
		return true
	end

	-- growth beanstalk sekarang dari billboard: return cur, max (nil kalau ga kebaca)
	local function growth()
		local inter = workspace:FindFirstChild("Interaction")
		local m = inter and inter:FindFirstChild("BeanstalkEventModel")
		if not m then return nil end
		for _, g in ipairs(m:GetDescendants()) do
			if g:IsA("TextLabel") then
				local a, b = g.Text:match("^(%d+)%s*/%s*(%d+)$")
				if a and b then return tonumber(a), tonumber(b) end
			end
		end
		return nil
	end

	local function hopLoop()
		ctx.state.beanHopId = (ctx.state.beanHopId or 0) + 1
		local myId = ctx.state.beanHopId
		ctx.elevate()
		local t0 = os.clock() -- buat timeout nunggu event kebaca
		while CFG.beanstalkHopEnabled and ctx.alive() and ctx.state.beanHopId == myId do
			local cur, max = growth()
			if not cur then
				-- event belum kebaca; kasih grace 40s (nunggu map load) sebelum nyerah & hop
				if os.clock() - t0 > 40 then
					setStatus("Beanstalk Hop: event ga kebaca — cari server lain...")
					hop(); return
				end
				setStatus("Beanstalk Hop: nunggu beanstalk kebaca...")
				task.wait(2)
			elseif cur >= max then
				setStatus(("Beanstalk Hop: server penuh (%d/%d) — cari server baru..."):format(cur, max))
				hop(); return -- instance ini ilang setelah teleport
			else
				-- server bagus: stay, biar automation lain yg farming. Cek berkala sampai 900.
				setStatus(("Beanstalk Hop: server OK (%d/%d) — farming"):format(cur, max))
				t0 = os.clock()
				task.wait(15)
			end
		end
	end

	function ctx.startBeanstalkHop()
		if not CFG.beanstalkHopEnabled then return end
		task.spawn(hopLoop)
	end
	function ctx.stopBeanstalkHop() ctx.state.beanHopId = (ctx.state.beanHopId or 0) + 1 end
end
]=],
	["modules/event/automation_beanstalk.lua"] = [=[
--[[ automation_beanstalk.lua — Automation Beanstalk Event (NPC Jack).
     Beanstalk minta 1 TRAIT tanaman (mis. "Vegetable"), refresh tiap jam. Feed plant
     yang trait-nya cocok -> naikin Beanstalk Growth global (mis. 0/900) & dapat reward.
     Craving DIBACA dari billboard "We need <trait> Plants" (selalu akurat, ga nebak RNG).

     Flow (tiap sub-toggle bisa nyala sendiri, jalan 1 loop):
       Auto Plant   : tanam seed yang trait-nya == craving, sampai target N (input).
       Auto Collect : panen fruit yang trait-nya == craving (ke backpack).
       Auto Submit  : equip tiap produce tool trait==craving -> SubmitHeldPlant.
                      SENGAJA per-plant (bukan SubmitAllPlant) biar crop lain (non-craving,
                      mahal) TIDAK ikut kefeed. Aman.

     Remote:
       Plant_RE:FireServer(pos, seedName)
       GameEvents.Crops.Collect:FireServer({fruitModels})
       GameEvents.Events.BeanstalkEvent.BeanstalkRESubmitHeldPlant:FireServer()
]]
return function(ctx)
	local LP          = ctx.LP
	local CFG         = ctx.CFG
	local RS          = game:GetService("ReplicatedStorage")
	local GE          = RS:WaitForChild("GameEvents")
	local DataService = ctx.deps.DataService
	local function setStatus(s) ctx.setStatus(s) end

	local Plant_RE = GE:WaitForChild("Plant_RE")
	local Collect  = GE:WaitForChild("Crops"):WaitForChild("Collect")
	local BeanEv   = GE:WaitForChild("Events"):WaitForChild("BeanstalkEvent")
	local SubmitHeld = BeanEv:WaitForChild("BeanstalkRESubmitHeldPlant")
	local SubmitAll  = BeanEv:WaitForChild("BeanstalkRESubmitAllPlant")
	local SellInventory = GE:FindFirstChild("Sell_Inventory") -- jual SEMUA isi backpack (NPC Steven)
	local IS; pcall(function() IS = require(RS.Modules.InventoryService) end)
	local function backpackFull()
		if not IS then return false end
		local ok, full = pcall(function() return IS:IsMaxInventory() end)
		return ok and full == true
	end

	local PlantTraits
	pcall(function() PlantTraits = require(RS.Modules.PlantTraitsData) end)
	local ALL_TRAITS = { "Berry", "Flower", "Fruit", "Leafy", "Vegetable", "Woody", "Prickly", "Stalky", "Tropical" }
	pcall(function()
		local cfg = require(RS.Data.Events.BeanstalkEvent.BeanstalkEventConfig)
		if type(cfg.Traits) == "table" and #cfg.Traits > 0 then ALL_TRAITS = cfg.Traits end
	end)

	local function hasTrait(name, trait)
		if not name or name == "" or not trait then return false end
		if PlantTraits and PlantTraits.HasTrait then
			local ok, res = pcall(function() return PlantTraits.HasTrait(name, trait) end)
			if ok then return res == true end
		end
		return false
	end

	----------------------------------------------------------------- craving (baca billboard)
	local function beanModel() return workspace:FindFirstChild("Interaction") and workspace.Interaction:FindFirstChild("BeanstalkEventModel") end
	-- Buang tag rich-text lalu cari trait yang cocok di ALL_TRAITS.
	local function parseTrait(txt)
		if not txt then return nil end
		local clean = txt:gsub("<[^>]->", "")
		for _, tr in ipairs(ALL_TRAITS) do
			if clean:find(tr, 1, true) then return tr end
		end
		return nil
	end
	-- craving trait sekarang (nil kalau event ga aktif / label ga ketemu)
	local function currentCraving()
		local m = beanModel(); if not m then return nil end
		for _, g in ipairs(m:GetDescendants()) do
			if g:IsA("TextLabel") and g.Text:find("need") then
				local tr = parseTrait(g.Text)
				if tr then return tr end
			end
		end
		return nil
	end
	-- progress growth global "X/Y" dari billboard (buat status)
	local function growthText()
		local m = beanModel(); if not m then return nil end
		for _, g in ipairs(m:GetDescendants()) do
			if g:IsA("TextLabel") then
				local a, b = g.Text:match("^(%d+)%s*/%s*(%d+)$")
				if a and b then return a .. "/" .. b end
			end
		end
		return nil
	end
	-- Event aktif = model ada DAN billboard nampilin UI event (craving / growth / decay).
	-- CATATAN: attribute workspace "ActivateBeanstalk" TERNYATA ga reliable (bisa false pas
	-- event jelas jalan), jadi JANGAN dipakai. Billboard = sumber kebenaran.
	-- Beanstalk PENUH (growth mentok a>=b): setor lebih lanjut percuma, tunggu reset.
	-- CATATAN: label "Beanstalk Decays in:" itu timer decay NORMAL yg SELALU muncul selama
	-- event jalan (bukan penanda cooldown), jadi JANGAN dipakai — cukup cek growth mentok.
	local function isDecaying()
		local m = beanModel(); if not m then return false end
		for _, g in ipairs(m:GetDescendants()) do
			if g:IsA("TextLabel") then
				local a, b = g.Text:match("^(%d+)%s*/%s*(%d+)$")
				if a and b and tonumber(a) >= tonumber(b) then return true end
			end
		end
		return false
	end
	local function isActive()
		if beanModel() == nil then return false end
		return currentCraving() ~= nil or growthText() ~= nil or isDecaying()
	end

	----------------------------------------------------------------- seed inventory (per trait)
	local function seedInventory()
		local out = {}
		local ok, d = pcall(function() return DataService:GetData() end)
		if ok and d and type(d.InventoryData) == "table" then
			for _, v in pairs(d.InventoryData) do
				if type(v) == "table" and v.ItemType == "Seed" and v.ItemData then
					local nm = v.ItemData.ItemName
					local q = tonumber(v.ItemData.Quantity) or 0
					if nm then out[nm] = (out[nm] or 0) + q end
				end
			end
		end
		return out
	end

	----------------------------------------------------------------- farm helpers (plant)
	local function myFarm()
		local ok, GetFarm = pcall(function() return require(RS.Modules.GetFarm) end)
		if ok and GetFarm then
			local ok2, f = pcall(function() return GetFarm(LP) end)
			if ok2 then return f end
		end
		return nil
	end
	local function canPlantParts()
		local f = myFarm()
		local imp = f and f:FindFirstChild("Important")
		local pl = imp and imp:FindFirstChild("Plant_Locations")
		local parts = {}
		if pl then for _, p in ipairs(pl:GetChildren()) do if p:IsA("BasePart") then parts[#parts + 1] = p end end end
		return parts
	end
	local function randomPos()
		local parts = canPlantParts()
		if #parts == 0 then return nil end
		local p = parts[math.random(1, #parts)]
		local hx, hz = p.Size.X / 2 - 1, p.Size.Z / 2 - 1
		local x = p.Position.X + (math.random() * 2 - 1) * hx
		local z = p.Position.Z + (math.random() * 2 - 1) * hz
		return Vector3.new(x, p.Position.Y, z)
	end
	-- equip seed tool "<Nama> Seed [Xn]" (server wajib megang pas Plant_RE)
	local function seedBase(t) return t:IsA("Tool") and t.Name:match("^(.-) Seed %[X%d+%]") or nil end
	local function holdingSeed(name)
		local ch = LP.Character
		if ch then for _, t in ipairs(ch:GetChildren()) do if seedBase(t) == name then return true end end end
		return false
	end
	local function equipSeed(name)
		if holdingSeed(name) then return true end
		local bp = LP:FindFirstChild("Backpack")
		local tool
		if bp then for _, t in ipairs(bp:GetChildren()) do if seedBase(t) == name then tool = t; break end end end
		if tool then
			local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
			if hum then pcall(function() hum:EquipTool(tool) end) end
		end
		return holdingSeed(name)
	end

	----------------------------------------------------------------- fruit di farm (collect)
	-- PENTING: cuma sentuh kebun MILIK SENDIRI. Semua garden namanya "Farm", dibedain lewat
	-- Important.Data.Owner. Dulu cuma skip CommunityGarden -> kesapu kebun pemain lain (bug).
	local function myGarden()
		local f = myFarm()            -- via GetFarm(LP), paling akurat
		if f then return f end
		local Farm = workspace:FindFirstChild("Farm"); if not Farm then return nil end
		for _, g in ipairs(Farm:GetChildren()) do
			local d = g:FindFirstChild("Important") and g.Important:FindFirstChild("Data")
			local o = d and d:FindFirstChild("Owner")
			if o and o.Value == LP.Name then return g end
		end
		return nil
	end
	local function myPlantsPhysical()
		local g = myGarden(); local imp = g and g:FindFirstChild("Important")
		return imp and imp:FindFirstChild("Plants_Physical")
	end
	local function eachFruit(fn)
		local pp = myPlantsPhysical(); if not pp then return end
		for _, plant in ipairs(pp:GetChildren()) do
			local fr = plant:FindFirstChild("Fruits")
			if fr then for _, f in ipairs(fr:GetChildren()) do fn(f) end end
		end
	end

	-- iterasi tiap plant (model) yang lagi tumbuh di kebun SENDIRI
	local function eachPlant(fn)
		local pp = myPlantsPhysical(); if not pp then return end
		for _, plant in ipairs(pp:GetChildren()) do
			if plant:IsA("Model") then fn(plant) end
		end
	end
	-- cache nama tanaman -> set trait (biar HasTrait ga dipanggil berulang)
	local nameTraitCache = {}
	local function traitsOf(name)
		local c = nameTraitCache[name]
		if c then return c end
		c = {}
		for _, tr in ipairs(ALL_TRAITS) do if hasTrait(name, tr) then c[tr] = true end end
		nameTraitCache[name] = c
		return c
	end
	-- jumlah plant tumbuh per SEMUA trait (1x pass). return map trait->count
	local function plantedByTrait()
		local counts = {}
		for _, tr in ipairs(ALL_TRAITS) do counts[tr] = 0 end
		eachPlant(function(p)
			for tr in pairs(traitsOf(p.Name)) do counts[tr] = (counts[tr] or 0) + 1 end
		end)
		return counts
	end
	-- jumlah plant 1 trait yang sudah ketanam (+ breakdown per nama)
	local function plantedInfo(trait)
		local total, byName = 0, {}
		eachPlant(function(p)
			if hasTrait(p.Name, trait) then
				total = total + 1
				byName[p.Name] = (byName[p.Name] or 0) + 1
			end
		end)
		return total, byName
	end

	----------------------------------------------------------------- produce tool di backpack (submit)
	-- Tool hasil panen: punya child "Item_String" (nama tanaman), bukan pet (PET_UUID), bukan seed.
	local function produceName(t)
		if not t:IsA("Tool") then return nil end
		if t:GetAttribute("PET_UUID") then return nil end
		if t.Name:match("Seed %[X%d+%]") then return nil end
		local is = t:FindFirstChild("Item_String")
		if is and is.Value ~= "" then return is.Value end
		return nil
	end
	-- daftar produce tool di backpack yang cocok trait
	local function cravingProduceTools(trait)
		local out = {}
		local bp = LP:FindFirstChild("Backpack"); if not bp then return out end
		for _, t in ipairs(bp:GetChildren()) do
			local nm = produceName(t)
			if nm and hasTrait(nm, trait) then out[#out + 1] = t end
		end
		return out
	end

	----------------------------------------------------------------- status summary buat GUI
	function ctx.getBeanstalkSummary()
		local craving = currentCraving()
		local res = { active = isActive(), craving = craving, traits = ALL_TRAITS }
		res.growth = growthText() or "-"
		local ok, d = pcall(function() return DataService:GetData() end)
		res.contributed = (ok and d and d.BeanstalkEvent and d.BeanstalkEvent.EventsContributed) or 0
		res.target = tonumber(CFG.beanstalkPlantCount) or 0
		-- ketanam per SEMUA trait (buat display "Vegetable 50/20, Flower 0/20, ...")
		local counts = plantedByTrait()
		res.perTrait = {}
		for _, tr in ipairs(ALL_TRAITS) do
			res.perTrait[#res.perTrait + 1] = { trait = tr, planted = counts[tr] or 0, target = res.target, craving = (tr == craving) }
		end
		if craving then
			res.ready = #cravingProduceTools(craving)               -- produce craving siap setor
			res.planted = counts[craving] or 0                      -- ketanam trait craving
			local seeds, seedTotal = seedInventory(), 0
			for nm, q in pairs(seeds) do if q > 0 and hasTrait(nm, craving) then seedTotal = seedTotal + q end end
			res.seeds = seedTotal
		else
			res.ready, res.seeds, res.planted = 0, 0, 0
		end
		return res
	end

	----------------------------------------------------------------- aksi tunggal (reusable)
	-- FOKUS 1 TRAIT per panggilan: pilih trait pertama (urutan ALL_TRAITS) yang masih < target
	-- DAN ada seed-nya, tanam persis sampai target (ga lebih). Count dihitung ulang tiap siklus
	-- jadi ga overshoot. return jumlahBaru, namaTrait.
	function ctx.beanstalkPlantOnce(target)
		target = tonumber(target) or 0; if target <= 0 then return 0, nil end
		local counts = plantedByTrait()
		local inv = seedInventory()
		for _, trait in ipairs(ALL_TRAITS) do
			local need = target - (counts[trait] or 0)
			if need > 0 then
				local names = {}
				for nm, q in pairs(inv) do if q > 0 and hasTrait(nm, trait) then names[#names + 1] = nm end end
				table.sort(names)
				if #names > 0 then
					local planted = 0
					for _, name in ipairs(names) do
						while (inv[name] or 0) > 0 and planted < need do
							if not CFG.beanstalkPlantEnabled or not ctx.alive() then return planted, trait end
							if equipSeed(name) then
								local pos = randomPos()
								if pos then
									pcall(function() Plant_RE:FireServer(pos, name) end)
									planted = planted + 1; inv[name] = inv[name] - 1
								else break end
							else break end
							task.wait(tonumber(CFG.beanstalkDelay) or 0.2)
						end
						if planted >= need then break end
					end
					return planted, trait  -- selesai 1 trait dulu, sisanya siklus berikut
				end
			end
		end
		return 0, nil
	end

	-- Panen fruit craving ke backpack. return jumlah dikirim, atau -1 kalau backpack penuh (dijeda).
	function ctx.beanstalkCollectOnce(trait)
		trait = trait or currentCraving(); if not trait then return 0 end
		if backpackFull() then return -1 end   -- penuh: jeda collect (ga spam)
		local batch = {}
		eachFruit(function(f) if hasTrait(f.Name, trait) then batch[#batch + 1] = f end end)
		local n = 0
		for i = 1, #batch, 40 do
			if not ctx.alive() then break end
			local chunk = {}
			for j = i, math.min(i + 39, #batch) do chunk[#chunk + 1] = batch[j] end
			pcall(function() Collect:FireServer(chunk) end)
			n = n + #chunk
			task.wait(0.1)
		end
		return n
	end

	-- Setor SEMUA plant sekaligus (BeanstalkRESubmitAllPlant, 1 call). Server hanya kredit
	-- plant yang sesuai craving. return jumlah produce craving yang ada saat setor (perkiraan).
	function ctx.beanstalkSubmitOnce(trait)
		trait = trait or currentCraving(); if not trait then return 0 end
		local n = #cravingProduceTools(trait)
		if n <= 0 then return 0 end
		pcall(function() SubmitAll:FireServer() end)
		task.wait(0.5)
		return n
	end

	-- Claim reward: tiap RewardPoint yang ProximityPrompt-nya Enabled -> fireproximityprompt.
	-- Itu memicu handler client asli (BeanstalkGrowController) yang FireServer ClaimReward(i)
	-- dengan index BENAR, jadi ga usah nebak index. return jumlah reward yang di-claim.
	local function rewardPrompts()
		local m = beanModel(); if not m then return {} end
		local bs = m:FindFirstChild("BeanStalk2")
		local root = bs and bs:FindFirstChild("Root")
		local rp = root and root:FindFirstChild("RewardPoints")
		local out = {}
		if rp then
			for _, pt in ipairs(rp:GetChildren()) do
				local pp = pt:FindFirstChildWhichIsA("ProximityPrompt", true)
				if pp and pp.Enabled then out[#out + 1] = pp end
			end
		end
		return out
	end
	function ctx.beanstalkClaimOnce()
		if type(fireproximityprompt) ~= "function" then return 0 end
		local prompts = rewardPrompts()
		local n = 0
		for _, pp in ipairs(prompts) do
			if not ctx.alive() then break end
			pcall(function() fireproximityprompt(pp) end)
			n = n + 1
			task.wait(0.2)
		end
		return n
	end

	local function claimLoop()
		ctx.state.beanClaimId = (ctx.state.beanClaimId or 0) + 1
		local myId = ctx.state.beanClaimId
		ctx.elevate()
		while CFG.beanstalkClaimEnabled and ctx.alive() and ctx.state.beanClaimId == myId do
			if isActive() then
				local c = ctx.beanstalkClaimOnce()
				if c > 0 then setStatus(("Beanstalk: claim %d reward"):format(c)) end
			end
			task.wait(3)
		end
	end
	function ctx.startBeanstalkClaim()
		if not CFG.beanstalkClaimEnabled then return end
		task.spawn(claimLoop)
	end
	function ctx.stopBeanstalkClaim() ctx.state.beanClaimId = (ctx.state.beanClaimId or 0) + 1 end

	-- Jual SEMUA isi backpack (recovery pas mentok: backpack penuh trait salah). Return true kalau di-fire.
	function ctx.beanstalkSellAll()
		if not SellInventory then return false end
		pcall(function() SellInventory:FireServer() end)
		return true
	end

	----------------------------------------------------------------- loop utama (1 loop, semua toggle)
	local function anyOn() return CFG.beanstalkPlantEnabled or CFG.beanstalkCollectEnabled or CFG.beanstalkSubmitEnabled or false end
	ctx.beanstalkAnyOn = anyOn

	local function beanstalkLoop()
		ctx.state.beanstalkId = (ctx.state.beanstalkId or 0) + 1
		local myId = ctx.state.beanstalkId
		ctx.elevate()
		while anyOn() and ctx.alive() and ctx.state.beanstalkId == myId do
			if not isActive() then
				setStatus("Beanstalk: event ga aktif, tunggu...")
				task.wait(5)
			else
				-- Auto Plant: top-up SEMUA trait, ga butuh craving (pre-stock).
				if CFG.beanstalkPlantEnabled then
					local p, tr = ctx.beanstalkPlantOnce(CFG.beanstalkPlantCount)
					if p > 0 then setStatus(("Beanstalk: tanam %d %s"):format(p, tr or "")) end
				end
				local trait = currentCraving()
				if not trait then
					if not CFG.beanstalkPlantEnabled then setStatus("Beanstalk: craving ga kebaca, tunggu...") end
					task.wait(3)
				else
					if isDecaying() then
						-- growth penuh: setor ditolak (CD). Cukup nunggu refresh, jangan setor/jual/collect.
						setStatus("Beanstalk: growth penuh (CD) — nunggu refresh")
					else
						-- 1) SUBMIT dulu: kredit produce craving + kosongin slot-nya di backpack.
						if CFG.beanstalkSubmitEnabled then
							local s = ctx.beanstalkSubmitOnce(trait)
							if s > 0 then setStatus(("Beanstalk: setor %d %s"):format(s, trait))
							else setStatus(("Beanstalk: nunggu %s plant (craving)"):format(trait)) end
						end
						-- 2) Backpack MASIH penuh setelah submit = keisi trait salah (clog).
						--    Jual semua biar lega (kalau toggle Auto Sell ON). Produce craving udah
						--    kesetor di langkah 1, jadi yang kejual cuma sisa trait lain.
						local full = backpackFull()
						if full and CFG.beanstalkAutoSellEnabled and #cravingProduceTools(trait) == 0 then
							if ctx.beanstalkSellAll() then
								setStatus("Beanstalk: backpack mentok (trait salah) — jual semua")
								task.wait(1); full = backpackFull()
							end
						end
						-- 3) COLLECT fruit craving (isi backpack buat disetor siklus berikut).
						if CFG.beanstalkCollectEnabled then
							local c = ctx.beanstalkCollectOnce(trait)
							if c > 0 then setStatus(("Beanstalk: panen %d %s"):format(c, trait))
							elseif c < 0 then setStatus("Beanstalk: backpack penuh — collect dijeda"..(CFG.beanstalkAutoSellEnabled and "" or " (nyalain Auto Sell)")) end
						end
					end
					task.wait(math.max(0.5, tonumber(CFG.beanstalkDelay) or 0.5) + 0.5)
				end
			end
		end
	end

	function ctx.startBeanstalk()
		if not anyOn() then return end
		task.spawn(beanstalkLoop)
	end
	function ctx.stopBeanstalk() ctx.state.beanstalkId = (ctx.state.beanstalkId or 0) + 1 end

	----------------------------------------------------------------- Beanstalk Event Shop (auto-buy)
	-- Shop beanstalk = "Goliath's Goods" (Main) + "Goliath's Friends Deals" (Friendship).
	-- Beli: GameEvents.BuyEventShopStock:FireServer(item, shopName). Currency Sheckles.
	local SHOP_LIST = { "Goliath's Goods", "Goliath's Friends Deals" }
	local BuyEventShopStock = GE:FindFirstChild("BuyEventShopStock")
	local function eventShopData()
		local ok, ESD = pcall(function() return require(RS.Data.EventShopData) end)
		return ok and ESD or {}
	end
	-- Tampilkan SEMUA item yang di-display shop (TANPA filter harga). Item mahal (Price >= 1e9
	-- kayak Gnome, Pet Shard GiantBean) itu harga Sheckle valid, dibeli via BuyEventShopStock;
	-- FallbackPrice/PurchaseID cuma opsi Robux. Cuma skip DisplayInShop==false.
	local function shopBuyable(v)
		return type(v) == "table" and v.DisplayInShop ~= false
	end
	local function shopStock(shop, item)
		local ok, d = pcall(function() return DataService:GetData() end)
		local s = ok and d and d.EventShopStock and d.EventShopStock[shop]
		local st = s and s.Stocks and s.Stocks[item]
		return st and tonumber(st.Stock) or 0
	end

	-- opsi dropdown item shop (gabungan 2 shop, "All" di atas)
	function ctx.getBeanstalkShopOptions()
		local ESD = eventShopData()
		local out = { { value = "All", display = "All (semua item)" } }
		local seen = {}
		for _, shop in ipairs(SHOP_LIST) do
			local cat = ESD[shop]
			if cat then
				local names = {}
				for name, v in pairs(cat) do if shopBuyable(v) and not seen[name] then seen[name] = true; names[#names + 1] = name end end
				table.sort(names)
				for _, n in ipairs(names) do out[#out + 1] = { value = n, display = n } end
			end
		end
		return out
	end

	local function buyShopLoop()
		ctx.state.beanShopId = (ctx.state.beanShopId or 0) + 1
		local myId = ctx.state.beanShopId
		ctx.elevate()
		while CFG.buyBeanstalkShopEnabled and ctx.alive() and ctx.state.beanShopId == myId do
			local sel = CFG.buyBeanstalkShopNames or {}
			if next(sel) and BuyEventShopStock then
				local ESD = eventShopData()
				local bought = 0
				for _, shop in ipairs(SHOP_LIST) do
					local cat = ESD[shop]
					if cat then
						for name, v in pairs(cat) do
							if shopBuyable(v) and (sel["All"] or sel[name]) then
								local n = shopStock(shop, name)
								for _ = 1, n do
									if not CFG.buyBeanstalkShopEnabled or ctx.state.beanShopId ~= myId then break end
									pcall(function() BuyEventShopStock:FireServer(name, shop) end)
									bought = bought + 1
									task.wait(0.15)
								end
							end
						end
					end
				end
				if bought > 0 then setStatus(("Beanstalk Shop: beli %d item"):format(bought)) end
			end
			task.wait(2)
		end
	end
	function ctx.startBuyBeanstalkShop() task.spawn(buyShopLoop) end
	function ctx.stopBuyBeanstalkShop() ctx.state.beanShopId = (ctx.state.beanShopId or 0) + 1 end
end
]=],
	["modules/farm/automation_collect.lua"] = [=[
--[[ automation_collect.lua — Auto Collect fruit (harvest ke backpack).
     Remote (dari CollectController): GameEvents.Crops.Collect:FireServer({fruitModel,...})
       — batch collect list FRUIT MODEL. Jalan walau jauh (server ga cek proximity).
     Backpack full: require(Modules.InventoryService):IsMaxInventory().
     Auto-sell: GameEvents.SellFood_RE:FireServer().
     3 mode (bisa barengan), collect fruit yang cocok SALAH SATU mode aktif:
       1) Whitelist Fruit   : tipe fruit terpilih
       2) Whitelist Mutation: fruit punya mutasi terpilih
       3) Combined          : fruit + mutasi + variant + berat (SEMUA kriteria) ]]
return function(ctx)
	local RS  = game:GetService("ReplicatedStorage")
	local CFG = ctx.CFG
	local LP  = ctx.LP
	local Collect = RS.GameEvents:WaitForChild("Crops"):WaitForChild("Collect")
	local SellInv = RS.GameEvents:WaitForChild("Sell_Inventory")
	local IS
	pcall(function() IS = require(RS.Modules.InventoryService) end)

	-- Jual semua fruit: HARUS deket NPC jual (Steven) — teleport bentar, jual, balik.
	local function sellAllFruits()
		local char = LP.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if not hrp then return end
		local npcs = workspace:FindFirstChild("NPCS")
		local steven = npcs and npcs:FindFirstChild("Steven")
		local shrp = steven and steven:FindFirstChild("HumanoidRootPart")
		if not shrp then return end
		local orig = hrp.CFrame
		hrp.CFrame = shrp.CFrame * CFrame.new(0, 0, 4) -- deket Steven
		task.wait(0.5)
		pcall(function() SellInv:FireServer() end)
		task.wait(0.8)
		pcall(function() if hrp and hrp.Parent then hrp.CFrame = orig end end) -- balik
	end

	local NOT_MUTATION = {
		FruitVersion = true, MaxAge = true, GrowRateMulti = true, WeightMulti = true,
		DoneGrowTime = true, FruitSpawnIndex = true, OfflineGrowthTarget = true,
		MasteryGrowthMulti = true, MasterySizeMulti = true,
	}

	local function backpackFull()
		if not IS then return false end
		local ok, full = pcall(function() return IS:IsMaxInventory() end)
		return ok and full == true
	end

	-- Cuma kebun MILIK SENDIRI. Semua garden namanya "Farm", dibedain lewat Important.Data.Owner.
	-- Skip-CommunityGarden aja ga cukup -> kesapu kebun pemain lain (bug).
	local function myGarden()
		local ok, GetFarm = pcall(function() return require(RS.Modules.GetFarm) end)
		if ok and GetFarm then local ok2, f = pcall(function() return GetFarm(LP) end); if ok2 and f then return f end end
		local Farm = workspace:FindFirstChild("Farm"); if not Farm then return nil end
		for _, g in ipairs(Farm:GetChildren()) do
			local d = g:FindFirstChild("Important") and g.Important:FindFirstChild("Data")
			local o = d and d:FindFirstChild("Owner")
			if o and o.Value == LP.Name then return g end
		end
		return nil
	end
	local function eachFruit(fn)
		local g = myGarden(); local imp = g and g:FindFirstChild("Important")
		local pp = imp and imp:FindFirstChild("Plants_Physical")
		if not pp then return end
		for _, plant in ipairs(pp:GetChildren()) do
			local fr = plant:FindFirstChild("Fruits")
			if fr then for _, f in ipairs(fr:GetChildren()) do fn(f) end end
		end
	end

	----------------------------------------------------------------- opsi UI
	local function optionsFrom(names, allLabel)
		local out = { { value = "All", display = allLabel or "All" } }
		for _, n in ipairs(names) do out[#out + 1] = { value = n, display = n } end
		return out
	end
	local function catalog()
		local ok, t = pcall(function() return require(RS.Data.SeedShopData) end)
		local names = {}
		if ok and type(t) == "table" then
			for k in pairs(t) do local n = tostring(k); if n ~= "RefreshTime" and n ~= "Gear" then names[#names + 1] = n end end
			table.sort(names)
		end
		return names
	end
	function ctx.getCollectFruitOptions() return optionsFrom(catalog(), "All (semua fruit)") end
	function ctx.getCollectVariantOptions()
		local set = { Normal = true, Gold = true, Rainbow = true }
		eachFruit(function(f) local v = f:FindFirstChild("Variant"); if v and v.Value ~= "" then set[tostring(v.Value)] = true end end)
		local names = {} for k in pairs(set) do names[#names + 1] = k end; table.sort(names)
		return optionsFrom(names, "All (semua variant)")
	end
	function ctx.getCollectMutationOptions()
		-- daftar LENGKAP semua mutasi buah dari registry (MutationHandler.MutationNames)
		local ok, MH = pcall(function() return require(RS.Modules.MutationHandler) end)
		local names = {}
		if ok and MH and type(MH.MutationNames) == "table" then
			local mn = MH.MutationNames
			if mn[1] ~= nil then for _, v in ipairs(mn) do names[#names + 1] = tostring(v) end
			else for k in pairs(mn) do names[#names + 1] = tostring(k) end end
			table.sort(names)
		end
		return optionsFrom(names, "All (semua mutasi)")
	end
	function ctx.getCollectModeOptions() return { ">= (berat minimal)", "<= (berat maksimal)" } end

	----------------------------------------------------------------- match per-mode
	local function hasSelMut(f, muts)
		for m in pairs(muts) do if m ~= "All" and f:GetAttribute(m) == true then return true end end
		return false
	end
	local function fruitVariant(f) local v = f:FindFirstChild("Variant"); return v and tostring(v.Value) or "Normal" end
	local function fruitWeight(f) local w = f:FindFirstChild("Weight"); return w and tonumber(w.Value) or 0 end

	-- mode 1: whitelist fruit type
	local function matchWlFruit(f)
		if not CFG.collectWlFruitEnabled then return false end
		local sel = CFG.collectWlFruitNames or {}
		return sel["All"] == true or sel[f.Name] == true
	end
	-- mode 2: whitelist mutation
	local function matchWlMut(f)
		if not CFG.collectWlMutEnabled then return false end
		local muts = CFG.collectWlMutNames or {}
		if muts["All"] then return true end
		return hasSelMut(f, muts)
	end
	-- mode 3: combined (SEMUA kriteria)
	local function matchCombined(f)
		if not CFG.collectCombEnabled then return false end
		local sel  = CFG.collectCombFruitNames or {}
		local muts = CFG.collectCombMutNames or {}
		local vars = CFG.collectCombVariants or {}
		if not (next(sel) == nil or sel["All"] or sel[f.Name]) then return false end
		if not (next(muts) == nil or muts["All"] or hasSelMut(f, muts)) then return false end
		if not (next(vars) == nil or vars["All"] or vars[fruitVariant(f)]) then return false end
		local thr = tonumber(CFG.collectCombWeight) or 0
		if thr > 0 then
			local w = fruitWeight(f)
			if (CFG.collectCombMode or ">="):find("<=") then if not (w <= thr) then return false end
			else if not (w >= thr) then return false end end
		end
		return true
	end

	local function shouldCollect(f)
		return matchWlFruit(f) or matchWlMut(f) or matchCombined(f)
	end
	local function anyEnabled()
		return CFG.collectWlFruitEnabled or CFG.collectWlMutEnabled or CFG.collectCombEnabled
	end

	----------------------------------------------------------------- loop
	local running = false
	local function collectLoop()
		ctx.state.collectId = (ctx.state.collectId or 0) + 1
		local myId = ctx.state.collectId
		ctx.elevate()
		while anyEnabled() and ctx.alive() and ctx.state.collectId == myId do
			-- backpack full handling
			if backpackFull() then
				if CFG.collectAutoSellIfFull then
					ctx.setStatus("Auto Collect: backpack penuh -> jual (ke Steven)")
					sellAllFruits()
					task.wait(0.5)
				elseif CFG.collectStopIfFull then
					ctx.setStatus("Auto Collect: backpack penuh -> stop")
					task.wait(math.max(1, tonumber(CFG.collectDelay) or 0))
					-- lanjut cek lagi (ga collect)
				end
			end
			if not (backpackFull() and CFG.collectStopIfFull and not CFG.collectAutoSellIfFull) then
				-- kumpulin fruit yg cocok
				local batch = {}
				eachFruit(function(f) if shouldCollect(f) then batch[#batch + 1] = f end end)
				-- fire per-chunk (biar payload ga kegedean)
				local n = 0
				for i = 1, #batch, 40 do
					if not anyEnabled() or ctx.state.collectId ~= myId then break end
					local chunk = {}
					for j = i, math.min(i + 39, #batch) do chunk[#chunk + 1] = batch[j] end
					pcall(function() Collect:FireServer(chunk) end)
					n = n + #chunk
					task.wait(0.1)
					if backpackFull() then break end
				end
				ctx.setStatus(("Auto Collect: collect %d fruit"):format(n))
			end
			task.wait(math.max(0.5, tonumber(CFG.collectDelay) or 0) + 0.5)
		end
		running = false
	end

	-- 1 loop dipakai bareng semua mode; idempotent (semua toggle panggil ini).
	function ctx.startCollect()
		if running then return end
		running = true
		task.spawn(collectLoop)
	end
	function ctx.stopCollect() ctx.state.collectId = (ctx.state.collectId or 0) + 1 end
end
]=],
	["modules/farm/automation_favorite.lua"] = [=[
--[[ automation_favorite.lua — Auto Favorite/Unfavorite fruit.
     Favorite = "lock" buah biar ga kejual/keshovel. Pakai Favorite Tool (equip + guard).
     Remote (dari Favorite Tool script): LockToolRemote:InvokeServer(favTool, fruitModel, state)
       state=true -> favorite, false -> unfavorite. RemoteFunction.
     State fruit: fruit:GetAttribute("Favorited") (boolean). Cuma fruit tag "Harvestable".
     Filter: tipe fruit + mutasi (required) + berat (mode + threshold). ]]
return function(ctx)
	local RS  = game:GetService("ReplicatedStorage")
	local CFG = ctx.CFG
	local LP  = ctx.LP
	-- Ambil remote LAZY (jangan WaitForChild di module-load -> bisa nge-block init).
	local function favRemote()
		local GE = RS:FindFirstChild("GameEvents"); if not GE then return nil end
		return GE:FindFirstChild("FavoriteToolRemote") or GE:FindFirstChild("Favorite_Item")
	end
	-- Panggil remote: RemoteFunction -> InvokeServer, RemoteEvent -> FireServer.
	local function doFav(tool, fruit, state)
		local re = favRemote(); if not re then return end
		pcall(function()
			if re:IsA("RemoteFunction") then re:InvokeServer(tool, fruit, state)
			else re:FireServer(tool, fruit, state) end
		end)
	end

	----------------------------------------------------------------- tool equip + guard
	local function findTool()
		for _, where in ipairs({ LP.Character, LP:FindFirstChildOfClass("Backpack") }) do
			if where then for _, t in ipairs(where:GetChildren()) do
				if t:IsA("Tool") and tostring(t.Name):find("Favorite") then return t end
			end end
		end
	end
	local function heldTool()
		local char = LP.Character
		if not char then return nil end
		for _, t in ipairs(char:GetChildren()) do
			if t:IsA("Tool") and tostring(t.Name):find("Favorite") then return t end
		end
	end
	local function equipTool()
		local char = LP.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if not hum then return false end
		if heldTool() then return true end
		local tl = findTool()
		if not tl then return false end
		pcall(function() hum:EquipTool(tl) end)
		task.wait(0.2)
		return heldTool() ~= nil
	end
	local guardRunning = false
	local function ensureGuard()
		if guardRunning then return end
		guardRunning = true
		task.spawn(function()
			while (CFG.favEnabled or CFG.unfavEnabled) and ctx.alive() do
				if not heldTool() then equipTool() end
				task.wait(0.25)
			end
			guardRunning = false
		end)
	end

	----------------------------------------------------------------- opsi UI
	local function optionsFrom(names, allLabel)
		local out = { { value = "All", display = allLabel or "All" } }
		for _, n in ipairs(names) do out[#out + 1] = { value = n, display = n } end
		return out
	end
	local function catalog()
		local ok, t = pcall(function() return require(RS.Data.SeedShopData) end)
		local names = {}
		if ok and type(t) == "table" then
			for k in pairs(t) do local n = tostring(k); if n ~= "RefreshTime" and n ~= "Gear" then names[#names + 1] = n end end
			table.sort(names)
		end
		return names
	end
	function ctx.getFavFruitOptions() return optionsFrom(catalog(), "All (semua fruit)") end
	function ctx.getFavMutationOptions()
		local ok, MH = pcall(function() return require(RS.Modules.MutationHandler) end)
		local names = {}
		if ok and MH and type(MH.MutationNames) == "table" then
			local mn = MH.MutationNames
			if mn[1] ~= nil then for _, v in ipairs(mn) do names[#names + 1] = tostring(v) end
			else for k in pairs(mn) do names[#names + 1] = tostring(k) end end
			table.sort(names)
		end
		return optionsFrom(names, "All (mutasi apapun)")
	end
	function ctx.getFavModeOptions() return { ">= (berat minimal)", "<= (berat maksimal)" } end

	----------------------------------------------------------------- match filter
	local function fruitWeight(f) local w = f:FindFirstChild("Weight"); return w and tonumber(w.Value) or 0 end
	local function fruitMatches(f)
		local sel  = CFG.favFruitNames or {}
		local muts = CFG.favMutNames or {}
		-- tipe (kosong = any)
		if not (next(sel) == nil or sel["All"] or sel[f.Name]) then return false end
		-- mutasi required (kosong = any). Fruit harus punya salah satu mutasi terpilih.
		if not (next(muts) == nil or muts["All"]) then
			local hit = false
			for m in pairs(muts) do if m ~= "All" and f:GetAttribute(m) == true then hit = true; break end end
			if not hit then return false end
		end
		-- berat (0 = off)
		local thr = tonumber(CFG.favWeight) or 0
		if thr > 0 then
			local w = fruitWeight(f)
			if (CFG.favMode or ">="):find("<=") then if not (w <= thr) then return false end
			else if not (w >= thr) then return false end end
		end
		return true
	end

	-- kebun MILIK SENDIRI aja. Semua garden namanya "Farm", dibedain lewat Important.Data.Owner
	-- -> skip-CommunityGarden aja kesapu kebun pemain lain (bug).
	local function myGarden()
		local ok, GetFarm = pcall(function() return require(RS.Modules.GetFarm) end)
		if ok and GetFarm then local ok2, f = pcall(function() return GetFarm(LP) end); if ok2 and f then return f end end
		local Farm = workspace:FindFirstChild("Farm"); if not Farm then return nil end
		for _, g in ipairs(Farm:GetChildren()) do
			local d = g:FindFirstChild("Important") and g.Important:FindFirstChild("Data")
			local o = d and d:FindFirstChild("Owner")
			if o and o.Value == LP.Name then return g end
		end
		return nil
	end
	local function eachHarvestable(fn)
		local g = myGarden(); local imp = g and g:FindFirstChild("Important")
		local pp = imp and imp:FindFirstChild("Plants_Physical")
		if not pp then return end
		for _, plant in ipairs(pp:GetChildren()) do
			local fr = plant:FindFirstChild("Fruits")
			if fr then for _, f in ipairs(fr:GetChildren()) do
				if f:HasTag("Harvestable") then fn(f) end
			end end
		end
	end

	----------------------------------------------------------------- loop
	local function favLoop()
		ctx.state.favId = (ctx.state.favId or 0) + 1
		local myId = ctx.state.favId
		ctx.elevate()
		while (CFG.favEnabled or CFG.unfavEnabled) and ctx.alive() and ctx.state.favId == myId do
			local tool = heldTool() or findTool()
			if not tool then
				ctx.setStatus("Auto Favorite: Favorite Tool ga ada")
			else
				local n = 0
				eachHarvestable(function(f)
					if not (CFG.favEnabled or CFG.unfavEnabled) or ctx.state.favId ~= myId then return end
					if not fruitMatches(f) then return end
					local isFav = f:GetAttribute("Favorited") == true
					if CFG.favEnabled and not isFav then
						doFav(tool, f, true); n = n + 1; task.wait(0.08)
					elseif CFG.unfavEnabled and isFav then
						doFav(tool, f, false); n = n + 1; task.wait(0.08)
					end
				end)
				ctx.setStatus(("Auto Favorite: proses %d buah"):format(n))
			end
			task.wait(math.max(0.5, tonumber(CFG.favDelay) or 1) + 0.5)
		end
	end

	function ctx.startFavorite()
		equipTool(); ensureGuard()
		task.spawn(favLoop)
	end
	function ctx.stopFavorite() ctx.state.favId = (ctx.state.favId or 0) + 1 end
end
]=],
	["modules/farm/automation_plants.lua"] = [=[
--[[ automation_plants.lua — Auto Plant seed (Farm).
     Tanam seed dari inventory ke farm.
     Remote: Plant_RE:FireServer(Vector3 pos, "SeedName")
     Seed & jumlah dari DataService InventoryData (ItemType="Seed", ItemData.ItemName/Quantity).
     WAJIB megang tool seed-nya pas Plant_RE -> equip ulang tiap mau tanam (kayak reclaimer).
     Posisi: Random (titik acak di Can_Plant) / Player Position (posisi karakter).
     Fungsi: ctx.getPlantSeedOptions / ctx.startPlant. ]]
return function(ctx)
	local LP  = ctx.LP
	local CFG = ctx.CFG
	local RS  = game:GetService("ReplicatedStorage")
	local GE  = RS:WaitForChild("GameEvents")
	local Plant_RE = GE:WaitForChild("Plant_RE")
	local DataService = ctx.deps.DataService
	local function setStatus(s) ctx.setStatus(s) end

	local function myFarm()
		local ok, GetFarm = pcall(function() return require(RS.Modules.GetFarm) end)
		if ok and GetFarm then
			local ok2, f = pcall(function() return GetFarm(LP) end)
			if ok2 then return f end
		end
		return nil
	end
	local function important() local f = myFarm(); return f and f:FindFirstChild("Important") end
	local function canPlantParts()
		local imp = important()
		local pl = imp and imp:FindFirstChild("Plant_Locations")
		local parts = {}
		if pl then for _, p in ipairs(pl:GetChildren()) do if p:IsA("BasePart") then parts[#parts + 1] = p end end end
		return parts
	end

	----------------------------------------------------------------- seed inventory
	-- name -> total quantity (dari semua entry Seed di InventoryData)
	local function seedInventory()
		local out = {}
		local ok, d = pcall(function() return DataService:GetData() end)
		if ok and d and type(d.InventoryData) == "table" then
			for _, v in pairs(d.InventoryData) do
				if type(v) == "table" and v.ItemType == "Seed" and v.ItemData then
					local nm = v.ItemData.ItemName
					local q = tonumber(v.ItemData.Quantity) or 0
					if nm then out[nm] = (out[nm] or 0) + q end
				end
			end
		end
		return out
	end

	-- Opsi dropdown seed: "Nama (jumlah)". Sekalian buang seed yg udah 0 dari selection.
	local function seedOptions()
		local inv = seedInventory()
		local sel = CFG.plantSeedNames
		if type(sel) == "table" then
			local changed = false
			for nm in pairs(sel) do if (inv[nm] or 0) <= 0 then sel[nm] = nil; changed = true end end
			if changed and ctx.persistState then pcall(ctx.persistState) end
		end
		local names = {}
		for n, q in pairs(inv) do if q > 0 then names[#names + 1] = n end end
		table.sort(names)
		local out = {}
		for _, n in ipairs(names) do out[#out + 1] = { value = n, display = ("%s (%d)"):format(n, inv[n]) } end
		return out
	end
	function ctx.getPlantSeedOptions() return seedOptions() end

	----------------------------------------------------------------- posisi
	local function randomPos()
		local parts = canPlantParts()
		if #parts == 0 then return nil end
		local p = parts[math.random(1, #parts)]
		local hx, hz = p.Size.X / 2 - 1, p.Size.Z / 2 - 1
		local x = p.Position.X + (math.random() * 2 - 1) * hx
		local z = p.Position.Z + (math.random() * 2 - 1) * hz
		return Vector3.new(x, p.Position.Y, z)
	end
	local function playerPos()
		local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
		if not hrp then return nil end
		local parts = canPlantParts()
		local y = parts[1] and parts[1].Position.Y or 0
		return Vector3.new(hrp.Position.X, y, hrp.Position.Z)
	end

	----------------------------------------------------------------- equip seed
	-- Tool seed namanya "<Nama> Seed [Xjumlah]". Server WAJIB kamu megang tool-nya
	-- pas Plant_RE, jadi equip ulang tiap mau tanam (walau user pindah manual).
	local function seedBase(t)
		return t:IsA("Tool") and t.Name:match("^(.-) Seed %[X%d+%]") or nil
	end
	local function holdingSeed(name)
		local ch = LP.Character
		if ch then for _, t in ipairs(ch:GetChildren()) do if seedBase(t) == name then return true end end end
		return false
	end
	local function equipSeed(name)
		if holdingSeed(name) then return true end
		local bp = LP:FindFirstChild("Backpack")
		local tool
		if bp then for _, t in ipairs(bp:GetChildren()) do if seedBase(t) == name then tool = t; break end end end
		if tool then
			local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
			if hum then pcall(function() hum:EquipTool(tool) end) end
		end
		return holdingSeed(name)
	end

	----------------------------------------------------------------- loop tanam
	local function plantLoop(myId)
		ctx.elevate()
		while CFG.plantSeedEnabled and ctx.alive() and ctx.state.plantId == myId do
			local sel = CFG.plantSeedNames or {}
			if next(sel) then
				local inv = seedInventory()
				local mode = CFG.plantPosition == "Player Position" and "Player Position" or "Random"
				-- Kecepatan sepenuhnya ikut Delay input (0 = secepat mungkin).
				local planted, anySeed = 0, false
				for name in pairs(sel) do
					local qty = inv[name] or 0
					if qty > 0 then
						anySeed = true
						for _ = 1, qty do
							if not CFG.plantSeedEnabled or ctx.state.plantId ~= myId then break end
							if equipSeed(name) then -- equip seed tiap mau tanam
								local pos = (mode == "Player Position") and playerPos() or randomPos()
								if pos then
									pcall(function() Plant_RE:FireServer(pos, name) end)
									planted = planted + 1
								end
							end
							task.wait(tonumber(CFG.plantDelay) or 0)
						end
					end
				end
				if not anySeed then setStatus("Plants: seed terpilih habis")
				else setStatus(("Plants: tanam %d (%s)"):format(planted, mode)) end
			else
				setStatus("Plants: pilih seed dulu")
			end
			task.wait(1)
		end
	end

	function ctx.startPlant()
		ctx.state.plantId = (ctx.state.plantId or 0) + 1
		local myId = ctx.state.plantId
		task.spawn(function() plantLoop(myId) end)
	end
end
]=],
	["modules/farm/automation_reclaimer.lua"] = [=[
--[[ automation_reclaimer.lua — Auto Reclaimer plant (Farm).
     Reclaim plant yg ditanam di garden pakai tool Reclaimer.
     Remote: ReclaimerService_RE:FireServer("TryReclaim", plantModel)
       plantModel = Model di Farm.Important.Plants_Physical (mis. "Blueberry").
     Dropdown "Select Plants": jenis plant unik yg ada di garden (+ "All").
     Butuh tool Reclaimer (auto-equip di loop). Tiap reclaim makan 1 charge Reclaimer.
     Fungsi: ctx.getReclaimPlantOptions / ctx.startReclaim. ]]
return function(ctx)
	local LP  = ctx.LP
	local CFG = ctx.CFG
	local RS  = game:GetService("ReplicatedStorage")
	local GE  = RS:WaitForChild("GameEvents")
	local ReclaimRE = GE:WaitForChild("ReclaimerService_RE")
	local function setStatus(s) ctx.setStatus(s) end

	local function myFarm()
		local ok, GetFarm = pcall(function() return require(RS.Modules.GetFarm) end)
		if ok and GetFarm then
			local ok2, f = pcall(function() return GetFarm(LP) end)
			if ok2 then return f end
		end
		return nil
	end

	local function plantsFolder()
		local f = myFarm()
		local imp = f and f:FindFirstChild("Important")
		return imp and imp:FindFirstChild("Plants_Physical")
	end

	-- Jenis plant unik yg lagi ada di garden.
	local function existingTypes()
		local seen = {}
		local pf = plantsFolder()
		if pf then for _, m in ipairs(pf:GetChildren()) do if m.Name then seen[m.Name] = true end end end
		return seen
	end

	-- Buang plant terpilih yg udah ga ada di garden (kecuali "All"),
	-- biar ga kepilih tapi tanamannya udah abis.
	local function pruneSelection(existing)
		local sel = CFG.reclaimPlantNames
		if type(sel) ~= "table" then return end
		local changed = false
		for name in pairs(sel) do
			if name ~= "All" and not existing[name] then sel[name] = nil; changed = true end
		end
		if changed and ctx.persistState then pcall(ctx.persistState) end
	end

	-- Opsi dropdown: "All" + jenis plant yg lagi ada. Sekalian prune selection stale.
	local function plantOptions()
		local existing = existingTypes()
		pruneSelection(existing)
		local out = { { value = "All", display = "All (semua plant)" } }
		local names = {}
		for n in pairs(existing) do names[#names + 1] = n end
		table.sort(names)
		for _, n in ipairs(names) do out[#out + 1] = { value = n, display = n } end
		return out
	end
	function ctx.getReclaimPlantOptions() return plantOptions() end

	-- Nama tool di inventory ada suffix jumlah (mis. "Reclaimer x50634"),
	-- jadi cocokin per-prefix, bukan exact.
	local function isReclaimer(t)
		return t:IsA("Tool") and t.Name:match("^Reclaimer") ~= nil
	end
	local function heldReclaimer()
		local char = LP.Character
		if not char then return nil end
		for _, t in ipairs(char:GetChildren()) do if isReclaimer(t) then return t end end
		return nil
	end

	-- Equip tool Reclaimer dari Backpack kalau belum kepegang.
	local function equipReclaimer()
		local char = LP.Character
		if not char then return false end
		if heldReclaimer() then return true end
		local bp = LP:FindFirstChild("Backpack")
		local tool
		if bp then for _, t in ipairs(bp:GetChildren()) do if isReclaimer(t) then tool = t; break end end end
		if tool then
			local hum = char:FindFirstChildOfClass("Humanoid")
			if hum then pcall(function() hum:EquipTool(tool) end) end
		end
		return heldReclaimer() ~= nil
	end

	----------------------------------------------------------------- loop reclaim
	local POLL = 1
	local function reclaimLoop(myId)
		ctx.elevate()
		while CFG.reclaimEnabled and ctx.alive() and ctx.state.reclaimId == myId do
			local pf = plantsFolder()
			local sel = CFG.reclaimPlantNames or {}
			local all = sel["All"]
			if pf and (all or next(sel)) then
				local hasTool = equipReclaimer()
				if not hasTool then
					setStatus("Reclaimer: tool 'Reclaimer' ga ada di inventory")
				else
					local n = 0
					for _, m in ipairs(pf:GetChildren()) do
						if not CFG.reclaimEnabled or ctx.state.reclaimId ~= myId then break end
						if all or sel[m.Name] then
							pcall(function() ReclaimRE:FireServer("TryReclaim", m) end)
							n = n + 1
							task.wait(CFG.reclaimSpeed or 0.15)
						end
					end
					setStatus(("Reclaimer: proses %d plant"):format(n))
				end
			else
				setStatus("Reclaimer: pilih plant dulu")
			end
			task.wait(POLL)
		end
	end

	-- Guard: selama enable, tool Reclaimer WAJIB tetap kepegang. Kalau user pindah
	-- manual ke pet/tool lain, langsung equip ulang Reclaimer (cek cepat 0.25s).
	local function keepEquipped(myId)
		while CFG.reclaimEnabled and ctx.alive() and ctx.state.reclaimId == myId do
			if not heldReclaimer() then equipReclaimer() end
			task.wait(0.25)
		end
	end

	function ctx.startReclaim()
		ctx.state.reclaimId = (ctx.state.reclaimId or 0) + 1
		local myId = ctx.state.reclaimId
		equipReclaimer() -- equip langsung pas enable
		task.spawn(function() reclaimLoop(myId) end)
		task.spawn(function() keepEquipped(myId) end)
	end
end
]=],
	["modules/farm/automation_shovel.lua"] = [=[
--[[ automation_shovel.lua — Auto Shovel (2 mode):
       1) Shovel Tree/Plant  : hapus plant dari tipe terpilih (CFG.shovelTreeNames).
       2) Shovel Fruit        : hapus plant kalau punya FRUIT yang cocok filter
                                (tipe + mutasi + variant + berat vs threshold).
     Mekanisme (dari remote spy + tes live): Remove_Item:FireServer(plant.PrimaryPart)
     — hapus SELURUH plant. Ga perlu equip Shovel (server terima langsung).
     Plant ada di workspace.Farm.<garden>.Important.Plants_Physical (nama = tipe).
     Tiap plant.Fruits berisi fruit models: child Weight (NumberValue), Variant (StringValue),
     + attribute mutasi boolean (Wet/Twisted/dll). ]]
return function(ctx)
	local RS  = game:GetService("ReplicatedStorage")
	local CFG = ctx.CFG
	local LP  = ctx.LP
	local Remove = RS:WaitForChild("GameEvents"):WaitForChild("Remove_Item")

	-- cari + equip Shovel dulu (server nolak kalau ga pegang shovel)
	local function findShovel()
		for _, where in ipairs({ LP.Character, LP:FindFirstChildOfClass("Backpack") }) do
			if where then
				for _, t in ipairs(where:GetChildren()) do
					if t:IsA("Tool") and tostring(t.Name):find("Shovel") then return t end
				end
			end
		end
	end
	local function heldShovel()
		local char = LP.Character
		if not char then return nil end
		for _, t in ipairs(char:GetChildren()) do
			if t:IsA("Tool") and tostring(t.Name):find("Shovel") then return t end
		end
	end
	local function equipShovel()
		local char = LP.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if not hum then return false end
		if heldShovel() then return true end
		local sh = findShovel()
		if not sh then return false end
		pcall(function() hum:EquipTool(sh) end)
		task.wait(0.2)
		return heldShovel() ~= nil
	end

	-- Guard (mirip reclaimer): selama shovel aktif, Shovel WAJIB tetap kepegang.
	-- Kalau user pindah manual ke tool lain, langsung equip ulang (cek 0.25s).
	local guardRunning = false
	local function ensureGuard()
		if guardRunning then return end
		guardRunning = true
		task.spawn(function()
			while (CFG.shovelTreeEnabled or CFG.shovelFruitEnabled) and ctx.alive() do
				if not heldShovel() then equipShovel() end
				task.wait(0.25)
			end
			guardRunning = false
		end)
	end

	-- attribute fruit yang BUKAN mutasi (metadata) — dibuang pas listing opsi mutasi
	local NOT_MUTATION = {
		FruitVersion = true, MaxAge = true, GrowRateMulti = true, WeightMulti = true,
		DoneGrowTime = true, FruitSpawnIndex = true, OfflineGrowthTarget = true,
		MasteryGrowthMulti = true, MasterySizeMulti = true,
	}

	local function optionsFrom(names, allLabel)
		local out = { { value = "All", display = allLabel or "All" } }
		for _, n in ipairs(names) do out[#out + 1] = { value = n, display = n } end
		return out
	end

	-- iterasi plant di kebun MILIK SENDIRI. KRITIS: shovel nyabut tanaman -> JANGAN sampai
	-- kena kebun pemain lain. Semua garden namanya "Farm", dibedain lewat Important.Data.Owner.
	local function myGarden()
		local ok, GetFarm = pcall(function() return require(RS.Modules.GetFarm) end)
		if ok and GetFarm then local ok2, f = pcall(function() return GetFarm(LP) end); if ok2 and f then return f end end
		local Farm = workspace:FindFirstChild("Farm"); if not Farm then return nil end
		for _, g in ipairs(Farm:GetChildren()) do
			local d = g:FindFirstChild("Important") and g.Important:FindFirstChild("Data")
			local o = d and d:FindFirstChild("Owner")
			if o and o.Value == LP.Name then return g end
		end
		return nil
	end
	local function eachPlant(fn)
		local g = myGarden(); local imp = g and g:FindFirstChild("Important")
		local pp = imp and imp:FindFirstChild("Plants_Physical")
		if not pp then return end
		for _, plant in ipairs(pp:GetChildren()) do fn(plant) end
	end

	-- shovel SELURUH plant (Remove_Item di part plant)
	local function shovel(plant)
		local part = plant.PrimaryPart or plant:FindFirstChildWhichIsA("BasePart")
		if part then pcall(function() Remove:FireServer(part) end) end
	end
	-- shovel 1 BUAH aja (Remove_Item di part buah -> plant tetap)
	local function shovelFruit(fruit)
		local part = fruit.PrimaryPart or fruit:FindFirstChildWhichIsA("BasePart")
		if part then pcall(function() Remove:FireServer(part) end) end
	end

	----------------------------------------------------------------- opsi (buat UI)
	local function catalog()
		local ok, t = pcall(function() return require(RS.Data.SeedShopData) end)
		local names = {}
		if ok and type(t) == "table" then
			for k in pairs(t) do local n = tostring(k); if n ~= "RefreshTime" and n ~= "Gear" then names[#names + 1] = n end end
			table.sort(names)
		end
		return names
	end
	function ctx.getShovelTreeOptions()  return optionsFrom(catalog(), "All (semua plant)") end
	function ctx.getShovelFruitOptions() return optionsFrom(catalog(), "All (semua fruit)") end
	function ctx.getShovelVariantOptions()
		-- kumpulin variant yg ADA di garden + base
		local set = { Normal = true, Gold = true, Rainbow = true }
		eachPlant(function(plant)
			local fr = plant:FindFirstChild("Fruits")
			if fr then for _, f in ipairs(fr:GetChildren()) do
				local v = f:FindFirstChild("Variant"); if v and v.Value ~= "" then set[tostring(v.Value)] = true end
			end end
		end)
		local names = {} for k in pairs(set) do names[#names + 1] = k end; table.sort(names)
		return optionsFrom(names, "All (semua variant)")
	end
	function ctx.getShovelMutationOptions()
		-- daftar LENGKAP semua mutasi buah dari registry (MutationHandler.MutationNames)
		local ok, MH = pcall(function() return require(RS.Modules.MutationHandler) end)
		local names = {}
		if ok and MH and type(MH.MutationNames) == "table" then
			local mn = MH.MutationNames
			if mn[1] ~= nil then for _, v in ipairs(mn) do names[#names + 1] = tostring(v) end
			else for k in pairs(mn) do names[#names + 1] = tostring(k) end end
			table.sort(names)
		end
		return optionsFrom(names, "All (semua mutasi)")
	end
	function ctx.getShovelModeOptions() return { ">= (berat minimal)", "<= (berat maksimal)" } end

	----------------------------------------------------------------- cek fruit cocok filter
	local function fruitMatches(f)
		local sel  = CFG.shovelFruitNames or {}
		local muts = CFG.shovelFruitMuts or {}
		local vars = CFG.shovelFruitVariants or {}
		-- tipe
		if not (next(sel) == nil or sel["All"] or sel[f.Name]) then return false end
		-- variant
		if not (next(vars) == nil or vars["All"]) then
			local fv = f:FindFirstChild("Variant")
			local vn = fv and tostring(fv.Value) or "Normal"
			if not vars[vn] then return false end
		end
		-- mutasi (fruit harus punya salah satu mutasi terpilih)
		if not (next(muts) == nil or muts["All"]) then
			local hit = false
			for m in pairs(muts) do if m ~= "All" and f:GetAttribute(m) == true then hit = true; break end end
			if not hit then return false end
		end
		-- berat vs threshold
		local thr = tonumber(CFG.shovelFruitWeight) or 0
		if thr > 0 then
			local w = f:FindFirstChild("Weight")
			local wv = w and tonumber(w.Value) or 0
			local mode = CFG.shovelFruitMode or ">="
			if mode:find("<=") then if not (wv <= thr) then return false end
			else if not (wv >= thr) then return false end end
		end
		return true
	end

	----------------------------------------------------------------- loop: shovel tree/plant
	local function treeLoop()
		ctx.state.shovelTreeId = (ctx.state.shovelTreeId or 0) + 1
		local myId = ctx.state.shovelTreeId
		ctx.elevate()
		while CFG.shovelTreeEnabled and ctx.alive() and ctx.state.shovelTreeId == myId do
			if not equipShovel() then
				ctx.setStatus("Auto Shovel Tree: Shovel ga ada / gagal equip")
				task.wait(math.max(1, tonumber(CFG.shovelTreeDelay) or 0))
			else
				local sel = CFG.shovelTreeNames or {}
				local all = sel["All"]
				local n = 0
				eachPlant(function(plant)
					if not CFG.shovelTreeEnabled or ctx.state.shovelTreeId ~= myId then return end
					if all or sel[plant.Name] then
						shovel(plant); n = n + 1; task.wait(0.12)
					end
				end)
				ctx.setStatus(("Auto Shovel Tree: cabut %d plant"):format(n))
				task.wait(math.max(0.5, tonumber(CFG.shovelTreeDelay) or 0) + 0.5)
			end
		end
	end

	----------------------------------------------------------------- loop: shovel fruit
	local function fruitLoop()
		ctx.state.shovelFruitId = (ctx.state.shovelFruitId or 0) + 1
		local myId = ctx.state.shovelFruitId
		ctx.elevate()
		while CFG.shovelFruitEnabled and ctx.alive() and ctx.state.shovelFruitId == myId do
			if not equipShovel() then
				ctx.setStatus("Auto Shovel Fruit: Shovel ga ada / gagal equip")
				task.wait(math.max(1, tonumber(CFG.shovelFruitDelay) or 0))
			else
				local n = 0
				eachPlant(function(plant)
					if not CFG.shovelFruitEnabled or ctx.state.shovelFruitId ~= myId then return end
					local fr = plant:FindFirstChild("Fruits")
					if not fr then return end
					-- hapus TIAP buah yg cocok filter (plant tetap ada)
					for _, f in ipairs(fr:GetChildren()) do
						if not CFG.shovelFruitEnabled or ctx.state.shovelFruitId ~= myId then break end
						if fruitMatches(f) then shovelFruit(f); n = n + 1; task.wait(0.12) end
					end
				end)
				ctx.setStatus(("Auto Shovel Fruit: cabut %d buah"):format(n))
				task.wait(math.max(0.5, tonumber(CFG.shovelFruitDelay) or 0) + 0.5)
			end
		end
	end

	function ctx.startShovelTree()  equipShovel(); ensureGuard(); task.spawn(treeLoop) end
	function ctx.stopShovelTree()   ctx.state.shovelTreeId = (ctx.state.shovelTreeId or 0) + 1 end
	function ctx.startShovelFruit() equipShovel(); ensureGuard(); task.spawn(fruitLoop) end
	function ctx.stopShovelFruit()  ctx.state.shovelFruitId = (ctx.state.shovelFruitId or 0) + 1 end
end
]=],
	["modules/farm/automation_sprinkler.lua"] = [=[
--[[ automation_sprinkler.lua — Auto Sprinkler + Sprinkler Shovel (Farm).
     Pasang sprinkler:  equip tool sprinkler -> SprinklerService:FireServer("Create", CFrame)
     Cabut sprinkler:   equip Shovel        -> DeleteObject:FireServer(sprinklerModel)
     Sprinkler & jumlah dari Backpack tool "<Nama> Sprinkler x<jumlah>".
     Posisi pasang: kalau "Sprinkler Plants" dipilih -> di posisi plant itu;
                    kalau kosong -> Position mode (Random / Player Position).
     Fungsi: ctx.getSprinklerOptions / ctx.getSprinklerPlantOptions /
             ctx.getShovelSprinklerOptions / ctx.startSprinkler / ctx.startShovelSprinkler ]]
return function(ctx)
	local LP  = ctx.LP
	local CFG = ctx.CFG
	local RS  = game:GetService("ReplicatedStorage")
	local GE  = RS:WaitForChild("GameEvents")
	local SprinklerService = GE:WaitForChild("SprinklerService")
	local DeleteObject     = GE:WaitForChild("DeleteObject")
	local function setStatus(s) ctx.setStatus(s) end

	local function myFarm()
		local ok, GetFarm = pcall(function() return require(RS.Modules.GetFarm) end)
		if ok and GetFarm then local ok2, f = pcall(function() return GetFarm(LP) end); if ok2 then return f end end
		return nil
	end
	local function important() local f = myFarm(); return f and f:FindFirstChild("Important") end
	local function plantsFolder() local imp = important(); return imp and imp:FindFirstChild("Plants_Physical") end
	local function objectsFolder() local imp = important(); return imp and imp:FindFirstChild("Objects_Physical") end
	local function canPlantParts()
		local imp = important(); local pl = imp and imp:FindFirstChild("Plant_Locations")
		local parts = {}
		if pl then for _, p in ipairs(pl:GetChildren()) do if p:IsA("BasePart") then parts[#parts + 1] = p end end end
		return parts
	end

	----------------------------------------------------------------- inventory sprinkler
	local function sprinklerBase(t) return t:IsA("Tool") and t.Name:match("^(.- Sprinkler) x%d+") or nil end
	-- name -> jumlah (dari Backpack + Character)
	local function sprinklerInventory()
		local out = {}
		for _, where in ipairs({ LP:FindFirstChild("Backpack"), LP.Character }) do
			if where then for _, t in ipairs(where:GetChildren()) do
				local b = sprinklerBase(t)
				if b then out[b] = (out[b] or 0) + (tonumber(t.Name:match("x(%d+)$")) or 0) end
			end end
		end
		return out
	end
	local function sprinklerOptions()
		local inv = sprinklerInventory()
		-- prune sprinkler terpilih yg stok-nya udah 0
		local sel = CFG.sprinklerNames
		if type(sel) == "table" then
			local changed = false
			for nm in pairs(sel) do if (inv[nm] or 0) <= 0 then sel[nm] = nil; changed = true end end
			if changed and ctx.persistState then pcall(ctx.persistState) end
		end
		local names = {}
		for n, q in pairs(inv) do if q > 0 then names[#names + 1] = n end end
		table.sort(names)
		local out = {}
		for _, n in ipairs(names) do out[#out + 1] = { value = n, display = ("%s (%d)"):format(n, inv[n]) } end
		return out
	end
	ctx.getSprinklerOptions = sprinklerOptions

	-- jenis plant unik di garden (buat "place near plants") + "All"
	function ctx.getSprinklerPlantOptions()
		local out = { { value = "All", display = "All (semua plant)" } }
		local pf = plantsFolder()
		if pf then
			local seen, names = {}, {}
			for _, m in ipairs(pf:GetChildren()) do if m.Name and not seen[m.Name] then seen[m.Name] = true; names[#names + 1] = m.Name end end
			table.sort(names)
			for _, n in ipairs(names) do out[#out + 1] = { value = n, display = n } end
		end
		return out
	end

	-- Opsi shovel: gabungan jenis sprinkler yg kamu punya (inventory) + yg lagi
	-- terpasang, + "All". Daftar dari inventory bikin stabil (ga ilang pas objek
	-- expire). Sekalian prune pilihan yg jenisnya udah ga ada sama sekali.
	function ctx.getShovelSprinklerOptions()
		local set = {}
		for n in pairs(sprinklerInventory()) do set[n] = true end
		local of = objectsFolder()
		if of then for _, o in ipairs(of:GetChildren()) do
			local ty = o:GetAttribute("OBJECT_TYPE") or o.Name
			if ty then set[ty] = true end
		end end
		local sel = CFG.shovelSprinklerNames
		if type(sel) == "table" then
			local changed = false
			for nm in pairs(sel) do if nm ~= "All" and not set[nm] then sel[nm] = nil; changed = true end end
			if changed and ctx.persistState then pcall(ctx.persistState) end
		end
		local names = {}
		for n in pairs(set) do names[#names + 1] = n end
		table.sort(names)
		local out = { { value = "All", display = "All (semua terpasang)" } }
		for _, n in ipairs(names) do out[#out + 1] = { value = n, display = n } end
		return out
	end

	----------------------------------------------------------------- equip helper
	local function heldName() local c = LP.Character; local t = c and c:FindFirstChildOfClass("Tool"); return t and t.Name end
	local function equipByPredicate(pred)
		local c = LP.Character
		if c then for _, t in ipairs(c:GetChildren()) do if t:IsA("Tool") and pred(t) then return true end end end
		local bp = LP:FindFirstChild("Backpack")
		if bp then for _, t in ipairs(bp:GetChildren()) do if t:IsA("Tool") and pred(t) then
			local hum = c and c:FindFirstChildOfClass("Humanoid"); if hum then pcall(function() hum:EquipTool(t) end) end
			break
		end end end
		if c then for _, t in ipairs(c:GetChildren()) do if t:IsA("Tool") and pred(t) then return true end end end
		return false
	end
	local function equipSprinkler(name) return equipByPredicate(function(t) return sprinklerBase(t) == name end) end
	local function equipShovel() return equipByPredicate(function(t) return t.Name == "Shovel [Destroy Plants]" or t.Name:match("^Shovel") end) end

	----------------------------------------------------------------- posisi
	local function randomPos()
		local parts = canPlantParts(); if #parts == 0 then return nil end
		local p = parts[math.random(1, #parts)]
		local hx, hz = p.Size.X / 2 - 1, p.Size.Z / 2 - 1
		return Vector3.new(p.Position.X + (math.random() * 2 - 1) * hx, p.Position.Y, p.Position.Z + (math.random() * 2 - 1) * hz)
	end
	local function playerPos()
		local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart"); if not hrp then return nil end
		local parts = canPlantParts(); local y = parts[1] and parts[1].Position.Y or 0
		return Vector3.new(hrp.Position.X, y, hrp.Position.Z)
	end
	-- posisi plant yg tipenya dipilih (buat "place near plants")
	local function plantPositions(sel)
		local out = {}
		local pf = plantsFolder(); if not pf then return out end
		local all = sel["All"]
		for _, m in ipairs(pf:GetChildren()) do
			if all or sel[m.Name] then
				local piv = m:GetPivot(); out[#out + 1] = Vector3.new(piv.X, piv.Y, piv.Z)
			end
		end
		return out
	end

	----------------------------------------------------------------- loop PASANG
	local function sprinklerLoop(myId)
		ctx.elevate()
		while CFG.sprinklerEnabled and ctx.alive() and ctx.state.sprinklerId == myId do
			local selSpr = CFG.sprinklerNames or {}
			local inv = sprinklerInventory()
			-- daftar tipe sprinkler terpilih yg masih ada stok (urut stabil)
			local types = {}
			for n in pairs(selSpr) do if (inv[n] or 0) > 0 then types[#types + 1] = n end end
			table.sort(types)
			if #types == 0 then
				setStatus("Sprinkler: pilih sprinkler (stok kosong?)")
			else
				-- posisi target
				local plantsSel = CFG.sprinklerPlantNames or {}
				local positions
				if next(plantsSel) then
					positions = plantPositions(plantsSel)
				else
					local mode = CFG.sprinklerPosition == "Player Position" and "Player Position" or "Random"
					positions = { mode == "Player Position" and playerPos() or randomPos() }
				end
				local placed = 0
				for _, pos in ipairs(positions) do
					if not CFG.sprinklerEnabled or ctx.state.sprinklerId ~= myId then break end
					if pos then
						-- rotasi 1-1 antar tipe, indeks persist antar-siklus (biar ga tipe pertama terus)
						ctx.state.sprRotIdx = (ctx.state.sprRotIdx or 0) % #types + 1
						local name = types[ctx.state.sprRotIdx]
						if equipSprinkler(name) then
							pcall(function() SprinklerService:FireServer("Create", CFrame.new(pos)) end)
							placed = placed + 1
							task.wait(tonumber(CFG.sprinklerDelay) or 0)
						end
					end
				end
				setStatus(("Sprinkler: pasang %d"):format(placed))
			end
			task.wait(1)
		end
	end
	function ctx.startSprinkler()
		ctx.state.sprinklerId = (ctx.state.sprinklerId or 0) + 1
		local myId = ctx.state.sprinklerId
		task.spawn(function() sprinklerLoop(myId) end)
	end

	----------------------------------------------------------------- loop CABUT (shovel)
	local function shovelLoop(myId)
		ctx.elevate()
		while CFG.shovelSprinklerEnabled and ctx.alive() and ctx.state.shovelSprId == myId do
			local sel = CFG.shovelSprinklerNames or {}
			local of = objectsFolder()
			if of and next(sel) then
				local all = sel["All"]
				equipShovel()
				local removed = 0
				for _, o in ipairs(of:GetChildren()) do
					if not CFG.shovelSprinklerEnabled or ctx.state.shovelSprId ~= myId then break end
					local ty = o:GetAttribute("OBJECT_TYPE") or o.Name
					if all or sel[ty] then
						pcall(function() DeleteObject:FireServer(o) end)
						removed = removed + 1
						task.wait(tonumber(CFG.shovelSprinklerDelay) or 0)
					end
				end
				setStatus(("Shovel Sprinkler: cabut %d"):format(removed))
			else
				setStatus("Shovel Sprinkler: pilih sprinkler dulu")
			end
			task.wait(1)
		end
	end
	function ctx.startShovelSprinkler()
		ctx.state.shovelSprId = (ctx.state.shovelSprId or 0) + 1
		local myId = ctx.state.shovelSprId
		task.spawn(function() shovelLoop(myId) end)
	end
end
]=],
	["modules/farm/automation_water.lua"] = [=[
--[[ automation_water.lua — Auto Water Fruits.
     Siram plant terpilih pakai Watering Can. Mekanisme (dari remote spy):
       Water_RE:FireServer(plant:GetPivot().Position)
     Ga perlu equip can — server auto-decrement uses dari Watering Can di inventory.
     Loop tiap CFG.waterDelay detik, cuma siram plant yang tipenya ada di CFG.waterFruitNames
     (atau "All"). Plant ada di workspace.Farm.<garden>.Important.Plants_Physical (nama = tipe fruit). ]]
return function(ctx)
	local RS  = game:GetService("ReplicatedStorage")
	local CFG = ctx.CFG
	local LP  = ctx.LP
	local Water = RS:WaitForChild("GameEvents"):WaitForChild("Water_RE")

	-- cari Watering Can (prioritas regular = uses banyak; fallback Super/Sugar/apapun)
	local function findCan()
		local best, fallback
		for _, where in ipairs({ LP.Character, LP:FindFirstChildOfClass("Backpack") }) do
			if where then
				for _, t in ipairs(where:GetChildren()) do
					local n = tostring(t.Name)
					if t:IsA("Tool") and n:find("Watering Can") then
						if not n:find("Super") and not n:find("Sugar") then best = best or t
						else fallback = fallback or t end
					end
				end
			end
		end
		return best or fallback
	end

	local function heldCan()
		local char = LP.Character
		if not char then return nil end
		for _, t in ipairs(char:GetChildren()) do
			if t:IsA("Tool") and tostring(t.Name):find("Watering Can") then return t end
		end
	end
	-- pastiin Watering Can ke-equip (server nyiram cuma pas can dipegang)
	local function equipCan()
		local char = LP.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if not hum then return false end
		if heldCan() then return true end
		local can = findCan()
		if not can then return false end
		pcall(function() hum:EquipTool(can) end)
		task.wait(0.2)
		return heldCan() ~= nil
	end

	-- Guard (mirip reclaimer): selama auto water aktif, Watering Can WAJIB tetap kepegang.
	-- Kalau user pindah manual ke tool lain, langsung equip ulang (cek 0.25s).
	local guardRunning = false
	local function ensureGuard()
		if guardRunning then return end
		guardRunning = true
		task.spawn(function()
			while CFG.waterEnabled and ctx.alive() do
				if not heldCan() then equipCan() end
				task.wait(0.25)
			end
			guardRunning = false
		end)
	end

	-- opsi fruit = katalog seed (semua yang bisa ditanam). Format sama kayak shop.
	local function optionsFrom(names)
		local out = { { value = "All", display = "All (siram semua)" } }
		for _, n in ipairs(names) do out[#out + 1] = { value = n, display = n } end
		return out
	end
	function ctx.getWaterFruitOptions()
		local ok, t = pcall(function() return require(RS.Data.SeedShopData) end)
		local names = {}
		if ok and type(t) == "table" then
			for k in pairs(t) do
				local n = tostring(k)
				if n ~= "RefreshTime" and n ~= "Gear" then names[#names + 1] = n end
			end
			table.sort(names)
		end
		return optionsFrom(names)
	end

	-- iterasi plant di kebun MILIK SENDIRI. Semua garden namanya "Farm", dibedain lewat
	-- Important.Data.Owner -> skip-CommunityGarden aja kesapu kebun pemain lain (bug).
	local function myGarden()
		local ok, GetFarm = pcall(function() return require(RS.Modules.GetFarm) end)
		if ok and GetFarm then local ok2, f = pcall(function() return GetFarm(LP) end); if ok2 and f then return f end end
		local Farm = workspace:FindFirstChild("Farm"); if not Farm then return nil end
		for _, g in ipairs(Farm:GetChildren()) do
			local d = g:FindFirstChild("Important") and g.Important:FindFirstChild("Data")
			local o = d and d:FindFirstChild("Owner")
			if o and o.Value == LP.Name then return g end
		end
		return nil
	end
	local function eachPlant(fn)
		local g = myGarden(); local imp = g and g:FindFirstChild("Important")
		local pp = imp and imp:FindFirstChild("Plants_Physical")
		if not pp then return end
		for _, plant in ipairs(pp:GetChildren()) do fn(plant) end
	end

	local function waterLoop()
		ctx.state.waterId = (ctx.state.waterId or 0) + 1
		local myId = ctx.state.waterId
		ctx.elevate()
		while CFG.waterEnabled and ctx.alive() and ctx.state.waterId == myId do
			local sel = CFG.waterFruitNames or {}
			local all = sel["All"]
			local n = 0
			-- equip can dulu; kalau ga ada, kasih tau & tunggu
			if not equipCan() then
				ctx.setStatus("Auto Water: Watering Can ga ada / gagal equip")
				task.wait(math.max(1, tonumber(CFG.waterDelay) or 1))
			else
			eachPlant(function(plant)
				if not CFG.waterEnabled or ctx.state.waterId ~= myId then return end
				if all or sel[plant.Name] then
					local ok, pos = pcall(function() return plant:GetPivot().Position end)
					if ok and pos then
						pcall(function() Water:FireServer(pos) end)
						n = n + 1
						task.wait(0.05) -- jeda antar-fire biar ga flood remote
					end
				end
			end)
				ctx.setStatus(("Auto Water: siram %d plant"):format(n))
				task.wait(math.max(0.5, tonumber(CFG.waterDelay) or 1))
			end
		end
	end

	function ctx.startWater() equipCan(); ensureGuard(); task.spawn(waterLoop) end
	function ctx.stopWater() ctx.state.waterId = (ctx.state.waterId or 0) + 1 end
end
]=],
	["modules/growth/automation_growth.lua"] = [=[
--[[ growth.lua — Growth pipeline (BATCH per-step): jalankan target pet lewat urutan
     step (default Elephant -> Mutation -> Leveling), semua pet kelar 1 step baru lanjut.
     Config TERPISAH dari fitur standalone (growth*).
     Step & kriteria "complete":
       elephant : BaseWeight >= growthElephantWeight
       mutation : dapat salah satu growthMutationTargets (aura team; mutasi salah -> shard)
       leveling : Level >= growthLevP2Target (2 phase: P1 team -> P2 team)
     Saat ganti step/phase: bersihin garden TOTAL dulu -> pasang team baru (lengkap) -> proses. ]]
return function(ctx)
	local DataService = ctx.deps.DataService
	local PetsService = ctx.deps.PetsService
	local CFG = ctx.CFG
	local LP  = ctx.LP
	local RS  = game:GetService("ReplicatedStorage")
	local PetShardService = RS:WaitForChild("GameEvents"):WaitForChild("PetShardService_RE")
	local mutDisplay = (ctx.reg and ctx.reg.mutDisplay) or function(c) return c end

	----------------------------------------------------------------- posisi grid
	local function farmCenter()
		local GetFarm = require(RS.Modules.GetFarm)
		local farm = GetFarm and GetFarm(LP)
		local pa = farm and farm:FindFirstChild("PetArea")
		if pa then return pa.Position end
		local char = LP.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		return hrp and hrp.Position or nil
	end
	local slotOf, nextSlot = {}, 0
	local function getPos(uuid)
		if not slotOf[uuid] then slotOf[uuid] = nextSlot; nextSlot = nextSlot + 1 end
		local center = farmCenter(); if not center then return nil end
		local i = slotOf[uuid]
		return center + Vector3.new((i % 6 - 2.5) * 3, 0, (math.floor(i / 6) - 1) * 3)
	end

	----------------------------------------------------------------- helper mutasi/shard
	-- pet yang di-favorite JANGAN diproses & JANGAN dihitung di step manapun
	-- (elephant/mutation/leveling). Kalau ikut dihitung, pet fav yg ga pernah beres
	-- bikin step "belum semua selesai" selamanya -> growth mandek.
	local function isFav(pd) return (pd or {}).IsFavorite == true end
	-- Flow efektif: buang step kosong/"none" (mis. cuma mau Mutation+Leveling, Step 3 dikosongin).
	local function effFlow()
    	local out = {}
    	local validSteps = {
        	elephant = true,
        	mutation = true,
        	leveling = true,
        	leveling_p1 = true,
        	leveling_p2 = true,
    	}
    	for _, s in ipairs(CFG.growthFlow or {}) do
        	if validSteps[s] then
            	out[#out + 1] = s
        	end
    	end
    	return out
	end
	-- Target pet PER-METHOD: tiap step bisa punya target beda (mis. leveling: Dilo/
	-- Lion/Mimic, mutation: Hotdog/Griffin/Mimic). Kalau set per-step kosong ->
	-- fallback ke growthPetTypes (global). Backward-compatible.
	local function typesFor(step)
    	local per
    	if step == "elephant" then
        	per = CFG.growthPetTypesElephant
    	elseif step == "mutation" then
        	per = CFG.growthPetTypesMutation
    	elseif step == "leveling_p1" then
        	per = CFG.growthPetTypesLeveling
        	if not (per and next(per)) and CFG.growthPetTypesElephant and next(CFG.growthPetTypesElephant) then
            	per = CFG.growthPetTypesElephant
        	end
    	elseif step == "leveling" or step == "leveling_p2" then
        	per = CFG.growthPetTypesLeveling
    	end
    	if per and next(per) then return per end
    	return CFG.growthPetTypes or {}
	end
	-- ada target ke-set di mana pun (global / salah satu per-step)?
	local function anyTypesSet()
		if next(CFG.growthPetTypes or {}) then return true end
		return next(CFG.growthPetTypesElephant or {}) or next(CFG.growthPetTypesMutation or {})
			or next(CFG.growthPetTypesLeveling or {}) or false
	end
	local function mutOf(pd) return mutDisplay((pd or {}).MutationType) end
	local function hasMut(pd)
		local m = (pd or {}).MutationType
		return m ~= nil and m ~= "" and m ~= "None" and m ~= "Normal"
	end
	local function findShard()
		for _, where in ipairs({ LP.Character, LP:FindFirstChildOfClass("Backpack") }) do
			if where then
				for _, t in ipairs(where:GetChildren()) do
					if t:IsA("Tool") and (t:HasTag("PetShardTool") or tostring(t.Name):find("Cleansing Pet Shard")) then return t end
				end
			end
		end
	end
	local function findPetModel(uuid)
		local pm = workspace:FindFirstChild("PetsPhysical")
		if not pm then return nil end
		for _, mover in ipairs(pm:GetChildren()) do
			local m = mover:FindFirstChild(uuid); if m then return m end
		end
	end
	local function cleansePet(uuid)
		local model = findPetModel(uuid); if not model then return end
		local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
		local shard = findShard()
		if hum and shard then pcall(function() hum:EquipTool(shard) end); task.wait(0.3) end
		local held = LP.Character and LP.Character:FindFirstChildWhichIsA("Tool")
		if held and (held:HasTag("PetShardTool") or tostring(held.Name):find("Cleansing Pet Shard")) then
			pcall(function() PetShardService:FireServer("ApplyShard", model) end)
			task.wait(0.3)
		end
	end

	----------------------------------------------------------------- kriteria complete per step
	local function stepDone(step, pd)
    	pd = pd or {}
    	if step == "elephant" then
        	return (pd.BaseWeight or 0) >= (CFG.growthElephantWeight or 3.845)
    	elseif step == "mutation" then
        	local tg = CFG.growthMutationTargets or {}
        	if not next(tg) then return true end
        	return tg[mutOf(pd)] == true
    	elseif step == "leveling" then
        	return (pd.Level or 0) >= (CFG.growthLevP2Target or 500)
    	elseif step == "leveling_p1" then
        	return (pd.Level or 0) >= (CFG.growthLevP1Target or 50)
    	elseif step == "leveling_p2" then
        	return (pd.Level or 0) >= (CFG.growthLevP2Target or 500)
    	end
    	return true
	end

	ctx.state.growthStatus = "Idle"

	----------------------------------------------------------------- ringkasan status
	function ctx.getGrowthSummary()
		local ok, d = pcall(function() return DataService:GetData() end)
		local inv = ok and d and d.PetsData and d.PetsData.PetInventory and d.PetsData.PetInventory.Data or {}
		local flow = effFlow()
		local perStep = {}
		for _, s in ipairs(flow) do perStep[s] = { done = 0, total = 0 } end
		for _, v in pairs(inv) do
			if not isFav(v.PetData) and v.PetData then   -- skip pet tanpa PetData
				for _, s in ipairs(flow) do
					if typesFor(s)[v.PetType] then
						perStep[s].total = perStep[s].total + 1
						if stepDone(s, v.PetData) then perStep[s].done = perStep[s].done + 1 end
					end
				end
			end
		end
		local function nm(t) local o = {}; for k in pairs(t or {}) do o[#o + 1] = k end; return #o > 0 and table.concat(o, ", ") or "-" end
		-- label target: kalau ada per-method di-set -> "E:.. | M:.. | L:..", else global.
		local function typesLabel()
			local e, m, l = CFG.growthPetTypesElephant or {}, CFG.growthPetTypesMutation or {}, CFG.growthPetTypesLeveling or {}
			if not (next(e) or next(m) or next(l)) then return nm(CFG.growthPetTypes) end
			return ("E:%s | M:%s | L:%s"):format(nm(typesFor("elephant")), nm(typesFor("mutation")), nm(typesFor("leveling")))
		end
		-- ringkas team: hitung per tipe pet -> "Peacock x3, Dog x2" (biar ga kepanjangan)
		local function teamNm(teamSet)
			local count, order, total = {}, {}, 0
			for uuid in pairs(teamSet or {}) do
				local v = inv[uuid]
				local pt = (v and v.PetType) or "?"
				if not count[pt] then order[#order + 1] = pt end
				count[pt] = (count[pt] or 0) + 1
				total = total + 1
			end
			if total == 0 then return "-" end
			local parts = {}
			for _, pt in ipairs(order) do
				parts[#parts + 1] = count[pt] > 1 and (pt .. " x" .. count[pt]) or pt
			end
			return ("(%d) %s"):format(total, table.concat(parts, ", "))
		end
		return {
			status = CFG.growthEnabled and "ACTIVE" or "STOPPED",
			step = ctx.state.growthStep or "-",
			flow = (#flow > 0) and table.concat(flow, " -> ") or "-",
			types = typesLabel(),
			perStep = perStep,
			teamElephant = teamNm(CFG.growthElephantTeam),
			teamMutation = teamNm(CFG.growthMutationTeam),
			teamLevP1 = teamNm(CFG.growthLevP1Team),
			teamLevP2 = teamNm(CFG.growthLevP2Team),
		}
	end

	----------------------------------------------------------------- core check
	local function checkGrowth()
		local ok, d = pcall(function() return DataService:GetData() end)
		if not ok or not d or not d.PetsData then return end
		local eq  = d.PetsData.EquippedPets or {}
		local inv = d.PetsData.PetInventory and d.PetsData.PetInventory.Data or {}
		local flow = effFlow()
		if not anyTypesSet() or #flow == 0 then
			ctx.state.growthStatus = "Growth: set target pet & flow dulu"
			return
		end

		-- STEP AKTIF = step pertama di flow yg belum selesai.
		-- Flow yang umum: leveling_p1 -> elephant -> leveling / mutation
		-- Di tahap elephant, pet levelnya ter-reset (level turun). Setelah semua pet level 50
		-- di-boost elephant dan levelnya reset, elephant tidak ada lagi target siap (level 50).
		-- Jika masih ada target pet yang belum capai target weight, sistem otomatis balik ke leveling_p1.
		local step, stepIdx
		local p1Target = CFG.growthLevP1Target or 50
		local hasElephantInFlow = false
		local hasLevP1InFlow = false
		for _, s in ipairs(flow) do
			if s == "elephant" then hasElephantInFlow = true end
			if s == "leveling_p1" then hasLevP1InFlow = true end
		end

		-- Jika flow mengandung siklus leveling_p1 + elephant:
		if hasElephantInFlow and hasLevP1InFlow then
			local tyEle = typesFor("elephant")
			local tyP1 = typesFor("leveling_p1")

			local anyNeedWeight = false
			local anyReadyLevel50 = false
			local anyNeedLevel50 = false

			for _, v in pairs(inv) do
				if v.PetData and not isFav(v.PetData) then
					local pd = v.PetData
					local lvl = pd.Level or 0
					-- Cek apakah pet target elephant butuh up weight
					if (tyEle[v.PetType] or tyP1[v.PetType]) and not stepDone("elephant", pd) then
						anyNeedWeight = true
						if lvl >= p1Target then
							anyReadyLevel50 = true
						else
							anyNeedLevel50 = true
						end
					end
				end
			end

			-- Tentukan step untuk fase siklus elephant / leveling_p1:
			local cycleStep = nil
			if anyNeedWeight then
				local cyclePhase = ctx.state.growthCyclePhase
				if not cyclePhase then
					-- Initial phase: kalau semua pet target sudah level 50 -> langsung elephant, kalau ada yg belum -> leveling_p1
					if anyReadyLevel50 and not anyNeedLevel50 then
						cyclePhase = "elephant"
					else
						cyclePhase = "leveling_p1"
					end
				end

				if cyclePhase == "leveling_p1" then
					-- Tetap di leveling_p1 sampai SEMUA pet target (yg butuh weight) sudah level >= 50
					if not anyNeedLevel50 then
						-- Selesai semua leveling_p1! Switch ke elephant
						cyclePhase = "elephant"
					end
				elseif cyclePhase == "elephant" then
					-- Tetap di elephant sampai TIDAK ADA LAGI pet level >= 50 (semua sudah ter-reset)
					if not anyReadyLevel50 then
						-- Semua pet level 50 sudah di-boost & ter-reset! Switch balik ke leveling_p1
						cyclePhase = "leveling_p1"
					end
				end
				ctx.state.growthCyclePhase = cyclePhase
				cycleStep = cyclePhase
			else
				ctx.state.growthCyclePhase = nil
			end

			for i, s in ipairs(flow) do
				if s == "leveling_p1" or s == "elephant" then
					if anyNeedWeight then
						-- Masih dalam proses weight: pilih step sesuai status kesiapan
						if s == cycleStep then
							step, stepIdx = s, i
							break
						end
						-- Jika bukan cycleStep, lewati
					else
						-- Weight sudah beres semua! leveling_p1 & elephant dianggap done, lanjut ke step berikutnya (mutation/leveling)
					end
				else
					-- Step lain (mutation, leveling, leveling_p2, dll)
					local ty = typesFor(s)
					local allDone = true
					for _, v in pairs(inv) do
						if ty[v.PetType] and v.PetData and not isFav(v.PetData) and not stepDone(s, v.PetData) then
							allDone = false
							break
						end
					end
					if not allDone then
						step, stepIdx = s, i
						break
					end
				end
			end
		else
			-- Flow standar tanpa kombinasi leveling_p1 + elephant
			for i, s in ipairs(flow) do
				local ty = typesFor(s)
				local allDone = true
				for _, v in pairs(inv) do
					if ty[v.PetType] and v.PetData and not isFav(v.PetData) and not stepDone(s, v.PetData) then
						allDone = false; break
					end
				end
				if not allDone then step, stepIdx = s, i; break end
			end
		end

		if not step then
			ctx.state.growthStep = "SELESAI"
			ctx.state.growthStatus = "Growth: semua step selesai ✓"
			if ctx.state.growthClearKey ~= "__done" then ctx.state.growthClearKey = "__done"; if ctx.clearGarden then ctx.clearGarden("Growth") end end
			return
		end

		-- target pet buat step aktif ini (per-method / fallback global)
		local types = typesFor(step)

		-- team / max / kriteria "masih perlu diproses" untuk step ini (leveling: sub-phase)
		local team, maxPets, needsWork
		local levPhase2 = false  -- true kalau step leveling lagi di Phase 2 (buat catat duration)
		local stepLabel = ("Step %d: %s"):format(stepIdx, step)
		if step == "elephant" then
			local p1Target = CFG.growthLevP1Target or 50
			team, maxPets = CFG.growthElephantTeam or {}, CFG.growthElephantMax or 2
			-- Elephant HANYA boleh ambil pet yang belum target weight DAN level >= p1Target (level 50)
			needsWork = function(pd)
				return not stepDone("elephant", pd) and (pd.Level or 0) >= p1Target
			end
		elseif step == "mutation" then
			team, maxPets = CFG.growthMutationTeam or {}, CFG.growthMutationMax or 2
			needsWork = function(pd) return not stepDone("mutation", pd) end
		elseif step == "leveling_p1" then
			local p1Target = CFG.growthLevP1Target or 50
			team, maxPets = CFG.growthLevP1Team or {}, CFG.growthLevP1Max or 3
			stepLabel = stepLabel .. " (Phase 1 - forced)"
			needsWork = function(pd)
				return (pd.Level or 0) < p1Target and not stepDone("elephant", pd)
			end
		elseif step == "leveling_p2" then
			team, maxPets = CFG.growthLevP2Team or {}, CFG.growthLevP2Max or 1
			stepLabel = stepLabel .. " (Phase 2 - forced)"
			needsWork = function(pd) return (pd.Level or 0) < (CFG.growthLevP2Target or 500) end
			levPhase2 = true
		else -- step == "leveling" (auto phase)
			local p1t = CFG.growthLevP1Target or 50
			local phase1 = false
			for _, v in pairs(inv) do
				if types[v.PetType] and not isFav(v.PetData) and not stepDone("leveling", v.PetData) and ((v.PetData or {}).Level or 0) < p1t then
					phase1 = true
					break
				end
			end
			if phase1 then
				team, maxPets = CFG.growthLevP1Team or {}, CFG.growthLevP1Max or 3
				stepLabel = stepLabel .. " (Phase 1 - auto)"
				needsWork = function(pd) return (pd.Level or 0) < p1t end
			else
				team, maxPets = CFG.growthLevP2Team or {}, CFG.growthLevP2Max or 1
				stepLabel = stepLabel .. " (Phase 2 - auto)"
				needsWork = function(pd) return not stepDone("leveling", pd) end
				levPhase2 = true
			end
		end
		ctx.state.growthStep = stepLabel

		-- Kirim webhook "enabled" SEKALI pas MASUK step baru (mis. enable -> elephant duluan).
		if ctx.state.growthLastStepName ~= step then
			ctx.state.growthLastStepName = step
			if step == "elephant" and ctx.webhookElephant and ctx.webhookElephant.sendEnabled then
				pcall(function() ctx.webhookElephant.sendEnabled(ctx) end)
			end
			-- leveling: TIDAK kirim webhook "enabled" pas masuk step; cuma pas pet beres (sendFinished).
			-- mutation (aura/cleanse) ga punya sendEnabled -> notif cuma per pet dapat mutasi
		end

		local localEq = {}
		for _, uuid in ipairs(eq) do localEq[uuid] = true end

		-- Transisi step/phase -> bersihin garden TOTAL dulu (verified kosong).
		if ctx.state.growthClearKey ~= nil and ctx.state.growthClearKey ~= stepLabel then
			ctx.state.growthClearing = true
		end
		ctx.state.growthClearKey = stepLabel
		if ctx.state.growthFirstRun or ctx.state.growthClearing then
			if #eq > 0 then
				ctx.state.growthStatus = ("%s: bersihin garden (%d pet)..."):format(stepLabel, #eq)
				for _, uuid in ipairs(eq) do
					pcall(function() PetsService:FireServer("UnequipPet", uuid) end)
					task.wait(0.1)
				end
				return
			end
			ctx.state.growthFirstRun = false
			ctx.state.growthClearing = false
		end

		-- Pasang team step ini + PASTIKAN LENGKAP dulu.
		local teamComplete = true
		for uuid in pairs(team) do
			if not localEq[uuid] then
				teamComplete = false
				local pos = getPos(uuid)
				if pos then pcall(function() PetsService:FireServer("EquipPet", uuid, CFrame.new(pos)) end); task.wait(0.15) end
			end
		end
		if not teamComplete then
			ctx.state.growthStatus = stepLabel .. ": nunggu team lengkap..."
			return
		end

		-- Klasifikasi target pet equipped: kalau ga perlu kerja lagi -> lepas.
		-- Khusus mutation: mutasi SALAH (bukan target) -> cleanse (shard) biar coba lagi.
		local active = {}
		for uuid in pairs(localEq) do
			if not team[uuid] then
				local v = inv[uuid]
				if v and types[v.PetType] then
					local pd = v.PetData or {}
					if pd.IsFavorite then
						-- Favorite -> JANGAN cleanse, JANGAN biarin di garden. Keluarkan.
						pcall(function() PetsService:FireServer("UnequipPet", uuid) end)
						localEq[uuid] = nil
						task.wait(0.1)
					elseif needsWork(pd) then
						if step == "mutation" and hasMut(pd) and not (CFG.growthMutationTargets or {})[mutOf(pd)] then
							cleansePet(uuid) -- mutasi salah -> cleanse
						end
						table.insert(active, uuid)
						if step == "elephant" then
							ctx.state.growthElephantStart = ctx.state.growthElephantStart or {}
							if not ctx.state.growthElephantStart[uuid] then
								ctx.state.growthElephantStart[uuid] = os.time()
							end
						elseif step == "leveling" and levPhase2 then
							-- catat mulai leveling Phase 2 (buat Duration di webhook, samain v2)
							ctx.state.growthLevStart = ctx.state.growthLevStart or {}
							if not ctx.state.growthLevStart[uuid] then
								ctx.state.growthLevStart[uuid] = os.time()
							end
						end
					else
						-- pet SELESAI step ini -> kirim webhook (template per-step)
						local pt = v.PetType
						if step == "elephant" and stepDone("elephant", pd) and ctx.webhookElephant and ctx.webhookElephant.onFinished then
							-- Durasi: dari pet masuk garden (equip) sampai lepas; nil kalau ga kecatat
							local dur
							if ctx.state.growthElephantStart and ctx.state.growthElephantStart[uuid] then
								dur = os.time() - ctx.state.growthElephantStart[uuid]
								ctx.state.growthElephantStart[uuid] = nil
							end
							pcall(function() ctx.webhookElephant.onFinished(ctx, pt, pd.BaseWeight or 0) end)
							if ctx.webhookElephant.sendFinished then
								pcall(function() ctx.webhookElephant.sendFinished(ctx, pt, pd.BaseWeight or 0, pd.MutationType, pd.Level or 0, dur) end)
							end
						elseif step == "mutation" and ctx.webhookCleanse and ctx.webhookCleanse.sendObtained then
							-- aura/cleanse webhook (bukan mutasi mesin)
							local remainsM = 0
							for _, iv in pairs(inv) do
								if types[iv.PetType] and not isFav(iv.PetData) and not stepDone("mutation", iv.PetData) then remainsM = remainsM + 1 end
							end
							pcall(function() ctx.webhookCleanse.sendObtained(ctx, pt, mutOf(pd), pd.Level or 0, remainsM) end)
						elseif step == "leveling" and stepDone("leveling", pd)
							and ctx.webhookLeveling and ctx.webhookLeveling.sendFinished then
							-- CUMA Phase 2 (reached final). Phase 1 (P1Target) ga kirim.
							local remains = 0
							for _, iv in pairs(inv) do
								if types[iv.PetType] and not isFav(iv.PetData) and not stepDone("leveling", iv.PetData) then remains = remains + 1 end
							end
							-- Duration: dari pet masuk Phase 2 sampai capai target final (nil = Unknown)
							local dur
							if ctx.state.growthLevStart and ctx.state.growthLevStart[uuid] then
								dur = os.time() - ctx.state.growthLevStart[uuid]
								ctx.state.growthLevStart[uuid] = nil
							end
							pcall(function() ctx.webhookLeveling.sendFinished(ctx, pt, mutOf(pd), pd.Level or 0, dur, remains) end)
						end
						pcall(function() PetsService:FireServer("UnequipPet", uuid) end)
						localEq[uuid] = nil
						task.wait(0.1)
					end
				else
            -- ⭐ INI PERUBAHAN PENTING: Pet bukan team dan bukan target → KELUARKAN!
            		pcall(function() PetsService:FireServer("UnequipPet", uuid) end)
            		localEq[uuid] = nil
           			task.wait(0.1)
				end
			end
		end

		-- Tambah target pet baru yg butuh kerja di step/phase ini, sampai maxPets.
		local needed = maxPets - #active
		if needed > 0 then
			local pool = {}
			for uuid, v in pairs(inv) do
				-- skip pet tanpa PetData agar tidak masuk garden secara salah
				if not localEq[uuid] and types[v.PetType] and v.PetData
					and not v.PetData.IsFavorite and needsWork(v.PetData) then
					local sortKey = v.PetData.Level or 0
					if step == "elephant" then
						sortKey = v.PetData.BaseWeight or 0
					end
					table.insert(pool, { uuid = uuid, key = sortKey })
				end
			end
			table.sort(pool, function(a, b) return a.key < b.key end)
			for i = 1, math.min(needed, #pool) do
				local pos = getPos(pool[i].uuid)
				if pos then
					pcall(function() PetsService:FireServer("EquipPet", pool[i].uuid, CFrame.new(pos)) end)
					localEq[pool[i].uuid] = true
					table.insert(active, pool[i].uuid)
					if step == "elephant" then
						ctx.state.growthElephantStart = ctx.state.growthElephantStart or {}
						ctx.state.growthElephantStart[pool[i].uuid] = os.time()
					elseif step == "leveling" and levPhase2 then
						ctx.state.growthLevStart = ctx.state.growthLevStart or {}
						ctx.state.growthLevStart[pool[i].uuid] = os.time()
					end
					task.wait(0.15)
				end
			end
		end

		ctx.state.growthStatus = ("%s: %d/%d aktif"):format(stepLabel, #active, maxPets)
	end

	----------------------------------------------------------------- loop
	local function growthLoop()
		ctx.state.growthId = (ctx.state.growthId or 0) + 1
		local myId = ctx.state.growthId
		ctx.elevate()
		ctx.state.growthFirstRun = true
		ctx.state.growthClearKey = nil
		while CFG.growthEnabled and ctx.alive() and ctx.state.growthId == myId do
			pcall(checkGrowth)
			-- pas bersihin/transisi -> cek cepat (1s) biar garden cepat bersih & lanjut;
			-- steady (proses grow/level) -> 2s (hemat, toh pet numbuh di server).
			task.wait((ctx.state.growthClearing or ctx.state.growthFirstRun) and 0.5 or 2)
		end
		ctx.state.growthStatus = "Idle"
	end

	function ctx.startGrowth()
		if ctx.cancelClearGarden then ctx.cancelClearGarden() end
		-- override config webhook elephant -> baca config GROWTH (bukan standalone)
		ctx.state.elephantCfgOverride = { team = CFG.growthElephantTeam, types = CFG.growthPetTypes, weight = CFG.growthElephantWeight }
		ctx.state.elephantWebhookPost = true -- Growth: POST pesan baru tiap pet selesai (bukan edit)
		ctx.state.growthLastStepName = nil -- reset biar step pertama kirim webhook "enabled"
		ctx.state.growthCyclePhase = nil
		task.spawn(growthLoop)
	end
	function ctx.stopGrowth()
		ctx.state.growthId = (ctx.state.growthId or 0) + 1
		ctx.state.elephantCfgOverride = nil -- balikin webhook elephant ke config standalone
		ctx.state.elephantWebhookPost = nil -- balikin webhook elephant ke mode edit (standalone)
		ctx.state.growthCyclePhase = nil
		if ctx.clearGarden then ctx.clearGarden("Growth") end
	end
end]=],
	["modules/hatch/automation_hatch.lua"] = [=[
--[[ hatch.lua — Auto Hatch + Auto Sell (Stage 1).
     - Team-swap dengan GUARD: team ga diproses kalau yg ke-equip udah sesuai.
     - Auto Hatch: equip hatch team -> hatch semua egg READY -> hitung cycle.
     - Auto Sell: pet yg COCOK filter dijual; sisanya DIFAVORITIN biar aman.
       Favorite via Favorite_Item (toggle), jual via SellPet_RE / SellAllPets_RE.
     Catatan: auto-place egg baru & bronto phase = stage berikutnya. ]]
return function(ctx)
	local RS = game:GetService("ReplicatedStorage")
	local LP = ctx.LP
	local CFG = ctx.CFG
	local DataService = ctx.deps.DataService
	local PetsRemote = RS.GameEvents.PetsService
	local FavoriteRemote = RS.GameEvents:FindFirstChild("Favorite_Item")
	local SellPet = RS.GameEvents:FindFirstChild("SellPet_RE")
	local SellAll = RS.GameEvents:FindFirstChild("SellAllPets_RE")
	local EggRemote = RS.GameEvents.PetEggService
	local FAV_KEY = "d"
	pcall(function() FAV_KEY = require(RS.Data.EnumRegistry.InventoryServiceEnums).Favorite end)

	-- LISTEN notif game = recovery ASLI (1 notif = 1 egg balik). Sumber paling akurat.
	--   Hatch: "Lucky Hatch! Your egg has been recovered."
	--   Sell : "Lucky Pet! You got a ... egg back from selling your pet!"
	do
		local g = (getgenv and getgenv()) or _G
		if g.__hatchNotifConn then pcall(function() g.__hatchNotifConn:Disconnect() end) end
		local NotifRemote = RS.GameEvents:FindFirstChild("Notification")
		if NotifRemote then
			g.__hatchNotifConn = NotifRemote.OnClientEvent:Connect(function(msg)
				if type(msg) ~= "string" or not CFG.hatchEnabled then return end
				local l = msg:lower()
				if l:find("egg has been recovered") then
					ctx.state.periodHatchRec = (ctx.state.periodHatchRec or 0) + 1
				elseif l:find("egg back from selling") then
					ctx.state.periodSellRec = (ctx.state.periodSellRec or 0) + 1
				end
			end)
		end
	end

	----------------------------------------------------------------- util
	local function getData() local ok, d = pcall(function() return DataService:GetData() end); return ok and d or nil end
	local function inventory() local d = getData(); return d and d.PetsData and d.PetsData.PetInventory and d.PetsData.PetInventory.Data or {} end
	local function equippedList() local d = getData(); return d and d.PetsData and d.PetsData.EquippedPets or {} end

	local function farmCenter()
		local GetFarm = require(RS.Modules.GetFarm)
		local farm = GetFarm and GetFarm(LP)
		local pa = farm and farm:FindFirstChild("PetArea")
		if pa then return pa.Position end
		local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
		return hrp and hrp.Position or nil
	end
	local slotOf, nextSlot = {}, 0
	local function getPos(uuid)
		if not slotOf[uuid] then slotOf[uuid] = nextSlot; nextSlot = nextSlot + 1 end
		local c = farmCenter(); if not c then return nil end
		local i = slotOf[uuid]
		return c + Vector3.new((i % 6 - 2.5) * 3, 0, (math.floor(i / 6) - 1) * 3)
	end

	----------------------------------------------------------------- TEAM + GUARD
	-- ActivePetsService: sumber pet yg beneran AKTIF (model spawn + passive kebaca).
	local ActivePets; pcall(function() ActivePets = require(RS.Modules.PetServices.ActivePetsService) end)
	-- teamSet = { [uuid]=true }. Return true kalau equipped PERSIS == teamSet.
	local function teamMatches(teamSet)
		if not next(teamSet or {}) then return true end -- team kosong = ga usah proses
		local eq = equippedList()
		local eqSet, eqN = {}, 0
		for _, u in ipairs(eq) do eqSet[u] = true; eqN = eqN + 1 end
		local tN = 0
		for u in pairs(teamSet) do if not eqSet[u] then return false end; tN = tN + 1 end
		return eqN == tN
	end
	-- Semua anggota team udah AKTIF di garden (ClientPetState) -> passive-nya kebaca.
	local function teamActive(teamSet)
		if not next(teamSet or {}) then return true end
		if not ActivePets or not ActivePets.ClientPetState then return true end -- ga bisa cek -> anggap ok
		local cps = ActivePets.ClientPetState[LP.Name]
		if not cps then return false end
		for u in pairs(teamSet) do if cps[u] == nil then return false end end
		return true
	end

	-- 1 pass: cabut non-team, pasang anggota team yg belum ke-equip.
	local function equipTeamOnce(teamSet, unequipDelay, equipDelay)
		local unDelay = tonumber(unequipDelay) or 0.1
		local eqDelay = tonumber(equipDelay) or 0.15
		local keep = {}
		for u in pairs(teamSet) do keep[u] = true end
		local hasUnequipped = false
		for _, u in ipairs(equippedList()) do
			if not keep[u] then
				pcall(function() PetsRemote:FireServer("UnequipPet", u) end)
				hasUnequipped = true
				if unDelay > 0 then task.wait(unDelay) end
			end
		end
		-- Jika ada pet yg dicabut, beri jeda sedikit agar server game membebaskan slot garden
		if hasUnequipped then task.wait(0.15) end

		local eqNow = {}
		for _, u in ipairs(equippedList()) do eqNow[u] = true end
		for u in pairs(teamSet) do
			if not eqNow[u] then
				local pos = getPos(u)
				if pos then
					pcall(function() PetsRemote:FireServer("EquipPet", u, CFrame.new(pos)) end)
					if eqDelay > 0 then task.wait(eqDelay) end
				end
			end
		end
	end

	-- Equip team: BLOK sampai team LENGKAP ter-equip (data). Boost/passive (bronto/koi/seal)
	-- diterapin server-side pas pet KE-EQUIP, BUKAN pas model kerender di client. ClientPetState
	-- (spawn model) cuma dipake sbg sinyal cepat kalau kebaca — tapi di LOW PERFORMANCE MODE
	-- model pet sering ga spawn, jadi JANGAN jadiin gate. Kalau ga kebaca aktif, tetap lanjut
	-- setelah settle delay (team udah ke-equip = boost udah masuk server).
	local function equipTeam(teamSet, label, unequipDelay, equipDelay)
		if not next(teamSet or {}) then return true end
		if teamMatches(teamSet) and teamActive(teamSet) then return true end -- fast path
		ctx.state.teamSwapActive = true
		ctx.state.hatchStatus = (label or "Team") .. ": equipping..."
		-- 1) pasang sampai data-equipped lengkap
		local ok = false
		for _ = 1, 8 do
			if teamMatches(teamSet) then ok = true; break end
			equipTeamOnce(teamSet, unequipDelay, equipDelay)
			task.wait(0.25)
		end
		if not ok then
			ctx.state.teamSwapActive = false
			return false
		end
		-- 2) best-effort tunggu pet aktif (model spawn) — poll max ~4s. Begitu kebaca, lanjut.
		for _ = 1, 20 do
			if teamActive(teamSet) then
				ctx.state.teamSwapActive = false
				return true
			end
			ctx.state.hatchStatus = (label or "Team") .. ": nunggu pet aktif..."
			task.wait(0.2)
		end
		-- 3) ga kebaca aktif (kemungkinan low-perf, model ga spawn) TAPI udah ke-equip di data.
		--    Boost server tetap kepasang -> LANJUT (jgn skip). Settle bentar buat jaga2.
		ctx.state.hatchStatus = (label or "Team") .. ": ke-equip (settle)..."
		task.wait(1.5)
		ctx.state.teamSwapActive = false
		return true
	end

	----------------------------------------------------------------- FAVORITE / SELL
	local function petTools()
		local out = {}
		local bp = LP:FindFirstChildOfClass("Backpack")
		for _, src in ipairs({ bp, LP.Character }) do
			if src then for _, t in ipairs(src:GetChildren()) do
				if t:IsA("Tool") and t:GetAttribute("PET_UUID") then out[#out + 1] = t end
			end end
		end
		return out
	end
	local function isFav(tool) return tool:GetAttribute(FAV_KEY) == true end
	local function setFav(tool, want)
		if isFav(tool) ~= want and FavoriteRemote then
			pcall(function() FavoriteRemote:FireServer(tool) end); task.wait(0.06)
		end
	end

	-- filter disimpan pakai label "Pet - Egg"; cocokin pakai label yg sama.
	local petEggLabel = (ctx.reg and ctx.reg.petEggLabel) or function(p) return p end
	-- Helper pencocokan pet ke Sell & Bronto Config list
	local function findRule(petType)
		if not CFG.hatchSellList or not next(CFG.hatchSellList) then return nil end
		local key = petEggLabel(petType)
		local ptLower = tostring(petType or ""):lower()
		local keyLower = tostring(key or ""):lower()
		for name, r in pairs(CFG.hatchSellList) do
			local nLower = tostring(name):lower()
			if name == petType or key == name or ptLower == nLower or keyLower == nLower
				or keyLower:find(nLower, 1, true) or ptLower:find(nLower, 1, true) then
				return r
			end
		end
		return nil
	end

	-- apakah pet ini termasuk yg DIJUAL (cocok filter)?
	-- PENTING: pakai berat TAMPIL (BaseWeight*(1+0.1*Level)) = yg keliatan di game/dropdown,
	-- BUKAN BaseWeight mentah (beda angka -> salah keep/favorite). Weight & Age = AND
	-- (harus dua-duanya kepenuhi; 0 = filter itu dimatiin).
	local function shouldSell(petType, pd)
		pd = pd or {}
		local age = pd.Level or 0
		local w = (pd.BaseWeight or 0) * (1 + 0.1 * age)
		local key = petEggLabel(petType)

		-- Prioritas 1: Sell & Bronto Config List terpadu (Bulk / per-pet setting)
		local rule = findRule(petType)
		if rule then
			if rule.special == true then
				return false -- Special pet (bintang aktif) mutlak disimpan (KEEP)
			end
			local targetKg = tonumber(rule.kg) or 0
			if w >= targetKg then
				return false -- Weight >= KG -> KEEP (pet aman, tetap disimpan, dan masuk ke proses Bronto)
			else
				-- Weight < KG -> mengikuti pengaturan tombol KEEP / SELL
				return rule.action == "SELL"
			end
		elseif CFG.hatchSellList and next(CFG.hatchSellList) then
			-- Pet tidak ada di list config -> KEEP (aman)
			return false
		end

		-- Fallback: config lama (Pets to Sell & Special Pets to Sell)
		if (CFG.sellPetTypes or {})[key] then
			local wt = CFG.sellWeightThreshold or 0
			local at = CFG.sellAgeThreshold or 0
			local wOk = wt <= 0 or w < wt
			local aOk = at <= 0 or age < at
			if (wt > 0 or at > 0) and wOk and aOk then return true end
		end
		if (CFG.sellSpecialTypes or {})[key] then
			local sw = CFG.sellSpecialWeight or 0
			if sw > 0 and w < sw then return true end
		end
		return false
	end

	-- Jalankan sell: pet yg keep -> favorit; pet yg dijual -> unfavorit lalu jual.
	local function doSell()
		-- GUARD: filter kosong -> batalin (biar ga ada kecelakaan)
		if not next(CFG.hatchSellList or {}) and not next(CFG.sellPetTypes or {}) and not next(CFG.sellSpecialTypes or {}) then
			ctx.state.hatchStatus = "Sell dibatalin: filter 'Pets to Sell' kosong"
			return 0
		end
		local inv = inventory()
		local keeps, sells = {}, {}
		for _, t in ipairs(petTools()) do
			local uuid = t:GetAttribute("PET_UUID")
			local v = inv[uuid]
			local pt = (v and v.PetType) or t:GetAttribute("f")
			local pd = v and v.PetData
			if isFav(t) then
				keeps[#keeps + 1] = t              -- udah favorit = MUTLAK ga dijual (walau filter cocok)
			elseif shouldSell(pt, pd) then
				sells[#sells + 1] = t
			else
				keeps[#keeps + 1] = t
			end
		end

		if CFG.sellStyle == "All at Once" then
			-- proteksi: favoritin semua keep, unfavorit yg mau dijual
			ctx.state.hatchStatus = "Selling: favorit proteksi..."
			for _, t in ipairs(keeps) do setFav(t, true) end
			for _, t in ipairs(sells) do setFav(t, false) end
			-- VERIFY: tunggu sync + cek SEMUA keep bener favorit; retry; abort kalau gagal.
			local safe = false
			for _ = 1, 4 do
				task.wait(0.5)
				local bad = {}
				for _, t in ipairs(keeps) do if t.Parent and not isFav(t) then bad[#bad + 1] = t end end
				if #bad == 0 then safe = true; break end
				ctx.state.hatchStatus = ("Verify: %d keep-pet belum favorit, retry..."):format(#bad)
				for _, t in ipairs(bad) do setFav(t, true) end
			end
			if not safe then
				ctx.state.hatchStatus = "Sell DIBATALIN: ada keep-pet belum favorit (aman, ga jadi jual)"
				return 0
			end
			if SellAll then pcall(function() SellAll:FireServer() end) end
			ctx.state.hatchSellCycles = (ctx.state.hatchSellCycles or 0) + 1
			ctx.state.hatchStatus = ("Sold all-at-once (%d matched)"):format(#sells)
			return #sells
		else
			-- One by One: cuma jual yg cocok filter, targeted (aman by design)
			ctx.state.hatchStatus = "Selling one-by-one..."
			for _, t in ipairs(sells) do
				if t.Parent then
					setFav(t, false)
					if SellPet then pcall(function() SellPet:FireServer(t, true) end) end
					task.wait(0.1)
				end
			end
			ctx.state.hatchSellCycles = (ctx.state.hatchSellCycles or 0) + 1
			ctx.state.hatchStatus = ("Sold %d pet (one by one)"):format(#sells)
			return #sells
		end
	end
	ctx.hatchDoSell = doSell -- expose buat tombol manual

	----------------------------------------------------------------- HATCH
	-- Egg ready = timer habis (TimeToHatch <= 0). Egg yg timer-nya jalan = belum ready.
	local function readyEggs()
		local GetFarm = require(RS.Modules.GetFarm); local farm = GetFarm(LP)
		local t = {}
		if farm then for _, e in ipairs(farm:GetDescendants()) do
			if e:IsA("Model") and e.Name == "PetEgg" and e:GetAttribute("OWNER") == LP.Name then
				local tth = tonumber(e:GetAttribute("TimeToHatch")) or 0
				if tth <= 0 then t[#t + 1] = e end
			end
		end end
		return t
	end
	local function backpackPetCount()
		local n = 0
		for _, t in ipairs(petTools()) do local _ = t; n = n + 1 end
		return n
	end
	local function getInventoryCapacity()
		local d = getData()
		local maxCap = d and d.PetsData and d.PetsData.MutableStats and tonumber(d.PetsData.MutableStats.MaxPetsInInventory) or 0
		local bpc = backpackPetCount()
		local inv = inventory()
		local invCount = 0
		for _ in pairs(inv) do invCount = invCount + 1 end
		local cur = math.max(bpc, invCount)
		return cur, maxCap
	end

	-- Parse nama tool egg & jumlahnya (mendukung angka positif dan minus misal "Paradise Egg x-20", "Paradise Egg -20", "x -20", "[x-20]", dll)
	local function parseEggTool(t)
		if not (t and t:IsA("Tool") and not t:GetAttribute("PET_UUID")) then
			return nil, 0
		end
		local raw = tostring(t.Name)
		local rawLower = raw:lower()
		local targetEgg = CFG.hatchEggName
		local hasEgg = rawLower:find("egg", 1, true) or (targetEgg and rawLower:find(targetEgg:lower(), 1, true))
		if not hasEgg then
			return nil, 0
		end

		-- Normalize unicode dashes/minuses ke ASCII "-"
		-- \226\128\147 = en-dash (–), \226\128\148 = em-dash (—), \226\136\146 = minus sign (−)
		local norm = raw:gsub("[\226\128\147\226\128\148\226\136\146]", "-")

		-- Cek attribute / child Value jika ada
		local attrVal = t:GetAttribute("Quantity") or t:GetAttribute("Count") or t:GetAttribute("Amount")
		if not attrVal then
			local qChild = t:FindFirstChild("Quantity") or t:FindFirstChild("Count") or t:FindFirstChild("Amount")
			if qChild and (qChild:IsA("IntValue") or qChild:IsA("NumberValue")) then
				attrVal = qChild.Value
			end
		end

		-- Ekstraksi base & count dari string
		-- Format 1: "Egg Name x-20", "Egg Name x -20", "Egg Name [X-20]", "Egg Name (x - 20)"
		local base, cnt = norm:match("^(.-)%s*[%[%(]?%s*[xX]%s*([%-+]?%s*%d+)%s*[%]%)]?$")
		-- Format 2: "Egg Name -20", "Egg Name [-20]", "Egg Name (-20)", "Egg Name - 20"
		if not cnt then
			base, cnt = norm:match("^(.-)%s*[%[%(]?%s*([%-+]%s*%d+)%s*[%]%)]?$")
		end
		-- Format 3: "Egg Name [20]" atau "Egg Name (20)"
		if not cnt then
			base, cnt = norm:match("^(.-)%s*[%[%(]%s*([%-+]?%s*%d+)%s*[%]%)]$")
		end

		if cnt then
			local num = tonumber((cnt:gsub("%s+", "")))
			if num then
				-- Bersihkan base dari bracket/tanda sisa
				base = base and base:gsub("[%[%(]%s*$", ""):match("^%s*(.-)%s*$") or raw
				return base, num
			end
		end

		-- Jika name tidak ada format angka, tapi ada attribute bernilai angka
		if attrVal and tonumber(attrVal) then
			local cleanBase = norm:match("^%s*(.-)%s*$")
			return cleanBase, tonumber(attrVal)
		end

		return norm:match("^%s*(.-)%s*$"), 1
	end

	-- Daftar egg di backpack + jumlah (buat dropdown Egg Configuration).
	function ctx.getEggBackpackOptions()
		local out = {}
		local bp = LP:FindFirstChildOfClass("Backpack")
		if bp then for _, t in ipairs(bp:GetChildren()) do
			local base, cnt = parseEggTool(t)
			if base then
				out[#out + 1] = { name = base, display = ("%s x%d"):format(base, cnt) }
			end
		end end
		table.sort(out, function(a, b) return a.name < b.name end)
		return out
	end

	----------------------------------------------------------------- PLACE EGG
	local function placedEggCount()
		local GetFarm = require(RS.Modules.GetFarm); local farm = GetFarm(LP)
		local n = 0
		if farm then for _, e in ipairs(farm:GetDescendants()) do
			if e:IsA("Model") and e.Name == "PetEgg" and e:GetAttribute("OWNER") == LP.Name then n = n + 1 end
		end end
		return n
	end
	local function plantLocPart()
		local GetFarm = require(RS.Modules.GetFarm); local farm = GetFarm(LP)
		local PL = farm and farm:FindFirstChild("Plant_Locations", true)
		if not PL then return nil end
		if PL:IsA("BasePart") then return PL end
		for _, d in ipairs(PL:GetDescendants()) do if d:IsA("BasePart") then return d end end
		return nil
	end
	-- Grid FIX & rapih: n slot, center di area, baris rata (spacing 4 studs).
	-- + sedikit baris cadangan di belakang biar tetap bisa penuh kalau ada egg nyempil.
	local function gridPositions(n)
		local p = plantLocPart(); if not p then return {} end
		n = math.max(1, n or 9)
		local SP = 4 -- jarak antar egg (min server = 3, kasih margin biar ga "Too close")
		local usableX = math.max(SP, p.Size.X - 4)
		local cols = math.max(1, math.min(n, math.floor(usableX / SP) + 1))
		-- baris = cukup buat n + 1 baris cadangan (anti-stuck, tetap rapi)
		local rows = math.ceil(n / cols) + 1
		local startX = -((cols - 1) * SP) / 2
		local startZ = -((rows - 1) * SP) / 2
		local out = {}
		for r = 0, rows - 1 do
			for c = 0, cols - 1 do
				out[#out + 1] = p.Position + Vector3.new(startX + c * SP, p.Size.Y / 2 + 0.2, startZ + r * SP)
			end
		end
		return out
	end
	-- Sebar egg ACAK di dalam area, tetap jaga jarak antar-egg biar ga "Too close".
	local function randomPositions(n)
		local p = plantLocPart(); if not p then return {} end
		n = math.max(1, n or 9)
		local SP = 4 -- jarak minimum antar egg
		local halfX = math.max(SP, p.Size.X / 2 - 2)
		local halfZ = math.max(SP, p.Size.Z / 2 - 2)
		local y = p.Size.Y / 2 + 0.2
		local out, tries = {}, 0
		-- generate lebih banyak dari n (buffer) biar tetap bisa penuh walau ada yg bentrok
		while #out < n * 2 and tries < n * 40 do
			tries = tries + 1
			local cand = p.Position + Vector3.new((math.random() * 2 - 1) * halfX, y, (math.random() * 2 - 1) * halfZ)
			local ok = true
			for _, e in ipairs(out) do
				if (Vector3.new(e.X, 0, e.Z) - Vector3.new(cand.X, 0, cand.Z)).Magnitude < SP then ok = false; break end
			end
			if ok then out[#out + 1] = cand end
		end
		return out
	end
	local function currentEggs()
		local GetFarm = require(RS.Modules.GetFarm); local farm = GetFarm(LP)
		local t = {}
		if farm then for _, e in ipairs(farm:GetDescendants()) do
			if e:IsA("Model") and e.Name == "PetEgg" and e:GetAttribute("OWNER") == LP.Name then t[#t + 1] = e end
		end end
		return t
	end
	local function slotOccupied(pos, eggs)
		for _, e in ipairs(eggs) do
			local ep = e:GetPivot().Position
			if (Vector3.new(ep.X, 0, ep.Z) - Vector3.new(pos.X, 0, pos.Z)).Magnitude < 3.5 then return true end
		end
		return false
	end
	-- return tool egg yg lagi dipegang (scan SEMUA tool, bukan cuma yg pertama) + apakah ada
	-- tool lain (pet/egg beda) yg ikut nyangkut.
	local function scanHeld(eggName)
		local char = LP.Character
		local heldEgg, otherCount = nil, 0
		if char then for _, t in ipairs(char:GetChildren()) do
			if t:IsA("Tool") then
				if not t:GetAttribute("PET_UUID") and tostring(t.Name):find(eggName, 1, true) then heldEgg = t
				else otherCount = otherCount + 1 end
			end
		end end
		return heldEgg, otherCount
	end
	local function equipEggTool(eggName)
		local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
		if not hum then return nil end
		local heldEgg, otherCount = scanHeld(eggName)
		-- udah megang egg yg bener DAN ga ada tool lain nyangkut -> ok
		if heldEgg and otherCount == 0 then return heldEgg end
		-- ada pet/egg-lain ke-pegang barengan (bug double-hold) -> lepas SEMUA biar bersih
		pcall(function() hum:UnequipTools() end); task.wait(0.15)
		local bp = LP:FindFirstChildOfClass("Backpack")
		if bp then for _, t in ipairs(bp:GetChildren()) do
			if t:IsA("Tool") and tostring(t.Name):find(eggName, 1, true) and not t:GetAttribute("PET_UUID") then
				pcall(function() hum:EquipTool(t) end); task.wait(0.35)
				-- pastiin abis equip ga ada tool lain nyusup lagi
				local eg2, oc2 = scanHeld(eggName)
				if eg2 and oc2 > 0 then pcall(function() hum:UnequipTools() end); task.wait(0.1); pcall(function() hum:EquipTool(t) end); task.wait(0.25) end
				return t
			end
		end end
		return nil
	end
	-- Isi egg RAPIH ke grid, cuma di slot yg kosong. Retry sampai penuh (target).
	local function placeEggs(target)
		local eggName = CFG.hatchEggName or "Rare Egg"
		if not equipEggTool(eggName) then ctx.state.hatchStatus = "Egg '" .. eggName .. "' ga ada di backpack"; return 0 end
		local start = placedEggCount()
		local isRandom = (CFG.hatchPlacePattern == "Random")
		-- isi slot kosong sampai TEPAT target; berhenti kalau 1 pass ga nambah (mentok)
		for _ = 1, 3 do
			if placedEggCount() >= target then break end
			local before = placedEggCount()
			-- Random: sebar ulang tiap pass (spot baru). Grid: pola tetap.
			local grid = isRandom and randomPositions(target) or gridPositions(target)
			local eggs = currentEggs()
			for _, pos in ipairs(grid) do
				if not CFG.hatchEnabled or placedEggCount() >= target then break end
				if not slotOccupied(pos, eggs) then
					equipEggTool(eggName)
					-- pastiin bener-bener MEGANG egg (scan semua tool, bukan cuma yg pertama;
					-- kadang pet hasil hatch ikut ke-pegang). Kalau ada pet nyangkut, equipEggTool
					-- di atas udah bersihin -> re-scan.
					local held = scanHeld(eggName)
					if held then
						pcall(function() EggRemote:FireServer("CreateEgg", pos) end)
						task.wait(0.3)
						eggs = currentEggs() -- refresh biar ga dobel di slot sama
						ctx.state.hatchStatus = ("Placing: %d/%d egg"):format(placedEggCount(), target)
					end
				end
			end
			if placedEggCount() <= before then break end -- ga nambah -> mentok
		end
		return placedEggCount() - start
	end
	local function unionTeam(a, b)
		local u = {}
		for k in pairs(a or {}) do u[k] = true end
		for k in pairs(b or {}) do u[k] = true end
		return u
	end

	-- Pending pet dari egg (dari SavedObjects): return petType, displayWeight (base*1.1)
	local eggSlotKey
	local function eggPending(egg)
		local uuid = egg:GetAttribute("OBJECT_UUID"); if not uuid then return nil, 0 end
		local d = getData(); local slots = d and d.SaveSlots and d.SaveSlots.AllSlots
		if not slots then return nil, 0 end
		local function fromSlot(s) local so = s and s.SavedObjects and s.SavedObjects[uuid]; return so and so.Data end
		local dt = eggSlotKey and fromSlot(slots[eggSlotKey])
		if not dt then for sn, slot in pairs(slots) do if type(slot) == "table" then local x = fromSlot(slot); if x then eggSlotKey = sn; dt = x; break end end end end
		if not dt then return nil, 0 end
		return dt.Type, (tonumber(dt.BaseWeight) or 0) * 1.1
	end

	-- Klasifikasi egg buat bronto: "skip" | "bronto" | "normal"
	local function classifyEgg(egg)
		local pt, w = eggPending(egg)
		if not pt then return "normal" end

		local key = petEggLabel(pt)

		-- 1) Prioritas 1: Sell & Bronto Config List terpadu
		local rule = findRule(pt)
		if rule then
			if rule.special == true then
				if CFG.brontoSkipSpecial then return "skip" end
				return "bronto"
			end
			local targetKg = tonumber(rule.kg) or 0
			if w >= targetKg then
				if CFG.brontoSkipSpecial then return "skip" end
				return "bronto"
			else
				return "normal"
			end
		end

		-- 2) Fallback filter lama jika ada
		local isSpecial = (CFG.brontoSpecialPets or {})[key] == true
		if isSpecial and (CFG.brontoSpecialWeight or 0) > 0 and w <= CFG.brontoSpecialWeight then isSpecial = false end
		if isSpecial and CFG.brontoSkipSpecial then return "skip" end
		local isUni = false
		if (CFG.brontoUniversalWeight or 0) > 0 and w > CFG.brontoUniversalWeight then
			local types = CFG.brontoUniversalTypes or {}
			if not next(types) or types[key] then isUni = true end
		end
		if isSpecial or isUni then return "bronto" end
		return "normal"
	end

	----------------------------------------------------------------- Hatch Alert (webhook bronto)
	local PetList; pcall(function() PetList = require(RS.Data.PetRegistry.PetList) end)
	local PetRegistry; pcall(function() PetRegistry = require(RS.Data.PetRegistry) end)
	local function petSize(eggName, petType, baseW)
		local egg = PetRegistry and PetRegistry.PetEggs and PetRegistry.PetEggs[eggName]
		local item = egg and egg.RarityData and egg.RarityData.Items and egg.RarityData.Items[petType]
		local wr = item and item.GeneratedPetData and item.GeneratedPetData.WeightRange
		if type(wr) == "table" and wr[1] and wr[2] and wr[2] > wr[1] then
			local f = (baseW - wr[1]) / (wr[2] - wr[1])
			if f < 0.33 then return "Small" elseif f < 0.7 then return "Normal" else return "Big" end
		end
		return "Normal"
	end
	-- dispWeight = berat tampil (base*1.1). Bronto = dispWeight*1.3 (+30%).
	local function sendHatchAlert(petType, eggName, dispWeight, isBrontoHatch)
		local url = (CFG.hatchWebhookUrl and CFG.hatchWebhookUrl ~= "" and CFG.hatchWebhookUrl) or CFG.webhookUrl
		if not url or url == "" or not ctx.sendWebhook then return end
		if isBrontoHatch == nil then isBrontoHatch = true end
		local finalW = isBrontoHatch and (dispWeight * 1.3) or dispWeight
		local weightStr = isBrontoHatch and (("`%.2f KG` ➜ `%.2f KG` (+30%%)"):format(dispWeight, finalW)) or (("`%.2f KG`"):format(dispWeight))
		local rule = findRule(petType)
		local isSpec = (rule and rule.special == true)
		local alertTitle = isSpec and "✦ CeszParadise — ★ SPECIAL PET Alert" or "✦ CeszParadise — 🦕 BRONTO PET Alert"
		local alertColor = isSpec and 16766720 or 5814783
		local payload = {
			content = "@everyone",
			embeds = { {
				title = alertTitle,
				color = alertColor,
				fields = {
					{
						name = "**Profile :**",
						value = ("> Username : **%s**"):format(LP.Name),
						inline = false,
					},
					{
						name = "**Hatched :**",
						value = ("> Pet Name: `%s` %s\n> Hatched From: `%s`\n> Weight: %s")
							:format(petType, isSpec and "⭐" or "", eggName, weightStr),
						inline = false,
					},
				},
				footer = {
					text = ("Server Version: %s\n%s"):format(tostring(game.PlaceVersion), os.date("%B %d | %I:%M %p")),
					icon_url = "https://raw.githubusercontent.com/milmscr/iniapa/main/cobainaja/Logo/logo_icon.png",
				},
			} },
		}
		pcall(function() ctx.sendWebhook(url, payload, ctx) end)
	end

	local function sendInventoryFullWebhook(cur, maxCap)
		local url = (CFG.hatchWebhookUrl and CFG.hatchWebhookUrl ~= "" and CFG.hatchWebhookUrl) or CFG.webhookUrl
		if not url or url == "" or not ctx.sendWebhook then return end
		local payload = {
			content = ("@everyone ⚠️ **Auto Hatch STOPPED** — Invent Max `%d/%d`"):format(cur, maxCap),
			embeds = { {
				title = "⚠️ CeszParadise — Inventory Full Alert",
				color = 16728135,
				description = ("> **Status :** `Invent Max %d/%d`\n> Auto Hatch otomatis dihentikan karena kapasitas penyimpanan pet telah mencapai batas maksimal!"):format(cur, maxCap),
				fields = {
					{
						name = "**Profile :**",
						value = ("> Username : **%s**"):format(LP.Name),
						inline = false,
					},
					{
						name = "**Inventory Statistics :**",
						value = ("> Current Pets: `%d`\n> Max Capacity: `%d`\n> Capacity Status: `Penuh (%d/%d)`"):format(cur, maxCap, cur, maxCap),
						inline = false,
					},
				},
				footer = {
					text = ("Server Version: %s\n%s"):format(tostring(game.PlaceVersion), os.date("%B %d | %I:%M %p")),
					icon_url = "https://raw.githubusercontent.com/milmscr/iniapa/main/cobainaja/Logo/logo_icon.png",
				},
			} },
		}
		pcall(function() ctx.sendWebhook(url, payload, ctx) end)
	end

	local function handleInventoryFull(cur, maxCap)
		if not CFG.hatchEnabled and ctx.state.hatchStatus and ctx.state.hatchStatus:find("Invent Max") then return end
		CFG.hatchEnabled = false
		if ctx.persistState then pcall(ctx.persistState) end
		ctx.stopHatch()
		if ctx.ui and ctx.ui.rHatchToggle then
			pcall(ctx.ui.rHatchToggle)
		end
		ctx.state.hatchPhase = ("Invent Max (%d/%d)"):format(cur, maxCap)
		ctx.state.hatchStatus = ("Auto Hatch STOPPED: Invent Max %d/%d"):format(cur, maxCap)
		if ctx.log then ctx.log(("Auto Hatch STOPPED: Invent Max %d/%d"):format(cur, maxCap)) end
		task.spawn(function()
			sendInventoryFullWebhook(cur, maxCap)
		end)
	end

	local function eggAmount(eggName)
		local n = 0
		local target = tostring(eggName or ""):lower():match("^%s*(.-)%s*$")
		if target == "" then return 0 end
		local safeTarget = target:gsub("([%%%^%$%(%)%%.%[%]%*%+%-%?])", "%%%1")
		for _, src in ipairs({ LP:FindFirstChildOfClass("Backpack"), LP.Character }) do
			if src then for _, t in ipairs(src:GetChildren()) do
				local base, cnt = parseEggTool(t)
				if base then
					local b = tostring(base):lower():match("^%s*(.-)%s*$")
					if b == target then
						n = n + cnt
					elseif b:find("%f[%a]" .. safeTarget .. "%f[%A]") then
						n = n + cnt
					end
				end
			end end
		end
		return n
	end

	local function totalEggCount(eggName)
		return eggAmount(eggName) + placedEggCount()
	end

	----------------------------------------------------------------- Auto Rejoin on Egg Threshold (Minus / Plus)
	local function sendRejoinWebhook(rType, eggName, curAmt, netResult, thresh)
		local url = CFG.webhookUrl
		if not url or url == "" or not ctx.sendWebhook then return end
		local diffStr = (type(netResult) == "number") and (("%+d"):format(netResult)) or tostring(netResult)
		local isPlus = (rType == "Plus")
		local title = isPlus and "🔄 CeszParadise — Auto Rejoin (Egg Plus)" or "🔄 CeszParadise — Auto Rejoin (Egg Minus)"
		local color = isPlus and 3066993 or 16744272
		local sign = isPlus and "+" or "-"
		local notifyText = ("auto rejoin on, %s %d (%s)"):format(eggName, curAmt, diffStr)
		local desc = isPlus
			and ("> **Status :** `%s`\n> Penambahan egg terdeteksi surplus melebihi ambang batas (`+%d`)! Melakukan auto rejoin ke server..."):format(notifyText, thresh)
			or ("> **Status :** `%s`\n> Pengurangan egg terdeteksi minus melebihi ambang batas (`-%d`)! Melakukan auto rejoin ke server..."):format(notifyText, thresh)
		local payload = {
			content = ("@everyone ⚠️ **Auto Rejoin** — `%s`"):format(notifyText),
			embeds = { {
				title = title,
				color = color,
				description = desc,
				fields = {
					{
						name = "**Profile :**",
						value = ("> Username : **%s**\n> Display : **%s**"):format(LP.Name, LP.DisplayName or LP.Name),
						inline = false,
					},
					{
						name = "**Egg Information :**",
						value = ("> Egg Name : `%s`\n> Current Egg : `%d` (`%s`)\n> Threshold : `%s%d`"):format(eggName, curAmt, diffStr, sign, thresh),
						inline = false,
					},
					{
						name = "**Action :**",
						value = "> Reconnecting to server immediately...",
						inline = false,
					},
				},
				footer = {
					text = ("Server Version: %s\n%s"):format(tostring(game.PlaceVersion), os.date("%B %d | %I:%M %p")),
					icon_url = "https://raw.githubusercontent.com/milmscr/iniapa/main/cobainaja/Logo/logo_icon.png",
				},
			} },
		}
		pcall(function() ctx.sendWebhook(url, payload, ctx) end)
	end

	function ctx.testRejoinWebhook()
		local eggName = CFG.hatchEggName or "Paradise Egg"
		local thresh = math.abs(tonumber(CFG.hatchRejoinMinusThreshold) or 20)
		sendRejoinWebhook("Minus", eggName, 200, -thresh, thresh)
	end

	function ctx.testRejoinPlusWebhook()
		local eggName = CFG.hatchEggName or "Paradise Egg"
		local thresh = math.abs(tonumber(CFG.hatchRejoinPlusThreshold) or 20)
		sendRejoinWebhook("Plus", eggName, 220, thresh, thresh)
	end

	local function sendStartHatchWebhook()
		local url = CFG.webhookUrl
		if not url or url == "" or not ctx.sendWebhook then return end
		local eggName = CFG.hatchEggName or "Rare Egg"
		local eggBefore = ctx.state.hatchEggBefore or 0
		local bpc = 0
		for _, t in ipairs((function() local o={}; local bp=LP:FindFirstChildOfClass("Backpack"); for _,src in ipairs({bp,LP.Character}) do if src then for _,c in ipairs(src:GetChildren()) do if c:IsA("Tool") and c:GetAttribute("PET_UUID") then o[#o+1]=c end end end end; return o end)()) do bpc=bpc+1 end
		local maxBp = 0
		pcall(function() local d = require(game:GetService("ReplicatedStorage").Modules.GetData)(LP); if d then maxBp = tonumber(d.PetsData.MutableStats.MaxPetsInInventory) or 0 end end)
		local rec = ctx.getRecoveryStat and ctx.getRecoveryStat() or {}
		local payload = {
			embeds = { {
				title = "🥚 CeszParadise — Auto Hatch Started",
				color = 3066993,
				description = "> **Auto Hatch** telah dimulai! Memulai siklus hatching otomatis...",
				fields = {
					{
						name = "**Profile :**",
						value = ("> Username : **%s**\n> Display : **%s**"):format(LP.Name, LP.DisplayName or LP.Name),
						inline = false,
					},
					{
						name = "**Egg Info :**",
						value = ("> Egg Name : `%s`\n> Egg Before : `%d`\n> Max Placed : `%d`"):format(eggName, eggBefore, CFG.hatchMaxPlaced or 8),
						inline = false,
					},
					{
						name = "**Inventory :**",
						value = ("> Pet on Backpack : `%d/%d`"):format(bpc, maxBp),
						inline = false,
					},
					{
						name = "**Recovery Stat :**",
						value = ("> Koi (hatch) : `%d ekor → %.1f%%`\n> Seal (sell) : `%d ekor → %.1f%%`"):format(
							(rec.koiCount or 0), (rec.koiPct or 0),
							(rec.sealCount or 0), (rec.sealPct or 0)),
						inline = false,
					},
					{
						name = "**Sell Config :**",
						value = ("> Sell Mode : `%s`\n> Sell Style : `%s`\n> Sell Every : `%d cycles`"):format(
							CFG.sellMode or "Cycle", CFG.sellStyle or "All at Once", CFG.sellEveryNCycles or 1),
						inline = false,
					},
				},
				footer = {
					text = ("Server Version: %s\n%s"):format(tostring(game.PlaceVersion), os.date("%B %d | %I:%M %p")),
					icon_url = "https://raw.githubusercontent.com/milmscr/iniapa/main/cobainaja/Logo/logo_icon.png",
				},
			} },
		}
		pcall(function() ctx.sendWebhook(url, payload, ctx) end)
	end

	local function checkEggThreshold()
		local eggName = CFG.hatchEggName or "Rare Egg"
		local curAmt = totalEggCount(eggName)
		local eggBefore = ctx.state.hatchEggBefore or 0

		-- Inisialisasi hatchEggBefore jika belum ada atau saat ganti egg
		if ctx.state.lastTrackedEggName ~= eggName then
			ctx.state.lastTrackedEggName = eggName
			ctx.state.hatchEggBefore = curAmt
			eggBefore = curAmt
		elseif (not ctx.state.hatchEggBefore or ctx.state.hatchEggBefore == 0) and curAmt > 0 and CFG.hatchEnabled then
			ctx.state.hatchEggBefore = curAmt
			eggBefore = curAmt
		end

		local netResult = curAmt - eggBefore

		-- 1. Cek THRESHOLD EGG MINUS (berkurang)
		if CFG.hatchRejoinMinusEnabled then
			local minusThresh = math.abs(tonumber(CFG.hatchRejoinMinusThreshold) or 20)
			if minusThresh <= 0 then minusThresh = 20 end

			-- netResult minus melebihi threshold (misal: netResult <= -20)
			if eggBefore > 0 and netResult <= -minusThresh then
				return true, "Minus", eggName, curAmt, netResult, minusThresh
			end

			-- Tool stack egg itu sendiri minus di backpack (misal: curAmt <= -20)
			if curAmt <= -minusThresh then
				return true, "Minus", eggName, curAmt, curAmt, minusThresh
			end

			-- Cek jika ada tool egg lain di inventory dengan stack minus
			local counts = {}
			for _, src in ipairs({ LP:FindFirstChildOfClass("Backpack"), LP.Character }) do
				if src then
					for _, t in ipairs(src:GetChildren()) do
						local base, qty = parseEggTool(t)
						if base then counts[base] = (counts[base] or 0) + qty end
					end
				end
			end
			for name, qty in pairs(counts) do
				if qty <= -minusThresh then
					return true, "Minus", name, qty, qty, minusThresh
				end
			end
		end

		-- 2. Cek THRESHOLD EGG PLUS (bertambah)
		if CFG.hatchRejoinPlusEnabled then
			local plusThresh = math.abs(tonumber(CFG.hatchRejoinPlusThreshold) or 20)
			if plusThresh <= 0 then plusThresh = 20 end

			-- netResult bertambah melebihi threshold (misal: netResult >= +20)
			if eggBefore > 0 and netResult >= plusThresh then
				return true, "Plus", eggName, curAmt, netResult, plusThresh
			end
		end

		return false, nil, eggName, curAmt, netResult, 0
	end

	local function doDirectReconnect()
		if ctx.reconnect then
			pcall(ctx.reconnect)
		else
			local branch = (getgenv and getgenv().GAG_BRANCH) or _G.GAG_BRANCH or "main"
			local q = (syn and syn.queue_on_teleport) or queue_on_teleport
				or (fluxus and fluxus.queue_on_teleport) or (getgenv and getgenv().queue_on_teleport)
			if q then
				pcall(function()
					q(('if getgenv then getgenv().GAG_BRANCH=%q end loadstring(game:HttpGet("https://raw.githubusercontent.com/milmscr/iniapa/%s/cobainaja/init.lua"))()'):format(branch, branch))
				end)
			end
			task.wait(0.4)
			local TeleportService = game:GetService("TeleportService")
			local TeleportFn = TeleportService.Teleport
			local ok = pcall(function() TeleportFn(TeleportService, game.PlaceId, LP) end)
			if not ok then
				pcall(function() TeleportService:Teleport(game.PlaceId, LP) end)
			end
		end
	end

	local function handleEggRejoin(rType, eggName, curAmt, netResult, thresh)
		if ctx.state.hatchIsRejoining then return end
		ctx.state.hatchIsRejoining = true

		local diffStr = (type(netResult) == "number") and (("%+d"):format(netResult)) or tostring(netResult)
		local sign = (rType == "Plus") and "+" or "-"
		local reason = ("auto rejoin on, %s %d (%s)"):format(eggName, curAmt, diffStr)
		ctx.state.hatchPhase = "Auto Rejoin"
		ctx.state.hatchStatus = ("Rejoining (%s %d [%s])..."):format(eggName, curAmt, diffStr)
		if ctx.log then ctx.log(("[Auto Hatch] %s (Threshold: %s%d) -> Rejoining server immediately..."):format(reason, sign, thresh)) end

		-- Kirim webhook rejoin
		task.spawn(function()
			sendRejoinWebhook(rType, eggName, curAmt, netResult, thresh)
		end)

		-- Jeda 1.2 detik agar webhook selesai dikirim sebelum client disconnect
		task.wait(1.2)

		-- Eksekusi Reconnect (seperti di interval rejoin)
		doDirectReconnect()
	end

	----------------------------------------------------------------- Cycle Statistics (webhook)
	-- Team ringkas: "N Nama Lengkap" (mutasi + tipe), grup per nama.
	local function teamNames(set)
		local mutDisplay = (ctx.reg and ctx.reg.mutDisplay) or function(x) return x end
		local inv = inventory()
		local tally, order = {}, {}
		for u in pairs(set or {}) do
			local v = inv[u]
			if v then
				local pt = v.PetType or "?"
				local mut = v.PetData and v.PetData.MutationType
				local mutName = mut and mutDisplay(mut) or mut
				local name = (mut and mut ~= "" and mut ~= "Normal") and (tostring(mutName) .. " " .. pt) or pt
				if not tally[name] then tally[name] = 0; order[#order + 1] = name end
				tally[name] = tally[name] + 1
			end
		end
		table.sort(order)
		local parts = {}
		for _, name in ipairs(order) do parts[#parts + 1] = tally[name] .. " " .. name end
		return #parts > 0 and table.concat(parts, ", ") or "None"
	end
	ctx.hatchTeamNames = teamNames

	-- Kategori Hunt: Special (dari filter Bronto Config) + Heavy (>= 5kg, gabungan Huge s/d Colossal).
	-- Apakah pet masuk filter Special di Sell & Bronto Configuration?
	local function isBrontoSpecial(petType, w)
		local rule = findRule(petType)
		if rule then
			if rule.special == true then return true end
			local targetKg = tonumber(rule.kg) or 0
			return (tonumber(w) or 0) >= targetKg
		end
		local key = petEggLabel(petType)
		if (CFG.brontoSpecialPets or {})[key] ~= true then return false end
		if (CFG.brontoSpecialWeight or 0) > 0 and (w or 0) <= CFG.brontoSpecialWeight then return false end
		return true
	end
	-- akumulasi pet ke-hatch: Special vs Heavy (>= 5 kg). Simpan list semua bobot per petType.
	local function trackHatch(petType, dispW, special)
		ctx.state.hatchTiers = ctx.state.hatchTiers or {}
		dispW = tonumber(dispW) or 0
		local category = special and "Special" or (dispW >= 5 and "Heavy" or nil)
		if not category then return end -- <5kg non-special: skip

		local bucket = ctx.state.hatchTiers[category]
		if not bucket then bucket = {}; ctx.state.hatchTiers[category] = bucket end
		local t = bucket[petType]
		if not t then t = { n = 0, weights = {} }; bucket[petType] = t end
		t.n = t.n + 1
		t.weights[#t.weights + 1] = dispW
	end
	ctx.hatchIsBrontoSpecial = isBrontoSpecial

	-- Recovery stat DIHITUNG dari team yg dipilih (formula game, bukan empiris).
	-- Per pet: value = clamp(Base + Scale*scaledLevel, 0, Max). scaledLevel diminishing
	-- di atas 100. Total di-cap 50% (cap per egg). Koi @ Hatch team, Seal @ Sell team.
	local function scaledLevel(lv)
		lv = lv or 0
		if lv <= 100 then return lv
		elseif lv <= 120 then return (lv - 100) * 0.25 + 100
		else return (lv - 120) * 0.1 + 105 end
	end
	local function passivePct(teamSet, typeMatch, base, scale, maxPer)
		local inv = inventory()
		local n, total = 0, 0
		for u in pairs(teamSet or {}) do
			local v = inv[u]
			if v and tostring(v.PetType):find(typeMatch) then
				n = n + 1
				local val = base + scale * scaledLevel((v.PetData or {}).Level or 0)
				total = total + math.clamp(val, 0, maxPer) -- per-pet asli (Max 10), total ga di-cap
			end
		end
		return n, total
	end
	-- Koi (Fish of Fortune): Base1 Scale0.22 Max10. Seal (Seal the Deal): Base1 Scale0.05 Max10.
	function ctx.getRecoveryStat()
		local kn, kp = passivePct(CFG.hatchHatchTeam, "Koi", 1, 0.22, 10)
		local sn, sp = passivePct(CFG.hatchSellTeam, "Seal", 1, 0.05, 10)
		return {
			koiCount = kn, koiPct = kp,
			sealCount = sn, sealPct = sp,
		}
	end

	-- Recovery ASLI dihitung dari notif game (listener di atas): periodHatchRec / periodSellRec.
	-- periodHatched / periodSold = jumlah aksi (buat hitung % efektif).

	local function fmtDur(sec)
		sec = math.max(0, math.floor(sec))
		local h = math.floor(sec / 3600); local m = math.floor((sec % 3600) / 60); local s = sec % 60
		local p = {}
		if h > 0 then p[#p + 1] = h .. "h" end
		if m > 0 then p[#p + 1] = m .. "m" end
		p[#p + 1] = s .. "s"
		return table.concat(p, " ")
	end

	local function sendCycleStats()
		local url = CFG.webhookUrl
		if not url or url == "" or not ctx.sendWebhook then return end
		local eggName = CFG.hatchEggName or "Rare Egg"
		local hatched = ctx.state.hatchEggsHatched or 0
		local eggBefore = ctx.state.hatchEggBefore or 0
		local curAmt = totalEggCount(eggName)

		-- Format Hunt: Special (range min-max kg) & Heavy/Huge-Colossal (daftar bobot tiap pet)
		local tiers = ctx.state.hatchTiers or {}
		local huntLines, totalPets = {}, 0

		-- 1. Special Pets (langsung hasil tanpa judul 'Special:')
		local specBucket = tiers["Special"] or {}
		local specKeys = {}
		for pt in pairs(specBucket) do specKeys[#specKeys + 1] = pt end
		table.sort(specKeys)
		for _, pt in ipairs(specKeys) do
			local t = specBucket[pt]
			totalPets = totalPets + t.n
			local minW, maxW = math.huge, 0
			for _, w in ipairs(t.weights) do
				if w < minW then minW = w end
				if w > maxW then maxW = w end
			end
			local rng = (minW == maxW or minW == math.huge) and ("`%.2f kg`"):format(maxW)
				or ("`%.2f-%.2f kg`"):format(minW, maxW)
			huntLines[#huntLines + 1] = ("> • **%s** `x%d` (%s)"):format(pt, t.n, rng)
		end

		-- 2. Heavy / Huge-Colossal Pets (daftar bobot per pet)
		local heavyBucket = tiers["Heavy"] or {}
		local heavyKeys = {}
		for pt in pairs(heavyBucket) do heavyKeys[#heavyKeys + 1] = pt end
		table.sort(heavyKeys)
		for _, pt in ipairs(heavyKeys) do
			local t = heavyBucket[pt]
			totalPets = totalPets + t.n
			local wStrs = {}
			for _, w in ipairs(t.weights) do
				wStrs[#wStrs + 1] = ("%.2f"):format(w)
			end
			huntLines[#huntLines + 1] = ("> • **%s** `x%d` (`%skg`)"):format(pt, t.n, table.concat(wStrs, ", "))
		end

		local huntText = #huntLines > 0 and table.concat(huntLines, "\n"):sub(1, 1020) or "> • *Tidak ada pet bronto*"

		-- Recovery deterministik (cap 50%). Koi dari Hatch+Bronto team; Seal dari Sell team.
		local rec = ctx.getRecoveryStat()
		local sellDone = ctx.state.sellDoneThisReport == true
		local recHatchCycle = math.floor((ctx.state.periodHatchRec or 0) + 0.5)
		local recSellCycle = sellDone and math.floor((ctx.state.periodSellRec or 0) + 0.5) or 0
		local koiPctShown = rec.koiPct
		local sellPctShown = sellDone and rec.sealPct or 0
		local totalRecovery = recHatchCycle + recSellCycle

		local curAdj = curAmt
		local maxBp = 0
		local d = getData(); if d then maxBp = tonumber(d.PetsData.MutableStats.MaxPetsInInventory) or 0 end
		local hatchCycles = ctx.state.hatchRounds or 0
		local netResult = curAdj - eggBefore

		local payload = { embeds = { {
			title = "📊 Tracking",
			color = 5793266,
			fields = {
				{
					name = "**Profile :**",
					value = ("> Username : **%s**"):format(LP.Name),
					inline = false
				},
				{
					name = "**Hatch Statistics :**",
					value = ("> Cycle Count: `%d`\n> Total Hatched: `%d`\n> Sell Cycle: `%d / %d`\n> Reduce Time: `%s`\n> Duration: `%s`\n> \n> Egg Name: `%s`\n> Pet on Inventory: `%d/%d`")
						:format(
							hatchCycles,
							hatched,
							(ctx.state.hatchReportSellProg or ((ctx.state.hatchRounds or 0) - (ctx.state.hatchLastSellCycle or 0))),
							CFG.sellEveryNCycles or 1,
							fmtDur(os.time() - (ctx.state.hatchCycleStartTime or os.time())),
							fmtDur(os.time() - (ctx.state.hatchStartTime or os.time())),
							eggName,
							backpackPetCount(),
							maxBp
						),
					inline = false
				},
				{
					name = ("**Hatch Bronto (%d):**"):format(totalPets),
					value = huntText,
					inline = false
				},
				{
					name = "**Egg Statistics :**",
					value = ("> Egg Before: `%d`\n> Current Egg: `%d` (`%+d`)\n> Lucky Hatch: `%d` (`%.2f%%`)\n> Lucky Sell: `%d` (`%.2f%%`)\n> Total Recovery: `%d`")
						:format(eggBefore, curAdj, netResult, recHatchCycle, koiPctShown, recSellCycle, sellPctShown, totalRecovery),
					inline = false
				},
			},
			footer = {
				text = ("Server Version: %s\n%s"):format(tostring(game.PlaceVersion), os.date("%B %d | %I:%M %p")),
				icon_url = "https://raw.githubusercontent.com/milmscr/iniapa/main/cobainaja/Logo/logo_icon.png"
			},
		} } }
		pcall(function() ctx.sendWebhook(url, payload, ctx) end)
		ctx.state.hatchCycleStartTime = os.time()
		-- reset counter periode (Lucky Hatch/Sell dihitung ulang tiap webhook)
		ctx.state.periodHatched, ctx.state.periodSold, ctx.state.sellDoneThisReport = 0, 0, false
		ctx.state.periodHatchRec, ctx.state.periodSellRec = 0, 0
	end
	ctx.hatchSendCycleStats = sendCycleStats
	ctx.hatchTrack = trackHatch

	----------------------------------------------------------------- STATUS
	ctx.state.hatchStatus = "Idle"
	function ctx.getHatchSummary()
		-- team: format per pet "Mutasi - Nama - Berat - Age" (pakai teamNames global)
		local nm = teamNames
		-- max backpack + jumlah egg terpilih
		local d = getData()
		local maxBp = d and d.PetsData and d.PetsData.MutableStats and tonumber(d.PetsData.MutableStats.MaxPetsInInventory) or 0
		local eggName = CFG.hatchEggName or "Rare Egg"
		local curEgg = totalEggCount(eggName)
		return {
			status = CFG.hatchEnabled and "RUNNING" or "STOPPED",
			phase = ctx.state.hatchPhase or "-",
			core = nm(CFG.hatchCoreTeam), hatch = nm(CFG.hatchHatchTeam),
			bronto = nm(CFG.hatchBrontoTeam), sell = nm(CFG.hatchSellTeam),
			backpack = backpackPetCount(), maxBackpack = maxBp,
			currentEgg = eggName, eggBefore = ctx.state.hatchEggBefore or curEgg, currentAmount = curEgg,
			eggsHatched = ctx.state.hatchEggsHatched or 0,
			sellCycles = ctx.state.hatchSellCycles or 0,
			ready = #readyEggs(),
			placed = placedEggCount(),
			maxPlaced = CFG.hatchMaxPlaced or 9,
			sellMode = CFG.sellMode or "Cycle",
			cycleProg = (ctx.state.hatchRounds or 0) - (ctx.state.hatchLastSellCycle or 0),
			cycleTarget = CFG.sellEveryNCycles or 1,
			proc = ctx.getRecoveryStat(),
		}
	end

	----------------------------------------------------------------- LOOP
	local function tick()
		local bpc = backpackPetCount()
		local maxP = CFG.hatchMaxPlaced or 9
		local placed = placedEggCount()

		-- CHECK EGG THRESHOLD (Fallback saat Auto Sell dimatikan atau kondisi stuck total):
		-- Jika Auto Sell mati, atau stuck (tidak ada egg di inventory, plot kosong, dan tidak ada pet untuk di-sell),
		-- cek langsung agar tidak idle selamanya.
		-- Jika Auto Sell aktif, pengecekan UTAMA dilakukan SETELAH sell di bawah agar egg bisa balik dulu (Seal the Deal recovery).
		if CFG.hatchRejoinMinusEnabled or CFG.hatchRejoinPlusEnabled then
			local curEgg = totalEggCount(CFG.hatchEggName or "Rare Egg")
			local isStuck = (curEgg <= 0 and placed == 0 and bpc == 0)
			if not CFG.autoSellEnabled or isStuck then
				local shouldRejoin, rType, rEgg, rCur, rNet, rThresh = checkEggThreshold()
				if shouldRejoin then
					handleEggRejoin(rType, rEgg, rCur, rNet, rThresh)
					return
				end
			end
		end

		-- cycle = jumlah RONDE hatch (tiap 1 batch garden selesai di-hatch = 1 cycle)
		local cycle = ctx.state.hatchRounds or 0
		-- 1) SELL trigger: mode "Cycle" (tiap N cycle) atau "Backpack" (pas penuh)
		local sellNow = false
		if CFG.autoSellEnabled then
			if CFG.sellMode == "Cycle" then
				sellNow = (cycle - (ctx.state.hatchLastSellCycle or 0)) >= (CFG.sellEveryNCycles or 1)
			else
				sellNow = bpc >= (CFG.sellWhenReach or 100)
			end
		end
		if sellNow then
			ctx.state.pnpBlockedByHatch = true
			ctx.state.hatchPhase = "Selling Pets"
			if next(CFG.hatchSellTeam or {}) and not equipTeam(CFG.hatchSellTeam, "Sell Team", CFG.hatchSellUnequipDelay, CFG.hatchSellEquipDelay) then return end -- team wajib lengkap
			task.wait(CFG.sellTeamDelay or 5.5)
			local sold = doSell()
			ctx.state.periodSold = (ctx.state.periodSold or 0) + (tonumber(sold) or 0)
			ctx.state.sellDoneThisReport = true
			-- simpan progress sell-cycle SEBELUM reset (biar webhook nampilin 2/2 bukan 0/2)
			ctx.state.hatchReportSellProg = cycle - (ctx.state.hatchLastSellCycle or 0)
			ctx.state.hatchLastSellCycle = cycle

			-- Tunggu 2 detik agar notifikasi Lucky Pet / recovery Seal the Deal selesai masuk ke inventory
			task.wait(2.0)

			-- 1) Kirim Webhook Sell Terlebih Dahulu Sebelum Rejoin!
			sendCycleStats()
			ctx.state.hatchPendingReport = false

			-- 2) Beri jeda 0.6s agar HTTP request webhook sell terkirim ke Discord
			task.wait(0.6)

			-- 3) CEK EGG THRESHOLD (MINUS / PLUS) SETELAH SIKLUS AUTO SELL SELESAI:
			-- Memberi kesempatan Sell Team mengembalikan egg (Seal recovery) terlebih dahulu.
			-- Jika setelah sell selesai egg minus/plus melebihi threshold -> kirim webhook rejoin lalu langsung auto rejoin!
			if CFG.hatchRejoinMinusEnabled or CFG.hatchRejoinPlusEnabled then
				local shouldRejoin, rType, rEgg, rCur, rNet, rThresh = checkEggThreshold()
				if shouldRejoin then
					handleEggRejoin(rType, rEgg, rCur, rNet, rThresh)
					return
				end
			end

			return
		end

		-- CHECK INVENTORY FULL: jika penyimpanan penuh, hentikan auto hatch & kirim webhook
		local curPets, maxPets = getInventoryCapacity()
		if maxPets > 0 and curPets >= maxPets then
			if CFG.autoSellEnabled and not ctx.state.sellDoneThisReport then
				ctx.state.pnpBlockedByHatch = true
				ctx.state.hatchPhase = "Selling Pets (Inv Full)"
				if not next(CFG.hatchSellTeam or {}) or equipTeam(CFG.hatchSellTeam, "Sell Team", CFG.hatchSellUnequipDelay, CFG.hatchSellEquipDelay) then
					task.wait(CFG.sellTeamDelay or 5.5)
					local sold = doSell()
					ctx.state.periodSold = (ctx.state.periodSold or 0) + (tonumber(sold) or 0)
					ctx.state.sellDoneThisReport = true
					curPets, maxPets = getInventoryCapacity()
					task.wait(2.0)

					-- Kirim webhook sell dulu
					sendCycleStats()
					ctx.state.hatchPendingReport = false
					task.wait(0.6)

					-- Cek egg threshold setelah sell darurat
					if CFG.hatchRejoinMinusEnabled or CFG.hatchRejoinPlusEnabled then
						local shouldRejoin, rType, rEgg, rCur, rNet, rThresh = checkEggThreshold()
						if shouldRejoin then
							handleEggRejoin(rType, rEgg, rCur, rNet, rThresh)
							return
						end
					end
				end
			end
			if maxPets > 0 and curPets >= maxPets then
				handleInventoryFull(curPets, maxPets)
				return
			end
		end

		-- clamp target ke kapasitas farm biar ga nyangkut (mis. Max Placed > MaxEggsInFarm)
		local d = getData()
		local farmCap = d and d.PetsData and d.PetsData.MutableStats and d.PetsData.MutableStats.MaxEggsInFarm or maxP
		maxP = math.min(maxP, farmCap)

		local placed = placedEggCount()

		-- 2) PLACE (best-effort): tambah egg kalau kurang. JANGAN stuck kalau ga bisa penuh
		--    (grid bentrok egg recovered / kapasitas farm mentok) -> lanjut proses egg yg ada.
		if placed < maxP then
			ctx.state.hatchPhase = ("Placing Eggs (%d/%d)"):format(placed, maxP)
			if not equipTeam(CFG.hatchCoreTeam, "Core Team", CFG.hatchCoreUnequipDelay, CFG.hatchCoreEquipDelay) then return end -- team wajib lengkap dulu
			ctx.state.pnpBlockedByHatch = false
			local added = placeEggs(maxP)
			placed = placedEggCount()
			if added > 0 and placed < maxP then return end -- masih nambah -> lanjut place tick berikut
			-- added==0 (mentok) & belum penuh -> anti-stuck: lanjut proses egg yg udah ada
		end

		-- REPORT: garden udah ke-refill (place selesai). Kalau ada report pending dari
		-- hatch/sell sebelumnya, KIRIM sekarang -> Current Amount = backpack + garden (stabil).
		if ctx.state.hatchPendingReport then
			ctx.state.hatchPendingReport = false
			task.spawn(sendCycleStats)
		end

		local ready = readyEggs()
		-- 3) HATCH: HANYA kalau SEMUA egg (yg ke-place) udah READY (jangan switch selama timer jalan)
		if placed > 0 and #ready >= placed then
			ctx.state.pnpBlockedByHatch = true
			local curHatchPets, maxHatchPets = getInventoryCapacity()
			if maxHatchPets > 0 and curHatchPets >= maxHatchPets then
				handleInventoryFull(curHatchPets, maxHatchPets)
				return
			end

			ctx.state.hatchPhase = "Hatching"
			-- klasifikasi tiap egg: normal (Hatch team) / bronto (Bronto team) / skip
			local normal, bronto = {}, {}
			for _, e in ipairs(ready) do
				local c = classifyEgg(e)
				if c == "bronto" then bronto[#bronto + 1] = e
				elseif c == "normal" then normal[#normal + 1] = e end
			end
			local function hatchList(list)
				for _, e in ipairs(list) do
					if not CFG.hatchEnabled then break end
					local cPets, mPets = getInventoryCapacity()
					if mPets > 0 and cPets >= mPets then
						handleInventoryFull(cPets, mPets)
						break
					end
					local pt, w = eggPending(e)
					if pt then
						local isSpecial = isBrontoSpecial(pt, w)
						trackHatch(pt, w, isSpecial)
						if isSpecial then
							task.spawn(function() sendHatchAlert(pt, CFG.hatchEggName or "Rare Egg", w, false) end)
						end
					end
					pcall(function() EggRemote:FireServer("HatchPet", e) end)
					ctx.state.hatchEggsHatched = (ctx.state.hatchEggsHatched or 0) + 1
				end
			end
			-- pass NORMAL -> Hatch Team (Koi recover)
			if #normal > 0 then
				if next(CFG.hatchHatchTeam or {}) and not equipTeam(CFG.hatchHatchTeam, "Hatch Team", CFG.hatchTeamUnequipDelay, CFG.hatchTeamEquipDelay) then return end
				if next(CFG.hatchHatchTeam or {}) and (CFG.hatchTeamDelay or 5.5) > 0 then
					task.wait(CFG.hatchTeamDelay or 5.5)
				end
				ctx.state.hatchPhase = ("Hatching Hatch-team (%d)"):format(#normal)
				hatchList(normal)
			end
			if not CFG.hatchEnabled then return end
			-- pass BRONTO -> Bronto Team (+30% berat) + kirim Hatch Alert per pet
			if #bronto > 0 then
				if next(CFG.hatchBrontoTeam or {}) and not equipTeam(CFG.hatchBrontoTeam, "Bronto Team", CFG.hatchBrontoUnequipDelay, CFG.hatchBrontoEquipDelay) then return end
				if next(CFG.hatchBrontoTeam or {}) and (CFG.brontoTeamDelay or 5.5) > 0 then
					task.wait(CFG.brontoTeamDelay or 5.5)
				end
				ctx.state.hatchPhase = ("Hatching Bronto-team (%d)"):format(#bronto)
				for _, e in ipairs(bronto) do
					if not CFG.hatchEnabled then break end
					local cPets, mPets = getInventoryCapacity()
					if mPets > 0 and cPets >= mPets then
						handleInventoryFull(cPets, mPets)
						break
					end
					local pt, w = eggPending(e)
					-- pet ini di-hatch pakai Bronto team -> berat aktual +30% (buat tier Hunt)
					if pt then trackHatch(pt, w * 1.3, isBrontoSpecial(pt, w)); task.spawn(function() sendHatchAlert(pt, CFG.hatchEggName or "Rare Egg", w) end) end
					pcall(function() EggRemote:FireServer("HatchPet", e) end)
					ctx.state.hatchEggsHatched = (ctx.state.hatchEggsHatched or 0) + 1
				end
			end
			if not CFG.hatchEnabled then return end
			-- jumlah hatch (recovery-nya diisi listener notif). Beri jeda biar notif nyusul.
			ctx.state.periodHatched = (ctx.state.periodHatched or 0) + #normal + #bronto
			task.wait(1.5)
			-- 1 batch (normal+bronto) selesai = 1 ronde/cycle
			ctx.state.hatchRounds = (ctx.state.hatchRounds or 0) + 1
			-- TANDAI report pending. Webhook ga dikirim di sini — ditunda sampai garden
			-- ke-refill (place egg lagi) biar Current Amount stabil & Lucky Hatch keitung.
			if not (ctx.state.sellDoneThisReport) then ctx.state.hatchReportSellProg = nil end
			ctx.state.hatchPendingReport = true
			return
		end

		-- 4) INCUBATE: masih ada egg belum ready -> TETAP Core Team (speed), jangan switch/hatch
		ctx.state.hatchPhase = ("Incubating (%d/%d ready)"):format(#ready, placed)
		equipTeam(CFG.hatchCoreTeam, "Core Team")
		ctx.state.pnpBlockedByHatch = false
		ctx.state.hatchStatus = ("Nunggu egg ready (%d/%d)..."):format(#ready, placed)
	end

	local function loop()
		ctx.state.hatchId = (ctx.state.hatchId or 0) + 1
		local my = ctx.state.hatchId
		ctx.elevate()
		while CFG.hatchEnabled and ctx.alive() and ctx.state.hatchId == my do
			pcall(tick)
			task.wait(1.0)
		end
		ctx.state.hatchStatus = "Idle"
		ctx.state.pnpBlockedByHatch = false
		ctx.state.teamSwapActive = false
	end

	function ctx.startHatch()
		if ctx.cancelClearGarden then ctx.cancelClearGarden() end
		-- RESET semua statistik: tiap nyalain ulang mulai dari awal (webhook + live status)
		ctx.state.hatchEggsHatched = 0
		ctx.state.hatchRounds = 0
		ctx.state.hatchLastSellCycle = 0
		ctx.state.hatchReportSellProg = nil
		ctx.state.hatchSellCycles = 0
		ctx.state.hatchTiers = {}
		ctx.state.periodHatched = 0
		ctx.state.periodSold = 0
		ctx.state.periodHatchRec = 0
		ctx.state.periodSellRec = 0
		ctx.state.sellDoneThisReport = false
		ctx.state.hatchPendingReport = false
		ctx.state.hatchIsRejoining = false
		-- catat jumlah egg terpilih di awal (buat "Egg Before") = backpack + placed
		local eggName = CFG.hatchEggName or "Rare Egg"
		ctx.state.lastTrackedEggName = eggName
		ctx.state.hatchEggBefore = totalEggCount(eggName)
		ctx.state.hatchStartTime = os.time()
		ctx.state.hatchCycleStartTime = os.time()
		task.spawn(loop)
		task.spawn(sendStartHatchWebhook)
		if (CFG.hatchRejoinMinusEnabled or CFG.hatchRejoinPlusEnabled) and ctx.startEggMinusWatcher then
			ctx.startEggMinusWatcher()
		end
	end
	function ctx.stopHatch()
		ctx.state.hatchId = (ctx.state.hatchId or 0) + 1
		ctx.state.hatchStatus = "Idle"
		ctx.state.pnpBlockedByHatch = false
		ctx.state.teamSwapActive = false
	end

	----------------------------------------------------------------- AUTO FAVORITE
	-- Favoritin otomatis pet yg tipenya ada di CFG.favoritePetTypes (biar ga ke-sell).
	-- favoritePetTypes = key PET_OPTIONS (nama pet polos); tool attribute "f" = nama pet.
	function ctx.startAutoFavorite()
		ctx.state.autoFavId = (ctx.state.autoFavId or 0) + 1
		local my = ctx.state.autoFavId
		ctx.elevate()
		task.spawn(function()
			while CFG.autoFavorite and ctx.alive() and ctx.state.autoFavId == my do
				if next(CFG.favoritePetTypes or {}) then
					for _, t in ipairs(petTools()) do
						local pt = t:GetAttribute("f")
						if pt and (CFG.favoritePetTypes)[pt] and not isFav(t) then
							setFav(t, true)
						end
					end
				end
				task.wait(3)
			end
		end)
	end
	function ctx.stopAutoFavorite()
		ctx.state.autoFavId = (ctx.state.autoFavId or 0) + 1
	end

	----------------------------------------------------------------- AUTO UNFAVORITE
	-- Unfavoritin otomatis pet yg tipenya ada di CFG.unfavoritePetTypes (atau semua jika kosong).
	function ctx.startAutoUnfavorite()
		ctx.state.autoUnfavId = (ctx.state.autoUnfavId or 0) + 1
		local my = ctx.state.autoUnfavId
		ctx.elevate()
		task.spawn(function()
			while CFG.autoUnfavoritePets and ctx.alive() and ctx.state.autoUnfavId == my do
				for _, t in ipairs(petTools()) do
					local pt = t:GetAttribute("f")
					local match = (not next(CFG.unfavoritePetTypes or {})) or (pt and (CFG.unfavoritePetTypes)[pt])
					if match and isFav(t) then
						setFav(t, false)
					end
				end
				task.wait(3)
			end
		end)
	end
	function ctx.stopAutoUnfavorite()
		ctx.state.autoUnfavId = (ctx.state.autoUnfavId or 0) + 1
	end

	----------------------------------------------------------------- EGG THRESHOLD WATCHER
	-- Watcher independen jika Auto Rejoin on Egg Minus / Plus diaktifkan, agar tetap terpantau
	-- meskipun Auto Hatch sedang idle atau di luar siklus hatch.
	local function eggMinusWatcherLoop(myId)
		while (CFG.hatchRejoinMinusEnabled or CFG.hatchRejoinPlusEnabled) and ctx.alive() and ctx.state.eggMinusWatchId == myId do
			-- Jika Auto Hatch aktif dan Auto Sell aktif, biarkan loop Auto Hatch yang mengecek setelah sell
			if not CFG.hatchEnabled or not CFG.autoSellEnabled then
				local shouldRejoin, rType, rEgg, rCur, rNet, rThresh = checkEggThreshold()
				if shouldRejoin then
					handleEggRejoin(rType, rEgg, rCur, rNet, rThresh)
					return
				end
			end
			task.wait(2.0)
		end
	end

	function ctx.startEggMinusWatcher()
		ctx.state.eggMinusWatchId = (ctx.state.eggMinusWatchId or 0) + 1
		local myId = ctx.state.eggMinusWatchId
		task.spawn(function() eggMinusWatcherLoop(myId) end)
	end
	function ctx.stopEggMinusWatcher()
		ctx.state.eggMinusWatchId = (ctx.state.eggMinusWatchId or 0) + 1
	end
end
]=],
	["modules/inventory/automation_accept.lua"] = [=[
--[[ accept.lua — Automation Accept.
     * Accept Gifts : gift pet LANGSUNG (tanpa trade/tiket). Remote GiftPet masuk,
                      dijawab AcceptPetGift:FireServer(true, giftId).
     * Accept Trades: auto-terima AJAKAN trade masuk (RespondRequest true) [menyusul].
     Dua hal berbeda — gift ≠ trade. ]]
return function(ctx)
	local CFG            = ctx.CFG
	local SendRequest    = ctx.deps.SendRequest
	local RespondRequest = ctx.deps.RespondRequest
	local GiftPet        = ctx.deps.GiftPet
	local AcceptPetGift  = ctx.deps.AcceptPetGift
	local TC             = ctx.deps.TradingController
	local Accept         = ctx.deps.Accept
	local Confirm        = ctx.deps.Confirm
	local function log(m) ctx.log(m) end

	----------------------------------------------------------------- AUTO ACCEPT GIFT
	-- GiftPet.OnClientEvent(giftId, petDescription, senderName)
	-- UI notif dibuat game di PlayerGui.Gift_Notification.Frame (tiap gift = 1 clone,
	-- tombolnya di notif.Holder.Frame.Accept). Kita picu klik tombol itu supaya
	-- handler asli jalan (destroy UI + fire AcceptPetGift) -> UI ikut hilang.
	local LP = ctx.LP

	local function clickAcceptButtons()
		local pg = LP:FindFirstChild("PlayerGui")
		local gn = pg and pg:FindFirstChild("Gift_Notification")
		local frame = gn and gn:FindFirstChild("Frame")
		if not frame then return 0 end
		local n = 0
		for _, notif in ipairs(frame:GetChildren()) do
			local holder = notif:FindFirstChild("Holder")
			local inner  = holder and holder:FindFirstChild("Frame")
			local accept = inner and inner:FindFirstChild("Accept")
			if accept then
				local fired = false
				if type(getconnections) == "function" then
					for _, c in ipairs(getconnections(accept.MouseButton1Click)) do
						pcall(function() c:Fire() end); fired = true
					end
				end
				if fired then n += 1 end
			end
		end
		return n
	end

	if GiftPet and AcceptPetGift then
		GiftPet.OnClientEvent:Connect(function(giftId, petDesc, sender)
			if not CFG.acceptGifts then return end
			if type(giftId) ~= "string" then return end
			log(("Gift masuk dari %s: %s"):format(tostring(sender), tostring(petDesc)))
			-- Terima langsung via remote tanpa jeda (instant response)
			pcall(function() AcceptPetGift:FireServer(true, giftId) end)
			task.spawn(function()
				task.wait(0.04)
				local clicked = clickAcceptButtons()
				local pg = LP:FindFirstChild("PlayerGui")
				local gn = pg and pg:FindFirstChild("Gift_Notification")
				local frame = gn and gn:FindFirstChild("Frame")
				if frame then for _, c in ipairs(frame:GetChildren()) do c:Destroy() end end
			end)
			log("Gift diterima ✓")
		end)
	else
		warn("[CeszParadise] GiftPet/AcceptPetGift remote tidak ketemu — auto accept gift nonaktif.")
	end

	----------------------------------------------------------------- AUTO ACCEPT TRADE
	-- 1) Terima AJAKAN masuk: SendRequest.OnClientEvent(reqId, sender) -> RespondRequest(reqId,true)
	if SendRequest and RespondRequest then
		pcall(function()
			SendRequest.OnClientEvent:Connect(function(requestId, senderPlayer)
				if not CFG.acceptTrades then return end
				log("Auto-terima ajakan trade dari " .. tostring(senderPlayer and senderPlayer.Name or "?"))
				task.wait(0.3)
				pcall(function() RespondRequest:FireServer(requestId, true) end)
			end)
		end)
	end

	-- 2) Di window trade masuk: auto Accept (pas cooldown habis) -> tunggu lawan -> Confirm.
	--    Penerima ngasih kosong. Guard: jangan ganggu Automation Trade kita sendiri.
	if TC and TC.OnTradeCreated and Accept and Confirm then
		TC.OnTradeCreated:Connect(function()
			if not CFG.acceptTrades then return end
			if ctx.state.tradeRunning then return end -- kita lagi jadi pengirim, jangan diganggu
			task.spawn(function()
				log("Window trade masuk — auto accept + confirm.")
				-- auto accept: spam pelan sampai status KITA jadi Accepted (cooldown habis)
				local myOk, a0 = false, os.clock()
				repeat
					pcall(function() Accept:FireServer() end)
					task.wait(1)
					local s = ctx.myState and ctx.myState(ctx.replicatorData())
					if s == "Accepted" or s == "Confirmed" then myOk = true; break end
				until (not (TC and TC.CurrentTradeReplicator)) or (os.clock() - a0) > 20
				if not myOk or not (TC and TC.CurrentTradeReplicator) then return end

				-- tunggu lawan accept
				local t0 = os.clock()
				local otherOk = false
				repeat
					task.wait(0.5)
					if ctx.otherAccepted and ctx.otherAccepted(ctx.replicatorData()) then otherOk = true; break end
				until (not (TC and TC.CurrentTradeReplicator)) or (os.clock() - t0) > 60
				if not otherOk or not (TC and TC.CurrentTradeReplicator) then return end

				-- confirm sampai trade tertutup
				t0 = os.clock()
				repeat
					pcall(function() Confirm:FireServer() end)
					task.wait(1.5)
				until (not (TC and TC.CurrentTradeReplicator)) or (os.clock() - t0) > 15
				log("Trade masuk selesai (confirmed).")
			end)
		end)
	end
end
]=],
	["modules/inventory/automation_trade.lua"] = [=[
--[[ trade.lua — inti Automation Trade.
     Alur per-trade: SendRequest -> tunggu window kebuka -> AddItem pets -> Accept
                     -> tunggu lawan accept -> Confirm -> tunggu selesai.
     Mengisi: ctx.getPlayers, ctx.getData, ctx.matchingPetUuids,
              ctx.startTrade, ctx.stopTrade ]]
return function(ctx)
	local Players     = ctx.Services.Players
	local LP          = ctx.LP
	local CFG         = ctx.CFG
	local DataService = ctx.deps.DataService
	local TC          = ctx.deps.TradingController
	local SendRequest = ctx.deps.SendRequest
	local AddItem     = ctx.deps.AddItem
	local Accept      = ctx.deps.Accept
	local Confirm     = ctx.deps.Confirm
	local Decline     = ctx.deps.Decline
	local FavoriteItem = ctx.deps.FavoriteItem
	local function log(m) ctx.log(m) end
	local function setStatus(s) ctx.setStatus(s) end

	----------------------------------------------------------------- data helpers
	local function getData()
		local ok, d = pcall(function() return DataService:GetData() end)
		if ok then return d end
		return nil
	end
	ctx.getData = getData

	local function getPlayers()
		local list = {}
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= LP then list[#list + 1] = p.Name end
		end
		table.sort(list)
		return list
	end
	ctx.getPlayers = getPlayers

	-- cek pet cocok dengan filter CFG (bisa mode ticket atau gift)
	local function petPasses(v, isGift)
		local pt = v.PetType
		local pd = v.PetData
		if not (pt and pd) then return false end
		-- filter type (kosong = semua)
		local pTypes = isGift and CFG.giftPetTypes or CFG.petTypes
		if pTypes and next(pTypes) and not pTypes[pt] then return false end
		-- weight: berat TAMPIL di game = BaseWeight + 0.5 (pakai angka tampilan di filter)
		local w = (pd.BaseWeight or 0) + 0.5
		local wf = isGift and (CFG.giftWeightFilter or 0) or (CFG.weightFilter or 0)
		if wf > 0 and w < wf then return false end
		if wf < 0 and w > -wf then return false end
		-- age (Level)
		local age = pd.Level or 0
		local af = isGift and (CFG.giftAgeFilter or 0) or (CFG.ageFilter or 0)
		if af > 0 and age < af then return false end
		if af < 0 and age > -af then return false end
		return true
	end

	-- kumpulkan uuid pet yang cocok (maksimal `limit`)
	local function matchingPetUuids(limit, isGift)
		local out = {}
		local d = getData()
		local pinv = d and d.PetsData and d.PetsData.PetInventory and d.PetsData.PetInventory.Data
		if not pinv then return out end
		-- pet yang lagi di-equip jangan di-trade
		local equipped = {}
		if d.PetsData.EquippedPets then for _, u in ipairs(d.PetsData.EquippedPets) do equipped[u] = true end end
		local autoUnfav = isGift and CFG.giftAutoUnfavorite or CFG.autoUnfavorite
		for uuid, v in pairs(pinv) do
			if #out >= limit then break end
			if not equipped[uuid] and petPasses(v, isGift) then
				local fav = v.PetData.IsFavorite
				if (not fav) or autoUnfav then
					out[#out + 1] = { uuid = uuid, fav = fav, petType = v.PetType }
				end
			end
		end
		return out
	end
	ctx.matchingPetUuids = matchingPetUuids

	-- Hitung SEMUA pet yang cocok filter (tanpa limit) untuk status GUI.
	function ctx.countMatchingPets(isGift)
		if isGift == nil then isGift = (CFG.tradeMethod == "gift") end
		local n = 0
		local d = getData()
		local pinv = d and d.PetsData and d.PetsData.PetInventory and d.PetsData.PetInventory.Data
		if not pinv then return 0 end
		local equipped = {}
		if d.PetsData.EquippedPets then for _, u in ipairs(d.PetsData.EquippedPets) do equipped[u] = true end end
		local autoUnfav = isGift and CFG.giftAutoUnfavorite or CFG.autoUnfavorite
		for uuid, v in pairs(pinv) do
			if not equipped[uuid] and petPasses(v, isGift) then
				local fav = v.PetData.IsFavorite
				if (not fav) or autoUnfav then n = n + 1 end
			end
		end
		return n
	end

	-- PRE-PASS: unfavorite SEMUA pet favorite yang lolos filter dulu (dipanggil di awal
	-- trade). Biar ga ke-race pas add item (unfav satu-satu tiap batch rawan gagal).
	local function unfavoriteAllMatching(isGift)
		local autoUnfav = isGift and CFG.giftAutoUnfavorite or CFG.autoUnfavorite
		if not (autoUnfav and FavoriteItem) then return end
		local d = getData()
		local pinv = d and d.PetsData and d.PetsData.PetInventory and d.PetsData.PetInventory.Data
		if not pinv then return end
		local equipped = {}
		if d.PetsData.EquippedPets then for _, u in ipairs(d.PetsData.EquippedPets) do equipped[u] = true end end
		local favSet, favCount = {}, 0
		for uuid, v in pairs(pinv) do
			if not equipped[uuid] and petPasses(v, isGift) and v.PetData.IsFavorite then
				favSet[uuid] = true; favCount = favCount + 1
			end
		end
		if favCount == 0 then return end
		setStatus(("Unfavorite %d pet target dulu..."):format(favCount))
		local Favorite_Item_BE = game:GetService("ReplicatedStorage").GameEvents:FindFirstChild("Favorite_Item_BE")
		local done = 0
		for _, src in ipairs({ LP:FindFirstChildOfClass("Backpack"), LP.Character }) do
			if src then for _, t in ipairs(src:GetChildren()) do
				local u = t:IsA("Tool") and t:GetAttribute("PET_UUID")
				if u and favSet[u] then
					pcall(function() FavoriteItem:FireServer(t) end)
					if Favorite_Item_BE then pcall(function() Favorite_Item_BE:Fire(t) end) end
					favSet[u] = nil; done = done + 1
					task.wait(0.04)
				end
			end end
		end
		if done > 0 then task.wait(0.2) end -- kasih waktu sync sebelum mulai trade
	end
	ctx.unfavoriteAllMatching = unfavoriteAllMatching

	----------------------------------------------------------------- trade-state read
	local function replicatorData()
		if not (TC and TC.CurrentTradeReplicator) then return nil end
		local rep = TC.CurrentTradeReplicator
		local ok, d = pcall(function() return rep:GetDataAsync() end)
		if ok and d then return d end
		ok, d = pcall(function() return rep:GetData() end)
		if ok then return d end
		return nil
	end

	ctx.replicatorData = replicatorData

	-- Skema (dari remote-spy): d.players = {p1,p2}, d.states = {[1]="None"/"Accepted", [2]=...}
	-- state index sejajar dengan players. Lawan dianggap accept kalau statenya "Accepted"/"Confirmed".
	local function stateOf(d, wantSelf)
		if type(d) ~= "table" then return nil end
		local players = d.players or d.Players
		local states  = d.states or d.States
		if type(players) ~= "table" or type(states) ~= "table" then return nil end
		local idx
		for i, p in ipairs(players) do
			if wantSelf then if p == LP then idx = i end
			else if p ~= LP then idx = i end end
		end
		if not idx then return nil end
		return states[idx]
	end
	local function otherState(d) return stateOf(d, false) end
	local function myState(d) return stateOf(d, true) end
	ctx.myState = myState
	local function otherAccepted(d)
		local s = otherState(d)
		return s == "Accepted" or s == "Confirmed"
	end
	ctx.otherAccepted = otherAccepted

	-- Trade cuma bisa dikirim kalau kita lagi MEGANG Trading Ticket.
	local function equipTradingTicket()
		local char = LP.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if not hum then return false end
		-- sudah megang tiket?
		for _, t in ipairs(char:GetChildren()) do
			if t:IsA("Tool") and t.Name:find("Trading Ticket") then return true end
		end
		local bp = LP:FindFirstChild("Backpack")
		if not bp then return false end
		for _, t in ipairs(bp:GetChildren()) do
			if t:IsA("Tool") and t.Name:find("Trading Ticket") then
				pcall(function() hum:EquipTool(t) end)
				task.wait(0.3)
				return true
			end
		end
		return false
	end
	ctx.equipTradingTicket = equipTradingTicket

	----------------------------------------------------------------- one trade
	local function doOneTrade(target)
		-- Cek dulu ketersediaan pet yang cocok sebelum melakukan apapun!
		local pets = matchingPetUuids(CFG.petsPerTrade)
		if #pets == 0 then
			log("Tidak ada pet cocok filter. Stop send ticket request.")
			setStatus("Tidak ada pet cocok filter. Auto stop.")
			ctx.state.tradeRunning = false
			CFG.tradeEnabled = false
			if ctx.persistState then ctx.persistState() end
			if ctx.refreshTradeStatus then ctx.refreshTradeStatus() end
			return false
		end

		-- pegang tiket dulu, wajib biar panel trade kebuka
		if not equipTradingTicket() then
			log("Trading Ticket tidak ada / gagal di-equip. Stop.")
			ctx.state.tradeRunning = false
			return false
		end
		setStatus("Kirim ajakan ke " .. target.Name)
		pcall(function() SendRequest:FireServer(target) end)

		-- tunggu window trade kebuka (lawan accept request)
		local t0 = os.clock()
		repeat task.wait(0.3) until (not ctx.state.tradeRunning) or (TC and TC.CurrentTradeReplicator) or (os.clock() - t0) > 20
		if not ctx.state.tradeRunning then return false end
		if not (TC and TC.CurrentTradeReplicator) then
			log("Timeout: " .. target.Name .. " tidak accept ajakan.")
			return false
		end

		-- re-check ketersediaan pet setelah trade terbuka
		pets = matchingPetUuids(CFG.petsPerTrade)
		if #pets == 0 then
			log("Tidak ada pet cocok filter. Batalkan trade.")
			pcall(function() Decline:FireServer() end)
			ctx.state.tradeRunning = false
			CFG.tradeEnabled = false
			if ctx.persistState then ctx.persistState() end
			if ctx.refreshTradeStatus then ctx.refreshTradeStatus() end
			return false
		end

		-- auto unfavorite dulu kalau perlu.
		-- PENTING: Favorite_Item butuh TOOL object (bukan uuid). Cari tool di Backpack/Character.
		if CFG.autoUnfavorite and FavoriteItem then
			local Favorite_Item_BE = game:GetService("ReplicatedStorage").GameEvents:FindFirstChild("Favorite_Item_BE")
			local function findToolByUuid(uuid)
				local bp = LP:FindFirstChildOfClass("Backpack")
				if bp then for _, t in ipairs(bp:GetChildren()) do
					if t:IsA("Tool") and t:GetAttribute("PET_UUID") == uuid then return t end
				end end
				if LP.Character then for _, t in ipairs(LP.Character:GetChildren()) do
					if t:IsA("Tool") and t:GetAttribute("PET_UUID") == uuid then return t end
				end end
				return nil
			end
			for _, p in ipairs(pets) do
				if p.fav then
					local tool = findToolByUuid(p.uuid)
					if tool then
						pcall(function() FavoriteItem:FireServer(tool) end)
						if Favorite_Item_BE then pcall(function() Favorite_Item_BE:Fire(tool) end) end
						task.wait(0.15)
					end
				end
			end
			task.wait(0.3)
		end

		-- add item (percepat proses pengisian pet)
		log(("Cocok %d pet. Mengisi offer..."):format(#pets))
		setStatus(("Menambah %d pet..."):format(#pets))
		for _, p in ipairs(pets) do
			if not ctx.state.tradeRunning then break end
			pcall(function() AddItem:FireServer("Pet", p.uuid) end)
			task.wait(0.06)
		end

		-- verifikasi berapa pet yang benar-benar masuk ke offer kita
		task.wait(0.4)
		do
			local d = replicatorData()
			local myIdx
			if d and d.players then for i, pl in ipairs(d.players) do if pl == LP then myIdx = i end end end
			local n = 0
			if d and myIdx and d.offers and d.offers[myIdx] then
				for _ in pairs(d.offers[myIdx].items or {}) do n += 1 end
			end
			log(("Pet masuk ke offer: %d/%d"):format(n, #pets))
			if n == 0 then
				log("AddItem tidak masuk — cek: pet favorit? equipped? uuid?")
			end
		end

		-- Auto-accept: game punya cooldown anti-scam sebelum tombol Accept aktif.
		-- Daripada nebak durasinya, kita spam Accept pelan sampai status KITA jadi
		-- "Accepted" (artinya cooldown sudah habis & Accept kebaca). Otomatis nunggu pas.
		setStatus("Accept (nunggu cooldown game)...")
		local myOk = false
		local a0 = os.clock()
		repeat
			pcall(function() Accept:FireServer() end)
			task.wait(1)
			local s = myState(replicatorData())
			if s == "Accepted" or s == "Confirmed" then myOk = true; break end
		until (not ctx.state.tradeRunning) or (not (TC and TC.CurrentTradeReplicator)) or (os.clock() - a0) > 20
		if not ctx.state.tradeRunning or not (TC and TC.CurrentTradeReplicator) then return false end
		if not myOk then
			log("Accept kita belum kebaca setelah 20s. Batalkan.")
			pcall(function() Decline:FireServer() end)
			return false
		end
		log("Accept kita OK.")
		setStatus("Menunggu lawan accept...")

		-- tunggu lawan accept
		t0 = os.clock()
		local accepted = false
		repeat
			task.wait(0.5)
			if otherAccepted(replicatorData()) then accepted = true; break end
		until (not ctx.state.tradeRunning) or (not (TC and TC.CurrentTradeReplicator)) or (os.clock() - t0) > 30
		if not ctx.state.tradeRunning then return false end
		if not (TC and TC.CurrentTradeReplicator) then
			log("Trade ditutup sebelum selesai.")
			return false
		end
		if not accepted then
			log("Lawan tidak accept (timeout). Batalkan.")
			pcall(function() Decline:FireServer() end)
			return false
		end

		-- confirm (retry sampai trade tertutup)
		setStatus("Confirm... menunggu selesai")
		t0 = os.clock()
		repeat
			pcall(function() Confirm:FireServer() end)
			task.wait(1.5)
		until (not (TC and TC.CurrentTradeReplicator)) or (not ctx.state.tradeRunning) or (os.clock() - t0) > 15
		if TC and TC.CurrentTradeReplicator then
			log("Confirm terkirim tapi trade belum tertutup.")
			return false
		end
		return true
	end

	----------------------------------------------------------------- one gift (tanpa ticket)
	local function doOneGift(target)
		local pets = matchingPetUuids(CFG.petsPerTrade or 1)
		if #pets == 0 then
			log("Tidak ada pet cocok filter untuk Gift. Stop.")
			setStatus("Pet cocok filter 0. Auto stop.")
			ctx.state.tradeRunning = false
			CFG.tradeEnabled = false
			if ctx.persistState then ctx.persistState() end
			if ctx.refreshTradeStatus then ctx.refreshTradeStatus() end
			return false
		end

		local targetChar = target.Character
		local targetHrp = targetChar and (targetChar:FindFirstChild("HumanoidRootPart") or targetChar.PrimaryPart)
		if not targetHrp then
			log("Target " .. target.Name .. " belum spawn / tidak ada character.")
			setStatus("Target tidak ada character.")
			return false
		end

		local myChar = LP.Character
		local myHrp = myChar and (myChar:FindFirstChild("HumanoidRootPart") or myChar.PrimaryPart)
		local hum = myChar and myChar:FindFirstChildOfClass("Humanoid")
		if not myHrp or not hum then
			log("Character kita belum siap.")
			return false
		end

		-- Teleport dekat target (berdiri di depan target dalam jarak ~3 stud)
		local dist = (myHrp.Position - targetHrp.Position).Magnitude
		if dist > 6 then
			setStatus(("Mendekat ke %s (jarak: %.1f)..."):format(target.Name, dist))
			pcall(function()
				myHrp.CFrame = targetHrp.CFrame * CFrame.new(0, 0, -3) * CFrame.Angles(0, math.pi, 0)
			end)
			task.wait(0.1)
		end

		local GiftPet = ctx.deps.GiftPet or game:GetService("ReplicatedStorage").GameEvents:FindFirstChild("GiftPet")
		local Gift = ctx.deps.Gift or game:GetService("ReplicatedStorage").GameEvents:FindFirstChild("Gift")
		local Favorite_Item = ctx.deps.FavoriteItem or game:GetService("ReplicatedStorage").GameEvents:FindFirstChild("Favorite_Item")
		local Favorite_Item_BE = game:GetService("ReplicatedStorage").GameEvents:FindFirstChild("Favorite_Item_BE")

		local function findToolByUuid(uuid)
			local bp = LP:FindFirstChildOfClass("Backpack")
			if bp then for _, t in ipairs(bp:GetChildren()) do
				if t:IsA("Tool") and t:GetAttribute("PET_UUID") == uuid then return t end
			end end
			if LP.Character then for _, t in ipairs(LP.Character:GetChildren()) do
				if t:IsA("Tool") and t:GetAttribute("PET_UUID") == uuid then return t end
			end end
			return nil
		end

		local sentCount = 0

		for _, p in ipairs(pets) do
			if not ctx.state.tradeRunning then break end
			local tool = findToolByUuid(p.uuid)
			if tool then
				-- Auto unfavorite jika difavoritkan
				if p.fav and Favorite_Item then
					pcall(function() Favorite_Item:FireServer(tool) end)
					if Favorite_Item_BE then pcall(function() Favorite_Item_BE:Fire(tool) end) end
				end

				-- Equip tool ke character dan tunggu sampai ter-equip (polling kilat 0.02s)
				if hum and tool.Parent ~= LP.Character then
					hum:EquipTool(tool)
					local eq0 = os.clock()
					repeat task.wait(0.02) until tool.Parent == LP.Character or (os.clock() - eq0) > 0.8
				end

				-- Pastikan masih dekat target
				if myHrp and targetHrp and (myHrp.Position - targetHrp.Position).Magnitude > 6 then
					pcall(function()
						myHrp.CFrame = targetHrp.CFrame * CFrame.new(0, 0, -3) * CFrame.Angles(0, math.pi, 0)
					end)
				end

				setStatus(("Mengirim gift pet ke %s..."):format(target.Name))

				-- 1. Picu interaksi ProximityPrompt di target character (tanpa hold delay)
				if target.Character then
					for _, desc in ipairs(target.Character:GetDescendants()) do
						if desc:IsA("ProximityPrompt") then
							local aText = desc.ActionText:lower()
							local oText = desc.ObjectText:lower()
							local pName = desc.Name:lower()
							if aText:find("gift") or oText:find("gift") or pName:find("gift") or aText:find("give") then
								pcall(function()
									desc.HoldDuration = 0
									if type(fireproximityprompt) == "function" then
										fireproximityprompt(desc, 0)
										fireproximityprompt(desc)
									else
										desc:InputHoldBegin()
										desc:InputHoldEnd()
									end
								end)
								break
							end
						end
					end
				end

				-- 2. Picu Remote Events langsung
				if GiftPet then
					pcall(function() GiftPet:FireServer(target, tool) end)
					pcall(function() GiftPet:FireServer(target) end)
					pcall(function() GiftPet:FireServer(target, p.uuid) end)
					pcall(function() GiftPet:FireServer(tool, target) end)
					pcall(function() GiftPet:FireServer(target.Character) end)
				end
				if Gift then
					pcall(function() Gift:FireServer(target, tool) end)
					pcall(function() Gift:FireServer(target) end)
					pcall(function() Gift:FireServer(target, p.uuid) end)
					pcall(function() Gift:FireServer(tool, target) end)
					pcall(function() Gift:FireServer(target.Character) end)
				end

				local GE = game:GetService("ReplicatedStorage"):FindFirstChild("GameEvents")
				if GE then
					local sendGift = GE:FindFirstChild("SendGift") or GE:FindFirstChild("GiftItem")
					if sendGift and sendGift:IsA("RemoteEvent") then
						pcall(function() sendGift:FireServer(target, tool) end)
						pcall(function() sendGift:FireServer(target) end)
					end
				end

				-- 3. Coba tool:Activate()
				pcall(function() tool:Activate() end)

				-- Tunggu verifikasi cepat apakah pet sudah terkirim / diterima lawan (tool hilang)
				local waitStart = os.clock()
				local petGone = false
				while (os.clock() - waitStart) < 1.8 and ctx.state.tradeRunning do
					if not findToolByUuid(p.uuid) then
						petGone = true
						break
					end
					task.wait(0.04)
					-- Jika belum terkirim setelah 0.25s, picu ulang prompt & remote
					if (os.clock() - waitStart) > 0.25 and math.floor((os.clock() - waitStart) * 100) % 25 == 0 then
						if target.Character then
							for _, desc in ipairs(target.Character:GetDescendants()) do
								if desc:IsA("ProximityPrompt") then
									pcall(function()
										desc.HoldDuration = 0
										if type(fireproximityprompt) == "function" then
											fireproximityprompt(desc, 0)
										else
											desc:InputHoldBegin()
											desc:InputHoldEnd()
										end
									end)
									break
								end
							end
						end
						if GiftPet then pcall(function() GiftPet:FireServer(target, tool) end) end
						if Gift then pcall(function() Gift:FireServer(target, tool) end) end
					end
				end

				if petGone then
					sentCount = sentCount + 1
					log(("Gift terkirim & diterima %s: %s"):format(target.Name, tostring(p.petType or "Pet")))
				else
					log(("Gift %s ke %s timeout/belum diterima."):format(tostring(p.petType or "Pet"), target.Name))
				end
				task.wait(0.04)
			end
		end

		return sentCount > 0
	end

	----------------------------------------------------------------- loop
	local function tradeLoop()
		ctx.elevate()
		local isGift = (CFG.tradeMethod == "gift")
		unfavoriteAllMatching(isGift) -- unfav semua target favorite dulu, baru mulai trade
		while ctx.state.tradeRunning do
			local totalLimit = isGift and (CFG.giftTotalGifts or CFG.totalTrades) or CFG.totalTrades
			if ctx.state.completed >= totalLimit then
				ctx.state.status = "DONE"
				setStatus(("Selesai %d/%d %s."):format(ctx.state.completed, totalLimit, isGift and "gift" or "trade"))
				ctx.state.tradeRunning = false
				if isGift then CFG.tradeGiftEnabled = false else CFG.tradeTicketEnabled = false; CFG.tradeEnabled = false end
				if ctx.refreshTradeStatus then ctx.refreshTradeStatus() end
				if ctx.refreshGiftStatus then ctx.refreshGiftStatus() end
				break
			end
			-- Stop kalau pet cocok filter sudah habis -> jangan kirim trade/gift lagi.
			if ctx.countMatchingPets(isGift) == 0 then
				ctx.state.status = "DONE"
				setStatus("Pet habis (sesuai filter). " .. (isGift and "Gift" or "Trade") .. " dihentikan.")
				ctx.state.tradeRunning = false
				if isGift then CFG.tradeGiftEnabled = false else CFG.tradeTicketEnabled = false; CFG.tradeEnabled = false end
				if ctx.persistState then ctx.persistState() end
				if ctx.refreshTradeStatus then ctx.refreshTradeStatus() end
				if ctx.refreshGiftStatus then ctx.refreshGiftStatus() end
				break
			end

			local targetName = isGift and (CFG.giftTargetPlayer ~= "" and CFG.giftTargetPlayer or CFG.targetPlayer) or CFG.targetPlayer
			local target = targetName ~= "" and Players:FindFirstChild(targetName) or nil
			if not target then
				setStatus("Target player (" .. tostring(targetName) .. ") tidak ada / belum dipilih.")
				task.wait(1.5)
			else
				ctx.state.status = "RUNNING"
				if ctx.refreshTradeStatus then ctx.refreshTradeStatus() end
				if ctx.refreshGiftStatus then ctx.refreshGiftStatus() end
				local ok = isGift and doOneGift(target) or doOneTrade(target)
				if ok then
					ctx.state.completed += 1
					log(("%s sukses (%d/%d)"):format(isGift and "Gift" or "Trade", ctx.state.completed, totalLimit))
					if ctx.notifyTrade then
						local petLimit = isGift and (CFG.giftPetsPerBatch or 12) or CFG.petsPerTrade
						ctx.notifyTrade(target, #matchingPetUuids(petLimit, isGift))
					end
				end
				if ctx.refreshTradeStatus then ctx.refreshTradeStatus() end
				if ctx.refreshGiftStatus then ctx.refreshGiftStatus() end
				task.wait(isGift and 0.2 or 1.5)
			end
		end
	end

	function ctx.startTrade(method)
		if ctx.state.tradeRunning then return end
		if method then CFG.tradeMethod = method end
		ctx.state.tradeRunning = true
		ctx.state.status = "RUNNING"
		task.spawn(tradeLoop)
	end

	function ctx.stopTrade()
		ctx.state.tradeRunning = false
		ctx.state.status = "IDLE"
		if ctx.refreshTradeStatus then ctx.refreshTradeStatus() end
		if ctx.refreshGiftStatus then ctx.refreshGiftStatus() end
	end
end
]=],
	["modules/leveling/automation_leveling_v1.lua"] = [=[
--[[ leveling.lua — logika leveling pet otomatis (garden). ]]
return function(ctx)
	local DataService = ctx.deps.DataService
	local PetsService = ctx.deps.PetsService
	local CFG         = ctx.CFG
	local LP          = ctx.LP
	local RS          = game:GetService("ReplicatedStorage")

	local function farmCenter()
		local GetFarm = require(RS.Modules.GetFarm)
		local farm = GetFarm and GetFarm(LP)
		local pa = farm and farm:FindFirstChild("PetArea")
		if pa then return pa.Position end
		local char = LP.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		return hrp and hrp.Position or nil
	end

	local slotOf, nextSlot = {}, 0
	local GRID_COLS, GRID_SP = 6, 3
	local function getPos(uuid)
		if not slotOf[uuid] then slotOf[uuid] = nextSlot; nextSlot = nextSlot + 1 end
		local center = farmCenter()
		if not center then return nil end
		local i = slotOf[uuid]
		local col = i % GRID_COLS
		local row = math.floor(i / GRID_COLS)
		local offX = (col - (GRID_COLS - 1) / 2) * GRID_SP
		local offZ = (row - 1) * GRID_SP
		return center + Vector3.new(offX, 0, offZ)
	end

	ctx.state.levelingStatus = "Idle"

	-- Mendapatkan ringkasan statistik leveling untuk UI
	function ctx.getLevelingSummary()
		local ok, d = pcall(function() return DataService:GetData() end)
		local inv = ok and d and d.PetsData and d.PetsData.PetInventory and d.PetsData.PetInventory.Data or {}
		
		local teamCount = 0
		for _ in pairs(CFG.levelingTeamUuids) do teamCount = teamCount + 1 end
		
		local typesList = {}
		for k in pairs(CFG.levelingPetTypes) do table.insert(typesList, k) end
		table.sort(typesList)
		local typesStr = #typesList > 0 and table.concat(typesList, ", ") or "None"
		
		local readyCount = 0
		local maxLvlCount = 0
		local targetLvl = CFG.levelingTargetLevel or 500
		
		for _, v in pairs(inv) do
			local pt = v.PetType
			if CFG.levelingPetTypes[pt] then
				local pd = v.PetData or {}
				local lvl = pd.Level or 0
				if not pd.IsFavorite then
					if lvl < targetLvl then
						readyCount = readyCount + 1
					else
						maxLvlCount = maxLvlCount + 1
					end
				end
			end
		end
		
		return {
			status = CFG.levelingEnabled and "ACTIVE" or "STOPPED",
			team = string.format("%d pets selected", teamCount),
			types = typesStr,
			ready = string.format("%d pets", readyCount),
			maxLvl = string.format("%d pets", maxLvlCount),
			maxInGarden = string.format("%d pets", CFG.levelingMaxPets or 2),
			targetLevel = tostring(targetLvl),
		}
	end

	-- Mendapatkan semua tipe unik pet yang dimiliki di inventory
	function ctx.getInventoryPetTypes(selectedSet)
		local out, seen = {}, {}
		local ok, d = pcall(function() return DataService:GetData() end)
		local inv = ok and d and d.PetsData and d.PetsData.PetInventory and d.PetsData.PetInventory.Data
		if inv then
			for _, v in pairs(inv) do
				local pt = v.PetType
				if pt and not seen[pt] then
					seen[pt] = true
					table.insert(out, { value = pt, display = pt })
				end
			end
		end
		-- Selalu tampilkan tipe yang DIPILIH walau stok 0 (biar pilihan ga ilang dari filter).
		if selectedSet then
			for t in pairs(selectedSet) do
				if not seen[t] then
					seen[t] = true
					table.insert(out, { value = t, display = t .. " (0 di inventory)" })
				end
			end
		end
		table.sort(out, function(a, b)
			local selA = selectedSet and selectedSet[a.value] and 1 or 0
			local selB = selectedSet and selectedSet[b.value] and 1 or 0
			if selA ~= selB then
				return selA > selB
			end
			return a.display < b.display
		end)
		return out
	end

	local function checkLeveling()
		local ok, d = pcall(function() return DataService:GetData() end)
		if not ok or not d then return end
		local petsData = d.PetsData
		if not petsData then return end
		local eq = petsData.EquippedPets or {}
		local inv = petsData.PetInventory and petsData.PetInventory.Data or {}

		local teamSet = CFG.levelingTeamUuids or {}
		local targetTypes = CFG.levelingPetTypes or {}
		local targetLvl = CFG.levelingTargetLevel or 500
		local maxLvlPets = CFG.levelingMaxPets or 2

		-- Lacak status equip secara lokal agar kebal dari delay replikasi server
		local localEq = {}
		local localEqCount = 0
		for _, uuid in ipairs(eq) do
			localEq[uuid] = true
			localEqCount = localEqCount + 1
		end

		-- A. DETEKSI FIRST RUN: Cabut semua pet jika ada pet aktif
		if ctx.state.levelingFirstRun then
			ctx.state.levelingFirstRun = false
			if #eq > 0 then
				ctx.state.levelingStatus = "Resetting garden..."
				for _, uuid in ipairs(eq) do
					pcall(function() PetsService:FireServer("UnequipPet", uuid) end)
					localEq[uuid] = nil
					localEqCount = localEqCount - 1
					task.wait(0.25)
				end
			end
		end

		-- B. DETEKSI PERSISTENSI TEAM: Pasang kembali pet team yang dicabut oleh user/game
		for uuid, _ in pairs(teamSet) do
			if not localEq[uuid] then
				ctx.state.levelingStatus = "Re-equipping team..."
				local pos = getPos(uuid)
				if pos then
					pcall(function() PetsService:FireServer("EquipPet", uuid, CFrame.new(pos)) end)
					localEq[uuid] = true
					localEqCount = localEqCount + 1
					task.wait(0.3)
				end
			end
		end

		-- C. KLASIFIKASI PET YANG SEDANG DI-EQUIP (berdasarkan localEq terbaru)
		local currentLeveling = {}   -- list of active leveling uuids (lvl < targetLvl)
		local finishedLeveling = {}  -- list of finished leveling uuids (lvl >= targetLvl)
		local otherEquipped = {}     -- list of other uuids (not team, not target type)

		for uuid, _ in pairs(localEq) do
			if not teamSet[uuid] then
				local pInfo = inv[uuid]
				local pt = pInfo and pInfo.PetType
				local pd = pInfo and pInfo.PetData or {}
				local lvl = pd.Level or 0

				if targetTypes[pt] then
					if lvl < targetLvl then
						table.insert(currentLeveling, uuid)
						-- Catat waktu mulai jika belum ada
						ctx.state.levelingStartTime = ctx.state.levelingStartTime or {}
						if not ctx.state.levelingStartTime[uuid] then
							ctx.state.levelingStartTime[uuid] = os.time()
						end
					else
						table.insert(finishedLeveling, uuid)
					end
				else
					table.insert(otherEquipped, uuid)
				end
			end
		end

		-- D. LEPAS PET LEVELING YANG SUDAH SELESAI (mencapai target level)
		for _, uuid in ipairs(finishedLeveling) do
			local duration = 0
			if ctx.state.levelingStartTime and ctx.state.levelingStartTime[uuid] then
				duration = os.time() - ctx.state.levelingStartTime[uuid]
				ctx.state.levelingStartTime[uuid] = nil
			end

			local pInfo = inv[uuid]
			local petType = pInfo and pInfo.PetType or "Unknown"
			local pd = pInfo and pInfo.PetData or {}
			local mutation = pd.MutationType or "Normal"
			local finalAge = pd.Level or targetLvl

			pcall(function() PetsService:FireServer("UnequipPet", uuid) end)
			localEq[uuid] = nil
			localEqCount = localEqCount - 1
			task.wait(0.25)

			-- Hitung sisa antrean
			local remainsQueue = 0
			for otherUuid, v in pairs(inv) do
				local pt = v.PetType
				if targetTypes[pt] and not localEq[otherUuid] then
					local otherPd = v.PetData or {}
					local otherLvl = otherPd.Level or 0
					if otherLvl < targetLvl and not otherPd.IsFavorite then
						remainsQueue = remainsQueue + 1
					end
				end
			end

			-- Kirim Webhook Finished
			task.spawn(function()
				local WebhookLev = ctx.webhookLeveling
				if WebhookLev then
					pcall(function() WebhookLev.sendFinished(ctx, petType, mutation, finalAge, duration, remainsQueue) end)
				end
			end)
		end

		-- E. TAMBAHKAN PET BARU DARI INVENTORY
		local currentActiveCount = #currentLeveling
		local needed = maxLvlPets - currentActiveCount

		if needed > 0 then
			-- Cari pool pet di inventory yang tidak ter-equip di localEq
			local pool = {}
			for uuid, v in pairs(inv) do
				local pt = v.PetType
				local pd = v.PetData or {}
				local lvl = pd.Level or 0

				if not localEq[uuid] and targetTypes[pt] and lvl < targetLvl and not pd.IsFavorite then
					table.insert(pool, { uuid = uuid, petType = pt, level = lvl })
				end
			end
			table.sort(pool, function(a, b) return a.level < b.level end) -- Prioritaskan level terendah

			for i = 1, math.min(needed, #pool) do
				local target = pool[i]
				local pos = getPos(target.uuid)
				if pos then
					-- Jika total equipped secara lokal penuh (misal >= 15), copot non-team non-leveling
					if localEqCount >= 15 and #otherEquipped > 0 then
						local toRemove = table.remove(otherEquipped)
						pcall(function() PetsService:FireServer("UnequipPet", toRemove) end)
						localEq[toRemove] = nil
						localEqCount = localEqCount - 1
						task.wait(0.25)
					end
					
					pcall(function() PetsService:FireServer("EquipPet", target.uuid, CFrame.new(pos)) end)
					localEq[target.uuid] = true
					localEqCount = localEqCount + 1
					table.insert(currentLeveling, target.uuid)
					-- Catat waktu mulai
					ctx.state.levelingStartTime = ctx.state.levelingStartTime or {}
					ctx.state.levelingStartTime[target.uuid] = os.time()
					task.wait(0.3)
				end
			end
		end

		-- Update status akhir setelah proses
		ctx.state.levelingStatus = string.format("Leveling: %d/%d aktif", #currentLeveling, maxLvlPets)
	end

	local function levelingLoop()
		ctx.state.levelingId = (ctx.state.levelingId or 0) + 1
		local myId = ctx.state.levelingId
		ctx.elevate()
		
		ctx.state.levelingFirstRun = true

		-- Kirim webhook Enabled
		task.spawn(function()
			local WebhookLev = ctx.webhookLeveling
			if WebhookLev then
				local queueList = {}
				local teamList = {}
				local okData, d = pcall(function() return DataService:GetData() end)
				if okData and d and d.PetsData then
					local inv = d.PetsData.PetInventory and d.PetsData.PetInventory.Data or {}
					
					-- 1. Antrean pet target
					local targetTypes = CFG.levelingPetTypes or {}
					local targetLvl = CFG.levelingTargetLevel or 500
					for _, v in pairs(inv) do
						local pt = v.PetType
						if targetTypes[pt] then
							local pd = v.PetData or {}
							local lvl = pd.Level or 0
							if lvl < targetLvl then
								table.insert(queueList, { type = pt, level = lvl })
							end
						end
					end

					-- 2. Nama pet dalam EXP team
					local teamUuids = CFG.levelingTeamUuids or {}
					for uuid, _ in pairs(teamUuids) do
						local pInfo = inv[uuid]
						if pInfo then
							table.insert(teamList, pInfo.PetType)
						end
					end
				end
				pcall(function() WebhookLev.sendEnabled(ctx, queueList, teamList) end)
			end
		end)
		
		while CFG.levelingEnabled and ctx.alive() and ctx.state.levelingId == myId do
			pcall(checkLeveling)
			task.wait(3.0)
		end
		ctx.state.levelingStatus = "Idle"
	end

	function ctx.startLeveling()
		if ctx.cancelClearGarden then ctx.cancelClearGarden() end -- batalkan clear tertunda
		task.spawn(levelingLoop) -- loop set firstRun=true -> reset garden + equip team
	end

	-- Batalkan clearGarden yang mungkin lagi jalan (dipanggil saat fitur di-ENABLE lagi,
	-- biar pet team yang baru dipasang ga ke-unequip balik oleh clear yang tertunda).
	function ctx.cancelClearGarden()
		ctx.state.clearGardenId = (ctx.state.clearGardenId or 0) + 1
	end

	-- Lepas SEMUA pet dari garden (dipakai stop leveling/mutation/cleanse, mirror elephant).
	function ctx.clearGarden(label)
		ctx.state.clearGardenId = (ctx.state.clearGardenId or 0) + 1
		local myGen = ctx.state.clearGardenId
		task.spawn(function()
			if ctx.setStatus then ctx.setStatus((label or "Clear") .. ": lepas pet dari garden...") end
			task.wait(0.3)
			for _ = 1, 30 do
				if ctx.state.clearGardenId ~= myGen then return end -- dibatalkan (fitur di-enable lagi)
				local ok, d = pcall(function() return DataService:GetData() end)
				local eq = ok and d and d.PetsData and d.PetsData.EquippedPets or {}
				if #eq == 0 then break end
				for _, uuid in ipairs(eq) do
					if ctx.state.clearGardenId ~= myGen then return end
					pcall(function() PetsService:FireServer("UnequipPet", uuid) end)
					task.wait(0.2)
				end
				task.wait(0.4)
			end
			if ctx.state.clearGardenId == myGen and ctx.setStatus then ctx.setStatus((label or "Clear") .. ": garden kosong.") end
		end)
	end

	function ctx.stopLeveling()
		ctx.state.levelingId = (ctx.state.levelingId or 0) + 1 -- matikan loop
		ctx.clearGarden("Leveling")
	end
end
]=],
	["modules/leveling/automation_leveling_v2.lua"] = [=[
--[[ leveling_v2.lua — Automation Leveling V2 (2 phase).
     Konsep sama dengan V1 tapi bertahap:
       Phase 1: pakai Phase 1 Team, level target pet dari age 1 s/d Phase 1 Target,
                max Phase 1 Max Pets di garden.
       Phase 2: setelah semua target pet >= Phase 1 Target, ganti ke Phase 2 Team,
                level s/d Phase 2 Target (final), max Phase 2 Max Pets.
     Team & jumlah pet di garden beda per-phase (mis. cepat di awal, sedikit di akhir). ]]
return function(ctx)
	local DataService = ctx.deps.DataService
	local PetsService = ctx.deps.PetsService
	local CFG = ctx.CFG
	local LP  = ctx.LP
	local RS  = game:GetService("ReplicatedStorage")

	----------------------------------------------------------------- posisi grid
	local function farmCenter()
		local GetFarm = require(RS.Modules.GetFarm)
		local farm = GetFarm and GetFarm(LP)
		local pa = farm and farm:FindFirstChild("PetArea")
		if pa then return pa.Position end
		local char = LP.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		return hrp and hrp.Position or nil
	end
	local slotOf, nextSlot = {}, 0
	local GRID_COLS, GRID_SP = 6, 3
	local function getPos(uuid)
		if not slotOf[uuid] then slotOf[uuid] = nextSlot; nextSlot = nextSlot + 1 end
		local center = farmCenter()
		if not center then return nil end
		local i = slotOf[uuid]
		local col = i % GRID_COLS
		local row = math.floor(i / GRID_COLS)
		return center + Vector3.new((col - (GRID_COLS - 1) / 2) * GRID_SP, 0, (row - 1) * GRID_SP)
	end

	ctx.state.levelingV2Status = "Idle"

	----------------------------------------------------------------- ringkasan status
	function ctx.getLevelingV2Summary()
		local ok, d = pcall(function() return DataService:GetData() end)
		local inv = ok and d and d.PetsData and d.PetsData.PetInventory and d.PetsData.PetInventory.Data or {}
		local types = CFG.levelingV2PetTypes or {}
		local p1t = CFG.levelingV2P1Target or 40
		local p2t = CFG.levelingV2P2Target or 500
		local p1q, p2q, maxq = 0, 0, 0
		for _, v in pairs(inv) do
			if types[v.PetType] and not (v.PetData or {}).IsFavorite then
				local lvl = (v.PetData or {}).Level or 0
				if lvl < p1t then p1q = p1q + 1
				elseif lvl < p2t then p2q = p2q + 1
				else maxq = maxq + 1 end          -- udah >= target final = max level
			end
		end
		local function cnt(t) local n = 0; for _ in pairs(t or {}) do n = n + 1 end; return n end
		local function nm(t) local o = {}; for k in pairs(t or {}) do o[#o + 1] = k end; return #o > 0 and table.concat(o, ", ") or "-" end
		return {
			status = CFG.levelingV2Enabled and "ACTIVE" or "STOPPED",
			phase = ctx.state.levelingV2Phase or "-",
			types = nm(types),
			p1team = cnt(CFG.levelingV2P1Team), p2team = cnt(CFG.levelingV2P2Team),
			p1queue = p1q, p2queue = p2q, maxLvl = maxq,
			p1target = p1t, p2target = p2t,
		}
	end

	----------------------------------------------------------------- core check
	local function checkV2()
		local ok, d = pcall(function() return DataService:GetData() end)
		if not ok or not d then return end
		local petsData = d.PetsData
		if not petsData then return end
		local eq  = petsData.EquippedPets or {}
		local inv = petsData.PetInventory and petsData.PetInventory.Data or {}

		local targetTypes = CFG.levelingV2PetTypes or {}
		local p1Team = CFG.levelingV2P1Team or {}
		local p2Team = CFG.levelingV2P2Team or {}
		local p1Target = CFG.levelingV2P1Target or 40
		local p2Target = CFG.levelingV2P2Target or 500
		local p1Max = CFG.levelingV2P1Max or 3
		local p2Max = CFG.levelingV2P2Max or 1

		-- Tentukan phase aktif: ada target pet < p1Target -> Phase 1, else Phase 2.
		local phase1Work = 0
		for _, v in pairs(inv) do
			if targetTypes[v.PetType] and ((v.PetData or {}).Level or 0) < p1Target and not (v.PetData or {}).IsFavorite then phase1Work = phase1Work + 1 end
		end
		local phase = (phase1Work > 0) and 1 or 2
		ctx.state.levelingV2Phase = "Phase " .. phase
		local team       = (phase == 1) and p1Team or p2Team
		local otherTeam  = (phase == 1) and p2Team or p1Team
		local phaseTarget = (phase == 1) and p1Target or p2Target
		local phaseMin    = (phase == 1) and 0 or p1Target  -- batas bawah level utk phase ini
		local maxPets     = (phase == 1) and p1Max or p2Max

		-- Deteksi TRANSISI phase -> picu pembersihan garden TOTAL.
		if ctx.state.levelingV2LastPhase ~= nil and ctx.state.levelingV2LastPhase ~= phase then
			ctx.state.levelingV2Clearing = true
		end
		ctx.state.levelingV2LastPhase = phase

		local localEq = {}
		for _, uuid in ipairs(eq) do localEq[uuid] = true end

		-- A. First run / TRANSISI phase: bersihin garden TOTAL & pastikan BENAR-BENAR kosong
		-- dulu (verified) sebelum pasang team phase baru. Cegah sisa pet phase 1 nyangkut.
		if ctx.state.levelingV2FirstRun or ctx.state.levelingV2Clearing then
			if #eq > 0 then
				ctx.state.levelingV2Status = ("Phase %d: bersihin garden dulu (%d pet)..."):format(phase, #eq)
				for _, uuid in ipairs(eq) do
					pcall(function() PetsService:FireServer("UnequipPet", uuid) end)
					task.wait(0.2)
				end
				return -- cek ulang cycle berikutnya sampai garden BENAR-BENAR kosong
			end
			-- garden udah kosong -> pembersihan selesai, lanjut pasang team
			ctx.state.levelingV2FirstRun = false
			ctx.state.levelingV2Clearing = false
		end

		-- C. Pasang team phase ini + PASTIKAN LENGKAP dulu sebelum proses target pet.
		-- Cek dari data equipped asli; kalau belum lengkap, equip lalu RETURN (recheck).
		local teamComplete = true
		for uuid in pairs(team) do
			if not localEq[uuid] then
				teamComplete = false
				local pos = getPos(uuid)
				if pos then
					pcall(function() PetsService:FireServer("EquipPet", uuid, CFrame.new(pos)) end)
					task.wait(0.25)
				end
			end
		end
		if not teamComplete then
			ctx.state.levelingV2Status = ("Phase %d: nunggu team lengkap..."):format(phase)
			return -- tunggu team komplit dulu, baru proses target pet
		end

		-- D. Target pet yang lulus phase (level >= phaseTarget) -> lepas
		local active = {}
		for uuid in pairs(localEq) do
			if not team[uuid] and not otherTeam[uuid] then
				local v = inv[uuid]
				if v and targetTypes[v.PetType] then
					local pd  = v.PetData or {}
					local lvl = pd.Level or 0
					if lvl >= phaseTarget then
						-- Webhook HANYA pas phase 2 (pet mencapai target final). Phase 1 = intermediate, skip.
						if phase == 2 then
							local petType  = v.PetType or "Unknown"
							local mutation = pd.MutationType or "Normal"
							local finalAge = pd.Level or phaseTarget
							local duration = 0
							ctx.state.levelingV2StartTime = ctx.state.levelingV2StartTime or {}
							if ctx.state.levelingV2StartTime[uuid] then
								duration = os.time() - ctx.state.levelingV2StartTime[uuid]
								ctx.state.levelingV2StartTime[uuid] = nil
							end
							-- Sisa antrean phase 2 (target type, level dalam [p1Target, p2Target), belum equipped, bukan favorite)
							local remainsQueue = 0
							for ou, ov in pairs(inv) do
								if ou ~= uuid and not localEq[ou] and targetTypes[ov.PetType] then
									local ol = (ov.PetData or {}).Level or 0
									if ol >= p1Target and ol < p2Target and not (ov.PetData or {}).IsFavorite then
										remainsQueue = remainsQueue + 1
									end
								end
							end
							task.spawn(function()
								local W = ctx.webhookLeveling
								if W and W.sendFinished then
									pcall(function() W.sendFinished(ctx, petType, mutation, finalAge, duration, remainsQueue) end)
								end
							end)
						end
						pcall(function() PetsService:FireServer("UnequipPet", uuid) end)
						localEq[uuid] = nil
						task.wait(0.2)
					else
						table.insert(active, uuid)
						-- Catat waktu mulai leveling phase 2 (buat Duration di webhook)
						if phase == 2 then
							ctx.state.levelingV2StartTime = ctx.state.levelingV2StartTime or {}
							if not ctx.state.levelingV2StartTime[uuid] then
								ctx.state.levelingV2StartTime[uuid] = os.time()
							end
						end
					end
				end
			end
		end

		-- E. Tambah target pet baru buat phase ini (level dalam [phaseMin, phaseTarget))
		local needed = maxPets - #active
		if needed > 0 then
			local pool = {}
			for uuid, v in pairs(inv) do
				local lvl = (v.PetData or {}).Level or 0
				if not localEq[uuid] and targetTypes[v.PetType] and lvl >= phaseMin and lvl < phaseTarget and not (v.PetData or {}).IsFavorite then
					table.insert(pool, { uuid = uuid, level = lvl })
				end
			end
			table.sort(pool, function(a, b) return a.level < b.level end) -- level terendah dulu
			for i = 1, math.min(needed, #pool) do
				local pos = getPos(pool[i].uuid)
				if pos then
					pcall(function() PetsService:FireServer("EquipPet", pool[i].uuid, CFrame.new(pos)) end)
					localEq[pool[i].uuid] = true
					table.insert(active, pool[i].uuid)
					-- Catat waktu mulai leveling phase 2 (buat Duration di webhook)
					if phase == 2 then
						ctx.state.levelingV2StartTime = ctx.state.levelingV2StartTime or {}
						ctx.state.levelingV2StartTime[pool[i].uuid] = os.time()
					end
					task.wait(0.25)
				end
			end
		end

		ctx.state.levelingV2Status = ("Phase %d: %d/%d aktif"):format(phase, #active, maxPets)
	end

	----------------------------------------------------------------- loop
	local function loopV2()
		ctx.state.levelingV2Id = (ctx.state.levelingV2Id or 0) + 1
		local myId = ctx.state.levelingV2Id
		ctx.elevate()
		ctx.state.levelingV2FirstRun = true
		ctx.state.levelingV2LastPhase = nil -- reset biar ga false-trigger transisi di cycle pertama
		while CFG.levelingV2Enabled and ctx.alive() and ctx.state.levelingV2Id == myId do
			pcall(checkV2)
			task.wait(3)
		end
		ctx.state.levelingV2Status = "Idle"
	end

	function ctx.startLevelingV2()
		if ctx.cancelClearGarden then ctx.cancelClearGarden() end -- batalkan clear tertunda
		task.spawn(loopV2)
	end
	function ctx.stopLevelingV2()
		ctx.state.levelingV2Id = (ctx.state.levelingV2Id or 0) + 1 -- matikan loop
		if ctx.clearGarden then ctx.clearGarden("Leveling V2") end
	end
end
]=],
	["modules/leveling/webhook.lua"] = [=[
--[[ webhook/leveling.lua — Discord webhook untuk leveling.
     Di-load via HttpGet loader; sender diambil dari ctx.sendWebhook (bukan require script). ]]
local HttpService = game:GetService("HttpService")

local levelingWebhook = {}

local function formatDuration(sec)
	if not sec or sec <= 0 then return "Unknown" end
	local h = math.floor(sec / 3600)
	local m = math.floor((sec % 3600) / 60)
	local s = sec % 60
	local parts = {}
	if h > 0 then table.insert(parts, h .. "h") end
	if m > 0 then table.insert(parts, m .. "m") end
	if s > 0 or #parts == 0 then table.insert(parts, s .. "s") end
	return table.concat(parts, " ")
end

-- Webhook saat leveling di-enable
function levelingWebhook.sendEnabled(ctx, queueList, teamList, targetAge)
	local CFG = ctx.CFG
	if not CFG.webhookUrl or CFG.webhookUrl == "" then return end
	queueList = queueList or {}
	teamList = teamList or {}

	local petLines = {}
	for _, p in ipairs(queueList) do
		table.insert(petLines, string.format("> - `%s` (Level %d)", p.type, p.level))
	end
	local petsText = #petLines > 0 and table.concat(petLines, "\n") or "> - Tidak ada pet di antrean"

	local teamLines = {}
	for _, pName in ipairs(teamList) do
		table.insert(teamLines, "`" .. pName .. "`")
	end
	local teamText = #teamLines > 0 and table.concat(teamLines, ", ") or "None"

	local payload = {
		embeds = {
			{
				title = "Growth • Leveling Enabled",
				color = 3066993, -- Green
				fields = {
					{
						name = "Profile :",
						value = string.format("> Username : ||%s||", ctx.LP.Name),
						inline = false
					},
					{
						name = "Leveling Configuration",
						value = string.format(
							"> EXP Pet Team: %s\n" ..
							"> Target Age: `%s`\n" ..
							"> Queue Count: `%d`",
							teamText,
							tostring(targetAge or CFG.levelingTargetLevel or 500),
							#queueList
						),
						inline = false
					},
					{
						name = "Leveling Queue Status",
						value = petsText,
						inline = false
					}
				},
				footer = {
					text = os.date("%B %d | %I:%M %p"),
					icon_url = "https://raw.githubusercontent.com/milmscr/iniapa/main/cobainaja/Logo/logo_icon.png"
				}
			}
		}
	}
	if ctx.sendWebhook then ctx.sendWebhook(CFG.webhookUrl, payload, ctx) end
end

-- Webhook saat pet selesai leveling
function levelingWebhook.sendFinished(ctx, petType, mutation, age, durationSec, remainsQueue)
	local CFG = ctx.CFG
	if not CFG.webhookUrl or CFG.webhookUrl == "" then return end

	local mutDisplay = ctx.reg.mutDisplay and ctx.reg.mutDisplay(mutation) or mutation
	local durationStr = formatDuration(durationSec)

	local payload = {
		embeds = {
			{
				title = "Growth • Leveling",
				color = 3066993, -- Green
				fields = {
					{
						name = "Profile :",
						value = string.format("> Username : ||%s||", ctx.LP.Name),
						inline = false
					},
					{
						name = "Final Age Reached",
						value = string.format(
							"> Pet Type: `%s`\n" ..
							"> Mutation: `%s`\n" ..
							"> Age: `%s`\n" ..
							"> Duration: `%s`\n" ..
							"> Remains Queue: `%s`",
							petType,
							mutDisplay,
							tostring(age),
							durationStr,
							tostring(remainsQueue)
						),
						inline = false
					}
				},
				footer = {
					text = os.date("%B %d | %I:%M %p"),
					icon_url = "https://raw.githubusercontent.com/milmscr/iniapa/main/cobainaja/Logo/logo_icon.png"
				}
			}
		}
	}
	if ctx.sendWebhook then ctx.sendWebhook(CFG.webhookUrl, payload, ctx) end
end

return levelingWebhook
]=],
	["modules/misc/automation_reconnect.lua"] = [=[
--[[ automation_reconnect.lua — Auto Reconnect/Rejoin tiap interval (Misc).
     Tiap X menit: queue loader (biar hub auto jalan lagi abis rejoin) lalu
     teleport ke server yg SAMA (reconnect), fallback server baru kalau gagal.
     Config: CFG.reconnectEnabled (toggle), CFG.reconnectInterval (menit).
     Fungsi: ctx.startReconnect. Auto-resume di app.lua biar loop lanjut tiap masuk. ]]
return function(ctx)
	local LP  = ctx.LP
	local CFG = ctx.CFG
	local TeleportService = game:GetService("TeleportService")
	local function setStatus(s) ctx.setStatus(s) end

	local branch = (getgenv and getgenv().GAG_BRANCH) or _G.GAG_BRANCH or "main"

	-- queue loader hub biar auto jalan lagi setelah rejoin (branch dijaga).
	local function queueLoader()
		local q = (syn and syn.queue_on_teleport) or queue_on_teleport
			or (fluxus and fluxus.queue_on_teleport) or (getgenv and getgenv().queue_on_teleport)
		if q then
			local cmd = ('if getgenv then getgenv().GAG_BRANCH=%q end loadstring(game:HttpGet("https://raw.githubusercontent.com/milmscr/iniapa/%s/cobainaja/init.lua"))()'):format(branch, branch)
			pcall(function() q(cmd) end)
		end
	end

	-- Cache reference Teleport SEKARANG (bukan pas dipanggil) biar bypass hook
	-- __namecall yg mungkin dipasang game buat block teleport pihak-3.
	local TeleportFn = TeleportService.Teleport

	local function doReconnect()
		queueLoader()
		task.wait(0.4)
		-- Teleport(placeId, player) via cached-ref. Pas di private server, Roblox
		-- rejoin ke private server juga (bukan publik) -> stay private. Kalau di
		-- server publik, ke publik. TeleportToPlaceInstance JANGAN dipakai (773 +
		-- diblok buat private).
		local ok = pcall(function() TeleportFn(TeleportService, game.PlaceId, LP) end)
		if not ok then
			pcall(function() TeleportService:Teleport(game.PlaceId, LP) end)
		end
	end

	local function reconnectLoop(myId)
		while CFG.reconnectEnabled and ctx.alive() and ctx.state.reconnectId == myId do
			local mins = tonumber(CFG.reconnectInterval) or 5
			if mins <= 0 then mins = 5 end
			local total = mins * 60
			local t0 = os.clock()
			while os.clock() - t0 < total do
				if not CFG.reconnectEnabled or ctx.state.reconnectId ~= myId or not ctx.alive() then
					ctx.state.reconnectRemaining = nil; return
				end
				local rem = math.ceil(total - (os.clock() - t0))
				ctx.state.reconnectRemaining = rem
				setStatus(("Reconnect: %d dtk lagi"):format(rem))
				task.wait(1)
			end
			if CFG.reconnectEnabled and ctx.state.reconnectId == myId then
				setStatus("Reconnect: rejoin...")
				doReconnect()
				return -- instance ini bakal ilang setelah teleport
			end
		end
	end

	function ctx.startReconnect()
		ctx.state.reconnectId = (ctx.state.reconnectId or 0) + 1
		local myId = ctx.state.reconnectId
		task.spawn(function() reconnectLoop(myId) end)
	end

	ctx.reconnect = doReconnect
end
]=],
	["modules/misc/esp_inventory.lua"] = [=[
--[[ esp_inventory.lua — ESP Base Weight di INVENTORY (Pet Items).
     Nempel label kecil "Base X.XX KG" di tiap slot pet di backpack GUI,
     jadi pas buka inventory langsung keliatan BaseWeight tiap pet.
     Mapping: slot.ToolName.Text == Tool.Name -> Tool.PET_UUID ->
              PetData.BaseWeight (dari DataService).
     Toggle: CFG.espInvEnabled. ]]
return function(ctx)
	local RS = game:GetService("ReplicatedStorage")
	local LP = ctx.LP
	local DataService = ctx.deps.DataService

	local GRID_PATH   = { "BackpackGui", "Backpack", "Inventory", "ScrollingFrame", "UIGridFrame" }
	local HOTBAR_PATH = { "BackpackGui", "Backpack", "Hotbar" }
	local LBL_NAME    = "AH_BaseW" -- label yg kita tempel di slot

	local function byPath(path)
		local n = LP:FindFirstChild("PlayerGui")
		for _, seg in ipairs(path) do
			if not n then return nil end
			n = n:FindFirstChild(seg)
		end
		return n
	end
	-- container slot pet: grid inventory + hotbar (bar bawah, termasuk pet yg dipegang).
	local function containers()
		local out = {}
		local g = byPath(GRID_PATH);   if g then out[#out + 1] = g end
		local h = byPath(HOTBAR_PATH); if h then out[#out + 1] = h end
		return out
	end

	-- map Tool.Name -> {base, level} (cuma pet). Dibangun tiap refresh (murah).
	local function buildWeightMap()
		local ok, d = pcall(function() return DataService:GetData() end)
		local inv = ok and d and d.PetsData and d.PetsData.PetInventory and d.PetsData.PetInventory.Data or {}
		local byUuid = {}
		for uuid, v in pairs(inv) do
			local pd = v.PetData or {}
			if pd.BaseWeight then byUuid[uuid] = { base = pd.BaseWeight, level = pd.Level or 0 } end
		end
		local byName = {}
		local function scan(where)
			if not where then return end
			for _, t in ipairs(where:GetChildren()) do
				if t:IsA("Tool") and t:GetAttribute("ItemType") == "Pet" then
					local uuid = t:GetAttribute("PET_UUID")
					local e = uuid and byUuid[uuid]
					if e and byName[t.Name] == nil then byName[t.Name] = e end
				end
			end
		end
		scan(LP.Character)
		scan(LP:FindFirstChildOfClass("Backpack"))
		return byName
	end

	-- Game: Weight = BaseWeight * (1 + 0.1*Level). MAX_LEVEL = umur 500.
	-- Berat "dasar" (level dasar) yg biasa dilihat = BaseWeight * 1.1, di-floor
	-- 1 desimal — persis game (5.5 base -> 6.0, 5.6 -> 6.1). Max = base*(1+0.1*500).
	local WEIGHT_MULT = 1.1
	local MAX_LEVEL   = 500
	local function floor1(n) return math.floor(n * 10) / 10 end
	local function baseKG(bw) return floor1(bw * WEIGHT_MULT) end
	local function maxKG(bw)  return floor1(bw * (1 + 0.1 * MAX_LEVEL)) end

	-- teks label sesuai mode CFG.espInvMode ("base" / "age" / "max").
	local function labelText(e)
		local base = baseKG(e.base)
		local mode = ctx.CFG.espInvMode
		if mode == "max" then
			return ("%.1f \u{2192} %.1f KG"):format(base, maxKG(e.base))
		elseif mode == "base" then
			return ("%.1f KG"):format(base)
		end
		return ("%.1f KG A%d"):format(base, e.level or 0)
	end

	-- tempel/refresh label di slot; hapus dari slot non-pet.
	local function setLabel(slot, e)
		local lbl = slot:FindFirstChild(LBL_NAME)
		if not e then
			if lbl then lbl:Destroy() end
			return
		end
		if not lbl then
			lbl = Instance.new("TextLabel")
			lbl.Name = LBL_NAME
			lbl.AnchorPoint = Vector2.new(0.5, 1)
			lbl.Position = UDim2.new(0.5, 0, 1, 0)
			lbl.Size = UDim2.new(1, 0, 0, 15)
			lbl.BackgroundColor3 = Color3.fromRGB(24, 10, 32)
			lbl.BackgroundTransparency = 0.15
			lbl.Font = Enum.Font.MontserratBold
			lbl.TextSize = 11
			lbl.TextScaled = true -- auto-fit biar muat di slot sempit
			lbl.TextColor3 = Color3.fromRGB(255, 215, 240) -- soft pastel rose
			lbl.TextStrokeTransparency = 0.4
			lbl.TextStrokeColor3 = Color3.fromRGB(60, 10, 40)
			lbl.ZIndex = 20
			lbl.RichText = false
			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0, 4)
			corner.Parent = lbl
			local str = Instance.new("UIStroke")
			str.Color = Color3.fromRGB(255, 95, 175)
			str.Transparency = 0.4
			str.Thickness = 1
			str.Parent = lbl
			local con = Instance.new("UITextSizeConstraint")
			con.MaxTextSize = 12
			con.Parent = lbl
			lbl.Parent = slot
		end
		lbl.Text = labelText(e)
	end

	local function clearAll()
		for _, c in ipairs(containers()) do
			for _, slot in ipairs(c:GetChildren()) do
				if slot:IsA("GuiButton") then
					local lbl = slot:FindFirstChild(LBL_NAME)
					if lbl then lbl:Destroy() end
				end
			end
		end
	end

	local function update()
		local cs = containers()
		if #cs == 0 then return end
		local byName = buildWeightMap()
		for _, c in ipairs(cs) do
			for _, slot in ipairs(c:GetChildren()) do
				if slot:IsA("GuiButton") then
					local tn = slot:FindFirstChild("ToolName")
					local name = tn and tn:IsA("TextLabel") and tn.Text or nil
					setLabel(slot, name and byName[name] or nil)
				end
			end
		end
	end

	local loopId = 0
	function ctx.startEspInv()
		loopId = loopId + 1
		local my = loopId
		task.spawn(function()
			while ctx.alive() and ctx.CFG.espInvEnabled and loopId == my do
				pcall(update)
				task.wait(0.5)
			end
			pcall(clearAll)
		end)
	end

	function ctx.stopEspInv()
		loopId = loopId + 1
		pcall(clearAll)
	end
end
]=],
	["modules/misc/esp_label.lua"] = [=[
--[[ esp.lua — label melayang (BillboardGui) di dunia 3D di atas tiap egg.
     Egg: nama egg + ISI-nya (pet yang bakal menetas + berat) dari
          SaveSlots.AllSlots.<slot>.SavedObjects.<uuid>.Data (Type/BaseWeight),
          fallback sisa waktu hatch / READY.
     Toggle: CFG.espEnabled. ]]
return function(ctx)
	local RS = game:GetService("ReplicatedStorage")
	local LP = ctx.LP
	local DataService = ctx.deps.DataService

	-- Game nampilin berat = BaseWeight * 1.1 (bukan raw BaseWeight).
	local WEIGHT_MULT = 1.1

	local bbFolder
	local billboards = {} -- key -> { gui, lbl }
	local eggSlotKey  -- cache slot aktif yg nyimpen SavedObjects

	local function ensureFolder()
		if bbFolder and bbFolder.Parent then return bbFolder end
		bbFolder = Instance.new("Folder")
		bbFolder.Name = "AllegiaanESP"
		bbFolder.Parent = (gethui and gethui()) or game:GetService("CoreGui")
		return bbFolder
	end

	local function partOf(model)
		if model:IsA("BasePart") then return model end
		if model.PrimaryPart then return model.PrimaryPart end
		for _, d in ipairs(model:GetDescendants()) do if d:IsA("BasePart") then return d end end
		return nil
	end

	local function makeBB(key, adornee, offset)
		local bb = Instance.new("BillboardGui")
		bb.Name = "esp_" .. key
		bb.Adornee = adornee
		bb.Size = UDim2.fromOffset(260, 72)
		bb.StudsOffset = Vector3.new(0, offset or 2.8, 0)
		bb.AlwaysOnTop = true
		bb.MaxDistance = 600
		bb.LightInfluence = 0
		bb.ClipsDescendants = false
		bb.Parent = ensureFolder()

		-- Background card (translucent dark pink)
		local bg = Instance.new("Frame")
		bg.Size = UDim2.new(1, 0, 1, 0)
		bg.BackgroundColor3 = Color3.fromRGB(18, 6, 26)
		bg.BackgroundTransparency = 0.22
		bg.BorderSizePixel = 0
		bg.Parent = bb
		Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 10)
		local bgStroke = Instance.new("UIStroke", bg)
		bgStroke.Color = Color3.fromRGB(255, 55, 145)
		bgStroke.Thickness = 1.4
		bgStroke.Transparency = 0.3
		bgStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

		-- Top accent glow strip
		local topBar = Instance.new("Frame")
		topBar.Size = UDim2.new(0.7, 0, 0, 2)
		topBar.Position = UDim2.new(0.15, 0, 0, 0)
		topBar.BackgroundColor3 = Color3.fromRGB(255, 135, 205)
		topBar.BackgroundTransparency = 0.1
		topBar.BorderSizePixel = 0
		topBar.ZIndex = 3
		topBar.Parent = bg
		Instance.new("UICorner", topBar).CornerRadius = UDim.new(0, 2)

		local lbl = Instance.new("TextLabel")
		lbl.BackgroundTransparency = 1
		lbl.Size = UDim2.new(1, -8, 1, 0)
		lbl.Position = UDim2.fromOffset(4, 0)
		lbl.Font = Enum.Font.FredokaOne
		lbl.TextSize = 15
		lbl.RichText = true
		lbl.TextColor3 = Color3.new(1, 1, 1)
		lbl.TextStrokeTransparency = 0.5
		lbl.TextStrokeColor3 = Color3.fromRGB(120, 0, 60)
		lbl.TextYAlignment = Enum.TextYAlignment.Center
		lbl.ZIndex = 4
		lbl.Parent = bg

		local rec = { gui = bb, lbl = lbl }
		billboards[key] = rec
		return rec
	end

	local function acquire(key, adornee, offset)
		local rec = billboards[key]
		if (not rec) or rec.gui.Adornee ~= adornee or not rec.gui.Parent then
			if rec then rec.gui:Destroy(); billboards[key] = nil end
			rec = makeBB(key, adornee, offset)
		end
		return rec
	end

	local function fmtTime(sec)
		sec = math.max(0, math.floor(sec))
		local m = math.floor(sec / 60)
		local s = sec % 60
		if m >= 60 then local h = math.floor(m / 60); m = m % 60; return string.format("%dh %dm", h, m) end
		return string.format("%dm %02ds", m, s)
	end

	-- Data isi egg (pet yg bakal menetas + berat) dari SavedObjects by uuid.
	local function eggDataOf(uuid)
		if not uuid then return nil end
		local ok, d = pcall(function() return DataService:GetData() end)
		local slots = ok and d and d.SaveSlots and d.SaveSlots.AllSlots
		if not slots then return nil end
		-- coba slot yg di-cache dulu
		local s = eggSlotKey and slots[eggSlotKey]
		if s and s.SavedObjects and s.SavedObjects[uuid] then return s.SavedObjects[uuid].Data end
		-- scan semua slot
		for sn, slot in pairs(slots) do
			if type(slot) == "table" and slot.SavedObjects and slot.SavedObjects[uuid] then
				eggSlotKey = sn
				return slot.SavedObjects[uuid].Data
			end
		end
		return nil
	end

	local function eggNameFallback(e)
		local n = e:GetAttribute("EggName")
		if not n or n == "" then
			for _, c in ipairs(e:GetChildren()) do if c:IsA("Model") then n = c.Name; break end end
		end
		return n or "Egg"
	end

	local function update()
		local seen = {}

		-- ===== EGG (nama + isi: pet + berat) =====
		local farm; pcall(function() farm = require(RS.Modules.GetFarm)(LP) end)
		if farm then
			for _, e in ipairs(farm:GetDescendants()) do
				if e:IsA("Model") and e.Name == "PetEgg" and e:GetAttribute("OWNER") == LP.Name then
					local adornee = e:FindFirstChild("PetEgg") or partOf(e)
					if adornee then
						local uuid = e:GetAttribute("OBJECT_UUID")
						local key = "egg_" .. tostring(uuid or e:GetDebugId())
						seen[key] = true
						local rec = acquire(key, adornee, 3)
						local data = eggDataOf(uuid)
						local lines = { ("<font color='#FF87CD'><b>🥚 %s</b></font>"):format(eggNameFallback(e)) }
						if data and data.Type then
							lines[#lines + 1] = ("<font color='#FF3791'>%s</font>"):format(tostring(data.Type))
							local w = tonumber(data.BaseWeight)
							if w then lines[#lines + 1] = ("<font color='#FFD7F0'>%.2f KG</font>"):format(w * WEIGHT_MULT) end
						end
						local t = tonumber(e:GetAttribute("TimeToHatch")) or (data and tonumber(data.TimeToHatch)) or 0
						if t > 0 then
							lines[#lines + 1] = ("<font color='#FFB4CD'>⏱ %s</font>"):format(fmtTime(t))
						elseif not (data and data.Type) then
							lines[#lines + 1] = "<font color='#6EF5B9'><b>READY</b></font>"
						end
						rec.lbl.Text = table.concat(lines, "\n")
					end
				end
			end
		end

		-- ===== PET (nama + berat + lv) =====
		local okData, d = pcall(function() return DataService:GetData() end)
		local inv = okData and d and d.PetsData and d.PetsData.PetInventory and d.PetsData.PetInventory.Data or {}
		local pp = workspace:FindFirstChild("PetsPhysical")
		if pp then
			for _, mover in ipairs(pp:GetChildren()) do
				for _, petModel in ipairs(mover:GetChildren()) do
					if petModel:IsA("Model") then
						local uuid = petModel.Name
						local pData = inv[uuid]
						if pData then
							local adornee = partOf(petModel)
							if adornee then
								local key = "pet_" .. tostring(uuid)
								seen[key] = true
								local rec = acquire(key, adornee, 2.5)
								local pt = pData.PetType or "Pet"
								local pd = pData.PetData or {}
								local bw = tonumber(pd.BaseWeight)
								local lv = tonumber(pd.Level) or 0
								local mut = pd.MutationType

								local lines = { ("<font color='#FF5FA0'><b>🐾 %s</b></font>"):format(tostring(pt)) }
								if bw then
									lines[#lines + 1] = ("<font color='#FFD7F0'>%.2f KG</font> <font color='#FF87CD'>[Lv.%d]</font>"):format(bw * WEIGHT_MULT, lv)
								end
								if mut and mut ~= "" and mut ~= "Normal" and mut ~= "m" then
									lines[#lines + 1] = ("<font color='#6EF5B9'>✨ %s</font>"):format(tostring(mut))
								end
								rec.lbl.Text = table.concat(lines, "\n")
							end
						end
					end
				end
			end
		end

		for key, rec in pairs(billboards) do
			if not seen[key] then rec.gui:Destroy(); billboards[key] = nil end
		end
	end

	local function clearAll()
		for _, rec in pairs(billboards) do pcall(function() rec.gui:Destroy() end) end
		billboards = {}
		if bbFolder then pcall(function() bbFolder:Destroy() end); bbFolder = nil end
	end

	local loopId = 0
	function ctx.startEsp()
		loopId = loopId + 1
		local my = loopId
		task.spawn(function()
			while ctx.alive() and ctx.CFG.espEnabled and loopId == my do
				pcall(update)
				task.wait(0.5)
			end
			clearAll()
		end)
	end

	function ctx.stopEsp()
		loopId = loopId + 1
		clearAll()
	end
end
]=],
	["modules/misc/perf_mods.lua"] = [=[
--[[ perf_mods.lua — Performance / Graphics Optimization.
     - Hide My/Other Garden Plants : sembunyiin plant (LocalTransparencyModifier) buat FPS.
     - Auto Remove Spider Web FX    : hapus particle/trail/beam efek web terus-menerus.
     - Performance Mode (off/low/extreme) : matiin shadow & (extreme) semua efek partikel.
     - Disable 3D Rendering          : RunService:Set3dRenderingEnabled(false).
     Toggle: CFG.hideMyPlants / hideOtherPlants / autoRemoveWebFx / perfMode / disable3d. ]]
return function(ctx)
	local RS  = game:GetService("ReplicatedStorage")
	local RunService = game:GetService("RunService")
	local Lighting = game:GetService("Lighting")
	local LP  = ctx.LP
	local CFG = ctx.CFG

	local function myFarm()
		local f; pcall(function() f = require(RS.Modules.GetFarm)(LP) end)
		return f
	end
	-- iterasi Plants_Physical: which = "mine" / "other"
	local function eachPlantContainer(which, fn)
		local Farm = workspace:FindFirstChild("Farm"); if not Farm then return end
		local mine = myFarm()
		for _, g in ipairs(Farm:GetChildren()) do
			local isMine = (g == mine)
			if (which == "mine" and isMine) or (which == "other" and not isMine) then
				local imp = g:FindFirstChild("Important")
				local pp = imp and imp:FindFirstChild("Plants_Physical")
				if pp then fn(pp) end
			end
		end
	end

	------------------------------------------------------------------- hide plants
	local function applyHide(which, hidden)
		eachPlantContainer(which, function(pp)
			for _, d in ipairs(pp:GetDescendants()) do
				if d:IsA("BasePart") then d.LocalTransparencyModifier = hidden and 1 or 0 end
			end
		end)
	end

	local hideConn
	local function hideLoopActive() return CFG.hideMyPlants or CFG.hideOtherPlants end
	local function ensureHideLoop()
		if hideConn then return end
		hideConn = task.spawn(function()
			while ctx.alive() and hideLoopActive() do
				if CFG.hideMyPlants then applyHide("mine", true) end
				if CFG.hideOtherPlants then applyHide("other", true) end
				task.wait(1) -- catch plant baru; ga perlu tiap frame
			end
			hideConn = nil
		end)
	end
	function ctx.setHidePlants(which, v)
		if which == "mine" then CFG.hideMyPlants = v else CFG.hideOtherPlants = v end
		if v then ensureHideLoop() else applyHide(which, false) end
	end

	------------------------------------------------------------------- spider web FX
	local WEB_MATCH = { "web", "spider", "cobweb" }
	local WEB_CLASS = { ParticleEmitter = true, Trail = true, Beam = true, Decal = true, Texture = true }
	local function isWeb(d)
		if not WEB_CLASS[d.ClassName] then return false end
		local n = d.Name:lower()
		for _, m in ipairs(WEB_MATCH) do if n:find(m) then return true end end
		return false
	end
	local webConn
	function ctx.setAutoRemoveWeb(v)
		CFG.autoRemoveWebFx = v
		if v then
			if webConn then return end
			webConn = task.spawn(function()
				while ctx.alive() and CFG.autoRemoveWebFx do
					for _, d in ipairs(workspace:GetDescendants()) do
						if isWeb(d) then pcall(function() d:Destroy() end) end
					end
					task.wait(1)
				end
				webConn = nil
			end)
		end
	end

	------------------------------------------------------------------- performance mode
	local FX_CLASS = { ParticleEmitter = true, Trail = true, Beam = true, Fire = true, Smoke = true, Sparkles = true, Explosion = true }
	local function setAllFxEnabled(on)
		for _, d in ipairs(workspace:GetDescendants()) do
			if FX_CLASS[d.ClassName] then pcall(function() d.Enabled = on end) end
		end
	end
	local pmConn
	local function stopPmLoop() if pmConn then task.cancel(pmConn); pmConn = nil end end
	function ctx.setPerfMode(mode)
		CFG.perfMode = mode
		stopPmLoop()
		if mode == "off" then
			pcall(function() Lighting.GlobalShadows = true end)
			setAllFxEnabled(true)
		elseif mode == "low" then
			pcall(function() Lighting.GlobalShadows = false end)
		elseif mode == "extreme" then
			pcall(function() Lighting.GlobalShadows = false end)
			-- terus-terusan matiin efek partikel (extreme FPS)
			pmConn = task.spawn(function()
				while ctx.alive() and CFG.perfMode == "extreme" do
					setAllFxEnabled(false)
					task.wait(1.5)
				end
			end)
		end
	end
	function ctx.getPerfModeOptions()
		return { { name = "off", display = "Off" }, { name = "low", display = "Low" }, { name = "extreme", display = "Extreme" } }
	end

	------------------------------------------------------------------- disable 3D
	function ctx.setDisable3d(v)
		CFG.disable3d = v
		ctx.elevate()
		pcall(function() RunService:Set3dRenderingEnabled(not v) end)
	end
end
]=],
	["modules/misc/player_mods.lua"] = [=[
--[[ player_mods.lua — utilitas Player: Noclip, Walk Speed, Infinity Jump.
     Semua toggle-able & guarded (auto re-apply tiap frame selama aktif).
     Toggle: CFG.noclipEnabled / CFG.walkSpeedEnabled (+CFG.walkSpeed) / CFG.infJumpEnabled. ]]
return function(ctx)
	local RunService = game:GetService("RunService")
	local UIS = game:GetService("UserInputService")
	local LP  = ctx.LP
	local CFG = ctx.CFG
	local DEFAULT_WS = 16

	local function char() return LP.Character end
	local function hum()
		local c = char()
		return c and c:FindFirstChildOfClass("Humanoid")
	end

	------------------------------------------------------------------- NOCLIP
	local noclipConn
	local function startNoclip()
		if noclipConn then return end
		noclipConn = RunService.Stepped:Connect(function()
			local c = char()
			if not c then return end
			for _, p in ipairs(c:GetDescendants()) do
				if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end
			end
		end)
	end
	local function stopNoclip()
		if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
	end
	function ctx.setNoclip(v)
		CFG.noclipEnabled = v
		if v then startNoclip() else stopNoclip() end
	end

	------------------------------------------------------------------- WALK SPEED
	local wsConn
	local function startWS()
		if wsConn then return end
		wsConn = RunService.Stepped:Connect(function()
			local h = hum()
			if h then
				local target = tonumber(CFG.walkSpeed) or DEFAULT_WS
				if h.WalkSpeed ~= target then h.WalkSpeed = target end
			end
		end)
	end
	local function stopWS()
		if wsConn then wsConn:Disconnect(); wsConn = nil end
		local h = hum()
		if h then h.WalkSpeed = DEFAULT_WS end
	end
	function ctx.setWalkSpeed(v)
		CFG.walkSpeedEnabled = v
		if v then startWS() else stopWS() end
	end
	-- dipanggil pas nilai input berubah (biar langsung kepakai kalau lagi ON)
	function ctx.applyWalkSpeed()
		if not CFG.walkSpeedEnabled then return end
		local h = hum()
		if h then h.WalkSpeed = tonumber(CFG.walkSpeed) or DEFAULT_WS end
	end

	------------------------------------------------------------------- INFINITY JUMP
	local jumpConn
	local function startInfJump()
		if jumpConn then return end
		jumpConn = UIS.JumpRequest:Connect(function()
			local h = hum()
			if h then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end
		end)
	end
	local function stopInfJump()
		if jumpConn then jumpConn:Disconnect(); jumpConn = nil end
	end
	function ctx.setInfJump(v)
		CFG.infJumpEnabled = v
		if v then startInfJump() else stopInfJump() end
	end
end
]=],
	["modules/mutation/automation_mutation_machine.lua"] = [=[
--[[ mutation.lua — logika mesin mutasi pet otomatis (garden). ]]
return function(ctx)
	local DataService = ctx.deps.DataService
	local PetsService = ctx.deps.PetsService
	local CFG         = ctx.CFG
	local LP          = ctx.LP
	local RS          = game:GetService("ReplicatedStorage")
	local TimeHelper  = require(RS.Modules.TimeHelper)
	local PetMutationMachineService_RE = RS:WaitForChild("GameEvents").PetMutationMachineService_RE

	local function farmCenter()
		local GetFarm = require(RS.Modules.GetFarm)
		local farm = GetFarm and GetFarm(LP)
		local pa = farm and farm:FindFirstChild("PetArea")
		if pa then return pa.Position end
		local char = LP.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		return hrp and hrp.Position or nil
	end

	local function cleanUuid(u)
		if not u then return "" end
		return tostring(u):lower():gsub("[{}]", "")
	end

	local function hasTargetMutation(pd, targetMutations)
		if not pd then return false end
		local mut = pd.MutationType
		local display = ctx.reg.mutDisplay and ctx.reg.mutDisplay(mut) or tostring(mut or "None")
		return targetMutations[display] == true
	end

	local slotOf, nextSlot = {}, 0
	local GRID_COLS, GRID_SP = 6, 3
	local function getPos(uuid)
		if not slotOf[uuid] then slotOf[uuid] = nextSlot; nextSlot = nextSlot + 1 end
		local center = farmCenter()
		if not center then return nil end
		local i = slotOf[uuid]
		local col = i % GRID_COLS
		local row = math.floor(i / GRID_COLS)
		local offX = (col - (GRID_COLS - 1) / 2) * GRID_SP
		local offZ = (row - 1) * GRID_SP
		return center + Vector3.new(offX, 0, offZ)
	end

	-- Helper untuk memastikan tim pet terpasang 100% dengan benar (dengan retry loop)
	local function ensureEquippedTeam(targetTeamSet, targetPetUuid)
		local targetActive = {}
		if targetPetUuid then
			targetActive[cleanUuid(targetPetUuid)] = true
		end
		for u, _ in pairs(targetTeamSet) do
			targetActive[cleanUuid(u)] = true
		end

		for attempt = 1, 3 do
			local ok, d = pcall(function() return DataService:GetData() end)
			if not ok or not d or not d.PetsData then break end
			local eq = d.PetsData.EquippedPets or {}
			
			local localEq = {}
			for _, uuid in ipairs(eq) do
				localEq[cleanUuid(uuid)] = true
			end

			-- 1. Lepas pet yang tidak diijinkan berada di garden
			local unequippedAny = false
			for _, uuid in ipairs(eq) do
				local cu = cleanUuid(uuid)
				if not targetActive[cu] then
					pcall(function() PetsService:FireServer("UnequipPet", uuid) end)
					unequippedAny = true
					task.wait(0.1)
				end
			end

			-- 2. Pasang target pet (jika leveling)
			local equippedAny = false
			if targetPetUuid and not localEq[cleanUuid(targetPetUuid)] then
				local pos = getPos(targetPetUuid)
				if pos then
					pcall(function() PetsService:FireServer("EquipPet", targetPetUuid, CFrame.new(pos)) end)
					equippedAny = true
					task.wait(0.1)
				end
			end

			-- 3. Pasang sisa anggota team yang belum terpasang
			for uuid, _ in pairs(targetTeamSet) do
				local cu = cleanUuid(uuid)
				if not localEq[cu] then
					local pos = getPos(uuid)
					if pos then
						pcall(function() PetsService:FireServer("EquipPet", uuid, CFrame.new(pos)) end)
						equippedAny = true
						task.wait(0.1)
					end
				end
			end

			-- Jika tidak ada aktivitas unequip/equip lagi, berarti kebun sudah sinkron
			if not unequippedAny and not equippedAny then
				break
			end
			task.wait(0.3)
		end

		-- Verifikasi kelengkapan: SEMUA anggota target harus benar-benar ke-equip (no miss).
		local ok, d = pcall(function() return DataService:GetData() end)
		local eq = ok and d and d.PetsData and d.PetsData.EquippedPets or {}
		local eqSet = {}
		for _, uuid in ipairs(eq) do eqSet[cleanUuid(uuid)] = true end
		for cu in pairs(targetActive) do
			if not eqSet[cu] then return false end
		end
		return true
	end

	ctx.state.mutationStatus = "Idle"
	ctx.state.mutationPhase = "Idle"

	-- Mendapatkan ringkasan statistik mutation untuk UI
	function ctx.getMutationSummary()
		local ok, d = pcall(function() return DataService:GetData() end)
		local inv = ok and d and d.PetsData and d.PetsData.PetInventory and d.PetsData.PetInventory.Data or {}
		local machine = ok and d and d.PetMutationMachine or {}

		local expCount = 0
		for _ in pairs(CFG.mutationExpTeam) do expCount = expCount + 1 end

		local boostCount = 0
		for _ in pairs(CFG.mutationBoostTeam) do boostCount = boostCount + 1 end

		local phoenixCount = 0
		for _ in pairs(CFG.mutationPhoenixTeam) do phoenixCount = phoenixCount + 1 end

		local typesList = {}
		for k in pairs(CFG.mutationTargetTypes) do table.insert(typesList, k) end
		table.sort(typesList)
		local typesStr = #typesList > 0 and table.concat(typesList, ", ") or "None"

		local mutsList = {}
		for k in pairs(CFG.mutationTargetMutations) do table.insert(mutsList, k) end
		table.sort(mutsList)
		local mutsStr = #mutsList > 0 and table.concat(mutsList, ", ") or "None"

		local targetAge = CFG.mutationTargetAge or 50

		-- Info mesin
		local machineStr = "Empty"
		if machine.SubmittedPet then
			local pt = machine.SubmittedPet.PetType or "?"
			local mut = machine.SubmittedPet.PetData and machine.SubmittedPet.PetData.MutationType or "Normal"
			local mutName = ctx.reg.mutDisplay and ctx.reg.mutDisplay(mut) or mut
			machineStr = string.format("%s | %s", pt, mutName)
			if machine.PetReady then
				machineStr = machineStr .. " [Ready]"
			elseif machine.IsRunning or (machine.TimeLeft and machine.TimeLeft > 0) then
				local v2 = TimeHelper:GenerateColonFormatFromTime(machine.TimeLeft) or "00:00"
				machineStr = machineStr .. string.format(" [CD: %s]", v2)
			end
		end

		local readyCount = 0
		local doneCount = 0

		for _, v in pairs(inv) do
			local pt = v.PetType
			if CFG.mutationTargetTypes[pt] then
				local pd = v.PetData or {}
				local lvl = pd.Level or 0
				local mut = pd.MutationType or "Normal"
				local isFav = pd.IsFavorite or false

				if not isFav then
					if hasTargetMutation(pd, CFG.mutationTargetMutations) then
						doneCount = doneCount + 1
					else
						-- Belum punya mutasi target = masih perlu diproses (bakal di-leveling
						-- dulu kalau age belum cukup, lalu di-submit). Hitung semua, lepas dari level.
						readyCount = readyCount + 1
					end
				end
			end
		end

		return {
			status = CFG.mutationEnabled and "ACTIVE" or "STOPPED",
			phase = ctx.state.mutationPhase or "Idle",
			expCount = expCount,
			boostCount = boostCount,
			phoenixCount = phoenixCount,
			types = typesStr,
			mutations = mutsStr,
			targetAge = targetAge,
			machine = machineStr,
			readyCount = readyCount,
			doneCount = doneCount,
		}
	end

	local function checkMutation()
		local ok, d = pcall(function() return DataService:GetData() end)
		if not ok or not d then return end
		local petsData = d.PetsData
		local machine = d.PetMutationMachine
		if not petsData or not machine then return end
		local eq = petsData.EquippedPets or {}
		local inv = petsData.PetInventory and petsData.PetInventory.Data or {}

		local expTeam = CFG.mutationExpTeam or {}
		local boostTeam = CFG.mutationBoostTeam or {}
		local phoenixTeam = CFG.mutationPhoenixTeam or {}
		local targetTypes = CFG.mutationTargetTypes or {}
		local targetMutations = CFG.mutationTargetMutations or {}
		local targetAge = CFG.mutationTargetAge or 50
		local delayClaim = CFG.mutationDelayAutoClaim or 0.5

		-- CATATAN: passing team ASLI (uuid ber-kurawal) ke ensureEquippedTeam. cleanUuid dipakai
		-- HANYA buat matching di dalam fungsi; EquipPet butuh uuid format asli (dengan {}).

		-- A. DETEKSI APAKAH PET READY UNTUK DICLAIM
		if machine.PetReady then
			-- Validasi Phoenix team LENGKAP dulu (no miss) sebelum claim.
			if not ensureEquippedTeam(phoenixTeam) then
				ctx.state.mutationPhase = "Menunggu Phoenix Team lengkap..."
				return
			end
			ctx.state.mutationPhase = "Claiming Pet"

			-- Tunggu delay klaim
			task.wait(delayClaim)
			
			-- 1. Ambil snapshot mutasi pet di inventory sebelum klaim
			local preSnapshot = {}
			local okSnap, snapD = pcall(function() return DataService:GetData() end)
			if okSnap and snapD and snapD.PetsData then
				local invD = snapD.PetsData.PetInventory and snapD.PetsData.PetInventory.Data or {}
				for u, v in pairs(invD) do
					if targetTypes[v.PetType] then
						preSnapshot[u] = v.PetData and v.PetData.MutationType or "Normal"
					end
				end
			end

			-- Kirim remote klaim
			pcall(function() PetMutationMachineService_RE:FireServer("ClaimMutatedPet") end)
			task.wait(1.0)

			-- 2. Tentukan pet hasil klaim.
			-- Sumber UTAMA = machine.SubmittedPet (pet yg barusan diproses) -> reliable, ga
			-- jadi "Unknown" walau data inventory telat sync. Diff inventory dipakai buat
			-- refine (mis. dapat mutasi hasil terbaru) kalau ketemu.
			local sp = machine.SubmittedPet or {}
			local claimedPetType = sp.PetType or "Unknown"
			local outcomeMutation = (sp.PetData and sp.PetData.MutationType) or "Normal"

			local ok3, d3 = pcall(function() return DataService:GetData() end)
			if ok3 and d3 and d3.PetsData then
				local newInv = d3.PetsData.PetInventory and d3.PetsData.PetInventory.Data or {}
				for u, v in pairs(newInv) do
					if targetTypes[v.PetType] then
						local pd = v.PetData or {}
						local mut = pd.MutationType or "Normal"
						if not preSnapshot[u] or preSnapshot[u] ~= mut then
							claimedPetType = v.PetType
							outcomeMutation = mut
							break
						end
					end
				end
			end
			local isMatched = hasTargetMutation({ MutationType = outcomeMutation }, targetMutations)

			-- Durasi proses: dari submit sampai klaim
			local duration = 0
			if ctx.state.mutationSubmitTime then
				duration = os.time() - ctx.state.mutationSubmitTime
				ctx.state.mutationSubmitTime = nil
			end

			-- Kirim Webhook Claimed
			task.spawn(function()
				local WebhookMut = ctx.webhookMutation
				if WebhookMut then
					pcall(function() WebhookMut.sendClaimed(ctx, claimedPetType, outcomeMutation, isMatched, duration) end)
				end
			end)

			if isMatched then
				-- Pet ini dapat mutasi target. JANGAN matikan automation — lanjut proses
				-- pet ready berikutnya (section D sudah auto-skip pet yg sudah hasTargetMutation,
				-- jadi pet ini ga bakal diproses ulang).
				ctx.state.mutationPhase = "Matched! Lanjut next target..."
			else
				ctx.state.mutationPhase = "Non-target, lanjut..."
			end
			return
		end

		-- B. DETEKSI APAKAH MESIN SEDANG BERJALAN
		if machine.IsRunning or (machine.TimeLeft and machine.TimeLeft > 0) then
			-- Validasi Boost team LENGKAP dulu (no miss) baru dianggap boosting.
			if ensureEquippedTeam(boostTeam) then
				ctx.state.mutationPhase = "Boosting Machine"
			else
				ctx.state.mutationPhase = "Menunggu Boost Team lengkap..."
			end
			return
		end

		-- C. DETEKSI PET SUDAH DI-SUBMIT TETAPI BELUM DI-START
		if machine.SubmittedPet and not machine.IsRunning then
			ctx.state.mutationPhase = "Starting Machine"
			pcall(function() PetMutationMachineService_RE:FireServer("StartMachine") end)
			task.wait(0.5)
			return
		end

		-- D. DETEKSI MESIN KOSONG: Cari pet dari inventory untuk dimasukkan ke mesin
		if not machine.SubmittedPet then
			-- Cari pet target yang siap (level >= targetAge)
			local candidateUuid, candidateType
			for uuid, v in pairs(inv) do
				local pt = v.PetType
				local pd = v.PetData or {}
				local lvl = pd.Level or 0
				local mut = pd.MutationType or "Normal"
				local isFav = pd.IsFavorite or false

				-- Hanya pet tipe target, dengan level >= targetAge, bukan favorite, dan belum memiliki mutasi target
				if targetTypes[pt] and lvl >= targetAge and not isFav and not hasTargetMutation(pd, targetMutations) then
					candidateUuid = uuid
					candidateType = pt
					break
				end
			end

			-- Jika ada pet yang siap, submit ke mesin!
			if candidateUuid then
				ctx.state.mutationPhase = "Submitting Target"
				
				-- 1. Pastikan dicopot dari garden dulu sebelum di-submit
				pcall(function() PetsService:FireServer("UnequipPet", candidateUuid) end)
				task.wait(0.25)

				-- 2. Cari tool pet tersebut di Backpack atau Character
				local targetTool
				for _, item in ipairs(LP.Backpack:GetChildren()) do
					if item:IsA("Tool") and cleanUuid(item:GetAttribute("PET_UUID")) == cleanUuid(candidateUuid) then
						targetTool = item
						break
					end
				end
				if not targetTool and LP.Character then
					for _, item in ipairs(LP.Character:GetChildren()) do
						if item:IsA("Tool") and cleanUuid(item:GetAttribute("PET_UUID")) == cleanUuid(candidateUuid) then
							targetTool = item
							break
						end
					end
				end

				-- 3. Equip pet ke tangan lalu VERIFIKASI beneran dipegang sebelum submit.
				--    Cegah submit KOSONG kalau equip gagal/ke-race (mesin nerima submit hampa
				--    -> langsung "ready" tanpa isi). Kalau gagal pegang, JANGAN submit.
				if targetTool then
					local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
					local held
					for _ = 1, 4 do
						pcall(function()
							if hum then hum:EquipTool(targetTool) else targetTool.Parent = LP.Character end
						end)
						task.wait(0.35)
						local h = LP.Character and LP.Character:FindFirstChildWhichIsA("Tool")
						if h and cleanUuid(h:GetAttribute("PET_UUID")) == cleanUuid(candidateUuid) then
							held = h
							break
						end
					end

					if held then
						pcall(function() PetMutationMachineService_RE:FireServer("SubmitHeldPet") end)
						-- Duration: dari mulai EXP leveling kalau pet ini sempat di-level, else dari submit
						ctx.state.mutationStartTime = ctx.state.mutationStartTime or {}
						ctx.state.mutationSubmitTime = ctx.state.mutationStartTime[candidateUuid] or os.time()
						ctx.state.mutationStartTime[candidateUuid] = nil
						task.wait(0.5)

						-- Kirim Webhook Submitted
						task.spawn(function()
							local WebhookMut = ctx.webhookMutation
							if WebhookMut then
								local petLevel = inv[candidateUuid] and inv[candidateUuid].PetData and inv[candidateUuid].PetData.Level or 50
								pcall(function() WebhookMut.sendSubmitted(ctx, candidateType, petLevel) end)
							end
						end)

						-- Jalankan mesin langsung di detik yang sama
						pcall(function() PetMutationMachineService_RE:FireServer("StartMachine") end)
						task.wait(0.3)
					else
						ctx.state.mutationPhase = "Gagal pegang pet, retry..."
					end
				end
				return
			end

			-- Jika tidak ada pet yang siap, cari pet target yang levelnya kurang untuk kita LEVELING!
			local levelUuid, levelType, levelLvl
			for uuid, v in pairs(inv) do
				local pt = v.PetType
				local pd = v.PetData or {}
				local lvl = pd.Level or 0
				local mut = pd.MutationType or "Normal"
				local isFav = pd.IsFavorite or false

				if targetTypes[pt] and lvl < targetAge and not isFav and not hasTargetMutation(pd, targetMutations) then
					-- Prioritaskan level yang paling tinggi tapi masih di bawah targetAge agar cepat jadi!
					if not levelLvl or lvl > levelLvl then
						levelUuid = uuid
						levelType = pt
						levelLvl = lvl
					end
				end
			end

			-- Jika ada pet yang perlu di-leveling:
			if levelUuid then
				-- Validasi EXP team + target pet LENGKAP dulu (no miss).
				if ensureEquippedTeam(expTeam, levelUuid) then
					ctx.state.mutationPhase = "Leveling Target"
					-- Catat mulai proses EXP leveling pet ini (buat Duration total)
					ctx.state.mutationStartTime = ctx.state.mutationStartTime or {}
					if not ctx.state.mutationStartTime[levelUuid] then
						ctx.state.mutationStartTime[levelUuid] = os.time()
					end
				else
					ctx.state.mutationPhase = "Menunggu EXP Team lengkap..."
				end
				return
			end

			-- Jika sama sekali tidak ada pet kandidat
			ctx.state.mutationPhase = "Idle (No Targets)"
		end
	end

	local function mutationLoop()
		ctx.state.mutationId = (ctx.state.mutationId or 0) + 1
		local myId = ctx.state.mutationId
		ctx.elevate()

		-- Kirim Webhook Enabled
		task.spawn(function()
			local WebhookMut = ctx.webhookMutation
			if WebhookMut then
				local expTeamList = {}
				local boostTeamList = {}
				local phoenixTeamList = {}

				local okData, d = pcall(function() return DataService:GetData() end)
				if okData and d and d.PetsData then
					local inv = d.PetsData.PetInventory and d.PetsData.PetInventory.Data or {}

					-- 1. EXP Team
					for uuid, _ in pairs(CFG.mutationExpTeam or {}) do
						local pInfo = inv[uuid]
						if pInfo then table.insert(expTeamList, pInfo.PetType) end
					end

					-- 2. Boost Team
					for uuid, _ in pairs(CFG.mutationBoostTeam or {}) do
						local pInfo = inv[uuid]
						if pInfo then table.insert(boostTeamList, pInfo.PetType) end
					end

					-- 3. Phoenix Team
					for uuid, _ in pairs(CFG.mutationPhoenixTeam or {}) do
						local pInfo = inv[uuid]
						if pInfo then table.insert(phoenixTeamList, pInfo.PetType) end
					end
				end

				pcall(function() 
					WebhookMut.sendEnabled(ctx, CFG.mutationTargetTypes, CFG.mutationTargetMutations, CFG.mutationTargetAge, expTeamList, boostTeamList, phoenixTeamList)
				end)
			end
		end)

		while CFG.mutationEnabled and ctx.alive() and ctx.state.mutationId == myId do
			pcall(checkMutation)
			task.wait(3.0)
		end
		ctx.state.mutationStatus = "Idle"
		ctx.state.mutationPhase = "Idle"
	end

	function ctx.startMutation()
		if ctx.cancelClearGarden then ctx.cancelClearGarden() end
		task.spawn(mutationLoop)
	end

	function ctx.stopMutation()
		ctx.state.mutationId = (ctx.state.mutationId or 0) + 1 -- matikan loop
		if ctx.clearGarden then ctx.clearGarden("Mutation") end
	end
end
]=],
	["modules/mutation/automation_mutation.lua"] = [=[
--[[ cleanse.lua — Automation Cleanse Mutation (mutasi via aura + auto cleanse).
     - Pet Team for Mutation (aura pemberi mutasi) tetap di garden.
     - Pet target (Pet Types) dirotasi di garden (max = Max Pets in Garden) buat kena aura.
     - Target dapat mutasi di "Keep" -> disimpan (dikeluarkan dari garden).
     - Target dapat mutasi LAIN -> di-cleanse (Cleansing Pet Shard) biar coba lagi.
     Cleanse: pegang shard lalu PetShardService_RE:FireServer("ApplyShard", petModel). ]]
return function(ctx)
	local DataService = ctx.deps.DataService
	local PetsService = ctx.deps.PetsService
	local CFG = ctx.CFG
	local LP = ctx.LP
	local RS = game:GetService("ReplicatedStorage")
	local PetShardService = RS:WaitForChild("GameEvents"):WaitForChild("PetShardService_RE")
	local function setStatus(s) ctx.setStatus(s) end

	local function mutName(code)
		if ctx.reg and ctx.reg.mutDisplay then return ctx.reg.mutDisplay(code) end
		return tostring(code)
	end
	local function cleanUuid(u) return (tostring(u):gsub("[{}]", "")) end

	----------------------------------------------------------------- placement
	local function farmCenter()
		local GetFarm = require(RS.Modules.GetFarm)
		local farm = GetFarm and GetFarm(LP)
		local pa = farm and farm:FindFirstChild("PetArea")
		if pa then return pa.Position end
		local char = LP.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		return hrp and hrp.Position or nil
	end
	local slotOf, nextSlot = {}, 0
	local GRID_COLS, GRID_SP = 6, 3
	local function getPos(uuid)
		if not slotOf[uuid] then slotOf[uuid] = nextSlot; nextSlot = nextSlot + 1 end
		local center = farmCenter(); if not center then return nil end
		local i = slotOf[uuid]
		local col, row = i % GRID_COLS, math.floor(i / GRID_COLS)
		return center + Vector3.new((col - (GRID_COLS - 1) / 2) * GRID_SP, 0, (row - 1) * GRID_SP)
	end

	----------------------------------------------------------------- shard cleanse
	local function findShard()
		for _, src in ipairs({ LP.Character, LP:FindFirstChildOfClass("Backpack") }) do
			if src then for _, t in ipairs(src:GetChildren()) do
				if t:IsA("Tool") and (t:HasTag("PetShardTool") or tostring(t.Name):find("Cleansing Pet Shard")) then return t end
			end end
		end
		return nil
	end
	local function findPetModel(uuid)
		local pp = workspace:FindFirstChild("PetsPhysical")
		if not pp then return nil end
		for _, d in ipairs(pp:GetDescendants()) do
			if d.Name == uuid then return d end
		end
		return nil
	end
	-- Cleanse pet yang SUDAH equipped (model ada di garden).
	local function cleansePet(uuid)
		local model = findPetModel(uuid)
		if not model then return false, "model tidak ada" end
		local shard = findShard()
		if not shard then return false, "shard habis" end
		local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
		if not hum then return false, "no humanoid" end
		local held
		for _ = 1, 3 do
			pcall(function() hum:EquipTool(shard) end); task.wait(0.3)
			held = LP.Character and LP.Character:FindFirstChildWhichIsA("Tool")
			if held and (held:HasTag("PetShardTool") or tostring(held.Name):find("Cleansing Pet Shard")) then break end
			shard = findShard(); if not shard then break end
		end
		if held and (held:HasTag("PetShardTool") or tostring(held.Name):find("Cleansing Pet Shard")) then
			pcall(function() PetShardService:FireServer("ApplyShard", model) end)
			task.wait(0.4)
			return true
		end
		return false, "gagal pegang shard"
	end

	----------------------------------------------------------------- mutasi helpers
	local function hasMut(pd)
		local m = pd.MutationType
		if not m or m == "" or m == "Normal" or m == "m" then return false end
		return mutName(m) ~= "None"
	end
	local function isKept(pd)
		return hasMut(pd) and CFG.cleanseKeepMutations[mutName(pd.MutationType)] == true
	end

	ctx.state.cleansePhase = "Idle"

	-- Ringkasan status untuk UI
	function ctx.getCleanseSummary()
		local ok, d = pcall(function() return DataService:GetData() end)
		local inv = ok and d and d.PetsData and d.PetsData.PetInventory and d.PetsData.PetInventory.Data or {}

		local teamCount = 0
		for _ in pairs(CFG.cleanseTeamUuids or {}) do teamCount = teamCount + 1 end
		local typesList = {}
		for k in pairs(CFG.cleansePetTypes or {}) do typesList[#typesList + 1] = k end
		table.sort(typesList)
		local keepOrder = {}
		for k in pairs(CFG.cleanseKeepMutations or {}) do keepOrder[#keepOrder + 1] = k end
		table.sort(keepOrder)

		local ready, already = 0, {}
		for _, k in ipairs(keepOrder) do already[k] = 0 end
		for _, v in pairs(inv) do
			local pt = v.PetType
			if pt and CFG.cleansePetTypes[pt] then
				local pd = v.PetData or {}
				local disp = hasMut(pd) and mutName(pd.MutationType) or "None"
				if CFG.cleanseKeepMutations[disp] then
					already[disp] = (already[disp] or 0) + 1
				elseif not pd.IsFavorite then
					ready = ready + 1
				end
			end
		end

		return {
			status = CFG.cleanseEnabled and "ACTIVE" or "STOPPED",
			team = teamCount,
			types = #typesList > 0 and table.concat(typesList, ", ") or "None",
			keep = #keepOrder > 0 and table.concat(keepOrder, ", ") or "None",
			ready = ready,
			already = already,
			keepOrder = keepOrder,
			maxPets = CFG.cleanseMaxPets or 2,
			phase = ctx.state.cleansePhase or "Idle",
		}
	end

	----------------------------------------------------------------- loop utama
	local function checkCleanse()
		local ok, d = pcall(function() return DataService:GetData() end)
		if not ok or not d or not d.PetsData then return end
		local eq = d.PetsData.EquippedPets or {}
		local inv = d.PetsData.PetInventory and d.PetsData.PetInventory.Data or {}

		local teamSet = CFG.cleanseTeamUuids or {}
		local targetTypes = CFG.cleansePetTypes or {}
		local maxPets = CFG.cleanseMaxPets or 2

		local localEq = {}
		for _, u in ipairs(eq) do localEq[cleanUuid(u)] = u end -- clean->original

		-- A. FIRST RUN: reset garden
		if ctx.state.cleanseFirstRun then
			ctx.state.cleanseFirstRun = false
			for _, uuid in ipairs(eq) do
				pcall(function() PetsService:FireServer("UnequipPet", uuid) end)
				localEq[cleanUuid(uuid)] = nil
				task.wait(0.1)
			end
		end

		-- B. Pasang team aura (persisten)
		for uuid in pairs(teamSet) do
			if not localEq[cleanUuid(uuid)] then
				local pos = getPos(uuid)
				if pos then
					pcall(function() PetsService:FireServer("EquipPet", uuid, CFrame.new(pos)) end)
					localEq[cleanUuid(uuid)] = uuid
					task.wait(0.1)
				end
			end
		end

		-- C. Proses pet target yang equipped
		local activeTargets = 0
		for cu, origUuid in pairs(localEq) do
			if not teamSet[origUuid] and not teamSet["{" .. cu .. "}"] then
				local pInfo = inv[origUuid] or inv["{" .. cu .. "}"]
				local pt = pInfo and pInfo.PetType
				local pd = pInfo and pInfo.PetData or {}
				if pt and targetTypes[pt] then
					if pd.IsFavorite then
						-- Favorite -> JANGAN cleanse (lindungi mutasi). Keluarkan dari garden.
						ctx.state.cleansePhase = "Skip favorite (protected)"
						pcall(function() PetsService:FireServer("UnequipPet", origUuid) end)
						localEq[cu] = nil
						task.wait(0.1)
					elseif isKept(pd) then
						-- Harvest: mutasi bagus -> keluarkan dari garden (disimpan)
						ctx.state.cleansePhase = "Harvest " .. mutName(pd.MutationType)
						pcall(function() PetsService:FireServer("UnequipPet", origUuid) end)
						localEq[cu] = nil
						task.wait(0.15)

						-- Webhook: mutasi didapat
						if ctx.webhookCleanse then
							local gotType, gotMut, gotAge = pt, mutName(pd.MutationType), pd.Level or 0
							local remains = 0
							for _, iv in pairs(inv) do
								local ipt = iv.PetType
								if ipt and targetTypes[ipt] then
									local ipd = iv.PetData or {}
									if not ipd.IsFavorite and not isKept(ipd) then remains = remains + 1 end
								end
							end
							task.spawn(function()
								pcall(function() ctx.webhookCleanse.sendObtained(ctx, gotType, gotMut, gotAge, remains) end)
							end)
						end
					elseif hasMut(pd) then
						-- Mutasi salah -> cleanse (tetap di garden buat coba lagi)
						ctx.state.cleansePhase = "Cleanse " .. mutName(pd.MutationType)
						cleansePet(origUuid)
						activeTargets = activeTargets + 1
					else
						-- Normal -> lagi nunggu aura
						activeTargets = activeTargets + 1
					end
				elseif not (pt and targetTypes[pt]) then
					-- pet lain (bukan team, bukan target) -> keluarkan
					pcall(function() PetsService:FireServer("UnequipPet", origUuid) end)
					localEq[cu] = nil
					task.wait(0.1)
				end
			end
		end

		-- D. Isi garden dengan target baru sampai maxPets (belum punya mutasi keep)
		local needed = maxPets - activeTargets
		if needed > 0 then
			local pool = {}
			for uuid, v in pairs(inv) do
				local pt = v.PetType
				local pd = v.PetData or {}
				if not localEq[cleanUuid(uuid)] and pt and targetTypes[pt] and not pd.IsFavorite and not isKept(pd) then
					pool[#pool + 1] = uuid
				end
			end
			for i = 1, math.min(needed, #pool) do
				local pos = getPos(pool[i])
				if pos then
					pcall(function() PetsService:FireServer("EquipPet", pool[i], CFrame.new(pos)) end)
					localEq[cleanUuid(pool[i])] = pool[i]
					activeTargets = activeTargets + 1
					task.wait(0.15)
				end
			end
		end

		ctx.state.cleansePhase = string.format("Farming: %d/%d target", activeTargets, maxPets)
	end

	local function cleanseLoop()
		ctx.state.cleanseId = (ctx.state.cleanseId or 0) + 1
		local myId = ctx.state.cleanseId
		ctx.elevate()
		ctx.state.cleanseFirstRun = true

		while CFG.cleanseEnabled and ctx.alive() and ctx.state.cleanseId == myId do
			if not next(CFG.cleansePetTypes or {}) then
				setStatus("Cleanse: pilih Pet Types dulu")
				task.wait(3)
			else
				pcall(checkCleanse)
				setStatus("Cleanse " .. tostring(ctx.state.cleansePhase))
				task.wait(3)
			end
		end
		ctx.state.cleansePhase = "Idle"
	end

	function ctx.startCleanse()
		if ctx.cancelClearGarden then ctx.cancelClearGarden() end -- batalkan clear tertunda
		task.spawn(cleanseLoop) -- loop set firstRun=true -> reset garden + equip team aura
	end

	function ctx.stopCleanse()
		ctx.state.cleanseId = (ctx.state.cleanseId or 0) + 1 -- matikan loop
		if ctx.clearGarden then ctx.clearGarden("Auto Mutation") end
	end
end
]=],
	["modules/mutation/cleanse_webhook.lua"] = [=[
--[[ webhook/cleanse.lua — webhook Automation Mutation (aura + cleanse).
     Dikirim saat pet target dapat mutasi "keep" (harvest). ]]
local cleanseWebhook = {}

function cleanseWebhook.sendObtained(ctx, petType, mutation, age, remainsQueue)
	local CFG = ctx.CFG
	if not CFG.webhookUrl or CFG.webhookUrl == "" then return end

	local payload = {
		embeds = {
			{
				title = "\240\159\140\177 Growth \226\128\162 Mutation",
				color = 3066993,
				fields = {
					{
						name = "Profile :",
						value = string.format("> Username : ||%s||", ctx.LP.Name),
						inline = false,
					},
					{
						name = "Mutation Obtained",
						value = string.format(
							"> Pet Type: `%s`\n" ..
							"> Mutation: `%s`\n" ..
							"> Age: `%s`\n" ..
							"> Remains Queue: `%s`",
							tostring(petType or "?"),
							tostring(mutation or "?"),
							tostring(age or 0),
							tostring(remainsQueue or 0)
						),
						inline = false,
					},
				},
				footer = {
					text = os.date("%B %d | %I:%M %p"),
					icon_url = "https://raw.githubusercontent.com/milmscr/iniapa/main/cobainaja/Logo/logo_icon.png",
				},
			},
		},
	}
	if ctx.sendWebhook then ctx.sendWebhook(CFG.webhookUrl, payload, ctx) end
end

return cleanseWebhook
]=],
	["modules/mutation/webhook.lua"] = [=[
--[[ webhook/mutation.lua — Discord webhook untuk mutation.
     Di-load via HttpGet loader; sender diambil dari ctx.sendWebhook (bukan require script). ]]
local HttpService = game:GetService("HttpService")

local mutationWebhook = {}

-- Webhook saat mutasi di-enable
function mutationWebhook.sendEnabled(ctx, targetTypes, targetMuts, targetAge, expTeamList, boostTeamList, phoenixTeamList)
	local CFG = ctx.CFG
	if not CFG.webhookUrl or CFG.webhookUrl == "" then return end

	local typesList = {}
	for k in pairs(targetTypes) do table.insert(typesList, "`" .. k .. "`") end
	local typesText = #typesList > 0 and table.concat(typesList, ", ") or "None"

	local mutsList = {}
	for k in pairs(targetMuts) do table.insert(mutsList, "`" .. k .. "`") end
	local mutsText = #mutsList > 0 and table.concat(mutsList, ", ") or "None"

	local expText = #expTeamList > 0 and table.concat(expTeamList, ", ") or "None"
	local boostText = #boostTeamList > 0 and table.concat(boostTeamList, ", ") or "None"
	local phText = #phoenixTeamList > 0 and table.concat(phoenixTeamList, ", ") or "None"

	local payload = {
		embeds = {
			{
				title = "Mutation • Machine Enabled",
				color = 10181046, -- Purple (hex 0x9b59b6 -> 10181046)
				fields = {
					{
						name = "Profile :",
						value = string.format("> Username : ||%s||", ctx.LP.Name),
						inline = false
					},
					{
						name = "Mutation Configuration",
						value = string.format(
							"> Target Types: %s\n" ..
							"> Keep Mutations: %s\n" ..
							"> Target Age: `%s`",
							typesText,
							mutsText,
							tostring(targetAge)
						),
						inline = false
					},
					{
						name = "Mutation Support Teams",
						value = string.format(
							"> EXP Team: %s\n" ..
							"> Boost Team: %s\n" ..
							"> Phoenix Team: %s",
							expText,
							boostText,
							phText
						),
						inline = false
					}
				},
				footer = {
					text = os.date("%B %d | %I:%M %p"),
					icon_url = "https://raw.githubusercontent.com/milmscr/iniapa/main/cobainaja/Logo/logo_icon.png"
				}
			}
		}
	}
	if ctx.sendWebhook then ctx.sendWebhook(CFG.webhookUrl, payload, ctx) end
end

-- Webhook saat pet disubmit ke mesin
function mutationWebhook.sendSubmitted(ctx, petType, level)
	local CFG = ctx.CFG
	if not CFG.webhookUrl or CFG.webhookUrl == "" then return end

	local payload = {
		embeds = {
			{
				title = "Mutation • Pet Submitted",
				color = 10181046, -- Purple
				fields = {
					{
						name = "Profile :",
						value = string.format("> Username : ||%s||", ctx.LP.Name),
						inline = false
					},
					{
						name = "Machine Status",
						value = string.format(
							"> Submitted Pet: `%s`\n" ..
							"> Age: `%s` (Target: `%s`)",
							petType,
							tostring(level),
							tostring(CFG.mutationTargetAge)
						),
						inline = false
					}
				},
				footer = {
					text = os.date("%B %d | %I:%M %p"),
					icon_url = "https://raw.githubusercontent.com/milmscr/iniapa/main/cobainaja/Logo/logo_icon.png"
				}
			}
		}
	}
	if ctx.sendWebhook then ctx.sendWebhook(CFG.webhookUrl, payload, ctx) end
end

-- Format detik -> "Xm Ys" / "Ys"
local function fmtDuration(sec)
	sec = math.max(0, math.floor(tonumber(sec) or 0))
	if sec >= 60 then return string.format("%dm %ds", math.floor(sec / 60), sec % 60) end
	return string.format("%ds", sec)
end

-- Webhook saat pet diklaim (hasil mutasi)
function mutationWebhook.sendClaimed(ctx, petType, outcomeMutation, isMatched, duration)
	local CFG = ctx.CFG
	if not CFG.webhookUrl or CFG.webhookUrl == "" then return end

	local mutDisplay = ctx.reg.mutDisplay and ctx.reg.mutDisplay(outcomeMutation) or outcomeMutation
	local statusText = isMatched and "✅ Target Found" or "❌ Non-target"

	local payload = {
		embeds = {
			{
				title = "Mutation • Pet Claimed",
				color = isMatched and 3066993 or 10181046, -- Green or Purple
				fields = {
					{
						name = "Profile :",
						value = string.format("> Username : ||%s||", ctx.LP.Name),
						inline = false
					},
					{
						name = "Claim Outcome",
						value = string.format(
							"> Pet Type: `%s`\n" ..
							"> Outcome Mutation: `%s`\n" ..
							"> Duration: `%s`\n" ..
							"> Status: **%s**",
							petType,
							mutDisplay,
							fmtDuration(duration),
							statusText
						),
						inline = false
					}
				},
				footer = {
					text = os.date("%B %d | %I:%M %p"),
					icon_url = "https://raw.githubusercontent.com/milmscr/iniapa/main/cobainaja/Logo/logo_icon.png"
				}
			}
		}
	}
	if ctx.sendWebhook then ctx.sendWebhook(CFG.webhookUrl, payload, ctx) end
end

return mutationWebhook
]=],
	["modules/pet/automation_boost_pet.lua"] = [=[
--[[ boostpet.lua — Automation Boost Pet.
     Pilih pet + item boost (Pet Toy). Otomatis apply boost ke pet;
     re-apply pas boost habis (berdasar durasi item, atribut "p" = boostTime detik).
     Mekanik: pegang Tool bertag "PetBoost" lalu PetBoostService:FireServer("ApplyBoost", petUuid). ]]
return function(ctx)
	local DataService = ctx.deps.DataService
	local CFG = ctx.CFG
	local LP = ctx.LP
	local RS = game:GetService("ReplicatedStorage")
	local PetBoostService = RS:WaitForChild("GameEvents"):WaitForChild("PetBoostService")
	local function setStatus(s) ctx.setStatus(s) end

	-- "Medium Pet Toy x42[Passive Boost]" -> "Medium Pet Toy"
	local function baseName(n) return (tostring(n):gsub("%s*x%d+.*$", "")) end

	-- Daftar item boost (tag PetBoost) di backpack, dedupe per base name -> dropdown.
	function ctx.getBoostItemOptions(selectedSet)
		local out, seen = {}, {}
		local bp = LP:FindFirstChildOfClass("Backpack")
		if not bp then return out end
		for _, t in ipairs(bp:GetChildren()) do
			if t:IsA("Tool") and t:HasTag("PetBoost") then
				local bn = baseName(t.Name)
				if not seen[bn] then
					seen[bn] = true
					local dur = t:GetAttribute("p")
					out[#out + 1] = { value = bn, display = dur and (bn .. " (" .. tostring(dur) .. "s)") or bn }
				end
			end
		end
		table.sort(out, function(a, b)
			local sa = selectedSet and selectedSet[a.value] and 1 or 0
			local sb = selectedSet and selectedSet[b.value] and 1 or 0
			if sa ~= sb then return sa > sb end
			return a.display < b.display
		end)
		return out
	end

	local THRESHOLD = 5 -- detik; boost dianggap habis kalau sisa <= ini

	-- Key unik per varian boost: type + amount. Small & Medium Pet Toy sama-sama
	-- PASSIVE_BOOST tapi amount beda (0.1 vs 0.2) dan BISA di-stack, jadi harus dibedakan.
	local function boostKey(btype, amount)
		local n = tonumber(amount)
		return tostring(btype) .. "|" .. (n and tostring(n) or tostring(amount))
	end

	-- Baca boost yang MASIH aktif di pet (dari PetData.Boosts, sisa Time > THRESHOLD).
	-- Keyed by type+amount supaya varian beda amount tidak saling menutupi.
	local function petActiveTypes(uuid)
		local out = {}
		local ok, d = pcall(function() return DataService:GetData() end)
		local data = ok and d and d.PetsData and d.PetsData.PetInventory and d.PetsData.PetInventory.Data
		local pd = data and data[uuid]
		local boosts = pd and pd.PetData and pd.PetData.Boosts
		if type(boosts) == "table" then
			for _, b in ipairs(boosts) do
				if b.BoostType and (tonumber(b.Time) or 0) > THRESHOLD then
					out[boostKey(b.BoostType, b.BoostAmount)] = true
				end
			end
		end
		return out
	end

	-- Pet dianggap AKTIF di garden kalau uuid-nya ada di PetsData.EquippedPets (array uuid).
	-- Boost cuma berlaku ke pet yang lagi placed; kalau nggak placed, skip (percuma).
	local function isPetActive(uuid)
		local ok, d = pcall(function() return DataService:GetData() end)
		local eq = ok and d and d.PetsData and d.PetsData.EquippedPets
		return type(eq) == "table" and table.find(eq, uuid) ~= nil
	end

	-- Cari tool boost dipilih (Character dulu) yang varian (type+amount)-nya BELUM aktif di pet.
	local function findToolForMissing(activeTypes)
		local sel = CFG.boostItemNames or {}
		for _, src in ipairs({ LP.Character, LP:FindFirstChildOfClass("Backpack") }) do
			if src then
				for _, t in ipairs(src:GetChildren()) do
					if t:IsA("Tool") and t:HasTag("PetBoost") and sel[baseName(t.Name)] then
						local bt = t:GetAttribute("q")
						if bt and not activeTypes[boostKey(bt, t:GetAttribute("o"))] then return t end
					end
				end
			end
		end
		return nil
	end

	local function boostLoop()
		ctx.state.boostId = (ctx.state.boostId or 0) + 1
		local myId = ctx.state.boostId
		ctx.elevate()

		while CFG.boostEnabled and ctx.alive() and ctx.state.boostId == myId do
			local pets = CFG.boostPetUuids or {}
			if not next(pets) then
				setStatus("Boost: pilih pet dulu")
				task.wait(3)
			else
				for uuid in pairs(pets) do
					if not CFG.boostEnabled or ctx.state.boostId ~= myId then break end
					-- Skip pet yang nggak aktif/placed di garden (boost ga guna)
					if not isPetActive(uuid) then continue end
					-- Cek state asli: boost apa yang masih aktif di pet ini
					local active = petActiveTypes(uuid)
					local tool = findToolForMissing(active)
					if tool then
						local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
						if hum then
							-- pastikan item bener-bener dipegang sebelum ApplyBoost
							local held
							for _ = 1, 3 do
								pcall(function() hum:EquipTool(tool) end)
								task.wait(0.35)
								held = LP.Character and LP.Character:FindFirstChildWhichIsA("Tool")
								if held and held:HasTag("PetBoost") then break end
								tool = findToolForMissing(active)
								if not tool then break end
							end
							if held and held:HasTag("PetBoost") then
								pcall(function() PetBoostService:FireServer("ApplyBoost", uuid) end)
								setStatus(("Boost: %s -> #%s"):format(baseName(held.Name), uuid:sub(2, 5)))
								task.wait(0.6)
							end
						end
					end
				end
				task.wait(2)
			end
		end
	end

	function ctx.startBoostPet() task.spawn(boostLoop) end
end
]=],
	["modules/pet/automation_pickup_pet_v1.lua"] = [=[
--[[ automation_pickup_pet_v1.lua — PnP V1 (POLLING).
     Tiap pet target punya thread sendiri: query GetPetCooldown -> kalau ready pickup-place.
     Langsung & simpel, tapi kena JITTER latency server (round-trip tiap cek).
     Config SENDIRI: pnpUuids, pickupDelay, equipDelay, pnpScanInterval, pnpEnabled.
     Fungsi: ctx.startPnpV1 / ctx.stopPnpV1. Juga expose ctx.inventoryPetOptions (dipakai V1 & V2). ]]
return function(ctx)
	local DataService = ctx.deps.DataService
	local PetsService = ctx.deps.PetsService
	local CFG         = ctx.CFG
	local function setStatus(s) ctx.setStatus(s) end

	local RS = game:GetService("ReplicatedStorage")
	local LP = ctx.LP

	local cdMap = ctx.state.cdMap or {}
	ctx.state.cdMap = cdMap
	local READY_TH = 0

	local GetPetCooldown = RS:WaitForChild("GameEvents"):WaitForChild("GetPetCooldown")

	local function readMainCd(uuid)
		local ok, cd = pcall(function() return GetPetCooldown:InvokeServer(uuid) end)
		if not ok or type(cd) ~= "table" then return nil end
		local data, mainCd = {}, 0
		for _, e in ipairs(cd) do
			local t = tonumber(e.Time) or 0
			data[#data + 1] = { Passive = e.Passive, Time = t }
			if not tostring(e.Passive or ""):find("Mutation") then
				if t > mainCd then mainCd = t end
			end
		end
		cdMap[uuid] = { data = data }
		return mainCd
	end

	local function targetPets()
		local out = {}
		local ok, d = pcall(function() return DataService:GetData() end)
		if not ok or not d then return out end
		local eq  = d.PetsData and d.PetsData.EquippedPets
		local inv = d.PetsData and d.PetsData.PetInventory and d.PetsData.PetInventory.Data
		if not eq then return out end
		local sel = CFG.pnpUuids or {}
		for _, uuid in ipairs(eq) do
			-- Proteksi Auto Hatch: jangan sentuh pet yang merupakan anggota Hatch/Bronto/Sell team
			if CFG.hatchEnabled then
				if (CFG.hatchHatchTeam and CFG.hatchHatchTeam[uuid])
				   or (CFG.hatchBrontoTeam and CFG.hatchBrontoTeam[uuid])
				   or (CFG.hatchSellTeam and CFG.hatchSellTeam[uuid]) then
					continue
				end
				-- Jika Core Team ditentukan di config Hatch, hanya target pet Core Team
				if next(CFG.hatchCoreTeam or {}) and not CFG.hatchCoreTeam[uuid] then
					continue
				end
			end
			local pt = inv and inv[uuid] and inv[uuid].PetType
			if (not next(sel)) or sel[uuid] then
				out[#out + 1] = { uuid = uuid, petType = pt }
			end
		end
		return out
	end

	-- daftar pet dari INVENTORY buat dropdown Select Pets (SHARED: dipakai V1 & V2, serta semua Team).
	-- HANYA menampilkan pet yang difavoritkan (IsFavorite == true), agar tidak tercampur dengan pet target non-favorit.
	function ctx.inventoryPetOptions(selectedSet)
		local out = {}
		local ok, d = pcall(function() return DataService:GetData() end)
		if not ok or not d then return out end
		local inv = d.PetsData and d.PetsData.PetInventory and d.PetsData.PetInventory.Data
		if not inv then return out end
		local eq = d.PetsData.EquippedPets or {}
		local eqSet = {}; for _, u in ipairs(eq) do eqSet[u] = true end

		-- Cek apakah ada pet yang difavoritkan di inventory
		local anyFav = false
		for _, v in pairs(inv) do
			if v.PetData and v.PetData.IsFavorite then
				anyFav = true
				break
			end
		end

		for uuid, v in pairs(inv) do
			local pd = v.PetData or {}
			local isFav = (pd.IsFavorite == true)
			-- Filter favorit: jika ada pet favorit, hanya tampilkan yang favorit atau yang sedang terpilih di selectedSet.
			-- Jika belum ada pet favorit sama sekali di inventory, tampilkan semua sebagai fallback.
			if (not anyFav) or isFav or (selectedSet and selectedSet[uuid]) then
				local pt = v.PetType or "?"
				local age = pd.Level or 0
				local mut = pd.MutationType
				local mutName = mut
				if mut and ctx.reg and ctx.reg.mutDisplay then mutName = ctx.reg.mutDisplay(mut) end
				local mutPrefix = (mut and mut ~= "" and mut ~= "Normal") and (tostring(mutName) .. " ") or ""
				local weight = (pd.BaseWeight or 0) * (1 + 0.1 * age)
				local tag = eqSet[uuid] and " [aktif]" or ""
				local favTag = isFav and "⭐ " or ""
				out[#out + 1] = {
					value = uuid,
					display = ("%s%s%s • %.2f KG • Lvl %s • #%s%s"):format(favTag, mutPrefix, pt, weight, tostring(age), uuid:sub(2, 5), tag),
				}
			end
		end
		if selectedSet and next(inv) then
			local valid = {}
			for uuid in pairs(inv) do valid[uuid] = true end
			local changed = false
			for u in pairs(selectedSet) do
				if not valid[u] then selectedSet[u] = nil; changed = true end
			end
			if changed and ctx.persistState then ctx.persistState() end
		end
		table.sort(out, function(a, b)
			local selA = selectedSet and selectedSet[a.value] and 1 or 0
			local selB = selectedSet and selectedSet[b.value] and 1 or 0
			if selA ~= selB then return selA > selB end
			return a.display < b.display
		end)
		return out
	end

	local GetFarm = require(RS.Modules.GetFarm)
	local function placePos()
		local farm = GetFarm and GetFarm(LP)
		local pa = farm and farm:FindFirstChild("PetArea")
		if pa then return pa.Position end
		local char = LP.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		return hrp and hrp.Position or nil
	end

	----------------------------------------------------------------- loop (polling, paralel per-pet)
	local petThreads = {}
	local function runPetThread(uuid, myId)
		petThreads[uuid] = true
		while CFG.pnpEnabled and ctx.alive() and ctx.state.pnpV1Id == myId do
			-- Jika Auto Hatch sedang swap team atau di fase non-Core (Hatching / Selling), jeda PNP
			if ctx.state.teamSwapActive or ctx.state.pnpBlockedByHatch then
				task.wait(0.5)
				continue
			end

			local stillTarget = false
			for _, p in ipairs(targetPets()) do
				if p.uuid == uuid then stillTarget = true; break end
			end
			if not stillTarget then break end

			local mainCd = readMainCd(uuid)
			local pos = placePos()
			if pos and mainCd ~= nil and mainCd <= READY_TH then
				if (CFG.pickupDelay or 0) > 0 then task.wait(CFG.pickupDelay) end
				if not (CFG.pnpEnabled and ctx.state.pnpV1Id == myId) then break end
				if ctx.state.teamSwapActive or ctx.state.pnpBlockedByHatch then break end

				pcall(function() PetsService:FireServer("UnequipPet", uuid) end)
				if (CFG.equipDelay or 0) > 0 then task.wait(CFG.equipDelay) end
				if not (CFG.pnpEnabled and ctx.state.pnpV1Id == myId) then break end
				if ctx.state.teamSwapActive or ctx.state.pnpBlockedByHatch then break end

				pcall(function() PetsService:FireServer("EquipPet", uuid, CFrame.new(pos)) end)
			end
			task.wait(math.max(0.01, tonumber(CFG.pnpScanInterval) or 0.05))
		end
		petThreads[uuid] = nil
	end

	local function pnpLoop()
		ctx.state.pnpV1Id = (ctx.state.pnpV1Id or 0) + 1
		local myId = ctx.state.pnpV1Id
		ctx.elevate()
		while CFG.pnpEnabled and ctx.alive() and ctx.state.pnpV1Id == myId do
			if ctx.state.teamSwapActive or ctx.state.pnpBlockedByHatch then
				setStatus("PNP V1: dijeda (Hatch/Sell team aktif)")
				task.wait(1)
				continue
			end

			local pets = targetPets()
			if #pets == 0 then
				setStatus("PNP V1: tidak ada pet target (equip pet dulu)")
			else
				for _, p in ipairs(pets) do
					if not petThreads[p.uuid] then task.spawn(runPetThread, p.uuid, myId) end
				end
				setStatus(("PNP V1 (polling): %d pet"):format(#pets))
			end
			task.wait(1)
		end
	end

	function ctx.startPnpV1() task.spawn(pnpLoop) end
	function ctx.stopPnpV1() ctx.state.pnpV1Id = (ctx.state.pnpV1Id or 0) + 1 end -- bump id -> loop lama mati
end
]=],
	["modules/pet/automation_pickup_pet_v2.lua"] = [=[
--[[ automation_pickup_pet_v2.lua — PnP V2 (EVENT-DRIVEN).
     BUKAN polling. Dengerin RemoteEvent server `PetCooldownsUpdated` yang PUSH cooldown tiap
     berubah (nol round-trip -> nol jitter -> stabil). Actor act dari cd real-time di memori.
     Config SENDIRI: pnpV2Uuids, pnpV2PickupDelay, pnpV2EquipDelay, pnpV2ScanInterval, pnpV2Enabled.
     Fungsi: ctx.startPnpV2 / ctx.stopPnpV2. Dropdown pakai ctx.inventoryPetOptions (dari V1). ]]
return function(ctx)
	local DataService = ctx.deps.DataService
	local PetsService = ctx.deps.PetsService
	local CFG         = ctx.CFG
	local function setStatus(s) ctx.setStatus(s) end

	local RS = game:GetService("ReplicatedStorage")
	local LP = ctx.LP

	local cdMap = ctx.state.cdMap or {}
	ctx.state.cdMap = cdMap
	local READY_TH = 0

	local GameEvents = RS:WaitForChild("GameEvents")
	local GetPetCooldown = GameEvents:WaitForChild("GetPetCooldown")           -- seed awal
	local PetCooldownsUpdated = GameEvents:WaitForChild("PetCooldownsUpdated") -- push cd real-time

	local function computeMainCd(cd)
		if type(cd) ~= "table" then return nil end
		local data, mainCd = {}, 0
		for _, e in ipairs(cd) do
			local t = tonumber(e.Time) or 0
			data[#data + 1] = { Passive = e.Passive, Time = t }
			if not tostring(e.Passive or ""):find("Mutation") then
				if t > mainCd then mainCd = t end
			end
		end
		return mainCd, data
	end

	-- cdLive: cd real-time per pet, di-update oleh event PetCooldownsUpdated (server push).
	local cdLive = {}
	ctx.state.pnpV2CdLive = cdLive
	do
		local g = (getgenv and getgenv()) or _G
		if g.__pnpV2CdConn then pcall(function() g.__pnpV2CdConn:Disconnect() end) end
		g.__pnpV2CdConn = PetCooldownsUpdated.OnClientEvent:Connect(function(uuid, cdTable)
			if type(uuid) ~= "string" then return end
			local m, data = computeMainCd(cdTable)
			if m ~= nil then cdLive[uuid] = m; cdMap[uuid] = { data = data } end
		end)
	end
	local function seedCd(uuid)
		local ok, cd = pcall(function() return GetPetCooldown:InvokeServer(uuid) end)
		local m, data = computeMainCd(ok and cd or nil)
		if m ~= nil then cdLive[uuid] = m; cdMap[uuid] = { data = data } end
	end

	local function targetPets()
		local out = {}
		local ok, d = pcall(function() return DataService:GetData() end)
		if not ok or not d then return out end
		local eq  = d.PetsData and d.PetsData.EquippedPets
		local inv = d.PetsData and d.PetsData.PetInventory and d.PetsData.PetInventory.Data
		if not eq then return out end
		local sel = CFG.pnpV2Uuids or {}
		for _, uuid in ipairs(eq) do
			-- Proteksi Auto Hatch: jangan sentuh pet yang merupakan anggota Hatch/Bronto/Sell team
			if CFG.hatchEnabled then
				if (CFG.hatchHatchTeam and CFG.hatchHatchTeam[uuid])
				   or (CFG.hatchBrontoTeam and CFG.hatchBrontoTeam[uuid])
				   or (CFG.hatchSellTeam and CFG.hatchSellTeam[uuid]) then
					continue
				end
				-- Jika Core Team ditentukan di config Hatch, hanya target pet Core Team
				if next(CFG.hatchCoreTeam or {}) and not CFG.hatchCoreTeam[uuid] then
					continue
				end
			end
			local pt = inv and inv[uuid] and inv[uuid].PetType
			if (not next(sel)) or sel[uuid] then
				out[#out + 1] = { uuid = uuid, petType = pt }
			end
		end
		return out
	end

	local GetFarm = require(RS.Modules.GetFarm)
	local function placePos()
		local farm = GetFarm and GetFarm(LP)
		local pa = farm and farm:FindFirstChild("PetArea")
		if pa then return pa.Position end
		local char = LP.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		return hrp and hrp.Position or nil
	end

	----------------------------------------------------------------- loop (event-driven, paralel per-pet)
	local petThreads = {}
	local lastPlace = {}
	local function runPetThread(uuid, myId)
		petThreads[uuid] = true
		if cdLive[uuid] == nil then seedCd(uuid) end
		while CFG.pnpV2Enabled and ctx.alive() and ctx.state.pnpV2Id == myId do
			-- Jika Auto Hatch sedang swap team atau di fase non-Core (Hatching / Selling), jeda PNP
			if ctx.state.teamSwapActive or ctx.state.pnpBlockedByHatch then
				task.wait(0.5)
				continue
			end

			local stillTarget = false
			for _, p in ipairs(targetPets()) do
				if p.uuid == uuid then stillTarget = true; break end
			end
			if not stillTarget then break end

			local cd = cdLive[uuid]
			local pos = placePos()
			if pos and cd ~= nil and cd <= READY_TH and (os.clock() - (lastPlace[uuid] or 0)) > 0.25 then
				if (CFG.pnpV2PickupDelay or 0) > 0 then task.wait(CFG.pnpV2PickupDelay) end
				if not (CFG.pnpV2Enabled and ctx.state.pnpV2Id == myId) then break end
				if ctx.state.teamSwapActive or ctx.state.pnpBlockedByHatch then break end

				pcall(function() PetsService:FireServer("UnequipPet", uuid) end)
				task.wait(math.max(0.01, CFG.pnpV2EquipDelay or 0.03))
				if not (CFG.pnpV2Enabled and ctx.state.pnpV2Id == myId) then break end
				if ctx.state.teamSwapActive or ctx.state.pnpBlockedByHatch then break end

				pcall(function() PetsService:FireServer("EquipPet", uuid, CFrame.new(pos)) end)
				lastPlace[uuid] = os.clock()
			end
			task.wait(math.max(0.02, tonumber(CFG.pnpV2ScanInterval) or 0.05))
		end
		petThreads[uuid] = nil
	end

	local function pnpLoop()
		ctx.state.pnpV2Id = (ctx.state.pnpV2Id or 0) + 1
		local myId = ctx.state.pnpV2Id
		ctx.elevate()
		while CFG.pnpV2Enabled and ctx.alive() and ctx.state.pnpV2Id == myId do
			if ctx.state.teamSwapActive or ctx.state.pnpBlockedByHatch then
				setStatus("PNP V2: dijeda (Hatch/Sell team aktif)")
				task.wait(1)
				continue
			end

			local pets = targetPets()
			if #pets == 0 then
				setStatus("PNP V2: tidak ada pet target (equip pet dulu)")
			else
				for _, p in ipairs(pets) do
					if not petThreads[p.uuid] then task.spawn(runPetThread, p.uuid, myId) end
				end
				setStatus(("PNP V2 (event-driven): %d pet"):format(#pets))
			end
			task.wait(1)
		end
	end

	function ctx.startPnpV2() task.spawn(pnpLoop) end
	function ctx.stopPnpV2() ctx.state.pnpV2Id = (ctx.state.pnpV2Id or 0) + 1 end
end
]=],
	["modules/shop/automation_merchant.lua"] = [=[
--[[ automation_merchant.lua — Auto Buy Merchant (Traveling Merchant + Event/Night Shop).

     DUA jenis shop, disatuin di UI/loop yang sama:

     1) TRAVELING MERCHANT (kind "travel") — cuma 1 aktif per waktu.
          Katalog: TravelingMerchantData[MerchantType].ShopData
          Stok:    data.TravelingMerchantShopStock.Stocks[itemName].Stock
          Beli:    BuyTravelingMerchantShopStock:FireServer(itemName)               (sheckles)
          MerchantType di-canon-kan (dua "4th July" -> satu "American").

     2) EVENT / NIGHT SHOP (kind "event") — mis. Twilight Shop, Blood Moon Shop.
          Katalog: EventShopData[shopName]
          Stok:    data.EventShopStock[shopName].Stocks[itemName].Stock
          Beli:    BuyEventShopStock:FireServer(itemName, shopName)                 (sheckles)
          Ga perlu UI kebuka — remote diterima langsung selama shop lagi aktif.

     Item terpilih disimpan PER-ENTRI: CFG.merchantItems[id] = { [itemName]=true }.
     Toggle auto-buy (bisa nyala barengan, target di-UNION):
       merchantBuyEnabled -> beli item terpilih utk entri yang lagi ada stok
       merchantBuyAll     -> beli SEMUA item yang ada stock
       merchantBuyBest    -> beli 1 item TERMAHAL yang ada stock (per entri)
     Beli dipicu saat marker restock per-shop berubah, sama pola kayak Buy Seed. ]]
return function(ctx)
	local DataService = ctx.deps.DataService
	local CFG = ctx.CFG
	local RS = game:GetService("ReplicatedStorage")
	local GE = RS:WaitForChild("GameEvents")
	local BuyMerchant  = GE:WaitForChild("BuyTravelingMerchantShopStock")
	local BuyEventShop = GE:WaitForChild("BuyEventShopStock")
	local MerchantData = require(RS.Data.TravelingMerchant.TravelingMerchantData)
	local EventShopData = require(RS.Data.EventShopData)
	local EventShopUI = (function() local ok, m = pcall(function() return require(RS.Modules.EventShopUIController) end); return ok and m or nil end)()
	local UpdateService = (function() local ok, m = pcall(function() return require(RS.Modules.UpdateService) end); return ok and m or nil end)()
	local function setStatus(s) ctx.setStatus(s) end

	-- Event shop yang punya katalog di EventShopData (urutan tetap; UI-nya bisa dibuka).
	local KNOWN_EVENT = {
		"Twilight Shop", "Blood Moon Shop", "Summer Seed Shop", "Tide Token Shop",
		"Honey Coin Shop", "Honey Seed Shop", "Royal Jelly Shop", "Moon Coin Shop",
		"Easter Seed Shop", "Fall Market Seed Shop", "Fall Market Gear Shop",
		"Fall Market Pet Shop", "Fall Market Cosmetic Shop", "Goliath's Goods",
		"Goliath's Friends Deals",
	}

	-- Traveling merchant yang di-gabung jadi 1 entri UI (id canonical + judul rapih).
	local MERGE = {
		["American Traveling Merchant"]      = { id = "American", title = "American" },
		["American Traveling Merchant 2026"] = { id = "American", title = "American" },
	}
	local function canonId(mt) local m = MERGE[mt]; return m and m.id or mt end
	local function keysOf(id) -- id canonical -> daftar merchantType yang tercakup
		local ks = {}
		for key in pairs(MerchantData) do
			if canonId(key) == id then ks[#ks + 1] = key end
		end
		return ks
	end

	local function getData()
		local ok, d = pcall(function() return DataService:GetData() end)
		return ok and d or nil
	end

	-- Katalog + info traveling merchant yang AKTIF. return shopData, merchantType, merchantStock
	local function activeShop(d)
		d = d or getData()
		local ms = d and d.TravelingMerchantShopStock
		local mt = ms and ms.MerchantType
		if not mt or not MerchantData[mt] then return nil, nil, ms end
		return MerchantData[mt].ShopData, mt, ms
	end

	-- id ini traveling merchant? (kalau bukan -> dianggap event shop)
	local function isTravelId(id)
		for k in pairs(MerchantData) do if canonId(k) == id then return true end end
		return false
	end

	-- Semua event shop: KNOWN_EVENT dulu (urut), lalu shop lain yang ADA di EventShopStock
	-- (event lama/musiman yang katalognya ga di EventShopData -> tetap kebawa).
	local function allEventShops(d)
		local out, seen = {}, {}
		for _, s in ipairs(KNOWN_EVENT) do if not seen[s] then seen[s] = true; out[#out + 1] = s end end
		local ess = (d or getData()) and (d or getData()).EventShopStock
		local extra = {}
		if type(ess) == "table" then
			for shop, v in pairs(ess) do
				if shop ~= "" and type(v) == "table" and v.Stocks and not seen[shop] then
					seen[shop] = true; extra[#extra + 1] = shop
				end
			end
		end
		table.sort(extra)
		for _, s in ipairs(extra) do out[#out + 1] = s end
		return out
	end

	-- Katalog event shop: EventShopData kalau ada; else fallback dari stok live (tanpa harga).
	local function eventCatalog(shopName, d)
		local cat = EventShopData[shopName]
		if cat then return cat end
		local ess = (d or getData()) and (d or getData()).EventShopStock
		local s = ess and ess[shopName]
		local out = {}
		if s and type(s.Stocks) == "table" then
			for item in pairs(s.Stocks) do out[item] = { Price = 0, DisplayInShop = true } end
		end
		return out
	end

	-- Tampilkan SEMUA item yang di-display shop (TANPA filter harga). Item mahal (Price >= 1e9
	-- kayak Gnome, Pet Shard, Red Panda dll) itu harga Sheckle valid, dibeli via remote;
	-- PurchaseID/FallbackPrice cuma opsi Robux. Cuma skip DisplayInShop==false (disembunyiin game).
	local function isBuyable(v)
		return type(v) == "table" and v.DisplayInShop ~= false
	end

	-- Entri punya minimal 1 item yang bisa dibeli? (kalau ga ada, entri disembunyiin dari list)
	local function hasShecklesShop(shop)
		if type(shop) ~= "table" then return false end
		for _, v in pairs(shop) do
			if type(v) == "table" and v.DisplayInShop ~= false and isBuyable(v) then return true end
		end
		return false
	end
	local function entryHasSheckles(id, kind)
		if kind == "travel" then
			for _, key in ipairs(keysOf(id)) do
				if hasShecklesShop(MerchantData[key] and MerchantData[key].ShopData) then return true end
			end
			return false
		end
		return hasShecklesShop(eventCatalog(id))
	end

	----------------------------------------------------------------- opsi UI
	-- Daftar entri buat UI (traveling dulu diurut by title, lalu event shop).
	-- Cuma entri yang punya item beli-pakai-sheckles yang ditampilin.
	function ctx.getMerchantList()
		local out, seenId = {}, {}
		for key, m in pairs(MerchantData) do
			local id = canonId(key)
			if not seenId[id] and entryHasSheckles(id, "travel") then
				seenId[id] = true
				out[#out + 1] = { id = id, title = (MERGE[key] and MERGE[key].title) or m.Title or id, kind = "travel" }
			end
		end
		table.sort(out, function(a, b) return a.title < b.title end)
		for _, shopName in ipairs(allEventShops()) do
			if entryHasSheckles(shopName, "event") then
				out[#out + 1] = { id = shopName, title = shopName, kind = "event" }
			end
		end
		return out
	end

	-- Opsi item utk SATU entri (union katalog; item habis tetap tampil).
	function ctx.getMerchantItemOptions(id)
		local out = { { value = "All", display = "All (semua item)" } }
		local names, seen = {}, {}
		local function addFrom(shop)
			if not shop then return end
			for name, v in pairs(shop) do
				if v.DisplayInShop ~= false and isBuyable(v) and not seen[name] then
					seen[name] = true; names[#names + 1] = name
				end
			end
		end
		if isTravelId(id) then
			for _, key in ipairs(keysOf(id)) do addFrom(MerchantData[key] and MerchantData[key].ShopData) end
		else
			addFrom(eventCatalog(id))
		end
		table.sort(names)
		for _, n in ipairs(names) do out[#out + 1] = { value = n, display = n } end
		return out
	end

	-- Set selection utk entri (di-key pakai id).
	function ctx.merchantSelFor(id)
		CFG.merchantItems = CFG.merchantItems or {}
		CFG.merchantItems[id] = CFG.merchantItems[id] or {}
		return CFG.merchantItems[id]
	end

	-- Ada toggle auto-buy yang aktif? (master on/off buat loop)
	local function anyOn()
		return CFG.merchantBuyEnabled or CFG.merchantBuyAll or CFG.merchantBuyBest or false
	end
	ctx.merchantAnyOn = anyOn

	-- Ringkasan buat status live di UI: fokus ke ITEM yang dipilih buat dibeli per shop.
	-- res = { activeMerchant=<nama traveling aktif|nil>, mode="all"|"best"|nil,
	--         picks = { {title=, kind=, items={...}} ... } }  -- entri yang punya pilihan
	function ctx.getMerchantSummary()
		local d = getData()
		local _, mt = activeShop(d)
		local res = {
			activeMerchant = mt and (MerchantData[mt].Title or mt) or nil,
			mode = CFG.merchantBuyAll and "all" or (CFG.merchantBuyBest and "best") or nil,
			picks = {},
		}
		-- Kalau mode global (All/Best) nyala, item pilihan ga relevan.
		if res.mode then return res end
		-- Katalog gabungan buat 1 entri (buat ambil harga sheckles).
		local function catalogOf(id, kind)
			local cat = {}
			if kind == "travel" then
				for _, key in ipairs(keysOf(id)) do
					local sd = MerchantData[key] and MerchantData[key].ShopData
					if sd then for n, v in pairs(sd) do cat[n] = v end end
				end
			else
				cat = eventCatalog(id, d)
			end
			return cat
		end
		for _, m in ipairs(ctx.getMerchantList()) do
			local sel = (CFG.merchantItems and CFG.merchantItems[m.id]) or {}
			local cat = catalogOf(m.id, m.kind)
			local items = {}
			if sel["All"] then
				items = { { name = "All", price = nil } }
			else
				local names = {}
				for name, on in pairs(sel) do if on then names[#names + 1] = name end end
				table.sort(names)
				for _, name in ipairs(names) do
					local v = cat[name]
					items[#items + 1] = { name = name, price = v and v.Price or nil }
				end
			end
			if #items > 0 then
				res.picks[#res.picks + 1] = { title = m.title, kind = m.kind, items = items }
			end
		end
		return res
	end

	----------------------------------------------------------------- pilih target
	-- Toggle bisa nyala barengan; target-nya di-UNION (item ga dobel).
	-- stockOf(name) -> jumlah stock; selKey -> id buat CFG.merchantItems.
	local function pickTargets(catalog, stockOf, selKey)
		local targets, added = {}, {}
		local function add(name, s, price)
			if not added[name] then added[name] = true; targets[#targets + 1] = { name = name, stock = s, price = price } end
		end

		local buyAll   = CFG.merchantBuyAll
		local buySel   = CFG.merchantBuyEnabled
		local buyBest  = CFG.merchantBuyBest
		local sel = (CFG.merchantItems and CFG.merchantItems[selKey]) or {}
		local all = sel["All"]

		local bestName, bestPrice, bestStock = nil, -1, 0
		for name, v in pairs(catalog) do
			if v.DisplayInShop ~= false and isBuyable(v) then
				local s = stockOf(name)
				if s > 0 then
					local price = v.Price or 0
					if buyAll then
						add(name, s, price)
					else
						if buySel and (all or sel[name]) then add(name, s, price) end
					end
					if buyBest and price > bestPrice then bestName, bestPrice, bestStock = name, price, s end
				end
			end
		end
		if buyBest and bestName then add(bestName, bestStock, bestPrice) end
		return targets
	end

	----------------------------------------------------------------- loop beli
	local POLL = 2
	local function buyLoop()
		ctx.state.merchantId = (ctx.state.merchantId or 0) + 1
		local myId = ctx.state.merchantId
		ctx.elevate()
		local lastMarker = {} -- per-source: [srcKey] = markerVal

		-- Proses 1 source: beli target-nya kalau marker restock berubah. return jumlah beli.
		local function processSource(srcKey, marker, catalog, stockOf, selKey, buyFn)
			if lastMarker[srcKey] == marker then return nil end -- belum restock -> skip
			lastMarker[srcKey] = marker
			local targets = pickTargets(catalog, stockOf, selKey)
			local bought = 0
			for _, t in ipairs(targets) do
				for _ = 1, t.stock do
					if not anyOn() or ctx.state.merchantId ~= myId then break end
					pcall(buyFn, t.name)
					bought = bought + 1
					task.wait(0.15)
				end
			end
			return bought
		end

		while anyOn() and ctx.alive() and ctx.state.merchantId == myId do
			local d = getData()
			local acted = {}

			-- (1) Traveling merchant aktif
			local shop, mt, ms = activeShop(d)
			if mt then
				local marker = "travel|" .. tostring(mt) .. "|" .. tostring(ms.MerchantStartTime)
				local stocks = ms.Stocks or {}
				local bought = processSource("travel", marker, shop,
					function(n) return stocks[n] and stocks[n].Stock or 0 end,
					canonId(mt),
					function(n) BuyMerchant:FireServer(n) end)
				if bought then acted[#acted + 1] = ("%s:%d"):format(MerchantData[mt].Title or mt, bought) end
			else
				lastMarker["travel"] = nil -- reset biar pas merchant muncul langsung beli
			end

			-- (2) Event / night shop (Twilight, Blood Moon, event lama, ...)
			local ess = d and d.EventShopStock
			for _, shopName in ipairs(allEventShops(d)) do
				local s = ess and ess[shopName]
				local stocks = s and s.Stocks
				local catalog = eventCatalog(shopName, d)
				if stocks and catalog and next(catalog) then
					local marker = "event|" .. shopName .. "|" .. tostring(s.ShopSeed)
					local bought = processSource("event:" .. shopName, marker, catalog,
						function(n) return stocks[n] and stocks[n].Stock or 0 end,
						shopName,
						function(n) BuyEventShop:FireServer(n, shopName) end)
					if bought then acted[#acted + 1] = ("%s:%d"):format(shopName, bought) end
				else
					lastMarker["event:" .. shopName] = nil
				end
			end

			if #acted > 0 then
				setStatus("Merchant beli -> " .. table.concat(acted, ", "))
			else
				setStatus("Merchant: nunggu restock / merchant muncul")
			end
			task.wait(POLL)
		end
		setStatus("Merchant: idle")
	end

	function ctx.startBuyMerchant() task.spawn(buyLoop) end

	----------------------------------------------------------------- Open Shop UI
	-- Daftar shop buat dropdown "Merchant UI to Open" (event shop yang punya UI controller).
	function ctx.getEventShopOptions()
		local out = {}
		for _, s in ipairs(KNOWN_EVENT) do out[#out + 1] = { name = s, display = s } end
		return out
	end
	function ctx.getMerchantUiDisplay()
		return (CFG.merchantUiShop ~= nil and CFG.merchantUiShop ~= "") and CFG.merchantUiShop or "Select"
	end

	-- Nama ScreenGui event shop = shopName tanpa spasi + "EventShop_UI" (mis. "TwilightShopEventShop_UI").
	local function uiGuiName(shopName) return (shopName:gsub("%s+", "")) .. "EventShop_UI" end
	local function isUiOpen(shopName)
		local pg = ctx.LP and ctx.LP.PlayerGui
		local g = pg and pg:FindFirstChild(uiGuiName(shopName))
		return g and g.Enabled == true
	end
	local function shopActive(shopName)
		if not UpdateService then return true end
		local ok, r = pcall(function() return UpdateService:IsActive(shopName) end)
		return ok and r or false
	end

	-- Buka UI shop 1x (kalau shop aktif). return true kalau kebuka.
	function ctx.openEventShopUI(shopName)
		shopName = shopName or CFG.merchantUiShop
		if not shopName or shopName == "" or not EventShopUI then return false end
		if not shopActive(shopName) then
			setStatus(("Open UI: %s belum aktif"):format(shopName))
			return false
		end
		pcall(function() EventShopUI:Open(shopName) end)
		return true
	end

	-- Auto Open UI: jaga UI shop terpilih tetap kebuka (buka ulang kalau ke-close & shop aktif).
	local function autoOpenLoop()
		ctx.state.merchantUiId = (ctx.state.merchantUiId or 0) + 1
		local myId = ctx.state.merchantUiId
		while CFG.merchantAutoOpenUI and ctx.alive() and ctx.state.merchantUiId == myId do
			local shop = CFG.merchantUiShop
			if shop and shop ~= "" and EventShopUI then
				if shopActive(shop) then
					if not isUiOpen(shop) then pcall(function() EventShopUI:Open(shop) end) end
				end
			end
			task.wait(2)
		end
	end
	function ctx.startAutoOpenUI() task.spawn(autoOpenLoop) end
	function ctx.stopAutoOpenUI() ctx.state.merchantUiId = (ctx.state.merchantUiId or 0) + 1 end
end
]=],
	["modules/shop/automation_shop.lua"] = [=[
--[[ shop.lua — Automation Buy Seed / Egg / Gear.
     Opsi dropdown diambil dari REGISTRY katalog shop (bukan stock), jadi semua
     item tampil walau lagi habis; item baru dari update game auto masuk.
       Seed -> SeedShopData
       Gear -> GearShopData.Gear
       Egg  -> PetEggData
     Ada opsi "All" = beli semua yang lagi ada stock.
     Remote:
       BuySeedStock:FireServer("Shop", seedName)
       BuyGearStock:FireServer(gearName)
       BuyPetEgg:FireServer(eggIndex) ]]
return function(ctx)
	local DataService = ctx.deps.DataService
	local CFG = ctx.CFG
	local RS = game:GetService("ReplicatedStorage")
	local GE = RS:WaitForChild("GameEvents")
	local BuySeedStock = GE:WaitForChild("BuySeedStock")
	local BuyGearStock = GE:WaitForChild("BuyGearStock")
	local BuyPetEgg    = GE:WaitForChild("BuyPetEgg")
	local function setStatus(s) ctx.setStatus(s) end

	local function getData()
		local ok, d = pcall(function() return DataService:GetData() end)
		return ok and d or nil
	end

	-- Ambil daftar nama dari registry katalog; buang key non-item (RefreshTime, Gear).
	local function catalogNames(getTbl)
		local ok, t = pcall(getTbl)
		local out = {}
		if ok and type(t) == "table" then
			for k in pairs(t) do
				local n = tostring(k)
				if n ~= "RefreshTime" and n ~= "Gear" then out[#out + 1] = n end
			end
			table.sort(out)
		end
		return out
	end

	local function optionsFrom(names, sel)
		local out = { { value = "All", display = "All (beli semua)" } }
		for _, n in ipairs(names) do out[#out + 1] = { value = n, display = n } end
		return out
	end

	function ctx.getSeedShopOptions(sel)
		return optionsFrom(catalogNames(function() return require(RS.Data.SeedShopData) end), sel)
	end
	function ctx.getGearShopOptions(sel)
		return optionsFrom(catalogNames(function() return require(RS.Data.GearShopData).Gear end), sel)
	end
	function ctx.getEggShopOptions(sel)
		return optionsFrom(catalogNames(function() return require(RS.Data.PetEggData) end), sel)
	end

	----------------------------------------------------------------- loop beli
	-- Poll = cek marker restock (cuma BACA, bukan beli -> murah, ga lag).
	-- Beli tetap hanya saat marker berubah (restock). 2s biar deteksi cepat (minim miss).
	local POLL = 2

	local function buySeedLoop()
		ctx.state.buySeedId = (ctx.state.buySeedId or 0) + 1
		local myId = ctx.state.buySeedId
		ctx.elevate()
		local lastMarker
		while CFG.buySeedEnabled and ctx.alive() and ctx.state.buySeedId == myId do
			local d = getData()
			-- Game mindahin stok seed ke d.SeedStocks.Shop (d.SeedStock singular udah BEKU:
			-- markernya ga update lagi -> loop lama cuma beli sekali terus stuck "nunggu restock").
			-- Prefer path baru; fallback ke singular biar aman kalau server balikin lagi.
			local shop = d and ((d.SeedStocks and d.SeedStocks.Shop) or d.SeedStock)
			local marker = shop and shop.Seed
			if marker ~= lastMarker then -- restock baru (atau pertama jalan) -> beli
				lastMarker = marker
				local st = shop and shop.Stocks or {}
				local sel = CFG.buySeedNames or {}
				local all = sel["All"]
				local bought = 0
				for name, v in pairs(st) do
					if all or sel[name] then
						local stock = type(v) == "table" and v.Stock or 0
						for _ = 1, stock do
							if not CFG.buySeedEnabled or ctx.state.buySeedId ~= myId then break end
							pcall(function() BuySeedStock:FireServer("Shop", name) end)
							bought = bought + 1; task.wait(0.15)
						end
					end
				end
				setStatus(("Buy Seed: restock -> beli %d"):format(bought))
			else
				setStatus("Buy Seed: nunggu restock")
			end
			task.wait(POLL)
		end
	end

	local function buyGearLoop()
		ctx.state.buyGearId = (ctx.state.buyGearId or 0) + 1
		local myId = ctx.state.buyGearId
		ctx.elevate()
		local lastMarker
		while CFG.buyGearEnabled and ctx.alive() and ctx.state.buyGearId == myId do
			local d = getData()
			local marker = d and d.GearStock and d.GearStock.Gear
			if marker ~= lastMarker then
				lastMarker = marker
				local st = d and d.GearStock and d.GearStock.Stocks or {}
				local sel = CFG.buyGearNames or {}
				local all = sel["All"]
				local bought = 0
				for name, v in pairs(st) do
					if all or sel[name] then
						local stock = type(v) == "table" and v.Stock or 0
						for _ = 1, stock do
							if not CFG.buyGearEnabled or ctx.state.buyGearId ~= myId then break end
							pcall(function() BuyGearStock:FireServer(name) end)
							bought = bought + 1; task.wait(0.15)
						end
					end
				end
				setStatus(("Buy Gear: restock -> beli %d"):format(bought))
			else
				setStatus("Buy Gear: nunggu restock")
			end
			task.wait(POLL)
		end
	end

	local function buyEggLoop()
		ctx.state.buyEggId = (ctx.state.buyEggId or 0) + 1
		local myId = ctx.state.buyEggId
		ctx.elevate()
		local lastMarker
		while CFG.buyEggEnabled and ctx.alive() and ctx.state.buyEggId == myId do
			local d = getData()
			local marker = d and d.PetEggStock and d.PetEggStock.Egg
			if marker ~= lastMarker then
				lastMarker = marker
				local st = d and d.PetEggStock and d.PetEggStock.Stocks or {}
				local sel = CFG.buyEggNames or {}
				local all = sel["All"]
				local bought = 0
				for index, v in pairs(st) do
					local nm = type(v) == "table" and v.EggName
					local stock = type(v) == "table" and v.Stock or 0
					if nm and (all or sel[nm]) then
						for _ = 1, stock do
							if not CFG.buyEggEnabled or ctx.state.buyEggId ~= myId then break end
							pcall(function() BuyPetEgg:FireServer(index) end)
							bought = bought + 1; task.wait(0.15)
						end
					end
				end
				setStatus(("Buy Egg: restock -> beli %d"):format(bought))
			else
				setStatus("Buy Egg: nunggu restock")
			end
			task.wait(POLL)
		end
	end

	function ctx.startBuySeed() task.spawn(buySeedLoop) end
	function ctx.startBuyGear() task.spawn(buyGearLoop) end
	function ctx.startBuyEgg() task.spawn(buyEggLoop) end
end
]=],
	["modules/shop/premium_shop.lua"] = [=[
--[[ premium_shop.lua — Premium Shop beli via Robux atau Token.
     Sumber katalog: RS.Data.GiftData (sama seperti sc lain, ~394 item, live).
       tiap entry: { Display, NormalId (beli sendiri), GiftId (gift ke player) }.
     Beli:
       Token : GameEvents.TradeEvents.TradeTokens.Purchase:InvokeServer(id)
       Robux : MarketController:PromptPurchaseRobux(id, Enum.InfoType.Product)
     Gift  : pakai GiftId (game handle penerima). ]]
return function(ctx)
	local RS  = game:GetService("ReplicatedStorage")
	local MPS = game:GetService("MarketplaceService")
	local LP  = ctx.LP
	local CFG = ctx.CFG

	local MC; pcall(function() MC = require(RS.Modules.MarketController) end)
	local function giftData()
		local ok, d = pcall(function() return require(RS.Data.GiftData) end)
		return ok and d or {}
	end
	local function ttFolder()
		local ge = RS:FindFirstChild("GameEvents")
		local te = ge and ge:FindFirstChild("TradeEvents")
		return te and te:FindFirstChild("TradeTokens")
	end

	-- entry katalog berdasarkan key CFG.premiumItem.
	local function entryOf(key)
		local d = giftData()
		return key and d[key] or nil
	end

	------------------------------------------------------------- harga (Robux)
	-- Harga token dinamis (RAP), susah/ga stabil -> tampilkan harga Robux dari
	-- GetProductInfo. Di-cache; prefetch pelan di background (hindari rate limit).
	-- id -> number (harga) | false (id ga valid / ga dijual Robux) | nil (belum kebaca)
	-- PENTING: kegagalan karena throttle TIDAK di-cache (biar dicoba lagi), cuma
	-- id==0 / hasil valid-tanpa-harga yg di-cache false permanen.
	-- Cache disimpan di getgenv() biar SELAMAT dari reload script (dalam sesi/
	-- server yg sama) -> reload berikutnya 0 panggilan, harga langsung muncul.
	local priceCache = (getgenv and (getgenv().__AH_PREM_PRICE or (function() getgenv().__AH_PREM_PRICE = {}; return getgenv().__AH_PREM_PRICE end)())) or {}
	-- Tabel harga STATIS (id -> PriceInRobux), di-fetch sekali & ditempel di sini
	-- (kayak shop lain) -> instan selamanya, 0 panggilan walau reload/rejoin.
	-- Nilai 99999/999999999 = penanda off-sale dari game, sengaja tetap disimpan.
	-- Live-fetch tetap jalan buat id yg belum ada di sini (item/harga baru).
	local PRICE = {
		[3248690960]=19,[3248692171]=3,[3248692845]=55,[3248695199]=85,[3248695947]=21,[3248696942]=35,[3248697546]=80,[3248716238]=150,[3248744789]=175,[3249981764]=639,[3250137172]=49,[3250137261]=99,[3250137355]=325,[3250139018]=895,[3253012192]=240,[3259333414]=235,[3260229242]=39,
		[3260940714]=200,[3261009117]=99,[3265889601]=79,[3265889751]=99,[3265889948]=149,[3265927408]=6,[3265927978]=8,[3267528421]=999999999,[3267548052]=999999999,[3267548161]=999999999,[3267580365]=79,[3269001250]=459,[3273005969]=40900,[3273006109]=459,[3273679012]=999999999,[3273973729]=249,[3276346455]=19,[3276346509]=39,[3276346557]=89,[3276346676]=129,
		[3277000452]=149,[3277675404]=255,[3277814538]=575,[3277814625]=1699,[3278426597]=99999,[3281679093]=119,[3282157312]=999999999,[3282157462]=999999999,[3282870834]=205,[3282918403]=59,[3284390402]=715,[3286038236]=149,[3286560171]=119,[3290672626]=199,[3290672712]=575,[3290672848]=1699,[3295548770]=999999999,[3295548781]=1699,[3295548782]=999999999,[3300962946]=8000,
		[3300962950]=8000,[3300962952]=8000,[3300984139]=315,[3301473650]=39,[3301567955]=429,[3301567958]=149,[3301567960]=999999999,[3304968889]=329,[3306352279]=999999999,[3306352283]=999999999,[3306352284]=999999999,[3306767043]=139,[3311112163]=399,[3311388942]=999999999,[3311388948]=999999999,[3311388951]=999999999,[3312005774]=475,[3312007044]=135,[3312008833]=399,[3312011056]=419,
		[3312011732]=529,[3312012483]=589,[3312013208]=599,[3312013874]=679,[3312014286]=629,[3316261725]=99,[3316826714]=280,[3317459182]=99999,[3317459186]=99999,[3317459188]=999999999,[3317729900]=215,[3317730202]=715,[3323657547]=575,[3323657552]=999999999,[3323657553]=999999999,[3329526686]=189,[3329527365]=119,[3329528135]=35,[3330286148]=999999999,[3330286154]=99999,
		[3330286155]=99999,[3330562080]=929,[3338826790]=999999999,[3338826791]=999999999,[3338826792]=999999999,[3345148119]=385,[3345819463]=99999,[3345819470]=999999999,[3345819472]=999999999,[3352931398]=19,[3354130076]=115,[3354839803]=999999999,[3354839817]=999999999,[3354839826]=999999999,[3362680911]=999999999,[3362680916]=999999999,[3362680917]=999999999,[3371226353]=999999999,[3371226360]=999999999,[3371226363]=999999999,
		[3372004188]=395,[3379038152]=999999999,[3379038157]=999999999,[3379038159]=999999999,[3379245220]=139,[3379593726]=99999999,[3387753634]=999999999,[3387753638]=999999999,[3387753641]=199,[3388359799]=939,[3388360759]=897,[3388363071]=768,[3388363390]=839,[3394224231]=999999999,[3394224237]=999999999,[3394224239]=999999999,[3401426983]=149,[3401426984]=1249,[3401426985]=429,[3407391662]=199,
		[3407391663]=575,[3407391666]=1699,[3411693833]=749,[3414035789]=369,[3414586855]=149,[3420021043]=575,[3420021044]=1699,[3420021045]=199,[3426542757]=479,[3427163853]=9999999,[3427163854]=999999999,[3427163857]=999999,[3432380384]=399,[3438653517]=1699,[3438653518]=575,[3438653519]=199,[3444449485]=9999999,[3444449486]=9999999,[3444449487]=9999999,[3445155701]=6,
		[3445164189]=479,[3445262332]=530,[3449810469]=199,[3449810471]=1699,[3449810472]=575,[3455804869]=279,[3456989527]=150,[3460376533]=50,[3460378135]=250,[3460378800]=1000,[3460379424]=5000,[3460379831]=25000,[3460380041]=149,[3460380235]=149,[3460600736]=1699,
		[3460600737]=575,[3460600740]=199,[3461239818]=595,[3467103687]=1249,[3467103688]=429,[3467110142]=429,[3467110145]=1249,[3471911127]=1627,[3472461575]=625,[3472461579]=1899,[3472461584]=7450,[3472461585]=219,[3477922697]=429,[3477922698]=149,[3477922700]=1249,[3478031738]=149,[3478031853]=429,[3478031941]=1249,[3478043835]=4999,[3482199602]=79,
		[3482199918]=230,[3482200241]=679,[3482271454]=1799,[3482980939]=679,[3482982251]=799,[3483801741]=149,[3483801743]=4999,[3483801744]=1249,[3483801745]=429,[3489363338]=429,[3489363342]=1249,[3489363343]=149,[3489363344]=4999,[3490207231]=1299,[3497475839]=149,[3497475843]=4999,[3497475844]=1249,[3497475846]=429,[3498980651]=1799,
		[3512151971]=149,[3512151973]=429,[3512151976]=1249,[3512151977]=4999,[3519865801]=799,[3520430327]=429,[3520430328]=1249,[3520430329]=149,[3520430331]=4999,[3546475721]=1700,[3563674024]=1699,[3568823262]=639,[3568827015]=59,[3568827227]=175,[3568827595]=499,[3570157250]=4999,[3570335691]=6999,[3576524674]=149,[3576524780]=429,[3576524860]=1249,
		[3576525035]=4999,[3584036637]=149,[3584036735]=429,[3584036839]=1249,[3584075576]=639,[3587190661]=4999,[3587239446]=639,[3588292639]=199,[3588293165]=575,[3588293244]=1699,[3588293328]=6999,[3602505965]=149,[3602506028]=429,[3602506064]=1249,[3602506115]=4999,[3602742364]=639,[3603829987]=199,[3603830024]=575,[3603830055]=1699,[3603830077]=6999,
		[3607717721]=59,[3607717736]=175,[3607717758]=499,[3607717778]=1999,[3607717910]=639,[3608858826]=79,[3608858860]=230,[3608858882]=679,[3608858906]=2799,[3610249313]=279,[3611262564]=59,[3611262600]=175,[3611262627]=499,[3612305749]=59,[3612305786]=175,[3612305812]=499,[3612305842]=1999,[3612306093]=639,[3625639161]=79,[3625640337]=230,[3625641435]=679,[3625642643]=2799,[3708088084]=959,
	}
	-- Harga dari MarketplaceService:GetProductInfo(id, Product) — HARUS pakai
	-- InfoType.Product (MC:GetProductInfo cache-nya di-key by id doang, bisa
	-- ketuker sama info Asset). Engine nge-cache hasil per (id,infoType), jadi
	-- id yg udah pernah kefetch (mis. sama shop asli game) balik instan.
	-- RetryPcall manual: throttle ga di-cache -> diulang di pass prefetch berikut.
	local function fetchPrice(id)
		if id == nil or id == 0 then return nil end
		local st = PRICE[id]                     -- tabel statis: instan, 0 panggilan
		if st ~= nil then return st end
		local c = priceCache[id]
		if c ~= nil then return c or nil end
		local ok, info = pcall(function() return MPS:GetProductInfo(id, Enum.InfoType.Product) end)
		if not ok then return nil end           -- throttle/error: jangan cache, coba lagi nanti
		local p = info and info.PriceInRobux
		priceCache[id] = p or false             -- ok tapi ga ada harga = ga dijual Robux
		return p or nil
	end

	local prefetchStarted = false
	-- Prefetch PARALEL (bounded): fetchPrice yield di network, jadi N worker
	-- coroutine bikin ~N request barengan (game aslinya izinin ~36) -> jauh
	-- lebih cepet drpd 1-per-1. Multi-pass buat yg kena throttle (belum ke-cache).
	local WORKERS = 24
	local function startPrefetch(entries)
		if prefetchStarted then return end
		prefetchStarted = true
		task.spawn(function()
			for pass = 1, 6 do
				local idx = 0
				local finished = 0
				for _ = 1, WORKERS do
					task.spawn(function()
						while ctx.alive() do
							idx = idx + 1                 -- coroutine kooperatif: aman antar-yield
							local e = entries[idx]
							if not e then break end
							if e.id ~= 0 and priceCache[e.id] == nil then fetchPrice(e.id) end
						end
						finished = finished + 1
					end)
				end
				while finished < WORKERS and ctx.alive() do task.wait() end
				local remaining = 0
				for _, e in ipairs(entries) do
					if e.id ~= 0 and priceCache[e.id] == nil then remaining = remaining + 1 end
				end
				if remaining == 0 or not ctx.alive() then break end
				task.wait(0.5)                            -- napas sebentar sebelum retry throttle
			end
		end)
	end

	-- prewarm: mulai isi cache harga di background (dipanggil pas hub kebuka),
	-- jadi pas buka Premium Shop harga udah siap. Ringan & ga nge-block.
	function ctx.premiumPrewarm()
		local d = giftData()
		local ids = {}
		for _, v in pairs(d) do
			if type(v) == "table" and v.NormalId and v.NormalId ~= 0 and PRICE[v.NormalId] == nil then
				ids[#ids + 1] = { id = v.NormalId }   -- yg udah di tabel statis ga usah fetch
			end
		end
		startPrefetch(ids)
	end

	-- opsi dropdown item: cuma entry yg BENERAN bisa dibeli (NormalId ~= 0).
	-- Item 0/0 (mis. seed) itu cuma item trade/RAP, ga dijual di shop -> skip.
	-- Display + harga Robux (kalau udah ke-cache). Prefetch jalan di background.
	function ctx.getPremiumItemOptions()
		local d = giftData()
		local out, ids = {}, {}
		for k, v in pairs(d) do
			if type(v) == "table" and v.NormalId and v.NormalId ~= 0 then
				local disp = tostring(v.Display or k)
				local p = PRICE[v.NormalId] or priceCache[v.NormalId]
				if type(p) == "number" then
					disp = disp .. ("  (R$ %d)"):format(p)
				end
				out[#out + 1] = { name = k, display = disp }
				if PRICE[v.NormalId] == nil then ids[#ids + 1] = { id = v.NormalId } end
			end
		end
		table.sort(out, function(a, b) return a.display < b.display end)
		startPrefetch(ids)
		return out
	end
	function ctx.getPremiumPayOptions()
		return { { name = "robux", display = "Robux" }, { name = "token", display = "Token" } }
	end

	-- prompt beli 1 id sesuai payment method (token / robux).
	local function purchaseId(id, label)
		if CFG.premiumPay == "token" then
			local tt = ttFolder()
			if not (tt and tt:FindFirstChild("Purchase")) then ctx.setStatus("Premium Shop: Token remote ga ada"); return end
			local canOk, can = pcall(function() return tt.CanPurchase:InvokeServer(id) end)
			if canOk and can then
				pcall(function() tt.Purchase:InvokeServer(id) end)
				ctx.setStatus("Premium Shop: " .. label .. " via Token…")
			else
				ctx.setStatus("Premium Shop: item ini ga bisa Token, pakai Robux")
			end
		else
			if MC and MC.PromptPurchaseRobux then
				pcall(function() MC:PromptPurchaseRobux(id, Enum.InfoType.Product) end)
			else
				pcall(function() MPS:PromptProductPurchase(LP, id) end)
			end
			ctx.setStatus("Premium Shop: prompt Robux " .. label .. " dibuka")
		end
	end

	-- fetch harga item terpilih & tampilkan di status (dipanggil saat milih item).
	function ctx.premiumShowPrice()
		local e = entryOf(CFG.premiumItem)
		if not (e and e.NormalId) then return end
		local name = tostring(e.Display or CFG.premiumItem)
		local p = fetchPrice(e.NormalId)
		if p then
			ctx.setStatus(("Premium: %s — R$ %d"):format(name, p))
		else
			ctx.setStatus(("Premium: %s"):format(name))
		end
	end

	-- BELI buat diri sendiri (NormalId).
	function ctx.premiumBuy()
		local e = entryOf(CFG.premiumItem)
		if not (e and e.NormalId) then ctx.setStatus("Premium Shop: pilih item dulu"); return end
		purchaseId(e.NormalId, "beli")
	end

	-- GIFT ke player (GiftId). Game yg minta penerima.
	function ctx.premiumGift()
		local e = entryOf(CFG.premiumItem)
		if not (e and e.GiftId) then ctx.setStatus("Premium Shop: item ini ga ada opsi Gift"); return end
		purchaseId(e.GiftId, "gift")
	end
end
]=],
	["ui/components.lua"] = [=[
--[[ components.lua — Kontrol UI Garden (Fluent Mobile Remake)
     Komponen mobile-friendly, elegan, dan nyaman digunakan berpalet PINK ROYALE.
--]]

return function(ctx)
	local TS = game:GetService("TweenService")
	local UserInputService = game:GetService("UserInputService")
	local C  = ctx.C
	local F  = ctx.F
	local mk, corner, stroke, pad, grad = ctx.mk, ctx.corner, ctx.stroke, ctx.pad, ctx.grad

	local Window = ctx.Window or ctx.state.window

	----------------------------------------------------------------- Helper Label Kiri
	local function makeLabels(parent, title, desc, rightMargin)
		local txts = mk("Frame", {
			Size = UDim2.new(1, -(rightMargin or 130), 1, 0),
			BackgroundTransparency = 1,
		}, parent)
		pad(txts, 4, 0, 0, 0)

		local tLbl = mk("TextLabel", {
			Size = UDim2.new(1, 0, 0, 20),
			Position = UDim2.fromOffset(0, desc and 2 or 8),
			BackgroundTransparency = 1,
			Text = tostring(title or ""),
			Font = F.bold,
			TextSize = 13.5,
			TextColor3 = C.txt,
			TextXAlignment = Enum.TextXAlignment.Left,
		}, txts)

		local dLbl
		if desc and desc ~= "" then
			dLbl = mk("TextLabel", {
				Size = UDim2.new(1, 0, 0, 16),
				Position = UDim2.fromOffset(0, 22),
				BackgroundTransparency = 1,
				Text = tostring(desc),
				Font = F.reg,
				TextSize = 11.5,
				TextColor3 = C.sub,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
			}, txts)
		end

		return txts, tLbl, dLbl
	end

	----------------------------------------------------------------- Divider
	local function divider(parent)
		local d = mk("Frame", {
			Size = UDim2.new(1, 0, 0, 1),
			BackgroundColor3 = C.strokeSub,
			BackgroundTransparency = 0.5,
			BorderSizePixel = 0,
			LayoutOrder = 9999,
		}, parent)
		grad(d, 0, C.strokeSub, C.acc)
		return d
	end

	----------------------------------------------------------------- Section Header
	local function makeSection(parent, title)
		local sec = mk("Frame", {
			Size = UDim2.new(1, 0, 0, 28),
			BackgroundTransparency = 1,
			LayoutOrder = 0,
		}, parent)
		mk("TextLabel", {
			Size = UDim2.new(1, -10, 1, 0),
			Position = UDim2.fromOffset(6, 0),
			BackgroundTransparency = 1,
			Text = tostring(title):upper(),
			Font = F.bold,
			TextSize = 11,
			TextColor3 = C.acc,
			TextXAlignment = Enum.TextXAlignment.Left,
		}, sec)
		return sec
	end

	----------------------------------------------------------------- Toggle Switch (Touch-Optimized)
	local function makeToggle(parent, title, desc, getv, setv, order)
		local row = mk("Frame", {
			Size = UDim2.new(1, 0, 0, desc and 48 or 40),
			BackgroundColor3 = C.row,
			BackgroundTransparency = 0.5,
			BorderSizePixel = 0,
			LayoutOrder = order or 0,
		}, parent)
		corner(row, 8)
		local rowStroke = stroke(row, C.strokeSub, 1, 0.6)
		pad(row, 10, 10, 4, 4)

		makeLabels(row, title, desc, 54)

		local pill = mk("TextButton", {
			Size = UDim2.fromOffset(40, 22),
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -2, 0.5, 0),
			BackgroundColor3 = C.panel,
			Text = "",
			AutoButtonColor = false,
		}, row)
		corner(pill, 11)
		local pillStroke = stroke(pill, C.strokeSub, 1.2, 0.5)

		local pillGrad = mk("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = C.acc,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = 2,
		}, pill)
		corner(pillGrad, 11)
		grad(pillGrad, 0, C.acc, C.acc2)

		local knob = mk("Frame", {
			Size = UDim2.fromOffset(16, 16),
			Position = UDim2.fromOffset(3, 3),
			BackgroundColor3 = C.sub,
			ZIndex = 3,
		}, pill)
		corner(knob, 8)

		local function render(animate)
			local on = false
			if type(getv) == "function" then
				on = not not getv()
			elseif type(getv) == "boolean" then
				on = getv
			end

			local targetPos = on and UDim2.fromOffset(21, 3) or UDim2.fromOffset(3, 3)
			local targetDotColor = on and Color3.new(1, 1, 1) or C.sub
			local targetPillColor = on and C.acc or C.panel
			local targetGradTrans = on and 0 or 1
			local targetStrokeCol = on and C.accSoft or C.strokeSub

			if animate then
				TS:Create(knob, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Position = targetPos,
					BackgroundColor3 = targetDotColor,
				}):Play()
				TS:Create(pillGrad, TweenInfo.new(0.2), { BackgroundTransparency = targetGradTrans }):Play()
				TS:Create(pill, TweenInfo.new(0.2), { BackgroundColor3 = targetPillColor }):Play()
				TS:Create(pillStroke, TweenInfo.new(0.2), { Color = targetStrokeCol }):Play()
			else
				knob.Position = targetPos
				knob.BackgroundColor3 = targetDotColor
				pillGrad.BackgroundTransparency = targetGradTrans
				pill.BackgroundColor3 = targetPillColor
				pillStroke.Color = targetStrokeCol
			end
		end

		local function toggle()
			local cur = false
			if type(getv) == "function" then cur = not not getv() end
			local nv = not cur
			if setv then setv(nv) end
			render(true)
			if ctx.log then ctx.log(title .. (nv and " ➔ ON" or " ➔ OFF")) end
		end

		pill.MouseButton1Click:Connect(toggle)

		render(false)

		local comp = {
			Frame = row,
			Set = function(_, v) if setv then setv(v) end; render(true) end,
			Get = function(_) return type(getv) == "function" and getv() or false end,
			refresh = function() render(true) end
		}
		setmetatable(comp, {
			__call = function() render(true) end
		})
		return comp
	end

	----------------------------------------------------------------- Text Input
	local function makeInput(parent, title, desc, getv, setv, order)
		local row = mk("Frame", {
			Size = UDim2.new(1, 0, 0, desc and 48 or 40),
			BackgroundColor3 = C.row,
			BackgroundTransparency = 0.5,
			BorderSizePixel = 0,
			LayoutOrder = order or 0,
		}, parent)
		corner(row, 8)
		local rowStroke = stroke(row, C.strokeSub, 1, 0.6)
		pad(row, 10, 10, 4, 4)

		makeLabels(row, title, desc, 135)

		local boxFrame = mk("Frame", {
			Size = UDim2.fromOffset(125, 28),
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -2, 0.5, 0),
			BackgroundColor3 = C.panel,
			BorderSizePixel = 0,
		}, row)
		corner(boxFrame, 6)
		local bStroke = stroke(boxFrame, C.strokeSub, 1, 0.5)

		local val = type(getv) == "function" and getv() or getv or ""
		local box = mk("TextBox", {
			Size = UDim2.new(1, -12, 1, 0),
			Position = UDim2.fromOffset(6, 0),
			BackgroundTransparency = 1,
			Text = tostring(val),
			PlaceholderText = "...",
			Font = F.bold,
			TextSize = 12,
			TextColor3 = C.accSoft,
			ClearTextOnFocus = false,
			TextXAlignment = Enum.TextXAlignment.Center,
		}, boxFrame)

		local indicator = mk("Frame", {
			Size = UDim2.new(1, 0, 0, 1.5),
			Position = UDim2.new(0, 0, 1, -1),
			BackgroundColor3 = C.strokeSub,
			BorderSizePixel = 0,
		}, boxFrame)

		box.Focused:Connect(function()
			TS:Create(indicator, TweenInfo.new(0.2), { BackgroundColor3 = C.acc }):Play()
			TS:Create(bStroke, TweenInfo.new(0.2), { Color = C.acc, Transparency = 0.2 }):Play()
		end)

		box.FocusLost:Connect(function()
			TS:Create(indicator, TweenInfo.new(0.2), { BackgroundColor3 = C.strokeSub }):Play()
			TS:Create(bStroke, TweenInfo.new(0.2), { Color = C.strokeSub, Transparency = 0.5 }):Play()
			if setv then setv(box.Text) end
		end)

		return {
			Frame = row,
			Box = box,
			Set = function(_, t) box.Text = tostring(t) end,
			Get = function(_) return box.Text end,
		}
	end

	----------------------------------------------------------------- Single Dropdown (Touch-Safe)
	local function makeSingleDropdown(parent, title, desc, optionsOrFn, getv, setv, order)
		local row = mk("Frame", {
			Size = UDim2.new(1, 0, 0, desc and 48 or 40),
			BackgroundColor3 = C.row,
			BackgroundTransparency = 0.5,
			BorderSizePixel = 0,
			LayoutOrder = order or 0,
		}, parent)
		corner(row, 8)
		stroke(row, C.strokeSub, 1, 0.6)
		pad(row, 10, 10, 4, 4)

		makeLabels(row, title, desc, 160)

		local curVal = type(getv) == "function" and getv() or getv or "--"

		local triggerBtn = mk("TextButton", {
			Size = UDim2.fromOffset(150, 28),
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -2, 0.5, 0),
			BackgroundColor3 = C.panel,
			Text = "",
			AutoButtonColor = false,
		}, row)
		corner(triggerBtn, 6)
		local trStroke = stroke(triggerBtn, C.strokeSub, 1, 0.5)

		local valLbl = mk("TextLabel", {
			Size = UDim2.new(1, -24, 1, 0),
			Position = UDim2.fromOffset(8, 0),
			BackgroundTransparency = 1,
			Text = tostring(curVal),
			Font = F.bold,
			TextSize = 12,
			TextColor3 = C.accSoft,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
		}, triggerBtn)

		local chev = mk("TextLabel", {
			Size = UDim2.fromOffset(16, 16),
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -4, 0.5, 0),
			BackgroundTransparency = 1,
			Text = "▼",
			Font = F.bold,
			TextSize = 10,
			TextColor3 = C.acc,
		}, triggerBtn)

		-- Floating Dropdown Menu
		local hostGui = ctx.state.gui or (gethui and gethui()) or game:GetService("CoreGui")
		local backdrop = mk("TextButton", {
			Name = "SingleDropdownBackdrop",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Text = "",
			Visible = false,
			ZIndex = 200,
		}, hostGui)

		local menuFrame = mk("Frame", {
			Size = UDim2.fromOffset(160, 160),
			BackgroundColor3 = C.bg,
			BackgroundTransparency = 0.05,
			BorderSizePixel = 0,
			Visible = false,
			ZIndex = 201,
		}, backdrop)
		corner(menuFrame, 8)
		stroke(menuFrame, C.stroke, 1.4, 0.2)

		local scroll = mk("ScrollingFrame", {
			Size = UDim2.new(1, -8, 1, -8),
			Position = UDim2.fromOffset(4, 4),
			BackgroundTransparency = 1,
			ScrollBarThickness = 3,
			CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollBarImageColor3 = C.acc,
			BorderSizePixel = 0,
		}, menuFrame)
		mk("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder }, scroll)

		local function closeMenu()
			backdrop.Visible = false
			menuFrame.Visible = false
			TS:Create(chev, TweenInfo.new(0.2), { Rotation = 0 }):Play()
		end

		local function openMenu()
			for _, ch in ipairs(scroll:GetChildren()) do
				if ch:IsA("TextButton") then ch:Destroy() end
			end

			local opts = type(optionsOrFn) == "function" and optionsOrFn() or optionsOrFn or {}
			for i, item in ipairs(opts) do
				local val = type(item) == "table" and (item.value or item[1]) or item
				local disp = type(item) == "table" and (item.display or item[2] or val) or tostring(item)
				local isSel = (val == (type(getv) == "function" and getv() or curVal))

				local itm = mk("TextButton", {
					Size = UDim2.new(1, 0, 0, 30),
					BackgroundColor3 = isSel and C.rowAlt or C.panel,
					BackgroundTransparency = isSel and 0.2 or 0.7,
					Text = "   " .. tostring(disp),
					Font = isSel and F.bold or F.semi,
					TextSize = 12,
					TextColor3 = isSel and C.accSoft or C.txt,
					TextXAlignment = Enum.TextXAlignment.Left,
					AutoButtonColor = false,
					LayoutOrder = i,
				}, scroll)
				corner(itm, 5)

				itm.MouseButton1Click:Connect(function()
					curVal = val
					valLbl.Text = tostring(disp)
					if setv then setv(val) end
					closeMenu()
				end)
			end

			local pos = triggerBtn.AbsolutePosition
			local sz = triggerBtn.AbsoluteSize
			local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
			local menuW = math.max(160, sz.X)
			local menuH = math.min(180, #opts * 33 + 12)

			local posX = math.clamp(pos.X, 10, vp.X - menuW - 10)
			local posY = pos.Y + sz.Y + 4
			if posY + menuH > vp.Y - 10 then
				posY = pos.Y - menuH - 4
			end

			menuFrame.Position = UDim2.fromOffset(posX, posY)
			menuFrame.Size = UDim2.fromOffset(menuW, menuH)
			menuFrame.Visible = true
			backdrop.Visible = true
			TS:Create(chev, TweenInfo.new(0.2), { Rotation = 180 }):Play()
		end

		backdrop.MouseButton1Click:Connect(closeMenu)
		triggerBtn.MouseButton1Click:Connect(function()
			if backdrop.Visible then closeMenu() else openMenu() end
		end)

		local function refresh()
			curVal = type(getv) == "function" and getv() or curVal
			valLbl.Text = tostring(curVal)
		end

		return {
			Frame = row,
			Refresh = refresh,
			SetValue = function(_, v) curVal = v; valLbl.Text = tostring(v) end
		}
	end

	----------------------------------------------------------------- Multi Dropdown with Search & Count Badge
	local function makeMultiDropdown(parent, title, desc, optionsOrFn, selectedSet, onChange, order)
		local row = mk("Frame", {
			Size = UDim2.new(1, 0, 0, desc and 48 or 40),
			BackgroundColor3 = C.row,
			BackgroundTransparency = 0.5,
			BorderSizePixel = 0,
			LayoutOrder = order or 0,
		}, parent)
		corner(row, 8)
		stroke(row, C.strokeSub, 1, 0.6)
		pad(row, 10, 10, 4, 4)

		makeLabels(row, title, desc, 160)

		local triggerBtn = mk("TextButton", {
			Size = UDim2.fromOffset(150, 28),
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -2, 0.5, 0),
			BackgroundColor3 = C.panel,
			Text = "",
			AutoButtonColor = false,
		}, row)
		corner(triggerBtn, 6)
		stroke(triggerBtn, C.strokeSub, 1, 0.5)

		local valLbl = mk("TextLabel", {
			Size = UDim2.new(1, -24, 1, 0),
			Position = UDim2.fromOffset(8, 0),
			BackgroundTransparency = 1,
			Text = "--",
			Font = F.bold,
			TextSize = 12,
			TextColor3 = C.accSoft,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
		}, triggerBtn)

		local chev = mk("TextLabel", {
			Size = UDim2.fromOffset(16, 16),
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -4, 0.5, 0),
			BackgroundTransparency = 1,
			Text = "▼",
			Font = F.bold,
			TextSize = 10,
			TextColor3 = C.acc,
		}, triggerBtn)

		local function updateSummary()
			local count = 0
			local first = nil
			if type(selectedSet) == "table" then
				for k, v in pairs(selectedSet) do
					if v then
						count = count + 1
						if not first then first = k end
					end
				end
			end
			if count == 0 then
				valLbl.Text = "--"
				valLbl.TextColor3 = C.sub
			elseif count == 1 then
				valLbl.Text = tostring(first)
				valLbl.TextColor3 = C.accSoft
			else
				valLbl.Text = tostring(count) .. " dipilih ✦"
				valLbl.TextColor3 = C.acc
			end
		end

		local hostGui = ctx.state.gui or (gethui and gethui()) or game:GetService("CoreGui")
		local backdrop = mk("TextButton", {
			Name = "MultiDropdownBackdrop",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Text = "",
			Visible = false,
			ZIndex = 200,
		}, hostGui)

		local menuFrame = mk("Frame", {
			Size = UDim2.fromOffset(230, 250),
			BackgroundColor3 = C.bg,
			BackgroundTransparency = 0.04,
			BorderSizePixel = 0,
			Visible = false,
			ZIndex = 201,
		}, backdrop)
		corner(menuFrame, 10)
		stroke(menuFrame, C.stroke, 1.4, 0.2)

		local searchBox = mk("TextBox", {
			Size = UDim2.new(1, -16, 0, 28),
			Position = UDim2.fromOffset(8, 8),
			BackgroundColor3 = C.panel,
			PlaceholderText = "🔍 Cari opsi...",
			PlaceholderColor3 = C.sub,
			Text = "",
			Font = F.bold,
			TextSize = 12,
			TextColor3 = C.txt,
			ClearTextOnFocus = false,
		}, menuFrame)
		corner(searchBox, 6)
		stroke(searchBox, C.strokeSub, 1, 0.6)
		pad(searchBox, 8, 8, 0, 0)

		local scroll = mk("ScrollingFrame", {
			Size = UDim2.new(1, -16, 1, -44),
			Position = UDim2.fromOffset(8, 40),
			BackgroundTransparency = 1,
			ScrollBarThickness = 4,
			CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollBarImageColor3 = C.acc,
			BorderSizePixel = 0,
		}, menuFrame)
		mk("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder }, scroll)

		local optButtons = {}

		local function closeMenu()
			backdrop.Visible = false
			menuFrame.Visible = false
			TS:Create(chev, TweenInfo.new(0.2), { Rotation = 0 }):Play()
		end

		local function buildList()
			for _, ch in ipairs(scroll:GetChildren()) do
				if ch:IsA("TextButton") then ch:Destroy() end
			end
			optButtons = {}

			local opts = type(optionsOrFn) == "function" and optionsOrFn() or optionsOrFn or {}
			for i, item in ipairs(opts) do
				local val = type(item) == "table" and (item.value or item[1]) or item
				local disp = type(item) == "table" and (item.display or item[2] or val) or tostring(item)
				local isSel = selectedSet and selectedSet[val] == true

				local btn = mk("TextButton", {
					Size = UDim2.new(1, 0, 0, 30),
					BackgroundColor3 = isSel and C.rowAlt or C.panel,
					BackgroundTransparency = isSel and 0.1 or 0.6,
					Text = "   " .. tostring(disp),
					Font = isSel and F.bold or F.semi,
					TextSize = 12,
					TextColor3 = isSel and C.accSoft or C.txt,
					TextXAlignment = Enum.TextXAlignment.Left,
					AutoButtonColor = false,
					LayoutOrder = i,
				}, scroll)
				corner(btn, 6)
				local bStrk = stroke(btn, isSel and C.acc or C.strokeSub, 1, isSel and 0.2 or 0.7)

				local chk = mk("TextLabel", {
					Size = UDim2.fromOffset(18, 18),
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -6, 0.5, 0),
					BackgroundTransparency = 1,
					Text = isSel and "✓" or "",
					Font = F.bold,
					TextSize = 12,
					TextColor3 = C.green,
				}, btn)

				btn.MouseButton1Click:Connect(function()
					if selectedSet then
						if selectedSet[val] then
							selectedSet[val] = nil
						else
							selectedSet[val] = true
						end
					end
					local curSel = selectedSet and selectedSet[val] == true
					chk.Text = curSel and "✓" or ""
					btn.BackgroundColor3 = curSel and C.rowAlt or C.panel
					btn.TextColor3 = curSel and C.accSoft or C.txt
					bStrk.Color = curSel and C.acc or C.strokeSub
					bStrk.Transparency = curSel and 0.2 or 0.7
					updateSummary()
					if onChange then onChange() end
				end)

				optButtons[val] = { btn = btn, text = tostring(disp):lower() }
			end
		end

		searchBox:GetPropertyChangedSignal("Text"):Connect(function()
			local q = searchBox.Text:lower()
			for _, o in pairs(optButtons) do
				o.btn.Visible = (q == "" or o.text:find(q, 1, true) ~= nil)
			end
		end)

		local function openMenu()
			buildList()
			local pos = triggerBtn.AbsolutePosition
			local sz = triggerBtn.AbsoluteSize
			local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
			local menuW = 230
			local menuH = 240

			local posX = math.clamp(pos.X + sz.X - menuW, 10, vp.X - menuW - 10)
			local posY = pos.Y + sz.Y + 4
			if posY + menuH > vp.Y - 10 then
				posY = pos.Y - menuH - 4
			end

			menuFrame.Position = UDim2.fromOffset(posX, posY)
			menuFrame.Size = UDim2.fromOffset(menuW, menuH)
			menuFrame.Visible = true
			backdrop.Visible = true
			TS:Create(chev, TweenInfo.new(0.2), { Rotation = 180 }):Play()
		end

		backdrop.MouseButton1Click:Connect(closeMenu)
		triggerBtn.MouseButton1Click:Connect(function()
			if backdrop.Visible then closeMenu() else openMenu() end
		end)

		updateSummary()
		return updateSummary
	end

	local makeMultiDropdownDyn = makeMultiDropdown

	----------------------------------------------------------------- Button Card
	local function makeButton(parent, text, descOrColor, onClick, order, variant)
		local col = C.acc
		local descText = nil
		local clickCb = onClick

		if typeof(descOrColor) == "Color3" then
			col = descOrColor
		elseif type(descOrColor) == "string" and descOrColor ~= "" then
			descText = descOrColor
		elseif type(descOrColor) == "function" and not onClick then
			clickCb = descOrColor
		end

		local isDanger = (col == C.red)

		local btn = mk("TextButton", {
			Size = UDim2.new(1, 0, 0, descText and 48 or 36),
			BackgroundColor3 = isDanger and Color3.fromRGB(60, 20, 30) or C.row,
			BackgroundTransparency = 0.3,
			Text = "",
			AutoButtonColor = false,
			LayoutOrder = order or 0,
		}, parent)
		corner(btn, 8)
		local bStroke = stroke(btn, isDanger and C.red or C.strokeSub, 1.2, 0.4)
		pad(btn, 10, 10, 4, 4)

		if descText then
			makeLabels(btn, text, descText, 20)
		else
			mk("TextLabel", {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				Text = tostring(text or "Button"),
				Font = F.bold,
				TextSize = 13,
				TextColor3 = isDanger and C.red or C.txt,
				TextXAlignment = Enum.TextXAlignment.Center,
			}, btn)
		end

		btn.MouseEnter:Connect(function()
			TS:Create(btn, TweenInfo.new(0.15), { BackgroundTransparency = 0.1, BackgroundColor3 = isDanger and Color3.fromRGB(80, 25, 40) or C.rowHover }):Play()
			TS:Create(bStroke, TweenInfo.new(0.15), { Color = isDanger and C.red or C.acc, Transparency = 0.2 }):Play()
		end)
		btn.MouseLeave:Connect(function()
			TS:Create(btn, TweenInfo.new(0.15), { BackgroundTransparency = 0.3, BackgroundColor3 = isDanger and Color3.fromRGB(60, 20, 30) or C.row }):Play()
			TS:Create(bStroke, TweenInfo.new(0.15), { Color = isDanger and C.red or C.strokeSub, Transparency = 0.4 }):Play()
		end)
		btn.MouseButton1Click:Connect(function()
			if clickCb then clickCb() end
		end)

		return btn
	end

	----------------------------------------------------------------- Slider
	local function makeSlider(parent, optOrTitle, minVal, maxVal, curVal, suffixStr, onChangeCb, orderNum)
		local opt = type(optOrTitle) == "table" and optOrTitle or {
			label = optOrTitle,
			min = minVal or 0,
			max = maxVal or 100,
			value = curVal or minVal or 0,
			suffix = suffixStr or "",
			onChange = onChangeCb,
			order = orderNum,
		}

		local label = opt.label or "Slider"
		local min = opt.min or 0
		local max = opt.max or 100
		local cur = math.clamp(opt.value or min, min, max)
		local suffix = opt.suffix or ""
		local onChange = opt.onChange

		local row = mk("Frame", {
			Size = UDim2.new(1, 0, 0, 52),
			BackgroundColor3 = C.row,
			BackgroundTransparency = 0.5,
			BorderSizePixel = 0,
			LayoutOrder = opt.order or 0,
		}, parent)
		corner(row, 8)
		stroke(row, C.strokeSub, 1, 0.6)
		pad(row, 10, 10, 6, 6)

		local topRow = mk("Frame", {
			Size = UDim2.new(1, 0, 0, 18),
			BackgroundTransparency = 1,
		}, row)

		mk("TextLabel", {
			Size = UDim2.new(1, -70, 1, 0),
			BackgroundTransparency = 1,
			Text = label,
			Font = F.bold,
			TextSize = 13,
			TextColor3 = C.txt,
			TextXAlignment = Enum.TextXAlignment.Left,
		}, topRow)

		local valLbl = mk("TextLabel", {
			Size = UDim2.fromOffset(65, 18),
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, 0, 0, 0),
			BackgroundTransparency = 1,
			Text = tostring(cur) .. suffix,
			Font = F.bold,
			TextSize = 12,
			TextColor3 = C.acc,
			TextXAlignment = Enum.TextXAlignment.Right,
		}, topRow)

		local rail = mk("Frame", {
			Size = UDim2.new(1, 0, 0, 6),
			Position = UDim2.new(0, 0, 1, -8),
			BackgroundColor3 = C.panel,
			BorderSizePixel = 0,
		}, row)
		corner(rail, 3)

		local fill = mk("Frame", {
			Size = UDim2.new((cur - min) / (max - min), 0, 1, 0),
			BackgroundColor3 = C.acc,
			BorderSizePixel = 0,
		}, rail)
		corner(fill, 3)
		grad(fill, 0, C.acc, C.acc2)

		local knob = mk("Frame", {
			Size = UDim2.fromOffset(14, 14),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new((cur - min) / (max - min), 0, 0.5, 0),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,
			ZIndex = 2,
		}, rail)
		corner(knob, 7)
		stroke(knob, C.acc, 1.2, 0)

		local touchBtn = mk("TextButton", {
			Size = UDim2.new(1, 16, 0, 36),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Text = "",
		}, rail)

		local function updateFromX(posX)
			local rPos = rail.AbsolutePosition.X
			local rSz = rail.AbsoluteSize.X
			local pct = math.clamp((posX - rPos) / rSz, 0, 1)
			cur = math.floor(min + (max - min) * pct + 0.5)
			valLbl.Text = tostring(cur) .. suffix
			fill.Size = UDim2.new(pct, 0, 1, 0)
			knob.Position = UDim2.new(pct, 0, 0.5, 0)
			if onChange then onChange(cur) end
		end

		local dragging = false
		touchBtn.InputBegan:Connect(function(inp)
			if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				updateFromX(inp.Position.X)
			end
		end)
		UserInputService.InputChanged:Connect(function(inp)
			if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
				updateFromX(inp.Position.X)
			end
		end)
		UserInputService.InputEnded:Connect(function(inp)
			if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
				dragging = false
			end
		end)

		return {
			Frame = row,
			SetValue = function(_, v)
				cur = math.clamp(v, min, max)
				local pct = (cur - min) / (max - min)
				valLbl.Text = tostring(cur) .. suffix
				fill.Size = UDim2.new(pct, 0, 1, 0)
				knob.Position = UDim2.new(pct, 0, 0.5, 0)
			end,
			GetValue = function(_) return cur end,
		}
	end

	----------------------------------------------------------------- Collapsible Accordion Card
	local function makeAccordion(parent, title, order, defaultOpen)
		local container = mk("Frame", {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundColor3 = C.row,
			BackgroundTransparency = 0.4,
			BorderSizePixel = 0,
			LayoutOrder = order or 0,
		}, parent)
		corner(container, 10)
		local cardStroke = stroke(container, C.strokeSub, 1.2, 0.5)
		mk("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 0) }, container)

		local head = mk("TextButton", {
			Size = UDim2.new(1, 0, 0, 38),
			BackgroundTransparency = 1,
			Text = "",
			AutoButtonColor = false,
			LayoutOrder = 1,
		}, container)
		pad(head, 12, 12, 0, 0)

		local accentBar = mk("Frame", {
			Size = UDim2.new(0, 3, 0, 18),
			Position = UDim2.new(0, 0, 0.5, -9),
			BackgroundColor3 = C.acc,
			BorderSizePixel = 0,
		}, head)
		corner(accentBar, 2)
		grad(accentBar, 90, C.acc, C.acc2)

		local titleLabel = mk("TextLabel", {
			Size = UDim2.new(1, -30, 1, 0),
			Position = UDim2.fromOffset(10, 0),
			BackgroundTransparency = 1,
			Text = tostring(title),
			Font = F.bold,
			TextSize = 13,
			TextColor3 = C.txt,
			TextXAlignment = Enum.TextXAlignment.Left,
		}, head)

		local chevron = mk("TextLabel", {
			Size = UDim2.fromOffset(16, 16),
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, 0, 0.5, 0),
			BackgroundTransparency = 1,
			Text = "▼",
			Font = F.bold,
			TextSize = 10,
			TextColor3 = C.acc,
			Rotation = defaultOpen and 180 or 0,
		}, head)

		local body = mk("Frame", {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Visible = defaultOpen or false,
			LayoutOrder = 2,
		}, container)
		pad(body, 8, 8, 4, 8)
		mk("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, body)

		local isOpen = defaultOpen or false

		local function setOpen(open)
			isOpen = open and true or false
			body.Visible = isOpen
			local rot = isOpen and 180 or 0
			TS:Create(chevron, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Rotation = rot }):Play()
			TS:Create(cardStroke, TweenInfo.new(0.2), {
				Color = isOpen and C.stroke or C.strokeSub,
				Transparency = isOpen and 0.2 or 0.5
			}):Play()
		end

		head.MouseButton1Click:Connect(function()
			setOpen(not isOpen)
		end)

		head.MouseEnter:Connect(function()
			TS:Create(titleLabel, TweenInfo.new(0.15), { TextColor3 = C.accSoft }):Play()
		end)
		head.MouseLeave:Connect(function()
			TS:Create(titleLabel, TweenInfo.new(0.15), { TextColor3 = C.txt }):Play()
		end)

		return body, setOpen, container
	end

	----------------------------------------------------------------- SubTabs (Pill Navigation di Garden)
	local function makeSubTabs(parent, tabsList, defaultId, opts)
		opts = opts or {}
		local hasBottomBar = opts.hasBottomBar ~= false
		local currentTab = defaultId or (tabsList[1] and tabsList[1].id)

		local wrapper = mk("Frame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
		}, parent)

		local barFrame = mk("Frame", {
			Size = UDim2.new(1, 0, 0, 36),
			BackgroundTransparency = 1,
			LayoutOrder = 0,
		}, wrapper)
		pad(barFrame, 0, 0, 2, 6)
		mk("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 8),
		}, barFrame)

		local subContent = mk("Frame", {
			Size = UDim2.new(1, 0, 1, hasBottomBar and -76 or -38),
			Position = UDim2.fromOffset(0, 38),
			BackgroundTransparency = 1,
		}, wrapper)

		local pages = {}
		local tabBtns = {}

		local function selectSubTab(id)
			currentTab = id
			for pid, p in pairs(pages) do
				p.Visible = (pid == id)
			end
			for bid, b in pairs(tabBtns) do
				local active = (bid == id)
				TS:Create(b.btn, TweenInfo.new(0.15), {
					BackgroundColor3 = active and C.rowAlt or C.row,
					TextColor3 = active and Color3.new(1, 1, 1) or C.txt,
				}):Play()
				TS:Create(b.stroke, TweenInfo.new(0.15), {
					Color = active and C.acc or C.strokeSub,
					Transparency = active and 0.1 or 0.6,
				}):Play()
			end
		end

		for i, t in ipairs(tabsList) do
			local id = t.id
			local title = t.name or id
			local isDefault = (id == currentTab)

			local btn = mk("TextButton", {
				Size = UDim2.new(0, math.max(76, #title * 9 + 20), 1, 0),
				BackgroundColor3 = isDefault and C.rowAlt or C.row,
				Text = title,
				Font = F.bold,
				TextSize = 12.5,
				TextColor3 = isDefault and Color3.new(1, 1, 1) or C.txt,
				LayoutOrder = i,
				AutoButtonColor = false,
			}, barFrame)
			corner(btn, 12)
			local s = stroke(btn, isDefault and C.acc or C.strokeSub, 1.2, isDefault and 0.1 or 0.6)

			btn.MouseButton1Click:Connect(function()
				selectSubTab(id)
			end)

			tabBtns[id] = { btn = btn, stroke = s }

			local subPg = mk("ScrollingFrame", {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				Visible = isDefault,
				ScrollBarThickness = 3,
				CanvasSize = UDim2.new(),
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				ScrollBarImageColor3 = C.acc,
				BorderSizePixel = 0,
			}, subContent)
			pad(subPg, 2, 4, 2, 4)
			mk("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, subPg)

			pages[id] = subPg
		end

		local bottomBarFrame = nil
		if hasBottomBar then
			bottomBarFrame = mk("Frame", {
				Size = UDim2.new(1, 0, 0, 36),
				Position = UDim2.new(0, 0, 1, -36),
				BackgroundTransparency = 1,
				ZIndex = 5,
			}, wrapper)
		end

		return {
			wrapper = wrapper,
			pages = pages,
			selectTab = selectSubTab,
			bottomBarFrame = bottomBarFrame,
		}
	end

	----------------------------------------------------------------- Start / Stop Control Bar
	local function makeStartStopBar(parent, getRunning, onStart, onStop, order)
		local bar = mk("Frame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			LayoutOrder = order or 999,
		}, parent)
		pad(bar, 2, 2, 2, 2)
		mk("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 10),
			VerticalAlignment = Enum.VerticalAlignment.Center,
		}, bar)

		local startBtn = mk("TextButton", {
			Size = UDim2.fromOffset(88, 28),
			BackgroundColor3 = C.row,
			Text = "⚡ START",
			Font = F.bold,
			TextSize = 12,
			TextColor3 = C.txt,
			AutoButtonColor = false,
			LayoutOrder = 1,
		}, bar)
		corner(startBtn, 14)
		local startStroke = stroke(startBtn, C.strokeSub, 1.2, 0.4)

		local stopBtn = mk("TextButton", {
			Size = UDim2.fromOffset(78, 28),
			BackgroundColor3 = C.row,
			Text = "STOP",
			Font = F.bold,
			TextSize = 12,
			TextColor3 = C.sub,
			AutoButtonColor = false,
			LayoutOrder = 2,
		}, bar)
		corner(stopBtn, 14)
		local stopStroke = stroke(stopBtn, C.strokeSub, 1.2, 0.4)

		local function refresh()
			local running = (type(getRunning) == "function" and getRunning()) or false
			if running then
				startBtn.BackgroundColor3 = C.rowAlt
				startBtn.TextColor3 = C.green
				startStroke.Color = C.green
				startStroke.Transparency = 0.1

				stopBtn.BackgroundColor3 = C.row
				stopBtn.TextColor3 = C.txt
				stopStroke.Color = C.strokeSub
				stopStroke.Transparency = 0.5
			else
				startBtn.BackgroundColor3 = C.row
				startBtn.TextColor3 = C.txt
				startStroke.Color = C.strokeSub
				startStroke.Transparency = 0.5

				stopBtn.BackgroundColor3 = C.rowAlt
				stopBtn.TextColor3 = C.red
				stopStroke.Color = C.red
				stopStroke.Transparency = 0.1
			end
		end

		startBtn.MouseButton1Click:Connect(function()
			if onStart then onStart() end
			refresh()
		end)
		stopBtn.MouseButton1Click:Connect(function()
			if onStop then onStop() end
			refresh()
		end)

		refresh()
		return refresh
	end

	----------------------------------------------------------------- Page Creation (Maps to Fluent Tabs)
	local TAB_ICONS = {
		Pet       = "paw-print",
		Farm      = "sprout",
		Hatch     = "egg",
		Elephant  = "crown",
		Flow      = "flower-2",
		Growth    = "flower-2",
		Leveling  = "zap",
		Mutation  = "flask-conical",
		Inventory = "backpack",
		Shop      = "shopping-bag",
		Misc      = "settings",
	}

	local tabCount = 0
	local function makePage(name, titleText, iconLabel, order, fixedLayout, customSection)
		tabCount = tabCount + 1
		local idx = tabCount
		ctx.tabIndices = ctx.tabIndices or {}
		ctx.tabIndices[name] = idx

		local iconName = TAB_ICONS[name] or "sparkles"
		local tab = Window:AddTab({ Title = name, Icon = iconName })

		local pageContainer = tab.Container
		ctx.ui.pages[name] = pageContainer

		local dummyBtn = {
			BackgroundTransparency = 1,
			TextColor3 = C.txt,
			MouseButton1Click = {
				Connect = function(_, cb)
					return { Disconnect = function() end }
				end
			}
		}
		local dummyLine = { Visible = false }
		ctx.ui.tabBtns[name] = {
			btn = dummyBtn,
			line = dummyLine,
			setActive = function(on)
				if on and Window.SelectTab then
					Window:SelectTab(idx)
				end
			end
		}

		return pageContainer
	end

	----------------------------------------------------------------- Exports to ctx
	ctx.makePage            = makePage
	ctx.makeAccordion       = makeAccordion
	ctx.makeToggle          = makeToggle
	ctx.makeInput           = makeInput
	ctx.makeSingleDropdown  = makeSingleDropdown
	ctx.makeMultiDropdown   = makeMultiDropdown
	ctx.makeMultiDropdownDyn= makeMultiDropdownDyn
	ctx.makeButton          = makeButton
	ctx.makeSlider          = makeSlider
	ctx.makeSection         = makeSection
	ctx.makeSubTabs         = makeSubTabs
	ctx.makeStartStopBar    = makeStartStopBar
	ctx.divider             = divider
end
]=],
	["ui/fluent.lua"] = [=[
--[[
    Fluent Interface Suite - Android / Mobile Remake
    Integrated for CeszParadiseHub
--]]

local Fluent = (function()
--[[
    Fluent Interface Suite - Android / Mobile Remake
    Remade & Highly Optimized for Mobile, Touch & Cross-Platform Ergonomics
    
    Mobile Enhancements & Features:
    - Built-in Draggable Floating Mobile Toggle Button (Touch drag + tap bounce animation)
    - Scroll-Lock on Touch Drag: Sliders and Dropdowns temporarily lock ScrollingFrame
      so dragging sliders won't accidentally scroll the page!
    - Auto-Adaptive Screen Sizing & Dynamic Clamping (Adapts to phone landscape/portrait)
    - Viewport Orientation Listener (Keeps window visible when phone rotates)
    - Collapsible Mobile Tab Drawer (Hamburger menu for 100% full-width controls on mobile)
    - Touch-Optimized Sliders with 36px hitboxes, live badges & smooth drag
    - Touch-Safe Dropdowns with full-screen tap-to-close backdrop
    - Thumb-Friendly Toggles, Inputs, Colorpickers & Keybinds (Min 36-40px touch targets)
    - Safe 2D Frosted Glass fallback for Mobile Executors (Zero lag, 60-120 FPS, no crashes)
    - 100% Backward Compatible with original Fluent API
    - Built-in 818 Lucide Icons + Custom rbxassetid support
    - 6 Built-in Themes (Dark, Darker, Light, Aqua, Amethyst, Rose) + Custom Themes
    
    Original Author: dawid
    Remade for Android & Mobile Ergonomics
    License: MIT
--]]

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local TextService = game:GetService("TextService")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer and LocalPlayer:GetMouse()
local Camera = Workspace.CurrentCamera or Workspace:FindFirstChildWhichIsA("Camera")

-- Math & Table Polyfills
local typeof = typeof or type
local math_clamp = math.clamp or function(val, min, max)
    if val < min then return min end
    if val > max then return max end
    return val
end
local table_find = table.find or function(tbl, val)
    for i, v in ipairs(tbl) do
        if v == val then return i end
    end
    return nil
end

-- Protected GUI Helper (Works with Delta, Codex, Arceus X, Fluxus, Wave, Solara, Studio, etc.)
local protect_gui = protectgui or (syn and syn.protect_gui) or function() end
local function getGuiParent()
    if RunService:IsStudio() then
        return LocalPlayer:WaitForChild("PlayerGui")
    end
    if gethui then
        local success, result = pcall(gethui)
        if success and result then return result end
    end
    local coreGui = game:GetService("CoreGui")
    return coreGui or LocalPlayer:WaitForChild("PlayerGui")
end

-- Mobile Detection & Screen Helpers
local isMobile = (UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled)
local function isSmallScreen()
    if not Camera then return isMobile end
    local vp = Camera.ViewportSize
    return isMobile or (vp.Y > 0 and vp.Y < 520) or (vp.X > 0 and vp.X < 900)
end

-- ============================================================================
-- Signal & Spring Animation Engine (Flipper)
-- ============================================================================
local Signal = {}
Signal.__index = Signal
function Signal.new()
    return setmetatable({ _connections = {}, _threads = {} }, Signal)
end
function Signal:connect(handler)
    local conn = {
        signal = self,
        connected = true,
        _handler = handler,
        disconnect = function(c)
            if c.connected then
                c.connected = false
                for i, v in ipairs(c.signal._connections) do
                    if v == c then
                        table.remove(c.signal._connections, i)
                        break
                    end
                end
            end
        end
    }
    table.insert(self._connections, conn)
    return conn
end
function Signal:fire(...)
    for _, conn in ipairs(self._connections) do
        if conn.connected then
            task.spawn(conn._handler, ...)
        end
    end
    for _, thread in ipairs(self._threads) do
        task.spawn(thread, ...)
    end
    self._threads = {}
end
function Signal:wait()
    table.insert(self._threads, coroutine.running())
    return coroutine.yield()
end

local Spring = {}
Spring.__index = Spring
function Spring.new(targetValue, options)
    options = options or {}
    return setmetatable({
        _targetValue = targetValue,
        _frequency = options.frequency or 4,
        _dampingRatio = options.dampingRatio or 1
    }, Spring)
end
function Spring:step(state, dt)
    local d = self._dampingRatio
    local f = self._frequency * 2 * math.pi
    local g = self._targetValue
    local p0 = state.value
    local v0 = state.velocity or 0
    local offset = p0 - g
    local decay = math.exp(-d * f * dt)

    local p1, v1
    if d == 1 then
        p1 = (offset * (1 + f * dt) + v0 * dt) * decay + g
        v1 = (v0 * (1 - f * dt) - offset * (f * f * dt)) * decay
    elseif d < 1 then
        local c = math.sqrt(1 - d * d)
        local cos = math.cos(f * c * dt)
        local sin = math.sin(f * c * dt)
        local s = c > 0.0001 and (sin / c) or (dt * f)
        local s2 = (f * c > 0.0001) and (sin / (f * c)) or dt
        p1 = (offset * (cos + d * s) + v0 * s2) * decay + g
        v1 = (v0 * (cos - s * d) - offset * (s * f)) * decay
    else
        local c = math.sqrt(d * d - 1)
        local r1 = -f * (d - c)
        local r2 = -f * (d + c)
        local co2 = (v0 - offset * r1) / (2 * f * c)
        local co1 = offset - co2
        local e1 = co1 * math.exp(r1 * dt)
        local e2 = co2 * math.exp(r2 * dt)
        p1 = e1 + e2 + g
        v1 = e1 * r1 + e2 * r2
    end

    local complete = math.abs(v1) < 0.001 and math.abs(p1 - g) < 0.001
    return {
        complete = complete,
        value = complete and g or p1,
        velocity = v1
    }
end

local Instant = {}
Instant.__index = Instant
function Instant.new(targetValue)
    return setmetatable({ _targetValue = targetValue }, Instant)
end
function Instant:step()
    return { complete = true, value = self._targetValue, velocity = 0 }
end

local Linear = {}
Linear.__index = Linear
function Linear.new(targetValue, options)
    options = options or {}
    return setmetatable({
        _targetValue = targetValue,
        _velocity = options.velocity or 1
    }, Linear)
end
function Linear:step(state, dt)
    local v = state.value
    local vel = self._velocity
    local g = self._targetValue
    local step = dt * vel
    local complete = step >= math.abs(g - v)
    v = v + step * (g > v and 1 or -1)
    if complete then v = g vel = 0 end
    return { complete = complete, value = v, velocity = vel }
end

local BaseMotor = {}
BaseMotor.__index = BaseMotor
function BaseMotor.new()
    return setmetatable({
        _onStep = Signal.new(),
        _onStart = Signal.new(),
        _onComplete = Signal.new()
    }, BaseMotor)
end
function BaseMotor:onStep(fn) return self._onStep:connect(fn) end
function BaseMotor:onStart(fn) return self._onStart:connect(fn) end
function BaseMotor:onComplete(fn) return self._onComplete:connect(fn) end
function BaseMotor:start()
    if not self._connection then
        self._connection = RunService.RenderStepped:Connect(function(dt)
            self:step(dt)
        end)
    end
end
function BaseMotor:stop()
    if self._connection then
        self._connection:Disconnect()
        self._connection = nil
    end
end
BaseMotor.destroy = BaseMotor.stop

local SingleMotor = setmetatable({}, BaseMotor)
SingleMotor.__index = SingleMotor
function SingleMotor.new(initialValue, useImplicitConnections)
    local self = setmetatable(BaseMotor.new(), SingleMotor)
    self._useImplicitConnections = useImplicitConnections ~= nil and useImplicitConnections or true
    self._goal = nil
    self._state = { complete = true, value = initialValue }
    return self
end
function SingleMotor:step(dt)
    if self._state.complete then return true end
    local newState = self._goal:step(self._state, dt)
    self._state = newState
    self._onStep:fire(newState.value)
    if newState.complete then
        if self._useImplicitConnections then self:stop() end
        self._onComplete:fire()
    end
    return newState.complete
end
function SingleMotor:getValue() return self._state.value end
function SingleMotor:setGoal(goal)
    self._state.complete = false
    self._goal = goal
    self._onStart:fire()
    if self._useImplicitConnections then self:start() end
end

local GroupMotor = setmetatable({}, BaseMotor)
GroupMotor.__index = GroupMotor
function GroupMotor.new(initialValues, useImplicitConnections)
    local self = setmetatable(BaseMotor.new(), GroupMotor)
    self._useImplicitConnections = useImplicitConnections ~= nil and useImplicitConnections or true
    self._complete = true
    self._motors = {}
    for k, v in pairs(initialValues) do
        if typeof(v) == "number" then
            self._motors[k] = SingleMotor.new(v, false)
        end
    end
    return self
end
function GroupMotor:step(dt)
    if self._complete then return true end
    local allComplete = true
    for _, motor in pairs(self._motors) do
        if not motor:step(dt) then
            allComplete = false
        end
    end
    self._onStep:fire(self:getValue())
    if allComplete then
        if self._useImplicitConnections then self:stop() end
        self._complete = true
        self._onComplete:fire()
    end
    return allComplete
end
function GroupMotor:setGoal(goals)
    self._complete = false
    self._onStart:fire()
    for k, goal in pairs(goals) do
        if self._motors[k] then
            self._motors[k]:setGoal(goal)
        end
    end
    if self._useImplicitConnections then self:start() end
end
function GroupMotor:getValue()
    local values = {}
    for k, motor in pairs(self._motors) do
        values[k] = motor:getValue()
    end
    return values
end

local Flipper = {
    Signal = Signal,
    Spring = Spring,
    Instant = Instant,
    Linear = Linear,
    BaseMotor = BaseMotor,
    SingleMotor = SingleMotor,
    GroupMotor = GroupMotor
}

-- ============================================================================
-- Assets & Lucide Icons Dictionary (818 Icons)
-- ============================================================================
local Assets = {
    Close = "rbxassetid://9886659671",
    Min = "rbxassetid://9886659276",
    Max = "rbxassetid://9886659406",
    Restore = "rbxassetid://9886659001",
    Chevron = "rbxassetid://10709790948",
    Check = "rbxassetid://10709791437",
    Menu = "rbxassetid://10709762698",
    Circle = "rbxassetid://12266946128",
    Shadow = "rbxassetid://8992230677"
}

local LucideIcons = {
    ["accessibility"] = "rbxassetid://10709751939",
    ["activity"] = "rbxassetid://10709752035",
    ["air-vent"] = "rbxassetid://10709752131",
    ["airplay"] = "rbxassetid://10709752254",
    ["alarm-check"] = "rbxassetid://10709752405",
    ["alarm-clock"] = "rbxassetid://10709752630",
    ["alarm-clock-off"] = "rbxassetid://10709752508",
    ["alarm-minus"] = "rbxassetid://10709752732",
    ["alarm-plus"] = "rbxassetid://10709752825",
    ["album"] = "rbxassetid://10709752906",
    ["alert-circle"] = "rbxassetid://10709752996",
    ["alert-octagon"] = "rbxassetid://10709753064",
    ["alert-triangle"] = "rbxassetid://10709753149",
    ["align-center"] = "rbxassetid://10709753570",
    ["align-center-horizontal"] = "rbxassetid://10709753272",
    ["align-center-vertical"] = "rbxassetid://10709753421",
    ["align-end-horizontal"] = "rbxassetid://10709753692",
    ["align-end-vertical"] = "rbxassetid://10709753808",
    ["align-horizontal-distribute-center"] = "rbxassetid://10747779791",
    ["align-horizontal-distribute-end"] = "rbxassetid://10747784534",
    ["align-horizontal-distribute-start"] = "rbxassetid://10709754118",
    ["align-horizontal-justify-center"] = "rbxassetid://10709754204",
    ["align-horizontal-justify-end"] = "rbxassetid://10709754317",
    ["align-horizontal-justify-start"] = "rbxassetid://10709754436",
    ["align-horizontal-space-around"] = "rbxassetid://10709754590",
    ["align-horizontal-space-between"] = "rbxassetid://10709754749",
    ["align-justify"] = "rbxassetid://10709759610",
    ["align-left"] = "rbxassetid://10709759764",
    ["align-right"] = "rbxassetid://10709759895",
    ["align-start-horizontal"] = "rbxassetid://10709760051",
    ["align-start-vertical"] = "rbxassetid://10709760244",
    ["align-vertical-distribute-center"] = "rbxassetid://10709760351",
    ["align-vertical-distribute-end"] = "rbxassetid://10709760434",
    ["align-vertical-distribute-start"] = "rbxassetid://10709760612",
    ["align-vertical-justify-center"] = "rbxassetid://10709760814",
    ["align-vertical-justify-end"] = "rbxassetid://10709761003",
    ["align-vertical-justify-start"] = "rbxassetid://10709761176",
    ["align-vertical-space-around"] = "rbxassetid://10709761324",
    ["align-vertical-space-between"] = "rbxassetid://10709761434",
    ["anchor"] = "rbxassetid://10709761530",
    ["angry"] = "rbxassetid://10709761629",
    ["annoyed"] = "rbxassetid://10709761722",
    ["aperture"] = "rbxassetid://10709761813",
    ["apple"] = "rbxassetid://10709761889",
    ["archive"] = "rbxassetid://10709762233",
    ["archive-restore"] = "rbxassetid://10709762058",
    ["armchair"] = "rbxassetid://10709762327",
    ["arrow-big-down"] = "rbxassetid://10747796644",
    ["arrow-big-left"] = "rbxassetid://10709762574",
    ["arrow-big-right"] = "rbxassetid://10709762727",
    ["arrow-big-up"] = "rbxassetid://10709762879",
    ["arrow-down"] = "rbxassetid://10709767827",
    ["arrow-down-circle"] = "rbxassetid://10709763034",
    ["arrow-down-left"] = "rbxassetid://10709767656",
    ["arrow-down-right"] = "rbxassetid://10709767750",
    ["arrow-left"] = "rbxassetid://10709768114",
    ["arrow-left-circle"] = "rbxassetid://10709767936",
    ["arrow-left-right"] = "rbxassetid://10709768019",
    ["arrow-right"] = "rbxassetid://10709768347",
    ["arrow-right-circle"] = "rbxassetid://10709768226",
    ["arrow-up"] = "rbxassetid://10709768939",
    ["arrow-up-circle"] = "rbxassetid://10709768432",
    ["arrow-up-down"] = "rbxassetid://10709768538",
    ["arrow-up-left"] = "rbxassetid://10709768661",
    ["arrow-up-right"] = "rbxassetid://10709768787",
    ["asterisk"] = "rbxassetid://10709769095",
    ["at-sign"] = "rbxassetid://10709769286",
    ["award"] = "rbxassetid://10709769406",
    ["axe"] = "rbxassetid://10709769508",
    ["axis-3d"] = "rbxassetid://10709769598",
    ["baby"] = "rbxassetid://10709769732",
    ["backpack"] = "rbxassetid://10709769841",
    ["baggage-claim"] = "rbxassetid://10709769935",
    ["banana"] = "rbxassetid://10709770005",
    ["banknote"] = "rbxassetid://10709770178",
    ["bar-chart"] = "rbxassetid://10709773755",
    ["bar-chart-2"] = "rbxassetid://10709770317",
    ["bar-chart-3"] = "rbxassetid://10709770431",
    ["bar-chart-4"] = "rbxassetid://10709770560",
    ["bar-chart-horizontal"] = "rbxassetid://10709773669",
    ["barcode"] = "rbxassetid://10747360675",
    ["baseline"] = "rbxassetid://10709773863",
    ["bath"] = "rbxassetid://10709773963",
    ["battery"] = "rbxassetid://10709774640",
    ["battery-charging"] = "rbxassetid://10709774068",
    ["battery-full"] = "rbxassetid://10709774206",
    ["battery-low"] = "rbxassetid://10709774370",
    ["battery-medium"] = "rbxassetid://10709774513",
    ["beaker"] = "rbxassetid://10709774756",
    ["bed"] = "rbxassetid://10709775036",
    ["bed-double"] = "rbxassetid://10709774864",
    ["bed-single"] = "rbxassetid://10709774968",
    ["beer"] = "rbxassetid://10709775167",
    ["bell"] = "rbxassetid://10709775704",
    ["bell-minus"] = "rbxassetid://10709775241",
    ["bell-off"] = "rbxassetid://10709775320",
    ["bell-plus"] = "rbxassetid://10709775448",
    ["bell-ring"] = "rbxassetid://10709775560",
    ["bike"] = "rbxassetid://10709775894",
    ["binary"] = "rbxassetid://10709776050",
    ["bitcoin"] = "rbxassetid://10709776126",
    ["bluetooth"] = "rbxassetid://10709776655",
    ["bluetooth-connected"] = "rbxassetid://10709776240",
    ["bluetooth-off"] = "rbxassetid://10709776344",
    ["bluetooth-searching"] = "rbxassetid://10709776501",
    ["bold"] = "rbxassetid://10747813908",
    ["bomb"] = "rbxassetid://10709781460",
    ["bone"] = "rbxassetid://10709781605",
    ["book"] = "rbxassetid://10709781824",
    ["book-open"] = "rbxassetid://10709781717",
    ["bookmark"] = "rbxassetid://10709782154",
    ["bookmark-minus"] = "rbxassetid://10709781919",
    ["bookmark-plus"] = "rbxassetid://10709782044",
    ["bot"] = "rbxassetid://10709782230",
    ["box"] = "rbxassetid://10709782497",
    ["box-select"] = "rbxassetid://10709782342",
    ["boxes"] = "rbxassetid://10709782582",
    ["briefcase"] = "rbxassetid://10709782662",
    ["brush"] = "rbxassetid://10709782758",
    ["bug"] = "rbxassetid://10709782845",
    ["building"] = "rbxassetid://10709783051",
    ["building-2"] = "rbxassetid://10709782939",
    ["bus"] = "rbxassetid://10709783137",
    ["cake"] = "rbxassetid://10709783217",
    ["calculator"] = "rbxassetid://10709783311",
    ["calendar"] = "rbxassetid://10709789505",
    ["calendar-check"] = "rbxassetid://10709783474",
    ["calendar-check-2"] = "rbxassetid://10709783392",
    ["calendar-clock"] = "rbxassetid://10709783577",
    ["calendar-days"] = "rbxassetid://10709783673",
    ["calendar-heart"] = "rbxassetid://10709783835",
    ["calendar-minus"] = "rbxassetid://10709783959",
    ["calendar-off"] = "rbxassetid://10709788784",
    ["calendar-plus"] = "rbxassetid://10709788937",
    ["calendar-range"] = "rbxassetid://10709789053",
    ["calendar-search"] = "rbxassetid://10709789200",
    ["calendar-x"] = "rbxassetid://10709789407",
    ["calendar-x-2"] = "rbxassetid://10709789329",
    ["camera"] = "rbxassetid://10709789686",
    ["camera-off"] = "rbxassetid://10747822677",
    ["car"] = "rbxassetid://10709789810",
    ["carrot"] = "rbxassetid://10709789960",
    ["cast"] = "rbxassetid://10709790097",
    ["charge"] = "rbxassetid://10709790202",
    ["check"] = "rbxassetid://10709790644",
    ["check-circle"] = "rbxassetid://10709790387",
    ["check-circle-2"] = "rbxassetid://10709790298",
    ["check-square"] = "rbxassetid://10709790537",
    ["chef-hat"] = "rbxassetid://10709790757",
    ["cherry"] = "rbxassetid://10709790875",
    ["chevron-down"] = "rbxassetid://10709790948",
    ["chevron-first"] = "rbxassetid://10709791015",
    ["chevron-last"] = "rbxassetid://10709791130",
    ["chevron-left"] = "rbxassetid://10709791281",
    ["chevron-right"] = "rbxassetid://10709791437",
    ["chevron-up"] = "rbxassetid://10709791523",
    ["chevrons-down"] = "rbxassetid://10709796864",
    ["chevrons-down-up"] = "rbxassetid://10709791632",
    ["chevrons-left"] = "rbxassetid://10709797151",
    ["chevrons-left-right"] = "rbxassetid://10709797006",
    ["chevrons-right"] = "rbxassetid://10709797382",
    ["chevrons-right-left"] = "rbxassetid://10709797274",
    ["chevrons-up"] = "rbxassetid://10709797622",
    ["chevrons-up-down"] = "rbxassetid://10709797508",
    ["chrome"] = "rbxassetid://10709797725",
    ["circle"] = "rbxassetid://10709798174",
    ["circle-dot"] = "rbxassetid://10709797837",
    ["circle-ellipsis"] = "rbxassetid://10709797985",
    ["circle-slashed"] = "rbxassetid://10709798100",
    ["citrus"] = "rbxassetid://10709798276",
    ["clapperboard"] = "rbxassetid://10709798350",
    ["clipboard"] = "rbxassetid://10709799288",
    ["clipboard-check"] = "rbxassetid://10709798443",
    ["clipboard-copy"] = "rbxassetid://10709798574",
    ["clipboard-edit"] = "rbxassetid://10709798682",
    ["clipboard-list"] = "rbxassetid://10709798792",
    ["clipboard-signature"] = "rbxassetid://10709798890",
    ["clipboard-type"] = "rbxassetid://10709798999",
    ["clipboard-x"] = "rbxassetid://10709799124",
    ["clock"] = "rbxassetid://10709805144",
    ["clock-1"] = "rbxassetid://10709799535",
    ["clock-10"] = "rbxassetid://10709799718",
    ["clock-11"] = "rbxassetid://10709799818",
    ["clock-12"] = "rbxassetid://10709799962",
    ["clock-2"] = "rbxassetid://10709803876",
    ["clock-3"] = "rbxassetid://10709803989",
    ["clock-4"] = "rbxassetid://10709804164",
    ["clock-5"] = "rbxassetid://10709804291",
    ["clock-6"] = "rbxassetid://10709804435",
    ["clock-7"] = "rbxassetid://10709804599",
    ["clock-8"] = "rbxassetid://10709804784",
    ["clock-9"] = "rbxassetid://10709804996",
    ["cloud"] = "rbxassetid://10709806740",
    ["cloud-cog"] = "rbxassetid://10709805262",
    ["cloud-drizzle"] = "rbxassetid://10709805371",
    ["cloud-fog"] = "rbxassetid://10709805477",
    ["cloud-hail"] = "rbxassetid://10709805596",
    ["cloud-lightning"] = "rbxassetid://10709805727",
    ["cloud-moon"] = "rbxassetid://10709805942",
    ["cloud-moon-rain"] = "rbxassetid://10709805838",
    ["cloud-off"] = "rbxassetid://10709806060",
    ["cloud-rain"] = "rbxassetid://10709806277",
    ["cloud-rain-wind"] = "rbxassetid://10709806166",
    ["cloud-snow"] = "rbxassetid://10709806374",
    ["cloud-sun"] = "rbxassetid://10709806631",
    ["cloud-sun-rain"] = "rbxassetid://10709806475",
    ["cloudy"] = "rbxassetid://10709806859",
    ["clover"] = "rbxassetid://10709806995",
    ["code"] = "rbxassetid://10709810463",
    ["code-2"] = "rbxassetid://10709807111",
    ["codepen"] = "rbxassetid://10709810534",
    ["codesandbox"] = "rbxassetid://10709810676",
    ["coffee"] = "rbxassetid://10709810814",
    ["cog"] = "rbxassetid://10709810948",
    ["coins"] = "rbxassetid://10709811110",
    ["columns"] = "rbxassetid://10709811261",
    ["command"] = "rbxassetid://10709811365",
    ["compass"] = "rbxassetid://10709811445",
    ["component"] = "rbxassetid://10709811595",
    ["concierge-bell"] = "rbxassetid://10709811706",
    ["connection"] = "rbxassetid://10747361219",
    ["contact"] = "rbxassetid://10709811834",
    ["contrast"] = "rbxassetid://10709811939",
    ["cookie"] = "rbxassetid://10709812067",
    ["copy"] = "rbxassetid://10709812159",
    ["copyleft"] = "rbxassetid://10709812251",
    ["copyright"] = "rbxassetid://10709812311",
    ["corner-down-left"] = "rbxassetid://10709812396",
    ["corner-down-right"] = "rbxassetid://10709812485",
    ["corner-left-down"] = "rbxassetid://10709812632",
    ["corner-left-up"] = "rbxassetid://10709812784",
    ["corner-right-down"] = "rbxassetid://10709812939",
    ["corner-right-up"] = "rbxassetid://10709813094",
    ["corner-up-left"] = "rbxassetid://10709813185",
    ["corner-up-right"] = "rbxassetid://10709813281",
    ["cpu"] = "rbxassetid://10709813383",
    ["croissant"] = "rbxassetid://10709818125",
    ["crop"] = "rbxassetid://10709818245",
    ["cross"] = "rbxassetid://10709818399",
    ["crosshair"] = "rbxassetid://10709818534",
    ["crown"] = "rbxassetid://10709818626",
    ["cup-soda"] = "rbxassetid://10709818763",
    ["curly-braces"] = "rbxassetid://10709818847",
    ["currency"] = "rbxassetid://10709818931",
    ["database"] = "rbxassetid://10709818996",
    ["delete"] = "rbxassetid://10709819059",
    ["diamond"] = "rbxassetid://10709819149",
    ["dice-1"] = "rbxassetid://10709819266",
    ["dice-2"] = "rbxassetid://10709819361",
    ["dice-3"] = "rbxassetid://10709819508",
    ["dice-4"] = "rbxassetid://10709819670",
    ["dice-5"] = "rbxassetid://10709819801",
    ["dice-6"] = "rbxassetid://10709819896",
    ["dices"] = "rbxassetid://10723343321",
    ["diff"] = "rbxassetid://10723343416",
    ["disc"] = "rbxassetid://10723343537",
    ["divide"] = "rbxassetid://10723343805",
    ["divide-circle"] = "rbxassetid://10723343636",
    ["divide-square"] = "rbxassetid://10723343737",
    ["dollar-sign"] = "rbxassetid://10723343958",
    ["download"] = "rbxassetid://10723344270",
    ["download-cloud"] = "rbxassetid://10723344088",
    ["droplet"] = "rbxassetid://10723344432",
    ["droplets"] = "rbxassetid://10734883356",
    ["drumstick"] = "rbxassetid://10723344737",
    ["edit"] = "rbxassetid://10734883598",
    ["edit-2"] = "rbxassetid://10723344885",
    ["edit-3"] = "rbxassetid://10723345088",
    ["egg"] = "rbxassetid://10723345518",
    ["egg-fried"] = "rbxassetid://10723345347",
    ["electricity"] = "rbxassetid://10723345749",
    ["electricity-off"] = "rbxassetid://10723345643",
    ["equal"] = "rbxassetid://10723345990",
    ["equal-not"] = "rbxassetid://10723345866",
    ["eraser"] = "rbxassetid://10723346158",
    ["euro"] = "rbxassetid://10723346372",
    ["expand"] = "rbxassetid://10723346553",
    ["external-link"] = "rbxassetid://10723346684",
    ["eye"] = "rbxassetid://10723346959",
    ["eye-off"] = "rbxassetid://10723346871",
    ["factory"] = "rbxassetid://10723347051",
    ["fan"] = "rbxassetid://10723354359",
    ["fast-forward"] = "rbxassetid://10723354521",
    ["feather"] = "rbxassetid://10723354671",
    ["figma"] = "rbxassetid://10723354801",
    ["file"] = "rbxassetid://10723374641",
    ["file-archive"] = "rbxassetid://10723354921",
    ["file-audio"] = "rbxassetid://10723355148",
    ["file-audio-2"] = "rbxassetid://10723355026",
    ["file-axis-3d"] = "rbxassetid://10723355272",
    ["file-badge"] = "rbxassetid://10723355622",
    ["file-badge-2"] = "rbxassetid://10723355451",
    ["file-bar-chart"] = "rbxassetid://10723355887",
    ["file-bar-chart-2"] = "rbxassetid://10723355746",
    ["file-box"] = "rbxassetid://10723355989",
    ["file-check"] = "rbxassetid://10723356210",
    ["file-check-2"] = "rbxassetid://10723356100",
    ["file-clock"] = "rbxassetid://10723356329",
    ["file-code"] = "rbxassetid://10723356507",
    ["file-cog"] = "rbxassetid://10723356830",
    ["file-cog-2"] = "rbxassetid://10723356676",
    ["file-diff"] = "rbxassetid://10723357039",
    ["file-digit"] = "rbxassetid://10723357151",
    ["file-down"] = "rbxassetid://10723357322",
    ["file-edit"] = "rbxassetid://10723357495",
    ["file-heart"] = "rbxassetid://10723357637",
    ["file-image"] = "rbxassetid://10723357790",
    ["file-input"] = "rbxassetid://10723357933",
    ["file-json"] = "rbxassetid://10723364435",
    ["file-json-2"] = "rbxassetid://10723364361",
    ["file-key"] = "rbxassetid://10723364605",
    ["file-key-2"] = "rbxassetid://10723364515",
    ["file-line-chart"] = "rbxassetid://10723364725",
    ["file-lock"] = "rbxassetid://10723364957",
    ["file-lock-2"] = "rbxassetid://10723364861",
    ["file-minus"] = "rbxassetid://10723365254",
    ["file-minus-2"] = "rbxassetid://10723365086",
    ["file-output"] = "rbxassetid://10723365457",
    ["file-pie-chart"] = "rbxassetid://10723365598",
    ["file-plus"] = "rbxassetid://10723365877",
    ["file-plus-2"] = "rbxassetid://10723365766",
    ["file-question"] = "rbxassetid://10723365987",
    ["file-scan"] = "rbxassetid://10723366167",
    ["file-search"] = "rbxassetid://10723366550",
    ["file-search-2"] = "rbxassetid://10723366340",
    ["file-signature"] = "rbxassetid://10723366741",
    ["file-spreadsheet"] = "rbxassetid://10723366962",
    ["file-symlink"] = "rbxassetid://10723367098",
    ["file-terminal"] = "rbxassetid://10723367244",
    ["file-text"] = "rbxassetid://10723367380",
    ["file-type"] = "rbxassetid://10723367606",
    ["file-type-2"] = "rbxassetid://10723367509",
    ["file-up"] = "rbxassetid://10723367734",
    ["file-video"] = "rbxassetid://10723373884",
    ["file-video-2"] = "rbxassetid://10723367834",
    ["file-volume"] = "rbxassetid://10723374172",
    ["file-volume-2"] = "rbxassetid://10723374030",
    ["file-warning"] = "rbxassetid://10723374276",
    ["file-x"] = "rbxassetid://10723374544",
    ["file-x-2"] = "rbxassetid://10723374378",
    ["files"] = "rbxassetid://10723374759",
    ["film"] = "rbxassetid://10723374981",
    ["filter"] = "rbxassetid://10723375128",
    ["fingerprint"] = "rbxassetid://10723375250",
    ["flag"] = "rbxassetid://10723375890",
    ["flag-off"] = "rbxassetid://10723375443",
    ["flag-triangle-left"] = "rbxassetid://10723375608",
    ["flag-triangle-right"] = "rbxassetid://10723375727",
    ["flame"] = "rbxassetid://10723376114",
    ["flashlight"] = "rbxassetid://10723376471",
    ["flashlight-off"] = "rbxassetid://10723376365",
    ["flask-conical"] = "rbxassetid://10734883986",
    ["flask-round"] = "rbxassetid://10723376614",
    ["flip-horizontal"] = "rbxassetid://10723376884",
    ["flip-horizontal-2"] = "rbxassetid://10723376745",
    ["flip-vertical"] = "rbxassetid://10723377138",
    ["flip-vertical-2"] = "rbxassetid://10723377026",
    ["flower"] = "rbxassetid://10747830374",
    ["flower-2"] = "rbxassetid://10723377305",
    ["focus"] = "rbxassetid://10723377537",
    ["folder"] = "rbxassetid://10723387563",
    ["folder-archive"] = "rbxassetid://10723384478",
    ["folder-check"] = "rbxassetid://10723384605",
    ["folder-clock"] = "rbxassetid://10723384731",
    ["folder-closed"] = "rbxassetid://10723384893",
    ["folder-cog"] = "rbxassetid://10723385213",
    ["folder-cog-2"] = "rbxassetid://10723385036",
    ["folder-down"] = "rbxassetid://10723385338",
    ["folder-edit"] = "rbxassetid://10723385445",
    ["folder-heart"] = "rbxassetid://10723385545",
    ["folder-input"] = "rbxassetid://10723385721",
    ["folder-key"] = "rbxassetid://10723385848",
    ["folder-lock"] = "rbxassetid://10723386005",
    ["folder-minus"] = "rbxassetid://10723386127",
    ["folder-open"] = "rbxassetid://10723386277",
    ["folder-output"] = "rbxassetid://10723386386",
    ["folder-plus"] = "rbxassetid://10723386531",
    ["folder-search"] = "rbxassetid://10723386787",
    ["folder-search-2"] = "rbxassetid://10723386674",
    ["folder-symlink"] = "rbxassetid://10723386930",
    ["folder-tree"] = "rbxassetid://10723387085",
    ["folder-up"] = "rbxassetid://10723387265",
    ["folder-x"] = "rbxassetid://10723387448",
    ["folders"] = "rbxassetid://10723387721",
    ["form-input"] = "rbxassetid://10723387841",
    ["forward"] = "rbxassetid://10723388016",
    ["frame"] = "rbxassetid://10723394389",
    ["framer"] = "rbxassetid://10723394565",
    ["frown"] = "rbxassetid://10723394681",
    ["fuel"] = "rbxassetid://10723394846",
    ["function-square"] = "rbxassetid://10723395041",
    ["gamepad"] = "rbxassetid://10723395457",
    ["gamepad-2"] = "rbxassetid://10723395215",
    ["gauge"] = "rbxassetid://10723395708",
    ["gavel"] = "rbxassetid://10723395896",
    ["gem"] = "rbxassetid://10723396000",
    ["ghost"] = "rbxassetid://10723396107",
    ["gift"] = "rbxassetid://10723396402",
    ["gift-card"] = "rbxassetid://10723396225",
    ["git-branch"] = "rbxassetid://10723396676",
    ["git-branch-plus"] = "rbxassetid://10723396542",
    ["git-commit"] = "rbxassetid://10723396812",
    ["git-compare"] = "rbxassetid://10723396954",
    ["git-fork"] = "rbxassetid://10723397049",
    ["git-merge"] = "rbxassetid://10723397165",
    ["git-pull-request"] = "rbxassetid://10723397431",
    ["git-pull-request-closed"] = "rbxassetid://10723397268",
    ["git-pull-request-draft"] = "rbxassetid://10734884302",
    ["glass"] = "rbxassetid://10723397788",
    ["glass-2"] = "rbxassetid://10723397529",
    ["glass-water"] = "rbxassetid://10723397678",
    ["glasses"] = "rbxassetid://10723397895",
    ["globe"] = "rbxassetid://10723404337",
    ["globe-2"] = "rbxassetid://10723398002",
    ["grab"] = "rbxassetid://10723404472",
    ["graduation-cap"] = "rbxassetid://10723404691",
    ["grape"] = "rbxassetid://10723404822",
    ["grid"] = "rbxassetid://10723404936",
    ["grip-horizontal"] = "rbxassetid://10723405089",
    ["grip-vertical"] = "rbxassetid://10723405236",
    ["hammer"] = "rbxassetid://10723405360",
    ["hand"] = "rbxassetid://10723405649",
    ["hand-metal"] = "rbxassetid://10723405508",
    ["hard-drive"] = "rbxassetid://10723405749",
    ["hard-hat"] = "rbxassetid://10723405859",
    ["hash"] = "rbxassetid://10723405975",
    ["haze"] = "rbxassetid://10723406078",
    ["headphones"] = "rbxassetid://10723406165",
    ["heart"] = "rbxassetid://10723406885",
    ["heart-crack"] = "rbxassetid://10723406299",
    ["heart-handshake"] = "rbxassetid://10723406480",
    ["heart-off"] = "rbxassetid://10723406662",
    ["heart-pulse"] = "rbxassetid://10723406795",
    ["help-circle"] = "rbxassetid://10723406988",
    ["hexagon"] = "rbxassetid://10723407092",
    ["highlighter"] = "rbxassetid://10723407192",
    ["history"] = "rbxassetid://10723407335",
    ["home"] = "rbxassetid://10723407389",
    ["hourglass"] = "rbxassetid://10723407498",
    ["ice-cream"] = "rbxassetid://10723414308",
    ["image"] = "rbxassetid://10723415040",
    ["image-minus"] = "rbxassetid://10723414487",
    ["image-off"] = "rbxassetid://10723414677",
    ["image-plus"] = "rbxassetid://10723414827",
    ["import"] = "rbxassetid://10723415205",
    ["inbox"] = "rbxassetid://10723415335",
    ["indent"] = "rbxassetid://10723415494",
    ["indian-rupee"] = "rbxassetid://10723415642",
    ["infinity"] = "rbxassetid://10723415766",
    ["info"] = "rbxassetid://10723415903",
    ["inspect"] = "rbxassetid://10723416057",
    ["italic"] = "rbxassetid://10723416195",
    ["japanese-yen"] = "rbxassetid://10723416363",
    ["joystick"] = "rbxassetid://10723416527",
    ["key"] = "rbxassetid://10723416652",
    ["keyboard"] = "rbxassetid://10723416765",
    ["lamp"] = "rbxassetid://10723417513",
    ["lamp-ceiling"] = "rbxassetid://10723416922",
    ["lamp-desk"] = "rbxassetid://10723417016",
    ["lamp-floor"] = "rbxassetid://10723417131",
    ["lamp-wall-down"] = "rbxassetid://10723417240",
    ["lamp-wall-up"] = "rbxassetid://10723417356",
    ["landmark"] = "rbxassetid://10723417608",
    ["languages"] = "rbxassetid://10723417703",
    ["laptop"] = "rbxassetid://10723423881",
    ["laptop-2"] = "rbxassetid://10723417797",
    ["lasso"] = "rbxassetid://10723424235",
    ["lasso-select"] = "rbxassetid://10723424058",
    ["laugh"] = "rbxassetid://10723424372",
    ["layers"] = "rbxassetid://10723424505",
    ["layout"] = "rbxassetid://10723425376",
    ["layout-dashboard"] = "rbxassetid://10723424646",
    ["layout-grid"] = "rbxassetid://10723424838",
    ["layout-list"] = "rbxassetid://10723424963",
    ["layout-template"] = "rbxassetid://10723425187",
    ["leaf"] = "rbxassetid://10723425539",
    ["library"] = "rbxassetid://10723425615",
    ["life-buoy"] = "rbxassetid://10723425685",
    ["lightbulb"] = "rbxassetid://10723425852",
    ["lightbulb-off"] = "rbxassetid://10723425762",
    ["line-chart"] = "rbxassetid://10723426393",
    ["link"] = "rbxassetid://10723426722",
    ["link-2"] = "rbxassetid://10723426595",
    ["link-2-off"] = "rbxassetid://10723426513",
    ["list"] = "rbxassetid://10723433811",
    ["list-checks"] = "rbxassetid://10734884548",
    ["list-end"] = "rbxassetid://10723426886",
    ["list-minus"] = "rbxassetid://10723426986",
    ["list-music"] = "rbxassetid://10723427081",
    ["list-ordered"] = "rbxassetid://10723427199",
    ["list-plus"] = "rbxassetid://10723427334",
    ["list-start"] = "rbxassetid://10723427494",
    ["list-video"] = "rbxassetid://10723427619",
    ["list-x"] = "rbxassetid://10723433655",
    ["loader"] = "rbxassetid://10723434070",
    ["loader-2"] = "rbxassetid://10723433935",
    ["locate"] = "rbxassetid://10723434557",
    ["locate-fixed"] = "rbxassetid://10723434236",
    ["locate-off"] = "rbxassetid://10723434379",
    ["lock"] = "rbxassetid://10723434711",
    ["log-in"] = "rbxassetid://10723434830",
    ["log-out"] = "rbxassetid://10723434906",
    ["luggage"] = "rbxassetid://10723434993",
    ["magnet"] = "rbxassetid://10723435069",
    ["mail"] = "rbxassetid://10734885430",
    ["mail-check"] = "rbxassetid://10723435182",
    ["mail-minus"] = "rbxassetid://10723435261",
    ["mail-open"] = "rbxassetid://10723435342",
    ["mail-plus"] = "rbxassetid://10723435443",
    ["mail-question"] = "rbxassetid://10723435515",
    ["mail-search"] = "rbxassetid://10734884739",
    ["mail-warning"] = "rbxassetid://10734885015",
    ["mail-x"] = "rbxassetid://10734885247",
    ["mails"] = "rbxassetid://10734885614",
    ["map"] = "rbxassetid://10734886202",
    ["map-pin"] = "rbxassetid://10734886004",
    ["map-pin-off"] = "rbxassetid://10734885803",
    ["maximize"] = "rbxassetid://10734886735",
    ["maximize-2"] = "rbxassetid://10734886496",
    ["medal"] = "rbxassetid://10734887072",
    ["megaphone"] = "rbxassetid://10734887454",
    ["megaphone-off"] = "rbxassetid://10734887311",
    ["meh"] = "rbxassetid://10734887603",
    ["menu"] = "rbxassetid://10734887784",
    ["message-circle"] = "rbxassetid://10734888000",
    ["message-square"] = "rbxassetid://10734888228",
    ["mic"] = "rbxassetid://10734888864",
    ["mic-2"] = "rbxassetid://10734888430",
    ["mic-off"] = "rbxassetid://10734888646",
    ["microscope"] = "rbxassetid://10734889106",
    ["microwave"] = "rbxassetid://10734895076",
    ["milestone"] = "rbxassetid://10734895310",
    ["minimize"] = "rbxassetid://10734895698",
    ["minimize-2"] = "rbxassetid://10734895530",
    ["minus"] = "rbxassetid://10734896206",
    ["minus-circle"] = "rbxassetid://10734895856",
    ["minus-square"] = "rbxassetid://10734896029",
    ["monitor"] = "rbxassetid://10734896881",
    ["monitor-off"] = "rbxassetid://10734896360",
    ["monitor-speaker"] = "rbxassetid://10734896512",
    ["moon"] = "rbxassetid://10734897102",
    ["more-horizontal"] = "rbxassetid://10734897250",
    ["more-vertical"] = "rbxassetid://10734897387",
    ["mountain"] = "rbxassetid://10734897956",
    ["mountain-snow"] = "rbxassetid://10734897665",
    ["mouse"] = "rbxassetid://10734898592",
    ["mouse-pointer"] = "rbxassetid://10734898476",
    ["mouse-pointer-2"] = "rbxassetid://10734898194",
    ["mouse-pointer-click"] = "rbxassetid://10734898355",
    ["move"] = "rbxassetid://10734900011",
    ["move-3d"] = "rbxassetid://10734898756",
    ["move-diagonal"] = "rbxassetid://10734899164",
    ["move-diagonal-2"] = "rbxassetid://10734898934",
    ["move-horizontal"] = "rbxassetid://10734899414",
    ["move-vertical"] = "rbxassetid://10734899821",
    ["music"] = "rbxassetid://10734905958",
    ["music-2"] = "rbxassetid://10734900215",
    ["music-3"] = "rbxassetid://10734905665",
    ["music-4"] = "rbxassetid://10734905823",
    ["navigation"] = "rbxassetid://10734906744",
    ["navigation-2"] = "rbxassetid://10734906332",
    ["navigation-2-off"] = "rbxassetid://10734906144",
    ["navigation-off"] = "rbxassetid://10734906580",
    ["network"] = "rbxassetid://10734906975",
    ["newspaper"] = "rbxassetid://10734907168",
    ["octagon"] = "rbxassetid://10734907361",
    ["option"] = "rbxassetid://10734907649",
    ["outdent"] = "rbxassetid://10734907933",
    ["package"] = "rbxassetid://10734909540",
    ["package-2"] = "rbxassetid://10734908151",
    ["package-check"] = "rbxassetid://10734908384",
    ["package-minus"] = "rbxassetid://10734908626",
    ["package-open"] = "rbxassetid://10734908793",
    ["package-plus"] = "rbxassetid://10734909016",
    ["package-search"] = "rbxassetid://10734909196",
    ["package-x"] = "rbxassetid://10734909375",
    ["paint-bucket"] = "rbxassetid://10734909847",
    ["paintbrush"] = "rbxassetid://10734910187",
    ["paintbrush-2"] = "rbxassetid://10734910030",
    ["palette"] = "rbxassetid://10734910430",
    ["palmtree"] = "rbxassetid://10734910680",
    ["paperclip"] = "rbxassetid://10734910927",
    ["party-popper"] = "rbxassetid://10734918735",
    ["pause"] = "rbxassetid://10734919336",
    ["pause-circle"] = "rbxassetid://10735024209",
    ["pause-octagon"] = "rbxassetid://10734919143",
    ["pen-tool"] = "rbxassetid://10734919503",
    ["pencil"] = "rbxassetid://10734919691",
    ["percent"] = "rbxassetid://10734919919",
    ["person-standing"] = "rbxassetid://10734920149",
    ["phone"] = "rbxassetid://10734921524",
    ["phone-call"] = "rbxassetid://10734920305",
    ["phone-forwarded"] = "rbxassetid://10734920508",
    ["phone-incoming"] = "rbxassetid://10734920694",
    ["phone-missed"] = "rbxassetid://10734920845",
    ["phone-off"] = "rbxassetid://10734921077",
    ["phone-outgoing"] = "rbxassetid://10734921288",
    ["pie-chart"] = "rbxassetid://10734921727",
    ["piggy-bank"] = "rbxassetid://10734921935",
    ["pin"] = "rbxassetid://10734922324",
    ["pin-off"] = "rbxassetid://10734922180",
    ["pipette"] = "rbxassetid://10734922497",
    ["pizza"] = "rbxassetid://10734922774",
    ["plane"] = "rbxassetid://10734922971",
    ["play"] = "rbxassetid://10734923549",
    ["play-circle"] = "rbxassetid://10734923214",
    ["plus"] = "rbxassetid://10734924532",
    ["plus-circle"] = "rbxassetid://10734923868",
    ["plus-square"] = "rbxassetid://10734924219",
    ["podcast"] = "rbxassetid://10734929553",
    ["pointer"] = "rbxassetid://10734929723",
    ["pound-sterling"] = "rbxassetid://10734929981",
    ["power"] = "rbxassetid://10734930466",
    ["power-off"] = "rbxassetid://10734930257",
    ["printer"] = "rbxassetid://10734930632",
    ["puzzle"] = "rbxassetid://10734930886",
    ["quote"] = "rbxassetid://10734931234",
    ["radio"] = "rbxassetid://10734931596",
    ["radio-receiver"] = "rbxassetid://10734931402",
    ["rectangle-horizontal"] = "rbxassetid://10734931777",
    ["rectangle-vertical"] = "rbxassetid://10734932081",
    ["recycle"] = "rbxassetid://10734932295",
    ["redo"] = "rbxassetid://10734932822",
    ["redo-2"] = "rbxassetid://10734932586",
    ["refresh-ccw"] = "rbxassetid://10734933056",
    ["refresh-cw"] = "rbxassetid://10734933222",
    ["refrigerator"] = "rbxassetid://10734933465",
    ["regex"] = "rbxassetid://10734933655",
    ["repeat"] = "rbxassetid://10734933966",
    ["repeat-1"] = "rbxassetid://10734933826",
    ["reply"] = "rbxassetid://10734934252",
    ["reply-all"] = "rbxassetid://10734934132",
    ["rewind"] = "rbxassetid://10734934347",
    ["rocket"] = "rbxassetid://10734934585",
    ["rocking-chair"] = "rbxassetid://10734939942",
    ["rotate-3d"] = "rbxassetid://10734940107",
    ["rotate-ccw"] = "rbxassetid://10734940376",
    ["rotate-cw"] = "rbxassetid://10734940654",
    ["rss"] = "rbxassetid://10734940825",
    ["ruler"] = "rbxassetid://10734941018",
    ["russian-ruble"] = "rbxassetid://10734941199",
    ["sailboat"] = "rbxassetid://10734941354",
    ["save"] = "rbxassetid://10734941499",
    ["scale"] = "rbxassetid://10734941912",
    ["scale-3d"] = "rbxassetid://10734941739",
    ["scaling"] = "rbxassetid://10734942072",
    ["scan"] = "rbxassetid://10734942565",
    ["scan-face"] = "rbxassetid://10734942198",
    ["scan-line"] = "rbxassetid://10734942351",
    ["scissors"] = "rbxassetid://10734942778",
    ["screen-share"] = "rbxassetid://10734943193",
    ["screen-share-off"] = "rbxassetid://10734942967",
    ["scroll"] = "rbxassetid://10734943448",
    ["search"] = "rbxassetid://10734943674",
    ["send"] = "rbxassetid://10734943902",
    ["separator-horizontal"] = "rbxassetid://10734944115",
    ["separator-vertical"] = "rbxassetid://10734944326",
    ["server"] = "rbxassetid://10734949856",
    ["server-cog"] = "rbxassetid://10734944444",
    ["server-crash"] = "rbxassetid://10734944554",
    ["server-off"] = "rbxassetid://10734944668",
    ["settings"] = "rbxassetid://10734950309",
    ["settings-2"] = "rbxassetid://10734950020",
    ["share"] = "rbxassetid://10734950813",
    ["share-2"] = "rbxassetid://10734950553",
    ["sheet"] = "rbxassetid://10734951038",
    ["shield"] = "rbxassetid://10734951847",
    ["shield-alert"] = "rbxassetid://10734951173",
    ["shield-check"] = "rbxassetid://10734951367",
    ["shield-close"] = "rbxassetid://10734951535",
    ["shield-off"] = "rbxassetid://10734951684",
    ["shirt"] = "rbxassetid://10734952036",
    ["shopping-bag"] = "rbxassetid://10734952273",
    ["shopping-cart"] = "rbxassetid://10734952479",
    ["shovel"] = "rbxassetid://10734952773",
    ["shower-head"] = "rbxassetid://10734952942",
    ["shrink"] = "rbxassetid://10734953073",
    ["shrub"] = "rbxassetid://10734953241",
    ["shuffle"] = "rbxassetid://10734953451",
    ["sidebar"] = "rbxassetid://10734954301",
    ["sidebar-close"] = "rbxassetid://10734953715",
    ["sidebar-open"] = "rbxassetid://10734954000",
    ["sigma"] = "rbxassetid://10734954538",
    ["signal"] = "rbxassetid://10734961133",
    ["signal-high"] = "rbxassetid://10734954807",
    ["signal-low"] = "rbxassetid://10734955080",
    ["signal-medium"] = "rbxassetid://10734955336",
    ["signal-zero"] = "rbxassetid://10734960878",
    ["siren"] = "rbxassetid://10734961284",
    ["skip-back"] = "rbxassetid://10734961526",
    ["skip-forward"] = "rbxassetid://10734961809",
    ["skull"] = "rbxassetid://10734962068",
    ["slack"] = "rbxassetid://10734962339",
    ["slash"] = "rbxassetid://10734962600",
    ["slice"] = "rbxassetid://10734963024",
    ["sliders"] = "rbxassetid://10734963400",
    ["sliders-horizontal"] = "rbxassetid://10734963191",
    ["smartphone"] = "rbxassetid://10734963940",
    ["smartphone-charging"] = "rbxassetid://10734963671",
    ["smile"] = "rbxassetid://10734964441",
    ["smile-plus"] = "rbxassetid://10734964188",
    ["snowflake"] = "rbxassetid://10734964600",
    ["sofa"] = "rbxassetid://10734964852",
    ["sort-asc"] = "rbxassetid://10734965115",
    ["sort-desc"] = "rbxassetid://10734965287",
    ["speaker"] = "rbxassetid://10734965419",
    ["sprout"] = "rbxassetid://10734965572",
    ["square"] = "rbxassetid://10734965702",
    ["star"] = "rbxassetid://10734966248",
    ["star-half"] = "rbxassetid://10734965897",
    ["star-off"] = "rbxassetid://10734966097",
    ["stethoscope"] = "rbxassetid://10734966384",
    ["sticker"] = "rbxassetid://10734972234",
    ["sticky-note"] = "rbxassetid://10734972463",
    ["stop-circle"] = "rbxassetid://10734972621",
    ["stretch-horizontal"] = "rbxassetid://10734972862",
    ["stretch-vertical"] = "rbxassetid://10734973130",
    ["strikethrough"] = "rbxassetid://10734973290",
    ["subscript"] = "rbxassetid://10734973457",
    ["sun"] = "rbxassetid://10734974297",
    ["sun-dim"] = "rbxassetid://10734973645",
    ["sun-medium"] = "rbxassetid://10734973778",
    ["sun-moon"] = "rbxassetid://10734973999",
    ["sun-snow"] = "rbxassetid://10734974130",
    ["sunrise"] = "rbxassetid://10734974522",
    ["sunset"] = "rbxassetid://10734974689",
    ["superscript"] = "rbxassetid://10734974850",
    ["swiss-franc"] = "rbxassetid://10734975024",
    ["switch-camera"] = "rbxassetid://10734975214",
    ["sword"] = "rbxassetid://10734975486",
    ["swords"] = "rbxassetid://10734975692",
    ["syringe"] = "rbxassetid://10734975932",
    ["table"] = "rbxassetid://10734976230",
    ["table-2"] = "rbxassetid://10734976097",
    ["tablet"] = "rbxassetid://10734976394",
    ["tag"] = "rbxassetid://10734976528",
    ["tags"] = "rbxassetid://10734976739",
    ["target"] = "rbxassetid://10734977012",
    ["tent"] = "rbxassetid://10734981750",
    ["terminal"] = "rbxassetid://10734982144",
    ["terminal-square"] = "rbxassetid://10734981995",
    ["text-cursor"] = "rbxassetid://10734982395",
    ["text-cursor-input"] = "rbxassetid://10734982297",
    ["thermometer"] = "rbxassetid://10734983134",
    ["thermometer-snowflake"] = "rbxassetid://10734982571",
    ["thermometer-sun"] = "rbxassetid://10734982771",
    ["thumbs-down"] = "rbxassetid://10734983359",
    ["thumbs-up"] = "rbxassetid://10734983629",
    ["ticket"] = "rbxassetid://10734983868",
    ["timer"] = "rbxassetid://10734984606",
    ["timer-off"] = "rbxassetid://10734984138",
    ["timer-reset"] = "rbxassetid://10734984355",
    ["toggle-left"] = "rbxassetid://10734984834",
    ["toggle-right"] = "rbxassetid://10734985040",
    ["tornado"] = "rbxassetid://10734985247",
    ["toy-brick"] = "rbxassetid://10747361919",
    ["train"] = "rbxassetid://10747362105",
    ["trash"] = "rbxassetid://10747362393",
    ["trash-2"] = "rbxassetid://10747362241",
    ["tree-deciduous"] = "rbxassetid://10747362534",
    ["tree-pine"] = "rbxassetid://10747362748",
    ["trees"] = "rbxassetid://10747363016",
    ["trending-down"] = "rbxassetid://10747363205",
    ["trending-up"] = "rbxassetid://10747363465",
    ["triangle"] = "rbxassetid://10747363621",
    ["trophy"] = "rbxassetid://10747363809",
    ["truck"] = "rbxassetid://10747364031",
    ["tv"] = "rbxassetid://10747364593",
    ["tv-2"] = "rbxassetid://10747364302",
    ["type"] = "rbxassetid://10747364761",
    ["umbrella"] = "rbxassetid://10747364971",
    ["underline"] = "rbxassetid://10747365191",
    ["undo"] = "rbxassetid://10747365484",
    ["undo-2"] = "rbxassetid://10747365359",
    ["unlink"] = "rbxassetid://10747365771",
    ["unlink-2"] = "rbxassetid://10747397871",
    ["unlock"] = "rbxassetid://10747366027",
    ["upload"] = "rbxassetid://10747366434",
    ["upload-cloud"] = "rbxassetid://10747366266",
    ["usb"] = "rbxassetid://10747366606",
    ["user"] = "rbxassetid://10747373176",
    ["user-check"] = "rbxassetid://10747371901",
    ["user-cog"] = "rbxassetid://10747372167",
    ["user-minus"] = "rbxassetid://10747372346",
    ["user-plus"] = "rbxassetid://10747372702",
    ["user-x"] = "rbxassetid://10747372992",
    ["users"] = "rbxassetid://10747373426",
    ["utensils"] = "rbxassetid://10747373821",
    ["utensils-crossed"] = "rbxassetid://10747373629",
    ["venetian-mask"] = "rbxassetid://10747374003",
    ["verified"] = "rbxassetid://10747374131",
    ["vibrate"] = "rbxassetid://10747374489",
    ["vibrate-off"] = "rbxassetid://10747374269",
    ["video"] = "rbxassetid://10747374938",
    ["video-off"] = "rbxassetid://10747374721",
    ["view"] = "rbxassetid://10747375132",
    ["voicemail"] = "rbxassetid://10747375281",
    ["volume"] = "rbxassetid://10747376008",
    ["volume-1"] = "rbxassetid://10747375450",
    ["volume-2"] = "rbxassetid://10747375679",
    ["volume-x"] = "rbxassetid://10747375880",
    ["wallet"] = "rbxassetid://10747376205",
    ["wand"] = "rbxassetid://10747376565",
    ["wand-2"] = "rbxassetid://10747376349",
    ["watch"] = "rbxassetid://10747376722",
    ["waves"] = "rbxassetid://10747376931",
    ["webcam"] = "rbxassetid://10747381992",
    ["wifi"] = "rbxassetid://10747382504",
    ["wifi-off"] = "rbxassetid://10747382268",
    ["wind"] = "rbxassetid://10747382750",
    ["wrap-text"] = "rbxassetid://10747383065",
    ["wrench"] = "rbxassetid://10747383470",
    ["x"] = "rbxassetid://10747384394",
    ["x-circle"] = "rbxassetid://10747383819",
    ["x-octagon"] = "rbxassetid://10747384037",
    ["x-square"] = "rbxassetid://10747384217",
    ["zoom-in"] = "rbxassetid://10747384552",
    ["zoom-out"] = "rbxassetid://10747384679",
}

-- ============================================================================
-- Fluent Library Root & Theme Engine
-- ============================================================================
local Fluent = {
    Version = "1.2.0-Mobile",
    OpenFrames = {},
    Options = {},
    Themes = {},
    Theme = "Dark",
    Window = nil,
    WindowFrame = nil,
    Unloaded = false,
    DialogOpen = false,
    UseAcrylic = false,
    Acrylic = false,
    Transparency = true,
    MinimizeKeybind = nil,
    MinimizeKey = Enum.KeyCode.LeftControl,
    GUI = nil
}

Fluent.Themes.Dark = {
    Name = "Dark",
    Accent = Color3.fromRGB(96, 205, 255),
    AcrylicMain = Color3.fromRGB(36, 36, 40),
    AcrylicBorder = Color3.fromRGB(75, 75, 85),
    AcrylicGradient = ColorSequence.new(Color3.fromRGB(40, 40, 45), Color3.fromRGB(28, 28, 32)),
    AcrylicNoise = 0.9,
    TitleBarLine = Color3.fromRGB(65, 65, 75),
    Tab = Color3.fromRGB(120, 120, 120),
    Element = Color3.fromRGB(50, 50, 56),
    ElementBorder = Color3.fromRGB(60, 60, 70),
    InElementBorder = Color3.fromRGB(80, 80, 95),
    ElementTransparency = 0.45,
    ToggleSlider = Color3.fromRGB(120, 120, 130),
    ToggleToggled = Color3.fromRGB(20, 20, 24),
    SliderRail = Color3.fromRGB(70, 70, 80),
    DropdownFrame = Color3.fromRGB(50, 50, 58),
    DropdownHolder = Color3.fromRGB(32, 32, 38),
    DropdownBorder = Color3.fromRGB(70, 70, 85),
    DropdownOption = Color3.fromRGB(55, 55, 65),
    Keybind = Color3.fromRGB(50, 50, 60),
    Input = Color3.fromRGB(50, 50, 60),
    InputFocused = Color3.fromRGB(25, 25, 30),
    InputIndicator = Color3.fromRGB(150, 150, 160),
    Dialog = Color3.fromRGB(38, 38, 44),
    DialogHolder = Color3.fromRGB(30, 30, 35),
    DialogHolderLine = Color3.fromRGB(50, 50, 60),
    DialogButton = Color3.fromRGB(50, 50, 60),
    DialogButtonBorder = Color3.fromRGB(80, 80, 95),
    DialogBorder = Color3.fromRGB(75, 75, 90),
    DialogInput = Color3.fromRGB(45, 45, 52),
    DialogInputLine = Color3.fromRGB(140, 140, 155),
    Text = Color3.fromRGB(245, 245, 248),
    SubText = Color3.fromRGB(175, 175, 185),
    Hover = Color3.fromRGB(70, 70, 80),
    HoverChange = 0.08
}

Fluent.Themes.Darker = {
    Name = "Darker",
    Accent = Color3.fromRGB(72, 138, 182),
    AcrylicMain = Color3.fromRGB(22, 22, 26),
    AcrylicBorder = Color3.fromRGB(50, 50, 60),
    AcrylicGradient = ColorSequence.new(Color3.fromRGB(25, 25, 30), Color3.fromRGB(15, 15, 18)),
    AcrylicNoise = 0.94,
    TitleBarLine = Color3.fromRGB(45, 45, 55),
    Tab = Color3.fromRGB(100, 100, 110),
    Element = Color3.fromRGB(35, 35, 42),
    ElementBorder = Color3.fromRGB(45, 45, 55),
    InElementBorder = Color3.fromRGB(60, 60, 75),
    ElementTransparency = 0.35,
    ToggleSlider = Color3.fromRGB(100, 100, 115),
    ToggleToggled = Color3.fromRGB(15, 15, 18),
    SliderRail = Color3.fromRGB(55, 55, 65),
    DropdownFrame = Color3.fromRGB(38, 38, 46),
    DropdownHolder = Color3.fromRGB(24, 24, 28),
    DropdownBorder = Color3.fromRGB(50, 50, 60),
    DropdownOption = Color3.fromRGB(40, 40, 50),
    Keybind = Color3.fromRGB(38, 38, 46),
    Input = Color3.fromRGB(38, 38, 46),
    InputFocused = Color3.fromRGB(18, 18, 22),
    InputIndicator = Color3.fromRGB(120, 120, 135),
    Dialog = Color3.fromRGB(26, 26, 32),
    DialogHolder = Color3.fromRGB(20, 20, 24),
    DialogHolderLine = Color3.fromRGB(35, 35, 42),
    DialogButton = Color3.fromRGB(38, 38, 48),
    DialogButtonBorder = Color3.fromRGB(60, 60, 75),
    DialogBorder = Color3.fromRGB(55, 55, 70),
    DialogInput = Color3.fromRGB(32, 32, 40),
    DialogInputLine = Color3.fromRGB(100, 100, 120),
    Text = Color3.fromRGB(240, 240, 245),
    SubText = Color3.fromRGB(160, 160, 175),
    Hover = Color3.fromRGB(50, 50, 60),
    HoverChange = 0.08
}

Fluent.Themes.Light = {
    Name = "Light",
    Accent = Color3.fromRGB(0, 103, 192),
    AcrylicMain = Color3.fromRGB(240, 240, 245),
    AcrylicBorder = Color3.fromRGB(210, 210, 220),
    AcrylicGradient = ColorSequence.new(Color3.fromRGB(250, 250, 255), Color3.fromRGB(235, 235, 242)),
    AcrylicNoise = 0.96,
    TitleBarLine = Color3.fromRGB(210, 210, 220),
    Tab = Color3.fromRGB(120, 120, 130),
    Element = Color3.fromRGB(255, 255, 255),
    ElementBorder = Color3.fromRGB(215, 215, 225),
    InElementBorder = Color3.fromRGB(200, 200, 215),
    ElementTransparency = 0.2,
    ToggleSlider = Color3.fromRGB(140, 140, 150),
    ToggleToggled = Color3.fromRGB(255, 255, 255),
    SliderRail = Color3.fromRGB(180, 180, 190),
    DropdownFrame = Color3.fromRGB(245, 245, 250),
    DropdownHolder = Color3.fromRGB(255, 255, 255),
    DropdownBorder = Color3.fromRGB(210, 210, 220),
    DropdownOption = Color3.fromRGB(240, 240, 245),
    Keybind = Color3.fromRGB(245, 245, 250),
    Input = Color3.fromRGB(245, 245, 250),
    InputFocused = Color3.fromRGB(255, 255, 255),
    InputIndicator = Color3.fromRGB(100, 100, 120),
    Dialog = Color3.fromRGB(255, 255, 255),
    DialogHolder = Color3.fromRGB(245, 245, 250),
    DialogHolderLine = Color3.fromRGB(225, 225, 235),
    DialogButton = Color3.fromRGB(255, 255, 255),
    DialogButtonBorder = Color3.fromRGB(200, 200, 215),
    DialogBorder = Color3.fromRGB(200, 200, 215),
    DialogInput = Color3.fromRGB(245, 245, 250),
    DialogInputLine = Color3.fromRGB(160, 160, 175),
    Text = Color3.fromRGB(25, 25, 30),
    SubText = Color3.fromRGB(90, 90, 105),
    Hover = Color3.fromRGB(225, 225, 235),
    HoverChange = 0.12
}

Fluent.Themes.Aqua = {
    Name = "Aqua",
    Accent = Color3.fromRGB(45, 180, 185),
    AcrylicMain = Color3.fromRGB(22, 34, 38),
    AcrylicBorder = Color3.fromRGB(45, 75, 85),
    AcrylicGradient = ColorSequence.new(Color3.fromRGB(25, 42, 48), Color3.fromRGB(18, 28, 32)),
    AcrylicNoise = 0.9,
    TitleBarLine = Color3.fromRGB(45, 75, 85),
    Tab = Color3.fromRGB(100, 140, 150),
    Element = Color3.fromRGB(30, 48, 54),
    ElementBorder = Color3.fromRGB(45, 75, 85),
    InElementBorder = Color3.fromRGB(60, 95, 108),
    ElementTransparency = 0.45,
    ToggleSlider = Color3.fromRGB(100, 140, 150),
    ToggleToggled = Color3.fromRGB(18, 28, 32),
    SliderRail = Color3.fromRGB(45, 75, 85),
    DropdownFrame = Color3.fromRGB(32, 52, 58),
    DropdownHolder = Color3.fromRGB(22, 36, 40),
    DropdownBorder = Color3.fromRGB(45, 75, 85),
    DropdownOption = Color3.fromRGB(35, 58, 65),
    Keybind = Color3.fromRGB(32, 52, 58),
    Input = Color3.fromRGB(32, 52, 58),
    InputFocused = Color3.fromRGB(18, 28, 32),
    InputIndicator = Color3.fromRGB(80, 160, 170),
    Dialog = Color3.fromRGB(24, 38, 44),
    DialogHolder = Color3.fromRGB(18, 28, 34),
    DialogHolderLine = Color3.fromRGB(40, 65, 75),
    DialogButton = Color3.fromRGB(32, 52, 60),
    DialogButtonBorder = Color3.fromRGB(55, 90, 102),
    DialogBorder = Color3.fromRGB(50, 85, 96),
    DialogInput = Color3.fromRGB(28, 46, 52),
    DialogInputLine = Color3.fromRGB(65, 135, 145),
    Text = Color3.fromRGB(240, 250, 252),
    SubText = Color3.fromRGB(150, 185, 195),
    Hover = Color3.fromRGB(40, 68, 78),
    HoverChange = 0.08
}

Fluent.Themes.Amethyst = {
    Name = "Amethyst",
    Accent = Color3.fromRGB(145, 95, 235),
    AcrylicMain = Color3.fromRGB(30, 24, 40),
    AcrylicBorder = Color3.fromRGB(75, 55, 95),
    AcrylicGradient = ColorSequence.new(Color3.fromRGB(38, 28, 52), Color3.fromRGB(24, 18, 32)),
    AcrylicNoise = 0.9,
    TitleBarLine = Color3.fromRGB(70, 50, 90),
    Tab = Color3.fromRGB(140, 120, 165),
    Element = Color3.fromRGB(45, 34, 58),
    ElementBorder = Color3.fromRGB(70, 52, 90),
    InElementBorder = Color3.fromRGB(95, 72, 125),
    ElementTransparency = 0.45,
    ToggleSlider = Color3.fromRGB(140, 120, 165),
    ToggleToggled = Color3.fromRGB(22, 16, 30),
    SliderRail = Color3.fromRGB(70, 52, 90),
    DropdownFrame = Color3.fromRGB(48, 36, 62),
    DropdownHolder = Color3.fromRGB(28, 22, 38),
    DropdownBorder = Color3.fromRGB(70, 52, 90),
    DropdownOption = Color3.fromRGB(52, 40, 68),
    Keybind = Color3.fromRGB(48, 36, 62),
    Input = Color3.fromRGB(48, 36, 62),
    InputFocused = Color3.fromRGB(20, 15, 28),
    InputIndicator = Color3.fromRGB(155, 115, 215),
    Dialog = Color3.fromRGB(32, 25, 44),
    DialogHolder = Color3.fromRGB(24, 18, 34),
    DialogHolderLine = Color3.fromRGB(60, 45, 80),
    DialogButton = Color3.fromRGB(46, 36, 62),
    DialogButtonBorder = Color3.fromRGB(80, 60, 105),
    DialogBorder = Color3.fromRGB(75, 58, 100),
    DialogInput = Color3.fromRGB(40, 30, 55),
    DialogInputLine = Color3.fromRGB(130, 95, 180),
    Text = Color3.fromRGB(248, 245, 255),
    SubText = Color3.fromRGB(180, 165, 205),
    Hover = Color3.fromRGB(65, 48, 85),
    HoverChange = 0.08
}

Fluent.Themes.Rose = {
    Name = "Rose",
    Accent = Color3.fromRGB(235, 75, 125),
    AcrylicMain = Color3.fromRGB(38, 22, 28),
    AcrylicBorder = Color3.fromRGB(90, 45, 62),
    AcrylicGradient = ColorSequence.new(Color3.fromRGB(48, 26, 35), Color3.fromRGB(28, 16, 22)),
    AcrylicNoise = 0.9,
    TitleBarLine = Color3.fromRGB(85, 42, 58),
    Tab = Color3.fromRGB(165, 120, 135),
    Element = Color3.fromRGB(56, 32, 42),
    ElementBorder = Color3.fromRGB(85, 45, 62),
    InElementBorder = Color3.fromRGB(115, 60, 85),
    ElementTransparency = 0.45,
    ToggleSlider = Color3.fromRGB(165, 120, 135),
    ToggleToggled = Color3.fromRGB(28, 16, 22),
    SliderRail = Color3.fromRGB(85, 45, 62),
    DropdownFrame = Color3.fromRGB(58, 34, 45),
    DropdownHolder = Color3.fromRGB(34, 20, 26),
    DropdownBorder = Color3.fromRGB(85, 45, 62),
    DropdownOption = Color3.fromRGB(64, 38, 50),
    Keybind = Color3.fromRGB(58, 34, 45),
    Input = Color3.fromRGB(58, 34, 45),
    InputFocused = Color3.fromRGB(24, 14, 18),
    InputIndicator = Color3.fromRGB(215, 95, 135),
    Dialog = Color3.fromRGB(40, 24, 30),
    DialogHolder = Color3.fromRGB(30, 18, 24),
    DialogHolderLine = Color3.fromRGB(75, 38, 52),
    DialogButton = Color3.fromRGB(58, 35, 46),
    DialogButtonBorder = Color3.fromRGB(98, 54, 74),
    DialogBorder = Color3.fromRGB(90, 50, 70),
    DialogInput = Color3.fromRGB(48, 28, 38),
    DialogInputLine = Color3.fromRGB(180, 85, 120),
    Text = Color3.fromRGB(255, 245, 248),
    SubText = Color3.fromRGB(205, 165, 180),
    Hover = Color3.fromRGB(78, 44, 58),
    HoverChange = 0.08
}

-- Lucide Icon Resolver
function Fluent:GetIcon(name)
    if not name then return nil end
    if typeof(name) == "number" then return "rbxassetid://" .. name end
    local str = tostring(name)
    if string.find(str, "rbxassetid://") or string.find(str, "http://") or string.find(str, "https://") then
        return str
    end
    local clean = string.lower(str)
    if string.sub(clean, 1, 7) == "lucide-" then
        clean = string.sub(clean, 8)
    end
    return LucideIcons[clean] or LucideIcons[str] or Assets[name] or nil
end

-- ============================================================================
-- Creator & Theme Engine
-- ============================================================================
local Creator = {
    Registry = {},
    Signals = {},
    TransparencyMotors = {},
    DefaultProperties = {
        ScreenGui = { ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling },
        Frame = { BackgroundColor3 = Color3.fromRGB(255, 255, 255), BorderColor3 = Color3.fromRGB(0, 0, 0), BorderSizePixel = 0 },
        ScrollingFrame = { BackgroundColor3 = Color3.fromRGB(255, 255, 255), BorderColor3 = Color3.fromRGB(0, 0, 0), BorderSizePixel = 0, ScrollBarImageColor3 = Color3.fromRGB(0, 0, 0) },
        TextLabel = { BackgroundColor3 = Color3.fromRGB(255, 255, 255), BorderColor3 = Color3.fromRGB(0, 0, 0), BackgroundTransparency = 1, Text = "", TextColor3 = Color3.fromRGB(0, 0, 0), TextSize = 14 },
        TextButton = { BackgroundColor3 = Color3.fromRGB(255, 255, 255), BorderColor3 = Color3.fromRGB(0, 0, 0), AutoButtonColor = false, Text = "", TextColor3 = Color3.fromRGB(0, 0, 0), TextSize = 14 },
        TextBox = { BackgroundColor3 = Color3.fromRGB(255, 255, 255), BorderColor3 = Color3.fromRGB(0, 0, 0), ClearTextOnFocus = false, Text = "", TextColor3 = Color3.fromRGB(0, 0, 0), TextSize = 14 },
        ImageLabel = { BackgroundTransparency = 1, BackgroundColor3 = Color3.fromRGB(255, 255, 255), BorderColor3 = Color3.fromRGB(0, 0, 0), BorderSizePixel = 0 },
        ImageButton = { BackgroundColor3 = Color3.fromRGB(255, 255, 255), BorderColor3 = Color3.fromRGB(0, 0, 0), AutoButtonColor = false },
        CanvasGroup = { BackgroundColor3 = Color3.fromRGB(255, 255, 255), BorderColor3 = Color3.fromRGB(0, 0, 0), BorderSizePixel = 0 }
    }
}

function Creator.AddSignal(signal, fn)
    local conn = signal:Connect(fn)
    table.insert(Creator.Signals, conn)
    return conn
end

function Creator.Disconnect()
    for i = #Creator.Signals, 1, -1 do
        local conn = table.remove(Creator.Signals, i)
        pcall(function() conn:Disconnect() end)
    end
end

function Creator.GetThemeProperty(prop)
    local currentTheme = Fluent.Themes[Fluent.Theme] or Fluent.Themes.Dark
    if currentTheme and currentTheme[prop] ~= nil then
        return currentTheme[prop]
    end
    return Fluent.Themes.Dark[prop]
end

function Creator.UpdateTheme()
    for obj, entry in pairs(Creator.Registry) do
        if obj and obj.Parent then
            for propName, themeKey in pairs(entry.Properties) do
                local val = Creator.GetThemeProperty(themeKey)
                if val ~= nil then
                    pcall(function() obj[propName] = val end)
                end
            end
        else
            Creator.Registry[obj] = nil
        end
    end
    for _, motor in ipairs(Creator.TransparencyMotors) do
        motor:setGoal(Instant.new(Creator.GetThemeProperty("ElementTransparency")))
    end
end

function Creator.AddThemeObject(obj, props)
    Creator.Registry[obj] = { Object = obj, Properties = props }
    for propName, themeKey in pairs(props) do
        local val = Creator.GetThemeProperty(themeKey)
        if val ~= nil then
            pcall(function() obj[propName] = val end)
        end
    end
    return obj
end

function Creator.OverrideTag(obj, props)
    if Creator.Registry[obj] then
        for k, v in pairs(props) do
            Creator.Registry[obj].Properties[k] = v
        end
    else
        Creator.Registry[obj] = { Object = obj, Properties = props }
    end
    for propName, themeKey in pairs(props) do
        local val = Creator.GetThemeProperty(themeKey)
        if val ~= nil then
            pcall(function() obj[propName] = val end)
        end
    end
end

function Creator.New(className, props, children)
    local inst = Instance.new(className)
    local defaults = Creator.DefaultProperties[className]
    if defaults then
        for k, v in pairs(defaults) do
            inst[k] = v
        end
    end
    local themeTag = props and props.ThemeTag
    if props then
        for k, v in pairs(props) do
            if k ~= "ThemeTag" then
                inst[k] = v
            end
        end
    end
    if children then
        for _, child in ipairs(children) do
            child.Parent = inst
        end
    end
    if themeTag then
        Creator.AddThemeObject(inst, themeTag)
    end
    return inst
end

function Creator.SpringMotor(initialValue, obj, prop, isDialog, isTransparency)
    local motor = SingleMotor.new(initialValue)
    motor:onStep(function(val)
        if obj and obj.Parent then
            obj[prop] = val
        end
    end)
    if isTransparency then
        table.insert(Creator.TransparencyMotors, motor)
    end
    local function setTarget(targetVal, force)
        if not isDialog and not force then
            if prop == "BackgroundTransparency" and Fluent.DialogOpen then
                return
            end
        end
        motor:setGoal(Spring.new(targetVal, { frequency = 8, dampingRatio = 1 }))
    end
    return motor, setTarget
end

-- ============================================================================
-- Acrylic & Frosted Glass System (Safe Mobile Glass)
-- ============================================================================
local Acrylic = {}
function Acrylic.CreatePaint(cornerRadius)
    cornerRadius = cornerRadius or 10
    local root = Creator.New("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0
    }, {
        -- Soft Outer Drop Shadow
        Creator.New("ImageLabel", {
            Name = "Shadow",
            Image = Assets.Shadow,
            ScaleType = Enum.ScaleType.Slice,
            SliceCenter = Rect.new(99, 99, 99, 99),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Size = UDim2.new(1, 40, 1, 40),
            Position = UDim2.fromScale(0.5, 0.5),
            BackgroundTransparency = 1,
            ImageColor3 = Color3.fromRGB(0, 0, 0),
            ImageTransparency = 0.55,
            ZIndex = 0
        }),
        -- Main Glass Surface
        Creator.New("Frame", {
            Name = "Background",
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 0.12,
            ThemeTag = {
                BackgroundColor3 = "AcrylicMain"
            }
        }, {
            Creator.New("UICorner", { CornerRadius = UDim.new(0, cornerRadius) }),
            -- Subtle Ambient Gradient Sheen
            Creator.New("UIGradient", {
                Rotation = 90,
                ThemeTag = { Color = "AcrylicGradient" }
            })
        }),
        -- Border Highlight / Stroke
        Creator.New("Frame", {
            Name = "Border",
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            ZIndex = 2
        }, {
            Creator.New("UICorner", { CornerRadius = UDim.new(0, cornerRadius) }),
            Creator.New("UIStroke", {
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                Thickness = 1.2,
                Transparency = 0.45,
                ThemeTag = { Color = "AcrylicBorder" }
            })
        })
    })

    return {
        Frame = root,
        SetVisibility = function(visible)
            root.Visible = visible
        end,
        Destroy = function()
            root:Destroy()
        end
    }
end

-- Safe Callback Helper
function Fluent:SafeCallback(func, ...)
    if not func then return end
    local ok, err = pcall(func, ...)
    if not ok then
        local errStr = tostring(err)
        local _, idx = string.find(errStr, ":%d+: ")
        if idx then errStr = string.sub(errStr, idx + 1) end
        Fluent:Notify({
            Title = "Callback Error",
            Content = errStr,
            Duration = 6
        })
    end
end

-- Accurate Rounding
function Fluent:Round(num, decimalPlaces)
    decimalPlaces = decimalPlaces or 0
    local formatted = string.format("%." .. tostring(decimalPlaces) .. "f", num)
    return tonumber(formatted) or num
end

-- ============================================================================
-- Notification System
-- ============================================================================
local Notification = { Holder = nil }
function Notification:Init(parentGui)
    self.Holder = Creator.New("Frame", {
        Name = "NotificationHolder",
        Position = UDim2.new(1, -20, 1, -20),
        Size = UDim2.new(0, 310, 1, -40),
        AnchorPoint = Vector2.new(1, 1),
        BackgroundTransparency = 1,
        Parent = parentGui,
        ZIndex = 100
    }, {
        Creator.New("UIListLayout", {
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            VerticalAlignment = Enum.VerticalAlignment.Bottom,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 10)
        })
    })
end

function Notification:New(config)
    config = config or {}
    local title = config.Title or "Notification"
    local content = config.Content or ""
    local subContent = config.SubContent or ""
    local duration = config.Duration or 4

    local notifObj = { Closed = false }
    local paint = Acrylic.CreatePaint(8)

    local titleLabel = Creator.New("TextLabel", {
        FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
        Text = title,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.new(0, 14, 0, 12),
        Size = UDim2.new(1, -40, 0, 14),
        ThemeTag = { TextColor3 = "Text" }
    })

    local contentLabel = Creator.New("TextLabel", {
        FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
        Text = content,
        TextSize = 12,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        AutomaticSize = Enum.AutomaticSize.Y,
        Size = UDim2.new(1, 0, 0, 0),
        ThemeTag = { TextColor3 = "Text" }
    })

    local subLabel = Creator.New("TextLabel", {
        FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
        Text = subContent,
        TextSize = 11,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        AutomaticSize = Enum.AutomaticSize.Y,
        Size = UDim2.new(1, 0, 0, 0),
        ThemeTag = { TextColor3 = "SubText" }
    })

    local bodyLayout = Creator.New("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 3)
    })

    local bodyHolder = Creator.New("Frame", {
        Position = UDim2.fromOffset(14, 32),
        Size = UDim2.new(1, -28, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1
    }, { bodyLayout, contentLabel, subLabel })

    if content == "" then contentLabel.Visible = false end
    if subContent == "" then subLabel.Visible = false end

    local closeBtn = Creator.New("TextButton", {
        Text = "",
        Position = UDim2.new(1, -12, 0, 10),
        Size = UDim2.fromOffset(22, 22),
        AnchorPoint = Vector2.new(1, 0),
        BackgroundTransparency = 1
    }, {
        Creator.New("ImageLabel", {
            Image = Assets.Close,
            Size = UDim2.fromOffset(14, 14),
            Position = UDim2.fromScale(0.5, 0.5),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            ThemeTag = { ImageColor3 = "SubText" }
        })
    })

    local root = Creator.New("Frame", {
        Size = UDim2.fromScale(1, 1),
        Position = UDim2.fromScale(1.1, 0),
        BackgroundTransparency = 1
    }, {
        paint.Frame,
        titleLabel,
        closeBtn,
        bodyHolder
    })

    local itemHolder = Creator.New("Frame", {
        Size = UDim2.new(1, 0, 0, 60),
        BackgroundTransparency = 1,
        Parent = self.Holder
    }, { root })

    local motor = SingleMotor.new(1.1)
    motor:onStep(function(val)
        root.Position = UDim2.new(val, 0, 0, 0)
    end)

    function notifObj:Close()
        if not notifObj.Closed then
            notifObj.Closed = true
            motor:setGoal(Spring.new(1.2, { frequency = 6, dampingRatio = 0.9 }))
            task.delay(0.25, function()
                paint.Destroy()
                itemHolder:Destroy()
            end)
        end
    end

    Creator.AddSignal(closeBtn.MouseButton1Click, function()
        notifObj:Close()
    end)

    task.spawn(function()
        task.wait()
        local h = bodyHolder.AbsoluteSize.Y + 44
        itemHolder.Size = UDim2.new(1, 0, 0, math.max(60, h))
        motor:setGoal(Spring.new(0, { frequency = 5, dampingRatio = 0.85 }))
    end)

    if duration then
        task.delay(duration, function()
            notifObj:Close()
        end)
    end

    return notifObj
end

function Fluent:Notify(config)
    return Notification:New(config)
end

-- ============================================================================
-- Dialog Modal System
-- ============================================================================
local Dialog = { Window = nil }
function Dialog:Init(window)
    self.Window = window
    return self
end

function Dialog:Create(config)
    config = config or {}
    local title = config.Title or "Dialog"
    local content = config.Content or ""
    local buttons = config.Buttons or {}

    local dialogObj = { Buttons = 0 }

    local tint = Creator.New("TextButton", {
        Text = "",
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 1,
        Parent = self.Window.Root,
        ZIndex = 50
    }, {
        Creator.New("UICorner", { CornerRadius = UDim.new(0, 10) })
    })

    local tintMotor, setTint = Creator.SpringMotor(1, tint, "BackgroundTransparency", true)

    local buttonHolder = Creator.New("Frame", {
        Size = UDim2.new(1, -24, 0, 42),
        Position = UDim2.new(0.5, 0, 1, -12),
        AnchorPoint = Vector2.new(0.5, 1),
        BackgroundTransparency = 1
    }, {
        Creator.New("UIListLayout", {
            Padding = UDim.new(0, 8),
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            SortOrder = Enum.SortOrder.LayoutOrder
        })
    })

    local titleLabel = Creator.New("TextLabel", {
        FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
        Text = title,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.fromOffset(16, 16),
        Size = UDim2.new(1, -32, 0, 20),
        ThemeTag = { TextColor3 = "Text" }
    })

    local contentLabel = Creator.New("TextLabel", {
        FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
        Text = content,
        TextSize = 13,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        Position = UDim2.fromOffset(16, 44),
        Size = UDim2.new(1, -32, 1, -104),
        ThemeTag = { TextColor3 = "SubText" }
    })

    local scale = Creator.New("UIScale", { Scale = 0.9 })
    local scaleMotor = SingleMotor.new(0.9)
    scaleMotor:onStep(function(val) scale.Scale = val end)

    local card = Creator.New("CanvasGroup", {
        Size = UDim2.fromOffset(300, 160),
        Position = UDim2.fromScale(0.5, 0.5),
        AnchorPoint = Vector2.new(0.5, 0.5),
        GroupTransparency = 1,
        Parent = tint,
        ThemeTag = { BackgroundColor3 = "Dialog" }
    }, {
        Creator.New("UICorner", { CornerRadius = UDim.new(0, 8) }),
        Creator.New("UIStroke", {
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            Thickness = 1.2,
            Transparency = 0.5,
            ThemeTag = { Color = "DialogBorder" }
        }),
        scale,
        titleLabel,
        contentLabel,
        buttonHolder
    })

    local cardMotor = SingleMotor.new(1)
    cardMotor:onStep(function(val) card.GroupTransparency = val end)

    function dialogObj:Open()
        Fluent.DialogOpen = true
        setTint(0.65)
        cardMotor:setGoal(Spring.new(0, { frequency = 8, dampingRatio = 0.8 }))
        scaleMotor:setGoal(Spring.new(1, { frequency = 8, dampingRatio = 0.75 }))
    end

    function dialogObj:Close()
        Fluent.DialogOpen = false
        setTint(1)
        cardMotor:setGoal(Spring.new(1, { frequency = 8, dampingRatio = 0.9 }))
        scaleMotor:setGoal(Spring.new(0.9, { frequency = 8, dampingRatio = 0.9 }))
        task.delay(0.2, function()
            tint:Destroy()
        end)
    end

    function dialogObj:AddButton(btnTitle, callback)
        dialogObj.Buttons = dialogObj.Buttons + 1
        local btn = Creator.New("TextButton", {
            Text = "",
            Size = UDim2.new(1, 0, 1, 0),
            Parent = buttonHolder,
            ThemeTag = { BackgroundColor3 = "DialogButton" }
        }, {
            Creator.New("UICorner", { CornerRadius = UDim.new(0, 6) }),
            Creator.New("UIStroke", {
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                Thickness = 1,
                Transparency = 0.6,
                ThemeTag = { Color = "DialogButtonBorder" }
            }),
            Creator.New("TextLabel", {
                FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal),
                Text = btnTitle or "Button",
                TextSize = 13,
                Size = UDim2.fromScale(1, 1),
                ThemeTag = { TextColor3 = "Text" }
            })
        })

        -- Re-distribute widths
        local total = dialogObj.Buttons
        for _, child in ipairs(buttonHolder:GetChildren()) do
            if child:IsA("TextButton") then
                child.Size = UDim2.new(1 / total, -(((total - 1) * 8) / total), 1, 0)
            end
        end

        Creator.AddSignal(btn.MouseButton1Click, function()
            Fluent:SafeCallback(callback)
            dialogObj:Close()
        end)

        return btn
    end

    for _, btnData in ipairs(buttons) do
        dialogObj:AddButton(btnData.Title, btnData.Callback)
    end
    if dialogObj.Buttons == 0 then
        dialogObj:AddButton("OK", nil)
    end

    dialogObj:Open()
    return dialogObj
end

-- ============================================================================
-- Element Base Component
-- ============================================================================
local function CreateElement(title, desc, parent, isClickable)
    local element = {}
    element.TitleLabel = Creator.New("TextLabel", {
        FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal),
        Text = title or "",
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(1, 0, 0, 16),
        ThemeTag = { TextColor3 = "Text" }
    })

    element.DescLabel = Creator.New("TextLabel", {
        FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
        Text = desc or "",
        TextSize = 11,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        AutomaticSize = Enum.AutomaticSize.Y,
        Size = UDim2.new(1, 0, 0, 0),
        Visible = (desc ~= nil and desc ~= ""),
        ThemeTag = { TextColor3 = "SubText" }
    })

    element.LabelHolder = Creator.New("Frame", {
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(12, 0),
        Size = UDim2.new(1, -170, 0, 0)
    }, {
        Creator.New("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 2)
        }),
        Creator.New("UIPadding", {
            PaddingTop = UDim.new(0, 10),
            PaddingBottom = UDim.new(0, 10)
        }),
        element.TitleLabel,
        element.DescLabel
    })

    element.Border = Creator.New("UIStroke", {
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Thickness = 1,
        Transparency = 0.5,
        ThemeTag = { Color = "ElementBorder" }
    })

    element.Frame = Creator.New("TextButton", {
        Name = "ElementFrame",
        Size = UDim2.new(1, 0, 0, 42),
        AutomaticSize = Enum.AutomaticSize.Y,
        Text = "",
        Parent = parent,
        ThemeTag = {
            BackgroundColor3 = "Element",
            BackgroundTransparency = "ElementTransparency"
        }
    }, {
        Creator.New("UICorner", { CornerRadius = UDim.new(0, 6) }),
        element.Border,
        element.LabelHolder
    })

    function element:SetTitle(newTitle)
        element.TitleLabel.Text = newTitle
    end

    function element:SetDesc(newDesc)
        if not newDesc or newDesc == "" then
            element.DescLabel.Visible = false
            element.DescLabel.Text = ""
        else
            element.DescLabel.Visible = true
            element.DescLabel.Text = newDesc
        end
    end

    function element:Destroy()
        element.Frame:Destroy()
    end

    if isClickable then
        local _, setTrans = Creator.SpringMotor(
            Creator.GetThemeProperty("ElementTransparency"),
            element.Frame,
            "BackgroundTransparency",
            false,
            true
        )
        Creator.AddSignal(element.Frame.MouseEnter, function()
            setTrans(Creator.GetThemeProperty("ElementTransparency") - Creator.GetThemeProperty("HoverChange"))
        end)
        Creator.AddSignal(element.Frame.MouseLeave, function()
            setTrans(Creator.GetThemeProperty("ElementTransparency"))
        end)
        Creator.AddSignal(element.Frame.MouseButton1Down, function()
            setTrans(Creator.GetThemeProperty("ElementTransparency") + Creator.GetThemeProperty("HoverChange"))
        end)
        Creator.AddSignal(element.Frame.MouseButton1Up, function()
            setTrans(Creator.GetThemeProperty("ElementTransparency") - Creator.GetThemeProperty("HoverChange"))
        end)
    end

    return element
end

-- Helper to normalize (id, config) vs (config)
local function parseArgs(arg1, arg2)
    if type(arg1) == "table" and arg2 == nil then
        local autoId = arg1.Title or ("Item_" .. tostring(math.random(10000, 99999)))
        return autoId, arg1
    end
    return arg1, arg2 or {}
end

-- ============================================================================
-- Elements Implementation
-- ============================================================================
local Elements = {}

-- Button
function Elements.AddButton(container, config)
    assert(config.Title, "Button - Missing Title")
    local elem = CreateElement(config.Title, config.Description, container.Container, true)
    
    local icon = Creator.New("ImageLabel", {
        Image = Assets.Check,
        Size = UDim2.fromOffset(16, 16),
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -12, 0.5, 0),
        BackgroundTransparency = 1,
        Parent = elem.Frame,
        ThemeTag = { ImageColor3 = "Text" }
    })

    Creator.AddSignal(elem.Frame.MouseButton1Click, function()
        container.Library:SafeCallback(config.Callback)
    end)

    return elem
end

-- Toggle Switch
function Elements.AddToggle(container, arg1, arg2)
    local id, config = parseArgs(arg1, arg2)
    assert(config.Title, "Toggle - Missing Title")
    local lib = container.Library
    local toggle = {
        Value = not not config.Default,
        Type = "Toggle",
        Callback = config.Callback or function() end
    }

    local elem = CreateElement(config.Title, config.Description, container.Container, true)
    elem.LabelHolder.Size = UDim2.new(1, -70, 0, 0)
    toggle.SetTitle = function(_, t) elem:SetTitle(t) end
    toggle.SetDesc = function(_, d) elem:SetDesc(d) end

    -- Thumb knob
    local knob = Creator.New("ImageLabel", {
        Image = Assets.Circle,
        Size = UDim2.fromOffset(14, 14),
        Position = UDim2.new(0, 3, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        ThemeTag = { ImageColor3 = "ToggleSlider" }
    })

    local switchBorder = Creator.New("UIStroke", {
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Thickness = 1.2,
        Transparency = 0.5,
        ThemeTag = { Color = "ToggleSlider" }
    })

    local switch = Creator.New("Frame", {
        Size = UDim2.fromOffset(40, 22),
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -12, 0.5, 0),
        Parent = elem.Frame,
        BackgroundTransparency = 1,
        ThemeTag = { BackgroundColor3 = "Accent" }
    }, {
        Creator.New("UICorner", { CornerRadius = UDim.new(0, 11) }),
        switchBorder,
        knob
    })

    function toggle:OnChanged(fn)
        toggle.Changed = fn
        fn(toggle.Value)
    end

    function toggle:SetValue(val)
        toggle.Value = not not val
        Creator.OverrideTag(switchBorder, { Color = toggle.Value and "Accent" or "ToggleSlider" })
        Creator.OverrideTag(knob, { ImageColor3 = toggle.Value and "ToggleToggled" or "ToggleSlider" })

        TweenService:Create(knob, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Position = UDim2.new(0, toggle.Value and 23 or 3, 0.5, 0)
        }):Play()

        TweenService:Create(switch, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            BackgroundTransparency = toggle.Value and 0 or 1
        }):Play()

        lib:SafeCallback(toggle.Callback, toggle.Value)
        if toggle.Changed then lib:SafeCallback(toggle.Changed, toggle.Value) end
    end

    function toggle:Destroy()
        elem:Destroy()
        lib.Options[id] = nil
    end

    Creator.AddSignal(elem.Frame.MouseButton1Click, function()
        toggle:SetValue(not toggle.Value)
    end)

    toggle:SetValue(toggle.Value)
    lib.Options[id] = toggle
    return toggle
end

-- Slider (Mobile Touch-Optimized with Scroll-Lock on Touch Drag)
function Elements.AddSlider(container, arg1, arg2)
    local id, config = parseArgs(arg1, arg2)
    assert(config.Title, "Slider - Missing Title")
    assert(config.Min, "Slider - Missing Min")
    assert(config.Max, "Slider - Missing Max")
    local lib = container.Library
    local slider = {
        Value = config.Default or config.Min,
        Min = config.Min,
        Max = config.Max,
        Rounding = config.Rounding or 0,
        Type = "Slider",
        Callback = config.Callback or function() end
    }

    local elem = CreateElement(config.Title, config.Description, container.Container, false)
    elem.LabelHolder.Size = UDim2.new(1, -190, 0, 0)
    slider.SetTitle = function(_, t) elem:SetTitle(t) end
    slider.SetDesc = function(_, d) elem:SetDesc(d) end

    -- Value Badge
    local valLabel = Creator.New("TextLabel", {
        FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal),
        Text = tostring(slider.Value),
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Right,
        Size = UDim2.new(0, 48, 0, 16),
        Position = UDim2.new(0, -6, 0.5, 0),
        AnchorPoint = Vector2.new(1, 0.5),
        ThemeTag = { TextColor3 = "Text" }
    })

    -- Slider Rail
    local fill = Creator.New("Frame", {
        Size = UDim2.new(0, 0, 1, 0),
        ThemeTag = { BackgroundColor3 = "Accent" }
    }, {
        Creator.New("UICorner", { CornerRadius = UDim.new(1, 0) })
    })

    local knob = Creator.New("ImageLabel", {
        Image = Assets.Circle,
        Size = UDim2.fromOffset(14, 14),
        Position = UDim2.new(0, -7, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        ThemeTag = { ImageColor3 = "Accent" }
    })

    local knobHolder = Creator.New("Frame", {
        Size = UDim2.new(1, -14, 1, 0),
        Position = UDim2.fromOffset(7, 0),
        BackgroundTransparency = 1
    }, { knob })

    local rail = Creator.New("Frame", {
        Size = UDim2.new(0, 130, 0, 6),
        Position = UDim2.new(1, -12, 0.5, 0),
        AnchorPoint = Vector2.new(1, 0.5),
        BackgroundTransparency = 0.5,
        Parent = elem.Frame,
        ThemeTag = { BackgroundColor3 = "SliderRail" }
    }, {
        Creator.New("UICorner", { CornerRadius = UDim.new(1, 0) }),
        valLabel,
        fill,
        knobHolder
    })

    -- Large Touch Hitbox (36px high for thumbs!)
    local touchArea = Creator.New("TextButton", {
        Size = UDim2.new(1, 20, 0, 36),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Text = "",
        Parent = rail
    })

    function slider:OnChanged(fn)
        slider.Changed = fn
        fn(slider.Value)
    end

    function slider:SetValue(v)
        local clamped = math_clamp(v, slider.Min, slider.Max)
        slider.Value = lib:Round(clamped, slider.Rounding)
        local progress = (slider.Value - slider.Min) / (slider.Max - slider.Min)
        
        knob.Position = UDim2.new(progress, -7, 0.5, 0)
        fill.Size = UDim2.fromScale(progress, 1)
        valLabel.Text = tostring(slider.Value)

        lib:SafeCallback(slider.Callback, slider.Value)
        if slider.Changed then lib:SafeCallback(slider.Changed, slider.Value) end
    end

    function slider:Destroy()
        elem:Destroy()
        lib.Options[id] = nil
    end

    -- Touch & Mouse Tracking with Scroll-Lock Prevention!
    local isDragging = false
    local activeInput = nil

    local function updateFromPos(xPos)
        local relX = xPos - rail.AbsolutePosition.X
        local pct = math_clamp(relX / rail.AbsoluteSize.X, 0, 1)
        slider:SetValue(slider.Min + (slider.Max - slider.Min) * pct)
    end

    Creator.AddSignal(touchArea.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDragging = true
            activeInput = input
            
            -- Lock container scrolling so dragging slider does not scroll page on mobile!
            if container.ScrollFrame then
                container.ScrollFrame.ScrollingEnabled = false
            end
            
            TweenService:Create(knob, TweenInfo.new(0.15), { Size = UDim2.fromOffset(18, 18) }):Play()
            updateFromPos(input.Position.X)
            
            local moveConn, endConn
            moveConn = Creator.AddSignal(UserInputService.InputChanged, function(moveInput)
                if isDragging and (moveInput == activeInput or moveInput.UserInputType == Enum.UserInputType.Touch or moveInput.UserInputType == Enum.UserInputType.MouseMovement) then
                    updateFromPos(moveInput.Position.X)
                end
            end)
            endConn = Creator.AddSignal(UserInputService.InputEnded, function(endInput)
                if endInput == activeInput or (endInput.UserInputType == Enum.UserInputType.MouseButton1 or endInput.UserInputType == Enum.UserInputType.Touch) then
                    isDragging = false
                    activeInput = nil
                    
                    -- Restore container scrolling
                    if container.ScrollFrame then
                        container.ScrollFrame.ScrollingEnabled = true
                    end
                    
                    TweenService:Create(knob, TweenInfo.new(0.15), { Size = UDim2.fromOffset(14, 14) }):Play()
                    if moveConn then pcall(function() moveConn:Disconnect() end) end
                    if endConn then pcall(function() endConn:Disconnect() end) end
                end
            end)
        end
    end)

    slider:SetValue(slider.Value)
    lib.Options[id] = slider
    return slider
end

-- Dropdown (Mobile-Safe with Outside Tap Backdrop & Scroll-Lock)
function Elements.AddDropdown(container, arg1, arg2)
    local id, config = parseArgs(arg1, arg2)
    assert(config.Title, "Dropdown - Missing Title")
    local lib = container.Library

    -- Normalize default value
    local initialVal = config.Default
    if config.Multi then
        if type(initialVal) ~= "table" then
            initialVal = initialVal and { [initialVal] = true } or {}
        else
            local mapped = {}
            for k, v in pairs(initialVal) do
                if type(k) == "number" and type(v) == "string" then
                    mapped[v] = true
                elseif type(k) == "number" and type(v) == "number" and config.Values and config.Values[v] then
                    mapped[config.Values[v]] = true
                else
                    mapped[k] = v
                end
            end
            initialVal = mapped
        end
    else
        if type(initialVal) == "number" and config.Values and config.Values[initialVal] then
            initialVal = config.Values[initialVal]
        end
    end

    local dropdown = {
        Values = config.Values or {},
        Value = initialVal,
        Multi = config.Multi or false,
        Opened = false,
        Type = "Dropdown",
        Callback = config.Callback or function() end
    }

    local elem = CreateElement(config.Title, config.Description, container.Container, false)
    elem.LabelHolder.Size = UDim2.new(1, -190, 0, 0)
    dropdown.SetTitle = function(_, t) elem:SetTitle(t) end
    dropdown.SetDesc = function(_, d) elem:SetDesc(d) end

    -- Display Button
    local displayLabel = Creator.New("TextLabel", {
        FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
        Text = "--",
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Size = UDim2.new(1, -28, 1, 0),
        Position = UDim2.fromOffset(10, 0),
        ThemeTag = { TextColor3 = "Text" }
    })

    local chevron = Creator.New("ImageLabel", {
        Image = Assets.Chevron,
        Size = UDim2.fromOffset(14, 14),
        Position = UDim2.new(1, -8, 0.5, 0),
        AnchorPoint = Vector2.new(1, 0.5),
        BackgroundTransparency = 1,
        ThemeTag = { ImageColor3 = "SubText" }
    })

    local triggerBtn = Creator.New("TextButton", {
        Size = UDim2.fromOffset(150, 32),
        Position = UDim2.new(1, -12, 0.5, 0),
        AnchorPoint = Vector2.new(1, 0.5),
        Parent = elem.Frame,
        ThemeTag = { BackgroundColor3 = "DropdownFrame" }
    }, {
        Creator.New("UICorner", { CornerRadius = UDim.new(0, 6) }),
        Creator.New("UIStroke", {
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            Thickness = 1,
            Transparency = 0.5,
            ThemeTag = { Color = "InElementBorder" }
        }),
        displayLabel,
        chevron
    })

    -- Fullscreen Touch Backdrop for Outside Tap Dismissal
    local backdrop = Creator.New("TextButton", {
        Name = "DropdownBackdrop",
        Text = "",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Visible = false,
        Parent = lib.GUI,
        ZIndex = 80
    })

    -- Floating Options Menu
    local listLayout = Creator.New("UIListLayout", {
        Padding = UDim.new(0, 4),
        SortOrder = Enum.SortOrder.LayoutOrder
    })

    local scroll = Creator.New("ScrollingFrame", {
        Size = UDim2.new(1, -8, 1, -10),
        Position = UDim2.fromOffset(4, 5),
        BackgroundTransparency = 1,
        ScrollBarThickness = 3,
        BorderSizePixel = 0,
        CanvasSize = UDim2.fromScale(0, 0)
    }, { listLayout })

    local menuFrame = Creator.New("Frame", {
        Size = UDim2.fromOffset(160, 160),
        BackgroundTransparency = 0.05,
        Parent = backdrop,
        ThemeTag = { BackgroundColor3 = "DropdownHolder" }
    }, {
        Creator.New("UICorner", { CornerRadius = UDim.new(0, 8) }),
        Creator.New("UIStroke", {
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            Thickness = 1.2,
            Transparency = 0.4,
            ThemeTag = { Color = "DropdownBorder" }
        }),
        scroll
    })

    function dropdown:Display()
        local currentValues = dropdown.Values
        if type(currentValues) == "function" then
            local ok, res = pcall(currentValues)
            if ok and type(res) == "table" then currentValues = res end
        end
        if dropdown.Multi then
            local count = 0
            local first = nil
            if type(dropdown.Value) == "table" then
                for k, v in pairs(dropdown.Value) do
                    if v then
                        count = count + 1
                        if not first then first = k end
                    end
                end
            end
            if count == 0 then
                displayLabel.Text = "--"
            elseif count == 1 then
                displayLabel.Text = tostring(first)
            else
                displayLabel.Text = tostring(count) .. " dipilih ✦"
            end
        else
            displayLabel.Text = dropdown.Value and tostring(dropdown.Value) or "--"
        end
    end

    function dropdown:Close()
        if dropdown.Opened then
            dropdown.Opened = false
            backdrop.Visible = false
            if container.ScrollFrame then
                container.ScrollFrame.ScrollingEnabled = true
            end
            TweenService:Create(chevron, TweenInfo.new(0.2), { Rotation = 0 }):Play()
        end
    end

    function dropdown:Open()
        if not dropdown.Opened then
            dropdown.Opened = true
            backdrop.Visible = true
            if container.ScrollFrame then
                container.ScrollFrame.ScrollingEnabled = false
            end
            TweenService:Create(chevron, TweenInfo.new(0.2), { Rotation = 180 }):Play()

            dropdown:BuildList()

            -- Position menu clamped on screen
            local vp = Camera and Camera.ViewportSize or Vector2.new(800, 600)
            local posX = triggerBtn.AbsolutePosition.X
            local posY = triggerBtn.AbsolutePosition.Y + triggerBtn.AbsoluteSize.Y + 4
            local menuH = math.min(180, listLayout.AbsoluteContentSize.Y + 12)
            
            if posY + menuH > vp.Y - 10 then
                posY = triggerBtn.AbsolutePosition.Y - menuH - 4
            end
            
            menuFrame.Size = UDim2.fromOffset(math.max(160, triggerBtn.AbsoluteSize.X), menuH)
            menuFrame.Position = UDim2.fromOffset(posX, posY)
            scroll.CanvasSize = UDim2.fromOffset(0, listLayout.AbsoluteContentSize.Y)
        end
    end

    function dropdown:BuildList()
        for _, child in ipairs(scroll:GetChildren()) do
            if child:IsA("TextButton") then child:Destroy() end
        end

        local currentValues = dropdown.Values
        if type(dropdown.GetValues) == "function" then
            local ok, res = pcall(dropdown.GetValues)
            if ok and type(res) == "table" then
                currentValues = res
                dropdown.Values = res
            end
        elseif type(currentValues) == "function" then
            local ok, res = pcall(currentValues)
            if ok and type(res) == "table" then
                currentValues = res
            end
        end

        for _, item in ipairs(currentValues or {}) do
            local itemVal = type(item) == "table" and (item.value or item.Value or item[1]) or item
            local itemDisp = type(item) == "table" and (item.display or item.Display or item[2] or itemVal) or tostring(item)
            local isSelected = false
            if dropdown.Multi then
                isSelected = type(dropdown.Value) == "table" and dropdown.Value[itemVal] or false
            else
                isSelected = dropdown.Value == itemVal
            end

            local checkmark = Creator.New("ImageLabel", {
                Image = Assets.Check,
                Size = UDim2.fromOffset(14, 14),
                Position = UDim2.new(1, -8, 0.5, 0),
                AnchorPoint = Vector2.new(1, 0.5),
                BackgroundTransparency = 1,
                Visible = isSelected,
                ThemeTag = { ImageColor3 = "Accent" }
            })

            local itemBtn = Creator.New("TextButton", {
                Size = UDim2.new(1, 0, 0, 34),
                Parent = scroll,
                ThemeTag = { BackgroundColor3 = isSelected and "DropdownOption" or "DropdownHolder" }
            }, {
                Creator.New("UICorner", { CornerRadius = UDim.new(0, 5) }),
                Creator.New("TextLabel", {
                    FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
                    Text = tostring(itemDisp),
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Size = UDim2.new(1, -28, 1, 0),
                    Position = UDim2.fromOffset(10, 0),
                    ThemeTag = { TextColor3 = "Text" }
                }),
                checkmark
            })

            Creator.AddSignal(itemBtn.MouseButton1Click, function()
                if dropdown.Multi then
                    if type(dropdown.Value) ~= "table" then dropdown.Value = {} end
                    dropdown.Value[itemVal] = not dropdown.Value[itemVal] or nil
                    dropdown:BuildList()
                    dropdown:Display()
                    lib:SafeCallback(dropdown.Callback, dropdown.Value)
                    if dropdown.Changed then lib:SafeCallback(dropdown.Changed, dropdown.Value) end
                else
                    dropdown.Value = itemVal
                    dropdown:BuildList()
                    dropdown:Display()
                    dropdown:Close()
                    lib:SafeCallback(dropdown.Callback, dropdown.Value)
                    if dropdown.Changed then lib:SafeCallback(dropdown.Changed, dropdown.Value) end
                end
            end)
        end
        scroll.CanvasSize = UDim2.fromOffset(0, listLayout.AbsoluteContentSize.Y)
    end

    function dropdown:SetValues(newValues)
        dropdown.Values = newValues or {}
        dropdown:BuildList()
        dropdown:Display()
    end

    function dropdown:SetValue(newVal)
        dropdown.Value = newVal
        dropdown:BuildList()
        dropdown:Display()
        lib:SafeCallback(dropdown.Callback, dropdown.Value)
        if dropdown.Changed then lib:SafeCallback(dropdown.Changed, dropdown.Value) end
    end

    function dropdown:OnChanged(fn)
        dropdown.Changed = fn
        fn(dropdown.Value)
    end

    function dropdown:Destroy()
        elem:Destroy()
        backdrop:Destroy()
        lib.Options[id] = nil
    end

    Creator.AddSignal(triggerBtn.MouseButton1Click, function()
        if dropdown.Opened then dropdown:Close() else dropdown:Open() end
    end)

    Creator.AddSignal(backdrop.MouseButton1Click, function()
        dropdown:Close()
    end)

    dropdown:BuildList()
    dropdown:Display()
    lib.Options[id] = dropdown
    return dropdown
end

-- Input Textbox
function Elements.AddInput(container, arg1, arg2)
    local id, config = parseArgs(arg1, arg2)
    assert(config.Title, "Input - Missing Title")
    local lib = container.Library
    local inputObj = {
        Value = config.Default or "",
        Type = "Input",
        Callback = config.Callback or function() end
    }

    local elem = CreateElement(config.Title, config.Description, container.Container, false)
    elem.LabelHolder.Size = UDim2.new(1, -190, 0, 0)
    inputObj.SetTitle = function(_, t) elem:SetTitle(t) end
    inputObj.SetDesc = function(_, d) elem:SetDesc(d) end

    local line = Creator.New("Frame", {
        Size = UDim2.new(1, 0, 0, 1.5),
        Position = UDim2.new(0, 0, 1, 0),
        AnchorPoint = Vector2.new(0, 1),
        ThemeTag = { BackgroundColor3 = "InputIndicator" }
    })

    local tb = Creator.New("TextBox", {
        FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
        Text = tostring(inputObj.Value),
        PlaceholderText = config.Placeholder or "Type here...",
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(1, -16, 1, 0),
        Position = UDim2.fromOffset(8, 0),
        ThemeTag = { TextColor3 = "Text", PlaceholderColor3 = "SubText" }
    })

    local inputFrame = Creator.New("Frame", {
        Size = UDim2.fromOffset(150, 32),
        Position = UDim2.new(1, -12, 0.5, 0),
        AnchorPoint = Vector2.new(1, 0.5),
        Parent = elem.Frame,
        ThemeTag = { BackgroundColor3 = "Input" }
    }, {
        Creator.New("UICorner", { CornerRadius = UDim.new(0, 6) }),
        Creator.New("UIStroke", {
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            Thickness = 1,
            Transparency = 0.5,
            ThemeTag = { Color = "InElementBorder" }
        }),
        tb,
        line
    })

    function inputObj:SetValue(str)
        if config.MaxLength and #str > config.MaxLength then
            str = string.sub(str, 1, config.MaxLength)
        end
        if config.Numeric then
            if not tonumber(str) and #str > 0 then
                str = inputObj.Value
            end
        end
        inputObj.Value = str
        tb.Text = str
        lib:SafeCallback(inputObj.Callback, inputObj.Value)
        if inputObj.Changed then lib:SafeCallback(inputObj.Changed, inputObj.Value) end
    end

    function inputObj:OnChanged(fn)
        inputObj.Changed = fn
        fn(inputObj.Value)
    end

    function inputObj:Destroy()
        elem:Destroy()
        lib.Options[id] = nil
    end

    Creator.AddSignal(tb.Focused, function()
        Creator.OverrideTag(line, { BackgroundColor3 = "Accent" })
        Creator.OverrideTag(inputFrame, { BackgroundColor3 = "InputFocused" })
    end)

    Creator.AddSignal(tb.FocusLost, function()
        Creator.OverrideTag(line, { BackgroundColor3 = "InputIndicator" })
        Creator.OverrideTag(inputFrame, { BackgroundColor3 = "Input" })
        if config.Finished then
            inputObj:SetValue(tb.Text)
        end
    end)

    if not config.Finished then
        Creator.AddSignal(tb:GetPropertyChangedSignal("Text"), function()
            inputObj:SetValue(tb.Text)
        end)
    end

    lib.Options[id] = inputObj
    return inputObj
end

-- Keybind (Cross-platform keyboard + mobile tap)
function Elements.AddKeybind(container, arg1, arg2)
    local id, config = parseArgs(arg1, arg2)
    assert(config.Title, "Keybind - Missing Title")
    assert(config.Default, "Keybind - Missing Default")
    local lib = container.Library
    local kb = {
        Value = config.Default,
        Mode = config.Mode or "Toggle",
        Toggled = false,
        Type = "Keybind",
        Callback = config.Callback or function() end,
        ChangedCallback = config.ChangedCallback or function() end
    }

    local elem = CreateElement(config.Title, config.Description, container.Container, true)
    elem.LabelHolder.Size = UDim2.new(1, -120, 0, 0)
    kb.SetTitle = function(_, t) elem:SetTitle(t) end
    kb.SetDesc = function(_, d) elem:SetDesc(d) end

    local bindLabel = Creator.New("TextLabel", {
        FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal),
        Text = tostring(kb.Value),
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Center,
        Size = UDim2.fromScale(1, 1),
        ThemeTag = { TextColor3 = "Text" }
    })

    local bindBtn = Creator.New("TextButton", {
        Size = UDim2.fromOffset(80, 28),
        Position = UDim2.new(1, -12, 0.5, 0),
        AnchorPoint = Vector2.new(1, 0.5),
        Parent = elem.Frame,
        ThemeTag = { BackgroundColor3 = "Keybind" }
    }, {
        Creator.New("UICorner", { CornerRadius = UDim.new(0, 6) }),
        Creator.New("UIStroke", {
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            Thickness = 1,
            Transparency = 0.5,
            ThemeTag = { Color = "InElementBorder" }
        }),
        bindLabel
    })

    local listening = false
    function kb:SetValue(keyName, mode)
        kb.Value = keyName or kb.Value
        kb.Mode = mode or kb.Mode
        bindLabel.Text = tostring(kb.Value)
    end

    function kb:OnClick(fn) kb.Clicked = fn end
    function kb:OnChanged(fn) kb.Changed = fn fn(kb.Value) end

    function kb:Destroy()
        elem:Destroy()
        lib.Options[id] = nil
    end

    Creator.AddSignal(bindBtn.MouseButton1Click, function()
        if isMobile then
            -- On Mobile: tap directly toggles or triggers!
            kb.Toggled = not kb.Toggled
            lib:SafeCallback(kb.Callback, kb.Toggled)
            if kb.Clicked then lib:SafeCallback(kb.Clicked, kb.Toggled) end
        else
            -- On Desktop: listen for keypress
            listening = true
            bindLabel.Text = "..."
            local conn
            conn = Creator.AddSignal(UserInputService.InputBegan, function(inp)
                if inp.UserInputType == Enum.UserInputType.Keyboard then
                    listening = false
                    kb.Value = inp.KeyCode.Name
                    bindLabel.Text = kb.Value
                    lib:SafeCallback(kb.ChangedCallback, inp.KeyCode)
                    if kb.Changed then lib:SafeCallback(kb.Changed, inp.KeyCode) end
                    conn:Disconnect()
                end
            end)
        end
    end)

    Creator.AddSignal(UserInputService.InputBegan, function(inp)
        if not listening and not UserInputService:GetFocusedTextBox() then
            if kb.Mode == "Toggle" and inp.UserInputType == Enum.UserInputType.Keyboard and inp.KeyCode.Name == kb.Value then
                kb.Toggled = not kb.Toggled
                lib:SafeCallback(kb.Callback, kb.Toggled)
                if kb.Clicked then lib:SafeCallback(kb.Clicked, kb.Toggled) end
            end
        end
    end)

    lib.Options[id] = kb
    return kb
end

-- Colorpicker (Mobile-Friendly Compact Dialog)
function Elements.AddColorpicker(container, arg1, arg2)
    local id, config = parseArgs(arg1, arg2)
    assert(config.Title, "Colorpicker - Missing Title")
    assert(config.Default, "Colorpicker - Missing Default")
    local lib = container.Library
    local cp = {
        Value = config.Default,
        Transparency = config.Transparency or 0,
        Type = "Colorpicker",
        Callback = config.Callback or function() end
    }

    local elem = CreateElement(config.Title, config.Description, container.Container, true)
    elem.LabelHolder.Size = UDim2.new(1, -70, 0, 0)
    cp.SetTitle = function(_, t) elem:SetTitle(t) end
    cp.SetDesc = function(_, d) elem:SetDesc(d) end

    local colorPreview = Creator.New("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = cp.Value
    }, {
        Creator.New("UICorner", { CornerRadius = UDim.new(0, 5) })
    })

    local previewBtn = Creator.New("TextButton", {
        Text = "",
        Size = UDim2.fromOffset(36, 24),
        Position = UDim2.new(1, -12, 0.5, 0),
        AnchorPoint = Vector2.new(1, 0.5),
        Parent = elem.Frame,
        BackgroundTransparency = 1
    }, {
        Creator.New("UICorner", { CornerRadius = UDim.new(0, 5) }),
        Creator.New("UIStroke", {
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            Thickness = 1.2,
            Transparency = 0.5,
            ThemeTag = { Color = "InElementBorder" }
        }),
        colorPreview
    })

    function cp:OnChanged(fn)
        cp.Changed = fn
        fn(cp.Value)
    end

    function cp:SetValue(col)
        cp.Value = col
        colorPreview.BackgroundColor3 = col
        lib:SafeCallback(cp.Callback, cp.Value)
        if cp.Changed then lib:SafeCallback(cp.Changed, cp.Value) end
    end

    function cp:SetValueRGB(col, trans)
        cp.Value = col
        cp.Transparency = trans or cp.Transparency
        colorPreview.BackgroundColor3 = col
        lib:SafeCallback(cp.Callback, cp.Value)
        if cp.Changed then lib:SafeCallback(cp.Changed, cp.Value) end
    end

    function cp:Destroy()
        elem:Destroy()
        lib.Options[id] = nil
    end

    -- Compact Colorpicker Dialog
    Creator.AddSignal(elem.Frame.MouseButton1Click, function()
        local h, s, v = Color3.toHSV(cp.Value)
        local curH, curS, curV = h, s, v

        local dialogTint = Creator.New("TextButton", {
            Text = "",
            Size = UDim2.fromScale(1, 1),
            BackgroundColor3 = Color3.fromRGB(0, 0, 0),
            BackgroundTransparency = 0.5,
            Parent = lib.GUI,
            ZIndex = 90
        })

        local cpBox = Creator.New("Frame", {
            Size = UDim2.fromOffset(280, 220),
            Position = UDim2.fromScale(0.5, 0.5),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Parent = dialogTint,
            ThemeTag = { BackgroundColor3 = "Dialog" }
        }, {
            Creator.New("UICorner", { CornerRadius = UDim.new(0, 10) }),
            Creator.New("UIStroke", {
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                Thickness = 1.2,
                ThemeTag = { Color = "DialogBorder" }
            })
        })

        -- Title
        Creator.New("TextLabel", {
            FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
            Text = config.Title,
            TextSize = 14,
            Position = UDim2.fromOffset(14, 12),
            Size = UDim2.new(1, -28, 0, 18),
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = cpBox,
            ThemeTag = { TextColor3 = "Text" }
        })

        -- SV Palette Box
        local svCursor = Creator.New("ImageLabel", {
            Image = Assets.Circle,
            Size = UDim2.fromOffset(12, 12),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(curS, 0, 1 - curV, 0),
            ThemeTag = { ImageColor3 = "Text" }
        })

        local svBox = Creator.New("ImageLabel", {
            Image = "rbxassetid://4155801252",
            Size = UDim2.fromOffset(170, 130),
            Position = UDim2.fromOffset(14, 38),
            BackgroundColor3 = Color3.fromHSV(curH, 1, 1),
            Parent = cpBox
        }, {
            Creator.New("UICorner", { CornerRadius = UDim.new(0, 6) }),
            svCursor
        })

        -- Hue Slider Bar
        local hueKeypoints = {}
        for i = 0, 10 do
            table.insert(hueKeypoints, ColorSequenceKeypoint.new(i / 10, Color3.fromHSV(i / 10, 1, 1)))
        end

        local hueCursor = Creator.New("Frame", {
            Size = UDim2.new(1, 4, 0, 4),
            Position = UDim2.new(0.5, 0, curH, 0),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        }, { Creator.New("UICorner", { CornerRadius = UDim.new(1, 0) }) })

        local hueBar = Creator.New("Frame", {
            Size = UDim2.fromOffset(18, 130),
            Position = UDim2.fromOffset(196, 38),
            Parent = cpBox
        }, {
            Creator.New("UICorner", { CornerRadius = UDim.new(0, 6) }),
            Creator.New("UIGradient", {
                Rotation = 90,
                Color = ColorSequence.new(hueKeypoints)
            }),
            hueCursor
        })

        -- Live Swatch
        local swatch = Creator.New("Frame", {
            Size = UDim2.fromOffset(36, 36),
            Position = UDim2.fromOffset(226, 38),
            BackgroundColor3 = cp.Value,
            Parent = cpBox
        }, {
            Creator.New("UICorner", { CornerRadius = UDim.new(0, 6) }),
            Creator.New("UIStroke", { ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Thickness = 1, ThemeTag = { Color = "InElementBorder" } })
        })

        -- Apply Button
        local applyBtn = Creator.New("TextButton", {
            Text = "Done",
            Size = UDim2.fromOffset(68, 30),
            Position = UDim2.fromOffset(198, 176),
            Parent = cpBox,
            ThemeTag = { BackgroundColor3 = "Accent" }
        }, {
            Creator.New("UICorner", { CornerRadius = UDim.new(0, 6) }),
            Creator.New("TextLabel", {
                FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal),
                Text = "Done",
                TextSize = 12,
                Size = UDim2.fromScale(1, 1),
                TextColor3 = Color3.fromRGB(255, 255, 255)
            })
        })

        local function updateColor()
            local c = Color3.fromHSV(curH, curS, curV)
            svBox.BackgroundColor3 = Color3.fromHSV(curH, 1, 1)
            svCursor.Position = UDim2.new(curS, 0, 1 - curV, 0)
            hueCursor.Position = UDim2.new(0.5, 0, curH, 0)
            swatch.BackgroundColor3 = c
        end

        -- SV Touch Drag
        local svDrag = false
        Creator.AddSignal(svBox.InputBegan, function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
                svDrag = true
                local relX = math_clamp((inp.Position.X - svBox.AbsolutePosition.X) / svBox.AbsoluteSize.X, 0, 1)
                local relY = math_clamp((inp.Position.Y - svBox.AbsolutePosition.Y) / svBox.AbsoluteSize.Y, 0, 1)
                curS = relX
                curV = 1 - relY
                updateColor()
            end
        end)

        -- Hue Touch Drag
        local hueDrag = false
        Creator.AddSignal(hueBar.InputBegan, function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
                hueDrag = true
                curH = math_clamp((inp.Position.Y - hueBar.AbsolutePosition.Y) / hueBar.AbsoluteSize.Y, 0, 1)
                updateColor()
            end
        end)

        Creator.AddSignal(UserInputService.InputChanged, function(inp)
            if svDrag and (inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseMovement) then
                local relX = math_clamp((inp.Position.X - svBox.AbsolutePosition.X) / svBox.AbsoluteSize.X, 0, 1)
                local relY = math_clamp((inp.Position.Y - svBox.AbsolutePosition.Y) / svBox.AbsoluteSize.Y, 0, 1)
                curS = relX
                curV = 1 - relY
                updateColor()
            elseif hueDrag and (inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseMovement) then
                curH = math_clamp((inp.Position.Y - hueBar.AbsolutePosition.Y) / hueBar.AbsoluteSize.Y, 0, 1)
                updateColor()
            end
        end)

        Creator.AddSignal(UserInputService.InputEnded, function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
                svDrag = false
                hueDrag = false
            end
        end)

        Creator.AddSignal(applyBtn.MouseButton1Click, function()
            cp:SetValue(Color3.fromHSV(curH, curS, curV))
            dialogTint:Destroy()
        end)

        Creator.AddSignal(dialogTint.MouseButton1Click, function()
            dialogTint:Destroy()
        end)
    end)

    cp:SetValue(cp.Value)
    lib.Options[id] = cp
    return cp
end

-- Paragraph
function Elements.AddParagraph(container, config)
    assert(config.Title, "Paragraph - Missing Title")
    local elem = CreateElement(config.Title, config.Content, container.Container, false)
    elem.LabelHolder.Size = UDim2.new(1, -24, 0, 0)
    return elem
end

-- Section
function Elements.AddSection(container, title)
    local section = {
        Container = container.Container,
        ScrollFrame = container.ScrollFrame,
        Library = container.Library
    }
    
    local header = Creator.New("Frame", {
        Size = UDim2.new(1, 0, 0, 28),
        BackgroundTransparency = 1,
        Parent = container.Container
    }, {
        Creator.New("TextLabel", {
            FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
            Text = title or "Section",
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            Size = UDim2.new(1, 0, 1, 0),
            ThemeTag = { TextColor3 = "Accent" }
        })
    })

    section.AddButton = function(_, cfg) return Elements.AddButton(section, cfg) end
    section.AddToggle = function(_, arg1, arg2) return Elements.AddToggle(section, arg1, arg2) end
    section.AddSlider = function(_, arg1, arg2) return Elements.AddSlider(section, arg1, arg2) end
    section.AddDropdown = function(_, arg1, arg2) return Elements.AddDropdown(section, arg1, arg2) end
    section.AddInput = function(_, arg1, arg2) return Elements.AddInput(section, arg1, arg2) end
    section.AddKeybind = function(_, arg1, arg2) return Elements.AddKeybind(section, arg1, arg2) end
    section.AddColorpicker = function(_, arg1, arg2) return Elements.AddColorpicker(section, arg1, arg2) end
    section.AddParagraph = function(_, cfg) return Elements.AddParagraph(section, cfg) end
    section.AddSection = function(_, titleText) return Elements.AddSection(section, titleText) end

    return setmetatable(section, { __index = container })
end

-- ============================================================================
-- Tab System
-- ============================================================================
local Tab = { Tabs = {}, Containers = {}, SelectedTab = 0, Window = nil }
function Tab:Init(window)
    self.Window = window
    self.Tabs = {}
    self.Containers = {}
    self.SelectedTab = 0
    return self
end

function Tab:New(title, iconName, parentHolder)
    local win = self.Window
    local tabIndex = #self.Tabs + 1
    local tabObj = {
        Index = tabIndex,
        Title = title,
        Selected = false
    }

    local iconAsset = Fluent:GetIcon(iconName)
    local tabBtn = Creator.New("TextButton", {
        Size = UDim2.new(1, 0, 0, 38),
        Parent = parentHolder,
        ThemeTag = { BackgroundColor3 = "Tab" }
    }, {
        Creator.New("UICorner", { CornerRadius = UDim.new(0, 6) }),
        Creator.New("ImageLabel", {
            Image = iconAsset or "",
            Size = UDim2.fromOffset(18, 18),
            Position = UDim2.new(0, 10, 0.5, 0),
            AnchorPoint = Vector2.new(0, 0.5),
            Visible = (iconAsset ~= nil),
            ThemeTag = { ImageColor3 = "Text" }
        }),
        Creator.New("TextLabel", {
            FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal),
            Text = title or "Tab",
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            Position = iconAsset and UDim2.fromOffset(36, 0) or UDim2.fromOffset(12, 0),
            Size = iconAsset and UDim2.new(1, -40, 1, 0) or UDim2.new(1, -16, 1, 0),
            ThemeTag = { TextColor3 = "Text" }
        })
    })

    -- Container Scrolling Frame
    local containerLayout = Creator.New("UIListLayout", {
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder
    })

    local containerFrame = Creator.New("ScrollingFrame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        ScrollBarThickness = 3,
        BorderSizePixel = 0,
        Visible = false,
        Parent = win.ContainerHolder,
        CanvasSize = UDim2.fromScale(0, 0)
    }, {
        containerLayout,
        Creator.New("UIPadding", {
            PaddingLeft = UDim.new(0, 2),
            PaddingRight = UDim.new(0, 8),
            PaddingTop = UDim.new(0, 4),
            PaddingBottom = UDim.new(0, 8)
        })
    })

    Creator.AddSignal(containerLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
        containerFrame.CanvasSize = UDim2.fromOffset(0, containerLayout.AbsoluteContentSize.Y + 16)
    end)

    local _, setTrans = Creator.SpringMotor(1, tabBtn, "BackgroundTransparency")
    tabObj.Frame = tabBtn
    tabObj.SetTransparency = setTrans
    tabObj.Container = containerFrame
    tabObj.ScrollFrame = containerFrame
    tabObj.Library = Fluent

    Creator.AddSignal(tabBtn.MouseButton1Click, function()
        self:SelectTab(tabIndex)
        if win.IsMobileView and win.TabsExpanded then
            win:ToggleTabs(false)
        end
    end)

    table.insert(self.Tabs, tabObj)
    table.insert(self.Containers, containerFrame)

    -- Attach Element Methods
    tabObj.AddButton = function(_, cfg) return Elements.AddButton(tabObj, cfg) end
    tabObj.AddToggle = function(_, arg1, arg2) return Elements.AddToggle(tabObj, arg1, arg2) end
    tabObj.AddSlider = function(_, arg1, arg2) return Elements.AddSlider(tabObj, arg1, arg2) end
    tabObj.AddDropdown = function(_, arg1, arg2) return Elements.AddDropdown(tabObj, arg1, arg2) end
    tabObj.AddInput = function(_, arg1, arg2) return Elements.AddInput(tabObj, arg1, arg2) end
    tabObj.AddKeybind = function(_, arg1, arg2) return Elements.AddKeybind(tabObj, arg1, arg2) end
    tabObj.AddColorpicker = function(_, arg1, arg2) return Elements.AddColorpicker(tabObj, arg1, arg2) end
    tabObj.AddParagraph = function(_, cfg) return Elements.AddParagraph(tabObj, cfg) end
    tabObj.AddSection = function(_, titleText) return Elements.AddSection(tabObj, titleText) end

    return tabObj
end

function Tab:SelectTab(idx)
    if self.Tabs[idx] then
        self.SelectedTab = idx
        for i, tab in ipairs(self.Tabs) do
            tab.Selected = (i == idx)
            tab.SetTransparency(i == idx and 0.85 or 1)
        end
        for i, cont in ipairs(self.Containers) do
            cont.Visible = (i == idx)
        end
        self.Window.TabTitleLabel.Text = self.Tabs[idx].Title
    end
end

-- ============================================================================
-- Window & TitleBar System (Mobile-Adaptive)
-- ============================================================================
function Fluent:CreateWindow(config)
    assert(config.Title, "CreateWindow - Missing Title")
    if Fluent.Window then
        print("[Fluent]: A window already exists.")
        return Fluent.Window
    end

    local vp = Camera and Camera.ViewportSize or Vector2.new(800, 600)
    local isMobileView = isSmallScreen()

    -- Window Dimensions
    local winW = config.Size and config.Size.X.Offset or 560
    local winH = config.Size and config.Size.Y.Offset or 440
    local tabW = config.TabWidth or 150

    if isMobileView and config.AutoScaling ~= false then
        winW = math_clamp(math.min(winW, vp.X - 24), 320, 560)
        winH = math_clamp(math.min(winH, vp.Y - 24), 240, 380)
    end

    local posX = math.max(10, math.floor((vp.X - winW) / 2))
    local posY = math.max(10, math.floor((vp.Y - winH) / 2))

    local window = {
        Size = UDim2.fromOffset(winW, winH),
        Position = UDim2.fromOffset(posX, posY),
        Minimized = false,
        Maximized = false,
        TabsExpanded = not isMobileView,
        IsMobileView = isMobileView
    }

    -- Create ScreenGui
    local screenGui = Creator.New("ScreenGui", {
        Name = "FluentMobileSuite",
        Parent = getGuiParent()
    })
    protect_gui(screenGui)
    Fluent.GUI = screenGui
    Notification:Init(screenGui)

    -- Window Frosted Glass Base
    local paint = Acrylic.CreatePaint(10)
    local root = Creator.New("Frame", {
        Name = "WindowRoot",
        Size = window.Size,
        Position = window.Position,
        BackgroundTransparency = 1,
        Parent = screenGui
    }, { paint.Frame })

    window.Root = root
    window.Paint = paint

    -- TitleBar
    local titleBar = Creator.New("Frame", {
        Name = "TitleBar",
        Size = UDim2.new(1, 0, 0, 42),
        BackgroundTransparency = 1,
        Parent = root
    }, {
        Creator.New("Frame", {
            Name = "Line",
            Size = UDim2.new(1, 0, 0, 1),
            Position = UDim2.new(0, 0, 1, -1),
            ThemeTag = { BackgroundColor3 = "TitleBarLine" }
        })
    })

    -- Hamburger / Tab Drawer Toggle Button for Mobile
    local menuToggleBtn = Creator.New("TextButton", {
        Name = "MenuToggleBtn",
        Size = UDim2.fromOffset(30, 30),
        Position = UDim2.fromOffset(8, 6),
        BackgroundTransparency = 1,
        Parent = titleBar
    }, {
        Creator.New("UICorner", { CornerRadius = UDim.new(0, 6) }),
        Creator.New("ImageLabel", {
            Image = Assets.Menu,
            Size = UDim2.fromOffset(18, 18),
            Position = UDim2.fromScale(0.5, 0.5),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            ThemeTag = { ImageColor3 = "Text" }
        })
    })

    -- Title & Subtitle Labels
    local titleLabel = Creator.New("TextLabel", {
        FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
        Text = config.Title,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = isMobileView and UDim2.fromOffset(42, 13) or UDim2.fromOffset(14, 13),
        Size = UDim2.new(0, 0, 0, 16),
        AutomaticSize = Enum.AutomaticSize.X,
        Parent = titleBar,
        ThemeTag = { TextColor3 = "Text" }
    })

    local subTitleLabel = Creator.New("TextLabel", {
        FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
        Text = config.SubTitle or "",
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.new(1, 6, 0, 1),
        Size = UDim2.new(0, 0, 1, 0),
        AutomaticSize = Enum.AutomaticSize.X,
        Parent = titleLabel,
        ThemeTag = { TextColor3 = "SubText" }
    })

    -- Window Controls (Minimize & Close)
    local closeBtn = Creator.New("TextButton", {
        Size = UDim2.fromOffset(30, 30),
        Position = UDim2.new(1, -36, 0, 6),
        BackgroundTransparency = 1,
        Parent = titleBar
    }, {
        Creator.New("UICorner", { CornerRadius = UDim.new(0, 6) }),
        Creator.New("ImageLabel", {
            Image = Assets.Close,
            Size = UDim2.fromOffset(14, 14),
            Position = UDim2.fromScale(0.5, 0.5),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            ThemeTag = { ImageColor3 = "Text" }
        })
    })

    local minBtn = Creator.New("TextButton", {
        Size = UDim2.fromOffset(30, 30),
        Position = UDim2.new(1, -70, 0, 6),
        BackgroundTransparency = 1,
        Parent = titleBar
    }, {
        Creator.New("UICorner", { CornerRadius = UDim.new(0, 6) }),
        Creator.New("ImageLabel", {
            Image = Assets.Min,
            Size = UDim2.fromOffset(14, 14),
            Position = UDim2.fromScale(0.5, 0.5),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            ThemeTag = { ImageColor3 = "Text" }
        })
    })

    -- Tabs Sidebar / Drawer
    local tabSidebar = Creator.New("Frame", {
        Name = "TabSidebar",
        Size = UDim2.new(0, tabW, 1, -50),
        Position = UDim2.fromOffset(10, 46),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        Parent = root,
        ZIndex = 5
    })

    local tabLayout = Creator.New("UIListLayout", {
        Padding = UDim.new(0, 4),
        SortOrder = Enum.SortOrder.LayoutOrder
    })

    local tabScroll = Creator.New("ScrollingFrame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        ScrollBarThickness = 2,
        BorderSizePixel = 0,
        Parent = tabSidebar,
        CanvasSize = UDim2.fromScale(0, 0)
    }, { tabLayout })

    Creator.AddSignal(tabLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
        tabScroll.CanvasSize = UDim2.fromOffset(0, tabLayout.AbsoluteContentSize.Y + 8)
    end)

    -- Tab Title Display & Content Holder
    local tabTitleDisplay = Creator.New("TextLabel", {
        FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
        Text = "Tab",
        TextSize = 18,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = isMobileView and UDim2.fromOffset(14, 46) or UDim2.fromOffset(tabW + 24, 46),
        Size = UDim2.new(1, -(tabW + 36), 0, 22),
        Parent = root,
        ThemeTag = { TextColor3 = "Text" }
    })
    window.TabTitleLabel = tabTitleDisplay

    local contentHolder = Creator.New("Frame", {
        Name = "ContainerHolder",
        Size = isMobileView and UDim2.new(1, -28, 1, -80) or UDim2.new(1, -(tabW + 36), 1, -80),
        Position = isMobileView and UDim2.fromOffset(14, 72) or UDim2.fromOffset(tabW + 24, 72),
        BackgroundTransparency = 1,
        Parent = root
    })
    window.ContainerHolder = contentHolder

    -- Sidebar Collapse / Expand Toggle
    function window:ToggleTabs(expanded)
        if expanded == nil then
            window.TabsExpanded = not window.TabsExpanded
        else
            window.TabsExpanded = expanded
        end

        if window.TabsExpanded then
            tabSidebar.Visible = true
            TweenService:Create(tabSidebar, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Position = UDim2.fromOffset(10, 46),
                Size = UDim2.new(0, tabW, 1, -50)
            }):Play()
            if window.IsMobileView then
                tabSidebar.BackgroundColor3 = Creator.GetThemeProperty("AcrylicMain")
                tabSidebar.BackgroundTransparency = 0.05
            end
        else
            TweenService:Create(tabSidebar, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, 0, 1, -50)
            }):Play()
            task.delay(0.2, function()
                if not window.TabsExpanded then tabSidebar.Visible = false end
            end)
        end
    end

    Creator.AddSignal(menuToggleBtn.MouseButton1Click, function()
        window:ToggleTabs()
    end)

    if isMobileView then
        tabSidebar.Visible = false
    end

    -- TitleBar Dragging with Screen Edge Clamping
    local isDragging = false
    local dragStart = Vector2.new()
    local startPos = UDim2.new()

    local posMotor = GroupMotor.new({ X = window.Position.X.Offset, Y = window.Position.Y.Offset })
    posMotor:onStep(function(p)
        root.Position = UDim2.fromOffset(p.X, p.Y)
    end)

    Creator.AddSignal(titleBar.InputBegan, function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            isDragging = true
            dragStart = Vector2.new(inp.Position.X, inp.Position.Y)
            startPos = root.Position

            local moveConn, endConn
            moveConn = Creator.AddSignal(UserInputService.InputChanged, function(moveInp)
                if isDragging and (moveInp.UserInputType == Enum.UserInputType.MouseMovement or moveInp.UserInputType == Enum.UserInputType.Touch) then
                    local delta = Vector2.new(moveInp.Position.X, moveInp.Position.Y) - dragStart
                    local curVp = Camera and Camera.ViewportSize or Vector2.new(800, 600)
                    local maxX = math.max(0, curVp.X - root.AbsoluteSize.X)
                    local maxY = math.max(0, curVp.Y - root.AbsoluteSize.Y)

                    local newX = math_clamp(startPos.X.Offset + delta.X, 0, maxX)
                    local newY = math_clamp(startPos.Y.Offset + delta.Y, 0, maxY)

                    posMotor:setGoal({
                        X = Instant.new(newX),
                        Y = Instant.new(newY)
                    })
                end
            end)

            endConn = Creator.AddSignal(UserInputService.InputEnded, function(endInp)
                if endInp.UserInputType == Enum.UserInputType.MouseButton1 or endInp.UserInputType == Enum.UserInputType.Touch then
                    isDragging = false
                    if moveConn then pcall(function() moveConn:Disconnect() end) end
                    if endConn then pcall(function() endConn:Disconnect() end) end
                end
            end)
        end
    end)

    -- Dynamic Viewport Re-clamping (e.g. mobile screen rotation)
    if Camera then
        Creator.AddSignal(Camera:GetPropertyChangedSignal("ViewportSize"), function()
            local curVp = Camera.ViewportSize
            local curX = root.Position.X.Offset
            local curY = root.Position.Y.Offset
            local maxX = math.max(0, curVp.X - root.AbsoluteSize.X)
            local maxY = math.max(0, curVp.Y - root.AbsoluteSize.Y)
            if curX > maxX or curY > maxY then
                posMotor:setGoal({
                    X = Instant.new(math_clamp(curX, 0, maxX)),
                    Y = Instant.new(math_clamp(curY, 0, maxY))
                })
            end
        end)
    end

    -- Window Controls Callbacks
    function window:Toggle()
        window.Minimized = not window.Minimized
        root.Visible = not window.Minimized
    end

    function window:Minimize()
        window:Toggle()
    end

    function window:SetTitle(t)
        titleLabel.Text = tostring(t)
    end

    function window:SetSubTitle(st)
        subTitleLabel.Text = tostring(st)
    end

    function window:Destroy()
        screenGui:Destroy()
        Creator.Disconnect()
        Fluent.Window = nil
    end

    Creator.AddSignal(minBtn.MouseButton1Click, function()
        window:Minimize()
    end)

    Creator.AddSignal(closeBtn.MouseButton1Click, function()
        window:Dialog({
            Title = "Unload Interface",
            Content = "Are you sure you want to unload the interface?",
            Buttons = {
                { Title = "Yes", Callback = function() window:Destroy() end },
                { Title = "No" }
            }
        })
    end)

    -- PC Keyboard Keybind to Toggle
    if config.MinimizeKey then
        Fluent.MinimizeKey = config.MinimizeKey
    end
    Creator.AddSignal(UserInputService.InputBegan, function(inp)
        if not UserInputService:GetFocusedTextBox() and inp.KeyCode == Fluent.MinimizeKey then
            window:Toggle()
        end
    end)

    -- Built-in Draggable Floating Mobile Toggle Button
    if config.MobileToggle ~= false then
        Fluent:CreateMobileToggleButton(window, config)
    end

    -- Tab System Initializer
    local tabSys = Tab:Init(window)
    function window:AddTab(tabCfg)
        return tabSys:New(tabCfg.Title, tabCfg.Icon, tabScroll)
    end
    function window:SelectTab(idx)
        tabSys:SelectTab(idx or 1)
    end

    -- Dialog Initializer
    local dialogSys = Dialog:Init(window)
    function window:Dialog(dialogCfg)
        return dialogSys:Create(dialogCfg)
    end

    Fluent.Window = window
    Fluent:SetTheme(config.Theme or "Dark")
    return window
end

-- ============================================================================
-- Floating Mobile Toggle Button Component (Draggable & Animated)
-- ============================================================================
function Fluent:CreateMobileToggleButton(window, config)
    config = config or {}
    local iconId = config.MobileToggleIcon or "menu"
    local resolvedIcon = Fluent:GetIcon(iconId) or Assets.Menu
    local btnSize = config.MobileToggleSize or 46
    local defaultPos = config.MobileTogglePosition or UDim2.new(0, 16, 0.45, 0)

    local holder = Creator.New("Frame", {
        Name = "MobileToggleHolder",
        Size = UDim2.fromOffset(btnSize, btnSize),
        Position = defaultPos,
        BackgroundTransparency = 1,
        Parent = Fluent.GUI,
        ZIndex = 999
    })

    local scale = Creator.New("UIScale", { Scale = 1, Parent = holder })
    local scaleMotor = SingleMotor.new(1)
    scaleMotor:onStep(function(val) scale.Scale = val end)

    local button = Creator.New("ImageButton", {
        Name = "ToggleButton",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 0.2,
        Parent = holder,
        ThemeTag = { BackgroundColor3 = "AcrylicMain" }
    }, {
        Creator.New("UICorner", { CornerRadius = UDim.new(0, math.floor(btnSize * 0.28)) }),
        Creator.New("UIStroke", {
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            Thickness = 1.6,
            ThemeTag = { Color = "Accent" }
        }),
        Creator.New("ImageLabel", {
            Name = "Shadow",
            Image = Assets.Shadow,
            ScaleType = Enum.ScaleType.Slice,
            SliceCenter = Rect.new(99, 99, 99, 99),
            Size = UDim2.new(1, 24, 1, 24),
            Position = UDim2.fromScale(0.5, 0.5),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            ImageColor3 = Color3.fromRGB(0, 0, 0),
            ImageTransparency = 0.6,
            ZIndex = 0
        }),
        Creator.New("ImageLabel", {
            Name = "Icon",
            Size = UDim2.fromOffset(math.floor(btnSize * 0.52), math.floor(btnSize * 0.52)),
            Position = UDim2.fromScale(0.5, 0.5),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            Image = resolvedIcon,
            ThemeTag = { ImageColor3 = "Text" }
        })
    })

    -- Touch Dragging & Tap Detection
    local dragging = false
    local touchStart = Vector2.new()
    local frameStart = UDim2.new()
    local movedDistance = 0
    local activeInput = nil

    local function updatePosition(inputPos)
        local delta = inputPos - touchStart
        movedDistance = delta.Magnitude
        local newX = frameStart.X.Offset + delta.X
        local newY = frameStart.Y.Offset + delta.Y

        local vp = Camera and Camera.ViewportSize or Vector2.new(800, 600)
        newX = math_clamp(newX, 6, vp.X - btnSize - 6)
        newY = math_clamp(newY, 6, vp.Y - btnSize - 6)
        holder.Position = UDim2.fromOffset(newX, newY)
    end

    Creator.AddSignal(button.InputBegan, function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            activeInput = inp
            touchStart = Vector2.new(inp.Position.X, inp.Position.Y)
            frameStart = holder.Position
            movedDistance = 0
            scaleMotor:setGoal(Spring.new(0.88, { frequency = 10, dampingRatio = 0.75 }))

            local changedConn, endedConn
            changedConn = Creator.AddSignal(UserInputService.InputChanged, function(moveInp)
                if dragging and (moveInp == activeInput or moveInp.UserInputType == Enum.UserInputType.Touch or moveInp.UserInputType == Enum.UserInputType.MouseMovement) then
                    updatePosition(Vector2.new(moveInp.Position.X, moveInp.Position.Y))
                end
            end)

            endedConn = Creator.AddSignal(UserInputService.InputEnded, function(endInp)
                if endInp == activeInput or (endInp.UserInputType == Enum.UserInputType.MouseButton1 or endInp.UserInputType == Enum.UserInputType.Touch) then
                    dragging = false
                    activeInput = nil
                    scaleMotor:setGoal(Spring.new(1, { frequency = 8, dampingRatio = 0.7 }))
                    if movedDistance < 8 then
                        window:Toggle()
                    end
                    if changedConn then pcall(function() changedConn:Disconnect() end) end
                    if endedConn then pcall(function() endedConn:Disconnect() end) end
                end
            end)
        end
    end)

    window.MobileToggleButton = holder
    window.ToggleMobileButton = function(_, visible)
        holder.Visible = visible
    end
    window.SetMobileButtonPosition = function(_, udim)
        holder.Position = udim
    end

    return holder
end

-- ============================================================================
-- Theme Management Methods
-- ============================================================================
function Fluent:SetTheme(themeName)
    if Fluent.Themes[themeName] then
        Fluent.Theme = themeName
        Creator.UpdateTheme()
    end
end

function Fluent:AddTheme(themeConfig)
    assert(themeConfig.Name, "AddTheme - Missing theme Name")
    Fluent.Themes[themeConfig.Name] = themeConfig
    if Fluent.Theme == themeConfig.Name then
        Creator.UpdateTheme()
    end
end

function Fluent:Destroy()
    if Fluent.Window then
        Fluent.Window:Destroy()
    end
end

-- Global Registration
if getgenv then
    getgenv().Fluent = Fluent
end

return Fluent

end)()

return function(ctx)
    ctx.Fluent = Fluent
    return Fluent
end
]=],
	["ui/pages.lua"] = [=[
--[[ pages.lua — halaman garden. Tab: Pet, Elephant, Growth, Leveling, Mutation, Event, Inventory, Shop, Misc.
     Isi utama ada di tab Inventory (Automation Trade + Automation Accept + Automation Favourite). ]]
return function(ctx)
	local C = ctx.C
	local F = ctx.F
	local CFG = ctx.CFG
	local mk, corner, stroke, pad = ctx.mk, ctx.corner, ctx.stroke, ctx.pad
	local persist = ctx.persistState
	local reg = ctx.reg
	local function log(m) ctx.log(m) end

	-- True kalau GuiObject benar-benar kelihatan di layar (tab aktif + accordion kebuka
	-- + window ga diminimize). Dipakai supaya loop status berhenti hitung/redraw label
	-- yang lagi nggak dilihat — cegah layout-thrashing yang bikin CPU naik.
	local function onScreen(o)
		while o and o ~= game do
			if o:IsA("GuiObject") and not o.Visible then return false end
			o = o.Parent
		end
		return o == game
	end

	local makePage = ctx.makePage
	local makeAccordion = ctx.makeAccordion
	local makeToggle = ctx.makeToggle
	local makeInput = ctx.makeInput
	local makeSingleDropdown = ctx.makeSingleDropdown
	local makeMultiDropdown = ctx.makeMultiDropdown
	local makeMultiDropdownDyn = ctx.makeMultiDropdownDyn
	local makeButton = ctx.makeButton
	local makeSubTabs = ctx.makeSubTabs
	local makeStartStopBar = ctx.makeStartStopBar

	local FIXED_TABS = {
		Hatch = true, Flow = true, Shop = true, Elephant = true,
		Pet = true, Inventory = true, Leveling = true, Mutation = true,
		Farm = true, Misc = true,
	}
	-- sidebar tabs (urut sesuai referensi)
	local TABS = {
		{ "Pet", "Pet", "🐾" },
		{ "Farm", "Farm", "🌾" },
		{ "Hatch", "Hatch", "🥚" },
		{ "Elephant", "Elephant", "🐘" },
		{ "Flow", "Flow", "🌱" },
		{ "Leveling", "Leveling", "⚡" },
		{ "Mutation", "Mutation", "🧪" },
		{ "Inventory", "Inventory", "🎒" },
		{ "Shop", "Shop", "🛒" },
		{ "Misc", "Misc", "⚙️" },
	}
	local pageRef = {}
	for i, t in ipairs(TABS) do
		pageRef[t[1]] = makePage(t[1], t[2], t[3], i, FIXED_TABS[t[1]])
	end

	-- placeholder untuk tab yang belum diisi
	local function placeholder(page)
		local box = mk("Frame", { Size = UDim2.new(1, 0, 0, 90), BackgroundColor3 = C.row, LayoutOrder = 1 }, page)
		corner(box, 8); stroke(box); pad(box, 14, 14, 12, 12)
		mk("TextLabel", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "Fitur untuk tab ini belum tersedia.", Font = F.reg, TextSize = 13, TextColor3 = C.sub, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top }, box)
	end
	------------------------------------------------------------------ FARM
	do
		local farmPage = pageRef["Farm"]
		local farmSub = makeSubTabs(farmPage, {
			{ id = "plants",  name = "Plants" },
			{ id = "care",    name = "Sprinkler & Water" },
			{ id = "shovel",  name = "Shovel" },
			{ id = "harvest", name = "Harvest & Fav" },
		}, "plants", { hasBottomBar = false, hasInfoLine = false })

		local pFarmPlants  = farmSub.pages["plants"]
		local pFarmCare    = farmSub.pages["care"]
		local pFarmShovel  = farmSub.pages["shovel"]
		local pFarmHarvest = farmSub.pages["harvest"]

		-- Automation Plants (fitur aktif): pilih seed + posisi + delay + toggle
		local plAcc = makeAccordion(pFarmPlants, "Automation Plants", 1, true)
		makeMultiDropdownDyn(plAcc, "Select Seeds", "Pilih seed dari inventory (angka = jumlah).",
			function() return ctx.getPlantSeedOptions() end, CFG.plantSeedNames, function() persist() end, 1)
		makeSingleDropdown(plAcc, "Select Position", "Lokasi tanam di farm.",
			function() return { "Random", "Player Position" } end,
			function() return CFG.plantPosition end,
			function(v) CFG.plantPosition = v; persist() end, 2)
		makeInput(plAcc, "Delay To Plants", "Extra delay (detik) tiap tanam seed.",
			function() return tostring(CFG.plantDelay) end,
			function(t) CFG.plantDelay = tonumber(t) or 0; persist() end, 3)
		makeToggle(plAcc, "Auto Plants Seed", "Tanam seed terpilih otomatis.",
			function() return CFG.plantSeedEnabled end,
			function(v) CFG.plantSeedEnabled = v; persist(); if v and ctx.startPlant then ctx.startPlant() end end, 4)

		-- Automation Sprinkler (fitur aktif): pasang sprinkler + shovel sprinkler
		local sprAcc = makeAccordion(pFarmCare, "Automation Sprinkler", 1, true)
		makeMultiDropdownDyn(sprAcc, "Select Sprinkler", "Sprinkler yg mau dipasang (angka = jumlah).",
			function() return ctx.getSprinklerOptions() end, CFG.sprinklerNames, function() persist() end, 1)
		makeMultiDropdownDyn(sprAcc, "Select Sprinkler Plants", "Pasang dekat plant ini. Kosong = pakai Position.",
			function() return ctx.getSprinklerPlantOptions() end, CFG.sprinklerPlantNames, function() persist() end, 2)
		makeSingleDropdown(sprAcc, "Select Sprinkler Position", "Lokasi pasang kalau Plants kosong.",
			function() return { "Random", "Player Position" } end,
			function() return CFG.sprinklerPosition end,
			function(v) CFG.sprinklerPosition = v; persist() end, 3)
		makeInput(sprAcc, "Delay To Sprinkler", "Extra delay (detik) tiap pasang.",
			function() return tostring(CFG.sprinklerDelay) end,
			function(t) CFG.sprinklerDelay = tonumber(t) or 0; persist() end, 4)
		makeToggle(sprAcc, "Auto Sprinkler", "Pasang sprinkler terpilih otomatis.",
			function() return CFG.sprinklerEnabled end,
			function(v) CFG.sprinklerEnabled = v; persist(); if v and ctx.startSprinkler then ctx.startSprinkler() end end, 5)

		-- sub-accordion: Sprinkler Shovel (cabut sprinkler terpasang, butuh Shovel)
		local shAcc = makeAccordion(sprAcc, "Sprinkler Shovel", 6, false)
		makeMultiDropdownDyn(shAcc, "Select Shovel Sprinkler", "Jenis sprinkler terpasang yg mau dicabut. 'All' = semua.",
			function() return ctx.getShovelSprinklerOptions() end, CFG.shovelSprinklerNames, function() persist() end, 1)
		makeInput(shAcc, "Delay To Shovel Sprinkler", "Extra delay (detik) tiap cabut.",
			function() return tostring(CFG.shovelSprinklerDelay) end,
			function(t) CFG.shovelSprinklerDelay = tonumber(t) or 0; persist() end, 2)
		makeToggle(shAcc, "Auto Shovel Sprinkler", "Cabut sprinkler terpilih otomatis (equip Shovel).",
			function() return CFG.shovelSprinklerEnabled end,
			function(v) CFG.shovelSprinklerEnabled = v; persist(); if v and ctx.startShovelSprinkler then ctx.startShovelSprinkler() end end, 3)

		-- Automation Water (fitur aktif): siram plant terpilih pakai Watering Can (Water_RE)
		local watAcc = makeAccordion(pFarmCare, "Automation Water", 2, true)
		makeMultiDropdownDyn(watAcc, "Select Water Fruits", "Pilih fruit/plant yang mau disiram. 'All' = semua.",
			function() return ctx.getWaterFruitOptions() end, CFG.waterFruitNames, function() persist() end, 1)
		makeInput(watAcc, "Delay to Water", "Extra delay (detik) tiap siklus siram.",
			function() return tostring(CFG.waterDelay) end,
			function(t) CFG.waterDelay = tonumber(t) or 1; persist() end, 2)
		makeToggle(watAcc, "Auto Water Fruits", "Siram fruit terpilih otomatis.",
			function() return CFG.waterEnabled end,
			function(v) CFG.waterEnabled = v; persist(); if v and ctx.startWater then ctx.startWater() end end, 3)

		-- Automation Shovel (fitur aktif): shovel tree/plant + shovel fruit (filter)
		local shvAcc = makeAccordion(pFarmShovel, "Automation Shovel", 1, true)
		makeMultiDropdownDyn(shvAcc, "Select Tree", "Pilih tree/plant yang mau di-shovel. 'All' = semua.",
			function() return ctx.getShovelTreeOptions() end, CFG.shovelTreeNames, function() persist() end, 1)
		makeInput(shvAcc, "Delay To Shovel Tree", "Extra delay (detik) tiap siklus shovel tree.",
			function() return tostring(CFG.shovelTreeDelay) end,
			function(t) CFG.shovelTreeDelay = tonumber(t) or 0; persist() end, 2)
		makeToggle(shvAcc, "Auto Shovel Tree", "Shovel tree/plant terpilih otomatis.",
			function() return CFG.shovelTreeEnabled end,
			function(v) CFG.shovelTreeEnabled = v; persist(); if v and ctx.startShovelTree then ctx.startShovelTree() end end, 3)

		-- sub: Fruits Shovel (shovel plant kalau fruit-nya cocok filter)
		local frShv = makeAccordion(shvAcc, "Fruits Shovel", 4, false)
		makeMultiDropdownDyn(frShv, "Select Shovel Fruits", "Tipe fruit yang mau di-shovel. 'All' = semua.",
			function() return ctx.getShovelFruitOptions() end, CFG.shovelFruitNames, function() persist() end, 1)
		makeMultiDropdownDyn(frShv, "Select Shovel Mutation", "Filter mutasi. Kosong/'All' = abaikan.",
			function() return ctx.getShovelMutationOptions() end, CFG.shovelFruitMuts, function() persist() end, 2)
		makeMultiDropdownDyn(frShv, "Select Shovel Variant", "Filter variant (Gold/Rainbow/dll). Kosong/'All' = abaikan.",
			function() return ctx.getShovelVariantOptions() end, CFG.shovelFruitVariants, function() persist() end, 3)
		makeSingleDropdown(frShv, "Select Shovel Threshold Mode", "Cara banding berat fruit.",
			function() return ctx.getShovelModeOptions() end,
			function() return CFG.shovelFruitMode end,
			function(v) CFG.shovelFruitMode = v; persist() end, 4)
		makeInput(frShv, "Shovel Weight Threshold", "Kalau ga mau pakai, isi '0'.",
			function() return tostring(CFG.shovelFruitWeight) end,
			function(t) CFG.shovelFruitWeight = tonumber(t) or 0; persist() end, 5)
		makeInput(frShv, "Delay To Shovel Fruit", "Extra delay (detik) tiap siklus shovel fruit.",
			function() return tostring(CFG.shovelFruitDelay) end,
			function(t) CFG.shovelFruitDelay = tonumber(t) or 0; persist() end, 6)
		makeToggle(frShv, "Auto Shovel Fruits", "Shovel plant yang fruit-nya cocok filter.",
			function() return CFG.shovelFruitEnabled end,
			function(v) CFG.shovelFruitEnabled = v; persist(); if v and ctx.startShovelFruit then ctx.startShovelFruit() end end, 7)

		-- Automation Collection (fitur aktif): auto harvest fruit (3 mode whitelist)
		local colAcc = makeAccordion(pFarmHarvest, "Automation Collection", 1, true)
		makeInput(colAcc, "Delay To Collect", "Extra delay (detik) tiap siklus collect.",
			function() return tostring(CFG.collectDelay) end,
			function(t) CFG.collectDelay = tonumber(t) or 0; persist() end, 1)
		makeToggle(colAcc, "Stop Collect If Backpack Is Full Max", "Stop collect pas backpack penuh.",
			function() return CFG.collectStopIfFull end,
			function(v) CFG.collectStopIfFull = v; persist() end, 2)
		makeToggle(colAcc, "Auto Sell Fruit If Backpack Full", "Jual semua fruit pas backpack penuh.",
			function() return CFG.collectAutoSellIfFull end,
			function(v) CFG.collectAutoSellIfFull = v; persist() end, 3)

		-- sub: Whitelist Fruit
		local colWf = makeAccordion(colAcc, "Collect Whitelist Fruit", 4, false)
		makeMultiDropdownDyn(colWf, "Select Whitelist Fruit", "Pilih tipe fruit yang mau di-collect.",
			function() return ctx.getCollectFruitOptions() end, CFG.collectWlFruitNames, function() persist() end, 1)
		makeToggle(colWf, "Auto Collect Whitelisted Fruits", "Collect cuma tipe fruit yang di-whitelist.",
			function() return CFG.collectWlFruitEnabled end,
			function(v) CFG.collectWlFruitEnabled = v; persist(); if v and ctx.startCollect then ctx.startCollect() end end, 2)

		-- sub: Whitelist Mutation
		local colWm = makeAccordion(colAcc, "Collect Whitelist Mutation", 5, false)
		makeMultiDropdownDyn(colWm, "Select Whitelist Mutations", "Pilih mutasi yang mau di-collect.",
			function() return ctx.getCollectMutationOptions() end, CFG.collectWlMutNames, function() persist() end, 1)
		makeToggle(colWm, "Auto Collect Whitelisted Mutations", "Collect cuma fruit dgn mutasi yang di-whitelist.",
			function() return CFG.collectWlMutEnabled end,
			function(v) CFG.collectWlMutEnabled = v; persist(); if v and ctx.startCollect then ctx.startCollect() end end, 2)

		-- sub: Combined (semua kriteria)
		local colCb = makeAccordion(colAcc, "Collect Whitelist Combined", 6, false)
		makeMultiDropdownDyn(colCb, "Select Combined Fruits", "Filter by fruit type.",
			function() return ctx.getCollectFruitOptions() end, CFG.collectCombFruitNames, function() persist() end, 1)
		makeMultiDropdownDyn(colCb, "Select Combined Mutation", "Filter by mutation type.",
			function() return ctx.getCollectMutationOptions() end, CFG.collectCombMutNames, function() persist() end, 2)
		makeMultiDropdownDyn(colCb, "Select Combined Variant", "Filter by variant type.",
			function() return ctx.getCollectVariantOptions() end, CFG.collectCombVariants, function() persist() end, 3)
		makeSingleDropdown(colCb, "Whitelist Weight Mode", "Cara banding berat fruit.",
			function() return ctx.getCollectModeOptions() end,
			function() return CFG.collectCombMode end,
			function(v) CFG.collectCombMode = v; persist() end, 4)
		makeInput(colCb, "Whitelist Weight", "Kalau ga dipakai, isi '0'.",
			function() return tostring(CFG.collectCombWeight) end,
			function(t) CFG.collectCombWeight = tonumber(t) or 0; persist() end, 5)
		makeToggle(colCb, "Auto Collect Fruits", "Collect fruit yang cocok SEMUA kriteria combined.",
			function() return CFG.collectCombEnabled end,
			function(v) CFG.collectCombEnabled = v; persist(); if v and ctx.startCollect then ctx.startCollect() end end, 6)

		-- Automation Favorite (fitur aktif): favorite/unfavorite fruit via Favorite Tool
		local favAcc = makeAccordion(pFarmHarvest, "Automation Favorite", 2, false)
		makeMultiDropdownDyn(favAcc, "Select Fruits", "Tipe fruit di garden buat di-favorite (kosong = any).",
			function() return ctx.getFavFruitOptions() end, CFG.favFruitNames, function() persist() end, 1)
		makeMultiDropdownDyn(favAcc, "Filter Mutations", "Mutasi yang diperluin (kosong = mutasi apapun OK).",
			function() return ctx.getFavMutationOptions() end, CFG.favMutNames, function() persist() end, 2)
		makeSingleDropdown(favAcc, "Weight Mode", "Banding berat fruit (kosong = off).",
			function() return ctx.getFavModeOptions() end,
			function() return CFG.favMode end,
			function(v) CFG.favMode = v; persist() end, 3)
		makeInput(favAcc, "Weight Value", "Threshold berat (0 = off).",
			function() return tostring(CFG.favWeight) end,
			function(t) CFG.favWeight = tonumber(t) or 0; persist() end, 4)
		makeInput(favAcc, "Delay To Favorite", "Detik tiap siklus scan favorite.",
			function() return tostring(CFG.favDelay) end,
			function(t) CFG.favDelay = tonumber(t) or 1; persist() end, 5)
		makeToggle(favAcc, "Auto Favorite Fruits", "Favorite fruit garden yang cocok filter.",
			function() return CFG.favEnabled end,
			function(v) CFG.favEnabled = v; persist(); if v and ctx.startFavorite then ctx.startFavorite() end end, 6)
		makeToggle(favAcc, "Auto Unfavorite Fruits", "Unfavorite fruit garden yang cocok filter.",
			function() return CFG.unfavEnabled end,
			function(v) CFG.unfavEnabled = v; persist(); if v and ctx.startFavorite then ctx.startFavorite() end end, 7)

		-- Automation Reclaimer (fitur aktif): pilih plant + toggle auto reclaim
		local recAcc = makeAccordion(pFarmHarvest, "Automation Reclaimer", 3, false)
		makeMultiDropdownDyn(recAcc, "Select Plants", "Pilih plant yg mau di-reclaim. 'All' = semua.",
			function() return ctx.getReclaimPlantOptions() end, CFG.reclaimPlantNames, function() persist() end, 1)
		makeToggle(recAcc, "Auto Reclaimer Plants", "Auto reclaim plant terpilih pakai tool Reclaimer",
			function() return CFG.reclaimEnabled end,
			function(v) CFG.reclaimEnabled = v; persist(); if v and ctx.startReclaim then ctx.startReclaim() end end, 2)
	end

	------------------------------------------------------------------ FLOW (pipeline batch per-step)
	do
		local flowPage = pageRef["Flow"] or pageRef["Growth"]
		local FLOW_OPTS = { { name = "none", display = "None (kosong)" }, { name = "elephant", display = "Elephant" }, { name = "mutation", display = "Mutation" }, { name = "leveling", display = "Leveling" }, { name = "leveling_p1", display = "Leveling Phase 1" }, { name = "leveling_p2", display = "Leveling Phase 2" } }
		local function capStep(s) for _, o in ipairs(FLOW_OPTS) do if o.name == s then return o.display end end return "Select" end

		local sub = makeSubTabs(flowPage, {
			{ id = "flow",     name = "Flow Config" },
			{ id = "elephant", name = "Elephant" },
			{ id = "mutation", name = "Mutation" },
			{ id = "leveling", name = "Leveling" },
		}, "flow", { hasBottomBar = true, hasInfoLine = false })

		-- 1) FLOW CONFIG
		local pFlow = sub.pages["flow"]
		local gMainAcc = makeAccordion(pFlow, "Flow Controls & Targets", 1, true)
		makeMultiDropdown(gMainAcc, "Flow Target Pet Types (Default)", "Target default; dipakai step yg target per-method-nya kosong",
			reg.PET_OPTIONS, CFG.growthPetTypes, function() persist() end, 1)

		local gFlow = makeAccordion(pFlow, "Configuration Flow", 2, true)
		local stepDesc = { "First step in pipeline flow", "Second step in pipeline flow", "Third step in pipeline flow", "Fourth step in pipeline flow", "Fifth step in pipeline flow", "Sixth step in pipeline flow", }
		for i = 1, 6 do
			makeSingleDropdown(gFlow, "Step " .. i, stepDesc[i],
				function() return FLOW_OPTS end,
				function() return capStep((CFG.growthFlow or {})[i]) end,
				function(code) CFG.growthFlow = CFG.growthFlow or {}; CFG.growthFlow[i] = code; persist() end, i)
		end

		-- 2) ELEPHANT STEP
		local pEle = sub.pages["elephant"]
		local gEle = makeAccordion(pEle, "Configuration Auto Elephant", 1, true)
		makeMultiDropdown(gEle, "Elephant Target Pet Types", "Target khusus step Elephant (kosong = pakai Default)",
			reg.PET_OPTIONS, CFG.growthPetTypesElephant, function() persist() end, 0)
		makeMultiDropdownDyn(gEle, "Elephant Pet Team", "Team aura buat grow weight",
			function() return ctx.inventoryPetOptions(CFG.growthElephantTeam) end, CFG.growthElephantTeam, function() persist() end, 1)
		makeInput(gEle, "Target Weight (KG)", "Berat target sebelum lanjut step berikutnya (mis. 5.5)",
			function() return tostring(CFG.growthElephantWeight) end, function(t) CFG.growthElephantWeight = tonumber(t) or 5.5; persist() end, 2)
		makeInput(gEle, "Max Target Pets", "Max pet target di garden (step Elephant)",
			function() return tostring(CFG.growthElephantMax) end, function(t) CFG.growthElephantMax = tonumber(t) or 2; persist() end, 3)

		-- 3) MUTATION STEP
		local pMut = sub.pages["mutation"]
		local gMut = makeAccordion(pMut, "Configuration Auto Mutation", 1, true)
		makeMultiDropdown(gMut, "Mutation Target Pet Types", "Target khusus step Mutation (kosong = pakai Default)",
			reg.PET_OPTIONS, CFG.growthPetTypesMutation, function() persist() end, 0)
		makeMultiDropdownDyn(gMut, "Mutation Pet Team", "Team aura pemberi mutasi",
			function() return ctx.inventoryPetOptions(CFG.growthMutationTeam) end, CFG.growthMutationTeam, function() persist() end, 1)
		makeMultiDropdown(gMut, "Target Mutations", "Mutasi yang diinginkan (mutasi salah -> auto cleanse)",
			reg.MUT_OPTIONS, CFG.growthMutationTargets, function() persist() end, 2)
		makeInput(gMut, "Max Target Pets", "Max pet target di garden (step Mutation)",
			function() return tostring(CFG.growthMutationMax) end, function(t) CFG.growthMutationMax = tonumber(t) or 2; persist() end, 3)

		-- 4) LEVELING STEP
		local pLev = sub.pages["leveling"]
		local gLev = makeAccordion(pLev, "Configuration Auto Leveling", 1, true)
		makeMultiDropdown(gLev, "Leveling Target Pet Types", "Target khusus step Leveling (kosong = pakai Default)",
			reg.PET_OPTIONS, CFG.growthPetTypesLeveling, function() persist() end, 0)
		makeMultiDropdownDyn(gLev, "Leveling Phase 1 Pet Team", "Team for Phase 1 (Age 1 to Phase 1 Target)",
			function() return ctx.inventoryPetOptions(CFG.growthLevP1Team) end, CFG.growthLevP1Team, function() persist() end, 1)
		makeInput(gLev, "Leveling Phase 1 Target", "End of Phase 1 / start of Phase 2 (default 40)",
			function() return tostring(CFG.growthLevP1Target) end, function(t) CFG.growthLevP1Target = tonumber(t) or 40; persist() end, 2)
		makeInput(gLev, "Leveling Phase 1 Max Pets", "Max target pets in garden during Phase 1",
			function() return tostring(CFG.growthLevP1Max) end, function(t) CFG.growthLevP1Max = tonumber(t) or 3; persist() end, 3)
		makeMultiDropdownDyn(gLev, "Leveling Phase 2 Pet Team", "Team for Phase 2 (Phase 1 Target to Final Target)",
			function() return ctx.inventoryPetOptions(CFG.growthLevP2Team) end, CFG.growthLevP2Team, function() persist() end, 4)
		makeInput(gLev, "Leveling Phase 2 Target", "Final target level (default 500 = max age)",
			function() return tostring(CFG.growthLevP2Target) end, function(t) CFG.growthLevP2Target = tonumber(t) or 500; persist() end, 5)
		makeInput(gLev, "Leveling Phase 2 Max Pets", "Max target pets in garden during Phase 2",
			function() return tostring(CFG.growthLevP2Max) end, function(t) CFG.growthLevP2Max = tonumber(t) or 1; persist() end, 6)

		-- Start / Stop Bar (PATEN DI BAWAH)
		makeStartStopBar(sub.bottomBarFrame or flowPage,
			function() return CFG.growthEnabled end,
			function()
				CFG.growthEnabled = true
				persist()
				ctx.startGrowth()
			end,
			function()
				CFG.growthEnabled = false
				persist()
				ctx.stopGrowth()
			end, 999)
	end

	------------------------------------------------------------------ HATCH (auto hatch + auto sell)
	do
		local hatchPage = pageRef["Hatch"]

		local sub = makeSubTabs(hatchPage, {
			{ id = "core",   name = "Main Team" },
			{ id = "bronto", name = "Bronto Team" },
			{ id = "hatch",  name = "Hatch Team" },
			{ id = "sell",   name = "Sell Team" },
			{ id = "config", name = "Config" },
		}, "core", { hasBottomBar = true, hasInfoLine = true })

		-- Helper live updater info line: 🐾 Main (0)  🦕 Bronto (0)  🥚 Hatch (0)  💰 Sell (0)
		local function countTeam(t)
			local c = 0
			if type(t) == "table" then
				for k, v in pairs(t) do
					if v == true or (type(v) == "table" and next(v)) then c = c + 1 end
				end
			end
			return c
		end

		local function updateHatchInfoLine()
			if not sub.infoLabel then return end
			local mCount = countTeam(CFG.hatchCoreTeam)
			local bCount = countTeam(CFG.hatchBrontoTeam)
			local hCount = countTeam(CFG.hatchHatchTeam)
			local sCount = countTeam(CFG.hatchSellTeam)
			sub.infoLabel.Text = ("🐾 <font color=\"#ffffff\"><b>Main (%d)</b></font>   🦕 <font color=\"#ffffff\"><b>Bronto (%d)</b></font>   🥚 <font color=\"#ffffff\"><b>Hatch (%d)</b></font>   💰 <font color=\"#ffffff\"><b>Sell (%d)</b></font>"):format(mCount, bCount, hCount, sCount)
		end
		updateHatchInfoLine()

		-- 1) MAIN / CORE TEAM SUB-TAB
		local pCore = sub.pages["core"]
		local cDelayAcc = makeAccordion(pCore, "( Main Team ) Delay Settings", 1, true)
		makeInput(cDelayAcc, "Delay Equip (sec)", "Jeda antar pet pas equip Main team",
			function() return tostring(CFG.hatchCoreEquipDelay or 0) end,
			function(t) CFG.hatchCoreEquipDelay = tonumber(t) or 0; persist() end, 1)
		makeInput(cDelayAcc, "Delay Unequip (sec)", "Jeda antar pet pas unequip Main team",
			function() return tostring(CFG.hatchCoreUnequipDelay or 1) end,
			function(t) CFG.hatchCoreUnequipDelay = tonumber(t) or 1; persist() end, 2)

		local cPetAcc = makeAccordion(pCore, "Select Pet (Main Team)", 2, true)
		makeMultiDropdownDyn(cPetAcc, "Core Team (Main)", "Percepat egg (incubation speed)",
			function() return ctx.inventoryPetOptions(CFG.hatchCoreTeam) end, CFG.hatchCoreTeam,
			function() persist(); updateHatchInfoLine() end, 1)

		-- 2) BRONTO TEAM SUB-TAB
		local pBronto = sub.pages["bronto"]
		local bDelayAcc = makeAccordion(pBronto, "( Bronto Team ) Delay Settings", 1, true)
		makeInput(bDelayAcc, "Delay Equip (sec)", "Jeda antar pet pas equip Bronto team",
			function() return tostring(CFG.hatchBrontoEquipDelay or 0) end,
			function(t) CFG.hatchBrontoEquipDelay = tonumber(t) or 0; persist() end, 1)
		makeInput(bDelayAcc, "Delay Unequip (sec)", "Jeda antar pet pas unequip Bronto team",
			function() return tostring(CFG.hatchBrontoUnequipDelay or 1) end,
			function(t) CFG.hatchBrontoUnequipDelay = tonumber(t) or 1; persist() end, 2)
		makeInput(bDelayAcc, "Bronto Team Delay (sec)", "Tunggu abis swap team sebelum hatch bronto",
			function() return tostring(CFG.brontoTeamDelay or 5.5) end,
			function(t) CFG.brontoTeamDelay = tonumber(t) or 5.5; persist() end, 3)

		local bPetAcc = makeAccordion(pBronto, "Select Pet (Bronto Team)", 2, true)
		makeMultiDropdownDyn(bPetAcc, "Bronto Team", "+30% berat pet pas hatch (Brontosaurus)",
			function() return ctx.inventoryPetOptions(CFG.hatchBrontoTeam) end, CFG.hatchBrontoTeam,
			function() persist(); updateHatchInfoLine() end, 1)

		-- 3) HATCH TEAM SUB-TAB
		local pHatch = sub.pages["hatch"]
		local hDelayAcc = makeAccordion(pHatch, "( Hatch Team ) Delay Settings", 1, true)
		makeInput(hDelayAcc, "Delay Equip (sec)", "Jeda antar pet pas equip Hatch team",
			function() return tostring(CFG.hatchTeamEquipDelay or 0) end,
			function(t) CFG.hatchTeamEquipDelay = tonumber(t) or 0; persist() end, 1)
		makeInput(hDelayAcc, "Delay Unequip (sec)", "Jeda antar pet pas unequip Hatch team",
			function() return tostring(CFG.hatchTeamUnequipDelay or 1) end,
			function(t) CFG.hatchTeamUnequipDelay = tonumber(t) or 1; persist() end, 2)
		makeInput(hDelayAcc, "Hatch Team Delay (sec)", "Tunggu abis swap team sebelum hatch",
			function() return tostring(CFG.hatchTeamDelay or 5.5) end,
			function(t) CFG.hatchTeamDelay = tonumber(t) or 5.5; persist() end, 3)

		local hPetAcc = makeAccordion(pHatch, "Select Pet (Hatch Team)", 2, true)
		makeMultiDropdownDyn(hPetAcc, "Hatch Team", "Hatch egg ready (Koi = balikin egg)",
			function() return ctx.inventoryPetOptions(CFG.hatchHatchTeam) end, CFG.hatchHatchTeam,
			function() persist(); updateHatchInfoLine() end, 1)

		-- 4) SELL TEAM SUB-TAB
		local pSell = sub.pages["sell"]
		local sDelayAcc = makeAccordion(pSell, "( Sell Team ) Delay Settings", 1, true)
		makeInput(sDelayAcc, "Delay Equip (sec)", "Jeda antar pet pas equip Sell team",
			function() return tostring(CFG.hatchSellEquipDelay or 0) end,
			function(t) CFG.hatchSellEquipDelay = tonumber(t) or 0; persist() end, 1)
		makeInput(sDelayAcc, "Delay Unequip (sec)", "Jeda antar pet pas unequip Sell team",
			function() return tostring(CFG.hatchSellUnequipDelay or 1) end,
			function(t) CFG.hatchSellUnequipDelay = tonumber(t) or 1; persist() end, 2)
		makeInput(sDelayAcc, "Sell Team Delay (sec)", "Tunggu abis swap team sebelum jual",
			function() return tostring(CFG.sellTeamDelay or 5.5) end,
			function(t) CFG.sellTeamDelay = tonumber(t) or 5.5; persist() end, 3)
		makeToggle(sDelayAcc, "Auto Boost Before Sell", "Boost pet aktif pakai toy sebelum jual",
			function() return CFG.autoBoostBeforeSell end,
			function(v) CFG.autoBoostBeforeSell = v; persist() end, 4)

		local sPetAcc = makeAccordion(pSell, "Select Pet (Sell Team)", 2, true)
		makeMultiDropdownDyn(sPetAcc, "Sell Team", "Jual + balikin pet jadi egg (Seal the Deal)",
			function() return ctx.inventoryPetOptions(CFG.hatchSellTeam) end, CFG.hatchSellTeam,
			function() persist(); updateHatchInfoLine() end, 1)

		-- 5) CONFIG SUB-TAB (Sell & Bronto Table exact as Node Hub + Bulk + Egg Config)
		local pCfg = sub.pages["config"]

		-- Sell & Bronto Table Accordion
		local sCfgAcc = makeAccordion(pCfg, "Sell & Bronto Configuration", 1, true)

		-- Info Card
		local infoCard = mk("Frame", {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundColor3 = C.panel,
			LayoutOrder = 1,
		}, sCfgAcc)
		corner(infoCard, 8)
		stroke(infoCard, C.strokeSub, 1, 0.4)
		pad(infoCard, 8, 8, 8, 8)
		mk("TextLabel", {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Text = "- Weight < KG -> mengikuti pengaturan tombol KEEP / SELL.\n- Weight >= KG -> KEEP + BRONTO (otomatis di-hatch pakai Bronto team + disimpan aman).",
			Font = F.reg,
			TextSize = 11,
			TextColor3 = C.txt,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true,
			LineHeight = 1.3,
		}, infoCard)

		-- Auto Sell Enable Toggle
		makeToggle(sCfgAcc, "Auto Sell Pets", "Jual otomatis pet di backpack sesuai pengaturan",
			function() return CFG.autoSellEnabled end,
			function(v) CFG.autoSellEnabled = v; persist() end, 2)

		-- Sell Trigger Mode row: Cycle | Total Pets (Backpack)
		local trigRow = mk("Frame", {
			Size = UDim2.new(1, 0, 0, 36),
			BackgroundTransparency = 1,
			LayoutOrder = 3,
		}, sCfgAcc)
		mk("TextLabel", {
			Size = UDim2.new(0, 110, 1, 0),
			BackgroundTransparency = 1,
			Text = "Sell Trigger :",
			Font = F.bold,
			TextSize = 12,
			TextColor3 = C.txt,
			TextXAlignment = Enum.TextXAlignment.Left,
		}, trigRow)

		local trigContainer = mk("Frame", {
			Size = UDim2.new(1, -110, 0, 28),
			Position = UDim2.new(0, 110, 0.5, -14),
			BackgroundTransparency = 1,
		}, trigRow)
		mk("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, 6),
			VerticalAlignment = Enum.VerticalAlignment.Center,
		}, trigContainer)

		local bTrigCycle = mk("TextButton", {
			Size = UDim2.new(0.5, -3, 1, 0),
			BackgroundColor3 = C.row,
			Text = "By Cycle",
			Font = F.bold,
			TextSize = 12,
			TextColor3 = C.sub,
			AutoButtonColor = false,
			LayoutOrder = 1,
		}, trigContainer)
		corner(bTrigCycle, 6)
		local sTrigCycleStroke = stroke(bTrigCycle, C.strokeSub, 1, 0.5)

		local bTrigBp = mk("TextButton", {
			Size = UDim2.new(0.5, -3, 1, 0),
			BackgroundColor3 = C.row,
			Text = "Total Pet (BP)",
			Font = F.bold,
			TextSize = 12,
			TextColor3 = C.sub,
			AutoButtonColor = false,
			LayoutOrder = 2,
		}, trigContainer)
		corner(bTrigBp, 6)
		local sTrigBpStroke = stroke(bTrigBp, C.strokeSub, 1, 0.5)

		-- Threshold Rows:
		-- 1) Sell Every N Cycles row
		local cycleRow = mk("Frame", {
			Size = UDim2.new(1, 0, 0, 32),
			BackgroundTransparency = 1,
			LayoutOrder = 4,
		}, sCfgAcc)
		mk("TextLabel", {
			Size = UDim2.new(1, -70, 1, 0),
			BackgroundTransparency = 1,
			Text = "Sell Tiap Berapa Cycle (Hatch Round) :",
			Font = F.bold,
			TextSize = 11.5,
			TextColor3 = C.txt,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
		}, cycleRow)
		local cycleBoxFrame = mk("Frame", {
			Size = UDim2.fromOffset(56, 26),
			Position = UDim2.new(1, -58, 0.5, -13),
			BackgroundColor3 = C.panel,
		}, cycleRow)
		corner(cycleBoxFrame, 6)
		stroke(cycleBoxFrame, C.strokeSub, 1, 0.5)
		local cycleBox = mk("TextBox", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Text = tostring(CFG.sellEveryNCycles or 1),
			Font = F.bold,
			TextSize = 12,
			TextColor3 = C.txt,
			ClearTextOnFocus = false,
			TextXAlignment = Enum.TextXAlignment.Center,
		}, cycleBoxFrame)
		cycleBox.FocusLost:Connect(function()
			CFG.sellEveryNCycles = math.max(1, tonumber(cycleBox.Text) or 1)
			cycleBox.Text = tostring(CFG.sellEveryNCycles)
			persist()
		end)

		-- 2) Activation row: Auto Sell Aktif Saat Total Pet
		local actRow = mk("Frame", {
			Size = UDim2.new(1, 0, 0, 32),
			BackgroundTransparency = 1,
			LayoutOrder = 5,
		}, sCfgAcc)
		local actLbl = mk("TextLabel", {
			Size = UDim2.new(1, -70, 1, 0),
			BackgroundTransparency = 1,
			Text = "Auto Sell Aktif Saat Total Pet :",
			Font = F.bold,
			TextSize = 11.5,
			TextColor3 = C.txt,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
		}, actRow)
		local actBoxFrame = mk("Frame", {
			Size = UDim2.fromOffset(56, 26),
			Position = UDim2.new(1, -58, 0.5, -13),
			BackgroundColor3 = C.panel,
		}, actRow)
		corner(actBoxFrame, 6)
		stroke(actBoxFrame, C.strokeSub, 1, 0.5)
		local actBox = mk("TextBox", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Text = tostring(CFG.sellWhenReach or 24),
			Font = F.bold,
			TextSize = 12,
			TextColor3 = C.txt,
			ClearTextOnFocus = false,
			TextXAlignment = Enum.TextXAlignment.Center,
		}, actBoxFrame)
		actBox.FocusLost:Connect(function()
			CFG.sellWhenReach = tonumber(actBox.Text) or 24
			actBox.Text = tostring(CFG.sellWhenReach)
			persist()
		end)

		local function updateSellTriggerBtns()
			local isCycle = (CFG.sellMode == "Cycle")
			bTrigCycle.BackgroundColor3 = isCycle and C.rowAlt or C.panel
			bTrigCycle.TextColor3 = isCycle and Color3.new(1, 1, 1) or C.txt
			sTrigCycleStroke.Color = isCycle and C.acc or C.strokeSub

			bTrigBp.BackgroundColor3 = (not isCycle) and C.rowAlt or C.panel
			bTrigBp.TextColor3 = (not isCycle) and Color3.new(1, 1, 1) or C.txt
			sTrigBpStroke.Color = (not isCycle) and C.acc or C.strokeSub

			cycleRow.Visible = isCycle
			actRow.Visible = not isCycle
		end
		updateSellTriggerBtns()

		bTrigCycle.MouseButton1Click:Connect(function()
			CFG.sellMode = "Cycle"
			persist()
			updateSellTriggerBtns()
		end)
		bTrigBp.MouseButton1Click:Connect(function()
			CFG.sellMode = "Backpack"
			persist()
			updateSellTriggerBtns()
		end)

		-- Sell Style row: Sell One By One | Sell All
		local modeRow = mk("Frame", {
			Size = UDim2.new(1, 0, 0, 36),
			BackgroundTransparency = 1,
			LayoutOrder = 6,
		}, sCfgAcc)
		mk("TextLabel", {
			Size = UDim2.new(0, 110, 1, 0),
			BackgroundTransparency = 1,
			Text = "Sell Style :",
			Font = F.bold,
			TextSize = 12,
			TextColor3 = C.txt,
			TextXAlignment = Enum.TextXAlignment.Left,
		}, modeRow)

		local modeContainer = mk("Frame", {
			Size = UDim2.new(1, -110, 0, 28),
			Position = UDim2.new(0, 110, 0.5, -14),
			BackgroundTransparency = 1,
		}, modeRow)
		mk("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, 6),
			VerticalAlignment = Enum.VerticalAlignment.Center,
		}, modeContainer)

		local bOneByOne = mk("TextButton", {
			Size = UDim2.new(0.5, -3, 1, 0),
			BackgroundColor3 = C.row,
			Text = "Sell One By One",
			Font = F.bold,
			TextSize = 12,
			TextColor3 = C.sub,
			AutoButtonColor = false,
			LayoutOrder = 1,
		}, modeContainer)
		corner(bOneByOne, 6)
		local sOneStroke = stroke(bOneByOne, C.strokeSub, 1, 0.5)

		local bSellAll = mk("TextButton", {
			Size = UDim2.new(0.5, -3, 1, 0),
			BackgroundColor3 = C.row,
			Text = "Sell All",
			Font = F.bold,
			TextSize = 12,
			TextColor3 = C.sub,
			AutoButtonColor = false,
			LayoutOrder = 2,
		}, modeContainer)
		corner(bSellAll, 6)
		local sAllStroke = stroke(bSellAll, C.strokeSub, 1, 0.5)

		local function updateSellModeBtns()
			local isAll = (CFG.sellStyle == "All at Once")
			bOneByOne.BackgroundColor3 = (not isAll) and C.rowAlt or C.panel
			bOneByOne.TextColor3 = (not isAll) and Color3.new(1, 1, 1) or C.txt
			sOneStroke.Color = (not isAll) and C.acc or C.strokeSub

			bSellAll.BackgroundColor3 = isAll and C.rowAlt or C.panel
			bSellAll.TextColor3 = isAll and Color3.new(1, 1, 1) or C.txt
			sAllStroke.Color = isAll and C.acc or C.strokeSub
		end
		updateSellModeBtns()

		bOneByOne.MouseButton1Click:Connect(function()
			CFG.sellStyle = "One by One"
			persist()
			updateSellModeBtns()
		end)
		bSellAll.MouseButton1Click:Connect(function()
			CFG.sellStyle = "All at Once"
			persist()
			updateSellModeBtns()
		end)

		-- Search Bar for Configured Pets Table
		local searchRow = mk("Frame", {
			Size = UDim2.new(1, 0, 0, 32),
			BackgroundColor3 = C.panel,
			LayoutOrder = 7,
		}, sCfgAcc)
		corner(searchRow, 6)
		stroke(searchRow, C.strokeSub, 1, 0.4)
		pad(searchRow, 8, 8, 0, 0)
		local sellTableSearch = mk("TextBox", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			PlaceholderText = "Search Pet Name...",
			PlaceholderColor3 = C.sub,
			Text = "",
			Font = F.reg,
			TextSize = 13,
			TextColor3 = C.txt,
			ClearTextOnFocus = false,
			TextXAlignment = Enum.TextXAlignment.Left,
		}, searchRow)

		-- Dynamic Pet List Table Container
		local tableListFrame = mk("Frame", {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			LayoutOrder = 8,
		}, sCfgAcc)
		mk("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 4),
		}, tableListFrame)

		local tableRows = {}

		local function rebuildSellTable()
			for _, r in ipairs(tableRows) do
				if r.frame then r.frame:Destroy() end
			end
			tableRows = {}

			CFG.hatchSellList = CFG.hatchSellList or {}

			local sortedKeys = {}
			for k in pairs(CFG.hatchSellList) do sortedKeys[#sortedKeys + 1] = k end
			table.sort(sortedKeys)

			local q = sellTableSearch.Text:lower()

			for i, petName in ipairs(sortedKeys) do
				local rule = CFG.hatchSellList[petName]
				if rule and type(rule) == "table" then
					local petLower = petName:lower()
					local visible = (q == "" or petLower:find(q, 1, true) ~= nil)

					local rowFrame = mk("Frame", {
						Size = UDim2.new(1, 0, 0, 32),
						BackgroundColor3 = C.panel,
						Visible = visible,
						LayoutOrder = i,
					}, tableListFrame)
					corner(rowFrame, 6)
					stroke(rowFrame, C.strokeSub, 1, 0.3)
					pad(rowFrame, 8, 6, 0, 0)

					-- Left: Pet Name + Sub Rule Text
					local nameCol = mk("Frame", {
						Size = UDim2.new(1, -198, 1, 0),
						BackgroundTransparency = 1,
					}, rowFrame)
					local pNameLbl = mk("TextLabel", {
						Size = UDim2.new(1, 0, 0, 17),
						Position = UDim2.new(0, 0, 0, 0),
						BackgroundTransparency = 1,
						Text = (rule.special and "<font color=\"#ffd700\">★ </font>" or "") .. petName,
						Font = F.bold,
						TextSize = 13,
						TextColor3 = C.txt,
						TextXAlignment = Enum.TextXAlignment.Left,
						TextTruncate = Enum.TextTruncate.AtEnd,
						RichText = true,
					}, nameCol)

					local subRuleLbl = mk("TextLabel", {
						Size = UDim2.new(1, 0, 0, 14),
						Position = UDim2.new(0, 0, 0, 16),
						BackgroundTransparency = 1,
						Font = F.reg,
						TextSize = 10.5,
						TextXAlignment = Enum.TextXAlignment.Left,
						RichText = true,
					}, nameCol)

					local function updateRuleText()
						local curKg = tonumber(rule.kg) or 0.8
						local curAction = tostring(rule.action or "KEEP"):upper()
						local col = curAction == "KEEP" and "#6ef5b9" or "#ff4b78"
						if rule.special then
							subRuleLbl.Text = string.format("<font color=\"#ffd700\"><b>★ SPECIAL</b></font> <font color=\"#ebd0eb\">| &lt; %.2f</font> <font color=\"%s\"><b>%s</b></font> <font color=\"#ebd0eb\">| &gt;= %.2f BRONTO+KEEP</font>", curKg, col, curAction, curKg)
						else
							subRuleLbl.Text = string.format("<font color=\"#ebd0eb\">&lt; %.2f</font> <font color=\"%s\"><b>%s</b></font> <font color=\"#ebd0eb\">| &gt;= %.2f BRONTO + KEEP</font>", curKg, col, curAction, curKg)
						end
					end
					updateRuleText()

					-- Star button (Special Pet toggle) [ ★ ] / [ ☆ ]
					local starBtn = mk("TextButton", {
						Size = UDim2.fromOffset(26, 24),
						Position = UDim2.new(1, -192, 0.5, -12),
						BackgroundColor3 = rule.special and Color3.fromRGB(60, 48, 15) or C.row,
						Text = rule.special and "★" or "☆",
						Font = F.bold,
						TextSize = 14,
						TextColor3 = rule.special and Color3.fromRGB(255, 215, 0) or C.sub,
						AutoButtonColor = false,
					}, rowFrame)
					corner(starBtn, 5)
					local starStroke = stroke(starBtn, rule.special and Color3.fromRGB(255, 215, 0) or C.strokeSub, 1, rule.special and 0.3 or 0.6)

					local function updateStarUI()
						local isSpec = (rule.special == true)
						starBtn.Text = isSpec and "★" or "☆"
						starBtn.TextColor3 = isSpec and Color3.fromRGB(255, 215, 0) or C.sub
						starBtn.BackgroundColor3 = isSpec and Color3.fromRGB(60, 48, 15) or C.row
						starStroke.Color = isSpec and Color3.fromRGB(255, 215, 0) or C.strokeSub
						starStroke.Transparency = isSpec and 0.3 or 0.6
						pNameLbl.Text = (isSpec and "<font color=\"#ffd700\">★ </font>" or "") .. petName
					end

					starBtn.MouseButton1Click:Connect(function()
						rule.special = not (rule.special == true)
						persist()
						updateStarUI()
						updateRuleText()
					end)

					-- KG input box [ 0.8 ]
					local kgFrame = mk("Frame", {
						Size = UDim2.fromOffset(46, 24),
						Position = UDim2.new(1, -160, 0.5, -12),
						BackgroundColor3 = C.row,
					}, rowFrame)
					corner(kgFrame, 5)
					stroke(kgFrame, C.strokeSub, 1, 0.5)
					local kgBox = mk("TextBox", {
						Size = UDim2.fromScale(1, 1),
						BackgroundTransparency = 1,
						Text = tostring(rule.kg or 0.8),
						Font = F.bold,
						TextSize = 12.5,
						TextColor3 = C.txt,
						ClearTextOnFocus = false,
						TextXAlignment = Enum.TextXAlignment.Center,
					}, kgFrame)
					kgBox.FocusLost:Connect(function()
						rule.kg = tonumber(kgBox.Text) or 0.8
						kgBox.Text = tostring(rule.kg)
						persist()
						updateRuleText()
					end)

					-- Action button [ KEEP ] / [ SELL ]
					local actBtn = mk("TextButton", {
						Size = UDim2.fromOffset(68, 24),
						Position = UDim2.new(1, -108, 0.5, -12),
						BackgroundColor3 = rule.action == "SELL" and Color3.fromRGB(120, 35, 35) or Color3.fromRGB(30, 85, 45),
						Text = tostring(rule.action or "KEEP"):upper(),
						Font = F.bold,
						TextSize = 11.5,
						TextColor3 = Color3.new(1, 1, 1),
						AutoButtonColor = false,
					}, rowFrame)
					corner(actBtn, 5)
					stroke(actBtn, rule.action == "SELL" and Color3.fromRGB(180, 50, 50) or Color3.fromRGB(50, 150, 70), 1, 0.4)

					actBtn.MouseButton1Click:Connect(function()
						if rule.action == "SELL" then
							rule.action = "KEEP"
							actBtn.Text = "KEEP"
							actBtn.BackgroundColor3 = Color3.fromRGB(30, 85, 45)
						else
							rule.action = "SELL"
							actBtn.Text = "SELL"
							actBtn.BackgroundColor3 = Color3.fromRGB(120, 35, 35)
						end
						persist()
						updateRuleText()
					end)

					-- Delete button [ - ]
					local delBtn = mk("TextButton", {
						Size = UDim2.fromOffset(26, 24),
						Position = UDim2.new(1, -34, 0.5, -12),
						BackgroundColor3 = Color3.fromRGB(100, 30, 30),
						Text = "-",
						Font = F.bold,
						TextSize = 14,
						TextColor3 = Color3.new(1, 1, 1),
						AutoButtonColor = false,
					}, rowFrame)
					corner(delBtn, 5)
					stroke(delBtn, Color3.fromRGB(160, 40, 40), 1, 0.4)

					delBtn.MouseButton1Click:Connect(function()
						CFG.hatchSellList[petName] = nil
						persist()
						rebuildSellTable()
					end)

					tableRows[#tableRows + 1] = { frame = rowFrame, name = petLower }
				end
			end
		end

		sellTableSearch:GetPropertyChangedSignal("Text"):Connect(function()
			local q = sellTableSearch.Text:lower()
			for _, r in ipairs(tableRows) do
				if r.frame then
					r.frame.Visible = (q == "" or r.name:find(q, 1, true) ~= nil)
				end
			end
		end)

		rebuildSellTable()

		-- Bulk Controls Below List
		local bulkPetSet = {}
		local bulkKgVal = 0.8
		local bulkActionVal = "sell"
		local bulkSpecialVal = false

		local updateBulkPetDd = makeMultiDropdown(sCfgAcc, "Select Pet Types (Bulk)", "Pilih beberapa jenis pet sekaligus",
			reg.PET_OPTIONS, bulkPetSet, nil, 9)

		makeInput(sCfgAcc, "KG (Bulk)", "Batas berat target pet",
			function() return tostring(bulkKgVal) end,
			function(t) bulkKgVal = tonumber(t) or 0.8 end, 10)

		local ACTION_OPTS = { { name = "sell", display = "sell" }, { name = "keep", display = "keep" } }
		makeSingleDropdown(sCfgAcc, "Below KG Action (Bulk)", "Aksi jika pet di bawah batas KG",
			function() return ACTION_OPTS end,
			function() return bulkActionVal end,
			function(code) bulkActionVal = code end, 11)

		makeToggle(sCfgAcc, "Special Pet (Bulk)", "Tandai pet terpilih sebagai Special Pet (★ Alert & Bronto count)",
			function() return bulkSpecialVal end,
			function(v) bulkSpecialVal = v end, 12)

		makeButton(sCfgAcc, "APPLY BULK LIST", "Terapkan setting ke semua pet terpilih di atas",
			function()
				CFG.hatchSellList = CFG.hatchSellList or {}
				local countApplied = 0
				for petName, isSel in pairs(bulkPetSet) do
					if isSel then
						CFG.hatchSellList[petName] = {
							kg = tonumber(bulkKgVal) or 0.8,
							action = tostring(bulkActionVal):upper(),
							special = bulkSpecialVal == true,
						}
						countApplied = countApplied + 1
					end
				end
				if countApplied > 0 then
					persist()
					rebuildSellTable()
					if ctx.log then ctx.log(("✦ Bulk config diterapkan untuk %d jenis pet"):format(countApplied)) end
				end
			end, 13)

		makeButton(sCfgAcc, "CLEAR BULK SELECTION", "Kosongkan checklist pet terpilih",
			function()
				for k in pairs(bulkPetSet) do bulkPetSet[k] = nil end
				bulkSpecialVal = false
				if updateBulkPetDd then updateBulkPetDd() end
			end, 14)

		-- Manual Sell Now button
		makeButton(sCfgAcc, "Sell Now (manual)", "Jalankan proses sell sekali sekarang",
			function() task.spawn(function() pcall(ctx.hatchDoSell) end) end, 15)

		makeToggle(sCfgAcc, "Don't Hatch Bronto Pets", "Skip pet yang memenuhi syarat Bronto (jangan di-hatch)",
			function() return CFG.brontoSkipSpecial end, function(v) CFG.brontoSkipSpecial = v; persist() end, 16)

		-- Egg Configuration Accordion
		local hEgg = makeAccordion(pCfg, "Egg Configuration", 2, false)
		makeSingleDropdown(hEgg, "Egg to Hatch", "Egg dari backpack yg di-place & di-hatch (+ jumlah)",
			function() return ctx.getEggBackpackOptions() end,
			function() return tostring(CFG.hatchEggName or "") end,
			function(code) CFG.hatchEggName = code; persist() end, 1)
		makeSingleDropdown(hEgg, "Placement Pattern", "Pola taro egg: Grid (rapih) / Random (sebar acak)",
			function() return { "Grid", "Random" } end,
			function() return CFG.hatchPlacePattern or "Grid" end,
			function(code) CFG.hatchPlacePattern = code; persist() end, 2)
		makeInput(hEgg, "Max Placed", "Maksimal egg ke-place di garden",
			function() return tostring(CFG.hatchMaxPlaced) end, function(t) CFG.hatchMaxPlaced = tonumber(t) or 8; persist() end, 3)
		makeToggle(hEgg, "Auto Rejoin on Egg Minus", "Auto rejoin server jika egg minus mencapai batas",
			function() return CFG.hatchRejoinMinusEnabled end,
			function(v)
				CFG.hatchRejoinMinusEnabled = v; persist()
				if v and ctx.startEggMinusWatcher then
					ctx.startEggMinusWatcher()
				elseif not v and not CFG.hatchRejoinPlusEnabled and ctx.stopEggMinusWatcher then
					ctx.stopEggMinusWatcher()
				end
			end, 4)
		makeInput(hEgg, "Egg Minus Threshold", "Batas jumlah minus untuk trigger rejoin (misal: 20)",
			function() return tostring(CFG.hatchRejoinMinusThreshold or 20) end,
			function(t) CFG.hatchRejoinMinusThreshold = tonumber(t) or 20; persist() end, 5)
		makeToggle(hEgg, "Auto Rejoin on Egg Plus", "Auto rejoin server jika egg bertambah mencapai batas",
			function() return CFG.hatchRejoinPlusEnabled end,
			function(v)
				CFG.hatchRejoinPlusEnabled = v; persist()
				if v and ctx.startEggMinusWatcher then
					ctx.startEggMinusWatcher()
				elseif not v and not CFG.hatchRejoinMinusEnabled and ctx.stopEggMinusWatcher then
					ctx.stopEggMinusWatcher()
				end
			end, 6)
		makeInput(hEgg, "Egg Plus Threshold", "Batas jumlah penambahan untuk trigger rejoin (misal: 20)",
			function() return tostring(CFG.hatchRejoinPlusThreshold or 20) end,
			function(t) CFG.hatchRejoinPlusThreshold = tonumber(t) or 20; persist() end, 7)

		-- START / STOP BAR (PATEN DI BAWAH HATCH PAGE)
		makeStartStopBar(sub.bottomBarFrame or hatchPage,
			function() return CFG.hatchEnabled end,
			function()
				CFG.hatchEnabled = true
				persist()
				ctx.startHatch()
			end,
			function()
				CFG.hatchEnabled = false
				persist()
				ctx.stopHatch()
			end, 999)
	end

	------------------------------------------------------------------ SHOP
	do
		local shopPage = pageRef["Shop"]

		local sub = makeSubTabs(shopPage, {
			{ id = "seed",     name = "Seeds" },
			{ id = "egg",      name = "Eggs" },
			{ id = "gear",     name = "Gears" },
			{ id = "merchant", name = "Merchant" },
			{ id = "premium",  name = "Premium" },
		}, "seed", 1)

		-- 1) SEEDS
		local pSeed = sub.pages["seed"]
		local seedAcc = makeAccordion(pSeed, "Automation Buy Seed", 1, true)
		makeMultiDropdownDyn(seedAcc, "Select Seeds to Buy", "Pilih seed buat auto-beli (stock realtime)",
			function() return ctx.getSeedShopOptions(CFG.buySeedNames) end, CFG.buySeedNames, function() persist() end, 1)
		makeToggle(seedAcc, "Enable Automation Buy Seed", "Auto-beli seed terpilih tiap ada stock",
			function() return CFG.buySeedEnabled end,
			function(v) CFG.buySeedEnabled = v; persist(); if v then ctx.startBuySeed() end end, 2)

		-- 2) EGGS
		local pEgg = sub.pages["egg"]
		local eggAcc = makeAccordion(pEgg, "Automation Buy Egg", 1, true)
		makeMultiDropdownDyn(eggAcc, "Select Eggs to Buy", "Pilih egg buat auto-beli (stock realtime)",
			function() return ctx.getEggShopOptions(CFG.buyEggNames) end, CFG.buyEggNames, function() persist() end, 1)
		makeToggle(eggAcc, "Enable Automation Buy Egg", "Auto-beli egg terpilih tiap ada stock",
			function() return CFG.buyEggEnabled end,
			function(v) CFG.buyEggEnabled = v; persist(); if v then ctx.startBuyEgg() end end, 2)

		-- 3) GEARS
		local pGear = sub.pages["gear"]
		local gearAcc = makeAccordion(pGear, "Automation Buy Gear", 1, true)
		makeMultiDropdownDyn(gearAcc, "Select Gear to Buy", "Pilih gear buat auto-beli (stock realtime)",
			function() return ctx.getGearShopOptions(CFG.buyGearNames) end, CFG.buyGearNames, function() persist() end, 1)
		makeToggle(gearAcc, "Enable Automation Buy Gear", "Auto-beli gear terpilih tiap ada stock",
			function() return CFG.buyGearEnabled end,
			function(v) CFG.buyGearEnabled = v; persist(); if v then ctx.startBuyGear() end end, 2)

		-- 4) MERCHANT
		local pMer = sub.pages["merchant"]
		local merAcc = makeAccordion(pMer, "Automation Buy Merchant", 1, true)
		local merStatus = mk("TextLabel", {
			Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1, Text = "Loading...",
			Font = F.reg, TextSize = 12, TextColor3 = C.txt,
			TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true,
			LineHeight = 1.3, RichText = true, LayoutOrder = 0
		}, merAcc)
		mk("Frame", { Size = UDim2.new(1, 0, 0, 8), BackgroundTransparency = 1, LayoutOrder = 1 }, merAcc)
		task.spawn(function()
			while ctx.alive() do
				if not onScreen(shopPage) then task.wait(1) continue end
				local ok, s = pcall(function() return ctx.getMerchantSummary() end)
				if ok and s then
					local lines = {}
					if s.activeMerchant then
						lines[#lines + 1] = "Traveling aktif: <font color=\"#5acc78\"><b>" .. s.activeMerchant .. "</b></font>"
					else
						lines[#lines + 1] = "Traveling aktif: <font color=\"#dc5050\">Tidak Ada</font>"
					end
					if s.mode == "all" then
						lines[#lines + 1] = "Mode: <font color=\"#f5c82d\"><b>Beli SEMUA item (All)</b></font>"
					elseif s.mode == "best" then
						lines[#lines + 1] = "Mode: <font color=\"#f5c82d\"><b>Beli item TERMAHAL (Best)</b></font>"
					elseif s.picks and #s.picks > 0 then
						lines[#lines + 1] = "Item dipilih buat dibeli:"
						for _, p in ipairs(s.picks) do
							local function shortNum(n)
								local a = math.abs(n)
								local s
								if a >= 1e9 then s = string.format("%.2f", n / 1e9):gsub("%.?0+$", "") .. "b"
								elseif a >= 1e6 then s = string.format("%.2f", n / 1e6):gsub("%.?0+$", "") .. "m"
								elseif a >= 1e3 then s = string.format("%.2f", n / 1e3):gsub("%.?0+$", "") .. "k"
								else s = tostring(n) end
								return s
							end
							local parts = {}
							for _, it in ipairs(p.items) do
								if it.price then
									parts[#parts + 1] = string.format("%s (%s)", it.name, shortNum(it.price))
								else
									parts[#parts + 1] = it.name
								end
							end
							lines[#lines + 1] = string.format(
								"- <font color=\"#5acc78\"><b>%s</b></font>: <font color=\"#f5c82d\">%s</font>",
								p.title, table.concat(parts, ", "))
						end
					else
						lines[#lines + 1] = "<font color=\"#dc5050\">Belum ada item dipilih.</font> Pilih di 'Select Items per Merchant' atau nyalakan Auto Buy All/Best."
					end
					merStatus.Text = table.concat(lines, "\n")
				end
				task.wait(2)
			end
		end)
		-- Pilih item — dipisah: Traveling Merchant vs Event Shop (biar rapih). Set duluan.
		-- Dua-duanya 1 path/buy toggle yang sama (Auto Buy Merchant/All/Best).
		local merSel = makeAccordion(merAcc, "Select Items per Merchant", 2, false)
		local evtSel = makeAccordion(merAcc, "Select Items per Event Shop", 3, false)
		do
			local iM, iE = 0, 0
			for _, m in ipairs(ctx.getMerchantList()) do
				local id = m.id
				if m.kind == "travel" then
					iM = iM + 1
					makeMultiDropdownDyn(merSel, m.title .. " Merchant", "Item dari " .. m.title .. " merchant. 'All' = semua.",
						function() return ctx.getMerchantItemOptions(id) end, ctx.merchantSelFor(id), function() persist() end, iM)
				else
					iE = iE + 1
					makeMultiDropdownDyn(evtSel, m.title, "Item dari " .. m.title .. ". 'All' = semua.",
						function() return ctx.getMerchantItemOptions(id) end, ctx.merchantSelFor(id), function() persist() end, iE)
				end
			end
		end
		-- Toggle bisa nyala barengan; target-nya digabung (union). Berlaku utk merchant & event shop.
		makeToggle(merAcc, "Auto Buy Merchant", "Beli item terpilih (merchant & event shop) tiap muncul / restock",
			function() return CFG.merchantBuyEnabled end,
			function(v) CFG.merchantBuyEnabled = v; persist(); if v then ctx.startBuyMerchant() end end, 4)
		makeToggle(merAcc, "Auto Buy All Merchant", "Beli SEMUA item yang ada stock",
			function() return CFG.merchantBuyAll end,
			function(v) CFG.merchantBuyAll = v; persist(); if v then ctx.startBuyMerchant() end end, 5)
		makeToggle(merAcc, "Auto Buy Best Merchant", "Beli 1 item TERMAHAL yang ada stock",
			function() return CFG.merchantBuyBest end,
			function(v) CFG.merchantBuyBest = v; persist(); if v then ctx.startBuyMerchant() end end, 6)

		-- Open Shop UI (event/night shop — tampilkan UI shop tanpa NPC)
		local merUi = makeAccordion(merAcc, "Open Shop UI", 7, false)
		makeSingleDropdown(merUi, "Merchant UI to Open", "Event shop yang mau dibuka UI-nya (1 shop per waktu)",
			function() return ctx.getEventShopOptions() end,
			function() return ctx.getMerchantUiDisplay() end,
			function(code) CFG.merchantUiShop = code; persist(); if ctx.openEventShopUI then ctx.openEventShopUI(code) end end, 1)
		makeButton(merUi, "Open Shop UI Now", "Buka UI shop terpilih sekarang (kalau shop lagi aktif)",
			function() if ctx.openEventShopUI then ctx.openEventShopUI() end end, 2)
		makeToggle(merUi, "Auto Open UI", "Jaga UI shop terpilih tetap kebuka (buka ulang otomatis, tanpa NPC)",
			function() return CFG.merchantAutoOpenUI end,
			function(v) CFG.merchantAutoOpenUI = v; persist()
				if v then ctx.startAutoOpenUI() elseif ctx.stopAutoOpenUI then ctx.stopAutoOpenUI() end end, 3)

		-- 5) PREMIUM
		local pPrem = sub.pages["premium"]
		local premAcc = makeAccordion(pPrem, "Premium Shop", 1, true)
		makeSingleDropdown(premAcc, "Select Item", "Select gamepass/product to purchase",
			function() return ctx.getPremiumItemOptions() end,
			function()
				for _, o in ipairs(ctx.getPremiumItemOptions()) do if o.name == CFG.premiumItem then return o.display end end
				return "Select Option"
			end,
			function(code) CFG.premiumItem = code; persist(); if ctx.premiumShowPrice then ctx.premiumShowPrice() end end, 1)
		makeSingleDropdown(premAcc, "Payment Method", "Pilih bayar pakai Robux / in-game Token",
			function() return ctx.getPremiumPayOptions() end,
			function() return CFG.premiumPay == "token" and "Token" or "Robux" end,
			function(code) CFG.premiumPay = code; persist() end, 2)
		makeButton(premAcc, "Purchase Item", "Beli item terpilih dengan payment method di atas",
			function() if ctx.premiumBuy then ctx.premiumBuy() end end, 3)
		makeButton(premAcc, "Gift to Player", "Beli varian Gift item ini (kalau tersedia)",
			function() if ctx.premiumGift then ctx.premiumGift() end end, 4)
	end

	------------------------------------------------------------------ ELEPHANT (V1 & V2)
	do
		local elephantPage = pageRef["Elephant"]
		local sub = makeSubTabs(elephantPage, {
			{ id = "v1", name = "Elephant V1" },
			{ id = "v2", name = "Elephant V2 (Swap 40)" },
		}, "v1", 1)

		-- V1 SUB-TAB
		local pV1 = sub.pages["v1"]
		local acc = makeAccordion(pV1, "Automation Elephant V1", 1, true)

		-- Status (live)
		local statusLbl = mk("TextLabel", {
			Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1, Text = "Loading stats...",
			Font = F.reg, TextSize = 12, TextColor3 = C.txt,
			TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true,
			LineHeight = 1.3, RichText = true, LayoutOrder = 0
		}, acc)
		mk("Frame", { Size = UDim2.new(1, 0, 0, 8), BackgroundTransparency = 1, LayoutOrder = 1 }, acc)
		task.spawn(function()
			while ctx.alive() do
				if not onScreen(elephantPage) then task.wait(1) continue end
				local ok, s = pcall(function() return ctx.getElephantSummary() end)
				if ok and s then
					local col = s.status == "ACTIVE" and "#5acc78" or "#dc5050"
					statusLbl.Text = string.format(
						"Automation Status: <font color=\"%s\"><b>%s</b></font>\n\n" ..
						"Elephant Team: <font color=\"#8c929e\">%s</font>\n" ..
						"Target Types: <font color=\"#f5c82d\">%s</font>\n" ..
						"Target Pets Ready: <font color=\"#8c929e\">%s</font>\n" ..
						"Pets at Max KG: <font color=\"#8c929e\">%s</font>\n\n" ..
						"Max Target Pets: <font color=\"#8c929e\">%s</font>\n" ..
						"Target Weight: <font color=\"#f5c82d\"><b>%s</b></font>",
						col, s.status, s.team, s.types, s.ready, s.maxKg, s.maxTarget, s.targetWeight)
				end
				task.wait(1.5)
			end
		end)

		-- Settings (dalam accordion yang sama)
		makeMultiDropdownDyn(acc, "V1 Pet Team", "Select elephant pet team (tetap di garden)",
			function() return ctx.inventoryPetOptions(CFG.elephantTeamUuids) end, CFG.elephantTeamUuids, function() persist() end, 2)
		makeMultiDropdown(acc, "V1 Target Pet Types", "Select pet types to auto-elephant (semua pet di game)",
			reg.PET_OPTIONS, CFG.elephantPetTypes, function() persist() end, 3)
		makeInput(acc, "Target Weight (KG)", "Berat max sebelum diganti (mis. 5.5)",
			function() return tostring(CFG.elephantTargetWeight) end,
			function(txt) CFG.elephantTargetWeight = tonumber(txt) or 5.5; persist() end, 4)
		makeInput(acc, "Max Target Pets", "Jumlah pet target aktif barengan",
			function() return tostring(CFG.elephantMaxPets) end,
			function(txt) CFG.elephantMaxPets = tonumber(txt) or 2; persist() end, 5)
		local refreshEleBar
		makeToggle(acc, "Enable Automation Elephant", "Rotasi pet target otomatis. OFF = cabut semua pet dari garden.",
			function() return CFG.elephantEnabled end,
			function(v)
				CFG.elephantEnabled = v; persist()
				if v then ctx.startElephant() else ctx.stopElephant() end
				if refreshEleBar then refreshEleBar() end
			end, 6)

		-- ===================== ELEPHANT V2 (swap gajah on lvl 40) =====================
		local pV2 = sub.pages["v2"]
		local acc2 = makeAccordion(pV2, "Automation Elephant V2", 1, true)

		local v2Lbl = mk("TextLabel", {
			Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1, Text = "Loading...",
			Font = F.reg, TextSize = 12, TextColor3 = C.txt,
			TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true,
			LineHeight = 1.3, RichText = true, LayoutOrder = 0
		}, acc2)
		mk("Frame", { Size = UDim2.new(1, 0, 0, 8), BackgroundTransparency = 1, LayoutOrder = 1 }, acc2)
		task.spawn(function()
			while ctx.alive() do
				if not onScreen(elephantPage) then task.wait(1) continue end
				local ok, s = pcall(function() return ctx.getElephantV2Summary() end)
				if ok and s then
					local col = s.status == "ACTIVE" and "#5acc78" or "#dc5050"
					v2Lbl.Text = string.format(
						"Automation Status: <font color=\"%s\"><b>%s</b></font>  |  <font color=\"#f5c82d\">%s</font>\n\n" ..
						"Elephant Team: <font color=\"#8c929e\">%s</font>\n" ..
						"Target Types: <font color=\"#f5c82d\">%s</font>\n" ..
						"Target Pets Ready: <font color=\"#8c929e\">%s</font>\n" ..
						"Pets at Max KG: <font color=\"#8c929e\">%s</font>\n" ..
						"Max Target Pets: <font color=\"#8c929e\">%s</font>  |  Target Weight: <font color=\"#f5c82d\"><b>%s</b></font>\n\n" ..
						"Gajah: <font color=\"#8c929e\">%s</font>\n" ..
						"Switch: <font color=\"#8c929e\">%s</font>\n" ..
						"Gajah masuk saat target Age >= <font color=\"#f5c82d\"><b>%s</b></font>",
						col, s.status, s.info, s.team, s.types, s.ready, s.maxKg, s.maxTarget, s.targetWeight, s.gajah, s.switch, s.level)
				end
				task.wait(0.5)
			end
		end)

		makeMultiDropdownDyn(acc2, "V2 Elephant Team", "Team standby di garden (sumber pilihan Pet Switch)",
			function() return ctx.inventoryPetOptions(CFG.elephantV2Team) end, CFG.elephantV2Team, function() persist() end, 2)
		makeMultiDropdown(acc2, "V2 Target Pet Types", "Select pet types to auto-level + elephant (semua pet di game)",
			reg.PET_OPTIONS, CFG.elephantV2Types, function() persist() end, 3)
		makeSingleDropdown(acc2, "Gajah Pet (Slot 1)", "Pilih gajah yang akan di-swap masuk saat target lvl 40",
			function() return ctx.elephantV2GajahOptions() end,
			function() return ctx.elephantV2Label(CFG.elephantV2Gajah) end,
			function(uuid) CFG.elephantV2Gajah = uuid; persist() end, 4)
		makeSingleDropdown(acc2, "Pet Switch (Slot 2)", "Pilih pet dari Team yang diganti oleh Gajah (biasanya Capy)",
			function() return ctx.elephantV2SwitchOptions() end,
			function() return ctx.elephantV2Label(CFG.elephantV2Switch) end,
			function(uuid) CFG.elephantV2Switch = uuid; persist() end, 5)
		makeInput(acc2, "Target Weight (KG)", "Berat max target sebelum dilepas (mis. 5.5)",
			function() return tostring(CFG.elephantV2Weight) end,
			function(txt) CFG.elephantV2Weight = tonumber(txt) or 5.5; persist() end, 6)
		makeInput(acc2, "Max Target Pets", "Jumlah pet target aktif barengan di garden",
			function() return tostring(CFG.elephantV2MaxPets) end,
			function(txt) CFG.elephantV2MaxPets = tonumber(txt) or 3; persist() end, 7)
		makeInput(acc2, "Trigger Level", "Level target buat masukin gajah (default 40)",
			function() return tostring(CFG.elephantV2Level) end,
			function(txt) CFG.elephantV2Level = tonumber(txt) or 40; persist() end, 8)
		makeToggle(acc2, "Enable Elephant V2", "Rotasi target + swap gajah otomatis saat target lvl 40. Jalan barengan PNP.",
			function() return CFG.elephantV2Enabled end,
			function(v)
				CFG.elephantV2Enabled = v; persist()
				if v then ctx.startElephantV2() else ctx.stopElephantV2() end
			end, 9)

		-- Start/Stop Bar for V1
		refreshEleBar = makeStartStopBar(elephantPage,
			function() return CFG.elephantEnabled end,
			function()
				CFG.elephantEnabled = true; persist(); ctx.startElephant()
			end,
			function()
				CFG.elephantEnabled = false; persist(); ctx.stopElephant()
			end, 999)
	end

	------------------------------------------------------------------ LEVELING
	local levelingPage = pageRef["Leveling"]
	do
		local levSub = makeSubTabs(levelingPage, {
			{ id = "v1", name = "Leveling V1" },
			{ id = "v2", name = "Leveling V2" },
		}, "v1", { hasBottomBar = false, hasInfoLine = false })

		local pLevV1 = levSub.pages["v1"]
		local pLevV2 = levSub.pages["v2"]

		-- Automation Leveling V1 — status + settings jadi satu accordion
		local levAcc = makeAccordion(pLevV1, "Automation Leveling V1", 1, true)

		local statusLbl = mk("TextLabel", {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Text = "Loading stats...",
			Font = F.reg,
			TextSize = 13,
			TextColor3 = C.txt,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true,
			LineHeight = 1.35,
			RichText = true,
			LayoutOrder = 0
		}, levAcc)
		-- spacer pemisah status & settings
		mk("Frame", { Size = UDim2.new(1, 0, 0, 12), BackgroundTransparency = 1, LayoutOrder = 1 }, levAcc)

		task.spawn(function()
			while ctx.alive() do
				if not onScreen(levelingPage) then task.wait(1) continue end
				local ok, s = pcall(function() return ctx.getLevelingSummary() end)
				if ok and s then
					local statusColor = s.status == "ACTIVE" and "#5acc78" or "#dc5050"
					statusLbl.Text = string.format(
						"Automation Status: <font color=\"%s\"><b>%s</b></font>\n\n" ..
						"<b>Current Settings:</b>\n" ..
						"Pet Team: <font color=\"#8c929e\">%s</font>\n" ..
						"Target Types: <font color=\"#f5c82d\">%s</font>\n" ..
						"Pets Ready to Level: <font color=\"#8c929e\">%s</font>\n" ..
						"Pets at Max Level: <font color=\"#8c929e\">%s</font>\n" ..
						"Max in Garden: <font color=\"#8c929e\">%s</font>\n\n" ..
						"Target Level: <font color=\"#f5c82d\"><b>%s</b></font>\n\n" ..
						"Ready: Settings configured",
						statusColor, s.status,
						s.team,
						s.types,
						s.ready,
						s.maxLvl,
						s.maxInGarden,
						s.targetLevel
					)
				end
				task.wait(1.5)
			end
		end)

		-- Settings (di accordion yang sama, setelah status + spacer)
		-- Leveling Pet Team (Multi-dropdown UUIDs)
		makeMultiDropdownDyn(levAcc, "Leveling Pet Team", "Select pets to keep in garden while leveling",
			function() return ctx.inventoryPetOptions(CFG.levelingTeamUuids) end, CFG.levelingTeamUuids, function() persist() end, 2)

		-- Leveling Pet Types (semua pet di game, bukan cuma yang di inventory)
		makeMultiDropdown(levAcc, "Leveling Pet Types", "Select pet types to auto-level (semua pet di game)",
			reg.PET_OPTIONS, CFG.levelingPetTypes, function() persist() end, 3)

		-- Target Level (Input)
		makeInput(levAcc, "Target Level", "Target level to reach before un-equipping",
			function() return tostring(CFG.levelingTargetLevel) end,
			function(txt) CFG.levelingTargetLevel = tonumber(txt) or 500; persist() end, 4)

		-- Max Pets in Garden (Input)
		makeInput(levAcc, "Max Pets in Garden", "Maximum active leveling pets allowed in garden",
			function() return tostring(CFG.levelingMaxPets) end,
			function(txt) CFG.levelingMaxPets = tonumber(txt) or 2; persist() end, 5)

		-- Enable Automation Leveling (Toggle)
		makeToggle(levAcc, "Enable Automation Leveling", "Equip and rotate pets automatically based on settings",
			function() return CFG.levelingEnabled end,
			function(v)
				CFG.levelingEnabled = v; persist()
				if v then ctx.startLeveling() else ctx.stopLeveling() end
			end, 6)

		---------------------------------------------------------- Automation Leveling V2 (2 phase)
		local lv2 = makeAccordion(pLevV2, "Automation Leveling V2", 1, true)

		local lv2Lbl = mk("TextLabel", {
			Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
			Text = "Loading...", Font = F.reg, TextSize = 13, TextColor3 = C.txt,
			TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, LineHeight = 1.35, RichText = true, LayoutOrder = 0
		}, lv2)
		mk("Frame", { Size = UDim2.new(1, 0, 0, 12), BackgroundTransparency = 1, LayoutOrder = 1 }, lv2)
		task.spawn(function()
			while ctx.alive() do
				if not onScreen(levelingPage) then task.wait(1) continue end
				local ok, s = pcall(function() return ctx.getLevelingV2Summary() end)
				if ok and s then
					local col = s.status == "ACTIVE" and "#5acc78" or "#dc5050"
					lv2Lbl.Text = string.format(
						"Automation Status: <font color=\"%s\"><b>%s</b></font>  |  <font color=\"#f5c82d\">%s</font>\n\n" ..
						"<b>Target Types:</b> <font color=\"#8c929e\">%s</font>\n\n" ..
						"<b>Phase 1</b> (→%s): team <font color=\"#8c929e\">%d</font> | antre <font color=\"#f5c82d\">%d</font> pet\n" ..
						"<b>Phase 2</b> (→%s): team <font color=\"#8c929e\">%d</font> | antre <font color=\"#f5c82d\">%d</font> pet\n" ..
						"<b>Pet at Max Level:</b> <font color=\"#5acc78\">%d</font> pet",
						col, s.status, s.phase, s.types,
						tostring(s.p1target), s.p1team, s.p1queue,
						tostring(s.p2target), s.p2team, s.p2queue,
						s.maxLvl or 0)
				end
				task.wait(1.5)
			end
		end)

		-- Target Pet Types (semua pet di game)
		makeMultiDropdown(lv2, "Leveling Target Pet Types", "Pet types to level up (semua pet di game)",
			reg.PET_OPTIONS, CFG.levelingV2PetTypes, function() persist() end, 2)

		-- Phase 1
		makeMultiDropdownDyn(lv2, "Leveling Phase 1 Pet Team", "Team for Phase 1 (Age 1 to Phase 1 Target)",
			function() return ctx.inventoryPetOptions(CFG.levelingV2P1Team) end, CFG.levelingV2P1Team, function() persist() end, 3)
		makeInput(lv2, "Leveling Phase 1 Target", "End of Phase 1 / start of Phase 2 (default 40)",
			function() return tostring(CFG.levelingV2P1Target) end,
			function(txt) CFG.levelingV2P1Target = tonumber(txt) or 40; persist() end, 4)
		makeInput(lv2, "Leveling Phase 1 Max Pets", "Max target pets in garden during Phase 1",
			function() return tostring(CFG.levelingV2P1Max) end,
			function(txt) CFG.levelingV2P1Max = tonumber(txt) or 3; persist() end, 5)

		-- Phase 2
		makeMultiDropdownDyn(lv2, "Leveling Phase 2 Pet Team", "Team for Phase 2 (Phase 1 Target to Final Target)",
			function() return ctx.inventoryPetOptions(CFG.levelingV2P2Team) end, CFG.levelingV2P2Team, function() persist() end, 6)
		makeInput(lv2, "Leveling Phase 2 Target", "Final target level (default 500 = max age)",
			function() return tostring(CFG.levelingV2P2Target) end,
			function(txt) CFG.levelingV2P2Target = tonumber(txt) or 500; persist() end, 7)
		makeInput(lv2, "Leveling Phase 2 Max Pets", "Max target pets in garden during Phase 2",
			function() return tostring(CFG.levelingV2P2Max) end,
			function(txt) CFG.levelingV2P2Max = tonumber(txt) or 1; persist() end, 8)

		-- Enable
		makeToggle(lv2, "Enable Automation Leveling V2", "Level pet 2 tahap (Phase 1 team -> Phase 2 team)",
			function() return CFG.levelingV2Enabled end,
			function(v)
				CFG.levelingV2Enabled = v; persist()
				if v then ctx.startLevelingV2() else ctx.stopLevelingV2() end
			end, 9)
	end

	------------------------------------------------------------------ MUTATION
	local mutationPage = pageRef["Mutation"]
	do
		local mutSub = makeSubTabs(mutationPage, {
			{ id = "machine", name = "Machine" },
			{ id = "cleanse", name = "Aura Cleanse" },
		}, "machine", { hasBottomBar = false, hasInfoLine = false })

		local pMutMachine = mutSub.pages["machine"]
		local pMutCleanse = mutSub.pages["cleanse"]

		-- 1. Status Accordion (Machine)
		local statusAcc = makeAccordion(pMutMachine, "Automation Mutation Machine", 1, true)
		
		local statusLbl = mk("TextLabel", {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Text = "Loading stats...",
			Font = F.reg,
			TextSize = 13,
			TextColor3 = C.txt,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true,
			LineHeight = 1.35,
			RichText = true,
			LayoutOrder = 0
		}, statusAcc)
		mk("Frame", { Size = UDim2.new(1, 0, 0, 12), BackgroundTransparency = 1, LayoutOrder = 1 }, statusAcc)

		task.spawn(function()
			while ctx.alive() do
				if not onScreen(mutationPage) then task.wait(1) continue end
				local ok, s = pcall(function() return ctx.getMutationSummary() end)
				if ok and s then
					local statusColor = s.status == "ACTIVE" and "#5acc78" or "#dc5050"
					statusLbl.Text = string.format(
						"Status: <font color=\"%s\"><b>%s</b></font>\n" ..
						"Phase: <b>%s</b>\n\n" ..
						"EXP Team: <font color=\"#8c929e\">%d pets</font>\n" ..
						"Boost Team: <font color=\"#8c929e\">%d pets</font>\n" ..
						"Phoenix Team: <font color=\"#8c929e\">%d pets</font>\n\n" ..
						"Target Types: <font color=\"#f5c82d\">%s</font>\n" ..
						"Keep Mutations: <font color=\"#f5c82d\">%s</font>\n" ..
						"Target Age: <font color=\"#f5c82d\"><b>%s</b></font>\n\n" ..
						"Machine: <font color=\"#85d0ff\"><b>%s</b></font>\n\n" ..
						"Target Pets Ready: <font color=\"#8c929e\">%d pets</font>\n" ..
						"Target Pets Done: <font color=\"#5acc78\"><b>%d pets</b></font>",
						statusColor, s.status,
						s.phase,
						s.expCount,
						s.boostCount,
						s.phoenixCount,
						s.types,
						s.mutations,
						tostring(s.targetAge),
						s.machine,
						s.readyCount,
						s.doneCount
					)
				end
				task.wait(1.5)
			end
		end)

		-- Settings (dalam accordion yang sama dengan status)
		local settingsAcc = statusAcc

		-- EXP Team (Multi-dropdown UUIDs)
		makeMultiDropdownDyn(settingsAcc, "EXP Team (Leveling)", "Pets for leveling target to age 50/500",
			function() return ctx.inventoryPetOptions(CFG.mutationExpTeam) end, CFG.mutationExpTeam, function() persist() end, 2)

		-- Boost Team (Machine) (Multi-dropdown UUIDs)
		makeMultiDropdownDyn(settingsAcc, "Boost Team (Machine)", "Pets for boosting mutation machine speed",
			function() return ctx.inventoryPetOptions(CFG.mutationBoostTeam) end, CFG.mutationBoostTeam, function() persist() end, 3)

		-- Phoenix Team (Claim) (Multi-dropdown UUIDs)
		makeMultiDropdownDyn(settingsAcc, "Phoenix Team (Claim)", "Pets for claiming mutated pet",
			function() return ctx.inventoryPetOptions(CFG.mutationPhoenixTeam) end, CFG.mutationPhoenixTeam, function() persist() end, 4)

		-- Target Pet Types (semua pet di game, bukan cuma yang di inventory)
		makeMultiDropdown(settingsAcc, "Target Pet Types", "Pet types to mutate (semua pet di game)",
			reg.PET_OPTIONS, CFG.mutationTargetTypes, function() persist() end, 5)

		-- Target Mutations (Multi-dropdown Mutations)
		makeMultiDropdown(settingsAcc, "Target Mutations (Machine)", "Stop when pet gets these mutations (hanya mutasi mesin)",
			ctx.reg.MACHINE_MUT_OPTIONS or ctx.reg.MUT_OPTIONS or {"None"}, CFG.mutationTargetMutations, function() persist() end, 6)

		-- Target Age (Input)
		makeInput(settingsAcc, "Target Age", "Level to reach before submitting (e.g. 50 or 500)",
			function() return tostring(CFG.mutationTargetAge) end,
			function(txt) CFG.mutationTargetAge = tonumber(txt) or 50; persist() end, 7)

		-- Delay Auto Claim (Input)
		makeInput(settingsAcc, "Delay Auto Claim (sec)", "Wait before claiming mutated pet from machine",
			function() return tostring(CFG.mutationDelayAutoClaim) end,
			function(txt) CFG.mutationDelayAutoClaim = tonumber(txt) or 0.5; persist() end, 8)

		-- Enable Auto Mutation Machine (Toggle)
		ctx.state.mutationToggleRender = makeToggle(settingsAcc, "Enable Auto Mutation Machine", "Submit, start, and claim mutated pets automatically",
			function() return CFG.mutationEnabled end,
			function(v)
				CFG.mutationEnabled = v; persist()
				if v then ctx.startMutation() else ctx.stopMutation() end
			end, 9)

		-- Accordion: Automation Mutation (mutasi via aura + cleanse)
		local cleanseAcc = makeAccordion(pMutCleanse, "Automation Mutation (Aura)", 1, true)

		-- Status (live)
		local cleanseLbl = mk("TextLabel", {
			Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1, Text = "Loading stats...",
			Font = F.reg, TextSize = 13, TextColor3 = C.txt,
			TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true,
			LineHeight = 1.35, RichText = true, LayoutOrder = 0
		}, cleanseAcc)
		mk("Frame", { Size = UDim2.new(1, 0, 0, 12), BackgroundTransparency = 1, LayoutOrder = 1 }, cleanseAcc)
		task.spawn(function()
			while ctx.alive() do
				if not onScreen(mutationPage) then task.wait(1) continue end
				local ok, s = pcall(function() return ctx.getCleanseSummary() end)
				if ok and s then
					local col = s.status == "ACTIVE" and "#5acc78" or "#dc5050"
					local alreadyLines = ""
					for _, k in ipairs(s.keepOrder) do
						alreadyLines = alreadyLines .. string.format("- Already %s: <font color=\"#8c929e\">%d pets</font>\n", k, s.already[k] or 0)
					end
					cleanseLbl.Text = string.format(
						"Automation Status: <font color=\"%s\"><b>%s</b></font>\n\n" ..
						"Mutation Team: <font color=\"#8c929e\">%d pets</font>\n" ..
						"Target Types: <font color=\"#f5c82d\">%s</font>\n" ..
						"Mutations to Keep: <font color=\"#f5c82d\">%s</font>\n\n" ..
						"Pet Statistics:\n" ..
						"- Pets Ready to Mutation: <font color=\"#8c929e\">%d pets</font>\n" ..
						"%s\n" ..
						"Max in Garden: <font color=\"#8c929e\">%d pets</font>\n\n" ..
						"Status: <font color=\"#85d0ff\">%s</font>",
						col, s.status, s.team, s.types, s.keep, s.ready, alreadyLines, s.maxPets, s.phase)
				end
				task.wait(1.5)
			end
		end)

		makeMultiDropdownDyn(cleanseAcc, "Pet Team for Mutation", "Pet aura pemberi mutasi (tetap di garden)",
			function() return ctx.inventoryPetOptions(CFG.cleanseTeamUuids) end, CFG.cleanseTeamUuids, function() persist() end, 2)
		makeMultiDropdown(cleanseAcc, "Pet Types for Mutation", "Tipe pet target yang mau dimutasi (semua pet di game)",
			reg.PET_OPTIONS, CFG.cleansePetTypes, function() persist() end, 3)
		makeMultiDropdown(cleanseAcc, "Mutations to Keep", "Mutasi ini disimpan (won't be cleansed)",
			ctx.reg.MUT_OPTIONS or {"None"}, CFG.cleanseKeepMutations, function() persist() end, 4)
		makeInput(cleanseAcc, "Max Pets in Garden", "Max pet target di garden barengan",
			function() return tostring(CFG.cleanseMaxPets) end,
			function(txt) CFG.cleanseMaxPets = tonumber(txt) or 2; persist() end, 5)
		makeToggle(cleanseAcc, "Enable Auto Mutation", "Mutasi target via aura; cleanse mutasi salah, simpan mutasi keep",
			function() return CFG.cleanseEnabled end,
			function(v)
				CFG.cleanseEnabled = v; persist()
				if v then ctx.startCleanse() else ctx.stopCleanse() end
			end, 6)
	end

	------------------------------------------------------------------ PET (PNP)
	local pet = pageRef["Pet"]
	local v1Render, v2Render -- buat sync visual mutual-exclusion

	local petSub = makeSubTabs(pet, {
		{ id = "v1",    name = "PnP V1" },
		{ id = "v2",    name = "PnP V2" },
		{ id = "boost", name = "Boost Pet" },
	}, "v1", { hasBottomBar = false, hasInfoLine = false })

	local pPetV1 = petSub.pages["v1"]
	local pPetV2 = petSub.pages["v2"]
	local pPetBoost = petSub.pages["boost"]

	------------------------------------------------------------------ PnP V1 (polling)
	local pnp = makeAccordion(pPetV1, "Automation Pickup Pet V1", 1, true)
	makeMultiDropdownDyn(pnp, "Select Pets for Pickup [V1]", "Pilih pet dari backpack (kosong = semua yg di garden)",
		function() return ctx.inventoryPetOptions(CFG.pnpUuids) end, CFG.pnpUuids, function() persist() end, 1)
	makeInput(pnp, "Pickup Delay (Seconds) [V1]", "Jeda tiap siklus (idealnya = saat skill ready)",
		function() return CFG.pickupDelay end,
		function(txt) CFG.pickupDelay = tonumber(txt) or 0.3; persist() end, 2)
	makeInput(pnp, "Equip Delay (Seconds) [V1]", "Jeda antara unequip -> equip",
		function()
			if CFG.equipDelay == 1e-20 or CFG.equipDelay == 0 or not CFG.equipDelay then return "1E-20" end
			return tostring(CFG.equipDelay)
		end,
		function(txt)
			if tostring(txt):upper():find("1E%-20") then
				CFG.equipDelay = 1e-20
			else
				CFG.equipDelay = tonumber(txt) or 1e-20
			end
			persist()
		end, 3)
	makeInput(pnp, "Scan Interval (Seconds) [V1]", "Frekuensi cek cooldown (kecil = makin ketat, min 0.01)",
		function() return CFG.pnpScanInterval end,
		function(txt) CFG.pnpScanInterval = math.max(0.01, tonumber(txt) or 0.05); persist() end, 4)
	v1Render = makeToggle(pnp, "Enable Automation Pickup V1", "Polling GetPetCooldown (lama). Nyalain ini matiin V2.",
		function() return CFG.pnpEnabled end,
		function(v)
			CFG.pnpEnabled = v; persist()
			if v then
				CFG.pnpV2Enabled = false; persist()
				if ctx.stopPnpV2 then ctx.stopPnpV2() end
				if v2Render then v2Render() end -- sync visual toggle V2 -> OFF
				if ctx.startPnpV1 then ctx.startPnpV1() end
			else
				if ctx.stopPnpV1 then ctx.stopPnpV1() end
			end
		end, 5)

	------------------------------------------------------------------ PnP V2 (event-driven)
	local pnp2 = makeAccordion(pPetV2, "Automation Pickup Pet V2", 1, true)
	makeMultiDropdownDyn(pnp2, "Select Pets for Pickup [V2]", "Pilih pet dari backpack (kosong = semua yg di garden)",
		function() return ctx.inventoryPetOptions(CFG.pnpV2Uuids) end, CFG.pnpV2Uuids, function() persist() end, 1)
	makeInput(pnp2, "Pickup Delay (Seconds) [V2]", "Jeda sebelum tiap pickup",
		function() return CFG.pnpV2PickupDelay end,
		function(txt) CFG.pnpV2PickupDelay = tonumber(txt) or 0.05; persist() end, 2)
	makeInput(pnp2, "Equip Delay (Seconds) [V2]", "Jeda antara unequip -> equip",
		function() return CFG.pnpV2EquipDelay end,
		function(txt) CFG.pnpV2EquipDelay = tonumber(txt) or 0.03; persist() end, 3)
	makeInput(pnp2, "Scan Interval (Seconds) [V2]", "Frekuensi cek cd dari cache event (min 0.02)",
		function() return CFG.pnpV2ScanInterval end,
		function(txt) CFG.pnpV2ScanInterval = math.max(0.02, tonumber(txt) or 0.05); persist() end, 4)
	v2Render = makeToggle(pnp2, "Enable Automation Pickup V2", "Event-driven (PetCooldownsUpdated), stabil. Nyalain ini matiin V1.",
		function() return CFG.pnpV2Enabled end,
		function(v)
			CFG.pnpV2Enabled = v; persist()
			if v then
				CFG.pnpEnabled = false; persist()
				if ctx.stopPnpV1 then ctx.stopPnpV1() end
				if v1Render then v1Render() end -- sync visual toggle V1 -> OFF
				if ctx.startPnpV2 then ctx.startPnpV2() end
			else
				if ctx.stopPnpV2 then ctx.stopPnpV2() end
			end
		end, 5)

	-- Accordion: Automation Boost Pet
	local boostAcc = makeAccordion(pPetBoost, "Automation Boost Pet", 1, true)
	makeMultiDropdownDyn(boostAcc, "Select Pets to Boost", "Pilih pet yang mau di-boost (aktif di garden)",
		function() return ctx.inventoryPetOptions(CFG.boostPetUuids) end, CFG.boostPetUuids, function() persist() end, 1)
	makeMultiDropdownDyn(boostAcc, "Select Boost Items", "Pilih item boost (Pet Toy) yang dipakai",
		function() return ctx.getBoostItemOptions(CFG.boostItemNames) end, CFG.boostItemNames, function() persist() end, 2)
	makeToggle(boostAcc, "Enable Automation Boost", "Auto apply boost item ke pet, re-apply pas boost habis",
		function() return CFG.boostEnabled end,
		function(v)
			CFG.boostEnabled = v; persist()
			if v then ctx.startBoostPet() end
		end, 3)

	------------------------------------------------------------------ INVENTORY
	local inv = pageRef["Inventory"]

	local invSub = makeSubTabs(inv, {
		{ id = "trade_ticket", name = "Trade Ticket" },
		{ id = "trade_gift",   name = "Trade Gift" },
		{ id = "accept",       name = "Auto Accept" },
		{ id = "fav",          name = "Favorite" },
	}, "trade_ticket", { hasBottomBar = false, hasInfoLine = false })

	local pInvTicket = invSub.pages["trade_ticket"]
	local pInvGift   = invSub.pages["trade_gift"]
	local pInvAccept = invSub.pages["accept"]
	local pInvFav    = invSub.pages["fav"]

	local targetOptions = function()
		local out = {}
		for _, n in ipairs(ctx.getPlayers()) do out[#out + 1] = n end
		return out
	end

	------------------------------------------------------------------ 1) SUB-TAB: TRADE TICKET
	local atTicket = makeAccordion(pInvTicket, "Auto Trade by Ticket", 1, true)

	makeSingleDropdown(atTicket, "Target Player", "Select player to trade with", targetOptions,
		function() return CFG.targetPlayer end,
		function(v) CFG.targetPlayer = v; persist() end, 1)

	makeMultiDropdown(atTicket, "Pet Types to Trade", "Filter pets by type (empty = all non-favorite)",
		reg.PET_OPTIONS, CFG.petTypes, function() persist() end, 2)

	makeInput(atTicket, "Weight Filter (KG)", "pakai berat tampilan game | 0=off | +6 = min 6kg | -6 = max 6kg",
		function() return CFG.weightFilter end,
		function(txt) CFG.weightFilter = tonumber(txt) or 0; persist() end, 3)

	makeInput(atTicket, "Age Filter", "0 = off | +50 = at least age 50 | -50 = at most age 50",
		function() return CFG.ageFilter end,
		function(txt) CFG.ageFilter = tonumber(txt) or 0; persist() end, 4)

	makeInput(atTicket, "Pets Per Trade", "Number of pets to add each trade",
		function() return CFG.petsPerTrade end,
		function(txt) local n = tonumber(txt); CFG.petsPerTrade = (n and n > 0) and math.floor(n) or 1; persist() end, 5)

	makeInput(atTicket, "Total Trades", "How many trades to perform",
		function() return CFG.totalTrades end,
		function(txt) local n = tonumber(txt); CFG.totalTrades = (n and n >= 0) and math.floor(n) or 0; persist() end, 6)

	makeToggle(atTicket, "Auto Unfavorite [Trade]", "Remove favorite before trading",
		function() return CFG.autoUnfavorite end,
		function(v) CFG.autoUnfavorite = v; persist() end, 7)

	-- Trade Ticket Status
	local stFrameTicket = mk("Frame", { Size = UDim2.new(1, 0, 0, 66), BackgroundTransparency = 1, LayoutOrder = 0 }, atTicket)
	mk("TextLabel", { Size = UDim2.new(1, 0, 0, 20), Position = UDim2.fromOffset(0, 4), BackgroundTransparency = 1, Text = "Ticket Trade Status", Font = F.bold, TextSize = 14, TextColor3 = C.txt, TextXAlignment = Enum.TextXAlignment.Left }, stFrameTicket)
	local stLblTicket = mk("TextLabel", { Size = UDim2.new(1, 0, 0, 44), Position = UDim2.fromOffset(0, 22), BackgroundTransparency = 1, Text = "Completed: 0 / 0\nPet cocok filter: -\nStatus: IDLE", Font = F.reg, TextSize = 11, TextColor3 = C.sub, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, RichText = true }, stFrameTicket)
	function ctx.refreshTradeStatus()
		local avail = ctx.countMatchingPets and ctx.countMatchingPets(false) or 0
		local availCol = avail > 0 and "#5acc78" or "#dc5050"
		local statusText = (CFG.tradeMethod == "ticket" and ctx.state.tradeRunning) and ctx.state.status or (CFG.tradeTicketEnabled and "RUNNING" or "IDLE")
		local comp = (CFG.tradeMethod == "ticket") and ctx.state.completed or 0
		stLblTicket.Text = ("Completed: %d / %d\nPet cocok filter: <font color=\"%s\"><b>%d</b></font>\nStatus: %s"):format(
			comp, CFG.totalTrades, availCol, avail, statusText)
	end
	task.spawn(function()
		while ctx.alive() do
			if not onScreen(stLblTicket) then task.wait(2) continue end
			pcall(function() ctx.refreshTradeStatus() end)
			task.wait(2)
		end
	end)

	-- Enable Trade Ticket Toggle
	makeToggle(atTicket, "Enable Trade by Ticket", "Kirim trade request tiket, isi pet, terima & confirm",
		function() return CFG.tradeTicketEnabled or (CFG.tradeEnabled and CFG.tradeMethod == "ticket") end,
		function(v)
			CFG.tradeTicketEnabled = v
			CFG.tradeEnabled = v
			if v then
				CFG.tradeGiftEnabled = false
				CFG.tradeMethod = "ticket"
				persist()
				ctx.state.completed = 0
				ctx.startTrade("ticket")
			else
				persist()
				if CFG.tradeMethod == "ticket" then
					ctx.stopTrade()
				end
			end
			ctx.refreshTradeStatus()
			if ctx.refreshGiftStatus then ctx.refreshGiftStatus() end
		end, 9)

	------------------------------------------------------------------ 2) SUB-TAB: TRADE GIFT
	local atGift = makeAccordion(pInvGift, "Auto Trade by Gift", 1, true)

	makeSingleDropdown(atGift, "Target Player", "Select player to send gifts to", targetOptions,
		function() return (CFG.giftTargetPlayer ~= "" and CFG.giftTargetPlayer) or CFG.targetPlayer end,
		function(v) CFG.giftTargetPlayer = v; persist() end, 1)

	makeMultiDropdown(atGift, "Pet Types to Gift", "Filter pets by type (empty = all non-favorite)",
		reg.PET_OPTIONS, CFG.giftPetTypes, function() persist() end, 2)

	makeInput(atGift, "Weight Filter (KG)", "0=off | +6 = min 6kg | -6 = max 6kg",
		function() return CFG.giftWeightFilter end,
		function(txt) CFG.giftWeightFilter = tonumber(txt) or 0; persist() end, 3)

	makeInput(atGift, "Age Filter", "0=off | +50 = at least age 50 | -50 = at most age 50",
		function() return CFG.giftAgeFilter end,
		function(txt) CFG.giftAgeFilter = tonumber(txt) or 0; persist() end, 4)

	makeInput(atGift, "Pets Per Batch", "Jumlah pet di-gift per ronde",
		function() return CFG.giftPetsPerBatch end,
		function(txt) local n = tonumber(txt); CFG.giftPetsPerBatch = (n and n > 0) and math.floor(n) or 1; persist() end, 5)

	makeInput(atGift, "Total Gifts", "Berapa pet/gift yang dikirim sebelum berhenti",
		function() return CFG.giftTotalGifts end,
		function(txt) local n = tonumber(txt); CFG.giftTotalGifts = (n and n >= 0) and math.floor(n) or 0; persist() end, 6)

	makeToggle(atGift, "Auto Unfavorite [Gift]", "Remove favorite before sending gift",
		function() return CFG.giftAutoUnfavorite end,
		function(v) CFG.giftAutoUnfavorite = v; persist() end, 7)

	-- Gift Status
	local stFrameGift = mk("Frame", { Size = UDim2.new(1, 0, 0, 66), BackgroundTransparency = 1, LayoutOrder = 0 }, atGift)
	mk("TextLabel", { Size = UDim2.new(1, 0, 0, 20), Position = UDim2.fromOffset(0, 4), BackgroundTransparency = 1, Text = "Gift Trade Status", Font = F.bold, TextSize = 14, TextColor3 = C.txt, TextXAlignment = Enum.TextXAlignment.Left }, stFrameGift)
	local stLblGift = mk("TextLabel", { Size = UDim2.new(1, 0, 0, 44), Position = UDim2.fromOffset(0, 22), BackgroundTransparency = 1, Text = "Completed: 0 / 0\nPet cocok filter: -\nStatus: IDLE", Font = F.reg, TextSize = 11, TextColor3 = C.sub, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, RichText = true }, stFrameGift)
	function ctx.refreshGiftStatus()
		local avail = ctx.countMatchingPets and ctx.countMatchingPets(true) or 0
		local availCol = avail > 0 and "#5acc78" or "#dc5050"
		local statusText = (CFG.tradeMethod == "gift" and ctx.state.tradeRunning) and ctx.state.status or (CFG.tradeGiftEnabled and "RUNNING" or "IDLE")
		local comp = (CFG.tradeMethod == "gift") and ctx.state.completed or 0
		stLblGift.Text = ("Completed: %d / %d gifts\nPet cocok filter: <font color=\"%s\"><b>%d</b></font>\nStatus: %s"):format(
			comp, CFG.giftTotalGifts, availCol, avail, statusText)
	end
	task.spawn(function()
		while ctx.alive() do
			if not onScreen(stLblGift) then task.wait(2) continue end
			pcall(function() ctx.refreshGiftStatus() end)
			task.wait(2)
		end
	end)

	-- Enable Trade Gift Toggle
	makeToggle(atGift, "Enable Trade by Gift", "Kirim gift pet langsung tanpa tiket (cepat & otomatis)",
		function() return CFG.tradeGiftEnabled or (CFG.tradeEnabled and CFG.tradeMethod == "gift") end,
		function(v)
			CFG.tradeGiftEnabled = v
			if v then
				CFG.tradeTicketEnabled = false
				CFG.tradeEnabled = false
				CFG.tradeMethod = "gift"
				persist()
				ctx.state.completed = 0
				ctx.startTrade("gift")
			else
				persist()
				if CFG.tradeMethod == "gift" then
					ctx.stopTrade()
				end
			end
			ctx.refreshGiftStatus()
			if ctx.refreshTradeStatus then ctx.refreshTradeStatus() end
		end, 9)

	-- Accordion: Automation Accept
	local acc = makeAccordion(pInvAccept, "Automation Accept", 1, true)
	makeToggle(acc, "Automation Accept Gifts", "Automation accept incoming gifts",
		function() return CFG.acceptGifts end,
		function(v) CFG.acceptGifts = v; persist() end, 1)
	makeToggle(acc, "Automation Accept Trades", "Automation accept incoming trades",
		function() return CFG.acceptTrades end,
		function(v) CFG.acceptTrades = v; persist() end, 2)

	-- Accordion: Automation Favourite Pets
	local fav = makeAccordion(pInvFav, "Automation Favourite Pets", 1, true)
	makeToggle(fav, "Auto Favourite Pets", "Automatically favorite selected pet types",
		function() return CFG.autoFavorite end,
		function(v) CFG.autoFavorite = v; persist(); if v then ctx.startAutoFavorite() else ctx.stopAutoFavorite() end end, 1)
	makeMultiDropdown(fav, "Favourite Pet Types", "Pet types to keep favorited",
		reg.PET_OPTIONS, CFG.favoritePetTypes, function() persist() end, 2)

	-- Accordion: Automation Unfavourite Pets
	local unfav = makeAccordion(pInvFav, "Automation Unfavourite Pets", 2, true)
	makeToggle(unfav, "Auto Unfavourite Pets", "Automatically unfavorite selected pet types",
		function() return CFG.autoUnfavoritePets end,
		function(v)
			CFG.autoUnfavoritePets = v; persist()
			if v and ctx.startAutoUnfavorite then ctx.startAutoUnfavorite()
			elseif ctx.stopAutoUnfavorite then ctx.stopAutoUnfavorite() end
		end, 1)
	makeMultiDropdown(unfav, "Unfavourite Pet Types", "Pet types to automatically unfavorite (kosong = semua pet)",
		reg.PET_OPTIONS, CFG.unfavoritePetTypes, function() persist() end, 2)

	------------------------------------------------------------------ MISC (log & webhooks)
	local misc = pageRef["Misc"]
	local miscSub = makeSubTabs(misc, {
		{ id = "player_esp", name = "Player & ESP" },
		{ id = "rejoin",     name = "Rejoin" },
		{ id = "webhook",    name = "Webhook" },
		{ id = "perf",       name = "Performance" },
	}, "player_esp", { hasBottomBar = false, hasInfoLine = false })

	local pMiscPlayer  = miscSub.pages["player_esp"]
	local pMiscRejoin  = miscSub.pages["rejoin"]
	local pMiscWebhook = miscSub.pages["webhook"]
	local pMiscPerf    = miscSub.pages["perf"]

	-- Player Accordion (Noclip / Walk Speed / Infinity Jump)
	local plAcc = makeAccordion(pMiscPlayer, "Player", 1, true)
	makeToggle(plAcc, "Noclip", "Walk through walls and obstacles",
		function() return CFG.noclipEnabled end,
		function(v) if ctx.setNoclip then ctx.setNoclip(v) end; persist() end, 1)
	makeInput(plAcc, "Walk Speed", "Player walk speed (default 16)",
		function() return tostring(CFG.walkSpeed) end,
		function(t) CFG.walkSpeed = tonumber(t) or 16; if ctx.applyWalkSpeed then ctx.applyWalkSpeed() end; persist() end, 2)
	makeToggle(plAcc, "Enable Walk Speed", "Apply custom walk speed",
		function() return CFG.walkSpeedEnabled end,
		function(v) if ctx.setWalkSpeed then ctx.setWalkSpeed(v) end; persist() end, 3)
	makeToggle(plAcc, "Infinity Jump", "Jump in mid-air infinitely",
		function() return CFG.infJumpEnabled end,
		function(v) if ctx.setInfJump then ctx.setInfJump(v) end; persist() end, 4)

	-- ESP Label Accordion
	local espAcc = makeAccordion(pMiscPlayer, "ESP Label (Pet & Egg)", 2, true)
	makeToggle(espAcc, "Enable ESP Label", "Label melayang di atas pet (nama+berat) & egg (nama+waktu hatch)",
		function() return CFG.espEnabled end,
		function(v)
			CFG.espEnabled = v; persist()
			if v then ctx.startEsp() else ctx.stopEsp() end
		end, 1)

	-- ESP Base Weight (Inventory) Accordion
	local espInvAcc = makeAccordion(pMiscPlayer, "ESP Base Weight (Inventory)", 3, false)
	makeToggle(espInvAcc, "Enable ESP Base Weight", "Tampilkan Base Weight di tiap slot pet saat buka inventory",
		function() return CFG.espInvEnabled end,
		function(v)
			CFG.espInvEnabled = v; persist()
			if v then ctx.startEspInv() else ctx.stopEspInv() end
		end, 1)
	local espInvModeOpts = { { name = "base", display = "Base Weight Only" }, { name = "age", display = "Base + Age" }, { name = "max", display = "Base + Max" } }
	makeSingleDropdown(espInvAcc, "Tampilan", "Pilih data yang tampil di label pet.",
		function() return espInvModeOpts end,
		function() for _, o in ipairs(espInvModeOpts) do if o.name == CFG.espInvMode then return o.display end end return "Base + Age" end,
		function(code) CFG.espInvMode = code; persist() end, 2)

	-- Auto-Reconnect toggle (rejoin otomatis kalau ke-kick / disconnect)
	local reconCard = mk("Frame", { Size = UDim2.new(1, 0, 0, 56), BackgroundColor3 = C.row, LayoutOrder = 1 }, pMiscRejoin)
	corner(reconCard, 10); stroke(reconCard); pad(reconCard, 12, 12, 0, 0)
	makeToggle(reconCard, "Auto Reconnect", "Rejoin otomatis kalau ke-kick / disconnect",
		function() return CFG.autoReconnect ~= false end,
		function(v) CFG.autoReconnect = v; persist() end, 1)

	-- Periodic Rejoin (Interval) Accordion
	local rcAcc = makeAccordion(pMiscRejoin, "Periodic Rejoin (Interval)", 2, true)
	-- countdown live di paling atas
	local rcLbl = mk("TextLabel", {
		Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
		Text = "Rejoin: OFF", Font = F.bold, TextSize = 15,
		TextColor3 = C.sub, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 0,
	}, rcAcc)
	mk("Frame", { Size = UDim2.new(1, 0, 0, 8), BackgroundTransparency = 1, LayoutOrder = 0 }, rcAcc)
	task.spawn(function()
		while ctx.alive() do
			if CFG.reconnectEnabled then
				local rem = ctx.state.reconnectRemaining
				if rem then
					rcLbl.Text = ("⏱ Rejoin in: %d:%02d"):format(math.floor(rem / 60), rem % 60)
				else
					rcLbl.Text = "⏱ Rejoin: ON"
				end
				rcLbl.TextColor3 = C.acc
			else
				rcLbl.Text = "Rejoin: OFF"
				rcLbl.TextColor3 = C.sub
			end
			task.wait(0.5)
		end
	end)
	makeInput(rcAcc, "Interval (menit)", "Rejoin server berkala tiap sekian menit (mis. 1 = tiap 1 menit).",
		function() return tostring(CFG.reconnectInterval) end,
		function(t) CFG.reconnectInterval = tonumber(t) or 5; persist() end, 1)
	makeToggle(rcAcc, "Periodic Rejoin", "Rejoin server berkala tiap interval waktu",
		function() return CFG.reconnectEnabled end,
		function(v) CFG.reconnectEnabled = v; persist(); if v and ctx.startReconnect then ctx.startReconnect() end end, 2)

	-- Webhook Settings Accordion
	local whAcc = makeAccordion(pMiscWebhook, "Discord Webhook Settings", 1, true)

	-- Discord Webhook URL Input
	makeInput(whAcc, "Discord Webhook URL", "Webhook URL for automation updates (Leveling, Mutation & Elephant)",
		function() return CFG.webhookUrl end,
		function(txt) CFG.webhookUrl = txt; persist() end, 1)

	-- Test Webhook Connection (Button)
	makeButton(whAcc, "Test Webhook Connection", "Send a test notification to your Discord channel",
		function()
			if not CFG.webhookUrl or CFG.webhookUrl == "" then
				ctx.log("[Webhook Test] Gagal: Webhook URL kosong!")
				return
			end
			ctx.log("[Webhook Test] Mengirim test payload...")
			task.spawn(function()
				local sendWebhook = ctx.sendWebhook
				if sendWebhook then
					pcall(function()
						sendWebhook(CFG.webhookUrl, {
							embeds = {
								{
									title = "Webhook Connection Test",
									description = "Koneksi Discord Webhook berhasil tersambung dengan CeszParadise Garden!",
									color = 3066993, -- Green
									fields = {
										{
											name = "Profile :",
											value = string.format("> Username : ||%s||", ctx.LP.Name),
											inline = false
										}
									},
									footer = {
										text = os.date("%B %d | %I:%M %p"),
										icon_url = "https://raw.githubusercontent.com/milmscr/iniapa/main/cobainaja/Logo/logo_icon.png"
									}
								}
							}
						}, ctx)
					end)
				else
					ctx.log("[Webhook Test] Gagal meload modul sender.")
				end
			end)
		end, 2)

	-- Performance / Graphics Optimization Accordion
	local perfAcc = makeAccordion(pMiscPerf, "Performance", 1, true)
	makeToggle(perfAcc, "Hide My Garden Plants", "Hide plants on your own farm for better FPS",
		function() return CFG.hideMyPlants end,
		function(v) if ctx.setHidePlants then ctx.setHidePlants("mine", v) end; persist() end, 1)
	makeToggle(perfAcc, "Hide Other Gardens Plants", "Hide plants on other players' farms",
		function() return CFG.hideOtherPlants end,
		function(v) if ctx.setHidePlants then ctx.setHidePlants("other", v) end; persist() end, 2)
	makeToggle(perfAcc, "Auto Remove Spider Web FX", "Continuously remove spider web particle effects",
		function() return CFG.autoRemoveWebFx end,
		function(v) if ctx.setAutoRemoveWeb then ctx.setAutoRemoveWeb(v) end; persist() end, 3)
	mk("TextLabel", { Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, Text = "- [ Graphics Optimization ] -", Font = F.bold, TextSize = 12, TextColor3 = C.sub, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 4 }, perfAcc)
	makeSingleDropdown(perfAcc, "Performance Mode", "Off: normal. Low: matiin shadow. Extreme: matiin semua efek partikel.",
		function() return ctx.getPerfModeOptions() end,
		function() local m = CFG.perfMode or "off"; for _, o in ipairs(ctx.getPerfModeOptions()) do if o.name == m then return o.display end end return "Off" end,
		function(code) if ctx.setPerfMode then ctx.setPerfMode(code) end; persist() end, 5)
	makeToggle(perfAcc, "Disable 3D Rendering", "Stop rendering the 3D world (huge FPS, black screen)",
		function() return CFG.disable3d end,
		function(v) if ctx.setDisable3d then ctx.setDisable3d(v) end; persist() end, 6)
	makeSingleDropdown(perfAcc, "UI Theme", "Ganti tema warna tampilan Fluent",
		function() return { "PinkRoyale", "Rose", "Dark", "Darker", "Aqua", "Amethyst", "Light" } end,
		function() return (ctx.Fluent and ctx.Fluent.Theme) or "PinkRoyale" end,
		function(themeName)
			if ctx.Fluent and ctx.Fluent.SetTheme then
				ctx.Fluent:SetTheme(themeName)
				ctx.log("Tema antarmuka diubah ke: " .. themeName)
			end
		end, 7)

	ctx.refreshTradeStatus()
end
]=],
	["ui/theme.lua"] = [=[
--[[ theme.lua — palet warna PINK ROYALE ELEGAN + Fluent Theme Registration.
     Karakter: Midnight Velvet Rose, Shimmering Pearl, Radiant Hot Rose, Soft Neon Sakura. ]]
return function(ctx)
	local C = {
		bg        = Color3.fromRGB(15, 9, 20),         -- Deep obsidian velvet (solid & clean)
		panel     = Color3.fromRGB(24, 13, 31),        -- Dark luxury wine panel
		row       = Color3.fromRGB(36, 19, 46),        -- Card container
		rowAlt    = Color3.fromRGB(58, 28, 74),        -- Elevated card / active item
		rowHover  = Color3.fromRGB(72, 35, 92),        -- Hover state card
		stroke    = Color3.fromRGB(255, 95, 175),      -- Radiant rose-pink border
		strokeSub = Color3.fromRGB(130, 68, 140),      -- Clear border outline
		acc       = Color3.fromRGB(255, 55, 145),      -- Hot Radiant Rose (aksen utama)
		acc2      = Color3.fromRGB(255, 135, 205),     -- Soft Neon Sakura (gradient partner)
		accSoft   = Color3.fromRGB(255, 215, 240),     -- Pastel Rose Shimmer (teks aksen super terang)
		glow      = Color3.fromRGB(255, 60, 145),      -- Ambient glow
		txt       = Color3.fromRGB(255, 255, 255),     -- Pure White (teks utama ultra-tajam & kontras tinggi)
		sub       = Color3.fromRGB(235, 205, 235),     -- Light Soft Rose-Lilac (deskripsi & label sekunder)
		green     = Color3.fromRGB(110, 245, 185),     -- Luminous Mint-Emerald
		red       = Color3.fromRGB(255, 75, 120),      -- Passion Crimson Rose
	}

	local F = {
		title = Enum.Font.FredokaOne,       -- Judul / Header / Branding
		bold  = Enum.Font.MontserratBold,   -- Subheader / Tombol / Label Tebal
		semi  = Enum.Font.MontserratMedium, -- Dropdown item / Value pill
		reg   = Enum.Font.Ubuntu,           -- Deskripsi & isi teks
		code  = Enum.Font.Code,             -- Console logs
	}

	local function mk(cls, props, parent)
		local o = Instance.new(cls)
		for k, v in pairs(props) do o[k] = v end
		o.Parent = parent
		return o
	end

	local function corner(o, r)
		return mk("UICorner", { CornerRadius = UDim.new(0, r or 10) }, o)
	end

	local function stroke(o, col, thick, trans)
		return mk("UIStroke", {
			Color = col or C.strokeSub,
			Thickness = thick or 1.2,
			Transparency = trans or 0.35,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		}, o)
	end

	local function pad(o, l, r, t, b)
		return mk("UIPadding", {
			PaddingLeft = UDim.new(0, l),
			PaddingRight = UDim.new(0, r),
			PaddingTop = UDim.new(0, t),
			PaddingBottom = UDim.new(0, b),
		}, o)
	end

	local function grad(o, rot, col1, col2)
		return mk("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, col1 or C.acc),
				ColorSequenceKeypoint.new(1, col2 or C.acc2),
			}),
			Rotation = rot or 90,
		}, o)
	end

	-- Daftarkan Theme Pink Royale di Fluent
	local Fluent = ctx.Fluent or (getgenv and getgenv().Fluent)
	if Fluent and Fluent.AddTheme then
		Fluent:AddTheme({
			Name = "PinkRoyale",
			Accent = C.acc,
			AcrylicMain = C.bg,
			AcrylicBorder = C.strokeSub,
			AcrylicGradient = ColorSequence.new(Color3.fromRGB(26, 14, 34), Color3.fromRGB(15, 9, 20)),
			AcrylicNoise = 0.92,
			TitleBarLine = Color3.fromRGB(90, 45, 98),
			Tab = Color3.fromRGB(180, 140, 175),
			Element = C.row,
			ElementBorder = Color3.fromRGB(75, 40, 90),
			InElementBorder = C.strokeSub,
			ElementTransparency = 0.35,
			ToggleSlider = Color3.fromRGB(170, 130, 165),
			ToggleToggled = Color3.fromRGB(255, 255, 255),
			SliderRail = Color3.fromRGB(75, 40, 90),
			DropdownFrame = Color3.fromRGB(42, 22, 54),
			DropdownHolder = C.panel,
			DropdownBorder = C.strokeSub,
			DropdownOption = C.rowAlt,
			Keybind = Color3.fromRGB(42, 22, 54),
			Input = C.row,
			InputFocused = Color3.fromRGB(20, 10, 26),
			InputIndicator = C.acc,
			Dialog = Color3.fromRGB(26, 14, 34),
			DialogHolder = C.bg,
			DialogHolderLine = Color3.fromRGB(75, 40, 90),
			DialogButton = Color3.fromRGB(42, 22, 54),
			DialogButtonBorder = C.strokeSub,
			DialogBorder = Color3.fromRGB(95, 50, 105),
			DialogInput = C.row,
			DialogInputLine = C.acc,
			Text = C.txt,
			SubText = C.sub,
			Hover = C.rowHover,
			HoverChange = 0.08
		})
	end

	ctx.C      = C
	ctx.F      = F
	ctx.mk     = mk
	ctx.corner = corner
	ctx.stroke = stroke
	ctx.pad    = pad
	ctx.grad   = grad
end
]=],
	["ui/window.lua"] = [=[
--[[ window.lua — Jendela Utama Garden CeszParadiseHub (Fluent Mobile Remake)
     Fitur:
     - Built-in Draggable Floating Mobile Toggle Button
     - Auto-Adaptive Sizing & Mobile Screen Clamping
     - Frosted Glass 2D & Native Spring Physics
     - 100% integrasi tema Pink Royale
     - Toast notifications via Fluent:Notify
--]]

return function(ctx)
	local Fluent = ctx.Fluent or (getgenv and getgenv().Fluent)
	if not Fluent then
		-- Fallback jika belum ter-inject
		local ok, f = pcall(function() return loadstring(game:HttpGet("https://raw.githubusercontent.com/milmscr/iniapa/main/cobainaja/shared/fluent.lua"))() end)
		if ok and f then Fluent = f; ctx.Fluent = f end
	end

	local C = ctx.C
	local F = ctx.F

	----------------------------------------------------------------- Bersihkan GUI lama
	pcall(function()
		local host = (gethui and gethui()) or game:GetService("CoreGui")
		for _, nm in ipairs({ "GAGGarden", "CeszParadiseGarden", "AllegiaanGarden", "GAGSeller", "CeszParadiseTrade" }) do
			local old = host:FindFirstChild(nm); if old then old:Destroy() end
		end
		if ctx.LP and ctx.LP:FindFirstChild("PlayerGui") then
			for _, nm in ipairs({ "GAGGarden", "CeszParadiseGarden", "AllegiaanGarden", "GAGSeller", "CeszParadiseTrade" }) do
				local old = ctx.LP.PlayerGui:FindFirstChild(nm); if old then old:Destroy() end
			end
		end
	end)

	----------------------------------------------------------------- Buat Window Fluent Mobile
	local Window = Fluent:CreateWindow({
		Title = "CeszParadise",
		SubTitle = "Garden Edition ✦ Mobile",
		TabWidth = 155,
		Size = UDim2.fromOffset(580, 430),
		Theme = "PinkRoyale",
		MinimizeKey = Enum.KeyCode.LeftControl,
		MobileToggle = true,
		MobileToggleIcon = "sprout",
		MobileToggleSize = 46,
		AutoScaling = true,
		CollapsibleTabs = true
	})

	ctx.Window = Window
	ctx.state.window = Window
	ctx.state.gui = Fluent.GUI
	ctx.state.isAlive = true

	if Fluent.GUI then
		Fluent.GUI.Destroying:Connect(function()
			ctx.state.isAlive = false
		end)
	end

	----------------------------------------------------------------- Toast Notifications (ctx.notify)
	function ctx.notify(msg)
		if not msg then return end
		pcall(function()
			Fluent:Notify({
				Title = "CeszParadise Garden",
				Content = tostring(msg),
				Duration = 3.5
			})
		end)
	end

	----------------------------------------------------------------- Status Badge (ctx.setStatus)
	function ctx.setStatus(s)
		ctx.state.status = tostring(s):upper()
		pcall(function()
			if Window.SetSubTitle then
				Window:SetSubTitle(("Garden Edition ✦ %s"):format(ctx.state.status))
			end
		end)
	end

	----------------------------------------------------------------- Console Logger (ctx.log)
	local logLines = ctx.state.logLines or {}
	ctx.state.logLines = logLines
	function ctx.log(msg)
		local ts = os.date("%H:%M:%S")
		local line = ("[%s] %s"):format(ts, tostring(msg))
		table.insert(logLines, line)
		if #logLines > 80 then table.remove(logLines, 1) end
		if ctx.ui and ctx.ui.logBox then
			pcall(function() ctx.ui.logBox.Text = table.concat(logLines, "\n") end)
		end
		print("[CeszParadise/Garden] " .. tostring(msg))
	end

	----------------------------------------------------------------- Tab Navigation
	ctx.ui = ctx.ui or {}
	ctx.ui.pages = ctx.ui.pages or {}
	ctx.ui.tabBtns = ctx.ui.tabBtns or {}
	local tabIndices = {}
	ctx.tabIndices = tabIndices

	function ctx.selectTab(nameOrIdx)
		local idx = type(nameOrIdx) == "number" and nameOrIdx or tabIndices[nameOrIdx]
		if idx and Window.SelectTab then
			Window:SelectTab(idx)
		end
	end

	ctx.ui.main = Window.Root or (Fluent.GUI and Fluent.GUI:FindFirstChildWhichIsA("Frame"))
end
]=],
}
