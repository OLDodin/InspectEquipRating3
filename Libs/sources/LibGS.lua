--------------------------------------------------------------------------------
-- LibGS.lua // "Gear Score Library" by hal.dll, version 2017-04-21
-- Created: 2014-08-25
-- Updated: 2017-04-21
-- Support: https://alloder.pro/topic/1718-libgslua-biblioteka-inspektirovaniya-igrokov/
--------------------------------------------------------------------------------
-- PUBLIC VARIABLES
--------------------------------------------------------------------------------
Global( "GS", {} )
--------------------------------------------------------------------------------
-- PUBLIC EVENTS
--------------------------------------------------------------------------------
--
-- LIBGS_GEARSCORE_AVAILABLE ( params )
--    Event LibGS is sending when gearscore info is available for requested unit
--    See GS.Callback description.
--
--------------------------------------------------------------------------------
-- PUBLIC FUNCTIONS
--------------------------------------------------------------------------------
--
-- GS.Init ( EnableTargetAutoInspection, SkipInitialTargetInspection )
--    Initializes LibGS.
--    The arguments are the same as in GS.EnableTargetInspection
--    To be called by your addon:
--        if GS.Init then GS.Init() end
--
-- GS.EnableTargetInspection ( Enable, SkipInitial )
--    By default LibGS is always inspecting current avatar's target.
--    This function is used to disable/enable automatic target inspection.
--    Enable - boolean - enable (true, nil) or disable (false) auto inspection.
--    SkipInitial - boolean - skip (true) or perform (false, nil) target inspection on addon-reloading.
--    To be called by your addon.
--
-- GS.RequestInfo ( unitId )
--    A function to request equipment information for specific player.
--    To be called by your addon.
--
-- GS.Callback ( params )
--    Callback function for LibGS to call when requested player's equipment is available.
--    To be set by your addon (if you do not want to subscribe to the event).
--    params - table:
--      unitId                  - ObjectId - inspected unit Id to check the event is for your unit
--      rank                    - number - rank of avatar inspection ability (0..6)
--      inspected               - boolean - able to inspect this unit, i.e. ability '.rank' >= 1, so is enough to inspect unit partially or completely (false, true)
--      reliable                - boolean - is unit inspected completely, and ability rank is enough to inspect unit (false, true)
--   NOTE: gearscore* fields exist only if inspected == true
--      gearscore               - number - unit equipment gearscore
--      gearscoreLevel          - number - average level of unit equipment, excluding ritual (1..66)
--      gearscoreQuality        - number - average quality of unit equipment adjusted by unit and equipment level, excluding ritual (1..8)
--      gearscoreStyle          - string - recommended style to show gearscore value ('Junk'..'Relic')
--   NOTE: equipment* fields exist only if inspected == true
--      equipmentLevel          - number - average level of unit equipment, excluding ritual (1..66)
--      equipmentQuality        - number - average quality of unit equipment, excluding ritual (1..8)
--      equipmentStyle          - string - recommended style for equipmentQuality ('Junk'..'Relic')
--   NOTE: runes* fields exist only if inspected == true, and only on Free-To-Play shards
--      runes                   - table: indexed by [DRESS_SLOT_*RUNE*], value is a table:
--          runeScore           - number - bonus of the rune (0..??%)
--          runeQuality         - number - rank of the rune (0..13)
--          runeStyle           - string - recommended style to show value ('Junk', 'Common'..'Legendary')
--      runesQuality            - number - average rank of all runes (0..13)
--      runesQualityOffensive   - number - average rank of offensive runes (0..13)
--      runesQualityDefensive   - number - average rank of defensive runes (0..13)
--      runesScoreOffensive     - number - overall bonus of offensive runes (0..??? %)
--      runesScoreDefensive     - number - overall bonus of defensive runes (0..??? %)
--      runesStyle              - string - recommended style to show value ('Junk', 'Common'..'Legendary')
--      runesStyleOffensive     - string - recommended style to show value ('Junk', 'Common'..'Legendary')
--      runesStyleDefensive     - string - recommended style to show value ('Junk', 'Common'..'Legendary')
--   NOTE: some fairy* fields exist only on specific game client versions: [AO 3-4][AO 5-6]; other should always exist
--      fairy                   - string - text to show ('-', 'I'..'V')
--      fairyLevel              - number - level of unit Martyr (1..65)
--      fairyQuality            - number - rank of unit Martyr (0..5)
--      fairyScore              - number - [AO 3-4] bonus for unit characteristic (0..???)
--      fairyScoreStat          - number - [AO 3-4] type of unit characteristic (INNATE_STAT_*)
--      fairyScorePower         - number - [AO 5-6] Power bonus (0..???)
--      fairyScoreDamage        - number - damage bonus of unit Martyr (0..250 %)
--      fairyScoreHeal          - number - healing bonus of unit Martyr (0..250 %)
--      fairyStyle              - number - recommended style to show value ('Junk', 'Goods'..'Epic')
--
--------------------------------------------------------------------------------
-- SYSTEM EVENTS
--------------------------------------------------------------------------------
-- EVENT_SECOND_TIMER
-- EVENT_AVATAR_CLIENT_ZONE_CHANGED
-- EVENT_INSPECT_STARTED
-- EVENT_INSPECT_FINISHED
-- EVENT_ADDON_LOAD_STATE_CHANGED
-- EVENT_AVATAR_TARGET_CHANGED
-- EVENT_AVATAR_SECONDARY_TARGET_CHANGED
--------------------------------------------------------------------------------
-- PRIVATE EVENTS
--------------------------------------------------------------------------------
-- LIBGS_PRESENT
-- LIBGS_PING
-- LIBGS_REQUEST
--------------------------------------------------------------------------------
-- PRIVATE DATA
--------------------------------------------------------------------------------
local Clothing, Weapon = 1, 2
local equipmentType = {
	-- left side
	[ DRESS_SLOT_HELM ]        = Clothing, -- [0]
	[ DRESS_SLOT_MANTLE ]      = Clothing, -- [4]
	[ DRESS_SLOT_CLOAK ]       = Clothing, -- [12]
	[ DRESS_SLOT_ARMOR ]       = Clothing, -- [1]
	[ DRESS_SLOT_GLOVES ]      = Clothing, -- [5]
	[ DRESS_SLOT_BELT ]        = Clothing, -- [7]
	[ DRESS_SLOT_PANTS ]       = Clothing, -- [2]
	[ DRESS_SLOT_BOOTS ]       = Clothing, -- [3]
	-- right side
	[ DRESS_SLOT_EARRINGS ]    = Clothing, -- [41] = [10] & [26]
	[ DRESS_SLOT_NECKLACE ]    = Clothing, -- [11]
	[ DRESS_SLOT_SHIRT ]       = Clothing, -- [13]
	[ DRESS_SLOT_BRACERS ]     = Clothing, -- [6]
	[ DRESS_SLOT_RING ]        = Clothing, -- [40] = [8] & [9]
	-- weapon
	[ DRESS_SLOT_RANGED ]      = Weapon, -- [16] -- Спец. Оружие
	[ DRESS_SLOT_TWOHANDED ]   = Weapon, -- [38] = [14] -- Двуручка
	[ DRESS_SLOT_DUALWIELD ]   = Weapon, -- [39] = [14] -- Парники
	[ DRESS_SLOT_MAINHAND ]    = Weapon, -- [14] -> [14] | [38] | [39] -- Правая рука
	[ DRESS_SLOT_OFFHAND ]     = Weapon, -- [15] -- Левая рука
}
local equipmentQuality = {
	[ ITEM_QUALITY_JUNK ]      = 1, -- Grey
	[ ITEM_QUALITY_GOODS ]     = 2, -- White
	[ ITEM_QUALITY_COMMON ]    = 3, -- Green
	[ ITEM_QUALITY_UNCOMMON ]  = 4, -- Blue
	[ ITEM_QUALITY_RARE ]      = 5, -- Violet
	[ ITEM_QUALITY_EPIC ]      = 6, -- Orange
	[ ITEM_QUALITY_LEGENDARY ] = 7, -- Cyan
	[ ITEM_QUALITY_RELIC ]     = 8, -- Yellow
}
local Offensive, Defensive = 1, 2
local runeType = {
	[ DRESS_SLOT_OFFENSIVERUNE1 ] = Offensive,
	[ DRESS_SLOT_OFFENSIVERUNE2 ] = Offensive,
	[ DRESS_SLOT_OFFENSIVERUNE3 ] = Offensive,
	[ DRESS_SLOT_DEFENSIVERUNE1 ] = Defensive,
	[ DRESS_SLOT_DEFENSIVERUNE2 ] = Defensive,
	[ DRESS_SLOT_DEFENSIVERUNE3 ] = Defensive,
}
local runeBonusField = { [ Offensive ] = "offensiveBonus", [ Defensive ] = "defensiveBonus" }
local runeQuality = { 1, 3, 3, 3, 4, 4, 4, 5, 5, 5, 5, 6, 6, 7 }
local fairyText = { '-', 'I', 'II', 'III', 'IV', 'V' }
local QualityStyle = {
	'Junk',
	'Goods',
	'Common',
	'Uncommon',
	'Rare',
	'Epic',
	'Legendary',
	'Relic'
}
-- Master part data
-- a) State machine
local GS_Busy
local GS_Requester
local GS_Waiting
local GS_Completed
local GS_InspectingUnit
local GS_Info
-- b) Queue
local GS_MasterQueue
local GS_MasterQueueN
-- c) Zone probing
local GS_InspectionTimeout = 3
local GS_Timer
local GS_Zone -- cached current zone id
local GS_ProbedZone
local GS_Once
local GS_Disabled
-- Client part data
local GS_TIEnabled
local GS_Queue
local GS_QueueN
-- Negotiations data
local GS_Addons
local GS_AddonsN
local GS_AddonParams
local GS_MyId
local GS_MyVersion = 8
local GS_Id_Master
local GS_Is_Master
-- Functions
local UnitIsFriend
local GetItemInfo
local GetItemBonus
local GetItemQuality
local GetRuneInfo
local ItemIsCursed
local GetGearScore
--------------------------------------------------------------------------------
-- GEARSCORE INFO HELPERS
--------------------------------------------------------------------------------
local function safe_div( S , N )
	return N > 0 and S / N or 0
end
local function GetGearScoreV7( unitId, result )
	local equip = unit.GetEquipmentItemIds( unitId, ITEM_CONT_EQUIPMENT ) or {}
	local Qs = 0
	local Qn = 0
	local Ls = 0
	local N = 0
	for slot,item in pairs( equip ) do
		local info = GetItemInfo( item )
		local quality = GetItemQuality( item )
		local t = equipmentType[ info.dressSlot ]
		if t then
			Ls = Ls + info.level
			N = N + 1
		end
		if t and quality and quality.quality then 
			Qs = Qs + equipmentQuality[quality.quality]
			Qn = Qn + 1
		end
	end
	if unitId == avatar.GetId() then
		local gs = avatar.GetGearScoreInfo()
		result.gearscore = gs and gs.currentValue or 0
	else
		result.gearscore = unit.GetGearScore( unitId )
	end
	result.equipmentLevel = safe_div( Ls , N )
	result.equipmentQuality = safe_div( Qs , Qn )
	result.equipmentStyle = QualityStyle[ math.floor(result.equipmentQuality + 0.3) ]
	local q = result.equipmentQuality
	local delta = result.equipmentLevel - unit.GetLevel(unitId)
	if delta >= 4 then q = q + 0.36 elseif delta <= -3 then q = q - 0.9 end
	result.gearscoreLevel = result.equipmentLevel
	result.gearscoreQuality = q < 1 and 1 or q > 8 and 8 or q
	result.gearscoreStyle = QualityStyle[ math.floor(result.gearscoreQuality + 0.3) ]
end
local function GetGearScoreV6( unitId, result )
	local equip = unit.GetEquipmentItemIds( unitId, ITEM_CONT_EQUIPMENT ) or {}
	local Qs = 0
	local Qn = 0
	local Ls = 0
	local N = 0
	for slot,item in pairs( equip ) do
		local info = GetItemInfo( item )
		local quality = GetItemQuality( item )
		local t = equipmentType[ info.dressSlot ]
		if t then
			Ls = Ls + info.level
			N = N + 1
		end
		if t and quality and quality.quality then 
			Qs = Qs + equipmentQuality[quality.quality]
			Qn = Qn + 1
		end
	end
	result.gearscore = unit.GetGearScore( unitId )
	result.equipmentLevel = safe_div( Ls , N )
	result.equipmentQuality = safe_div( Qs , Qn )
	result.equipmentStyle = QualityStyle[ math.floor(result.equipmentQuality + 0.3) ]
	local q = result.equipmentQuality
	local delta = result.equipmentLevel - unit.GetLevel(unitId)
	if delta >= 2 then q = q + 0.67 elseif delta <= -3 then q = q - 0.9 end
	result.gearscoreLevel = result.equipmentLevel
	result.gearscoreQuality = q < 1 and 1 or q > 8 and 8 or q
	result.gearscoreStyle = QualityStyle[ math.floor(result.gearscoreQuality + 0.3) ]
end
local function GetGearScoreV5( unitId, result )
	local equip = unit.GetEquipmentItemIds( unitId, ITEM_CONT_EQUIPMENT ) or {}
	local statsB = { [ Clothing ] = 0, [ Weapon ] = 0 }
	local statsA = { [ Clothing ] = 0, [ Weapon ] = 0 }
	local statsD = { [ Clothing ] = 0, [ Weapon ] = 0 }
	local Qs = 0
	local Qn = 0
	local Ls = 0
	local N = 0
	for slot,item in pairs( equip ) do
		local info = GetItemInfo( item )
		local bonus = GetItemBonus( item )
		local quality = GetItemQuality( item )
		local t = equipmentType[ info.dressSlot ]
		if t then
			Ls = Ls + info.level
			N = N + 1
		end
		if t and bonus and not itemLib.IsCursed( item ) then
			local db = bonus.miscStats.power.effective + bonus.miscStats.stamina.effective
			local da = 0
			for i = 0, 8 do
				da = da + bonus.innateStats[i].effective
			end
			statsB[ t ] = statsB[ t ] + db
			statsA[ t ] = statsA[ t ] + da
		end
		if t and quality and quality.quality then 
			Qs = Qs + equipmentQuality[quality.quality]
			Qn = Qn + 1
		end
	end
	local dragon = unit.GetEquipmentItemIds( unitId, ITEM_CONT_EQUIPMENT_RITUAL ) or {}
	for slot,item in pairs( dragon ) do
		local info = GetItemInfo( item )
		local t = equipmentType[ info.dressSlot ]
		local bonus = GetItemBonus( item )
		if t and bonus and not itemLib.IsCursed( item ) then
			local dd = bonus.miscStats.stamina.effective
			statsD[ t ] = statsD[ t ] + dd
		end
	end
	result.gearscore = (statsB[ Clothing ] + 4 * statsB[ Weapon ]) * (1 + 0.005 * (statsA[ Clothing ] + statsA[ Weapon ])) + 1.12 * (statsD[ Clothing ] + 4 * statsD[ Weapon ])
	result.equipmentLevel = safe_div( Ls , N )
	result.equipmentQuality = safe_div( Qs , Qn )
	result.equipmentStyle = QualityStyle[ math.floor(result.equipmentQuality + 0.3) ]
	local q = result.equipmentQuality
	local delta = result.equipmentLevel - unit.GetLevel(unitId)
	if delta >= 2 then q = q + 0.67 elseif delta <= -3 then q = q - 1 end
	result.gearscoreLevel = result.equipmentLevel
	result.gearscoreQuality = q < 1 and 1 or q > 8 and 8 or q
	result.gearscoreStyle = QualityStyle[ math.floor(result.gearscoreQuality + 0.3) ]
end
local function GetGearScoreV4( unitId, result )
	local mult = {
			[ INNATE_STAT_STRENGTH ]    = 4,  -- + Сила
			[ INNATE_STAT_MIGHT ]       = 4,  -- + Точность
			[ INNATE_STAT_DEXTERITY ]   = 4,  -- + Ловкость
			[ INNATE_STAT_AGILITY ]     = 1,  -- + Проворство
			[ INNATE_STAT_STAMINA ]     = 1,  -- + Выносливость
			[ INNATE_STAT_PRECISION ]   = 4,  -- + Удача
			[ INNATE_STAT_HARDINESS ]   = 1,  -- + Инстинкт
			[ INNATE_STAT_INTELLECT ]   = 4,  -- + Разум
			[ INNATE_STAT_INTUITION ]   = 4,  -- + Интуиция
			[ INNATE_STAT_SPIRIT ]      = 4,  -- + Дух
			[ INNATE_STAT_WILL ]        = 1,  -- + Упорство
			[ INNATE_STAT_RESOLVE ]     = 1,  -- + Воля
			[ INNATE_STAT_WISDOM ]      = 0,  -- + Мудрость
			[ INNATE_STAT_LETHALITY ]   = 1,  -- + Ярость
		}
	local gear = 0
	local Qs = 0
	local Qn = 0
	local Ls = 0
	local N = 0
	local equip = unit.GetEquipmentItemIds( unitId, ITEM_CONT_EQUIPMENT ) or {}
	for slot,item in pairs( equip ) do
		local info = GetItemInfo( item )
		local bonus = GetItemBonus( item )
		local quality = GetItemQuality( item )
		local t = equipmentType[ info.dressSlot ]
		if t then
			Ls = Ls + info.level
			N = N + 1
		end
		if t and bonus and bonus.innateStats and not itemLib.IsCursed( item ) then
			local db = 0
			if t == Weapon then
				for u,p in pairs(bonus.innateStats) do
					if p.effective > 0 then
						db = db + p.effective * mult[u]
					end
				end
			else
				for u,p in pairs(bonus.innateStats) do
					if p.effective > 0 then
						db = db + p.effective
					end
				end
			end
			gear = gear + db
		end
		if t and quality and quality.quality then 
			Qs = Qs + equipmentQuality[quality.quality]
			Qn = Qn + 1
		end
	end
	local ritual = unit.GetEquipmentItemIds( unitId, ITEM_CONT_EQUIPMENT_RITUAL ) or {}
	for slot,item in pairs( ritual or {} ) do
		local info = GetItemInfo( item )
		local t = equipmentType[ info.dressSlot ]
		local bonus = GetItemBonus( item )
		if t and bonus and bonus.innateStats and not itemLib.IsCursed( item ) then
			local dd = 0
			if t == Weapon then
				for u,p in pairs(bonus.innateStats) do
					if p.effective > 0 then
						dd = dd + p.effective * mult[u]
					end
				end
			else
				-- 45 lvl equipment gives 6 points, 51 - 9 points, 55 - 12 points
				dd = ( info.level == 45 and 6 ) or
				     ( info.level == 51 and 9 ) or
					 ( info.level == 55 and 12) or 0
			end
			gear = gear + dd
		end
	end
	result.gearscore = gear
	result.equipmentLevel = safe_div( Ls , N )
	result.equipmentQuality = safe_div( Qs , Qn )
	result.equipmentStyle = QualityStyle[ math.floor(result.equipmentQuality + 0.3) ]
	result.gearscoreLevel = result.equipmentLevel
	result.gearscoreQuality = result.equipmentQuality
	result.gearscoreStyle = QualityStyle[ math.floor(result.gearscoreQuality + 0.3) ]
end
local function GetRunes( unitId, result )
	local Bs = { [ Offensive ] = 0, [ Defensive ] = 0 }
	local Rs = { [ Offensive ] = 0, [ Defensive ] = 0 }
	local Rn = { [ Offensive ] = 0, [ Defensive ] = 0 }
	result.runes = {}
	for slot,t in pairs(runeType) do
		local id = unit.GetEquipmentItemId( unitId, slot, ITEM_CONT_EQUIPMENT )
		local info = id and GetRuneInfo( id )
		local rank = info ~= nil and (info.level or info.runeLevel) or 0
		local bonus = info ~= nil and info[ runeBonusField[ t ] ] or 0
		result.runes[slot] = {}
		result.runes[slot].runeQuality = rank
		result.runes[slot].runeScore = bonus
		result.runes[slot].runeStyle = QualityStyle[ runeQuality[ rank + 1 ] ]
		Bs[ t ] = Bs[ t ] + bonus
		Rs[ t ] = Rs[ t ] + rank
		Rn[ t ] = Rn[ t ] + 1
	end
	result.runesQuality = safe_div( Rs [ Offensive ] + Rs [ Defensive ] , Rn [ Offensive ] + Rn [ Defensive ] )
	result.runesQualityOffensive = safe_div( Rs [ Offensive ] , Rn [ Offensive ] )
	result.runesQualityDefensive = safe_div( Rs [ Defensive ] , Rn [ Defensive ] )
	result.runesScoreOffensive = Bs[ Offensive ]
	result.runesScoreDefensive = Bs[ Defensive ]
	result.runesStyle = QualityStyle[ runeQuality[ math.floor(result.runesQuality + 1.1) ] ]
	result.runesStyleOffensive = QualityStyle[ runeQuality[ math.floor(result.runesQualityOffensive + 1.1) ] ]
	result.runesStyleDefensive = QualityStyle[ runeQuality[ math.floor(result.runesQualityDefensive + 1.1) ] ]
end
local function GetFairy( unitId, result )
	local info = unit.GetFairyInfo( unitId )
	local exists = info ~= nil and info.isExist
	local rank = exists and info.rank or 0
	result.fairy = fairyText[ rank + 1 ]
	result.fairyLevel = exists and info.level or 0
	result.fairyQuality = rank
	result.fairyScore = exists and info.bonusStatValue or nil
	result.fairyScoreStat = exists and info.bonusStat or nil
	result.fairyScorePower = exists and info.powerBonus or nil
	result.fairyScoreDamage = exists and info.dpsBonus and ((info.dpsBonus-1)*100) or 0
	result.fairyScoreHeal = exists and info.healBonus and ((info.healBonus-1)*100) or 0
	result.fairyStyle = QualityStyle[ rank + 1 ]
end
local function GetArtifacts( unitId, result )
	if not guildHallLib then -- less AO 11.0.??
		result.artefactQuality = 0
		return
	end
	local artifactsArr = {}
	local equip = unit.GetEquipmentItemIds( unitId, ITEM_CONT_EQUIPMENT ) or {}
	for slot,item in pairs( equip ) do
		local info = GetItemInfo( item )
		if info.dressSlot == DRESS_SLOT_ARTIFACT then
			table.insert(artifactsArr, info.level)
		end
	end
	local artSumm = 0
	for _,artLvl in pairs(artifactsArr) do
		artSumm = artSumm + artLvl
	end
	
	result.artefactQuality = artSumm / 3
end
local function GetFullInfo( unitId, info )
	info = info or avatar.GetInspectInfo()
	local result = {}
	local rank = info and info.rank or 0
	result.rank = rank
	result.unitId = unitId
	if unitId == avatar.GetId() then
		result.inspected = true
		result.reliable = true
	elseif UnitIsFriend(unitId) then
		result.inspected = rank >= 1
		result.reliable = rank >= 3
	else
		result.inspected = rank >= 4
		result.reliable = rank == 6
	end
	if result.inspected then
		GetGearScore( unitId, result )
		if not common.IsOnPayToPlayShard or not common.IsOnPayToPlayShard() then
			GetRunes( unitId, result )
		end
		GetArtifacts( unitId, result )
	end
	GetFairy( unitId, result )
	return result
end
--------------------------------------------------------------------------------
-- MASTER PART OPERATIONS
--------------------------------------------------------------------------------
-- Flow:
-- Client: GS.RequestInfo -> RequestInfo -> add to queue, send LIBGS_REQUEST
-- Master: OnGearScoreRequested -> add to queue, ScheduleQueue -> send LIBGS_PING
--         OnPing -> ProcessQueue -> remove from queue, start timer, StartUnit -> avatar.StartInspect
--         OnSecondTimer -> reset, disable, DropQueue
--         OnInspectStarted -> avatar.GetInspectInfo, avatar.EndInspect
--         OnInspectFinished -> send LIBGS_GEARSCORE_AVAILABLE, ScheduleQueue
--                           -> StartUnit
-- Client: OnGearScoreAvailable -> remove from queue, GS.Callback
local function DropQueue()
	GS_MasterQueue, GS_MasterQueueN = nil, nil
end
local function OnSecondTimer( params )
	GS_Timer = GS_Timer + 1
	-- 2-3 seconds timeout for event
	if GS_Timer >= GS_InspectionTimeout or GS_Once then
		local func = common.UnRegisterEventHandler
		func( OnSecondTimer, "EVENT_SECOND_TIMER" )
		GS_Timer = nil
		GS_Disabled = not GS_Once
		GS_ProbedZone = GS_Zone
		if GS_Disabled then
			-- Reset state machine, it should be like after OnInspectFinished
			GS_InspectingUnit = nil
			GS_Requester = false
			GS_Waiting = false
			GS_Busy = false
			-- Drop queue safely
			DropQueue()
		end
	end
end
local function OnZoneChanged( params )
	local zone = cartographer.GetCurrentZoneInfo() or { zonesMapId = -1 }
	GS_Zone = zone.zonesMapId
end
local function StartUnit( unitId )
	-- Starting inspection
	-- Prepare state machine for new inspection cycle
	GS_InspectingUnit = unitId
	GS_Info = nil
	GS_Waiting = true
	GS_Completed = false
	GS_Requester = true
	GS_Busy = true -- GS_Busy - protector of current inspection cycle, and for GS_Requester
	if not GS_Once and not GS_Disabled and not GS_Timer then
		-- Wait for event timeout
		local func = common.RegisterEventHandler
		func( OnSecondTimer, "EVENT_SECOND_TIMER" )
		GS_Timer = 0
	end
	avatar.StartInspect( unitId )
end
local function ScheduleQueue( initial )
	-- Allow short "delay" between inspection cycles, less freezes
	userMods.SendEvent( "LIBGS_PING", { initial = initial } )
end
local function ProcessQueue()
	if not GS_MasterQueue then return end
	if GS_Zone ~= GS_ProbedZone then
		-- Prepare for StartUnit to start timer
		GS_Once = false
		GS_Disabled = false
		GS_ProbedZone = GS_Zone
	end
	if avatar.IsInspectAllowed and not avatar.IsInspectAllowed() then
		GS_Disabled = true
	end
-- | avatar.IsTargetInspected() | GS_Busy | Meaning
-- |   true                     |  true   | Inspection window is opened now, or other addon is inspecting unit, somewhere between avatar.StartInspect() and avatar.EndInspect()
-- |                            |         |   (Closing inspection and) waiting for EVENT_INSPECT_FINISHED to restart queue
-- |   false                    |  true   | Just finished inspection, somewhere between avatar.EndInspect() and EVENT_INSPECT_FINISHED
-- |                            |         |   Waiting for EVENT_INSPECT_FINISHED to restart queue
-- |   true                     |  false  | Inspection window is going to be opened now, or other addon just requested inspection, somewhere between avatar.StartInspect() and EVENT_INSPECT_STARTED
-- |                            |         |   (Closing inspection and) waiting for EVENT_INSPECT_STARTED -> EVENT_INSPECT_FINISHED cycle to restart queue
-- |   false                    |  false  | No inspection in progress
-- |                            |         |   Restarting queue
	if GS_Disabled then
		DropQueue()
	elseif not GS_Busy and not avatar.IsTargetInspected() then
		while true do
			local unitId = GS_MasterQueue[1]
			for i = GS_MasterQueueN, 1, -1 do
				if GS_MasterQueue[i] == unitId then
					table.remove(GS_MasterQueue, i)
					GS_MasterQueueN = GS_MasterQueueN - 1
				end
			end
			if not unitId then
				GS_MasterQueue, GS_MasterQueueN = nil, nil
				break
			elseif unitId == avatar.GetId() then
				local Info = GetFullInfo(unitId)
				userMods.SendEvent( "LIBGS_GEARSCORE_AVAILABLE", Info )
			elseif object.IsExist( unitId ) then
				StartUnit( unitId )
				break
			end
		end
	end
end
local function OnPing( params )
	ProcessQueue()
end
local function OnGearScoreRequested( params )
	if not params.unitId and not params.Queue then return end
	if not GS_MasterQueue then
		GS_MasterQueue, GS_MasterQueueN = {}, 0
		-- Let me receive all LIBGS_REQUEST before start processing queue
		ScheduleQueue( true )
	end
	for _,unitId in ipairs(params.Queue or { params.unitId } ) do
		if unitId and object.IsExist( unitId ) and object.IsUnit( unitId ) and unit.IsPlayer( unitId ) and not unit.IsPet( unitId ) then
			if unitId ~= GS_InspectingUnit or GS_Completed then
				table.insert(GS_MasterQueue, unitId)
				GS_MasterQueueN = GS_MasterQueueN + 1
			end
		end
	end
end
local function OnInspectStarted()
	GS_Once = true
	GS_Busy = true
	if not GS_Requester then
		-- Inspection requested by other addon/LibGS
		-- Waiting for EVENT_INSPECT_FINISHED to check queue
		-- Waiting for LIBGS_GEARSCORE_AVAILABLE to check it is for my unit
		return
	end
	-- Currently assured that i'm initiator of inspection, but not sure yet it's for my unit
	if not avatar.IsTargetInspected() then
		-- Conflicting with other addon/LibGS, which just closed inspection,
		-- so we can not inspect even if it was for the same unit
		-- Waiting for EVENT_INSPECT_FINISHED to restart inspection
		return
	end
	local info = avatar.GetInspectInfo()
	if not info or not info.playerId or not GS_InspectingUnit or info.playerId ~= GS_InspectingUnit then
		-- Conflicting with other addon/LibGS, which requested inspection for a different unit in parallel
		-- Waiting for EVENT_INSPECT_FINISHED to restart inspection
		return
	end
	-- Currently assured that this message is for me, for my request and for my unit, and still active
	if GS_Completed then
		-- Already received gearscore from another LibGS for my unit, which came right after my avatar.StartInspect(), and before EVENT_INSPECT_STARTED
		avatar.EndInspect()
		return
	end
	GS_Waiting = false
	GS_Info = GetFullInfo(GS_InspectingUnit, info)
	avatar.EndInspect()
end
local function OnInspectFinished()
	GS_Busy = true
	if GS_Waiting then
		-- Still have not received info for my unit, restarting inspection
		if avatar.IsTargetInspected() then
			-- Something just requested inspection... Race of addons ...
			-- Waiting for EVENT_INSPECT_STARTED -> EVENT_INSPECT_FINISHED cycle to continue my inspection
			GS_Requester = false
			return
		elseif object.IsExist( GS_InspectingUnit ) then
			GS_Requester = false
			StartUnit( unitId )
			return
		else
			-- Process next unit
			GS_Requester = false
			GS_Completed = true
			GS_Waiting = false
		end
	end
	if GS_Requester and not GS_Completed then
		userMods.SendEvent( "LIBGS_GEARSCORE_AVAILABLE", GS_Info )
		GS_Completed = true
	end
	GS_Requester = false
	GS_Busy = avatar.IsTargetInspected()
	ScheduleQueue( false )
	if not GS_Is_Master then
		local func = common.UnRegisterEventHandler
		func( OnInspectStarted, "EVENT_INSPECT_STARTED" )
		func( OnInspectFinished, "EVENT_INSPECT_FINISHED" )
	end
end
--------------------------------------------------------------------------------
-- CLIENT PART OPERATIONS
--------------------------------------------------------------------------------
local function RequestInfo( unitId )
	if not unitId or not avatar.IsExist() or not object.IsExist( unitId ) or not object.IsUnit( unitId ) or not unit.IsPlayer( unitId ) or unit.IsPet( unitId ) then return false end
	if not GS_Queue then GS_Queue, GS_QueueN = {}, 0 end
	for i = GS_QueueN, 1, -1 do
		if GS_Queue[i] == unitId then
			return true
		end
	end
	table.insert(GS_Queue, unitId)
	GS_QueueN = GS_QueueN + 1
	if GS_Id_Master then
		-- Not sending until first master has appeared
		userMods.SendEvent( "LIBGS_REQUEST", { from = GS_MyId, unitId = unitId } )
	end
	return true
end
local function OnTargetChanged()
	RequestInfo( avatar.GetTarget() )
end
local function OnGearScoreAvailable( params )
	if GS_Queue then
		for i = GS_QueueN, 1, -1 do
			if GS_Queue[i] == params.unitId then
				table.remove(GS_Queue, i)
				GS_QueueN = GS_QueueN - 1
				if GS.Callback then
					GS.Callback( params )
				end
				return
			end
		end
	end
end
--------------------------------------------------------------------------------
-- NEGOTIATIONS
--------------------------------------------------------------------------------
local function ResendQueue( Queue, N )
	if Queue and N > 0 then
		userMods.SendEvent( "LIBGS_REQUEST", { Queue = Queue, N = N } )
	end
end
local function ChangeMaster( Master )
	local Enable = Master == GS_MyId
	GS_Id_Master = Master
	if GS_Is_Master ~= Enable then
		local func = Enable and common.RegisterEventHandler or common.UnRegisterEventHandler
		func( OnPing, "LIBGS_PING" )
		func( OnGearScoreRequested, "LIBGS_REQUEST" )
		func( OnZoneChanged, "EVENT_AVATAR_CLIENT_ZONE_CHANGED" )
		if Enable or GS_Completed ~= false then
			func( OnInspectStarted, "EVENT_INSPECT_STARTED" )
			func( OnInspectFinished, "EVENT_INSPECT_FINISHED" )
		end
		GS_Is_Master = Enable
		if Enable then
			GS_Busy = avatar.IsExist() and (avatar.IsInspectAllowed == nil or avatar.IsInspectAllowed()) and avatar.IsTargetInspected()
			-- Ensure current zone ID is updated
			GS_Zone = (cartographer.GetCurrentZoneInfo() or { zonesMapId = -1 }).zonesMapId
			GS_ProbedZone = -2
			GS_Once = false
			GS_Disabled = false
		else
			-- Resend queue to new master and drop the queue now
			ResendQueue(GS_MasterQueue, GS_MasterQueueN)
			GS_MasterQueue, GS_MasterQueueN = nil, nil
		end
	end
end
local function OnAddonLoadStateChanged( params )
	if params.unloading then
		if params.name == GS_Id_Master then
			if not params.loading then
				-- Master has been unloaded (not reloaded)
				local v, m
				for i = GS_AddonsN, 1, -1 do
					if params.name == GS_Addons[i] then
						GS_AddonParams[ GS_Addons[i] ] = nil
						table.remove(GS_Addons, i)
						GS_AddonsN = GS_AddonsN - 1
					elseif not v or v < GS_AddonParams[ GS_Addons[i] ].version then
						v = GS_AddonParams[ GS_Addons[i] ].version
						m = GS_Addons[i]
					end
				end
				-- true -> false should never happen here
				ChangeMaster(m)
				if GS_Is_Master and not GS_AddonParams[GS_MyId].resending then
					GS_AddonParams[GS_MyId].resending = true
					userMods.SendEvent( "LIBGS_PRESENT", { from = GS_MyId, version = GS_MyVersion, resending = true } )
				end
			end
			-- Master has lost his queue, resending
			ResendQueue(GS_Queue, GS_QueueN)
		else
			for i = GS_AddonsN, 1, -1 do
				if params.name == GS_Addons[i] then
					GS_AddonParams[ GS_Addons[i] ] = nil
					table.remove(GS_Addons, i)
					GS_AddonsN = GS_AddonsN - 1
				end
			end
		end
	end
end
local function OnLibraryLoaded( params )
	for i = GS_AddonsN, 1, -1 do
		if params.from == GS_Addons[i] then
			table.remove(GS_Addons, i)
			GS_AddonsN = GS_AddonsN - 1
		end
	end
	params.version = params.version or 0
	table.insert(GS_Addons, params.from)
	GS_AddonsN = GS_AddonsN + 1
	GS_AddonParams[params.from] = { version = params.version }
	if not GS_Id_Master then
		-- We just (re-)loaded. Send all collected in queue to master. Likely, it's empty.
		ResendQueue(GS_Queue, GS_QueueN)
	end
	if not GS_Id_Master or params.version > GS_AddonParams[GS_Id_Master].version or params.resending then
		ChangeMaster(params.from)
	end
	if GS_Is_Master and params.from ~= GS_MyId and not GS_AddonParams[GS_MyId].resending then
		GS_AddonParams[GS_MyId].resending = true
		userMods.SendEvent( "LIBGS_PRESENT", { from = GS_MyId, version = GS_MyVersion, resending = true } )
	end
end
--------------------------------------------------------------------------------
-- PUBLIC FUNCTIONS
--------------------------------------------------------------------------------
function GS.Init( EnableTargetAutoInspection, SkipInitialTargetInspection )
	if not GS.Init then return end
	GS.Init = nil
	if avatar.GetGearScoreInfo then -- AO 7.0.??+
		GetGearScore = GetGearScoreV7
	elseif unit.GetGearScore then -- AO 6.0.00+
		GetGearScore = GetGearScoreV6
	elseif avatar.GetPower then -- AO 5.0.00+
		GetGearScore = GetGearScoreV5
	elseif raid.IsAutomatic then -- AO 4.0.00+
		GetGearScore = GetGearScoreV4
	else
		common.LogWarning( "common", "AO versions 1.x, 2.0.x, 3.0.x are not supported yet" )
		return
	end
	GetGearScoreV4 = nil
	GetGearScoreV5 = nil
	GetGearScoreV6 = nil
	GetGearScoreV7 = nil
	local haveItemLib = rawget( _G, "itemLib" ) ~= nil
	GetItemInfo = haveItemLib and itemLib.GetItemInfo or avatar.GetItemInfo
	GetItemBonus = haveItemLib and itemLib.GetBonus or avatar.GetItemBonus
	GetItemQuality = haveItemLib and itemLib.GetQuality or avatar.GetItemInfo
	GetRuneInfo = haveItemLib and itemLib.GetRuneInfo or function ( itemId ) return itemId and (avatar.GetItemInfo(itemId) or {}).runeInfo end
	ItemIsCursed = haveItemLib and itemLib.IsCursed or function ( itemId ) return itemId and (avatar.GetItemInfo(itemId) or {}).isCursed end
	UnitIsFriend = object.IsFriend or unit.IsFriend
	common.RegisterEventHandler( OnGearScoreAvailable, "LIBGS_GEARSCORE_AVAILABLE" )
	-- Start Negotiations
	local info = common.GetAddonInfo() or {}
	GS_Is_Master = false
	GS_MyId = info and info.sysFullName or "UserAddon/"..common.GetAddonName()
	if not GS_Addons then GS_Addons, GS_AddonParams, GS_AddonsN = {}, {}, 0 end
	common.RegisterEventHandler( OnLibraryLoaded, "LIBGS_PRESENT" )
	common.RegisterEventHandler( OnAddonLoadStateChanged, "EVENT_ADDON_LOAD_STATE_CHANGED" )
	userMods.SendEvent( "LIBGS_PRESENT", { from = GS_MyId, version = GS_MyVersion, initial = true } )
	GS_TIEnabled = false
	GS.EnableTargetInspection( EnableTargetAutoInspection, SkipInitialTargetInspection )
end
function GS.EnableTargetInspection( Enable, SkipInitial )
	if GS.Init then GS.Init(false) end
	Enable = Enable ~= false
	if GS_TIEnabled ~= Enable then
		local func = Enable and common.RegisterEventHandler or common.UnRegisterEventHandler
		func( OnTargetChanged, "EVENT_AVATAR_TARGET_CHANGED" )
		func( OnTargetChanged, "EVENT_AVATAR_SECONDARY_TARGET_CHANGED" )
		GS_TIEnabled = Enable
		if Enable and not SkipInitial and avatar.IsExist() then
			OnTargetChanged()
		end
	end
end
function GS.RequestInfo( unitId )
	if GS.Init then GS.Init() end
	GS.RequestInfo = RequestInfo
	return RequestInfo( unitId )
end
--------------------------------------------------------------------------------