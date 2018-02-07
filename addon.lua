local myname, ns = ...

local inv = LibStub("AceAddon-3.0"):GetAddon("Inventorian")
local original_WrapItemButton = inv.Item.WrapItemButton
inv.Item.WrapItemButton = function(...)
	local item = original_WrapItemButton(...)

	item.ItemLevel = item:CreateFontString('$parentItemLevel', 'ARTWORK')
	item.ItemLevel:SetPoint('TOPRIGHT', -2, -2)
	item.ItemLevel:SetFontObject(NumberFontNormal)
	item.ItemLevel:SetJustifyH('RIGHT')

	return item
end

local original_Update = inv.Item.prototype.Update
inv.Item.prototype.Update = function(self, ...)
	if self:IsVisible() then
		local icon, count, locked, quality, readable, lootable, link, noValue, itemID = self:GetInfo()
		self.ItemLevel:Hide()
		if itemID and link then
			local _, _, _, _, _, itemClass, itemSubClass = GetItemInfoInstant(itemID)
			if
				quality >= LE_ITEM_QUALITY_UNCOMMON and (
					itemClass == LE_ITEM_CLASS_WEAPON or
					itemClass == LE_ITEM_CLASS_ARMOR or
					(itemClass == LE_ITEM_CLASS_GEM and itemSubClass == LE_ITEM_GEM_ARTIFACTRELIC)
				)
			then
				local r, g, b, hex = GetItemQualityColor(quality)
				-- This used to work, but timewalking / post-7.3.5 quest items have a different effective level:
				-- local itemLevel = select(4, GetItemInfo(link))
				-- local itemLevel = IUI:GetUpgradedItemLevel(link)
				local itemLevel = ns.ActualItemLevel(self.bag, self.slot)
				self.ItemLevel:SetFormattedText('|c%s%s|r', hex, itemLevel or '?')
				self.ItemLevel:Show()
			end
		end
	end

	return original_Update(self, ...)
end

do
	local scanningTooltip, anchor
	local itemLevelPattern = _G.ITEM_LEVEL:gsub("%%d", "(%%d+)")
	local cache = {}

	ns.ActualItemLevel = function(itemLink, bagSlot)
		local bagId
		if not itemLink then return end
		if bagSlot then
			bagId = itemLink
			itemLink = select(7, GetContainerItemInfo(bagId, bagSlot))
		end
		if not cache[itemLink] then
			if type(itemLink) == "number" then
				cache[itemLink] = (select(4, GetItemInfo(itemLink)))
			else
				if not scanningTooltip then
					anchor = CreateFrame("Frame")
					anchor:Hide()
					scanningTooltip = _G.CreateFrame("GameTooltip", myname .. "ScanTooltip", nil, "GameTooltipTemplate")
				end
				GameTooltip_SetDefaultAnchor(scanningTooltip, anchor)
				local status, err
				if bagId then
					if bagId == BANK_CONTAINER or bagId == REAGENTBANK_CONTAINER then
						local id
						if bagId == BANK_CONTAINER then
							id = BankButtonIDToInvSlotID(bagSlot)
						else
							id = ReagentBankButtonIDToInvSlotID(bagSlot)
						end
						status, err = pcall(scanningTooltip.SetInventoryItem, scanningTooltip, "player", id)
					else
						status, err = pcall(scanningTooltip.SetBagItem, scanningTooltip, bagId, bagSlot)
					end
				else
					status, err = pcall(scanningTooltip.SetHyperlink, scanningTooltip, itemLink)
				end
				if not status then return end
				for i = 2, 5 do
					local left = _G[myname .. "ScanTooltipTextLeft" .. i]
					if left then
						local text = left:GetText()
						if text then
							local level = tonumber(text:match(itemLevelPattern))
							if level then
								cache[itemLink] = level
								break
							end
						end
					end
				end
				scanningTooltip:Hide()
			end
		end
		return cache[itemLink]
	end
end
