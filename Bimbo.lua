
local tip = BimboScanTip

local links = {}
local slots = {"BackSlot", "ChestSlot", "FeetSlot", "Finger0Slot", "Finger1Slot", "HandsSlot", "HeadSlot", "LegsSlot", "MainHandSlot", "NeckSlot", "RangedSlot", "SecondaryHandSlot", "ShoulderSlot", "Trinket0Slot", "Trinket1Slot", "WaistSlot", "WristSlot"}
local enchantables = {BackSlot = true, ChestSlot = true, FeetSlot = true, HandsSlot = true, HeadSlot = true, LegsSlot = true, MainHandSlot = true, ShoulderSlot = true, WristSlot = true}
local extrasockets = {WaistSlot = true}


local function GetSocketCount(link, slot, unit)
	local num, filled = 0, 0
	if slot then tip:SetInventoryItem(unit, GetInventorySlotInfo(slot)) else tip:SetHyperlink(link) end
	for i=1,10 do if tip.icon[i] then num = num + 1 end end

	local gem1, gem2, gem3, gem4 = link:match("item:%d+:%d+:(%d+):(%d+):(%d+):(%d+)")
	local filled = (gem1 ~= "0" and 1 or 0) + (gem2 ~= "0" and 1 or 0) + (gem3 ~= "0" and 1 or 0) + (gem4 ~= "0" and 1 or 0)

	return num, filled
end


local parentframes = {}
local meta = {
	__index = function(t,i)
		local slot = _G[parentframes[t]..i]
		local shine = LibStub("tekShiner").new(slot, 1, 0, 0)
		shine:SetAllPoints(slot)
		t[i] = shine
		return shine
	end
}
local playerGlows, inspectGlows = setmetatable({}, meta), setmetatable({}, meta)
parentframes[playerGlows], parentframes[inspectGlows] = "Character", "Inspect"

local function Check(unit, report)
	local glows = unit == "target" and inspectGlows or playerGlows
	local isplayer = unit == "player"

	for i in pairs(links) do links[i] = nil end
	for _,v in pairs(slots) do links[v] = GetInventoryItemLink(unit, GetInventorySlotInfo(v)) end
	for _,f in pairs(glows) do f:Hide() end

	enchantables.Finger0Slot = isplayer and GetSpellInfo((GetSpellInfo(7411))) -- Only check rings if the player is an enchanter
	enchantables.Finger1Slot = enchantables.Finger0Slot

	-- Only check waist enchant if the player is an engineer
	-- Not checking for now, since these enchants don't really have much benefit
--~ 	enchantables.WaistSlot = isplayer and GetSpellInfo((GetSpellInfo(4036)))

	if links.RangedSlot then
		local _, _, _, _, _, _, rangetype, _, slottype = GetItemInfo(links.RangedSlot)
		enchantables.RangedSlot = slottype ~= "INVTYPE_RELIC" and rangetype ~= "Wands" and rangetype ~= "Thrown" -- Can't enchant wands or thrown weapons
	end
	enchantables.SecondaryHandSlot = links.SecondaryHandSlot and select(9, GetItemInfo(links.SecondaryHandSlot)) ~= "INVTYPE_HOLDABLE" -- nor off-hand frills

	extrasockets.HandsSlot = isplayer and GetSpellInfo((GetSpellInfo(2018))) -- Make sure smithies are adding sockets
	extrasockets.WristSlot = extrasockets.HandsSlot

	local found = false
	for slot,check in pairs(enchantables) do
		local link = check and links[slot]
		if link and link:match("item:%d+:0") then
			found = true
			glows[slot]:Show()
			if report then print(link, "doesn't have an enchant") end
		end
	end

	for slot,check in pairs(extrasockets) do
		local link = check and links[slot]
		if link then
			local id = link:match("item:(%d+)")
			local _, link2 = GetItemInfo(id)
			local rawnum = GetSocketCount(link2, nil, unit)
			local num = GetSocketCount(link, slot, unit)
			if rawnum == num then
				found = true
				glows[slot]:Show()
				if report then print(link2, "doesn't have an extra socket") end
			end
		end
	end

	for slot,link in pairs(links) do
		local num, filled = GetSocketCount(link, slot, unit)
		if filled < num then
			found = true
			glows[slot]:Show()
			if report then print(link, "has empty sockets") end
		end
	end

	if not found and report then print("All equipped items are enchanted and gemmed") end
end



local butt = LibStub("tekKonfig-Button").new_small(PaperDollFrame, "BOTTOMLEFT", 25, 86)
butt:SetWidth(45) butt:SetHeight(18)
butt:SetText("Bimbo")
butt:SetScript("OnEvent", function(self, event, ...) self[event](self, event, ...) end)
butt:SetScript("OnShow", function() Check("player") end)
butt:SetScript("OnClick", function() Check("player", true) end)
butt:SetScript("OnLeave", function() GameTooltip:Hide() end)
butt:SetScript("OnEnter", function(self)
	GameTooltip:SetOwner(self, "ANCHOR_NONE")
	GameTooltip:SetPoint("TOPLEFT", self, "BOTTOMLEFT")
	GameTooltip:ClearLines()
	GameTooltip:SetText("Click to print missing gems and enchants.")
	GameTooltip:Show()
end)


function butt:UNIT_INVENTORY_CHANGED(event, unit)
	if unit == "player" and self:IsVisible() then Check("player") end
end
butt:RegisterEvent("UNIT_INVENTORY_CHANGED")


function butt:PLAYER_TARGET_CHANGED()
	if InspectFrame and InspectFrame:IsVisible() then Check("target") end
end


function butt:ADDON_LOADED(event, addon)
	if addon ~= "Blizzard_InspectUI" then return end

	local butt2 = LibStub("tekKonfig-Button").new_small(InspectFrame, "BOTTOMLEFT", 25, 86)
	butt2:SetText("Bimbo")
	butt2:SetWidth(45) butt2:SetHeight(18)
	butt2:SetScript("OnShow", butt.PLAYER_TARGET_CHANGED)
	butt2:SetScript("OnClick", function() Check("target", true) end)
	butt2:SetScript("OnEnter", butt:GetScript("OnEnter"))
	butt2:SetScript("OnLeave", butt:GetScript("OnLeave"))

	self:RegisterEvent("PLAYER_TARGET_CHANGED")
	self:UnregisterEvent("ADDON_LOADED")
	self.ADDON_LOADED = nil
end
butt:RegisterEvent("ADDON_LOADED")


if IsLoggedIn() and butt:IsVisible() then Check("player") end
if IsAddOnLoaded("Blizzard_InspectUI") and butt.ADDON_LOADED then butt:ADDON_LOADED("ADDON_LOADED", "Blizzard_InspectUI") end
