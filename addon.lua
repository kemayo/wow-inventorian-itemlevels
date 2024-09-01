local myname, ns = ...

local LAI = LibStub("LibAppropriateItems-1.0")

local inv = LibStub("AceAddon-3.0", true):GetAddon("Inventorian")

hooksecurefunc(inv.Item, "WrapItemButton", function(self, itemButton)
	local overlayFrame = CreateFrame("FRAME", nil, itemButton)
	overlayFrame:SetFrameLevel(4) -- Azerite overlay must be overlaid itself...
	overlayFrame:SetAllPoints()

	itemButton.ItemLevel = overlayFrame:CreateFontString('$parentItemLevel', 'ARTWORK')
	itemButton.ItemLevel:SetPoint('TOPRIGHT', -2, -2)
	itemButton.ItemLevel:SetFontObject(NumberFontNormal)
	itemButton.ItemLevel:SetJustifyH('RIGHT')

	itemButton.ItemLevelUpgrade = overlayFrame:CreateTexture(nil, "OVERLAY")
	itemButton.ItemLevelUpgrade:SetSize(8, 8)
	itemButton.ItemLevelUpgrade:SetPoint('TOPLEFT', 2, -2)
	-- MiniMap-PositionArrowUp?
	itemButton.ItemLevelUpgrade:SetAtlas("poi-door-arrow-up")
end)

local function ToIndex(bag, slot) -- copied from inside Inventorian
	return (bag < 0 and bag * 100 - slot) or (bag * 100 + slot)
end
local function invContainerUpdateSlot(self, bag, slot)
	local button = self.items[ToIndex(bag, slot)]
	if not button then return end
	if not button:IsVisible() then return end
	local item
	local icon, count, locked, quality, readable, lootable, link, noValue, itemID, isBound = button:GetInfo()
	if button:IsCached() then
		if link then
			item = Item:CreateFromItemLink(link)
		elseif itemID then
			item = Item:CreateFromItemID(itemID)
		end
	else
		item = Item:CreateFromBagAndSlot(bag, slot)
	end
	button.ItemLevel:Hide()
	button.ItemLevelUpgrade:Hide()
	if item:IsItemEmpty() then return end
	item:ContinueOnItemLoad(function()
		local itemInfo = item:GetItemLink() or item:GetItemID()
		local _, _, _, equipLoc, _, itemClass, itemSubClass = GetItemInfoInstant(itemInfo)
		if
			-- Mainline has Uncommon, Classic has Good
			quality >= (Enum.ItemQuality.Uncommon or Enum.ItemQuality.Good) and (
				itemClass == Enum.ItemClass.Weapon or
				itemClass == Enum.ItemClass.Armor or
				(itemClass == Enum.ItemClass.Gem and itemSubClass == Enum.ItemGemSubclass.Artifactrelic)
			)
		then
			local itemLevel = item:GetCurrentItemLevel()
			local r, g, b, hex = GetItemQualityColor(quality)
			button.ItemLevel:SetFormattedText('|c%s%s|r', hex, itemLevel or '?')
			button.ItemLevel:Show()
			if LAI:IsAppropriate(itemID) then
				ns.ForEquippedItems(equipLoc, function(equippedItem)
					if equippedItem:IsItemEmpty() or equippedItem:GetCurrentItemLevel() < itemLevel then
						button.ItemLevelUpgrade:Show()
					end
				end)
			end
		end
	end)
end
local function hookInventorian()
	hooksecurefunc(inv.bag.itemContainer, "UpdateSlot", invContainerUpdateSlot)
	hooksecurefunc(inv.bank.itemContainer, "UpdateSlot", invContainerUpdateSlot)
end
if inv.bag then
	hookInventorian()
else
	hooksecurefunc(inv, "OnEnable", function()
		hookInventorian()
	end)
end

do
	local EquipLocToSlot1 = {
		INVTYPE_HEAD = 1,
		INVTYPE_NECK = 2,
		INVTYPE_SHOULDER = 3,
		INVTYPE_BODY = 4,
		INVTYPE_CHEST = 5,
		INVTYPE_ROBE = 5,
		INVTYPE_WAIST = 6,
		INVTYPE_LEGS = 7,
		INVTYPE_FEET = 8,
		INVTYPE_WRIST = 9,
		INVTYPE_HAND = 10,
		INVTYPE_FINGER = 11,
		INVTYPE_TRINKET = 13,
		INVTYPE_CLOAK = 15,
		INVTYPE_WEAPON = 16,
		INVTYPE_SHIELD = 17,
		INVTYPE_2HWEAPON = 16,
		INVTYPE_WEAPONMAINHAND = 16,
		INVTYPE_RANGED = 16,
		INVTYPE_RANGEDRIGHT = 16,
		INVTYPE_WEAPONOFFHAND = 17,
		INVTYPE_HOLDABLE = 17,
		INVTYPE_TABARD = 19,
	}
	local EquipLocToSlot2 = {
		INVTYPE_FINGER = 12,
		INVTYPE_TRINKET = 14,
		INVTYPE_WEAPON = 17,
	}
	local ForEquippedItem = function(slot, callback)
		if not slot then
			return
		end
		local item = Item:CreateFromEquipmentSlot(slot)
		if item:IsItemEmpty() then
			return callback(item)
		end
		item:ContinueOnItemLoad(function() callback(item) end)
	end
	ns.ForEquippedItems = function(equipLoc, callback)
		ForEquippedItem(EquipLocToSlot1[equipLoc], callback)
		ForEquippedItem(EquipLocToSlot2[equipLoc], callback)
	end
end
