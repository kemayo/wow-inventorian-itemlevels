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
			local item = Item:CreateFromBagAndSlot(self.bag, self.slot)
			item:ContinueOnItemLoad(function()
				local _, _, _, _, _, itemClass, itemSubClass = GetItemInfoInstant(itemID)
				if
					quality >= LE_ITEM_QUALITY_UNCOMMON and (
						itemClass == LE_ITEM_CLASS_WEAPON or
						itemClass == LE_ITEM_CLASS_ARMOR or
						(itemClass == LE_ITEM_CLASS_GEM and itemSubClass == LE_ITEM_GEM_ARTIFACTRELIC)
					)
				then
					local r, g, b, hex = GetItemQualityColor(quality)
					self.ItemLevel:SetFormattedText('|c%s%s|r', hex, item:GetCurrentItemLevel() or '?')
					self.ItemLevel:Show()
				end
			end)
		end
	end

	return original_Update(self, ...)
end
