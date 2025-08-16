if (ZOMGPortalz) then
	ZOMGBuffs:Print("Installation error, duplicate copy of ZOMGBuffs_Portalz (Addons\ZOMGBuffs\ZOMGBuffs_Portalz and Addons\ZOMGBuffs_Portalz)")
	return
end

--local ANIM = true	-- Swirly testing changes
local L = LibStub("AceLocale-2.2"):new("ZOMGPortalz")
local R = LibStub("AceLocale-2.2"):new("ZOMGReagents")
local SM = LibStub("LibSharedMedia-3.0")
local playerClass

local cos, sin = cos, sin

BINDING_HEADER_ZOMGBUFFS_PORTALZ	= L["ZOMGBUFFS_PORTALZ"]
BINDING_NAME_ZOMGBUFFS_PORTAL_KEY	= L["ZOMGBUFFS_PORTAL_KEY"]

local z = ZOMGBuffs
local module = z:NewModule("ZOMGPortalz")
local portalBinding
ZOMGPortalz = module

z:CheckVersion("$Revision: 143 $")

local new, del, deepDel, copy = z.new, z.del, z.deepDel, z.copy
local InCombatLockdown	= InCombatLockdown
local IsUsableSpell		= IsUsableSpell
local GetSpellCooldown	= GetSpellCooldown
local GetSpellInfo		= GetSpellInfo
local UnitBuff			= UnitBuff
local UnitCanAssist		= UnitCanAssist
local UnitClass			= UnitClass
local UnitIsConnected	= UnitIsConnected
local UnitInParty		= UnitInParty
local UnitIsPVP			= UnitIsPVP
local UnitInRaid		= UnitInRaid
local UnitIsUnit		= UnitIsUnit
local UnitPowerType		= UnitPowerType

local function getOption(k)
	return module.db.char[k]
end
local function setOption(k, v)
	module.db.char[k] = v
end

do
	module.consoleCmd = "ZOMGPortalz"
	module.options = {
		type = 'group',
		order = 15,
		name = "|cFFFF8080Z|cFFFFFF80O|cFF80FF80M|cFF8080FFG|rPortalz",
		desc = L["Portal Configuration"],
		handler = module,
		disabled = function() return z:IsDisabled() end,
		args = {
			showall = {
				type = 'toggle',
				name = L["Show All"],
				desc = L["Show all portal spells, even if you have not learnt them yet."],
				get = function() return module.db.char.showall end,
				set = function(n) module.db.char.showall = n end,
				order = 1,
			},
			items = {
				type = 'toggle',
				name = L["Items"],
				desc = format(L["Include appropriate items as castable portals (eg: %s or %s)"], select(2,GetItemInfo(6948)) or "Hearthstone", select(2,GetItemInfo(32757)) or "Blessed Medallion of Karobor"),
				get = function() return module.db.char.useitems end,
				set = function(n) module.db.char.useitems = n end,
				order = 3,
			},
			anchor = {
				type = 'toggle',
				name = L["Locked"],
				desc = L["Unlocked, the portals can be dragged using the |cFF00FF00Right Mouse Button|r"],
				get = function() return module.db.char.locked end,
				set = function(n) module.db.char.locked = n end,
				order = 5,
			},
			pattern = {
				type = 'text',
				name = L["Pattern"],
				desc = L["Select the arrangement layout for the portals"],
				validate = {circle = L["Circle"], horz = L["Horizontal"], vert = L["Vertical"], arc = L["Arc"]},
				get = function() return module.db.char.pattern end,
				set = function(n) module.db.char.pattern = n module:SetPoints() module:Draw() end,
				order = 10,
			},
			scale = {
				type = 'range',
				name = L["Scale"],
				desc = L["Adjust the scale of the portals"],
				func = timeFunc,
				get = function() return module.db.char.scale end,
				set = function(n)
					module.db.char.scale = n
					if (module.frame) then
						module.frame:SetScale(n)
						module.frame.text:SetText(L["Portal Spell"])
						module.frame.reagents:SetText(L["Reagent information"])
					end
				end,
				min = 0.2,
				max = 2,
				isPercent = true,
				step = 0.01,
				bigStep = 0.05,
				order = 20,
			},
			spacer = {
				type = 'header',
				name = " ",
				order = 99,
			},
			keybinding = {
				type = 'text',
				name = L["Key-Binding"],
				desc = L["Define the key used for portal popup"],
				validate = "keybinding",
				get = function()
					return GetBindingKey("ZOMGBUFFS_PORTAL")
				end,
				set = function(n)
					local old = GetBindingAction(n)
					if (old and old ~= "") then
						module:Print(KEY_UNBOUND_ERROR, old)
					end

					SetBinding(n, "ZOMGBUFFS_PORTAL")
					SaveBindings(GetCurrentBindingSet())
				end,
				order = 100,
			},
			sticky = {
				type = 'toggle',
				name = L["Sticky"],
				desc = L["When sticky, the portals open on one keypress and close on another. When disabled, you are required to hold the key whilst making your selection."],
				get = function() return module.db.char.sticky end,
				set = function(n) module.db.char.sticky = n end,
				order = 120,
			},
			announce = {
				type = 'toggle',
				name = L["Announce"],
				desc = L["Announce when you've created a portal to someplace more fun and sunny than this dark damp dungeon."],
				get = function() return module.db.char.announce end,
				set = function(n) module.db.char.announce = n end,
				hidden = function() return select(2,UnitClass("player")) ~= "MAGE" end,
				order = 130,
			}
		},
	}
end

-- InitFrames
function module:InitFrames()
	local frame = CreateFrame("Frame", "ZOMGPortalzAnchor", UIParent)
	self.frame = frame
	frame:SetHeight(1)
	frame:SetWidth(1)
	frame:SetMovable(true)

	if (self.db.char.anchorPoint) then
		self.db.char.anchorPoint[2] = "UIParent"
		frame:SetPoint(unpack(self.db.char.anchorPoint))
	else
		frame:SetPoint("CENTER", 0, 155)
	end

	frame:SetScript("OnShow", function(self)
		module:RegisterEvent("PLAYER_REGEN_DISABLED")
		module:RegisterEvent("UNIT_SPELLCAST_SENT")
		module:RegisterEvent("SPELL_UPDATE_COOLDOWN")
		module:RegisterEvent("UNIT_INVENTORY_CHANGED")
	end)
	frame:SetScript("OnHide", function(self)
		if (module:IsEventRegistered("UNIT_SPELLCAST_SENT")) then
			module:UnregisterEvent("PLAYER_REGEN_DISABLED")
			module:UnregisterEvent("UNIT_SPELLCAST_SENT")
			module:UnregisterEvent("SPELL_UPDATE_COOLDOWN")
			module:UnregisterEvent("UNIT_INVENTORY_CHANGED")
		end
	end)

	frame:SetScript("OnUpdate",
		function(self, elapsed)
			if (module.mode) then
				module.mode(module, elapsed)
			end
		end)

	frame.text = frame:CreateFontString(nil, "OVERLAY", "ZoneTextFont")
	frame.reagents = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	frame.warning = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	frame.text:SetTextColor(1, 0.9294, 0.7607)
	frame.reagents:SetTextColor(0.85, 0.85, 0.85)
	frame.warning:SetTextColor(1, 0, 0)

	self:SetScale()

	frame:Hide()
end

-- Keybinding
function module:Keybinding(keystate)
	if (InCombatLockdown() or z:IsDisabled()) then
		return
	end

	if (self.db.char.sticky) then
		if (keystate == "down") then
			if (module.mode == module.OnUpdateOpening or module.mode == module.OnUpdate) then
				module.mode = module.OnUpdateClosing
			else
				module.mode = module.OnUpdateOpening
				self.frame:Show()
			end
		end
	else
		if (keystate == "down") then
			module.mode = module.OnUpdateOpening
			self.frame:Show()
		else
			module.mode = module.OnUpdateClosing
		end
	end
end

do
	local function buttonOnEnter(self)
		module:OnEnterButton(self)
	end
	local function buttonOnLeave(self)
		module:OnLeaveButton(self)
	end
	local function buttonOnDragStart(self)
		if (not module.db.char.locked) then
			module.frame:StartMoving()
		end
	end
	local function buttonOnDragStop(self)
		module.frame:StopMovingOrSizing()
		module.db.char.anchorPoint = {module.frame:GetPoint(1)}
		module.db.char.anchorPoint[2] = "UIParent"
	end

	-- CreateButton
	function module:CreateButton(city, single, spell, texture, spellIDSingle)
		local itemID, itemName
		if (type(city) == "number") then
			itemID = city
			itemName = GetItemInfo(itemID)
			texture = select(10, GetItemInfo(itemID))
			city, spell, single = nil, nil, nil
			buttonName = "ZOMGPortalszButton"..itemID.."_"..itemName
		else
			buttonName = "ZOMGPortalszButton"..city..(single and "Single" or "Group")
		end

		local b = CreateFrame("Frame", buttonName, self.frame)
		b:SetWidth(1)
		b:SetHeight(1)

		local d = CreateFrame("Button", nil, b, "SecureActionButtonTemplate")
		b.drawFrame = d
		d:SetFrameLevel(self.frame:GetFrameLevel() - 1)
		d:SetPoint("CENTER")
		d:SetWidth(self.sizeX)
		d:SetHeight(self.sizeY)

		if (city) then
			b.single = single
			b.group = not single
			d.single = single
			d.group = not single
		end

		b.tex = b.drawFrame:CreateTexture(nil, "BACKGROUND")
		b.tex:SetTexture(texture)
		b.tex:SetAllPoints()
		b.texture = texture

		b.cooldown = d:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		b.cooldown:SetAllPoints()
		b.cooldown:Hide()

		if (spell) then
			d:SetAttribute("*type1", "spell")
			d:SetAttribute("spell", spell)
			d.spellIDSingle = spellIDSingle
			b.spellIDSingle = spellIDSingle
			d.spell = spell
			b.spell = spell
			b.tex:SetBlendMode(self.spellBlend)
			if (self.spellTrim) then
				b.tex:SetTexCoord(0.06, 0.94, 0.09, 0.91)
			end
		else
			d:SetAttribute("*type1", "item")
			d:SetAttribute("item", itemName)
			d.item = itemID
			b.item = itemID
			b.tex:SetTexCoord(0.06, 0.94, 0.09, 0.91)
			b.tex:SetBlendMode(self.itemBlend)
		end

		d.highlight1 = b.drawFrame:CreateTexture(nil, "OVERLAY")
		d.highlight1:SetBlendMode("ADD")
		d.highlight1:SetAllPoints()
		d.highlight1.angleMod = -2
		d.highlight2 = b.drawFrame:CreateTexture(nil, "OVERLAY")
		d.highlight2:SetBlendMode("ADD")
		d.highlight2:SetAllPoints()
		d.highlight2.angleMod = -2.4
		d.highlight3 = b.drawFrame:CreateTexture(nil, "OVERLAY")
		d.highlight3:SetBlendMode("ADD")
		d.highlight3:SetAllPoints()
		d.highlight3:SetTexture("World\\GENERIC\\ACTIVEDOODADS\\SpellPortals\\Flare")
		d.highlight3:Hide()
		d.highlight3.angleMod = 3.33

		if (ANIM) then
			d.highlight1:SetTexture("SPELLS\\SHOCKWAVE10D")
			d.highlight2:SetTexture("SPELLS\\SHOCKWAVE10")
			d.highlight1.anim = self:CreatePortalAnimation(d.highlight1, 40)
			d.highlight2.anim = self:CreatePortalAnimation(d.highlight2, 35)
			d.highlight3.anim = self:CreatePortalAnimation(d.highlight3, 20)
		end

		d:SetScript("OnEnter", buttonOnEnter)
		d:SetScript("OnLeave", buttonOnLeave)
		d:SetScript("OnDragStart", buttonOnDragStart)
		d:SetScript("OnDragStop", buttonOnDragStop)
		d:RegisterForDrag("RightButton")

		return b
	end
end

if (ANIM) then
-- CreatePortalAnimation
function module:CreatePortalAnimation(frame, duration)
	local a = frame:CreateAnimationGroup()
	a:SetLooping("REPEAT")

	local r = a:CreateAnimation("Rotation")
	a.rotate = r
	r:SetDuration(duration)
	r:SetDegrees(-360)
	r:SetOrder(1)

	local alpha1 = a:CreateAnimation("Alpha")
	a.alpha1 = alpha1
	alpha1:SetChange(-0.8)
	alpha1:SetDuration(duration / 10)
	alpha1:SetOrder(1)

	local alpha2 = a:CreateAnimation("Alpha")
	a.alpha2 = alpha
	alpha2:SetChange(0.8)
	alpha2:SetDuration(duration / 10)
	alpha2:SetOrder(2)

	return a
end

end

-- IsItemEquiped
local function IsItemEquiped(item)
	for i = 1,18 do
		local link = GetInventoryItemLink("player", i)
		if (link) then
			local id = strmatch(link, "|Hitem:(%d+):")
			if (tonumber(id) == item) then
				return true
			end
		end
	end
end

local cycle = {
	"SPELLS\\SHOCKWAVE10",
	"SPELLS\\Shockwave10a",
	"SPELLS\\SHOCKWAVE10B",
	"SPELLS\\SHOCKWAVE10D",
}

local buttonOnUpdate
if (not ANIM) then

local function rotate(angle)
	local zpftA = 0.5 * cos(angle)
	local mzpftA = -zpftA
	local zpftB = 0.5 * sin(angle)
	local mzpftB = -zpftB
	local ULx, ULy = mzpftA - mzpftB, mzpftB + mzpftA
	local LLx, LLy = mzpftA - zpftB, mzpftB + zpftA
	local URx, URy = zpftA - mzpftB, zpftB + mzpftA
	local LRx, LRy = zpftA - zpftB, zpftB + zpftA
	return ULx+0.5, ULy+0.5, LLx+0.5, LLy+0.5, URx+0.5, URy+0.5, LRx+0.5, LRy+0.5
end

-- buttonOnUpdateHighlight
local function buttonOnUpdateHighlight(self, elapsed)
	if (self.dir == 0) then
		self:SetTexture(cycle[self.phase])
		self.dir = 1
	end

	if (self.dir == 1) then
		self.alpha = self.alpha + elapsed
		if (self.alpha > 1) then
			self.alpha = 1
			self.dir = -1
		end
	else
		self.alpha = self.alpha - elapsed
		if (self.alpha <= 0) then
			self.alpha = 0
			self.dir = 1

			if (self.phase ~= -1) then
				self.phase = self.phase + 1
				if (self.phase > #cycle) then
					self.phase = 1
				end
				self:SetTexture(cycle[self.phase])
			end
		end
	end
	
	self.angle = (self.angle or 0) + (elapsed * self.angleMod)
	if (self.angle >= 360) then
		self.angle = self.angle - 360
	end

	local ULx, ULy, LLx, LLy, URx, URy, LRx, LRy = rotate(self.angle)
	self:SetTexCoord(ULx, ULy, LLx, LLy, URx, URy, LRx, LRy)

	self:SetVertexColor(self.alpha, self.alpha, self.alpha)
end

-- buttonOnUpdate
function buttonOnUpdate(self, elapsed)
	buttonOnUpdateHighlight(self.highlight1, elapsed)
	buttonOnUpdateHighlight(self.highlight2, elapsed)
	buttonOnUpdateHighlight(self.highlight3, elapsed)

	if (self.equiped) then
		if (not self.item or IsItemEquiped(self.item)) then
			module.frame.warning:SetText("")
		end
	end
end
end

-- ShowBindLocation
function module:ShowBindLocation(on)
	if (on) then
		self.frame.reagents:SetText(GetBindLocation())
		self.frame.reagents:Show()
	else
		self.frame.reagents:Hide()
	end
end

-- OnEnterButton
local hearthStoneItems = {[6948] = true, [28585] = true, [44315] = true, [44314] = true, [37118] = true}
function module:OnEnterButton(button)
	if (ANIM) then
		if (not button.highlight1:IsShown()) then
			button.highlight1:Show()
			button.highlight2:Show()
			button.highlight3:Show()
			button.highlight1.anim:Play()
			button.highlight2.anim:Play()
			button.highlight3.anim:Play()
		end
	else
		button.highlight1.phase = 1
		button.highlight1.alpha = 0
		button.highlight1.dir = 0
		button.highlight2.phase = 2
		button.highlight2.alpha = 0.5
		button.highlight2.dir = 0
		button.highlight3.dir = 1
		button.highlight3.phase = -1
		button.highlight3.alpha = 0.3
		button.highlight3:Show()
		button:SetScript("OnUpdate", buttonOnUpdate)
	end

	local spell = button:GetAttribute("spell")
	local item = button:GetAttribute("item")

	self.frame.text:SetText(spell or item)

	if (spell) then
		local r = button.single and self.singleReagent or self.groupReagent
		if (r) then
			local count = GetItemCount(r)
			local colourCount
			if (count < 2) then
				colourCount = "|cFFFF4040"
			elseif (count < 5) then
				colourCount = "|cFFFFFF40"
			else
				colourCount = "|cFF40FF40"
			end
			self.frame.reagents:SetFormattedText("Reagents: %s%d|r %s", colourCount, count, GetItemInfo(r))
			self.frame.reagents:Show()
		else
			self:ShowBindLocation(button.spellIDSingle == 556)
		end

		self:CheckForWarning(button)
	else
		self:ShowBindLocation(hearthStoneItems[button.item])

		self.frame.warning:SetText("")
		if (button.equiped) then
			if (not IsItemEquiped(button.item)) then
				self.frame.warning:SetText(L["Click to equip. Click again when cooldown is up"])
			end
		end
	end
end

-- OnEnterButton
function module:OnLeaveButton(button)
	if (ANIM) then
		if (button.highlight1:IsShown()) then
			button.highlight1:Hide()
			button.highlight2:Hide()
			button.highlight3:Hide()
		end
	else
		button:SetScript("OnUpdate", nil)
		button.highlight1:SetTexture(nil)
		button.highlight2:SetTexture(nil)
		button.highlight3:Hide()
	end

	self.frame.text:SetText("")
	self.frame.reagents:SetText("")
	self.frame.warning:SetText("")
end

-- CheckForWarning
function module:CheckForWarning(button)
	local any
	if (button.single) then
		if (GetNumPartyMembers() > 0 or GetNumRaidMembers() > 0) then
			for unit,unitname in z:IterateRoster() do
				if (not UnitIsUnit("player", unit) and UnitIsConnected(unit) and UnitIsVisible(unit)) then
					any = true
				end
			end
		end
	end

	if (any) then
		self.frame.warning:SetText(L["Are you sure you're not leaving your friends behind?!"])
	else
		self.frame.warning:SetText("")
	end
end

-- getSpellCooldown
local function getSpellCooldown(self)
	if (self.spell) then
		return GetSpellCooldown(self.spell)
	end
end

-- CreatePortal
function module:CreatePortal(info, single, city)
	local spell = single and info.single or info.group
	local show

	if (not single and GetNumRaidMembers() == 0 and GetNumPartyMembers() == 0) then
		show = nil
	else
		show = self.db.char.showall or GetSpellInfo(spell)
	end

	local button = single and info.singleButton or info.groupButton
	if (not button) then
		if (show) then
			button = self:CreateButton(city, single, spell, info.tex, info.spellIDSingle)
			button.GetCooldown = getSpellCooldown

			self:UpdateCooldown(button)
			if (single) then
				info.singleButton = button
			else
				info.groupButton = button
			end
		end
	else
		if (show) then
			button:Show()
			self:UpdateCooldown(button)
		else
			button:Hide()
		end
	end
end

-- CreatePortals
function module:CreatePortals()
	for city,info in pairs(self.portals) do
		self:CreatePortal(info, true, city)
		if (info.group) then
			self:CreatePortal(info, false, city)
		end
	end
end

-- getItemCooldown
local function getItemCooldown(self)
	if (self.item) then
		if (self.equiped) then
			if (not IsItemEquiped(self.item)) then
				if (GetTime() - GetItemCooldown(self.item) < 60) then
					return 0, 0, 1		-- Not equiped, and cooldown is up soon anyway
				end
			end
		end

		return GetItemCooldown(self.item)
	end
end

-- CreatePortal
function module:CreateItemButton(item, equiped)
	local name = GetItemInfo(item)
	if (not name) then
		return
	end

	local show = GetItemCount(item) > 0
	local info = self.itemButtons and self.itemButtons[name]
	local button = info and info.singleButton

	if (not button) then
		if (show) then
			button = self:CreateButton(item)
			button.GetCooldown = getItemCooldown
			button.equiped = equiped
			button.drawFrame.equiped = equiped
			button.tex:SetVertexColor(1, 1, 1, 0.5)

			self:UpdateCooldown(button)
			if (not self.itemButtons) then
				self.itemButtons = new()
			end
			self.itemButtons[name] = {
				singleButton = button,
				tex = button.texture,
			}
		end
	else
		if (show) then
			button:Show()
			self:UpdateCooldown(button)
		else
			button:Hide()
		end
	end
end

-- CreateItemButtons
function module:CreateItemButtons()
	if (self.db.char.useitems) then
		if (GetItemCount(6948) > 0) then
			self:CreateItemButton(6948)				-- Hearthstone
		elseif (GetItemCount(28585) > 0) then
			self:CreateItemButton(28585, true)		-- Ruby Slippers
		end

		local clickItems = {
			-- ItemID and whether it needs equiping
			[35230] = false,			-- Darnarian's Scroll of Teleportation (SSO daily reward)
			[32757] = true,				-- Blessed Medallion of Karobor
			[18984] = false,			-- Dimensional Ripper - Everlook
			[30542] = false,			-- Dimensional Ripper - Area 52
			[18986] = false,			-- Ultrasafe Transporter: Gadgetzan
			[30544] = false,			-- Ultrasafe Transporter: Toshley's Station
			[48933] = false,			-- Wormhole Generator: Northrend
			[40585] = true,				-- Signet of the Kirin'Tor
			[40586] = true,				-- Band of the Kirin'Tor
			[44925] = true,				-- Ring of the Kirin'Tor
			[44934] = true,				-- Loop of the Kirin'Tor
			[45688] = true,				-- Inscribed Band of the Kirin Tor
			[45689] = true,				-- Inscribed Loop of the Kirin Tor
			[45690] = true,				-- Inscribed Ring of the Kirin Tor
			[45691] = true,				-- Inscribed Signet of the Kirin Tor
			[48954] = true,				-- Etched Band of the Kirin Tor
			[48955] = true,				-- Etched Loop of the Kirin Tor
			[48956] = true,				-- Etched Ring of the Kirin Tor
			[48957] = true,				-- Etched Signet of the Kirin Tor
			[51557] = true,				-- Runed Signet of the Kirin Tor
			[51558] = true,				-- Runed Loop of the Kirin Tor
			[51559] = true,				-- Runed Ring of the Kirin Tor
			[51560] = true,				-- Runed Band of the Kirin Tor
			[46874] = true,				-- Argent Crusader's Tabard
		}

		for id,equip in pairs(clickItems) do
			if (GetItemCount(id) > 0) then
				self:CreateItemButton(id, equip)
			end
		end

		if (GetItemCount(44315) > 0) then
			self:CreateItemButton(44315)			-- Scroll of Recall 3 (Level 71-80)
		elseif (GetItemCount(44314) > 0) then
			self:CreateItemButton(44314)			-- Scroll of Recall 2 (Level 41-70)
		elseif (GetItemCount(37118) > 0) then
			self:CreateItemButton(37118)			-- Scroll of Recall (Level 1-40)
		end

		if (self.newPortals) then
			for i,button in pairs(self.newPortals) do
				local name = GetItemInfo(button.item)
				self.portals[name] = {
					tex = select(10, GetItemInfo(button.item)),
					buttonSingle = button,
				}
			end
			self.newPortals = del(self.newPortals)
		end
	end
end

-- SetScale
function module:SetScale()
	local frame = self.frame
	if (frame) then
		local s = self.db.char.scale
		frame:SetScale(s)

	    local h = min(33, 100 * s)
		frame.text:SetFont("Fonts\\FRIZQT__.TTF", h, "OUTLINE")

		frame.text:SetTextColor(1, 0.9294, 0.7607)
		frame.reagents:SetTextColor(0.8, 0.8, 0.8)
	end
end

-- SetPoints
function module:SetPoints()
	local pat = self.db.char.pattern
	local f = self.frame
	for j = 1,(pat == "arc" and 2 or 1) do
		local list = new()

		if (j == 1) then
			for city,info in pairs(self.portals) do
				if (self.db.char.showall or GetSpellCooldown(info.single)) then
					tinsert(list, city)
				end
			end
		end

		if (self.db.char.useitems) then
			if ((j == 2) == (pat == "arc")) then
				if (self.itemButtons) then
					for name,info in pairs(self.itemButtons) do
						if (info.singleButton and info.singleButton:IsShown()) then
							if (GetItemCount(name) > 0) then
								tinsert(list, name)
							end
						end
					end
				end
			end
		end

		if (next(list)) then
			sort(list)

			local angle, seperatingAngle, offsetX, offsetY

			f.text:ClearAllPoints()
			f.reagents:ClearAllPoints()
			f.warning:ClearAllPoints()
			if (self.db.char.pattern == "circle") then
				angle = 0
				seperatingAngle = 360 / #list

				f.text:SetPoint("CENTER")
				f.text:SetJustifyH("CENTER")
				f.text:SetJustifyV("MIDDLE")
				f.reagents:SetPoint("TOP", f.text, "BOTTOM")
				f.warning:SetPoint("TOP", f.reagents, "BOTTOM")

			elseif (self.db.char.pattern == "arc") then
				seperatingAngle = 12
				angle = 0 - (seperatingAngle * (#list - 1) / 2)

				f.text:SetPoint("CENTER", 0, -self.distance)
				f.text:SetJustifyH("CENTER")
				f.text:SetJustifyV("TOP")
				f.reagents:SetPoint("TOP", f.text, "BOTTOM")
				f.warning:SetPoint("TOP", f.reagents, "BOTTOM")

			elseif (self.db.char.pattern == "horz") then
				offsetX = -(self.sizeX * ((#list - 1) / 2) * 1.1)
				offsetY = -(self.sizeY / 2)

				f.text:SetPoint("TOP", f, "CENTER", 0, -self.sizeY * 1.1)
				f.text:SetJustifyH("CENTER")
				f.text:SetJustifyV("TOP")
				f.reagents:SetPoint("TOP", f.text, "BOTTOM")
				f.warning:SetPoint("TOP", f.reagents, "BOTTOM")

			elseif (self.db.char.pattern == "vert") then
				offsetX = -(self.sizeX / 2)
				offsetY = -(self.sizeY * ((#list - 1) / 2) * 1.1)

				f.text:SetPoint("LEFT", self.sizeX * 1.1, 0)
				f.text:SetJustifyH("LEFT")
				f.text:SetJustifyV("MIDDLE")
				f.reagents:SetPoint("TOPLEFT", f.text, "BOTTOMLEFT")
				f.warning:SetPoint("TOPLEFT", f.reagents, "BOTTOMLEFT")
			end

			for i = 1,#list do
				local info = self.portals[list[i]] or self.itemButtons[list[i]]
				assert(info)

				if (not info.pos) then
					info.pos = new()
				end
				if (not info.pos[1]) then
					info.pos[1] = new()
				end
				if (not info.pos[2]) then
					info.pos[2] = new()
				end

				if (self.db.char.pattern == "circle") then
					info.angle = angle
					info.pos[1].x = sin(angle) * self.distance * 1.1
					info.pos[1].y = cos(angle) * self.distance * 1.1
					info.pos[2].x = sin(angle) * self.distance * 2
					info.pos[2].y = cos(angle) * self.distance * 2
					angle = angle + seperatingAngle

				elseif (self.db.char.pattern == "arc") then
					info.angle = angle
					info.pos[1].x = sin(angle) * self.distance * 4
					info.pos[1].y = cos(angle) * self.distance * 4 - (self.distance * 4)
					info.pos[2].x = sin(angle) * self.distance * 5
					info.pos[2].y = cos(angle) * self.distance * 5 - (self.distance * 4)
					if (j == 2) then
						info.pos[1].y = -200 - info.pos[1].y
						info.pos[2].y = -200 - info.pos[2].y
					end
					angle = angle + seperatingAngle

				elseif (self.db.char.pattern == "horz") then
					info.pos[1].x = offsetX
					info.pos[1].y = offsetY
					info.pos[2].x = offsetX
					info.pos[2].y = offsetY + self.distance
					offsetX = offsetX + self.sizeX * 1.1

				elseif (self.db.char.pattern == "vert") then
					info.pos[1].x = offsetX
					info.pos[1].y = offsetY
					info.pos[2].x = offsetX + self.distance
					info.pos[2].y = offsetY
					offsetY = offsetY + self.sizeY * 1.1
				end
			end
		end

		del(list)
	end
end

-- CloseButtonList
function module:CloseButtonList(list)	
	if (list) then
		for city,info in pairs(list) do
			if (info.singleButton) then
				info.singleButton:Hide()
			end
			if (info.groupButton) then
				info.groupButton:Hide()
			end
		end
	end
end

-- OnUpdateOpening
function module:OnUpdateOpening(elapsed)
	local s = self.expandingState
	if (not s) then
		self.expandingState = true
		self.frame:Show()

		self:CloseButtonList(self.portals)
		self:CloseButtonList(self.itemButtons)

		self:CreatePortals()
		self:CreateItemButtons()
		self:SetPoints()

		self.scale = 0.001
	end

	self.scale = min(1, self.scale + elapsed * 2)
	if (self.scale >= 1) then
		self.scale = 1
		self.expandingState = nil
		self.mode = self.OnUpdate
	end

	self.frame.text:SetTextColor(1, 0.9294, 0.7607, self.scale)
	self.frame.reagents:SetTextColor(0.8, 0.8, 0.8, self.scale)
	self.frame.warning:SetTextColor(1, 0, 0, self.scale)

	self:Draw()
end

-- Draw
function module:Draw()
	local mx, my = self:GetMouseXY()

	for city,info in pairs(self.portals) do
		if (info.singleButton) then
			if (info.pos and info.singleButton:IsShown()) then
				info.singleButton:SetPoint("CENTER", info.pos[1].x, info.pos[1].y)
				info.singleButton.drawFrame:SetScale(self.scale)
				self:CheckDistance(info.singleButton, mx, my)
				self:OnUpdateCheckCooldown(info.singleButton)
			end
		end
		if (info.groupButton) then
			if (info.pos and info.groupButton:IsShown()) then
				info.groupButton:SetPoint("CENTER", info.pos[2].x, info.pos[2].y)
				info.groupButton.drawFrame:SetScale(self.scale)
				self:CheckDistance(info.groupButton, mx, my)
				self:OnUpdateCheckCooldown(info.groupButton)
			end
		end
	end

	if (self.db.char.useitems and self.itemButtons) then
		for city,info in pairs(self.itemButtons) do
			if (info.singleButton) then
				if (info.pos and info.singleButton:IsShown()) then
					info.singleButton:SetPoint("CENTER", info.pos[1].x, info.pos[1].y)
					info.singleButton.drawFrame:SetScale(self.scale)
					self:CheckDistance(info.singleButton, mx, my)
					self:OnUpdateCheckCooldown(info.singleButton)
				end
			end
		end
	end
end

-- OnUpdateClosing
function module:OnUpdateClosing(elapsed)
	self.expandingState = nil

	local s = self.contractingState
	if (not s) then
		self.contractingState = true
	end

	self.scale = self.scale - elapsed * 2
	if (self.scale <= 0) then
		self.contractingState = nil
		self.scale = 1
		self.frame:Hide()
		self.mode = nil
		return
	end

	self.frame.text:SetTextColor(1, 0.9294, 0.7607, self.scale)
	self.frame.reagents:SetTextColor(0.8, 0.8, 0.8, self.scale)
	self.frame.warning:SetTextColor(1, 0, 0, self.scale)

	self:Draw()
end

-- GetMouseXY
function module:GetMouseXY()
	local mx, my = GetCursorPosition()
    local x, y = self.frame:GetCenter()
    if (mx and x) then
    	x = x * UIParent:GetEffectiveScale()
    	y = y * UIParent:GetEffectiveScale()
	    return mx - x, my - y
	end
end

-- GetMouseXY
function module:GetFrameXY(frame)
	local px, py = self.frame:GetCenter()
	local x, y = frame:GetCenter()
	if (px and x) then
		x = (x * self.frame:GetScale() - px) * UIParent:GetEffectiveScale()
		y = (y * self.frame:GetScale() - py) * UIParent:GetEffectiveScale()
	end
	return x, y
end

-- CheckDistance
function module:CheckDistance(frame, mx, my)
	if (not frame or not frame:IsShown()) then
		return
	end

	local x, y = self:GetFrameXY(frame)
	if (x) then
		local distance = abs(x - mx) + abs(y - my)
		local checkDistance = 100 * self.frame:GetScale()

		if (distance > checkDistance or frame.drawFrame:IsEnabled() == 0) then
			frame.drawFrame:SetScale(self.scale)
		else
			local factor = (checkDistance - distance) / checkDistance
			local scale = self.scale + ((self.scale * 0.6) * factor)
			frame.drawFrame:SetScale(scale)
		end
	end
end

-- OnUpdate
function module:OnUpdate(elapsed)
	local x, y = self:GetMouseXY()

	if (x) then
		for city,info in pairs(self.portals) do
			self:CheckDistance(info.singleButton, x, y)
			self:CheckDistance(info.groupButton, x, y)
			self:OnUpdateCheckCooldown(info.singleButton)
			self:OnUpdateCheckCooldown(info.groupButton)
		end
		if (self.db.char.useitems and self.itemButtons) then
			for city,info in pairs(self.itemButtons) do
				if (info.singleButton) then
					self:CheckDistance(info.singleButton, x, y)
					self:OnUpdateCheckCooldown(info.singleButton)
				end
			end
		end
	end
end

-- OnUpdateCheckCooldown
function module:OnUpdateCheckCooldown(button)
	if (button and button.endTime) then
		local diff = button.endTime - GetTime()
		if (diff <= 0) then
			button.cooldown:Hide()
			button.endTime = nil
			button.drawFrame:Enable()
			button.tex:SetDesaturated(false)
			button.tex:SetVertexColor(1, 1, 1)
		end

		button.cooldown:SetFormattedText(SecondsToTimeAbbrev(diff))
	end
end

-- UpdateCooldown
function module:UpdateCooldown(button)
	if (button) then
		local start, dur = button:GetCooldown()

		if (start == 0) then
			button.cooldownValue = nil
			button.cooldown:Hide()
			button.endTime = nil
			button.drawFrame:Enable()
			button.tex:SetDesaturated(false)
			button.tex:SetVertexColor(1, 1, 1)
		else
			button.endTime = start and start + dur

			if (button.endTime and button.endTime > GetTime() + 3) then
				button.cooldownValue = button.endTime
				button.cooldown:Show()
			else
				button.cooldownValue = nil
				button.cooldown:Hide()
			end

			button.drawFrame:Disable()

			if (not button.tex:SetDesaturated(true)) then
				button.tex:SetVertexColor(0.5, 0.5, 0.5)
			end
		end
	end
end

-- SPELL_UPDATE_COOLDOWN
function module:SPELL_UPDATE_COOLDOWN()
	for name, info in pairs(self.portals) do
		self:UpdateCooldown(info.singleButton)
		self:UpdateCooldown(info.groupButton)
	end
	if (self.db.char.useitems and self.itemButtons) then
		for city,info in pairs(self.itemButtons) do
			if (info.singleButton) then
				self:UpdateCooldown(info.singleButton)
			end
		end
	end
end

-- UNIT_INVENTORY_CHANGED
function module:UNIT_INVENTORY_CHANGED(unit)
	if (unit == "player") then
		self:SPELL_UPDATE_COOLDOWN()
	end
end

-- PLAYER_REGEN_DISABLED
function module:PLAYER_REGEN_DISABLED()
	self.frame:Hide()
	self.mode = nil
end

-- UNIT_SPELLCAST_START
function module:UNIT_SPELLCAST_SENT(x)
	module.mode = module.OnUpdateClosing
end

-- OnModuleInitialize
function module:OnModuleInitialize()
	playerClass = select(2, UnitClass("player"))

	self.db = z:AcquireDBNamespace("Portalz")
	z:RegisterDefaults("Portalz", "char", {
		pattern = "arc",
		locked = true,
		scale = 1,
		showall = false,
		useitems = true,
		sticky = true,
		announce = false,
	})

	z:RegisterChatCommand({"/zomgportalz", "/zomgport"}, self.options)
	self.OnMenuRequest = self.options
	z.options.args.ZOMGPortalz = self.options

	self.spellBlend = "BLEND"
	self.itemBlend = "ADD"

	if (playerClass == "MAGE") then
		if (UnitFactionGroup("player") == "Horde") then
			self.portals = {
				["Dalaran"]			= {group = 53142, single = 53140,	tex = "Interface\\Addons\\ZOMGBuffs\\Textures\\MagePortal_Dalaran"},
				["Shattrath"]		= {group = 35717, single = 35715,	tex = "Interface\\Addons\\ZOMGBuffs\\Textures\\MagePortal_Shattrath"},
				["Orgrimmar"]		= {group = 11417, single = 3567,	tex = "SPELLS\\Ogrimmar_Portal"},
				["Undercity"]		= {group = 11418, single = 3563,	tex = "SPELLS\\Undercity_Portal"},
				["Thunder Bluff"]	= {group = 11420, single = 3566,	tex = "SPELLS\\ThunderBluff_Portal"},
				["Silvermoon"]		= {group = 32267, single = 32272, 	tex = "Interface\\Addons\\ZOMGBuffs\\Textures\\MagePortal_Silvermoon"},
				["Stonard"]			= {group = 49361, single = 49358, 	tex = "World\\GENERIC\\ACTIVEDOODADS\\SpellPortals\\Stonard_Portal"},
			}
		else
			self.portals = {
				["Dalaran"]			= {group = 53142, single = 53140,	tex = "Interface\\Addons\\ZOMGBuffs\\Textures\\MagePortal_Dalaran"},
				["Shattrath"]		= {group = 33691, single = 33690, 	tex = "Interface\\Addons\\ZOMGBuffs\\Textures\\MagePortal_Shattrath"},
				["Stormwind"]		= {group = 10059, single = 3561, 	tex = "World\\GENERIC\\ACTIVEDOODADS\\MAGEPORTALS\\STORMWIND_PORTAL"},
				["Ironforge"]		= {group = 11416, single = 3562, 	tex = "SPELLS\\Ironforge_Portal"},
				["Darnassus"]		= {group = 11419, single = 3565, 	tex = "SPELLS\\Darnassus_Portal"},
				["Exodar"]			= {group = 32266, single = 32271, 	tex = "Interface\\Addons\\ZOMGBuffs\\Textures\\MagePortal_Exodar"},
				["Theramore"]		= {group = 49360, single = 49359, 	tex = "Interface\\Addons\\ZOMGBuffs\\Textures\\MagePortal_Theramore"},
			}
		end
		self.singleReagent = 17031
		self.groupReagent = 17032

	elseif (playerClass == "SHAMAN") then
		self.portals = {
			["Astral Recall"]		= {single = 556, tex = select(3, GetSpellInfo(556))},
		}
		self.spellBlend = "ADD"
		self.spellTrim = true

	elseif (playerClass == "DRUID") then
		self.portals = {
			["Moonglade"]			= {single = 18960, tex = "Interface\\Addons\\ZOMGBuffs\\Textures\\DruidPortal_Moonglade"},
		}

	elseif (playerClass == "DEATHKNIGHT") then
		self.portals = {
			["Death Gate"]			= {single = 50977, tex = "Interface\\Addons\\ZOMGBuffs\\Textures\\DeathKnightPortal_EbonHold"},
		}
	end

	self.lookup = {}
	if (self.portals) then
		for name, info in pairs(self.portals) do
			local s = info.single and GetSpellInfo(info.single)
			if (s) then
				info.spellIDSingle = info.single
				info.spellIDGroup = info.group
				info.single = s
				info.group = info.group and GetSpellInfo(info.group)
                if (info.group) then
					self.lookup[info.group] = name
				end
			else
				self.portals[name] = nil	-- Removes unknown spells (ie: running on live WoW will not know about Dalaran portal)
			end
		end
	else
		self.portals = {}
	end

	self.OnModuleInitialize = nil
end

do
	local BZ
	-- SpellCastSucceeded
	function module:SpellCastSucceeded(spell)
		if (self.db.char.announce) then
			if (GetNumRaidMembers() + GetNumPartyMembers() > 0) then
				local translated
				if (not BZ) then
					if (GetLocale() == "enUS" or GetLocale() == "enGB") then
						translated = true
					else
						LoadAddOn("LibBabble-Zone-3.0")
						BZ = LibStub("LibBabble-Zone-3.0"):GetUnstrictLookupTable()
					end
				end

				local name = self.lookup and self.lookup[spell]
				if (name) then
					if (BZ) then
						if (BZ[name]) then
							name = BZ[name]
							translated = true
						end
					end

					local msg
					if (translated or strfind(spell, name)) then
						msg = format(L[">>> Created a Portal to %s <<<"], name)			-- When name is localized
					else
						msg = format(L[">>> %s created <<<"], name)						-- When it is not
					end

					SendChatMessage(msg, GetNumRaidMembers() > 0 and "RAID" or "PARTY")
				end
			end
		end
	end
end

-- OnModuleEnable
function module:OnModuleEnable()
	self.distance = 100
	self.sizeX = 80
	self.sizeY = 100

	if (self.db) then
		local class = select(2, UnitClass("player"))
		if (class ~= playerClass and self.OnModuleInitialize) then
			self:OnModuleInitialize()
		end

		self:InitFrames()
	end
end

-- OnDisable
function module:OnDisable()
end
