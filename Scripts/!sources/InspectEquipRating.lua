local P2P_MODE = 1
local RUNE_SEPARATED_MODE = 2
local RUNE_AVERAGE_MODE = 3

local m_myMainForm = nil
local m_template = nil
local m_runeTxtWidget = nil
local m_gsTxtWidget = nil
local m_fairyTxtWidget = nil
local m_exoTxtWidget = nil
local m_artTxtWidget = nil

local m_currentFontSize = 14
local m_currentRuneMode = RUNE_AVERAGE_MODE
local m_currMountHP = -1

function IsBigInetrace()
	local isBigInetrace = userMods.GetGlobalConfigSection("InspectEquipRating_Big")
	return isBigInetrace and isBigInetrace.value
end 

function IsRuneSeparated()
	local isRuneSeparated = userMods.GetGlobalConfigSection("InspectEquipRating_RuneSeparated")
	return isRuneSeparated and isRuneSeparated.value
end 

function OnSlashCommand(aParams)
	local handled = false
	local chatCommand = toLowerString(aParams.text)
	if chatCommand == "/gsbig" or chatCommand == "\\gsbig" then
		userMods.SetGlobalConfigSection( "InspectEquipRating_Big", { value = true } )
		handled = true
	elseif chatCommand == "/gsnormal" or chatCommand == "\\gsnormal" then
		userMods.SetGlobalConfigSection( "InspectEquipRating_Big", { value = false } )
		handled = true
	elseif chatCommand == "/gsruneseparate" or chatCommand == "\\gsruneseparate" then
		userMods.SetGlobalConfigSection( "InspectEquipRating_RuneSeparated", { value = true } )
		handled = true
	elseif chatCommand == "/gsruneavg" or chatCommand == "\\gsruneavg" then
		userMods.SetGlobalConfigSection( "InspectEquipRating_RuneSeparated", { value = false } )
		handled = true
	end
	if handled then
		common.StateUnloadManagedAddon( "UserAddon/InspectEquipRating3" )
		common.StateLoadManagedAddon( "UserAddon/InspectEquipRating3" )
	end
end

function OnTargetChaged(params)
	local targetID = avatar.GetTarget()
	if not targetID or not object.IsExist(targetID) or not unit.IsPlayer(targetID) then
		hide(mainForm)
	end
end

function ToStringConv(aText)
	if not aText then return nil end
	if common.IsWString(aText) then
		aText = userMods.FromWString(aText)
	end
	return tostring(aText)
end

function CreateFormatText(anElementCnt)
	local formatStr = "<body fontname='AllodsWest' alignx = 'center' fontsize='"..tostring(m_currentFontSize).."'>"
	
	for i = 1, anElementCnt do
		formatStr = formatStr.."<rs class='style"..tostring(i).."'>".."<r name='elem"..tostring(i).."'/>".."</rs>"
	end
	formatStr = formatStr.."</body>"
	
	return formatStr
end

function RuneToTxt(aRuneVal)
	if aRuneVal == nil then 
		aRuneVal = 0 
	end
	local num1, num2 = math.modf(aRuneVal)
	local runeTxt = tostring(num1)
	if num2 ~= 0 then 
		runeTxt = runeTxt.."."..string.sub(tostring(num2), 3, 3)
	end
	return runeTxt
end

function ShowGearScore(aParams)
	if aParams.unitId ~= avatar.GetTarget() then
		return
	end

	if m_currentRuneMode == RUNE_AVERAGE_MODE then
		m_runeTxtWidget:SetVal("elem1", RuneToTxt(aParams.runesQualityOffensive))
		m_runeTxtWidget:SetVal("elem3", RuneToTxt(aParams.runesQualityDefensive))
		m_runeTxtWidget:SetClassVal("style1", aParams.runesStyleOffensive or "Goods")
		m_runeTxtWidget:SetClassVal("style3", aParams.runesStyleDefensive or "Goods")
	elseif m_currentRuneMode == RUNE_SEPARATED_MODE then
			m_runeTxtWidget:SetVal("elem1", tostring(aParams.runes[DRESS_SLOT_OFFENSIVERUNE1].runeQuality))
			m_runeTxtWidget:SetVal("elem3", tostring(aParams.runes[DRESS_SLOT_OFFENSIVERUNE2].runeQuality))
			m_runeTxtWidget:SetVal("elem5", tostring(aParams.runes[DRESS_SLOT_OFFENSIVERUNE3].runeQuality))
			m_runeTxtWidget:SetVal("elem7", tostring(aParams.runes[DRESS_SLOT_DEFENSIVERUNE1].runeQuality))
			m_runeTxtWidget:SetVal("elem9", tostring(aParams.runes[DRESS_SLOT_DEFENSIVERUNE2].runeQuality))
			m_runeTxtWidget:SetVal("elem11", tostring(aParams.runes[DRESS_SLOT_DEFENSIVERUNE3].runeQuality))
			
			m_runeTxtWidget:SetClassVal("style1", aParams.runes[DRESS_SLOT_OFFENSIVERUNE1].runeStyle)
			m_runeTxtWidget:SetClassVal("style3", aParams.runes[DRESS_SLOT_OFFENSIVERUNE2].runeStyle)
			m_runeTxtWidget:SetClassVal("style5", aParams.runes[DRESS_SLOT_OFFENSIVERUNE3].runeStyle)
			m_runeTxtWidget:SetClassVal("style7", aParams.runes[DRESS_SLOT_DEFENSIVERUNE1].runeStyle)
			m_runeTxtWidget:SetClassVal("style9", aParams.runes[DRESS_SLOT_DEFENSIVERUNE2].runeStyle)
			m_runeTxtWidget:SetClassVal("style11", aParams.runes[DRESS_SLOT_DEFENSIVERUNE3].runeStyle)
	elseif m_currentRuneMode == P2P_MODE then
		
	end

	m_fairyTxtWidget:SetVal("elem1", aParams.fairy)
	m_fairyTxtWidget:SetClassVal("style1", aParams.fairyStyle)
	
	m_gsTxtWidget:SetVal("elem1",tostring(math.floor(aParams.gearscore)))
	
	m_artTxtWidget:SetVal("elem1", aParams.artefactLvl1.." "..aParams.artefactLvl2.." "..aParams.artefactLvl3)
	
	ShowMountHP()
	
	show(mainForm)
end

function OnMountHPChanged(aParams)
	if aParams.unitId ~= avatar.GetTarget() then
		return
	end
	if not isVisible(mainForm) or not avatar.IsInspectAllowed() then
		return
	end
	ShowMountHP()
end

function ShowMountHP()
	local targetID = avatar.GetTarget()
	if not targetID or not object.IsExist(targetID) or not unit.IsPlayer(targetID) then
		return
	end
	
	local mountInfo = mount.GetUnitMountHealth( targetID )
	local mountMaxHealth = 0
	if mountInfo then
		mountMaxHealth = mountInfo.healthLimit
		mountMaxHealth = math.floor(mountMaxHealth / 1000)
	end
	if m_currMountHP ~= mountMaxHealth then	
		m_exoTxtWidget:SetVal("elem1", tostring(mountMaxHealth).."K")
	end
	m_currMountHP = mountMaxHealth
end

function Init()
	--common.StateUnloadManagedAddon( "InspectCharacter" )	
	if GS.Init then GS.Init() end
	m_template = getChild(mainForm, "Template")
	setTemplateWidget(m_template)
	
	m_myMainForm = mainForm:GetChildChecked("MainPanel", false)
	DnD:Init(m_myMainForm, m_myMainForm, true)
	if common.IsOnPayToPlayShard() then
		m_currentRuneMode = P2P_MODE
	elseif IsRuneSeparated() then
		m_currentRuneMode = RUNE_SEPARATED_MODE
		m_myMainForm:SetBackgroundTexture(common.GetAddonRelatedTextureGroup("common"):GetTexture("MainFrame2"))
	else
		m_currentRuneMode = RUNE_AVERAGE_MODE
	end
	
	m_runeTxtWidget = createWidget(m_myMainForm, "runeHeader", "TextView", nil, nil, 66, 25, 0, 9)
	m_gsTxtWidget = createWidget(m_myMainForm, "gsHeader", "TextView", nil, nil, 70, 25, 115, 9)
	m_fairyTxtWidget = createWidget(m_myMainForm, "fairyHeader", "TextView", nil, nil, 70, 25, 33, 9)
	m_exoTxtWidget = createWidget(m_myMainForm, "exoHeader", "TextView", nil, nil, 70, 25, 158, 9)
	m_artTxtWidget = createWidget(m_myMainForm, "artHeader", "TextView", nil, nil, 70, 25, 70, 9)
	
	hide(mainForm)
	
	if IsBigInetrace() then
		m_currentFontSize = 18
	else
		m_currentFontSize = 14
	end
	m_fairyTxtWidget:SetFormat(CreateFormatText(1))
	m_artTxtWidget:SetFormat(CreateFormatText(1))
	m_gsTxtWidget:SetFormat(CreateFormatText(1))
	m_exoTxtWidget:SetFormat(CreateFormatText(1))
	
	m_artTxtWidget:SetClassVal("style1", 'Legendary')
	m_exoTxtWidget:SetClassVal("style1", 'Junk')
	m_gsTxtWidget:SetClassVal("style1", "Goods")
		
	if m_currentRuneMode == P2P_MODE then
		m_runeTxtWidget:SetFormat(CreateFormatText(1))
		m_runeTxtWidget:SetVal("elem1", "p2p")
		m_runeTxtWidget:SetClassVal("style1", "Goods")
	elseif m_currentRuneMode == RUNE_SEPARATED_MODE then
		m_runeTxtWidget:SetFormat(CreateFormatText(11))
		resize(m_runeTxtWidget, 130)
		resize(m_myMainForm, 300, 35)
		local topShift = 9
		move(m_runeTxtWidget, 5, topShift)
		move(m_fairyTxtWidget, 113, topShift)
		move(m_artTxtWidget, 150, topShift)
		move(m_gsTxtWidget, 195, topShift)
		move(m_exoTxtWidget, 238, topShift)	
			
		m_runeTxtWidget:SetVal("elem2", " ")
		m_runeTxtWidget:SetVal("elem4", " ")
		m_runeTxtWidget:SetVal("elem6", " : ")
		m_runeTxtWidget:SetVal("elem8", " ")
		m_runeTxtWidget:SetVal("elem10", " ")
		
		m_runeTxtWidget:SetClassVal("style2", "Goods")
		m_runeTxtWidget:SetClassVal("style4", "Goods")
		m_runeTxtWidget:SetClassVal("style6", "Goods")
		m_runeTxtWidget:SetClassVal("style8", "Goods")
		m_runeTxtWidget:SetClassVal("style10", "Goods")
	else
		m_runeTxtWidget:SetFormat(CreateFormatText(3))
		m_runeTxtWidget:SetVal("elem2", ":")
		m_runeTxtWidget:SetClassVal("style2", "Goods")
	end
	
	if IsBigInetrace() then
		local currWidth= m_myMainForm:GetPlacementPlain().sizeX
		resize(m_myMainForm, currWidth*1.227, 55)
		local topShift = 16
		if m_currentRuneMode == RUNE_SEPARATED_MODE then
			resize(m_runeTxtWidget, 160)
			move(m_runeTxtWidget, 10, topShift)
			move(m_fairyTxtWidget, 147, topShift)
			move(m_artTxtWidget, 187, topShift)
			move(m_gsTxtWidget, 242, topShift)
			move(m_exoTxtWidget, 300, topShift)
		else
			move(m_runeTxtWidget, 6, topShift)
			move(m_fairyTxtWidget, 48, topShift)
			move(m_artTxtWidget, 87, topShift)
			move(m_gsTxtWidget, 142, topShift)
			move(m_exoTxtWidget, 200, topShift)
		end
	end
	
	common.RegisterEventHandler( OnTargetChaged, "EVENT_AVATAR_TARGET_CHANGED")
	common.RegisterEventHandler( OnSlashCommand, "EVENT_UNKNOWN_SLASH_COMMAND" )
	common.RegisterEventHandler( OnMountHPChanged, "EVENT_UNIT_MOUNT_HEALTH_CHANGED" )
	
	GS.Callback = ShowGearScore
	GS.EnableTargetInspection( true )
	GS.EnableLiteMode( true )
end

if (avatar.IsExist()) then
	Init()
else
	common.RegisterEventHandler(Init, "EVENT_AVATAR_CREATED")
end
