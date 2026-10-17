-- AUTO-GENERATED oleh tools/bundle.js — JANGAN edit manual.
-- Edit modul-nya langsung, terus run `node tools/bundle.js`.
-- 15 modul, di-generate 2026-10-17T00:58:34.658Z
return {
	["app.lua"] = [=[
--[[ app.lua — inisialisasi akhir: default page, supervisor auto-claim, auto-resume. ]]
return function(ctx)
	local CFG     = ctx.CFG
	local pages   = ctx.ui.pages
	local tabBtns = ctx.ui.tabBtns
	local C       = ctx.C
	local function log(msg) ctx.log(msg) end

	------------------------------------------------------------------ Default page
	pages["Sell"].Visible = true
	tabBtns["Sell"].btn.BackgroundTransparency = 0.86
	tabBtns["Sell"].btn.TextColor3 = C.txt
	tabBtns["Sell"].line.Visible = true

	log("CeszParadise GAG Seller v1.2.5 dimuat.")
	pcall(function()
		local Players = ctx.Services.Players or game:GetService("Players")
		log(("Masuk server: %d/%d pemain."):format(#Players:GetPlayers(), Players.MaxPlayers))
	end)
	ctx.renderInventory()

	------------------------------------------------------------------ Anti-AFK
	-- Roblox nendang setelah ~20 menit idle. Event LocalPlayer.Idled fire tepat sebelum kick;
	-- kita simulasi input (VirtualUser) buat reset timer idle-nya -> nggak ke-kick.
	pcall(function()
		local VirtualUser = game:GetService("VirtualUser")
		ctx.LP.Idled:Connect(function()
			pcall(function()
				VirtualUser:CaptureController()
				VirtualUser:ClickButton2(Vector2.new())
			end)
			log("Anti-AFK: reset idle timer.")
		end)
		log("Anti-AFK aktif.")
	end)

	------------------------------------------------------------------ Auto-Reconnect
	-- Kalau ke-kick / DC / error (dialog Roblox muncul) -> otomatis rejoin ke game yg sama,
	-- lalu hub di-load ulang di server baru (via queue_on_teleport). Ikut branch aktif.
	pcall(function()
		local GuiService = game:GetService("GuiService")
		local TeleportService = game:GetService("TeleportService")
		local branch = (getgenv and getgenv().GAG_BRANCH) or "main"
		local RECON = ("getgenv().GAG_BRANCH='%s';loadstring(game:HttpGet('https://raw.githubusercontent.com/milmscr/iniapa/%s/cobainaja/init.lua'))()"):format(branch, branch)
		local reconnecting = false
		local function reconnect()
			if reconnecting or CFG.autoReconnect == false then return end -- cek toggle real-time
			reconnecting = true
			log("Ke-DC/kick terdeteksi — auto reconnect...")
			local q = queue_on_teleport or queueonteleport or (syn and syn.queue_on_teleport)
			if q then pcall(function() q(RECON) end) end
			task.wait(3)
			pcall(function() TeleportService:Teleport(game.PlaceId, ctx.LP) end)
			-- fallback: kalau teleport gagal (place instance), coba matchmaking biasa
			task.wait(8)
			pcall(function() TeleportService:Teleport(game.PlaceId, ctx.LP) end)
		end
		GuiService.ErrorMessageChanged:Connect(reconnect)
		log("Auto-Reconnect aktif.")
	end)

	------------------------------------------------------------------ Auto Claim Supervisor Loop
	task.spawn(function()
		ctx.elevate()
		local lastState
		while ctx.alive() do
			local delay = 3
			local ok, err = pcall(function()
				if CFG.autoClaim then
					local owns, data, boothName = ctx.ownsBooth()
					if owns then
						if lastState ~= "own" then log("Booth aman: " .. tostring(boothName)); lastState = "own" end
						ctx.autoSwitchBoothPortal()
						delay = 6
					else
						if lastState ~= "hunt" then log("Booth hilang, mencari terdekat..."); lastState = "hunt" end
						ctx.tryClaimNearest()
						delay = 5
					end
				else
					lastState = nil
					delay = 1
				end
			end)
			if not ok then log("claim-loop err: " .. tostring(err)) end
			task.wait(delay)
		end
	end)

	------------------------------------------------------------------ Auto Resume
	-- Tunggu web sync PULL config dulu (max ~10s) biar setting web (autoSell) ke-apply
	-- sebelum loop nyala, lalu cek ULANG CFG.autoSell.
	task.spawn(function()
		local t = 0
		while not ctx.state.webSyncReady and t < 10 do task.wait(0.3); t = t + 0.3 end
		task.wait(1.0)
		if CFG.autoSell then
			ctx.state.running = true
			if ctx.ui.rAutoToggle then ctx.ui.rAutoToggle() end
			task.spawn(ctx.mainLoop)
			log("Auto-resume: loop dinyalakan.")
		end
	end)
end
]=],
	["modules/buy/sniper.lua"] = [=[
--[[ sniper.lua — Auto Snipe / Auto Buy pet dari booth pemain lain (Trade World).
     5 profil (pet types + mutation + max price, urutan = prioritas). Scan listing
     booth, beli otomatis kalau cocok & seller hadir. Kalau ga ada target -> cari
     seller lintas server (FindSellers) lalu TeleportToListing (auto server-hop).
     Beli: TradeEvents.Booths.BuyListing:InvokeServer(ownerPlayer, listingUUID).
     Mengisi: ctx.startSnipe, ctx.stopSnipe, ctx.getSnipeStatus ]]
return function(ctx)
	local RS              = ctx.Services.RS
	local Players         = ctx.Services.Players
	local HttpService     = ctx.Services.HttpService
	local TeleportService = game:GetService("TeleportService")
	local LP  = ctx.LP
	local CFG = ctx.CFG
	local RR                = ctx.deps.RR
	local DataService       = ctx.deps.DataService
	local BuyListing        = ctx.deps.BuyListing
	local FindSellers       = ctx.deps.FindSellers
	local TeleportToListing = ctx.deps.TeleportToListing
	local TokenRAPUtil      = ctx.deps.TokenRAPUtil
	local comboKey   = ctx.reg.comboKey
	local mutDisplay = ctx.reg.mutDisplay
	local NUM = ctx.NUM_SNIPE or 5
	local function log(m) ctx.log(m) end
	local function setStatus(s) ctx.setStatus(s) end
	-- running = toggle ON DAN GUI instance ini masih hidup. Cek ctx.alive() penting:
	-- kalau hub ke-load 2x (auto-exec + queue_on_teleport), instance lama yang GUI-nya
	-- di-destroy langsung berhenti -> ga ada dobel sniper.
	local function running() return ctx.state.snipeRunning == true and ctx.alive() end

	local ROUTER = "loadstring(game:HttpGet('https://raw.githubusercontent.com/milmscr/iniapa/main/cobainaja/init.lua'))()"

	------------------------------------------------------------------ helpers
	local function buildItemData(petType)
		if TokenRAPUtil and TokenRAPUtil.GetDefaultItemData then
			local ok, d = pcall(function() return TokenRAPUtil.GetDefaultItemData("Pet", petType) end)
			if ok and d then return d end
		end
		return { PetType = petType, PetData = { MutationType = "Normal", Level = 0, LevelProgress = 0, Hunger = 0, BaseWeight = 1, Boosts = {} }, PetAbility = {} }
	end

	local function getTokens()
		local ok, data = pcall(function() return DataService:GetData() end)
		if ok and type(data) == "table" and type(data.TradeData) == "table" then
			return data.TradeData.Tokens or 0
		end
		return math.huge
	end
	local function ownerToUserId(owner) return tonumber((tostring(owner):gsub("Player_", ""))) end

	-- cari target dari data booth, cocokkan ke profil (index profil = prioritas)
	local function collectTargets()
		local ok, data = pcall(function() return RR.new("Booths"):GetDataAsync() end)
		local targets = {}
		if not ok or not data then return targets end
		for _, b in pairs(data.Booths or {}) do
			local owner = b.Owner
			local pd = owner and data.Players and data.Players[owner]
			if pd and pd.Listings then
				for lid, l in pairs(pd.Listings) do
					local it = pd.Items and pd.Items[l.ItemId]
					local p  = it and it.PetData
					if p and it.PetType then
						local disp = mutDisplay(p.MutationType)
						local key  = comboKey(it.PetType, p.HatchedFrom or "?")
						for pi = 1, NUM do
							local prof = CFG.snipeProfiles[pi]
							-- match by kombinasi Pet - Egg (bedakan egg premium vs biasa)
							if prof and next(prof.pets) and prof.pets[key] then
								local mutOK   = (not next(prof.muts)) or prof.muts[disp]
								local priceOK = (prof.maxPrice or 0) <= 0 or l.Price <= prof.maxPrice
								if mutOK and priceOK then
									local ply = Players:GetPlayerByUserId(ownerToUserId(owner))
									targets[#targets + 1] = {
										profile = pi, pet = it.PetType, name = p.Name,
										mut = disp, price = l.Price, uuid = lid,
										owner = ply, present = ply ~= nil,
									}
									break -- profil prioritas tertinggi menang
								end
							end
						end
					end
				end
			end
		end
		table.sort(targets, function(a, b)
			if a.profile ~= b.profile then return a.profile < b.profile end
			return a.price < b.price
		end)
		return targets
	end

	------------------------------------------------------------------ webhook notif beli
	local function inventoryCounts()
		local counts = {}
		local ok, data = pcall(function() return DataService:GetData() end)
		if ok and type(data) == "table" and data.PetsData and data.PetsData.PetInventory and data.PetsData.PetInventory.Data then
			for _, v in pairs(data.PetsData.PetInventory.Data) do
				local pt = v and v.PetType
				if pt then counts[pt] = (counts[pt] or 0) + 1 end
			end
		end
		return counts
	end
	local function snipeSelectedTypes()
		local set, order = {}, {}
		for pi = 1, NUM do
			for petKey in pairs(CFG.snipeProfiles[pi].pets) do
				local pt = (string.split(petKey, " - ")[1]) or petKey -- ambil nama pet dari kombo
				if not set[pt] then set[pt] = true; order[#order + 1] = pt end
			end
		end
		table.sort(order)
		return order
	end
	local function buildSnipeSummary()
		local counts = inventoryCounts()
		local lines, total = {}, 0
		for _, pt in ipairs(snipeSelectedTypes()) do
			local c = counts[pt] or 0
			total = total + c
			lines[#lines + 1] = ("%s: %d"):format(pt, c)
		end
		return (#lines > 0 and table.concat(lines, "\n") or "-"), total
	end
	local function notifyBuy(t)
		if not ctx.sendWebhook then return end
		local seller = (t.owner and (t.owner.DisplayName or t.owner.Name)) or "?"
		local summary, total = buildSnipeSummary()
		local tok = getTokens(); tok = (tok == math.huge) and "?" or tostring(tok)
		ctx.sendWebhook({
			username = "CeszParadise GAG Sniper",
			embeds = {{
				title = "✅ Pet Sniped!",
				color = 3066993,
				fields = {
					{ name = "Pet",      value = tostring(t.pet),   inline = true },
					{ name = "Mutation", value = tostring(t.mut),   inline = true },
					{ name = "Price",    value = tostring(t.price) .. " Tokens", inline = true },
					{ name = "Nickname", value = tostring(t.name),  inline = true },
					{ name = "Profile",  value = "Snipe " .. t.profile, inline = true },
					{ name = "Seller",   value = "@" .. seller,     inline = true },
					{ name = ("📊 Total Punya (%d)"):format(total), value = summary, inline = false },
					{ name = "💰 Sisa Token", value = tok .. " Tokens", inline = false },
				},
				footer = { text = "JobId: " .. tostring(game.JobId) },
			}},
		})
		if ctx.reportEvent then
			ctx.reportEvent("buy", {
				pet = tostring(t.pet),
				mutation = (t.mut and t.mut ~= "None" and t.mut ~= "Normal") and tostring(t.mut) or nil,
				price = tonumber(t.price) or 0,
				counterpart = tostring(seller),
			})
		end
	end

	------------------------------------------------------------------ server hop (cari seller)
	local HUB_FOLDER = "AllegiaantHUB"
	local function ensureHubFolder()
		if type(makefolder) == "function" and (type(isfolder) ~= "function" or not isfolder(HUB_FOLDER)) then
			pcall(function() makefolder(HUB_FOLDER) end)
		end
	end
	ensureHubFolder()
	local HOP_FILE = HUB_FOLDER .. "/snipehops.json"
	local function revisitTTL() return math.max(5, math.floor(tonumber(CFG.snipeRevisitSec) or 120)) end
	local visited  = {}
	do
		if type(isfile) == "function" and isfile(HOP_FILE) then
			local ok, d = pcall(function() return HttpService:JSONDecode(readfile(HOP_FILE)) end)
			if ok and type(d) == "table" then
				local now, ttl = os.time(), revisitTTL()
				for job, ts in pairs(d) do if type(ts) == "number" and (now - ts) < ttl then visited[job] = ts end end
			end
		end
	end
	local function saveVisited() pcall(function() writefile(HOP_FILE, HttpService:JSONEncode(visited)) end) end
	local function markVisited(job) if job and job ~= "" then visited[job] = os.time(); saveVisited() end end
	-- Kalau kita SALAH MENDARAT di server yg udah divisit (taksi/matchmaking bawa balik),
	-- JANGAN reset timestamp -> CD tetap dihitung dari kunjungan PERTAMA. Landing pertama
	-- (belum ada di visited) baru dicatat.
	local reLanded = visited[game.JobId] ~= nil
	if not reLanded then markVisited(game.JobId) end
	ctx.state.snipeReLanded = reLanded

	-- Prune TTL secara real-time (bukan cuma saat load) -> "semua visited" self-heal
	-- setelah 2 menit walau ga reload, jadi server lama bisa dikunjungi lagi.
	local function pruneVisited()
		local now, ttl = os.time(), revisitTTL()
		for job, ts in pairs(visited) do
			if type(ts) ~= "number" or (now - ts) >= ttl then visited[job] = nil end
		end
	end

	-- Ambil BANYAK server publik (paginate) + CACHE ke file (TTL 45s) biar ga fetch tiap
	-- hop -> request ke games.roblox.com turun drastis -> ga kena rate-limit 429.
	local SLIST_FILE, SLIST_TTL = HUB_FOLDER .. "/serverlist.json", 45
	local function fetchAllServers()
		-- 1. pakai cache kalau masih fresh (< TTL)
		if type(isfile) == "function" and isfile(SLIST_FILE) then
			local ok, c = pcall(function() return HttpService:JSONDecode(readfile(SLIST_FILE)) end)
			if ok and type(c) == "table" and type(c.servers) == "table"
				and (os.time() - (tonumber(c.time) or 0)) < SLIST_TTL and #c.servers > 0 then
				return c.servers
			end
		end
		-- 2. fetch fresh (paginate)
		local reqFn = (syn and syn.request) or (http and http.request) or http_request or request
		if not reqFn then return nil end
		local all, cursor, tries = {}, nil, 0
		repeat
			local url = ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Desc&limit=100"):format(game.PlaceId)
			if cursor then url = url .. "&cursor=" .. cursor end
			local ok, res = pcall(reqFn, { Url = url, Method = "GET" })
			if not ok or not res or not res.Body then break end
			local ok2, data = pcall(function() return HttpService:JSONDecode(res.Body) end)
			if not ok2 or type(data) ~= "table" or type(data.data) ~= "table" then break end
			-- simpan super-ringkas: cuma id+playing (maxPlayers default 30 di getBusyServerList)
			for _, s in ipairs(data.data) do all[#all + 1] = { id = s.id, playing = s.playing } end
			cursor = data.nextPageCursor
			tries = tries + 1
		until not cursor or tries >= 5 or #all >= 400
		if #all > 0 then
			pcall(function() writefile(SLIST_FILE, HttpService:JSONEncode({ time = os.time(), servers = all })) end)
			return all
		end
		return nil
	end

	-- Pilih server acak: prioritas pemain >= minPop; kalau ga ada, ambil APA PUN yang
	-- belum divisit & ada slot (biar selalu gerak, ga nyangkut/ngulang server sama).
	-- SLOT_BUFFER: minimal slot kosong biar ga keburu penuh pas teleport (kurangi 771 "penuh").
	local SLOT_BUFFER = 1 -- cuma buang server BENER-BENER penuh (30/30); terima 29/30 (771 udah dihandle)
	-- Fetch server list SEKALI, balik daftar kandidat (acak). Dipakai buat retry banyak
	-- server tanpa re-fetch tiap kali (hindari rate-limit API).
	local function getBusyServerList(minPop, n)
		local servers = fetchAllServers()
		if not servers then return {} end
		local busy, any = {}, {}
		for _, s in ipairs(servers) do
			local playing = tonumber(s.playing) or 0
			local maxp = tonumber(s.maxPlayers) or 30
			if s.id ~= game.JobId and not visited[s.id] and playing <= (maxp - SLOT_BUFFER) then
				any[#any + 1] = s.id
				if playing >= minPop then busy[#busy + 1] = s.id end
			end
		end
		local pool = (#busy > 0) and busy or any
		-- acak (Fisher-Yates) lalu ambil n teratas
		for i = #pool, 2, -1 do local j = math.random(1, i); pool[i], pool[j] = pool[j], pool[i] end
		local out = {}
		for i = 1, math.min(n or 5, #pool) do out[i] = pool[i] end
		return out
	end

	local function queueResume()
		local q = queue_on_teleport or queueonteleport or (syn and syn.queue_on_teleport)
		if q then pcall(function() q(ROUTER) end) end
		-- Kabari agent Termux lagi hop (biar ga di-relaunch pas telemetry di server baru
		-- belum sempet load). Ini jalan tiap hop, ga nunggu telemetry — lebih reliable.
		pcall(function()
			local req = (syn and syn.request) or (http and http.request) or http_request or request
			if not req then return end
			req({
				Url = "https://api.allegiaant.my.id/api/agent/suppress",
				Method = "POST",
				Headers = { ["Content-Type"] = "application/json", ["x-api-key"] = "ae3858d4a2def3306d6cbff26ff2bd72eee9319b1aae27d1" },
				Body = game:GetService("HttpService"):JSONEncode({
					userId = game:GetService("Players").LocalPlayer.UserId,
					seconds = 120,
				}),
			})
		end)
	end

	local hopInProgress = false
	local function serverHop()
		if not CFG.snipeHop or hopInProgress then return end
		hopInProgress = true
		queueResume()

		local searchTargets, seen = {}, {}
		for pi = 1, NUM do
			for petKey in pairs(CFG.snipeProfiles[pi].pets) do
				local pt = (string.split(petKey, " - ")[1]) or petKey -- FindSellers butuh nama pet
				if not seen[pt] then seen[pt] = true; searchTargets[#searchTargets + 1] = pt end
			end
		end

		local function findJobId(tbl)
			if type(tbl) ~= "table" then return nil end
			for _, v in pairs(tbl) do
				if type(v) == "string" and v:match("^%w+-%w+-%w+-%w+-%w+$") then return v
				elseif type(v) == "table" then local r = findJobId(v); if r then return r end end
			end
			return nil
		end

		-- Deteksi teleport gagal (mis. 771 = server ga tersedia) biar cepat coba server lain.
		local tpFailed, failStreak = false, 0
		local conn = TeleportService.TeleportInitFailed:Connect(function(plr, _, msg)
			if plr == LP then tpFailed = true; log("Snipe: teleport gagal (" .. tostring(msg) .. "), coba server lain") end
		end)

		-- Seller hop: pakai teleport resmi game (robust, jarang 771). Cek visited udah di caller.
		-- Landing kadang beda dari jobId (revisit CD harmless), tapi ga bikin dialog 771.
		local function hopViaListing(tpData, jobId)
			tpFailed = false
			if jobId then markVisited(jobId) end
			task.wait(0.35) -- flush writefile sebelum teleport
			pcall(function() TeleportToListing:InvokeServer(tpData, true) end)
			local t0 = os.clock()
			repeat task.wait(0.25) until (not running()) or tpFailed or (os.clock() - t0) >= 4
			return not tpFailed
		end

		-- Busy hop: teleport ke instance spesifik (kontrol populasi). Gagal cepat -> coba lain.
		-- Gagal terus -> matchmaking (ga kena 771).
		local function hopTo(jobId)
			tpFailed = false
			markVisited(jobId)
			task.wait(0.35) -- flush writefile dulu (emulator lambat) sebelum teleport
			pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, jobId, LP) end)
			local t0 = os.clock()
			repeat task.wait(0.25) until (not running()) or tpFailed or (os.clock() - t0) >= 4
			if tpFailed then
				failStreak = failStreak + 1
				if failStreak >= 3 then -- join instance gagal terus -> matchmaking biasa (ga 771)
					failStreak = 0
					setStatus("Snipe: join gagal terus, teleport matchmaking...")
					pcall(function() TeleportService:Teleport(game.PlaceId, LP) end)
					local t2 = os.clock()
					repeat task.wait(0.5) until (not running()) or (os.clock() - t2) >= 8
				end
			end
			return not tpFailed
		end

		local function attempt()
			while running() do
				pruneVisited() -- TTL real-time: server lama kadaluarsa walau ga reload
				for i = #searchTargets, 2, -1 do
					local j = math.random(1, i); searchTargets[i], searchTargets[j] = searchTargets[j], searchTargets[i]
				end
				-- FILTER 1: Hop by Index (FindSellers / cari seller lintas server)
				if CFG.snipeHopIndex and #searchTargets > 0 then
					setStatus("Snipe: cari seller online...")
					-- GAME batasi FindSellers ~5 detik/panggilan ("Please wait Xs before finding
					-- another seller"). Jadi panggil CUMA 1 pet/hop (di-acak, semua kebagian lintas
					-- hop). Sisanya andalkan scan booth lokal + busy hop (ga ada cooldown).
					for idx, petType in ipairs(searchTargets) do
						if idx > 1 then break end
						if not running() then return end
						setStatus(("Snipe: cari seller %s"):format(petType))
						local itemData = buildItemData(petType)
						local ok, success, tpData = pcall(function()
							return FindSellers:InvokeServer("Pet", itemData)
						end)
						if ok and success and tpData then
							local targetJobId = (type(tpData) == "string" and tpData) or findJobId(tpData)
							if targetJobId == game.JobId then
								-- seller di server ini (harga > limit) -> lewati
							elseif targetJobId and visited[targetJobId] then
								-- sudah dikunjungi dalam TTL -> skip
							elseif targetJobId then
								setStatus(("Snipe: seller ketemu! TP (%s)..."):format(petType))
								hopViaListing(tpData, targetJobId) -- taksi game (robust); sukses -> unload
								if not running() then return end
							end
						end
						if not running() then return end
						-- cuma 1 FindSellers/hop -> ga perlu jeda anti rate-limit besar
					end
				end
				if not running() then return end
				-- FILTER 2: Hop by Player (server berdasarkan Min Players; set 1 = semua server).
				-- Tetap hormati revisit CD (getBusyServer exclude visited).
				local hopped = false
				if CFG.snipeHopPlayer then
					local minPop = math.max(1, math.floor(tonumber(CFG.snipeMinPop) or 25))
					-- Fetch daftar server SEKALI (hindari rate-limit), coba kandidat satu-satu:
					-- gagal (full/771) -> langsung server berikutnya. Sukses -> game unload.
					local candidates = getBusyServerList(minPop, 5)
					for _, busy in ipairs(candidates) do
						if not running() then return end
						setStatus(("Snipe: hop by player (>=%d)..."):format(minPop))
						hopTo(busy) -- sukses -> unload; gagal (~0.5s) -> kandidat berikutnya
						hopped = true
					end
				end
				if not running() then return end
				if not hopped then
					if CFG.snipeHopPlayer then
						-- pool kosong (semua kevisit/penuh) -> matchmaking biar ga stall 3s.
						setStatus("Snipe: server habis/kevisit, teleport matchmaking...")
						pcall(function() TeleportService:Teleport(game.PlaceId, LP) end)
						local t0 = os.clock()
						repeat task.wait(0.5) until (not running()) or (os.clock() - t0) >= 8
					else
						setStatus("Snipe: hop mati, tunggu 3s...")
						task.wait(3)
					end
				end
			end
		end

		attempt()
		if conn then conn:Disconnect() end
		hopInProgress = false
	end

	------------------------------------------------------------------ core loop
	local function anyProfileActive()
		for i = 1, NUM do if next(CFG.snipeProfiles[i].pets) then return true end end
		return false
	end
	local function buyPass()
		local targets = collectTargets()
		local buyable, bought = 0, 0
		for _, t in ipairs(targets) do
			if not running() then break end
			if t.present then
				buyable = buyable + 1
				if getTokens() >= t.price then
					local ok, success, m = pcall(function() return BuyListing:InvokeServer(t.owner, t.uuid) end)
					if ok and success then
						bought = bought + 1
						log(("BUY %s [%s] @%d (Snipe %d)"):format(t.pet, t.mut, t.price, t.profile))
						notifyBuy(t)
					else
						log(("FAIL %s @%d (%s)"):format(t.pet, t.price, tostring(m or success)))
					end
					task.wait(0.6)
				end
			end
		end
		return #targets, buyable, bought
	end

	local function mainLoop()
		while running() do
			if not anyProfileActive() then
				setStatus("Snipe: pilih pet di profil dulu")
				task.wait(2)
			else
				setStatus(("Snipe: scan... Token:%s"):format(tostring(getTokens())))
				local total, buyable, bought = buyPass()
				if not running() then break end
				setStatus(("Snipe: target %d beli %d Token:%s"):format(total, bought, tostring(getTokens())))
				if buyable > 0 and bought > 0 then
					task.wait(3)
				elseif CFG.snipeHop then
					setStatus("Snipe: ga ada target, hop...")
					task.wait(0.5); serverHop(); break -- pre-hop dipangkas 2s -> 0.5s
				else
					task.wait(3)
				end
			end
		end
	end

	------------------------------------------------------------------ status utk GUI
	function ctx.getSnipeStatus()
		local parts = {}
		for i = 1, NUM do
			local pr = CFG.snipeProfiles[i]
			if next(pr.pets) then
				local first; for pt in pairs(pr.pets) do first = pt; break end
				parts[#parts + 1] = ("[P%d] %s | Max %s"):format(i, first or "?", (pr.maxPrice or 0) > 0 and pr.maxPrice or "∞")
			end
		end
		return {
			on = CFG.snipeEnabled == true,
			lines = #parts > 0 and table.concat(parts, "\n") or "No profile set",
		}
	end

	function ctx.startSnipe()
		if running() then return end
		ctx.state.snipeRunning = true
		hopInProgress = false
		task.spawn(mainLoop)
	end
	function ctx.stopSnipe()
		ctx.state.snipeRunning = false
		hopInProgress = false
	end

	-- auto-resume setelah hop / rejoin.
	-- Tunggu web sync PULL config dulu (max ~10s) biar setting web (mis. snipe di-OFF-in)
	-- ke-apply sebelum snipe nyala & hop lagi. Tanpa ini, hop cepat bikin config web ga
	-- pernah ke-apply. Habis nunggu, cek ULANG CFG.snipeEnabled (bisa udah jadi false dari web).
	if CFG.snipeEnabled then
		task.spawn(function()
			local t = 0
			while not ctx.state.webSyncReady and t < 10 do task.wait(0.3); t = t + 0.3 end
			task.wait(1.0)
			if CFG.snipeEnabled then
				ctx.startSnipe()
				log("Auto-resume: Snipe ON.")
			else
				log("Snipe di-OFF dari web — tidak auto-resume.")
			end
		end)
	end
end
]=],
	["modules/core/config.lua"] = [=[
--[[ config.lua — konfigurasi default + persist/load state ke JSON.
     Mengisi: ctx.NUM_PROFILES, ctx.NUM_LISTINGS, ctx.CFG,
              ctx.persistState, ctx.loadState ]]
return function(ctx)
    local HttpService = ctx.Services.HttpService

    local NUM_PROFILES = 3
    local NUM_LISTINGS = 3
    local NUM_SNIPE    = 5

    local CFG = {
        autoSell         = false,
        autoClaim        = true,
        autoSwitchPortal = false,
        autoReconnect    = true,  -- auto rejoin kalau ke-kick/DC
        boothSkin        = "Default",
        profiles         = {},
        webhookUrl       = "",
        webhookEnabled   = false,
        relocateEnabled    = false,
        relocateIdleMin    = 20,
        relocateMinPlayers = 10,
        relocatePreferred  = 20,
        -- sniper / auto-buy
        snipeEnabled       = false,
        snipeHop           = true,  -- master enable hop
        snipeHopIndex      = true,  -- filter: hop by index (FindSellers / cari seller)
        snipeHopPlayer     = true,  -- filter: hop by player (server berdasarkan Min Players)
        snipeMinPop        = 25,   -- hop by player: server dgn pemain >= ini (set 1 = semua server)
        snipeRevisitSec    = 120,  -- jeda sebelum boleh balik ke server yang sama (detik)
        snipeProfiles      = {},
    }
    for i = 1, NUM_SNIPE do
        CFG.snipeProfiles[i] = { pets = {}, muts = {}, maxPrice = 0 }
    end
    for i = 1, NUM_PROFILES do
        CFG.profiles[i] = { listings = {} }
        for j = 1, NUM_LISTINGS do
            CFG.profiles[i].listings[j] = { pets = {}, muts = {}, minW = 0, maxW = 0, maxList = 0, price = 100 }
        end
    end

    -- Pastikan LocalPlayer dan UserId sudah siap (hindari nil)
    local Players = ctx.Services.Players or game:GetService("Players")
    local localPlayer = Players.LocalPlayer
    while not localPlayer do
        Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
        localPlayer = Players.LocalPlayer
    end
    local userId = localPlayer.UserId

    -- Setiap clone punya file terpisah (contoh: trade_state_12345.json)
    local STATE_FILE = "trade_state_" .. tostring(userId) .. ".json"

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

    ----------------------------------------------------------------- restore
    do
        local st = loadState()
        if st then
            if st.autoClaim ~= nil then CFG.autoClaim = st.autoClaim end
            if st.autoSwitchPortal ~= nil then CFG.autoSwitchPortal = st.autoSwitchPortal end
            if st.autoReconnect ~= nil then CFG.autoReconnect = st.autoReconnect end
            CFG.boothSkin       = st.boothSkin or "Default"
            CFG.autoSell        = st.autoSell or false
            CFG.webhookUrl      = st.webhookUrl or ""
            CFG.webhookEnabled  = st.webhookEnabled or false
            CFG.relocateEnabled    = st.relocateEnabled or false
            if st.relocateIdleMin    ~= nil then CFG.relocateIdleMin    = tonumber(st.relocateIdleMin) or 20 end
            if st.relocateMinPlayers ~= nil then CFG.relocateMinPlayers = tonumber(st.relocateMinPlayers) or 10 end
            if st.relocatePreferred  ~= nil then CFG.relocatePreferred  = tonumber(st.relocatePreferred) or 20 end
            CFG.snipeEnabled = st.snipeEnabled or false
            if st.snipeHop ~= nil then CFG.snipeHop = st.snipeHop end
            if st.snipeHopIndex ~= nil then CFG.snipeHopIndex = st.snipeHopIndex end
            if st.snipeHopPlayer ~= nil then CFG.snipeHopPlayer = st.snipeHopPlayer end
            if st.snipeMinPop ~= nil then CFG.snipeMinPop = tonumber(st.snipeMinPop) or 25 end
            if st.snipeRevisitSec ~= nil then CFG.snipeRevisitSec = tonumber(st.snipeRevisitSec) or 120 end
            if type(st.snipeProfiles) == "table" then
                for i = 1, NUM_SNIPE do
                    local sp = st.snipeProfiles[i] or st.snipeProfiles[tostring(i)]
                    if type(sp) == "table" then
                        CFG.snipeProfiles[i].pets     = (type(sp.pets) == "table") and sp.pets or {}
                        CFG.snipeProfiles[i].muts     = (type(sp.muts) == "table") and sp.muts or {}
                        CFG.snipeProfiles[i].maxPrice = tonumber(sp.maxPrice) or 0
                    end
                end
            end
            if type(st.profiles) == "table" then
                for i = 1, NUM_PROFILES do
                    local sp = st.profiles[i] or st.profiles[tostring(i)]
                    if type(sp) == "table" and type(sp.listings) == "table" then
                        for j = 1, NUM_LISTINGS do
                            local sl = sp.listings[j] or sp.listings[tostring(j)]
                            if type(sl) == "table" then
                                CFG.profiles[i].listings[j].pets    = (type(sl.pets) == "table") and sl.pets or {}
                                CFG.profiles[i].listings[j].muts    = (type(sl.muts) == "table") and sl.muts or {}
                                CFG.profiles[i].listings[j].minW    = tonumber(sl.minW) or 0
                                CFG.profiles[i].listings[j].maxW    = tonumber(sl.maxW) or 0
                                CFG.profiles[i].listings[j].maxList = tonumber(sl.maxList) or 0
                                CFG.profiles[i].listings[j].price   = tonumber(sl.price) or 100
                            end
                        end
                    end
                end
            end
        end
    end

    ctx.NUM_PROFILES = NUM_PROFILES
    ctx.NUM_LISTINGS = NUM_LISTINGS
    ctx.NUM_SNIPE    = NUM_SNIPE
    ctx.CFG          = CFG
    ctx.persistState = persistState
    ctx.loadState    = loadState
end
]=],
	["modules/core/registry.lua"] = [=[
--[[ registry.lua — bangun opsi dropdown dari data game.
     Mengisi: ctx.reg = { comboKey, mutDisplay, PET_OPTIONS, MUT_OPTIONS, SKIN_OPTIONS } ]]
return function(ctx)
	local PetEggs   = ctx.deps.PetEggs
	local PetList   = ctx.deps.PetList or {}
	local EnumToMut = ctx.deps.EnumToMut
	local SkinsReg  = ctx.deps.SkinsReg

	-- Map nama pet -> asset id icon (dari PetList[pet].Icon = "rbxassetid://123").
	local PET_ICONS = {}
	for petName, d in pairs(PetList) do
		if type(d) == "table" and d.Icon then
			local id = tostring(d.Icon):match("(%d+)")
			if id then PET_ICONS[tostring(petName)] = id end
		end
	end

	-- opsi dropdown = kombinasi "Pet - Egg"
	local function comboKey(petType, egg)
		return tostring(petType) .. " - " .. tostring(egg)
	end

	----------------------------------------------------------------- PET_OPTIONS
	local PET_OPTIONS = {}
	do
		local seen = {}
		for eggName, egg in pairs(PetEggs) do
			local items = egg.RarityData and egg.RarityData.Items
			if items then
				for petName in pairs(items) do
					if not tostring(petName):match("^Egg/") then
						local nameStr = tostring(petName)
						if not seen[nameStr] then
							seen[nameStr] = true
							PET_OPTIONS[#PET_OPTIONS + 1] = nameStr
						end
					end
				end
			end
		end
		table.sort(PET_OPTIONS)
	end

	----------------------------------------------------------------- PET_COMBO_OPTIONS (Pet - Egg)
	-- Bedakan pet per egg (premium vs biasa). Dipakai snipe biar bisa target spesifik.
	local PET_COMBO_OPTIONS = {}
	do
		local seen = {}
		for eggName, egg in pairs(PetEggs) do
			local items = egg.RarityData and egg.RarityData.Items
			if items then
				for petName in pairs(items) do
					if not tostring(petName):match("^Egg/") then
						local k = comboKey(petName, eggName)
						if not seen[k] then seen[k] = true; PET_COMBO_OPTIONS[#PET_COMBO_OPTIONS + 1] = k end
					end
				end
			end
		end
		table.sort(PET_COMBO_OPTIONS)
	end

	----------------------------------------------------------------- MUT_OPTIONS
	local MUT_OPTIONS, seenMut = { "None" }, { None = true }
	for _, name in pairs(EnumToMut) do
		if name ~= "Normal" and not seenMut[name] then
			seenMut[name] = true
			MUT_OPTIONS[#MUT_OPTIONS + 1] = name
		end
	end
	table.sort(MUT_OPTIONS)

	----------------------------------------------------------------- SKIN_OPTIONS
	local SKIN_OPTIONS = {}
	for name, data in pairs(SkinsReg) do
		SKIN_OPTIONS[#SKIN_OPTIONS + 1] = { name = name, display = data.DisplayName or name }
	end
	table.sort(SKIN_OPTIONS, function(a, b) return a.display < b.display end)

	----------------------------------------------------------------- mutDisplay
	local function mutDisplay(code)
		if code == nil or code == "" or code == "m" or code == "None" or code == "Normal" then
			return "None"
		end
		return EnumToMut[code] or code
	end

	ctx.reg = {
		comboKey          = comboKey,
		mutDisplay        = mutDisplay,
		PET_OPTIONS       = PET_OPTIONS,
		PET_COMBO_OPTIONS = PET_COMBO_OPTIONS,
		PET_ICONS         = PET_ICONS,
		MUT_OPTIONS       = MUT_OPTIONS,
		SKIN_OPTIONS      = SKIN_OPTIONS,
	}
end
]=],
	["modules/core/services.lua"] = [=[
--[[ services.lua — game services + require semua module game (deps).
     Mengisi: ctx.Services, ctx.LP, ctx.deps ]]
return function(ctx)
	local Players           = game:GetService("Players")
	local RS                = game:GetService("ReplicatedStorage")
	local HttpService       = game:GetService("HttpService")
	local UserInputService  = game:GetService("UserInputService")
	local CollectionService = game:GetService("CollectionService")

	if not game:IsLoaded() then game.Loaded:Wait() end
	repeat task.wait() until Players.LocalPlayer
	local LP = Players.LocalPlayer

	ctx.Services = {
		Players           = Players,
		RS                = RS,
		HttpService       = HttpService,
		UserInputService  = UserInputService,
		CollectionService = CollectionService,
	}
	ctx.LP = LP

	----------------------------------------------------------------- deps
	local RR              = require(RS.Modules.ReplicationReciever)
	local DataService     = require(RS.Modules.DataService)
	local TradeBoothsData = require(RS.Data.TradeBoothsData)
	local PU              = require(RS.Modules.PetServices.PetUtilities)
	local PetEggs         = require(RS.Data.PetRegistry.PetEggs)
	local MutReg          = require(RS.Data.PetRegistry.PetMutationRegistry)
	local okPL, PetList   = pcall(function() return require(RS.Data.PetRegistry.PetList) end)
	if not okPL then PetList = {} end
	local SkinsReg        = require(RS.Data.TradeBoothSkinRegistry)

	local Booths = RS.GameEvents.TradeEvents.Booths
	-- TokenRAPs (buat sniper cari seller lintas server) — akses defensif biar ga bikin
	-- seluruh hub error kalau path berubah.
	local TradeEvents = RS.GameEvents:FindFirstChild("TradeEvents")
	local TokenRAPs   = TradeEvents and TradeEvents:FindFirstChild("TokenRAPs")
	local okTRU, TokenRAPUtil = pcall(function() return require(RS.Modules.TradeTokens.TokenRAPUtil) end)

	ctx.deps = {
		RR              = RR,
		DataService     = DataService,
		TradeBoothsData = TradeBoothsData,
		PU              = PU,
		PetEggs         = PetEggs,
		PetList         = PetList,
		MutReg          = MutReg,
		SkinsReg        = SkinsReg,
		EnumToMut       = MutReg.EnumToPetMutation,

		Booths          = Booths,
		ClaimBooth      = Booths.ClaimBooth,
		CreateListing   = Booths.CreateListing,
		RemoveBooth     = Booths.RemoveBooth,
		RemoveListing   = Booths.RemoveListing,
		AddToHistory    = Booths.AddToHistory,
		BuyListing      = Booths.BuyListing,
		EquipSkin       = RS.GameEvents.TradeBoothSkinService.Equip,

		-- sniper (auto-buy dari booth pemain lain + cari seller lintas server)
		FindSellers       = TokenRAPs and TokenRAPs:FindFirstChild("FindSellers"),
		TeleportToListing = TokenRAPs and TokenRAPs:FindFirstChild("TeleportToListing"),
		TokenRAPUtil      = okTRU and TokenRAPUtil or nil,
	}
end
]=],
	["modules/core/webhook.lua"] = [=[
--[[ webhook.lua — Discord webhook + listener transaksi (notif terjual).
     Mengisi: ctx.sendWebhook
     Efek samping: connect AddToHistory.OnClientEvent ]]
return function(ctx)
	local LP          = ctx.LP
	local HttpService = ctx.Services.HttpService
	local CFG         = ctx.CFG
	local AddToHistory = ctx.deps.AddToHistory

	----------------------------------------------------------------- sender
	local function sendWebhook(payload)
		if not CFG.webhookEnabled or CFG.webhookUrl == "" then return end
		if type(payload) == "table" then
			if not payload.username then payload.username = "CeszParadise" end
			if not payload.avatar_url then payload.avatar_url = "https://raw.githubusercontent.com/milmscr/iniapa/main/cobainaja/Logo/logo_icon.png" end
		end
		task.spawn(function()
			local reqFn = (syn and syn.request) or (http and http.request) or http_request or request
			if not reqFn then return end
			pcall(reqFn, {
				Url = CFG.webhookUrl, Method = "POST",
				Headers = { ["Content-Type"] = "application/json" },
				Body = HttpService:JSONEncode(payload),
			})
		end)
	end
	ctx.sendWebhook = sendWebhook

	----------------------------------------------------------------- history ke dashboard
	-- Kirim transaksi (buy/sell) ke Laravel buat History tab. Non-blocking, best-effort.
	local EVENT_URL = "https://api.allegiaant.my.id/api/event"
	local EVENT_KEY = "ae3858d4a2def3306d6cbff26ff2bd72eee9319b1aae27d1"
	local function reportEvent(kind, data)
		task.spawn(function()
			local reqFn = (syn and syn.request) or (http and http.request) or http_request or request
			if not reqFn then return end
			data = data or {}
			data.kind = kind
			data.userId = LP.UserId
			pcall(reqFn, {
				Url = EVENT_URL, Method = "POST",
				Headers = { ["Content-Type"] = "application/json", ["x-api-key"] = EVENT_KEY },
				Body = HttpService:JSONEncode(data),
			})
		end)
	end
	ctx.reportEvent = reportEvent

	----------------------------------------------------------------- sell listener
	-- Dedup GLOBAL (persist antar-reload). ctx.state di-reset tiap reload, jadi
	-- kalau pakai tabel per-ctx, listener lama (yg bocor) + listener baru punya
	-- tabel dedup masing-masing -> kirim double/triple. Tabel global bikin listener
	-- mana pun yg duluan proses tx.id nge-block sisanya.
	local lastProcessedTx = _G.__AH_SellTx
	if type(lastProcessedTx) ~= "table" then
		lastProcessedTx = {}
		_G.__AH_SellTx = lastProcessedTx
	end
	ctx.state.lastProcessedTx = lastProcessedTx

	-- Disconnect listener dari eksekusi/reload sebelumnya biar nggak numpuk.
	if _G.__AH_SellConn then pcall(function() _G.__AH_SellConn:Disconnect() end) end

	_G.__AH_SellConn = AddToHistory.OnClientEvent:Connect(function(tx)
		if not CFG.webhookEnabled or CFG.webhookUrl == "" then return end
		if not tx or type(tx) ~= "table" then return end
		if lastProcessedTx[tx.id] then return end
		lastProcessedTx[tx.id] = true

		-- Cek apakah kita adalah penjual (seller) dan transaksinya sukses
		local myId = ctx.myPlayerId()
		local isSeller = (myId == tx.seller.userId) or (LP.UserId == tx.seller.userId)
		local isSuccess = tx.status and tx.status.result ~= "Failed"

		if isSeller and isSuccess then
			-- Dapatkan detail item
			local itemType = tx.item and tx.item.type or "Unknown"
			local petType = "Unknown"
			local petName = "-"
			local petAge = "-"
			local petWeight = "-"

			local sellW, sellAge, sellMut = nil, nil, nil
			if itemType == "Pet" and tx.item.data then
				local d = tx.item.data
				petType = d.PetType or "Unknown"
				if d.PetData then
					petName = d.PetData.Name or petType
					if petName == "" then petName = petType end
					petAge = tostring(d.PetData.Level or 0)
					petWeight = ("%.2f kg"):format(d.PetData.BaseWeight or 0)
					sellW = d.PetData.BaseWeight or 0
					sellAge = d.PetData.Level or 0
					local okm, m = pcall(function() return ctx.reg.mutDisplay(d.PetData.MutationType) end)
					if okm and m and m ~= "None" and m ~= "Normal" then sellMut = m end
				end
			else
				-- Fallback jika bukan pet
				if tx.item.data then
					if tx.item.data.ItemData then
						petType = tx.item.data.ItemData.ItemName or "Unknown"
					else
						petType = tx.item.data.PetType or tx.item.data.SkinID or "Unknown"
					end
					petName = petType
				end
			end

			local price = tx.price or 0
			local priceWithFee = price - math.ceil(price / 100)

			local currentTokens = tostring(ctx.getTokens())
			local formattedTokens = currentTokens
			local numTokens = tonumber(currentTokens)
			if numTokens then
				local formatted = tostring(numTokens)
				local k
				while true do
					formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1.%2')
					if k == 0 then break end
				end
				formattedTokens = formatted
			end

			local embed = {
				title = "✦ CeszParadise — Sell Notification",
				color = 16738670, -- Soft vibrant rose
				fields = {
					{
						name = "**Profile :**",
						value = ("> Username : **%s**\n> Buyer : `%s`"):format(tostring(tx.seller.username), tostring(tx.buyer.username)),
						inline = false
					},
					{
						name = "**Item Sold :**",
						value = ("> Item Type : `%s`\n> Pet Type : `%s`\n> Pet Name : `%s`\n> Pet Age : `%s`\n> Pet Weight : `%s`\n> Price : **%s Token**\n> Price (With Fee) : `%s Token`"):format(
							tostring(itemType),
							tostring(petType),
							tostring(petName),
							tostring(petAge),
							tostring(petWeight),
							tostring(price),
							tostring(priceWithFee)
						),
						inline = false
					},
					{
						name = "**Current Tokens :**",
						value = ("> **%s Token**"):format(tostring(formattedTokens)),
						inline = false
					}
				},
				footer = {
					text = ("CeszParadise Trade • %s"):format(os.date("%B %d | %I:%M %p")),
					icon_url = "https://raw.githubusercontent.com/milmscr/iniapa/main/cobainaja/Logo/logo_icon.png"
				}
			}

			sendWebhook({
				username = "CeszParadise",
				avatar_url = "https://raw.githubusercontent.com/milmscr/iniapa/main/cobainaja/Logo/logo_icon.png",
				embeds = { embed }
			})

			reportEvent("sell", {
				pet = petType,
				mutation = sellMut,
				weight = sellW,
				age = sellAge,
				price = tonumber(price) or 0,
				counterpart = tostring(tx.buyer and tx.buyer.username or "?"),
			})
		end
	end)
end
]=],
	["modules/core/websync.lua"] = [=[
--[[ websync.lua — sinkron opsi/config trade ke dashboard web (AllegiaantHUB Monitor).

     STEP 1: push OPTIONS (pet/mutasi/skin) -> dropdown web sama persis in-game.
     STEP 2: sync CONFIG DUA ARAH per-akun:
        - Web -> Script : poll GET /api/config/:userId tiap 5s, apply kalau beda + start/stop automation.
        - Script -> Web : bungkus ctx.persistState -> tiap setting diubah in-game, auto PUT ke web.
        - Baseline `lastApplied` (serialize deterministik) cegah gema/apply berulang.

     Semua HTTP di THREAD TERPISAH + pcall = non-blocking, ga ganggu automation. ]]
return function(ctx)
	local WEB_BASE = "https://api.allegiaant.my.id"
	local API_KEY  = "ae3858d4a2def3306d6cbff26ff2bd72eee9319b1aae27d1"
	local POLL_EVERY = 10  -- detik (hemat invocation Vercel; config/command telat max ~10s)

	local HttpService = game:GetService("HttpService")
	local Players     = game:GetService("Players")
	local LP          = ctx.LP or Players.LocalPlayer
	local httpReq     = (syn and syn.request) or (http and http.request) or http_request or request

	----------------------------------------------------------------- STEP 1: options
	local function buildOptions()
		local reg = ctx.reg or {}
		local skins = {}
		for _, s in ipairs(reg.SKIN_OPTIONS or {}) do
			skins[#skins + 1] = (type(s) == "table" and s.name) or tostring(s) -- CFG.boothSkin = nama internal
		end
		return {
			pets     = reg.PET_OPTIONS or {},
			petCombo = reg.PET_COMBO_OPTIONS or {},
			petIcons = reg.PET_ICONS or {},   -- nama pet -> asset id icon (buat gambar di web)
			muts     = reg.MUT_OPTIONS or {},
			skins    = skins,
		}
	end

	function ctx.webPushOptions()
		if not httpReq then return end
		task.spawn(function()
			pcall(function()
				httpReq({
					Url = WEB_BASE .. "/api/options",
					Method = "POST",
					Headers = { ["Content-Type"] = "application/json", ["x-api-key"] = API_KEY },
					Body = HttpService:JSONEncode(buildOptions()),
				})
			end)
		end)
	end

	----------------------------------------------------------------- STEP 2: config sync
	-- Field config yang di-sync (nama identik CFG <-> web TradeConfig).
	local function setKeys(s)
		if type(s) ~= "table" then return "" end
		local k = {}
		for key, v in pairs(s) do if v then k[#k + 1] = tostring(key) end end
		table.sort(k)
		return table.concat(k, ",")
	end

	-- Serialize deterministik buat bandingin config (lokal vs web). Field-nya sama, urutan tetap.
	local function serialize(c)
		c = c or {}
		local t = {}
		local function add(v) t[#t + 1] = tostring(v) end
		add(c.autoSell); add(c.autoClaim); add(c.autoSwitchPortal); add(c.autoReconnect); add(c.boothSkin)
		add(c.relocateEnabled); add(c.relocateIdleMin); add(c.relocateMinPlayers); add(c.relocatePreferred)
		add(c.snipeEnabled); add(c.snipeHop); add(c.snipeHopIndex); add(c.snipeHopPlayer); add(c.snipeMinPop); add(c.snipeRevisitSec)
		add(c.webhookEnabled); add(c.webhookUrl)
		local profs = c.profiles or {}
		for i = 1, (ctx.NUM_PROFILES or 3) do
			local p = profs[i] or profs[tostring(i)] or {}
			local ls = p.listings or {}
			for j = 1, (ctx.NUM_LISTINGS or 3) do
				local l = ls[j] or ls[tostring(j)] or {}
				add(setKeys(l.pets)); add(setKeys(l.muts)); add(l.minW); add(l.maxW); add(l.maxList); add(l.price)
			end
		end
		local sps = c.snipeProfiles or {}
		for i = 1, (ctx.NUM_SNIPE or 5) do
			local p = sps[i] or sps[tostring(i)] or {}
			add(setKeys(p.pets)); add(setKeys(p.muts)); add(p.maxPrice)
		end
		return table.concat(t, "|")
	end

	-- Snapshot CFG -> tabel yang match web TradeConfig (buat PUT).
	local function snapshot()
		local CFG = ctx.CFG
		return {
			autoSell = CFG.autoSell == true, autoClaim = CFG.autoClaim == true,
			autoSwitchPortal = CFG.autoSwitchPortal == true, autoReconnect = CFG.autoReconnect ~= false,
			boothSkin = CFG.boothSkin or "Default",
			relocateEnabled = CFG.relocateEnabled == true, relocateIdleMin = CFG.relocateIdleMin or 20,
			relocateMinPlayers = CFG.relocateMinPlayers or 10, relocatePreferred = CFG.relocatePreferred or 20,
			snipeEnabled = CFG.snipeEnabled == true, snipeHop = CFG.snipeHop ~= false,
			snipeHopIndex = CFG.snipeHopIndex ~= false, snipeHopPlayer = CFG.snipeHopPlayer ~= false,
			snipeMinPop = CFG.snipeMinPop or 25, snipeRevisitSec = CFG.snipeRevisitSec or 120,
			webhookEnabled = CFG.webhookEnabled == true, webhookUrl = CFG.webhookUrl or "",
			profiles = CFG.profiles, snipeProfiles = CFG.snipeProfiles,
		}
	end

	local lastApplied = nil            -- string serialize terakhir yg udah sinkron
	local ready = false                -- true setelah PULL pertama (web=master) selesai
	local origPersist = ctx.persistState

	-- PUT config ke web (script -> web). Set baseline biar poll balik ga apply ulang.
	local function pushConfigNow()
		if not httpReq or not (LP and LP.UserId) then return end
		local snap = snapshot()
		lastApplied = serialize(snap)
		task.spawn(function()
			pcall(function()
				httpReq({
					Url = WEB_BASE .. "/api/config/" .. tostring(LP.UserId),
					Method = "PUT",
					Headers = { ["Content-Type"] = "application/json", ["x-api-key"] = API_KEY },
					Body = HttpService:JSONEncode(snap),
				})
			end)
		end)
	end

	-- Debounce push (kumpulin perubahan beruntun jadi 1 PUT).
	local pushPending = false
	local function schedulePush()
		if pushPending then return end
		pushPending = true
		task.spawn(function()
			task.wait(1.5)
			pushPending = false
			pushConfigNow()
		end)
	end

	-- Bungkus persistState: tiap perubahan in-game -> simpan file + auto push ke web.
	ctx.persistState = function(...)
		origPersist(...)
		-- Cuma push kalau: bukan lagi apply dari web (hindari gema) DAN sudah pull awal
		-- (cegah config lokal stale ke-push pas boot sebelum web di-apply).
		if not ctx.__websyncApplying and ready then schedulePush() end
	end

	-- Salin isi SelSet (pets/muts) ke tabel tujuan IN-PLACE (clear lalu copy), JANGAN ganti
	-- referensi tabelnya. Dropdown GUI & loop listing pegang referensi tabel yg sama —
	-- kalau di-replace, mereka baca tabel lama (mutasi/pet ga ke-sync).
	local function copyInto(dst, src)
		if type(dst) ~= "table" then return end
		for k in pairs(dst) do dst[k] = nil end
		if type(src) == "table" then for k, v in pairs(src) do dst[k] = v end end
	end

	-- Terapkan nested (profiles / snipeProfiles) dari web ke CFG in-place.
	local function applyProfiles(w)
		local CFG = ctx.CFG
		if type(w.profiles) == "table" then
			for i = 1, (ctx.NUM_PROFILES or 3) do
				local sp = w.profiles[i] or w.profiles[tostring(i)]
				if type(sp) == "table" and type(sp.listings) == "table" then
					for j = 1, (ctx.NUM_LISTINGS or 3) do
						local sl = sp.listings[j] or sp.listings[tostring(j)]
						local dst = CFG.profiles[i] and CFG.profiles[i].listings[j]
						if type(sl) == "table" and dst then
							copyInto(dst.pets, sl.pets)
							copyInto(dst.muts, sl.muts)
							dst.minW    = tonumber(sl.minW) or 0
							dst.maxW    = tonumber(sl.maxW) or 0
							dst.maxList = tonumber(sl.maxList) or 0
							dst.price   = tonumber(sl.price) or 100
						end
					end
				end
			end
		end
		if type(w.snipeProfiles) == "table" then
			for i = 1, (ctx.NUM_SNIPE or 5) do
				local sp = w.snipeProfiles[i] or w.snipeProfiles[tostring(i)]
				local dst = CFG.snipeProfiles[i]
				if type(sp) == "table" and dst then
					copyInto(dst.pets, sp.pets)
					copyInto(dst.muts, sp.muts)
					dst.maxPrice = tonumber(sp.maxPrice) or 0
				end
			end
		end
	end

	-- Apply config dari web (web -> script) + start/stop automation yg toggle-nya berubah.
	local function applyWebConfig(w)
		local CFG = ctx.CFG
		local old = {
			autoSell = CFG.autoSell, relocate = CFG.relocateEnabled,
			snipe = CFG.snipeEnabled, skin = CFG.boothSkin,
		}

		if w.autoSell ~= nil then CFG.autoSell = w.autoSell == true end
		if w.autoClaim ~= nil then CFG.autoClaim = w.autoClaim == true end
		if w.autoSwitchPortal ~= nil then CFG.autoSwitchPortal = w.autoSwitchPortal == true end
		if w.autoReconnect ~= nil then CFG.autoReconnect = w.autoReconnect == true end
		if w.boothSkin ~= nil then CFG.boothSkin = tostring(w.boothSkin) end
		if w.relocateEnabled ~= nil then CFG.relocateEnabled = w.relocateEnabled == true end
		if w.relocateIdleMin ~= nil then CFG.relocateIdleMin = tonumber(w.relocateIdleMin) or CFG.relocateIdleMin end
		if w.relocateMinPlayers ~= nil then CFG.relocateMinPlayers = tonumber(w.relocateMinPlayers) or CFG.relocateMinPlayers end
		if w.relocatePreferred ~= nil then CFG.relocatePreferred = tonumber(w.relocatePreferred) or CFG.relocatePreferred end
		if w.snipeEnabled ~= nil then CFG.snipeEnabled = w.snipeEnabled == true end
		if w.snipeHop ~= nil then CFG.snipeHop = w.snipeHop == true end
		if w.snipeHopIndex ~= nil then CFG.snipeHopIndex = w.snipeHopIndex == true end
		if w.snipeHopPlayer ~= nil then CFG.snipeHopPlayer = w.snipeHopPlayer == true end
		if w.snipeMinPop ~= nil then CFG.snipeMinPop = tonumber(w.snipeMinPop) or CFG.snipeMinPop end
		if w.snipeRevisitSec ~= nil then CFG.snipeRevisitSec = tonumber(w.snipeRevisitSec) or CFG.snipeRevisitSec end
		if w.webhookEnabled ~= nil then CFG.webhookEnabled = w.webhookEnabled == true end
		if w.webhookUrl ~= nil then CFG.webhookUrl = tostring(w.webhookUrl) end
		applyProfiles(w)

		-- simpan ke file TANPA memicu push balik (hindari gema)
		ctx.__websyncApplying = true
		pcall(function() origPersist() end)
		ctx.__websyncApplying = false

		-- reconcile automation berdasar transisi toggle
		if old.autoSell ~= CFG.autoSell then
			if CFG.autoSell then
				if not ctx.state.running then ctx.state.running = true; task.spawn(ctx.mainLoop) end
			else
				ctx.state.running = false
			end
			if ctx.setStatus then ctx.setStatus(CFG.autoSell and "active" or "idle") end
		end
		if old.relocate ~= CFG.relocateEnabled then
			if CFG.relocateEnabled then if ctx.startRelocate then ctx.startRelocate() end
			else if ctx.stopRelocate then ctx.stopRelocate() end end
		end
		if old.snipe ~= CFG.snipeEnabled then
			if CFG.snipeEnabled then if ctx.startSnipe then ctx.startSnipe() end
			else if ctx.stopSnipe then ctx.stopSnipe() end end
			if ctx.refreshSnipeStatus then pcall(ctx.refreshSnipeStatus) end
		end
		if old.skin ~= CFG.boothSkin then
			pcall(function() if ctx.deps.EquipSkin then ctx.deps.EquipSkin:FireServer(CFG.boothSkin) end end)
		end

		-- re-render tampilan GUI (kalau hub kebuka): toggle + input/dropdown
		if ctx.state.toggleRenders then
			for _, r in ipairs(ctx.state.toggleRenders) do pcall(r) end
		end
		if ctx.state.uiRefreshers then
			for _, r in ipairs(ctx.state.uiRefreshers) do pcall(r) end
		end
		-- (log "Config di-sync" dihapus biar console ga spam)
	end

	-- Satu kali poll: GET config, apply kalau beda dari baseline.
	local function pollOnce()
		if not httpReq or not (LP and LP.UserId) then return end
		local res
		pcall(function()
			res = httpReq({
				Url = WEB_BASE .. "/api/config/" .. tostring(LP.UserId),
				Method = "GET",
				Headers = { ["x-api-key"] = API_KEY },
			})
		end)
		if not (res and res.Body) then return end
		local ok, j = pcall(function() return HttpService:JSONDecode(res.Body) end)
		if not (ok and type(j) == "table" and j.ok and type(j.config) == "table") then return end
		local webStr = serialize(j.config)
		if webStr ~= lastApplied then
			applyWebConfig(j.config)
			lastApplied = serialize(snapshot())
		end
	end

	----------------------------------------------------------------- STEP 3: commands
	-- Eksekusi 1 aksi dari web. Handler-nya udah ada di app trade.
	local function runAction(action)
		if action == "unlistAll" then
			if ctx.unlistAll then pcall(ctx.unlistAll) end
		elseif action == "unclaimBooth" then
			pcall(function() if ctx.deps.RemoveBooth then ctx.deps.RemoveBooth:FireServer() end end)
		elseif action == "relocateNow" then
			if ctx.relocateNow then pcall(ctx.relocateNow) end
		else
			return
		end
		if ctx.log then pcall(function() ctx.log("Command dari web: " .. tostring(action)) end) end
	end

	-- Ambil antrian command (GET = baca + buang di server) lalu jalankan berurutan.
	local function pollCommands()
		if not httpReq or not (LP and LP.UserId) then return end
		local res
		pcall(function()
			res = httpReq({
				Url = WEB_BASE .. "/api/command/" .. tostring(LP.UserId),
				Method = "GET",
				Headers = { ["x-api-key"] = API_KEY },
			})
		end)
		if not (res and res.Body) then return end
		local ok, j = pcall(function() return HttpService:JSONDecode(res.Body) end)
		if not (ok and type(j) == "table" and j.ok and type(j.commands) == "table") then return end
		for _, cmd in ipairs(j.commands) do
			if type(cmd) == "table" and cmd.action then runAction(cmd.action) end
		end
	end

	-- Gabungan config+command dalam 1 request (GET /api/sync) — hemat invocation Vercel.
	local function pollSync()
		if not httpReq or not (LP and LP.UserId) then return end
		local res
		pcall(function()
			res = httpReq({
				Url = WEB_BASE .. "/api/sync/" .. tostring(LP.UserId),
				Method = "GET",
				Headers = { ["x-api-key"] = API_KEY },
			})
		end)
		if not (res and res.Body) then return end
		local ok, j = pcall(function() return HttpService:JSONDecode(res.Body) end)
		if not (ok and type(j) == "table" and j.ok) then return end
		if type(j.config) == "table" then
			local webStr = serialize(j.config)
			if webStr ~= lastApplied then
				applyWebConfig(j.config)
				lastApplied = serialize(snapshot())
			end
		end
		if type(j.commands) == "table" then
			for _, cmd in ipairs(j.commands) do
				if type(cmd) == "table" and cmd.action then runAction(cmd.action) end
			end
		end
	end

	----------------------------------------------------------------- boot
	ctx.state.webSyncReady = false
	task.spawn(function()
		-- WEB = MASTER. PULL config PALING AWAL (sebelum automation auto-resume/hop), biar
		-- setting web (mis. snipe=off) ke-apply duluan. Auto-resume snipe nungguin flag ini.
		task.wait(0.5)
		pcall(pollSync)
		ready = true                  -- mulai sekarang, perubahan GUI in-game boleh push ke web
		ctx.state.webSyncReady = true -- sinyal ke auto-resume: config web udah ke-apply
		ctx.webPushOptions()          -- options nyusul (ga urgent buat dropdown web)
		while ctx.alive() and Players.LocalPlayer == LP do
			task.wait(POLL_EVERY)
			pcall(pollSync)           -- config + command sekaligus
		end
	end)
end
]=],
	["modules/sell/booth.lua"] = [=[
--[[ booth.lua — logika booth: kepemilikan, claim terdekat, pindah dekat portal, token.
     Mengisi: ctx.getTokens, ctx.myPlayerId, ctx.weightOf,
              ctx.ownsBooth, ctx.tryClaimNearest, ctx.ensureBooth,
              ctx.autoSwitchBoothPortal ]]
return function(ctx)
	local LP                = ctx.LP
	local CollectionService = ctx.Services.CollectionService
	local RR                = ctx.deps.RR
	local DataService       = ctx.deps.DataService
	local TradeBoothsData   = ctx.deps.TradeBoothsData
	local ClaimBooth        = ctx.deps.ClaimBooth
	local RemoveBooth       = ctx.deps.RemoveBooth
	local CFG               = ctx.CFG
	local function log(msg) ctx.log(msg) end

	local function getTokens()
		local ok, data = pcall(function() return DataService:GetData() end)
		if ok and type(data) == "table" and type(data.TradeData) == "table" then
			return data.TradeData.Tokens or 0
		end
		return 0
	end

	local function myPlayerId() return TradeBoothsData.getPlayerId(LP) end

	local function weightOf(petType, pd)
		return pd.BaseWeight or 0
	end

	local function ownsBooth()
		local ok, data = pcall(function() return RR.new("Booths"):GetDataAsync() end)
		if not ok or not data then return false, nil, nil end
		local id = myPlayerId()
		local playerRecord = data.Players and data.Players[id]
		local boothName = playerRecord and playerRecord.Booth
		return boothName ~= nil, data, boothName
	end

	local function tryClaimNearest()
		local owns, data = ownsBooth()
		if owns then return true end
		if not data then return false end
		local charPos
		local char = LP.Character
		if char and char:FindFirstChild("HumanoidRootPart") then charPos = char.HumanoidRootPart.Position end
		local list = {}
		for _, inst in ipairs(CollectionService:GetTagged("TradeBooth")) do
			local b = data.Booths and data.Booths[inst.Name]
			if (b == nil) or (b.Owner == nil) then
				local dist = 999999
				if charPos then
					local ok2, piv = pcall(function() return inst:GetPivot().Position end)
					if ok2 then dist = (piv - charPos).Magnitude end
				end
				list[#list + 1] = { inst = inst, dist = dist }
			end
		end
		if #list == 0 then log("Tidak ada booth kosong."); return false end
		table.sort(list, function(a, b) return a.dist < b.dist end)
		local pick = list[1]

		if char and char:FindFirstChild("HumanoidRootPart") then
			char.HumanoidRootPart.CFrame = pick.inst:GetPivot() * CFrame.new(0, 3, 3)
			task.wait(0.25)
		end

		pcall(function() ClaimBooth:FireServer(pick.inst) end)
		log(("Claim booth terdekat (%dstud, %d kosong)..."):format(math.floor(pick.dist), #list))
		return false
	end

	local function ensureBooth()
		local owns = ownsBooth()
		if owns then return true end
		if CFG.autoClaim then return tryClaimNearest() end
		return false
	end

	-- Auto Switch to Booth Near Portal
	local function autoSwitchBoothPortal()
		if not CFG.autoSwitchPortal then return end
		local owns, data, boothName = ownsBooth()
		if not owns or not data or not boothName then return end
		-- Cari portal Trade World (bukan lobby)
		local tradeWorld = workspace:FindFirstChild("TradeWorld")
		local portal = nil
		if tradeWorld then
			local pp = tradeWorld:FindFirstChild("PortalPetePlatform")
			if pp then portal = pp:FindFirstChild("Portal") or pp end
			if not portal then portal = tradeWorld:FindFirstChild("Portal Pete", true) end
		end
		if not portal then
			portal = workspace:FindFirstChild("Portal Pete", true) or workspace:FindFirstChild("Portal", true)
		end
		local portalPos = portal and portal:GetPivot().Position or Vector3.new(0, 0, 0)

		local myBoothInst = nil
		for _, inst in ipairs(CollectionService:GetTagged("TradeBooth")) do
			if inst.Name == boothName then myBoothInst = inst; break end
		end
		if not myBoothInst then return end

		local myDist = (myBoothInst:GetPivot().Position - portalPos).Magnitude
		local bestBooth = nil
		local bestDist = myDist

		for _, inst in ipairs(CollectionService:GetTagged("TradeBooth")) do
			local b = data.Booths and data.Booths[inst.Name]
			if (b == nil) or (b.Owner == nil) then
				local pDist = (inst:GetPivot().Position - portalPos).Magnitude
				if pDist < bestDist - 8 then -- harus lebih dekat minimal 8 stud agar worth-it pindah
					bestDist = pDist
					bestBooth = inst
				end
			end
		end

		if bestBooth then
			log(("Pindah ke booth lebih dekat portal (Lama: %dstud, Baru: %dstud)"):format(math.floor(myDist), math.floor(bestDist)))
			pcall(function() RemoveBooth:FireServer() end)
			task.wait(0.5)

			local char = LP.Character
			if char and char:FindFirstChild("HumanoidRootPart") then
				char.HumanoidRootPart.CFrame = bestBooth:GetPivot() * CFrame.new(0, 3, 3)
				task.wait(0.25)
			end

			pcall(function() ClaimBooth:FireServer(bestBooth) end)
		end
	end

	ctx.getTokens             = getTokens
	ctx.myPlayerId            = myPlayerId
	ctx.weightOf              = weightOf
	ctx.ownsBooth             = ownsBooth
	ctx.tryClaimNearest       = tryClaimNearest
	ctx.ensureBooth           = ensureBooth
	ctx.autoSwitchBoothPortal = autoSwitchBoothPortal
end
]=],
	["modules/sell/listing.lua"] = [=[
--[[ listing.lua — inti listing: scan inventory, listPass sekuensial, loop utama, util unlist/unequip.
     Mengisi: ctx.inventoryCounts, ctx.selectedPetTypes, ctx.buildSummary,
              ctx.listPass, ctx.anyProfileActive, ctx.mainLoop,
              ctx.unlistAll, ctx.unequipAllPets ]]
return function(ctx)
	local LP                = ctx.LP
	local RS                = ctx.Services.RS
	local CollectionService = ctx.Services.CollectionService
	local DataService       = ctx.deps.DataService
	local CreateListing     = ctx.deps.CreateListing
	local RemoveListing     = ctx.deps.RemoveListing
	local CFG               = ctx.CFG
	local NUM_PROFILES      = ctx.NUM_PROFILES
	local NUM_LISTINGS      = ctx.NUM_LISTINGS
	local comboKey          = ctx.reg.comboKey
	local mutDisplay        = ctx.reg.mutDisplay
	local weightOf          = ctx.weightOf
	local ownsBooth         = ctx.ownsBooth
	local myPlayerId        = ctx.myPlayerId
	local getTokens         = ctx.getTokens
	local ensureBooth       = ctx.ensureBooth
	local function log(msg) ctx.log(msg) end
	local function setStatus(s) ctx.setStatus(s) end

	----------------------------------------------------------------- inventory helpers
	-- list pet di inventory
	local function inventoryCounts()
		local counts = {}
		local ok, data = pcall(function() return DataService:GetData() end)
		if ok and type(data) == "table" and data.PetsData and data.PetsData.PetInventory and data.PetsData.PetInventory.Data then
			for _, v in pairs(data.PetsData.PetInventory.Data) do
				local pt = v and v.PetType
				if pt then counts[pt] = (counts[pt] or 0) + 1 end
			end
		end
		return counts
	end

	local function selectedPetTypes()
		local set, order = {}, {}
		for pi = 1, NUM_PROFILES do
			local prof = CFG.profiles[pi]
			if prof and type(prof.listings) == "table" then
				for li = 1, NUM_LISTINGS do
					local sub = prof.listings[li]
					if sub and type(sub.pets) == "table" then
						for petKey in pairs(sub.pets) do
							local pt = (string.split(petKey, " - ")[1]) or petKey
							if not set[pt] then set[pt] = true; order[#order + 1] = pt end
						end
					end
				end
			end
		end
		table.sort(order)
		return order
	end

	local function buildSummary()
		local counts = inventoryCounts()
		local lines, total = {}, 0
		for _, pt in ipairs(selectedPetTypes()) do
			local c = counts[pt] or 0
			total = total + c
			lines[#lines + 1] = ("%s: %d"):format(pt, c)
		end
		return (#lines > 0 and table.concat(lines, "\n") or "-"), total
	end

	----------------------------------------------------------------- listPass
	-- satu putaran listing: STRICT SEQUENTIAL P1L1→P1L2→P1L3→P2L1→...
	-- Setiap listing harus TEPAT maxList sebelum lanjut ke listing berikutnya
	local function listPass()
		local owns, bData, boothName = ownsBooth()
		if not owns or not boothName then return 0 end

		-- Teleport ke booth jika terlalu jauh agar lolos cek jarak server
		local myBoothInst = nil
		for _, inst in ipairs(CollectionService:GetTagged("TradeBooth")) do
			if inst.Name == boothName then myBoothInst = inst; break end
		end
		if myBoothInst then
			local char = LP.Character
			if char and char:FindFirstChild("HumanoidRootPart") then
				local root = char.HumanoidRootPart
				if (root.Position - myBoothInst:GetPivot().Position).Magnitude > 8 then
					root.CFrame = myBoothInst:GetPivot() * CFrame.new(0, 3, 3)
					task.wait(0.25)
				end
			end
		end

		-- Ambil data booth & inventory TERBARU
		local myId = myPlayerId()
		local myRecord = bData.Players and (bData.Players[myId] or bData.Players[tostring(myId)])
		local currentList = myRecord and myRecord.Listings or {}

		-- REBUILD listedSet dari booth aktual (agar pet yang sudah dibeli otomatis hilang)
		local listedSet = {}
		ctx.state.listedSet = listedSet
		for _, l in pairs(currentList) do
			if l.ItemId then listedSet[l.ItemId] = true end
		end

		local ok, data = pcall(function() return DataService:GetData() end)
		if not ok or not (data and data.PetsData and data.PetsData.PetInventory) then return 0 end
		local pets  = data.PetsData.PetInventory.Data
		local locks = (data.TradeData and data.TradeData.TradeLocks and data.TradeData.TradeLocks.Pet) or {}

		local equippedSet = {}
		if data.PetsData and data.PetsData.EquippedPets then
			for _, eqUuid in ipairs(data.PetsData.EquippedPets) do
				equippedSet[eqUuid] = true
			end
		end

		-- Track UUID booth yang sudah di-claim listing sebelumnya (anti double-count)
		local claimedByOther = {}
		local total = 0

		-- Helper: cek pet cocok dengan listing config
		local function petMatches(petType, pd, sub)
			if not (sub.pets[petType] or sub.pets[comboKey(petType, pd.HatchedFrom or "?")]) then return false end
			local mut = mutDisplay(pd.MutationType)
			local mutOK
			if not next(sub.muts) then mutOK = (mut == "None") else mutOK = sub.muts[mut] == true end
			if not mutOK then return false end
			local w    = weightOf(petType, pd)
			-- minW: toleransi -0.5 agar pet tepat di batas tetap lolos (mis. set 3.845 → cek >=3.345)
			local minW = (sub.minW or 0) > 0 and (sub.minW - 0.5) or 0
			-- maxW: STRICT tanpa toleransi — pet melebihi batas harus ditolak
			local maxW = sub.maxW or 0
			-- lolos jika: berat >= minW DAN (maxW tidak di-set ATAU berat <= maxW)
			return (w >= minW) and (maxW <= 0 or w <= maxW)
		end

		-- STRICT SEQUENTIAL: P1L1 → P1L2 → P1L3 → P2L1 → P2L2 → ...
		for pi = 1, NUM_PROFILES do
			local prof = CFG.profiles[pi]
			if prof and type(prof.listings) == "table" then
				for li = 1, NUM_LISTINGS do
					if not ctx.state.running then return total end
					local sub = prof.listings[li]
					if sub and next(sub.pets) and (sub.price or 0) > 0 then
						local cap = (sub.maxList and sub.maxList > 0) and sub.maxList or 0
						if cap <= 0 then -- skip listing tanpa max cap
						else
							-- STEP 1: Hitung berapa pet di booth yang cocok listing ini
							local boothCount = 0
							for _, l in pairs(currentList) do
								local itemUuid = l.ItemId
								if itemUuid and not claimedByOther[itemUuid] then
									local invPet = pets[itemUuid]
									if invPet and invPet.PetType and invPet.PetData then
										if petMatches(invPet.PetType, invPet.PetData, sub) then
											boothCount = boothCount + 1
											claimedByOther[itemUuid] = true
										end
									end
								end
							end

							-- STEP 2: Kalau belum penuh, tambah sampai tepat cap
							local needed = cap - boothCount
							if needed > 0 then
								log(("P%d-L%d: %d/%d di booth, perlu +%d"):format(pi, li, boothCount, cap, needed))
								local added = 0
								for uuid, v in pairs(pets) do
									if not ctx.state.running then return total end
									if added >= needed then break end
									local pd = v.PetData
									if v.PetType and pd and not pd.IsFavorite
										and not locks[uuid] and not listedSet[uuid]
										and not equippedSet[uuid] and not claimedByOther[uuid] then
										if petMatches(v.PetType, pd, sub) then
											local ok2, res = pcall(function() return CreateListing:InvokeServer("Pet", uuid, math.floor(sub.price)) end)
											if ok2 and res then
												listedSet[uuid] = true
												claimedByOther[uuid] = true
												added = added + 1
												total = total + 1
												local mut = mutDisplay(pd.MutationType)
												local w = weightOf(v.PetType, pd)
												log(("LIST %s [%s] %.2fkg @%d (P%d-L%d) [%d/%d]"):format(v.PetType, mut, w, sub.price, pi, li, boothCount + added, cap))

												-- Webhook dipindah ke event beli actual

												task.wait(5)
											else
												log(("FAIL list %s (%s)"):format(v.PetType, tostring(res)))
												task.wait(3) -- tunggu rate limit hilang
											end
										end
									end
								end
								-- Kalau stock habis, SKIP ke listing berikutnya (jangan stuck)
								if boothCount + added < cap then
									log(("P%d-L%d: stock habis, baru %d/%d. Skip ke listing berikutnya."):format(pi, li, boothCount + added, cap))
								end
							end
							-- Kalau sudah penuh (needed <= 0), lanjut ke listing berikutnya ✓
						end
					end
				end
			end
		end
		return total
	end

	----------------------------------------------------------------- main loop
	local function anyProfileActive()
		for i = 1, NUM_PROFILES do
			local prof = CFG.profiles[i]
			if prof and type(prof.listings) == "table" then
				for j = 1, NUM_LISTINGS do
					if next(prof.listings[j].pets) then return true end
				end
			end
		end
		return false
	end

	local function mainLoop()
		ctx.state.currentLoopId = ctx.state.currentLoopId + 1
		local myLoopId = ctx.state.currentLoopId
		ctx.elevate()
		while ctx.state.running and ctx.alive() and ctx.state.currentLoopId == myLoopId do
			if not anyProfileActive() then
				setStatus("Pilih pet di profil listing dulu.")
				task.wait(2)
			else
				local ready = true
				if CFG.autoClaim then ready = ensureBooth() end
				if ready then
					local n = listPass()
					if n > 0 then
						setStatus(("Refill +%d | Token:%s"):format(n, tostring(getTokens())))
						task.wait(2) -- cepat cek lagi karena baru ada perubahan
					else
						setStatus(("Booth OK ✓ | Token:%s"):format(tostring(getTokens())))
						task.wait(3) -- semua penuh, monitoring mode
					end
				else
					setStatus("Menunggu booth ke-claim...")
					task.wait(2.5)
				end
			end
		end
	end

	----------------------------------------------------------------- unlist / unequip
	local function unlistAll()
		local owns, data, boothName = ownsBooth()
		if not owns or not data or not boothName then log("Kamu tidak punya booth."); return end

		-- Temukan booth instance untuk teleportasi (agar lolos cek jarak server)
		local myBoothInst = nil
		for _, inst in ipairs(CollectionService:GetTagged("TradeBooth")) do
			if inst.Name == boothName then myBoothInst = inst; break end
		end
		if myBoothInst then
			local char = LP.Character
			if char and char:FindFirstChild("HumanoidRootPart") then
				char.HumanoidRootPart.CFrame = myBoothInst:GetPivot() * CFrame.new(0, 3, 3)
				task.wait(0.25)
			end
		end

		local myId = myPlayerId()
		local pd = data.Players and (data.Players[myId] or data.Players[tostring(myId)])
		local list = pd and pd.Listings or {}
		local count = 0
		for lid, _ in pairs(list) do
			local ok, res = pcall(function() return RemoveListing:InvokeServer(lid) end)
			if ok and res then count += 1; task.wait(0.1) end
		end
		ctx.state.listedSet = {}
		log(("Sukses menghapus %d pajangan."):format(count))
	end

	local function unequipAllPets()
		local ok, PetsService = pcall(require, RS.Modules.PetServices.PetsService)
		if not ok or not PetsService then log("Gagal memuat PetsService."); return end
		local ok2, data = pcall(function() return DataService:GetData() end)
		if ok2 and data and data.PetsData and data.PetsData.EquippedPets then
			local count = 0
			for _, uuid in ipairs(data.PetsData.EquippedPets) do
				local ok3 = pcall(function() PetsService:UnequipPet(uuid) end)
				if ok3 then count += 1 end
			end
			log(("Unequipped %d pets."):format(count))
		else
			log("Tidak ada pet yang aktif terpasang.")
		end
	end

	ctx.inventoryCounts  = inventoryCounts
	ctx.selectedPetTypes = selectedPetTypes
	ctx.buildSummary     = buildSummary
	ctx.listPass         = listPass
	ctx.anyProfileActive = anyProfileActive
	ctx.mainLoop         = mainLoop
	ctx.unlistAll        = unlistAll
	ctx.unequipAllPets   = unequipAllPets
end
]=],
	["modules/sell/relocate.lua"] = [=[
--[[ relocate.lua — Automation Relocate Sell (Trade World).
     Pindah server otomatis kalau booth idle (ga ada pembeli sekian menit) ATAU
     server terlalu sepi, ke server yang jumlah pemainnya paling dekat dengan
     'Preferred Lobby Size'. Timer idle di-reset tiap ada transaksi jual sukses.
       - Idle Timeout (menit)  -> pindah kalau ga ada pembeli sekian lama
       - Min Player Threshold  -> pindah kalau pemain < ambang (0 = mati)
       - Preferred Lobby Size  -> cari server dengan pemain paling dekat angka ini
     Mengisi: ctx.relocateNow, ctx.startRelocate, ctx.stopRelocate ]]
return function(ctx)
	local TeleportService = game:GetService("TeleportService")
	local Players     = ctx.Services.Players or game:GetService("Players")
	local HttpService = ctx.Services.HttpService
	local LP          = ctx.LP
	local CFG         = ctx.CFG
	local AddToHistory = ctx.deps.AddToHistory
	local function log(m) ctx.log(m) end
	local function setStatus(s) ctx.setStatus(s) end

	local ROUTER = "loadstring(game:HttpGet('https://raw.githubusercontent.com/milmscr/iniapa/main/cobainaja/init.lua'))()"

	-- waktu jual terakhir; reset tiap ada yang beli dari kita -> penanda booth aktif.
	ctx.state.lastSaleAt = os.time()
	local loadedAt = os.time()

	-- listener transaksi (independen dari webhook) buat reset timer idle.
	pcall(function()
		AddToHistory.OnClientEvent:Connect(function(tx)
			if type(tx) ~= "table" or not tx.seller then return end
			local myId = ctx.myPlayerId and ctx.myPlayerId()
			local isSeller = (myId and myId == tx.seller.userId) or (LP.UserId == tx.seller.userId)
			local isSuccess = tx.status and tx.status.result ~= "Failed"
			if isSeller and isSuccess then ctx.state.lastSaleAt = os.time() end
		end)
	end)

	-- queue hub biar auto-load lagi setelah landing di server baru.
	local function queueHub()
		local q = queue_on_teleport or queueonteleport or (syn and syn.queue_on_teleport)
		if q then pcall(function() q(ROUTER) end) end
	end

	-- daftar server publik. game:HttpGet ke roblox.com diblok Roblox, jadi pakai
	-- fungsi request executor (bisa hit games.roblox.com).
	local function fetchServers()
		local reqFn = (syn and syn.request) or (http and http.request) or http_request or request
		if not reqFn then return nil end
		local url = ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Desc&limit=100"):format(game.PlaceId)
		local ok, res = pcall(reqFn, { Url = url, Method = "GET" })
		if not ok or not res or not res.Body then return nil end
		local ok2, data = pcall(function() return HttpService:JSONDecode(res.Body) end)
		if not ok2 or type(data) ~= "table" or type(data.data) ~= "table" then return nil end
		return data.data
	end

	-- pilih server: ada slot kosong, bukan server ini, 'playing' paling dekat preferred.
	local function pickServer(preferred)
		local servers = fetchServers()
		if not servers then return nil end
		local best, bestDiff
		for _, s in ipairs(servers) do
			local playing = tonumber(s.playing) or 0
			local maxp = tonumber(s.maxPlayers) or 30
			if s.id ~= game.JobId and playing < maxp then
				local diff = math.abs(playing - preferred)
				if not bestDiff or diff < bestDiff then best, bestDiff = s, diff end
			end
		end
		return best
	end

	local function doRelocate(reason)
		local preferred = math.max(1, math.floor(tonumber(CFG.relocatePreferred) or 20))
		_G.__AH_reloActive = true -- tandai lagi proses pindah (buat retry handler)
		setStatus("Relocate: " .. reason .. " -> cari server...")
		log("Relocate: " .. reason)
		queueHub()
		local target = pickServer(preferred)
		if target and target.id then
			log(("Pindah ke server (%d/%d pemain)"):format(tonumber(target.playing) or 0, tonumber(target.maxPlayers) or 30))
			pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, target.id, LP) end)
		else
			log("List server gagal/kosong -> teleport acak.")
			pcall(function() TeleportService:Teleport(game.PlaceId, LP) end)
		end
	end
	function ctx.relocateNow() task.spawn(function() doRelocate("manual") end) end

	-- Handle gagal teleport: retry otomatis (Flooded=20s, gagal lain=6s).
	-- Semua kondisi (idle/sepi/manual) lewat doRelocate yang sama, jadi ke-cover.
	-- Guard _G biar ga double-connect walau hub ke-load ulang.
	if not _G.__AH_reloTpHandler then
		_G.__AH_reloTpHandler = true
		pcall(function()
			TeleportService.TeleportInitFailed:Connect(function(_, result)
				if not CFG.relocateEnabled or not _G.__AH_reloActive then return end
				local wait = (result == Enum.TeleportResult.Flooded) and 20 or 6
				setStatus(("Relocate: teleport gagal (%s), retry %ds..."):format(tostring(result), wait))
				log(("Teleport gagal (%s), retry %ds..."):format(tostring(result), wait))
				task.wait(wait)
				if CFG.relocateEnabled and _G.__AH_reloActive then doRelocate("retry") end
			end)
		end)
	end

	local function loop()
		ctx.state.relocateId = (ctx.state.relocateId or 0) + 1
		local myId = ctx.state.relocateId
		ctx.elevate()
		task.wait(15) -- grace: tunggu server settle + data pemain kebaca dulu
		while CFG.relocateEnabled and ctx.alive() and ctx.state.relocateId == myId do
			local players = #Players:GetPlayers()
			local idleFor = os.time() - (ctx.state.lastSaleAt or loadedAt)
			local idleLimit = math.max(1, math.floor(tonumber(CFG.relocateIdleMin) or 20)) * 60
			local minPlayers = math.floor(tonumber(CFG.relocateMinPlayers) or 0)

			if minPlayers > 0 and players < minPlayers then
				doRelocate(("server sepi (%d<%d)"):format(players, minPlayers))
				return
			elseif idleFor >= idleLimit then
				doRelocate(("idle %d menit tanpa pembeli"):format(math.floor(idleFor / 60)))
				return
			else
				local remain = math.max(0, idleLimit - idleFor)
				setStatus(("Relocate ON | idle %02d:%02d | pemain %d"):format(math.floor(remain / 60), remain % 60, players))
			end
			task.wait(5)
		end
	end

	function ctx.startRelocate()
		ctx.state.lastSaleAt = os.time()
		task.spawn(loop)
	end
	function ctx.stopRelocate()
		ctx.state.relocateId = (ctx.state.relocateId or 0) + 1
		_G.__AH_reloActive = false -- batalkan retry yang mungkin tertunda
		setStatus("Relocate: dimatikan")
	end

	-- auto-resume kalau sebelumnya aktif (mis. baru landing dari hop).
	if CFG.relocateEnabled then task.spawn(ctx.startRelocate) end
end
]=],
	["ui/components.lua"] = [=[
--[[ components.lua — Kontrol UI Trade World (Fluent Mobile Remake)
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
			-- Build options
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

			-- Position clamping
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
	local function makeDropdown(parent, title, desc, optionsOrFn, selectedSet, onChange, order)
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

		-- Floating Backdrop
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
			Size = UDim2.fromOffset(220, 240),
			BackgroundColor3 = C.bg,
			BackgroundTransparency = 0.04,
			BorderSizePixel = 0,
			Visible = false,
			ZIndex = 201,
		}, backdrop)
		corner(menuFrame, 10)
		stroke(menuFrame, C.stroke, 1.4, 0.2)

		-- Search Bar
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
			local menuW = 220
			local menuH = 220

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

	----------------------------------------------------------------- Button Card
	local function makeButton(parent, text, colorOrVariant, onClick, order)
		local col = (typeof(colorOrVariant) == "Color3") and colorOrVariant or C.acc
		local isDanger = (col == C.red)

		local btn = mk("TextButton", {
			Size = UDim2.new(1, 0, 0, 36),
			BackgroundColor3 = isDanger and Color3.fromRGB(60, 20, 30) or C.row,
			BackgroundTransparency = 0.3,
			Text = tostring(text or "Button"),
			Font = F.bold,
			TextSize = 13,
			TextColor3 = isDanger and C.red or C.txt,
			AutoButtonColor = false,
			LayoutOrder = order or 0,
		}, parent)
		corner(btn, 8)
		local bStroke = stroke(btn, isDanger and C.red or C.strokeSub, 1.2, 0.4)

		btn.MouseEnter:Connect(function()
			TS:Create(btn, TweenInfo.new(0.15), { BackgroundTransparency = 0.1, BackgroundColor3 = isDanger and Color3.fromRGB(80, 25, 40) or C.rowHover }):Play()
			TS:Create(bStroke, TweenInfo.new(0.15), { Color = isDanger and C.red or C.acc, Transparency = 0.2 }):Play()
		end)
		btn.MouseLeave:Connect(function()
			TS:Create(btn, TweenInfo.new(0.15), { BackgroundTransparency = 0.3, BackgroundColor3 = isDanger and Color3.fromRGB(60, 20, 30) or C.row }):Play()
			TS:Create(bStroke, TweenInfo.new(0.15), { Color = isDanger and C.red or C.strokeSub, Transparency = 0.4 }):Play()
		end)
		btn.MouseButton1Click:Connect(function()
			if onClick then onClick() end
		end)

		return btn
	end

	----------------------------------------------------------------- Slider (Touch-Safe with Scroll Lock)
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

	----------------------------------------------------------------- Page Creation (Maps to Fluent Tabs)
	local TAB_ICONS = {
		Sell      = "shopping-cart",
		Buy       = "crosshair",
		Inventory = "backpack",
		Misc      = "settings",
		Pet       = "paw-print",
		Farm      = "sprout",
		Hatch     = "egg",
		Elephant  = "crown",
		Flow      = "flower-2",
		Leveling  = "zap",
		Mutation  = "flask-conical",
		Shop      = "shopping-bag",
	}

	local tabCount = 0
	local function makePage(name, titleText, iconLabel, order)
		tabCount = tabCount + 1
		local idx = tabCount
		ctx.tabIndices = ctx.tabIndices or {}
		ctx.tabIndices[name] = idx

		local iconName = TAB_ICONS[name] or "sparkles"
		local tab = Window:AddTab({ Title = name, Icon = iconName })

		-- Container tempat meletakkan elemen di dalam ScrollingFrame tab
		local pageContainer = tab.Container

		ctx.ui.pages[name] = pageContainer

		-- Dummy tabBtns object untuk kompatibilitas app.lua
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
	ctx.makePage           = makePage
	ctx.makeAccordion      = makeAccordion
	ctx.makeToggle         = makeToggle
	ctx.makeInput          = makeInput
	ctx.makeDropdown       = makeDropdown
	ctx.makeSingleDropdown = makeSingleDropdown
	ctx.makeButton         = makeButton
	ctx.makeSlider         = makeSlider
	ctx.makeSection        = makeSection
	ctx.divider            = divider
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
--[[ pages.lua — membangun halaman: Sell, Profile 1..N, Inventory, Misc.
     Mengisi: ctx.renderInventory, ctx.ui.logBox, ctx.ui.rAutoToggle ]]
return function(ctx)
	local LP  = ctx.LP
	local CFG = ctx.CFG
	local C   = ctx.C
	local F   = ctx.F
	local mk, corner, stroke, pad = ctx.mk, ctx.corner, ctx.stroke, ctx.pad
	local NUM_PROFILES = ctx.NUM_PROFILES
	local NUM_LISTINGS = ctx.NUM_LISTINGS
	local NUM_SNIPE    = ctx.NUM_SNIPE
	local reg          = ctx.reg
	local persistState = ctx.persistState
	local EquipSkin    = ctx.deps.EquipSkin
	local RemoveBooth  = ctx.deps.RemoveBooth
	local function log(msg) ctx.log(msg) end

	local makePage           = ctx.makePage
	local makeAccordion      = ctx.makeAccordion
	local makeSingleDropdown = ctx.makeSingleDropdown
	local makeToggle         = ctx.makeToggle
	local makeButton         = ctx.makeButton
	local makeDropdown       = ctx.makeDropdown
	local makeInput          = ctx.makeInput

	------------------------------------------------------------------ SELL PAGE
	local sellPage = makePage("Sell", "Sell Settings", "🛒", 1)

	-- Enable Auto List (dipindah dari Misc) — toggle utama di atas
	local autoListCard = mk("Frame", { Size = UDim2.new(1, 0, 0, 60), BackgroundColor3 = C.row, LayoutOrder = 1 }, sellPage)
	corner(autoListCard, 8); stroke(autoListCard); pad(autoListCard, 12, 12, 0, 0)
	local rAutoToggle = makeToggle(autoListCard, "Enable Auto List", "Periodically scan inventory and list matching pets",
		function() return CFG.autoSell end,
		function(v)
			CFG.autoSell = v; persistState(); ctx.setStatus(v and "active" or "idle")
			if v and not ctx.state.running then ctx.state.running = true; task.spawn(ctx.mainLoop)
			elseif not v then ctx.state.running = false end
		end, 1)
	ctx.ui.rAutoToggle = rAutoToggle

	-- Accordion: Booth Settings
	local boothBody = makeAccordion(sellPage, "Booth Settings", 2)
	makeSingleDropdown(boothBody, "Booth Skin", "Equip skins you own in Trade Plaza", reg.SKIN_OPTIONS,
		function() return CFG.boothSkin or "Default" end,
		function(name)
			CFG.boothSkin = name; persistState()
			pcall(function() EquipSkin:FireServer(name) end)
			log("Memasang skin booth: " .. name)
		end, 1)

	makeToggle(boothBody, "Auto Claim Booth", "Automatically claim an unclaimed booth",
		function() return CFG.autoClaim end,
		function(v) CFG.autoClaim = v; persistState() end, 2)

	makeToggle(boothBody, "Auto Switch to Booth Near Portal", "Switch to a booth closer to the lobby portal",
		function() return CFG.autoSwitchPortal end,
		function(v) CFG.autoSwitchPortal = v; persistState() end, 3)

	-- Accordion: Unlist Utilities (di bawah Profile 3)
	local unlistBody = makeAccordion(sellPage, "Unlist Pets Utilities", 20)
	makeButton(unlistBody, "Unlist All Pets", C.red, ctx.unlistAll, 1)
	makeButton(unlistBody, "Unclaim Booth", C.row, function() pcall(function() RemoveBooth:FireServer() end) log("Unclaim booth dikirim.") end, 2)

	-- Accordion: Automation Relocate Sell (di bawah Profile 3)
	local reloBody = makeAccordion(sellPage, "Automation Relocate Sell", 21)
	makeInput(reloBody, "Idle Timeout (Minutes)", "Move server if no buyers within this duration",
		function() return CFG.relocateIdleMin or 20 end,
		function(txt) local n = tonumber(txt); CFG.relocateIdleMin = (n and n >= 1) and math.floor(n) or 20; persistState() end, 1)
	makeInput(reloBody, "Min Player Threshold", "Relocate if server has fewer players (0 = off)",
		function() return CFG.relocateMinPlayers or 0 end,
		function(txt) local n = tonumber(txt); CFG.relocateMinPlayers = (n and n >= 0) and math.floor(n) or 0; persistState() end, 2)
	makeInput(reloBody, "Preferred Lobby Size", "Find server closest to this player count",
		function() return CFG.relocatePreferred or 20 end,
		function(txt) local n = tonumber(txt); CFG.relocatePreferred = (n and n >= 1) and math.floor(n) or 20; persistState() end, 3)
	makeToggle(reloBody, "Automation Relocate Sell", "Automatically move to busier server when booth is idle",
		function() return CFG.relocateEnabled end,
		function(v)
			CFG.relocateEnabled = v; persistState()
			if v then ctx.startRelocate() else ctx.stopRelocate() end
		end, 4)
	makeButton(reloBody, "Relocate Now", C.acc, function() ctx.relocateNow() end, 5)

	------------------------------------------------------------------ LISTING PROFILES (accordion di Sell)
	-- simpan fungsi buka accordion + container biar bisa dinavigasi dari klik card Inventory
	local profileOpen, profileCont, listingOpen = {}, {}, {}
	ctx.ui.profileOpen, ctx.ui.profileCont, ctx.ui.listingOpen = profileOpen, profileCont, listingOpen
	for i = 1, NUM_PROFILES do
		local prof = CFG.profiles[i]
		local profBody, profSetOpen, profContainer = makeAccordion(sellPage, "Profile " .. i, 4 + i)
		profileOpen[i], profileCont[i], listingOpen[i] = profSetOpen, profContainer, {}

		local clearers = {} -- reset tiap listing (dipakai tombol Clear All)

		for j = 1, NUM_LISTINGS do
			local sub = prof.listings[j]
			local listBody, listSetOpen = makeAccordion(profBody, "Listing " .. j, j)
			listingOpen[i][j] = listSetOpen

			local petRefresh = makeDropdown(listBody, "Pet Types [Listing " .. j .. "]", "Select pet types to list", reg.PET_OPTIONS, sub.pets, function() persistState() end, 1)
			local mutRefresh = makeDropdown(listBody, "Mutation [Listing " .. j .. "]", "Empty = non-mutated only, select = must have mutation", reg.MUT_OPTIONS, sub.muts, function() persistState() end, 2)
			local minWBox = makeInput(listBody, "Min Weight [Listing " .. j .. "]", "Minimum weight filter (KG)", function() return sub.minW or 0 end, function(txt) local n = tonumber(txt); sub.minW = (n and n >= 0) and n or 0; persistState() end, 3)
			local maxWBox = makeInput(listBody, "Max Weight [Listing " .. j .. "]", "Maximum weight filter (KG)", function() return sub.maxW or 0 end, function(txt) local n = tonumber(txt); sub.maxW = (n and n >= 0) and n or 0; persistState() end, 4)
			local maxListBox = makeInput(listBody, "Max Listings [Listing " .. j .. "]", "Maximum number of listings for this profile", function() return sub.maxList or 0 end, function(txt) local n = tonumber(txt); sub.maxList = (n and n >= 0) and math.floor(n) or 0; persistState() end, 5)
			local priceBox = makeInput(listBody, "Price [Listing " .. j .. "]", "Price per listing (Tokens)", function() return sub.price or 100 end, function(txt) local n = tonumber(txt); sub.price = (n and n >= 0) and math.floor(n) or 0; persistState() end, 6)

			clearers[#clearers + 1] = function()
				for k in pairs(sub.pets) do sub.pets[k] = nil end
				for k in pairs(sub.muts) do sub.muts[k] = nil end
				sub.minW, sub.maxW, sub.maxList, sub.price = 0, 0, 0, 100
				petRefresh(); mutRefresh()
				minWBox.Text = tostring(sub.minW)
				maxWBox.Text = tostring(sub.maxW)
				maxListBox.Text = tostring(sub.maxList)
				priceBox.Text = tostring(sub.price)
			end
		end

		makeButton(profBody, "Clear All (Profile " .. i .. ")", C.red, function()
			for _, clr in ipairs(clearers) do clr() end
			persistState()
			log(("Profile %d dibersihkan."):format(i))
		end, NUM_LISTINGS + 1)
	end

	------------------------------------------------------------------ BUY PAGE (Auto Snipe)
	local buyPage = makePage("Buy", "Auto Snipe", "🎯", 2)

	-- Status snipe
	local snipeStatusCard = mk("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = C.row, LayoutOrder = 1 }, buyPage)
	corner(snipeStatusCard, 8); stroke(snipeStatusCard); pad(snipeStatusCard, 12, 12, 10, 10)
	mk("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, snipeStatusCard)
	mk("TextLabel", { Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1, Text = "🎯  Snipe Status", Font = F.bold, TextSize = 13, TextColor3 = C.txt, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 1 }, snipeStatusCard)
	local snipeStatusLbl = mk("TextLabel", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Text = "", Font = F.reg, TextSize = 12, TextColor3 = C.sub, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, LineHeight = 1.3, LayoutOrder = 2 }, snipeStatusCard)
	local function refreshSnipeStatus()
		local ok, s = pcall(function() return ctx.getSnipeStatus() end)
		if ok and s then snipeStatusLbl.Text = ("Status: %s\n%s"):format(s.on and "ON" or "OFF", s.lines) end
	end
	ctx.refreshSnipeStatus = refreshSnipeStatus

	-- Auto Snipe toggle
	local snipeToggleCard = mk("Frame", { Size = UDim2.new(1, 0, 0, 60), BackgroundColor3 = C.row, LayoutOrder = 2 }, buyPage)
	corner(snipeToggleCard, 8); stroke(snipeToggleCard); pad(snipeToggleCard, 12, 12, 0, 0)
	makeToggle(snipeToggleCard, "Auto Snipe Pet", "Scan & beli pet cocok dari booth pemain (profil 1-5)",
		function() return CFG.snipeEnabled end,
		function(v)
			CFG.snipeEnabled = v; persistState(); refreshSnipeStatus()
			if v then ctx.startSnipe() else ctx.stopSnipe() end
		end, 1)

	-- Accordion: Hop Server (1 enable + filter metode hop)
	local hopAcc = makeAccordion(buyPage, "Hop Server", 3)
	makeToggle(hopAcc, "Auto Server Hop", "Enable hop antar-server (master)",
		function() return CFG.snipeHop end,
		function(v) CFG.snipeHop = v; persistState() end, 1)
	makeToggle(hopAcc, "Filter: By Index (Find Seller)", "Cari seller lintas server via index game",
		function() return CFG.snipeHopIndex end,
		function(v) CFG.snipeHopIndex = v; persistState() end, 2)
	makeToggle(hopAcc, "Filter: By Player (Min Players)", "Hop ke server berdasarkan jumlah player",
		function() return CFG.snipeHopPlayer end,
		function(v) CFG.snipeHopPlayer = v; persistState() end, 3)
	makeInput(hopAcc, "Min Players", "By Player: hop ke server dgn pemain >= ini (1 = semua server)",
		function() return CFG.snipeMinPop or 25 end,
		function(txt) local n = tonumber(txt); CFG.snipeMinPop = (n and n >= 1) and math.floor(n) or 25; persistState() end, 4)
	makeInput(hopAcc, "Revisit Cooldown (detik)", "Jeda sebelum boleh balik ke server yang sama",
		function() return CFG.snipeRevisitSec or 120 end,
		function(txt) local n = tonumber(txt); CFG.snipeRevisitSec = (n and n >= 5) and math.floor(n) or 120; persistState() end, 5)

	-- 5 profil snipe (accordion; urutan = prioritas)
	for i = 1, NUM_SNIPE do
		local prof = CFG.snipeProfiles[i]
		local body = makeAccordion(buyPage, "Snipe " .. i, 6 + i)
		makeDropdown(body, "Pet Types [Snipe " .. i .. "]", "Pilih pet per egg (premium/biasa). Urutan profil = prioritas", reg.PET_COMBO_OPTIONS, prof.pets, function() persistState(); refreshSnipeStatus() end, 1)
		makeDropdown(body, "Mutation [Snipe " .. i .. "]", "Kosong = semua mutasi", reg.MUT_OPTIONS, prof.muts, function() persistState() end, 2)
		makeInput(body, "Max Price [Snipe " .. i .. "]", "0 = tanpa batas harga (Tokens)", function() return prof.maxPrice or 0 end, function(txt) local n = tonumber(txt); prof.maxPrice = (n and n >= 0) and math.floor(n) or 0; persistState(); refreshSnipeStatus() end, 3)
	end
	refreshSnipeStatus()

	------------------------------------------------------------------ INVENTORY PAGE
	local invPage = makePage("Inventory", "Inventory Tracker", "🎒", 5)

	-- format angka dgn pemisah ribuan (1234567 -> 1.234.567)
	local function fmt(n)
		local s = tostring(math.floor(tonumber(n) or 0))
		local k
		while true do s, k = s:gsub("^(-?%d+)(%d%d%d)", "%1.%2"); if k == 0 then break end end
		return s
	end

	-- === Stat cards (Target Pets + Saldo Token) ===
	local statRow = mk("Frame", { Size = UDim2.new(1, 0, 0, 88), BackgroundTransparency = 1, LayoutOrder = 1 }, invPage)
	mk("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder }, statRow)

	local function statCard(order, icon, title, accent)
		local card = mk("Frame", { Size = UDim2.new(0.5, -6, 1, 0), BackgroundColor3 = C.row, LayoutOrder = order, ClipsDescendants = true }, statRow)
		corner(card, 12); stroke(card)
		local glow = mk("Frame", { Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = accent, BackgroundTransparency = 0.9, BorderSizePixel = 0 }, card)
		corner(glow, 12)
		mk("UIGradient", { Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.82), NumberSequenceKeypoint.new(1, 1) }) }, glow)
		mk("TextLabel", { Size = UDim2.new(1, -32, 0, 16), Position = UDim2.fromOffset(16, 14), BackgroundTransparency = 1, Text = icon .. "  " .. title, Font = F.semi, TextSize = 11, TextColor3 = C.sub, TextXAlignment = Enum.TextXAlignment.Left }, card)
		return mk("TextLabel", { Size = UDim2.new(1, -32, 0, 36), Position = UDim2.fromOffset(16, 36), BackgroundTransparency = 1, Text = "0", Font = F.bold, TextSize = 26, TextColor3 = accent, TextXAlignment = Enum.TextXAlignment.Left }, card)
	end

	local targetVal = statCard(1, "🎯", "TARGET PETS", C.acc)
	local tokenVal  = statCard(2, "💰", "SALDO TOKEN", C.green)

	-- === Breakdown per tipe pet ===
	local listCard = mk("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = C.row, LayoutOrder = 2 }, invPage)
	corner(listCard, 12); stroke(listCard); pad(listCard, 14, 14, 12, 14)
	mk("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }, listCard)
	mk("TextLabel", { Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1, Text = "📋  Target Breakdown", Font = F.bold, TextSize = 13, TextColor3 = C.txt, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 1 }, listCard)
	local rowsHolder = mk("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = 2 }, listCard)
	mk("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, rowsHolder)
	local emptyLbl = mk("TextLabel", { Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, Text = "Belum ada pet target dipilih.", Font = F.reg, TextSize = 12, TextColor3 = C.sub, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 1 }, rowsHolder)

	-- cari (profil, listing) tempat pet type ini dikonfigurasi (ambil yg pertama ketemu)
	local function findListing(pt)
		for i = 1, NUM_PROFILES do
			local prof = CFG.profiles[i]
			if prof and type(prof.listings) == "table" then
				for j = 1, NUM_LISTINGS do
					local sub = prof.listings[j]
					if sub and type(sub.pets) == "table" then
						for petKey in pairs(sub.pets) do
							if ((string.split(petKey, " - ")[1]) or petKey) == pt then return i, j end
						end
					end
				end
			end
		end
	end

	-- klik card -> pindah ke tab Sell, buka Profile+Listing pet itu, scroll ke situ
	local function gotoListing(pt)
		local i, j = findListing(pt)
		if not i then return end
		if ctx.selectTab then ctx.selectTab("Sell") end
		local po = ctx.ui.profileOpen and ctx.ui.profileOpen[i]
		if po then po(true) end
		local lo = ctx.ui.listingOpen and ctx.ui.listingOpen[i] and ctx.ui.listingOpen[i][j]
		if lo then lo(true) end
		-- scroll accordion Profile ke atas viewport (tunggu 1 frame biar layout update)
		task.spawn(function()
			local sf = ctx.ui.pages and ctx.ui.pages["Sell"]
			local cont = ctx.ui.profileCont and ctx.ui.profileCont[i]
			if sf and cont then
				game:GetService("RunService").Heartbeat:Wait()
				local ok = pcall(function()
					local y = cont.AbsolutePosition.Y - sf.AbsolutePosition.Y + sf.CanvasPosition.Y
					sf.CanvasPosition = Vector2.new(0, math.max(0, y - 8))
				end)
				return ok
			end
		end)
	end

	local petRows = {}
	local function renderInventory()
		local counts = ctx.inventoryCounts()
		local types  = ctx.selectedPetTypes()
		local total = 0
		for _, pt in ipairs(types) do total = total + (counts[pt] or 0) end
		targetVal.Text = fmt(total)
		tokenVal.Text  = fmt(ctx.getTokens())

		for _, r in ipairs(petRows) do r:Destroy() end
		petRows = {}
		emptyLbl.Visible = (#types == 0)
		for i, pt in ipairs(types) do
			local c = counts[pt] or 0
			local row = mk("TextButton", { Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = C.panel, LayoutOrder = i + 1, Text = "", AutoButtonColor = false }, rowsHolder)
			corner(row, 8)
			mk("Frame", { Size = UDim2.fromOffset(3, 16), Position = UDim2.new(0, 10, 0.5, -8), BackgroundColor3 = (c > 0 and C.acc or C.stroke), BorderSizePixel = 0 }, row)
			mk("TextLabel", { Size = UDim2.new(1, -110, 1, 0), Position = UDim2.fromOffset(22, 0), BackgroundTransparency = 1, Text = pt, Font = F.semi, TextSize = 12, TextColor3 = C.txt, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd }, row)
			local pill = mk("Frame", { Size = UDim2.fromOffset(54, 22), Position = UDim2.new(1, -82, 0.5, -11), BackgroundColor3 = (c > 0 and C.acc or C.stroke), BorderSizePixel = 0 }, row)
			corner(pill, 11)
			mk("TextLabel", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = tostring(c), Font = F.bold, TextSize = 12, TextColor3 = Color3.new(1, 1, 1), TextXAlignment = Enum.TextXAlignment.Center }, pill)
			-- chevron penanda bisa diklik -> ke listing profile
			local chev = mk("TextLabel", { Size = UDim2.fromOffset(14, 34), Position = UDim2.new(1, -18, 0, 0), BackgroundTransparency = 1, Text = "›", Font = F.bold, TextSize = 16, TextColor3 = C.sub, TextXAlignment = Enum.TextXAlignment.Center }, row)
			row.MouseEnter:Connect(function() row.BackgroundColor3 = C.row; chev.TextColor3 = C.acc end)
			row.MouseLeave:Connect(function() row.BackgroundColor3 = C.panel; chev.TextColor3 = C.sub end)
			row.MouseButton1Click:Connect(function() gotoListing(pt) end)
			petRows[#petRows + 1] = row
		end
	end
	ctx.renderInventory = renderInventory

	-- auto-refresh tiap tab Inventory diklik (tombol manual dihapus, redundan)
	ctx.ui.tabBtns["Inventory"].btn.MouseButton1Click:Connect(renderInventory)

	------------------------------------------------------------------ MISC PAGE
	local miscPage = makePage("Misc", "Miscellaneous Settings", "⚙️", 6)

	-- Theme Selector
	local themeCard = mk("Frame", { Size = UDim2.new(1, 0, 0, 48), BackgroundColor3 = C.row, LayoutOrder = 0 }, miscPage)
	corner(themeCard, 8); stroke(themeCard); pad(themeCard, 12, 12, 0, 0)
	makeSingleDropdown(themeCard, "UI Theme", "Pilih warna dan gaya tampilan Fluent",
		{ "PinkRoyale", "Rose", "Dark", "Darker", "Aqua", "Amethyst", "Light" },
		function() return (ctx.Fluent and ctx.Fluent.Theme) or "PinkRoyale" end,
		function(themeName)
			if ctx.Fluent and ctx.Fluent.SetTheme then
				ctx.Fluent:SetTheme(themeName)
				log("Tema antarmuka diubah ke: " .. themeName)
			end
		end, 0)

	-- Auto-Reconnect toggle
	local reconCard = mk("Frame", { Size = UDim2.new(1, 0, 0, 60), BackgroundColor3 = C.row, LayoutOrder = 1 }, miscPage)
	corner(reconCard, 8); stroke(reconCard); pad(reconCard, 12, 12, 0, 0)
	makeToggle(reconCard, "Auto Reconnect", "Rejoin otomatis kalau ke-kick / disconnect",
		function() return CFG.autoReconnect ~= false end,
		function(v) CFG.autoReconnect = v; persistState() end, 1)

	local webhookCard = mk("Frame", { Size = UDim2.new(1, 0, 0, 128), BackgroundColor3 = C.row, LayoutOrder = 1 }, miscPage)
	corner(webhookCard, 8); stroke(webhookCard); pad(webhookCard, 12, 12, 8, 8)
	mk("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, webhookCard)

	makeToggle(webhookCard, "Enable Webhook Notifications", "Post listings to Discord Webhook",
		function() return CFG.webhookEnabled end,
		function(v) CFG.webhookEnabled = v; persistState() end, 1)

	local whBox = mk("TextBox", { Size = UDim2.new(1, 0, 0, 28), BackgroundColor3 = C.panel, PlaceholderText = "https://discord.com/api/webhooks/...", Text = CFG.webhookUrl, Font = F.reg, TextSize = 11, TextColor3 = C.acc, ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, ClipsDescendants = true, LayoutOrder = 2 }, webhookCard)
	corner(whBox, 6); stroke(whBox); pad(whBox, 6, 6, 0, 0)
	whBox.FocusLost:Connect(function() CFG.webhookUrl = whBox.Text; persistState() end)

	makeButton(webhookCard, "Test Webhook Connection", C.acc, function()
		if CFG.webhookUrl == "" then log("Webhook URL kosong."); return end
		local prev = CFG.webhookEnabled; CFG.webhookEnabled = true
		ctx.sendWebhook({
			username = "CeszParadise",
			avatar_url = "https://raw.githubusercontent.com/milmscr/iniapa/main/cobainaja/Logo/logo_icon.png",
			embeds = {{
				title = "🔔 Test Sukses",
				description = "Seller Webhook berhasil terhubung ke CeszParadise!",
				color = 10181046,
				footer = {
					text = "Player: " .. LP.Name,
					icon_url = "https://raw.githubusercontent.com/milmscr/iniapa/main/cobainaja/Logo/logo_icon.png"
				}
			}}
		})
		CFG.webhookEnabled = prev
		log("Test webhook terkirim.")
	end, 3)

	-- Logger Panel
	local loggerCard = mk("Frame", { Size = UDim2.new(1, 0, 0, 150), BackgroundColor3 = C.row, LayoutOrder = 3 }, miscPage)
	corner(loggerCard, 8); stroke(loggerCard); pad(loggerCard, 12, 12, 8, 8)
	mk("TextLabel", { Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1, Text = "Console Log", Font = F.bold, TextSize = 13, TextColor3 = C.txt, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 1 }, loggerCard)

	local logBox = mk("TextLabel", { Size = UDim2.new(1, 0, 1, -22), BackgroundColor3 = C.panel, Text = "", TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, Font = Enum.Font.Code, TextSize = 10, TextColor3 = C.sub, TextWrapped = true, LayoutOrder = 2 }, loggerCard)
	corner(logBox, 6); stroke(logBox); pad(logBox, 6, 6, 6, 6)
	ctx.ui.logBox = logBox
	-- tampilkan log yang mungkin sudah ter-buffer sebelum logBox dibuat
	logBox.Text = table.concat(ctx.state.logLines, "\n")
end
]=],
	["ui/theme.lua"] = [=[
--[[ theme.lua — palet warna PINK ROYALE ELEGAN + Fluent Theme Registration.
     Midnight Velvet Rose, Shimmering Pearl, Radiant Hot Rose, Soft Neon Sakura. ]]
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
--[[ window.lua — Jendela Trade World CeszParadiseHub (Fluent Mobile Remake)
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
		for _, nm in ipairs({ "GAGSeller", "CeszParadiseTrade", "GAGTrade", "CeszParadiseGarden", "AllegiaanGarden" }) do
			local old = host:FindFirstChild(nm); if old then old:Destroy() end
		end
		if ctx.LP and ctx.LP:FindFirstChild("PlayerGui") then
			for _, nm in ipairs({ "GAGSeller", "CeszParadiseTrade", "GAGTrade", "CeszParadiseGarden", "AllegiaanGarden" }) do
				local old = ctx.LP.PlayerGui:FindFirstChild(nm); if old then old:Destroy() end
			end
		end
	end)

	----------------------------------------------------------------- Buat Window Fluent Mobile
	local Window = Fluent:CreateWindow({
		Title = "CeszParadise",
		SubTitle = "Trade Edition ✦ Mobile",
		TabWidth = 155,
		Size = UDim2.fromOffset(580, 430),
		Theme = "PinkRoyale",
		MinimizeKey = Enum.KeyCode.LeftControl,
		MobileToggle = true,
		MobileToggleIcon = "shopping-cart",
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
				Title = "CeszParadise Trade",
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
				Window:SetSubTitle(("Trade Edition ✦ %s"):format(ctx.state.status))
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
		print("[CeszParadise/Trade] " .. tostring(msg))
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
