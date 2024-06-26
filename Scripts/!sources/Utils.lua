local cachedToWString = userMods.ToWString
local cachedFromWString = userMods.FromWString
local cachedIsWString = common.IsWString
local cachedIsExist = object.IsExist
local cachedIsUnit = object.IsUnit
--------------------------------------------------------------------------------
-- Integer functions
--------------------------------------------------------------------------------

function round(time)
	if not time then return nil end
	return math.floor(time+0.5)
end

--------------------------------------------------------------------------------
-- String functions
--------------------------------------------------------------------------------

local _lower = string.lower
local _upper = string.upper

function string.lower(s)
    return _lower(s:gsub("([�-�])",function(c) return string.char(c:byte()+32) end):gsub("�", "�"))
end

function string.upper(s)
    return _upper(s:gsub("([�-�])",function(c) return string.char(c:byte()-32) end):gsub("�", "�"))
end

function toWString(text)
	if not text then return nil end
	if not cachedIsWString(text) then
		text=cachedToWString(tostring(text))
	end
	return text
end

local function toStringUtils(text)
	if not text then return nil end
	if cachedIsWString(text) then
		text=cachedFromWString(text)
	end
	return tostring(text)
end

function toString(text)
	return cachedFromWString(text)
end

function toLowerString(text)
	text=toString(text)
	if not text then
		return nil
	end
	return string.lower(text)
end

function toLowerWString(text)
	text=toString(text)
	if not text then
		return nil
	end
	text=string.lower(text)
	return toWString(text)
end

function find(text, word)
	text=toStringUtils(text)
	word=toStringUtils(word)
	if text and word and word~="" then
		text=string.lower(text)
		word=string.lower(word)
		return string.find(text, word)
	end
	return false
end

function findSimpleString(text, word)
	if text and word and word~="" then
		return string.find(text, word)
	end
	return false
end

function findWord(text)
	if not text then return {} end
	if string.gmatch then return string.gmatch(toString(text), "([^,]+),*%s*") end
	return pairs({toString(text)})
end

function ConcatWString(...)
	local arg = { ... }
	local wStr = common.GetEmptyWString()
	for _, v in pairs(arg) do
		if type(v) == "number" then
			v = tostring(v)
		end
		wStr = wStr..v
	end
	return wStr
end 

function LogAllCSSStyle()
	local listCSS = common.GetCSSList()
	for i = 0, GetTableSize(listCSS) do
		if listCSS[i] then 
			LogInfo(listCSS[i])
		end
	end
end

function formatText(text, align, fontSize, shadow, outline, fontName)
	local firstPart = "<body fontname='"..(toStringUtils(fontName) or "AllodsWest").."' alignx = '"..(toStringUtils(align) or "left").."' fontsize='"..(toStringUtils(fontSize) or "14").."' shadow='"..(toStringUtils(shadow) or "0").."' outline='"..(toStringUtils(outline) or "1").."'><rs class='color'>"
	local textMessage = toWString(text) or common.GetEmptyWString()
	local secondPart = "</rs></body>"
	return ConcatWString(firstPart, textMessage, secondPart)
end

function toValuedText(text, color, align, fontSize, shadow, outline, fontName)
	local valuedText=common.CreateValuedText()
	text=toWString(text)
	if not valuedText or not text then return nil end
	valuedText:SetFormat(toWString(formatText(text, align, fontSize, shadow, outline, fontName)))
	
	if color then
		valuedText:SetClassVal( "color", color )
	else
		valuedText:SetClassVal( "color", "LogColorYellow" )
	end
	return valuedText
end

function compareStrWithConvert(aName1, aName2)
	local name1=toWString(aName1)
	local name2=toWString(aName2)
	if not name1 or not name2 then return nil end
	return name1 == name2
end

function compare(name1, name2)
	name1=toWString(name1)
	name2=toWString(name2)
	if not name1 or not name2 then return nil end
	return name1:Compare(name2, true) == 0
end

function getTimeString(ms)
	if		ms<1000	then return "0."..tostring(round(ms/100)).."s"
	else   	ms=round(ms/1000) end
	if		ms<60	then return tostring(ms).."s"
	else    ms=math.floor(ms/60) end
	if		ms<60	then return tostring(ms).."m"
	else    ms=round(ms/60) end
	if		ms<24	then return tostring(ms).."h"
	else    ms=round(ms/24) end
	return tostring(ms).."d"
end

function makeColorMoreGray(aColor)
	local grayedColor = {}
	grayedColor.r = aColor.r - 0.3
	grayedColor.g = aColor.g - 0.3
	grayedColor.b = aColor.b - 0.3
	grayedColor.a = aColor.a
	grayedColor.r = grayedColor.r > 0 and grayedColor.r or 0
	grayedColor.g = grayedColor.g > 0 and grayedColor.g or 0
	grayedColor.b = grayedColor.b > 0 and grayedColor.b or 0
	
	return grayedColor
end

function makeColorMoreTransparent(aColor)
	local grayedColor = {}
	grayedColor.r = aColor.r
	grayedColor.g = aColor.g
	grayedColor.b = aColor.b
	grayedColor.a = aColor.a - 0.4
	grayedColor.a = grayedColor.a > 0 and grayedColor.a or 0
	
	return grayedColor
end

function compareColor(aColor1, aColor2)
	if not aColor1 or not aColor2 then
		return false
	end
	if aColor1.r ~= aColor2.r or aColor1.g ~= aColor2.g or aColor1.b ~= aColor2.b or aColor1.a ~= aColor2.a then
		return false
	end
	return true
end

--------------------------------------------------------------------------------
-- Log functions
--------------------------------------------------------------------------------

function logMemoryUsage()
	common.LogInfo( common.GetAddonName(), "usage "..tostring(gcinfo()).."kb" )
end


--------------------------------------------------------------------------------
-- Widget funtions
--------------------------------------------------------------------------------

Global("WIDGET_ALIGN_LOW", 0)
Global("WIDGET_ALIGN_HIGH", 1)
Global("WIDGET_ALIGN_CENTER", 2)
Global("WIDGET_ALIGN_BOTH", 3)
Global("WIDGET_ALIGN_LOW_ABS", 4)

function destroy(widget)
	if widget and widget.DestroyWidget then widget:DestroyWidget() end
end

function isVisible(widget)
	if widget and widget.IsVisible then return widget:IsVisible() end
	return nil
end

function getChild(widget, name, g)
	if g==nil then g=false end
	if not widget or not widget.GetChildUnchecked or not name then return nil end
	return widget:GetChildUnchecked(name, g)
end

function move(widget, posX, posY)
	if not widget then return end
	local BarPlace=widget.GetPlacementPlain and widget:GetPlacementPlain()
	if not BarPlace then return nil end
	if posX then
		BarPlace.posX = posX
		BarPlace.highPosX = posX
	end
	if posY then
		BarPlace.posY = posY
		BarPlace.highPosY = posY
	end
	if widget.SetPlacementPlain then widget:SetPlacementPlain(BarPlace) end
end

function setFade(widget, fade)
	if widget and fade and widget.SetFade then
		widget:SetFade(fade)
	end
end

function resize(widget, width, height)
	if not widget then return end
	local BarPlace=widget.GetPlacementPlain and widget:GetPlacementPlain()
	if not BarPlace then return nil end
	if width then BarPlace.sizeX = width end
	if height then BarPlace.sizeY = height end
	if widget.SetPlacementPlain then widget:SetPlacementPlain(BarPlace) end
end

function align(widget, alignX, alingY)
	if not widget then return end
	local BarPlace=widget.GetPlacementPlain and widget:GetPlacementPlain()
	if not BarPlace then return nil end
	if alignX then BarPlace.alignX = alignX end
	if alingY then BarPlace.alignY = alingY end
	if widget.SetPlacementPlain then widget:SetPlacementPlain(BarPlace) end
end

function priority(widget, priority)
	if not widget or not priority then return nil end
	if widget.SetPriority then widget:SetPriority(priority) end
end

function show(widget)
	if not widget  then return nil end
	if widget:IsVisible() then return nil end
	widget:Show(true)
end

function hide(widget)
	if not widget  then return nil end
	if not widget:IsVisible()  then return nil end
	widget:Show(false)
end

function setName(widget, name)
	if not widget or not name then return nil end
	if widget.SetName then widget:SetName(name) end
end

function getName(widget)
	return widget and widget.GetName and widget:GetName() or nil
end

function getText(widget)
	return widget and widget.GetText and widget:GetText() or nil
end

function getTextString(widget)
	return widget and widget.GetText and toStringUtils(widget:GetText()) or nil
end

function setText(widget, text, color, align, fontSize, shadow, outline, fontName)
	if not widget then return nil end
	text=toWString(text or "")
	if widget.SetVal 		then widget:SetVal("button_label", text)  end
	--if widget.SetTextColor	then widget:SetTextColor("button_label", { a = 1, r = 1, g = 0, b = 0 } ) end --ENUM_ColorType_SHADOW
	if widget.SetText		then widget:SetText(text) end
	if widget.SetValuedText then widget:SetValuedText(toValuedText(text, color or "ColorWhite", align, fontSize, shadow, outline, fontName)) end
end

function setBackgroundTexture(widget, texture)
	if not widget or not widget.SetBackgroundTexture then return nil end
	widget:SetBackgroundTexture(texture)
end

function setBackgroundColor(widget, color)
	if not widget or not widget.SetBackgroundColor then return nil end
	if not color then color={ r = 0; g = 0, b = 0; a = 0 } end
	widget:SetBackgroundColor(color)
end

local templateWidget=nil

function getDesc(name)
	local widget=templateWidget and name and templateWidget.GetChildUnchecked and templateWidget:GetChildUnchecked(name, false)
	return widget and widget.GetWidgetDesc and widget:GetWidgetDesc() or nil
end

function getParent(widget, num)
	if not num or num<1 then num=1 end
	if not widget or not widget.GetParent then return nil end
	local parent=widget:GetParent()
	if num==1 then return parent end
	return getParent(parent, num-1)
end

function getForm(widget)
	if not widget then return nil end
	if not widget.CreateWidgetByDesc then
		return getForm(getParent(widget))
	end
	return widget
end

function createWidget(parent, widgetName, templateName, alignX, alignY, width, height, posX, posY, noParent)
	local widget = nil
	local owner=getForm(parent)

	local desc = getDesc(templateName)
	if not desc and parent then return nil end
	widget = owner and owner:CreateWidgetByDesc(desc)
	if parent and widget and not noParent then parent:AddChild(widget) end
	setName(widget, widgetName)
	align(widget, alignX, alignY)
	move(widget, posX, posY)
	resize(widget, width, height)
	return widget
end

function setTemplateWidget(widget)
	templateWidget=widget
end

function equals(widget1, widget2)
	if not widget1 or not widget2 then return nil end
	return widget1.IsEqual and widget1:IsEqual(widget2) or widget2.IsEqual and widget2:IsEqual(widget1) or nil
end

function swap(widget)
	if widget and widget.IsVisible and not widget:IsVisible() then
		show(widget)
	else
		hide(widget)
	end
end

function changeCheckBox(widget)
	if not widget or not widget.GetVariantCount then return end
	if not widget.GetVariant or not widget.SetVariant then return end
	if widget:GetVariantCount()<2 then return end
	
	if 0==widget:GetVariant() then 	widget:SetVariant(1)
	else 							widget:SetVariant(0) end
end

function setCheckBox(widget, value)
	if not widget or not widget.SetVariant or not widget.GetVariantCount then return end
	if widget:GetVariantCount()<2 then return end
	if 		value 	then 	widget:SetVariant(1) return end
	widget:SetVariant(0)
end

function getCheckBoxState(widget)
	if not widget or not widget.GetVariant then return end
	return widget:GetVariant()==1 and true or false
end

function getModFromFlags(flags)
	local ctrl=flags>3
	if ctrl then flags=flags-4 end
	local alt=flags>1
	if alt then flags=flags-2 end
	local shift=flags>0
	return ctrl, alt, shift
end

--------------------------------------------------------------------------------
-- Timers functions
--------------------------------------------------------------------------------



local template=getChild(mainForm, "Template")

local timers={}
local m_loopEffects={}

function timer(params)
	if not params.effectType == ET_FADE then return end
	local timerForTick = nil
	for _, someTimer in pairs(timers) do
		if params.wtOwner:IsEqual(someTimer.widget) then
			timerForTick = someTimer
			break
		end
	end
	if not timerForTick then return end

	if not timerForTick.one then
		timerForTick.widget:PlayFadeEffect( 1.0, 1.0, timerForTick.speed*1000, EA_MONOTONOUS_INCREASE, true)
	end
	timerForTick.callback()
end

function startTimer(name, callback, speed, one)
	if name and timers[name] then destroy(timers[name].widget) end
	setTemplateWidget(template)
	local timerWidget=createWidget(mainForm, name, "Timer")
	if not timerWidget or not name or not callback then return nil end
	timers[name]={}
	timers[name].callback=callback
	timers[name].widget=timerWidget
	timers[name].one=one
	timers[name].speed=tonumber(speed) or 1

	common.RegisterEventHandler(timer, "EVENT_EFFECT_FINISHED")
    timerWidget:PlayFadeEffect(1.0, 1.0, timers[name].speed*1000, EA_MONOTONOUS_INCREASE, true)
	return true
end

function stopTimer(name)
    common.UnRegisterEventHandler( timer, "EVENT_EFFECT_FINISHED" )
end

function setTimeout(name, speed)
	if name and timers[name] and speed then
		timers[name].speed=tonumber(speed) or 1
	end
end

function destroyTimer(name)
	if timers[name] then destroy(timers[name].widget) end
	timers[name]=nil
end

function effectDone(aParams)
	if aParams.effectType ~= ET_FADE then 
		return 
	end

	local findedWdg = nil
	for _, v in pairs(m_loopEffects) do
		if v and equals(aParams.wtOwner, v.widget) then
			findedWdg = v
			break
		end
	end
	if not findedWdg then return end

	if findedWdg.widget then
		findedWdg.widget:PlayFadeEffect( 0.0, 1.0, findedWdg.speed*1000, EA_SYMMETRIC_FLASH, true)
	end
end

function startLoopBlink(aWdg, aSpeed)
	for i, v in pairs(m_loopEffects) do
		if v and equals(aWdg, v.widget) then
			v.speed = aSpeed
			return
		end
	end
	
	local obj = {}
	obj.widget = aWdg
	obj.speed = aSpeed
	table.insert(m_loopEffects, obj)
	
	aWdg:PlayFadeEffect( 0.0, 1.0, aSpeed*1000, EA_SYMMETRIC_FLASH, true)
end

function stopLoopBlink(aWdg)
	for i, v in pairs(m_loopEffects) do
		if v and equals(aWdg, v.widget) then
			table.remove(m_loopEffects, i)
			break
		end
	end
	
	aWdg:FinishFadeEffect()
end


--------------------------------------------------------------------------------
-- Locales functions
--------------------------------------------------------------------------------

local locale=nil

function setLocaleTextEx(widget, checked, color, align, fontSize, shadow, outline, fontName)
	if not locale then
		locale=getLocale()
	end
	local name=getName(widget)
	local text=name and locale[name]
	if not text then
		text = name
	end
	if text then
		if checked~=nil then
			text=formatText(text, align)
			setCheckBox(widget, checked)
		end
		setText(widget, text, color, align, fontSize, shadow, outline, fontName)
	end
end

function setLocaleText(widget, checked)
	setLocaleTextEx(widget, checked, "ColorWhite",  "left")
end

--------------------------------------------------------------------------------
-- Spell functions
--------------------------------------------------------------------------------

Global("TYPE_SPELL", 0)
Global("TYPE_ITEM", 1)
Global("TYPE_NOT_DEFINED", 2)
Global("NOT_FOUND", 100)

local cacheSpellId=nil

function getSpellIdFromName(aName) 
	if not aName then return nil end
	
	if not cacheSpellId then
		cacheSpellId = GetAVLWStrTree()
		local spellbook = avatar.GetSpellBook()
		if not spellbook then return nil end

		for _, spellId in pairs(spellbook) do
			local spellInfo = spellId and spellLib.GetDescription(spellId)
			if spellInfo then
				cacheSpellId:add({name = spellInfo.name, id = spellId})
			end
		end
	end
	
	local objToFind = {name = aName}
	local searchRes = cacheSpellId:find(objToFind)
	if searchRes ~= nil then
		if type(searchRes.id)=="userdata" then
			if spellLib.CanRunAvatarEx(searchRes.id) then return searchRes.id end
		else
			return nil
		end
	end
	
	return nil
end

local cacheItemId=nil

function getItemIdFromName(aName)
	if not aName then return nil end
	
	if not cacheItemId then
		cacheItemId = GetAVLWStrTree()
		local inventory = avatar.GetInventoryItemIds()
		if not inventory then return nil end

		for i, itemId in pairs(inventory) do
			local itemInfo = itemId and itemLib.GetItemInfo(itemId)
			if itemInfo then
				cacheItemId:add({name = itemInfo.name, id = itemId})
			end
		end
	end
	
	local objToFind = {name = aName}
	local searchRes = cacheItemId:find(objToFind)
	if searchRes ~= nil then
		if type(searchRes.id)=="number" then
			if itemLib.IsItem(searchRes.id) then return searchRes.id end
		else
			return nil
		end
	end

	return nil
end

function clearSpellCache()
	cacheSpellId=nil
end

function clearItemsCache()
	cacheItemId=nil
end


function isExist(targetId)
	if targetId then
		return cachedIsExist(targetId) and cachedIsUnit(targetId)
	end
	return false
end

function selectTarget(targetId)
	--lastTarget=avatar.GetTarget()
	if isExist(targetId) then
		avatar.SelectTarget(targetId)
	else
		avatar.UnselectTarget()
	end
end

function isEnemy(objectId)
	if not isExist(objectId) then return nil end
	local enemy=object.IsEnemy(objectId)
	return enemy
end

function isFriend(objectId)
	if not isExist(objectId) then return nil end
	local friend=object.IsFriend(objectId)
	return friend
end

function isRaid()
	return raid.IsExist()
end

function isGroup()
	return group.IsExist()
end

function isPvpZoneNow()
	if matchMaking.CanUseMatchMaking() and matchMaking.IsEventProgressExist() then
		local battleInfo = matchMaking.GetCurrentBattleInfo()
		if battleInfo and not battleInfo.isPvE  then
			return true
		end
	end
	return false
end

function cast(name, targetId)
	if isPvpZoneNow() then
		return false
	end
	
	local spellId=name and getSpellIdFromName(name)
	if not spellId then return nil end
	if not spellLib.CanRunAvatar(spellId) then
		return false
	end
	
	local duration=spellLib.GetProperties(spellId).launchWhenReady
	local properties=spellLib.GetProperties(spellId)
	local duration=properties.prepareDuration
	local state=spellLib.GetState(spellId)
	if not state.prepared and duration and duration > 1 then selectTarget(targetId) end

	if avatar.RunTargetSpell then
		local targetType=properties.targetType and properties.targetType==SPELL_TYPE_SELF
		if targetId and cachedIsExist(targetId) and not targetType then
			avatar.RunTargetSpell(spellId, targetId)
		else
			avatar.RunSpell(spellId)
		end
	else
		avatar.RunSpell(spellId)
	end
	return true
end

function useItem(name, targetId)
	if matchMaking.CanUseMatchMaking() and matchMaking.IsEventProgressExist() then
		local battleInfo = matchMaking.GetCurrentBattleInfo()
		if battleInfo and not battleInfo.isPvE  then
			return false
		end
	end
	local itemId=name and getItemIdFromName(name)
	if not itemId then return nil end

	if not avatar.CheckCanUseItem( itemId, false ) then
		return false
	end

	if targetId then
		selectTarget(targetId)
	end

	avatar.UseItem(itemId)
	return true
end

function testSpell(name, targetId)
	if not targetId then return nil end

	local spellId=name and getSpellIdFromName(name)
	return spellId and spellLib.CanRunAvatar(spellId)
end

function ressurect(targetId, ressurectName)
	local arrNames = {}
	for i = 1, 4 do
		local defaultName = getLocale()["defaultRessurectNames"..i]
		if defaultName then
			table.insert(arrNames, defaultName)
		end
	end
	for i, v in ipairs(arrNames) do
		local name=v
		if testSpell(name, targetId) then
			selectTarget(targetId)
			cast(name, targetId)
			return true
		end
	end
	return false
end

local cachedObjGetPos = object.GetPos
local cachedAvatarGetPos = avatar.GetPos
local cachedAvatarGetDir = avatar.GetDir

function getDistanceToTarget(targetId)
	local objPos = cachedObjGetPos(targetId)
	if not objPos then return nil end
	local avPos = cachedAvatarGetPos()
	local res = ((objPos.posX-avPos.posX)^2+(objPos.posY-avPos.posY)^2+(objPos.posZ-avPos.posZ)^2)^0.5
	res = math.ceil(res)

	return res
end

function getAngleToTarget(targetId)
	local objPos = cachedObjGetPos(targetId)
	if not objPos then return nil end
	local myPos = cachedAvatarGetPos()
	return math.floor(math.atan2(objPos.posY-myPos.posY, objPos.posX-myPos.posX)*100+0.5)/100 - cachedAvatarGetDir()
end


function getPersIdToId(pid)
	if not pid then return nil end
	if isRaid() then
		local members=raid.GetMembers()
		for i, g in pairs(members) do
			for j, m in pairs(g) do
				if m and m.id==pid then return m.uniqueId or m.persistentId end
			end
		end
	elseif isGroup() then
		local members=group.GetMembers()
		for i, m in pairs(members) do
			if m and m.id==pid then return m.uniqueId or m.persistentId end
		end
	elseif avatar.GetId and avatar.GetId()==pid then
		return avatar.GetUniqueId and avatar.GetUniqueId() or avatar.GetServerId and avatar.GetServerId()
	end
	return pid
end

function getNameToPersId(pid)
	if not pid or type(pid)~="userdata" then return nil end
	if isRaid() then
		local members=raid.GetMembers()
		for i, g in pairs(members) do
			for j, m in pairs(g) do
				if m and (m.uniqueId and m.uniqueId.IsEqual and m.uniqueId.IsEqual(pid, m.uniqueId) or m.persistentId==pid) then return m.name end
			end
		end
	elseif isGroup() then
		local members=group.GetMembers()
		for i, m in pairs(members) do
			if m and (m.uniqueId and m.uniqueId.IsEqual and m.uniqueId.IsEqual(pid, m.uniqueId) or m.persistentId==pid) then return toStringUtils(m.name) end
		end
	end
	local avatarUniqueId=avatar.GetUniqueId and avatar.GetUniqueId()
	return (avatarUniqueId and avatarUniqueId.IsEqual and avatarUniqueId.IsEqual(pid, avatarUniqueId) or avatar.GetServerId and avatar.GetServerId()==pid) and avatar.GetId and object.GetName and object.GetName(avatar.GetId()) or nil
end

function getGroupFromPersId(pid)
	if not pid or type(pid)~="userdata" then return nil end
	if isRaid() and pid then
		local members=raid.GetMembers()
		if not members then return 0 end
		local activeGroups=0
		for i=0, 3 do
			if members[i] then
				local activeGroup=false
				for j, m in pairs(members[i]) do
					if m and (m.uniqueId and m.uniqueId.IsEqual and m.uniqueId.IsEqual(pid, m.uniqueId) or m.persistentId==pid) then return activeGroups end
					activeGroup=true
				end
				if activeGroup then activeGroups=activeGroups+1 end
			end
		end
	end
	return nil
end

function getGroupSizeFromPersId(pid)
	if not pid or type(pid)~="userdata" then return nil end
	if isRaid() then
		local group=nil
		local members=raid.GetMembers()
		if not members then return nil end
		for i=0, 3 do
			if members[i] then
				for j, m in pairs(members[i]) do
					if m and (m.uniqueId and m.uniqueId.IsEqual and m.uniqueId.IsEqual(pid, m.uniqueId) or m.persistentId==pid) then group=i end
				end
			end
		end
		if not group then return nil end

		local size=0
		for j, m in pairs(members[group]) do
			size=size+1
		end
		return size
	end
	return nil
end

function getFirstEmptyPartyInRaid()
	if isRaid() then
		local members=raid.GetMembers()
		if not members then return nil end
		for i=0, 3 do
			local active=false
			if members[i] then
				for j, m in pairs(members[i]) do
					active=true
				end
			end
			if not active then return i end
		end
	end
	return nil
end



function getTimestamp()
	return common.GetMsFromDateTime( common.GetLocalDateTime() )
end

Global("g_cachedTimestamp", getTimestamp())

function updateCachedTimestamp()
	g_cachedTimestamp = getTimestamp()
end

function copyTable(t)
  local result = { }
  for k, v in pairs( t ) do
    result[k] = v
  end
  return result
end

local m_spellTextureCache = {}
function getSpellTextureFromCache(aSpellID)
	for _, spellTexInfo in pairs(m_spellTextureCache) do
		if spellTexInfo.spellID:IsEqual(aSpellID) then
			return spellTexInfo.texture
		end
	end
	local newSpellTexInfo = {}
	newSpellTexInfo.spellID = aSpellID
	newSpellTexInfo.texture = spellLib.GetIcon(aSpellID)
	table.insert(m_spellTextureCache, newSpellTexInfo)
	
	return newSpellTexInfo.texture
end


function LogToChat(aMessage)
	if not cachedIsWString(aMessage) then	aMessage = cachedToWString(aMessage) end
	userMods.SendSelfChatMessage(aMessage, "notice")
end