local m_myMainForm = nil
local m_template = nil
local m_runeTxtWidget = nil
local m_gsTxtWidget = nil
local m_fairyTxtWidget = nil
local m_exoTxtWidget = nil
local m_artTxtWidget = nil

local m_currMountHP = -1

function OnTargetChaged(params)
	local targetID = avatar.GetTarget()
	if not targetID or not object.IsExist(targetID) or not unit.IsPlayer(targetID) then
		hide(mainForm)
	end
end

function CreateValuedText(aText1, aText2, aText3, aStyle1, aStyle2, aStyle3)
	local formatStr = "<body fontname='AllodsWest' alignx = 'center' fontsize='14'><rs class='style1'>"..(toString(aText1) or "").."</rs><rs class='style2'>"..(toString(aText2) or "").."</rs><rs class='style3'>"..(toString(aText3) or "").."</rs></body>"
	local valuedText=common.CreateValuedText()
	valuedText:SetFormat(toWString(formatStr))
	
	valuedText:SetClassVal( "style1", aStyle1 or "" )
	valuedText:SetClassVal( "style2", aStyle2 or "" )
	valuedText:SetClassVal( "style3", aStyle3 or "" )
	
	return valuedText
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
	if aParams.unitId == avatar.GetTarget() then
		local txt = CreateValuedText(RuneToTxt(aParams.runesQualityOffensive), ":", RuneToTxt(aParams.runesQualityDefensive), aParams.runesStyleOffensive, "", aParams.runesStyleDefensive)
		m_runeTxtWidget:SetValuedText(txt)

		txt = CreateValuedText(aParams.fairy, "", "", aParams.fairyStyle, "", "")
		m_fairyTxtWidget:SetValuedText(txt)

		txt = CreateValuedText(tostring(math.floor(aParams.gearscore)), "", "", aParams.gearscoreStyle, "", "")
		m_gsTxtWidget:SetValuedText(txt)
		
		txt = CreateValuedText(aParams.artefactLvl1.." "..aParams.artefactLvl2.." "..aParams.artefactLvl3, "", "", 'Legendary', "", "")		
		m_artTxtWidget:SetValuedText(txt)
		
		show(mainForm)
	end
end

function Update()
	local targetID = avatar.GetTarget()
	if not targetID or not object.IsExist(targetID) or not unit.IsPlayer(targetID) then
		return
	end
	if not isVisible(mainForm) or not avatar.IsInspectAllowed() then
		return
	end
	
	local mountInfo = mount.GetUnitMountHealth( targetID )
	local mountMaxHealth = 0
	if mountInfo then
		mountMaxHealth = mountInfo.healthLimit
		mountMaxHealth = math.floor(mountMaxHealth / 1000)
	end
	if m_currMountHP ~= mountMaxHealth then
		local mountStyle = 'Junk'
		local txt = CreateValuedText(tostring(mountMaxHealth).."K", "", "", mountStyle, "", "")
		m_exoTxtWidget:SetValuedText(txt)
	end
	m_currMountHP = mountMaxHealth
end

function Init()
	--common.StateUnloadManagedAddon( "InspectCharacter" )	
	if GS.Init then GS.Init() end
	
	m_template = createWidget(nil, "Template", "Template")
	setTemplateWidget(m_template)
	m_myMainForm =  mainForm:GetChildChecked("MainPanel", false)
	DnD:Init(m_myMainForm, m_myMainForm, true)
	
	m_runeTxtWidget = createWidget(m_myMainForm, "runeHeader", "TextView", nil, nil, 66, 25, 0, 9)
	m_gsTxtWidget = createWidget(m_myMainForm, "runeHeader", "TextView", nil, nil, 70, 25, 115, 9)
	m_fairyTxtWidget = createWidget(m_myMainForm, "runeHeader", "TextView", nil, nil, 134, 25, 0, 9)
	m_exoTxtWidget = createWidget(m_myMainForm, "runeHeader", "TextView", nil, nil, 70, 25, 158, 9)
	m_artTxtWidget = createWidget(m_myMainForm, "artHeader", "TextView", nil, nil, 70, 25, 70, 9)
	
	hide(mainForm)
	
	common.RegisterEventHandler( OnTargetChaged, "EVENT_AVATAR_TARGET_CHANGED")
	common.RegisterEventHandler( ShowGearScore, "LIBGS_GEARSCORE_AVAILABLE")
	startTimer("updateTimer", Update, 0.2)
	
	GS.Callback = ShowGearScore
	GS.EnableTargetInspection( true )
	GS.EnableLiteMode( true )
end

if (avatar.IsExist()) then
	Init()
else
	common.RegisterEventHandler(Init, "EVENT_AVATAR_CREATED")
end
