if (ZOMGSelfBuffs) then
	ZOMGBuffs:Print("Installation error, duplicate copy of ZOMGBuffs_SelfBuffs (Addons\ZOMGBuffs\ZOMGBuffs_SelfBuffs and Addons\ZOMGBuffs_SelfBuffs)")
	return
end

local wowVersion = tonumber((select(2,GetBuildInfo())))

local L = LibStub("AceLocale-2.2"):new("ZOMGSelfBuffs")
local R = LibStub("AceLocale-2.2"):new("ZOMGReagents")
local LGT = LibStub("LibGroupTalents-1.0")
local playerClass, playerName, playerGUID
local template

local InCombatLockdown	= InCombatLockdown
local IsUsableSpell		= IsUsableSpell
local GetSpellCooldown	= GetSpellCooldown
local GetSpellInfo		= GetSpellInfo
local UnitBuff			= UnitBuff
local UnitClass			= UnitClass

local z = ZOMGBuffs
local zs = z:NewModule("ZOMGSelfBuffs")
ZOMGSelfBuffs = zs

z:CheckVersion("$Revision: 152 $")

local enchantMatching		-- Table of spellName -> enchantName conversions
do
	if (GetLocale() == "enUS") then
		enchantMatching = {
			[GetSpellInfo(5761)] = "Mind Numbing Poison",			-- Mind-numbing Poison
			[GetSpellInfo(8232)] = "^Windfury (%d+)$",				-- Windfury Weapon
			[GetSpellInfo(8024)] = "^Flametongue (%d+)$",			-- Flametongue Weapon
			[GetSpellInfo(51730)] = "^Earthliving (%d+)$",			-- Earthliving Weapon
			[GetSpellInfo(8033)] = "^Frostbrand (%d+)$",			-- Frostbrand Weapon
		}

	elseif (GetLocale() == "deDE") then
		enchantMatching = {
			[GetSpellInfo(3408)] = "Verkrüppelungsgift",			-- Verkrüppelndes Gift (Crippling Poison)
			[GetSpellInfo(8232)] = "^Windzorn (%d+)$",				-- Windfury Weapon
			[GetSpellInfo(8024)] = "^Flammenzunge (%d+)$",			-- Flametongue Weapon
			[GetSpellInfo(51730)] = "^Lebensgeister (%d+)$",		-- Earthliving Weapon
			[GetSpellInfo(8033)] = "^Frostbrand (%d+)$",			-- Frostbrand Weapon
		}

	elseif (GetLocale() == "esES") then
		enchantMatching = {
			[GetSpellInfo(8232)] = "^Viento Furioso (%d+)$",		-- Windfury Weapon
			[GetSpellInfo(8024)] = "^Lengua de Fuego (%d+)$",		-- Flametongue Weapon
			[GetSpellInfo(51730)] = "^Vida terrestre (%d+)$",		-- Earthliving Weapon
			[GetSpellInfo(8033)] = "^Estigma de Escarcha (%d+)$",	-- Frostbrand Weapon
		}

	elseif (GetLocale() == "frFR") then
		enchantMatching = {
			[GetSpellInfo(5761)] = "Poison de Distraction mentale",	-- Poison de distraction mentale (Mind-numbing Poison)
			[GetSpellInfo(8232)] = "^Furie-des-vents (%d+)$",		-- Windfury Weapon
			[GetSpellInfo(8024)] = "^Langue de feu (%d+)$",			-- Flametongue Weapon
			[GetSpellInfo(51730)] = "^Viveterre (%d+)$",			-- Earthliving Weapon
			[GetSpellInfo(8033)] = "^Arme de givre (%d+)$",			-- Frostbrand Weapon
		}
		
	elseif (GetLocale() == "ruRU") then
		enchantMatching = {
			[GetSpellInfo(8232)] = "^Неистовство ветра (%d+)$",		-- Windfury Weapon
			[GetSpellInfo(8024)] = "^Язык пламени (%d+)$",			-- Flametongue Weapon
			[GetSpellInfo(51730)] = "^Жизнь Земли (%d+)$",			-- Earthliving Weapon
			[GetSpellInfo(8033)] = "^Ледяное клеймо (%d+)$",		-- Frostbrand Weapon
		}
	end
end

local new, del, deepDel, copy = z.new, z.del, z.deepDel, z.copy

local function getOption(v)
	return zs.db.char[v]
end

local function setOption(v, n, s)
	zs.db.char[v] = n
	if (s) then
		z:CheckForChange(zs)
	end
end

local function getPrelude(k)
	return zs.db.char.rebuff[k] or 0
end

local function setPrelude(k, v)
	if ((not v or v == 0) and k ~= "default") then
		zs.db.char.rebuff[k] = nil
	else
		zs.db.char.rebuff[k] = v
	end
end

zs.consoleCmd = L["Self"]
zs.options = {
	type = "group",
	order = 1,
	name = "|cFFFF8080Z|cFFFFFF80O|cFF80FF80M|cFF8080FFG|rSelfBuffs",
	desc = L["Self Buff Configuration"],
	handler = zs,
	disabled = function() return z:IsDisabled() end,
	args = {
		template = {
			type = "group",
			name = L["Templates"],
			desc = L["Template configuration"],
			order = 10,
			hidden = function() return not zs:IsModuleActive() end,
			args = {
			}
		},
		behaviour = {
			type = "group",
			name = L["Behaviour"],
			desc = L["Self buffing behaviour"],
			order = 201,
			hidden = function() return not zs:IsModuleActive() end,
			args = {
				combatnotice = {
					type = "toggle",
					name = L["Combat Warnings"],
					desc = L["Warn about expiring buffs in combat. Note that auto buffing cannot be done in combat, this is simply a reminder"],
					get = getOption,
					set = function(k,v) setOption(k, v, true) end,
					passValue = "combatnotice",
					order = 5,
				},
				rebuff = {
					type = "range",
					name = L["Expiry Prelude"],
					desc = L["Default rebuff prelude for all self buffs"],
					func = timeFunc,
					get = getPrelude,
					set = setPrelude,
					passValue = "default",
					min = 0,
					max = 15 * 60,
					step = 5,
					bigStep = 60,
					order = 10,
				},
				useauto = {
					type = "toggle",
					name = L["Auto buffs"],
					desc = L["Use auto-intelligent buffs such as Crusader Aura when mounted"],
					get = getOption,
					set = function(k,v) setOption(k, v, true) end,
					passValue = "useauto",
					order = 15,
				},
				info = {
					type = 'toggle',
					name = L["Reagent Reminder"],
					desc = L["Show message when spells requiring reagents are used"],
					get = getOption,
					set = setOption,
					passValue = "reagentNotices",
					order = 20,
				},
			},
		},
	}
}
zs.moduleOptions = zs.options

-- GetExistingItemWithSequence
local function GetExistingItemWithSequence(k, v)
	if (k and v) then
		local n = k
		if (v.sequence) then
			for i = #v.sequence,1,-1 do
				local temp = k..v.sequence[i]
				local c = GetItemCount(temp)
				if (c > 0) then
					return temp
				end
			end
		else
			return GetItemCount(k) > 0 and k
		end
	end
end

-- SetupForItem
function zs:SetupForItem(slot, itemName)
	local spell, item
	local t1, t2 = IsUsableSpell(itemName)
	spell = (t1 or t2) and itemName
	if (not spell) then
		item = GetExistingItemWithSequence(itemName, self.classBuffs[itemName])
	end
	if (spell or item) then
		z:SetupForItem(slot, item, self, spell, item and 4 or nil)	-- 4 for when casting poisons onto weapons, we need more than 1.5 secs for next check
		self.activeEnchantLoaded = item and 3 or 0
		self.lastEnchantSet = spell or item
		return true
	end
end

-- GetCurrentItemEnchant
do
	local tempTip, durMatch, encMatchHour, encMatchMin, encMatchSec
	function zs:GetCurrentItemEnchant(slot)
		local hasEnchant, Expiration, Charges = select(1 + (3 * (slot - 16)), GetWeaponEnchantInfo())
		if (hasEnchant) then
			local tipName = "ZOMGBuffTempTip"
			-- See what enchant is, so we can make sure it's the right one

			if (not tempTip) then
				tempTip = CreateFrame("GameTooltip", tipName, UIParent, "GameTooltipTemplate")
			end

			if (not durMatch) then
				-- ConvertGlobalString - Shamelessly pulled from Parser-3.0
				local function ConvertGlobalString(str, first)
					-- Escape lua magic chars.
					local pattern = str:gsub("([%(%)%.%*%+%-%[%]%?%^%$%%])", "%%%1")

					-- Convert %1$s to (..-) and %1$d to (%d+).
					-- We don't care about the capture order, it's always the same for these strings
					pattern = pattern:gsub("%%%%%d%%%$s", "(..-)")
					pattern = pattern:gsub("%%%%%d%%%$d", "(%%d+)")

					-- Convert %s to (..-) and %d to (%d+).
					pattern = pattern:gsub("%%%%s", "(..-)")
					pattern = pattern:gsub("%%%%d", "(%%d+)")

					-- Strip out "|4singular:plural;"
					pattern = pattern:gsub("|4%a+:(%a+);", "%1-")

					if pattern:sub(-5) == "(..-)" then
						pattern = pattern:sub(1, -6) .. "(.+)"
					end

					return "^" .. pattern
				end

				durMatch = ConvertGlobalString(DURABILITY_TEMPLATE)
				encMatchHour = ConvertGlobalString(ITEM_ENCHANT_TIME_LEFT_HOURS)
				encMatchMin = ConvertGlobalString(ITEM_ENCHANT_TIME_LEFT_MIN)
				encMatchSec = ConvertGlobalString(ITEM_ENCHANT_TIME_LEFT_SEC)
			end

			tempTip:SetOwner(UIParent, "ANCHOR_NONE")
			local ok, cd = tempTip:SetInventoryItem("player", slot)
			if (ok and cd) then
				local spellFind, timeLeft
				for i = 1,200 do
					local leftRegion = getglobal(format("%sTextLeft%d", tipName, i))
					if (not leftRegion) then
						break
					end
					local left = leftRegion:GetText()
					if (not left) then
						break
					end
					spellFind, timeLeft = strmatch(left, encMatchHour)
					if (not spellFind) then
						spellFind, timeLeft = strmatch(left, encMatchMin)
						if (not spellFind) then
							spellFind, timeLeft = strmatch(left, encMatchSec)
						end
					end
					if (spellFind and timeLeft) then
						break
					end
				end
				tempTip:Hide()

				if (spellFind and timeLeft) then
					return spellFind, Expiration / 1000 / 60
				end
			end
			tempTip:Hide()
		end
	end
end

-- CheckEnchant
function zs:CheckEnchant(slot, spellOrItem)
	if (spellOrItem) then
		if (not self.activeEnchant or self.activeEnchant < GetTime() - (playerClass == "ROGUE" and 3.5 or 2.5)) then
			local itemLink = GetInventoryItemLink("player", slot)
			if (itemLink) then
				local itemName, _, quality, itemLevel = GetItemInfo(itemLink)
				if (itemLevel == 1 and quality < 2) then
					-- Ignore itemLevel == 1 (Argent Lances etc)
					return
				end
				local name, tex, _, _, _, itemType, subType = GetItemInfo(itemLink)
				if (name) then
					if (subType == "Fishing Poles") then
						return
					end
				end
			end

			local hasEnchant, Expiration, Charges = select(1 + (3 * (slot - 16)), GetWeaponEnchantInfo())
			if (hasEnchant) then
				local lookFor = enchantMatching[spellOrItem]

				if (lookFor or playerClass ~= "SHAMAN") then		-- Shaman weapon enchants do not match spell names, so we won't check them
					local enc, timeLeft = self:GetCurrentItemEnchant(slot)
					if (enc) then
						local temp = (lookFor or spellOrItem):gsub("%-", "%%-")
						local found, pos, rank = strfind(enc, temp)
						if (not found) then
							hasEnchant = nil
						elseif (rank) then
							local foundRank = tonumber(rank)
							if (foundRank) then
								local name2, rank2 = GetSpellInfo(spellOrItem)
								if (name2 and rank2) then
									rank2 = tonumber(strmatch(rank2, "(%d+)"))
									if (rank2) then
										if (foundRank ~= rank2) then
											-- Available enchant is a higher rank than one on weapon
											hasEnchant = nil
										end
									end
								end
							end
						end
					end
				end
			end

			if (not hasEnchant or Expiration / 1000 < self.db.char.rebuff.default) then
				if (InCombatLockdown() or self:SetupForItem(slot, spellOrItem)) then
					local itemLink = GetInventoryItemLink("player", slot)
					if (not itemLink) then
						itemLink = (slot == 16 and L["Main Hand"]) or L["Off Hand"]
					end
					z:Notice(format(L["You need %s on |c00FFFF80%s|r"], z:LinkSpell(spellOrItem, nil, true), itemLink), "buffreminder")
					return true
				end
			end
		else
			z:GlobalCDSchedule()
		end
	end
end

-- CheckWeaponBuff
function zs:CheckWeaponBuffs()
	return self:CheckEnchant(16, template.mainhand) or (OffhandHasWeapon() and self:CheckEnchant(17, template.offhand))
end

-- CheckBuffs
function zs:CheckBuffs()
	if (not self.classBuffs) then
		return
	end

	--local myBuffs
	if (self.db.char.useauto and not InCombatLockdown()) then
		if (z.globalCooldownEnd > GetTime()) then
			z:GlobalCDSchedule()
			return
		end

		-- Special case for Crusader Aura when mounted, and Aspect of Cheetah when resting
		for k,v in pairs(self.classBuffs) do
			if (v.auto) then
				local name, rank, buff, count, _, max, endTime, isMine, isStealable = UnitBuff("player", k)
				isMine = isMine == "player"
				if (not name or not isMine) then
					if (v.auto()) then
						if (not UnitOnTaxi("player") and not UnitIsDeadOrGhost("player")) then
							z:SetupForSpell()
							z:SetupForSpell("player", k, self)
							z:Notice(format(L["You need %s"], z:LinkSpell(k, nil, true)), "buffreminder")
							z.icon.autospell = true
							return
						end
					end
				end
			end
		end
	end

	if (not z:CanCheckBuffs(self.db.char.combatnotice, true)) then
		if (IsMounted() and not z.db.profile.notmounted) then
			z:SetupForSpell()
		end
		return
	end

	if (z.icon.autospell) then
		if (not InCombatLockdown()) then
			z:SetupForSpell()
		end
	end

	local any

	local charges = self.db.char.charges
	local minTimeLeft
	for k,v in pairs(template) do
		if (v) then
			local cb = self.classBuffs[k]
			if (cb and (cb.who == "self" or cb.who == "single" or cb.who == "party")) then
				if (not cb.skip or not cb.skip()) then
					local name, rank, buff, count, _, max, endTime, isMine, isStealable = UnitBuff("player", k)
					local timeLeft = endTime and (endTime - GetTime())
					local requiredTimeLeft = self.db.char.rebuff[(cb and cb.rebuff) or k] or self.db.char.rebuff.default

					local c = charges and charges[k]
					if (c) then
						local cdef = cb.charges
						if (type(cdef) == "function") then
							cdef = cdef()
						end
						if (c > cdef) then
							if (LGT:GetUnitTalents("player")) then
								c = cdef
								charges[k] = cdef
							end
						end
					end

					if ((c and ((count or 0) < (c or 0))) or (endTime ~= 0 and (not timeLeft or timeLeft < requiredTimeLeft))) then
						-- Need recast
						local start, duration, enable = GetSpellCooldown(k)
						if ((start and (start == 0 or start + duration <= GetTime())) and enable == 1 and IsUsableSpell(k)) then
							if (not InCombatLockdown() or not cb.nocombatnotice) then
								z:Notice(format(L["You need %s"], z:LinkSpell(k, nil, true)), "buffreminder")
							end
							if (not InCombatLockdown()) then
								z:SetupForSpell("player", k, self)
							end
							any = true
							break
						elseif (start and start ~= 0) then
							local temp = (start + duration) - GetTime()
							if (not minTimeLeft or temp < minTimeLeft) then
								minTimeLeft = temp	-- Soon to cooldown spells caught here
							end
						end
					elseif (timeLeft and timeLeft < 10000) then
						local t = timeLeft - requiredTimeLeft
						if (not minTimeLeft or t < minTimeLeft) then
							minTimeLeft = t
						end
					end
				end
			end
		end
	end

	if (not any) then
		local safeFlaskIcon = select(3, GetSpellInfo(67016))			-- Flask of the North icon

		-- Handle Flask of the North
		local alc = GetSpellInfo(51304)
		if (GetSpellInfo(alc) and GetItemCount(47499) > 0) then
			if (self.db.char.flask) then
				local skip		-- Skip Flask of the North if any other potions/elixirs/flasks are buffed
				for i = 1,1000 do
					local name, rank, buff, count, _, max, endTime, isMine, isStealable = UnitBuff("player", i)
					if not name then break end
					if (strmatch(buff, "INV_Potion") or strmatch(buff, "INV_Alchemy")) and buff ~= safeFlaskIcon then
						skip = true
						break
					end
				end
				if (not skip) then
					local requiredTimeLeft = self.db.char.rebuff.flask or self.db.char.rebuff.default
					local name, rank, buff, count, _, max, endTime, isMine, isStealable = UnitBuff("player", (GetSpellInfo(67016)))
					if (not name) then
						self.db.char.activeFlaskOfTheNorth = nil
					end

					if (self.db.char.flask ~= self.db.char.activeFlaskOfTheNorth or not name or endTime - GetTime() < requiredTimeLeft) then
						z:SetupForItem(nil, (GetItemInfo(47499)), self)
						any = true
					end
				end
			end
		end
	end

	if (not any and (template.mainhand or template.offhand)) then
		if (self:CheckWeaponBuffs()) then
			any = true
		end
	end

	self:CancelScheduledEvent("ZOMGBuffs_SelfCheckBuffs")
	if (not any and minTimeLeft) then
		self:ScheduleEvent("ZOMGBuffs_SelfCheckBuffs", self.CheckBuffs, minTimeLeft, self)
	end
end

-- GetClassBuffs
function zs:GetClassBuffs()
	local classBuffs
	if (playerClass == "DRUID") then
		classBuffs = {
			{id = 16864, o = 2, duration = 30, who = "self", c = "80A0FF", noauto = true}, -- Omen of Clarity
			{id = 22812, o = 5, duration = 0.25, default = 5, who = "self", c = "A0A020", noauto = true, nocombatnotice = true}, -- Barkskin
			{id = 27009, o = 6, duration = 0.75, default = 5, who = "self", c = "80FF80", noauto = true, skip = function() return IsIndoors() end}, -- Nature's Grasp
			{id = 9846, o = 7, duration = 0.1, default = 1, who = "self", c = "FF8080", noauto = true}, -- Tiger's Fury
		}
		self.reagents = {
			[GetItemInfo(17034) or R["Maple Seed"]]			= {20, 1, 50, minLevel = 20, maxLevel = 29},
			[GetItemInfo(17035) or R["Stranglethorn Seed"]]	= {20, 1, 50, minLevel = 30, maxLevel = 39},
			[GetItemInfo(17036) or R["Ashwood Seed"]]			= {20, 1, 50, minLevel = 40, maxLevel = 49},
			[GetItemInfo(17037) or R["Hornbeam Seed"]]		= {20, 1, 50, minLevel = 50, maxLevel = 59},
			[GetItemInfo(17038) or R["Ironwood Seed"]]		= {20, 1, 50, minLevel = 60, maxLevel = 68},
			[GetItemInfo(22147) or R["Flintweed Seed"]]		= {20, 1, 50, minLevel = 69, maxLevel = 78},
			[GetItemInfo(44614) or R["Starleaf Seed"]]		= {20, 1, 50, minLevel = 79, maxLevel = 88},
		}
		self.notifySpells = {
			[GetSpellInfo(26994)] = {		-- Rebirth
				GetItemInfo(17034) or R["Maple Seed"],
				GetItemInfo(17035) or R["Stranglethorn Seed"],
				GetItemInfo(17036) or R["Ashwood Seed"],
				GetItemInfo(17037) or R["Hornbeam Seed"],
				GetItemInfo(17038) or R["Ironwood Seed"],
				GetItemInfo(22147) or R["Flintweed Seed"],
				GetItemInfo(44614) or R["Starleaf Seed"],
			},
		}

	elseif (playerClass == "MAGE") then
		classBuffs = {
			{id = 7301,  o = 4,  duration = 30,  who = "self", c = "0000FF", exclude = function() return IsUsableSpell(GetSpellInfo(36881)) end},	-- Frost Armor
			{id = 34913, o = 5,  duration = 30,  who = "self", dup = 2, c = "FF0000"},							-- Molten Armor
			{id = 27124, o = 6,  duration = 30,  who = "self", dup = 2, c = "0050FF"},							-- Ice Armor
			{id = 27125, o = 7,  duration = 30,  who = "self", dup = 2, c = "8080FF"},							-- Mage Armor
			{id = 33405, o = 9,  duration = 1,   who = "self", default = 5, c = "B0B0FF", noauto = true, cancancel = true}, -- Ice Barrier
			{id = 27128, o = 10, duration = 0.5, who = "self", default = 5, noauto = true, dup = 3, c = "FF5050", cancancel = true},	-- Fire Ward
			{id = 32796, o = 11, duration = 0.5, who = "self", default = 5, noauto = true, dup = 3, c = "5050FF", cancancel = true},	-- Frost Ward
			{id = 27131, o = 12, duration = 1,   who = "self", default = 5, noauto = true, c = "FFB0B0", cancancel = true},	-- Mana Shield
			{id = 11129, o = 14, duration = -1,  who = "self", noauto = true, c = "F5BC0B"},									-- Combustion
		}
		local singlePort = GetItemInfo(17031) or R["Rune of Teleportation"]
		local groupPort = GetItemInfo(17032) or R["Rune of Portals"]
		self.reagents = {
			[groupPort]		= {20, 1, 100},
			[singlePort]	= {20, 1, 100},
		}
		local singles = {3561, 3562, 3563, 3565, 3566, 3567, 32271, 32272, 33690}
		local groups = {10059, 11416, 11417, 11418, 11419, 11420, 32266, 32267, 33691}
		self.notifySpells = {}
		for i,id in pairs(singles) do
			self.notifySpells[(GetSpellInfo(id))] = singlePort
		end
		for i,id in pairs(groups) do
			self.notifySpells[(GetSpellInfo(id))] = groupPort
		end

	elseif (playerClass == "PRIEST") then
		classBuffs = {
			{id = 25218, o = 1, duration = 0.5, default = 5, who = "single", noauto = true, c = "C0C0FF"},	-- Power Word: Shield
			{id = 25431, o = 2, duration = 10, charges = 20, who = "self", c = "FFA080"},					-- Inner Fire
			{id = 15473, o = 9, duration = -1, who = "self", c = "A020A0"},									-- Shadowform
		}
		if (wowVersion > 10505) then		-- WoW 3.3 or better
			tinsert(classBuffs, {id = 15286, o = 3, duration = 30, who = "self", c = "8080A0"})				-- Vampiric Embrace (changed to a self buff with 3.3)
		end

	elseif (playerClass == "WARLOCK") then
		classBuffs = {
			{id = 27260, o = 1, duration = 30, who = "self", dup = 1, c = "FF80FF"},					-- Demon Armor
			{id = 696,   o = 2, duration = 30, who = "self", dup = 1, c = "FF20FF", exclude = function() return IsUsableSpell(GetSpellInfo(27260)) end}, -- Demon Skin
			{id = 44977, o = 3, duration = 30, who = "self", dup = 1, c = "FF8080"},					-- Fel Armor
			{id = 28610, o = 6, duration = 0.5, default = 5, who = "self", noauto = true, c = "FF60FF"},				-- Shadow Ward
			{id = 19028, o = 7, duration = -1, who = "self", noauto = true, c = "20FF80", skip = function() return not UnitExists("pet") end},				-- Soul Link
		}
		self.reagents = {
			[GetItemInfo(16583) or R["Demonic Figurine"]]	= {5, 1, 100},
			[GetItemInfo(5565) or R["Infernal Stone"]]	= {5, 1, 100},
		}
		local shoulShard = R["Soul Shard"]
		local warlockList = {
			27250, -- Create Firestone
			27238, -- Create Soulstone
			28172, -- Create Spellstone
			27230, -- Create Healthstone
			11726, -- Enslave Demon
			29893, -- Ritual of Souls
			698,   -- Ritual of Summoning
			30546, -- Shadowburn
			30545, -- Soul Fire
			29858, -- Soulshatter
			30146, -- Summon Felguard
			691,   -- Summon Felhunter
			712,   -- Summon Succubus
			697,   -- Summon Voidwalker
		}
		self.notifySpells = {}
		for i,id in pairs(warlockList) do
			self.notifySpells[(GetSpellInfo(id))] = soulShard
		end
		self.notifySpells[GetSpellInfo(24670)] = GetItemInfo(5565) or R["Infernal Stone"]		-- Inferno
		self.notifySpells[GetSpellInfo(18540)] = GetItemInfo(16583) or R["Demonic Figurine"]	-- Ritual of Doom

	elseif (playerClass == "HUNTER") then
		classBuffs = {
			{id = 19506, o = 1, duration = -1, who = "self", c = "FFFFFF"},					-- Trueshot Aura
			{id = 34074, o = 3, duration = -1, who = "self", dup = 1, c = "B080FF"},		-- Aspect of the Viper
			{id = 27044, o = 4, duration = -1, who = "self", dup = 1, c = "4090FF"},		-- Aspect of the Hawk
			{id = 61846, o = 5, duration = -1, who = "self", dup = 1, c = "808090"},		-- Aspect of the Dragonhawk
			{id = 5118, o = 6, duration = -1, who = "self", dup = 1, c = "FFFF80", auto = function() return IsResting() and z.db.profile.notresting and not IsMounted() end},	-- Aspect of the Cheetah
			{id = 13159, o = 7, duration = -1, who = "self", dup = 1, c = "B0B0B0"},		-- Aspect of the Pack
			{id = 27045, o = 8, duration = -1, who = "self", dup = 1, c = "20FF20"},		-- Aspect of the Wild
			{id = 13161, o = 9, duration = -1, who = "self", dup = 1, c = "FFA0FF"},		-- Aspect of the Beast
			{id = 13163, o = 10, duration = -1, who = "self", dup = 1, c = "808020"},		-- Aspect of the Monkey
		}

	elseif (playerClass == "SHAMAN") then
		local onEnableShield = function(key) 
			local btr = ZOMGBuffTehRaid
			if (btr) then
				local who = btr:ExclusiveTarget("EARTHSHIELD")
				if (who and UnitIsUnit(who, "player")) then
					btr:ModifyTemplate("EARTHSHIELD", nil)
				end
			end
		end

		local function getWaterShieldCharges()
			return LGT:UnitHasGlyph("player", (GetSpellInfo(58063))) and 4 or 3		-- Glyph of Water Shield
		end

		local function getLightningShieldCharges()
			return 3 + (LGT:UnitHasTalent("player", (GetSpellInfo(51525))) or 0) * 2		-- Static Shock
		end

		classBuffs = {
			{id = 49281, o = 1, dup = 2, charges = getLightningShieldCharges, duration = 10, who = "self", c = "8080FF", onEnable = onEnableShield},					-- Lightning Shield
			{id = 33736, o = 2, dup = 2, charges = getWaterShieldCharges, duration = 10, who = "self", noauto = true, c = "4040FF", onEnable = onEnableShield},	-- Water Shield
			{id = 8017,  o = 4, duration = 30, who = "weapon", c = "80FF80", dup = 1,				-- Rockbiter Weapon
				exclude = function() return IsUsableSpell(GetSpellInfo(25505)) end, -- Only use Rockbiter until we can use Windfury
			},
			{id = 25505, o = 4, duration = 30, who = "weapon", c = "FFFFFF", dup = 1},		-- Windfury Weapon
			{id = 25489, o = 5, duration = 30, who = "weapon", c = "FF8080", dup = 1},		-- Flametongue Weapon
			{id = 25500, o = 6, duration = 30, who = "weapon", c = "8080FF", dup = 1},		-- Frostbrand Weapon
			{id = 51993, o = 7, duration = 30, who = "weapon", c = "FFFF80", dup = 1},		-- Earthliving Weapon
		}
		self.reagents = {
			[GetItemInfo(17030) or R["Ankh"]] = {10, 1, 50, minLevel = 30},
		}
		self.notifySpells = {
			[GetSpellInfo(27740)] = GetItemInfo(17030) or R["Ankh"],										-- Reincarnation
		}

	elseif (playerClass == "WARRIOR") then
		classBuffs = {
			{id = 2048, o = 1, duration = 2, dup = 1, who = "self", c = "FF4040", checkdups = true},		-- Battle Shout
			{id = 469, o = 2, duration = 2, dup = 1, who = "self", c = "40FF40", checkdups = true},			-- Commanding Shout
			{id = 18499, o = 4, duration = 0.165, who = "self", noauto = true, c = "FFFF40"},				-- Berserker Rage
			{id = 29131, o = 5, duration = 0.165, who = "self", noauto = true, c = "FF0000"},				-- Bloodrage
		}

	elseif (playerClass == "ROGUE") then
		classBuffs = {
			{id = 41189, o = 1, dup = 1, duration = 60, who = "weapon", c = "40F040", sequence = {"", " II", " III", " IV", " V", " VI", " VII", " VIII", " IX"}},	-- Instant Poison
			{id = 43581, o = 2, dup = 1, duration = 60, who = "weapon", c = "40E040", sequence = {"", " II", " III", " IV", " V", " VI", " VII", " VIII", " IX"}},	-- Deadly Poison
			{id = 3408, o = 3, dup = 1, duration = 60, who = "weapon", c = "40C020"},																-- Crippling Poison
			{id = 5761, o = 4, dup = 1, duration = 60, who = "weapon", c = "40B040"},																-- Mind-numbing Poison
			{id = 43461, o = 5, dup = 1, duration = 60, who = "weapon", c = "A0A040", sequence = {"", " II", " III", " IV", " V", " VI", " VII"}},					-- Wound Poison
			{id = 57982, o = 6, dup = 1, duration = 60, who = "weapon", c = "209080", sequence = {"", " II"}},										-- Anesthetic Poison
		}
		self.reagents = {
			[6947] = {20, 1, 100, minLevel = 20, maxLevel = 27},			-- Instant Poison I
			[6949] = {20, 1, 100, minLevel = 28, maxLevel = 35},			-- Instant Poison II
			[6950] = {20, 1, 100, minLevel = 36, maxLevel = 43},			-- Instant Poison III
			[8926] = {20, 1, 100, minLevel = 44, maxLevel = 51},			-- Instant Poison IV
			[8927] = {20, 1, 100, minLevel = 52, maxLevel = 59},			-- Instant Poison V
			[8928] = {20, 1, 100, minLevel = 60, maxLevel = 67},			-- Instant Poison VI
			[21927]= {20, 1, 100, minLevel = 68, maxLevel = 72},			-- Instant Poison VII
			[43230]= {20, 1, 100, minLevel = 73, maxLevel = 78},			-- Instant Poison VIII
			[43231]= {20, 1, 100, minLevel = 79, maxLevel = 85},			-- Instant Poison IX

			[2892] = {20, 1, 100, minLevel = 30, maxLevel = 37},			-- Deadly Poison I
			[2893] = {20, 1, 100, minLevel = 38, maxLevel = 45},			-- Deadly Poison II
			[8984] = {20, 1, 100, minLevel = 46, maxLevel = 53},			-- Deadly Poison III
			[8985] = {20, 1, 100, minLevel = 54, maxLevel = 59},			-- Deadly Poison IV
			[20844]= {20, 1, 100, minLevel = 60, maxLevel = 61},			-- Deadly Poison V
			[22053]= {20, 1, 100, minLevel = 62, maxLevel = 69},			-- Deadly Poison VI
			[22054]= {20, 1, 100, minLevel = 70, maxLevel = 75},			-- Deadly Poison VII
			[43232]= {20, 1, 100, minLevel = 76, maxLevel = 79},			-- Deadly Poison VIII
			[43233]= {20, 1, 100, minLevel = 80, maxLevel = 87},			-- Deadly Poison IX

			[10918]= {20, 1, 100, minLevel = 32, maxLevel = 39},			-- Wound Poison I
			[10920]= {20, 1, 100, minLevel = 40, maxLevel = 47},			-- Wound Poison II
			[10921]= {20, 1, 100, minLevel = 48, maxLevel = 55},			-- Wound Poison III
			[10922]= {20, 1, 100, minLevel = 56, maxLevel = 63},			-- Wound Poison IV
			[22055]= {20, 1, 100, minLevel = 64, maxLevel = 71},			-- Wound Poison V
			[43234]= {20, 1, 100, minLevel = 72, maxLevel = 77},			-- Wound Poison VI
			[43235]= {20, 1, 100, minLevel = 78, maxLevel = 85},			-- Wound Poison VII

			[21835]= {20, 1, 100, minLevel = 68, maxLevel = 76},			-- Anesthetic Poison
			[43237]= {20, 1, 100, minLevel = 77, maxLevel = 85},			-- Anesthetic Poison II

			[3775] = {20, 1, 100, minLevel = 20},							-- Crippling Poison
			[5237] = {20, 1, 100, minLevel = 20},							-- Mind-numbing Poison
		}

	elseif (playerClass == "PALADIN") then
		local function skipFunc()
			return zs.db.char.useauto and IsMounted() and not z.db.profile.notmounted
		end

		classBuffs = {
			{id = 21084, o = 1,  duration = 30, who = "self", dup = 1, noauto = true, c = "C0C0FF", rebuff = L["Seals"]},	-- Seal of Righteousness
			{id = 20375, o = 2,  duration = 30, who = "self", dup = 1, noauto = true, c = "FFD010", rebuff = L["Seals"]},	-- Seal of Command
			{id = 20166, o = 3,  duration = 30, who = "self", dup = 1, noauto = true, c = "6070FF", rebuff = L["Seals"]},	-- Seal of Wisdom
			{id = 20165, o = 4,  duration = 30, who = "self", dup = 1, noauto = true, c = "FFA040", rebuff = L["Seals"]},	-- Seal of Light
			{id = 53736, o = 5,  duration = 30, who = "self", dup = 1, noauto = true, c = "FFD010", rebuff = L["Seals"]},	-- Seal of Corruption
			{id = 31801, o = 6,  duration = 30, who = "self", dup = 1, noauto = true, c = "FFD010", rebuff = L["Seals"]},	-- Seal of Vengeance
			{id = 20164, o = 7,  duration = 30, who = "self", dup = 1, noauto = true, c = "A0FFA0", rebuff = L["Seals"]},	-- Seal of Justice
			{id = 25780, o = 11, duration = 30, who = "self", c = "FFD020", cancancel = true},								-- Righteous Fury
			{id = 27179, o = 12, duration = 0.165, who = "self", c = "FFF0E0", noauto = true},								-- Holy Shield
			{id = 27149, o = 14, duration = -1, who = "self", dup = 2, mounted = true, c = "8090C0", checkdups = true, skip = skipFunc},		-- Devotion Aura
			{id = 27150, o = 15, duration = -1, who = "self", dup = 2, mounted = true, c = "D040D0", checkdups = true, skip = skipFunc},		-- Retribution Aura
			{id = 19746, o = 16, duration = -1, who = "self", dup = 2, mounted = true, c = "C020E0", checkdups = true, skip = skipFunc},		-- Concentration Aura
			{id = 27151, o = 17, duration = -1, who = "self", dup = 2, mounted = true, c = "8020FF", checkdups = true, skip = skipFunc},		-- Shadow Resistance Aura
			{id = 27152, o = 18, duration = -1, who = "self", dup = 2, mounted = true, c = "2020FF", checkdups = true, skip = skipFunc},		-- Frost Resistance Aura
			{id = 27153, o = 19, duration = -1, who = "self", dup = 2, mounted = true, c = "E06020", checkdups = true, skip = skipFunc},		-- Fire Resistance Aura
			{id = 32223, o = 20, duration = -1, who = "self", dup = 2, mounted = true, c = "D0D060", noauto = true, auto = function(v) return IsMounted() end, c = "FFFFFF"},	-- Crusader Aura
			{id = 54428, o = 22, duration = 0.25, who = "self", c = "FFFF70", noauto = true,		-- Divine Plea
				skip = function()
					local mana, maxmana = UnitMana("player"), UnitManaMax("player")
					return (mana / maxmana) > 0.75					-- Skip if over 75% mana
				end
			},
		}

		if (tonumber((select(2, GetBuildInfo()))) < 10000) then
			tinsert(classBuffs, 8, {id = 31892, o = 8,  duration = 30, who = "self", dup = 1, noauto = true, c = "FFA0A0", rebuff = L["Seals"]})	-- Seal of Blood
			tinsert(classBuffs, 9, {id = 53720, o = 9,  duration = 30, who = "self", dup = 1, noauto = true, c = "FFA0A0", rebuff = L["Seals"]})	-- Seal of the Martyr
		end

		self.notifySpells = {
			[GetSpellInfo(19752)] = GetItemInfo(17033) or R["Symbol of Divinity"],		-- Divine Intervention
		}
	elseif (playerClass == "DEATHKNIGHT") then
		local strOfEarth = GetSpellInfo(8076)										-- Strength of Earth
		classBuffs = {
			{id = 49222, o = 1, duration = 5, who = "self", c = "209020"},			-- Bone Armor
			{id = 49142, o = 2, duration = 30, who = "weapon", c = "204090"},		-- Frozen Rune Weapon
			{id = 57623, o = 3, duration = 2, who = "self", c = "808080",			-- Horn of Winter
				skip = function()
					return UnitBuff("player", strOfEarth) ~= nil
				end,
			},
		}
		self.notifySpells = {
			[GetSpellInfo(46584)] = GetItemInfo(37201) or R["Corpse Dust"],			-- Raise Dead
		}
		self.reagents = {
			[GetItemInfo(37201) or R["Corpse Dust"]]	= {20, 1, 200},
		}
	end

	local errors
	if (classBuffs) then
		self.classBuffs = {}
		for i,data in pairs(classBuffs) do
			if (data.id) then
				local name, _, icon = GetSpellInfo(data.id)
				if (name) then
					self.classBuffs[name] = data
				else
					-- Store the errors now till end, so the rest will still function even with unknown spells
					errors = (errors and (errors .. ", ") or "") .. tostring(data.id)
				end
			else
				self.classBuffs[i] = data
			end
		end
	else
		self.classBuffs = nil
		return
	end

	local altList = new()
	for k,v in pairs(self.classBuffs) do
		tinsert(altList, v)
	end

	local setLearnable = not self.db.char.notlearnable
	if (setLearnable) then
		self.db.char.notlearnable = {}
	end

	local rebuff = self.db.char.rebuff
	for k,v in pairs(self.classBuffs) do
		if (setLearnable) then
			if (v.noauto) then
				self.db.char.notlearnable[k] = true
			end
		end

		if (v.default and not not rebuff[k]) then
			rebuff[k] = v.default
		end

		if (v.who == "self" or v.who == "single" or v.who == "party") then
			--local t1, t2 = IsUsableSpell(k)
			local t1 = GetSpellCooldown(k)
			if (not t1) then	--not (t1 or t2)) then
				-- Remove any spells we don't have
				local o = v.o
				self.classBuffs[k] = nil

				for i = 1,#altList do
					if (altList[i].o > o) then
						altList[i].o = altList[i].o - 1
					end
				end
			end
		end
	end

	del(altList)

	self:MakeSpellOptions()
	self:MakeItemOptions()
	z:CheckForChange(self)

	if (errors) then
		error("No spell for spellID "..errors.." (class:".. playerClass ..")")
	end
end

-- OneOfYours
function zs:OneOfYours(spell)
	return self.classBuffs[spell]
end

-- GetSpellIcon
function zs:GetSpellIcon(spell)
	local info = self.classBuffs[spell]
	if (info) then
		local name, _, icon = GetSpellInfo(info.id)
		return icon
	else
		local icon = select(10, GetItemInfo(spell))
		if (icon) then
			return icon
		end
	end
end

local strClasses = {PALADIN = true, WARRIOR = true, DEATHKNIGHT = true}
local casterClasses = {MAGE = true, WARLOCK = true, PRIEST = true}

-- MakeSpellOptions
do
	local function setFunc(k)
		-- Untick any marked as 'dup' (Mutually exclusive buffs, such as Paladin Seals & Hunter Aspects)
		local b = zs.classBuffs[k]
		if (b) then
			local old = template[k]
			if (b.dup) then
				for i,s in pairs(zs.classBuffs) do
					if (b.dup == s.dup) then
						zs:ModifyTemplate(i, nil)
					end
				end
			end
			zs:ModifyTemplate(k, not old)
		end
		z:SetupForSpell()
		zs:CheckBuffs()
	end

	local function getLearnable(k)
		return not zs.db.char.notlearnable or not zs.db.char.notlearnable[k]
	end

	local function setLearnable(k, v)
		if (v == false) then
			if (not zs.db.char.notlearnable) then
				zs.db.char.notlearnable = {}
			end
			zs.db.char.notlearnable[k] = true
		else
			if (zs.db.char.notlearnable) then
				zs.db.char.notlearnable[k] = nil
				-- Don't nil this array, else next time we startup the defaults will be reset from the noauto values
			end
		end
	end

	local function getCharges(k)
		return zs.db.char.charges and zs.db.char.charges[k] or 0
	end

	local function setCharges(k, v)
		if (v > 0) then
			if (not zs.db.char.charges) then
				zs.db.char.charges = {}
			end
			zs.db.char.charges[k] = v
		else
			zs.db.char.charges[k] = nil
			if (not next(zs.db.char.charges)) then
				zs.db.char.charges = nil
			end
		end
	end

	function zs:MakeSpellOptions()
		local any
		local args = {}

		local order = 1
		local notDone, needBreak
		for i = 1,25 do
			local done
			for k,v in pairs(self.classBuffs) do
				if (v.o == i and (v.who == "self" or v.who == "single" or v.who == "party")) then
					if (not v.exclude or not v.exclude()) then
						if (needBreak and any) then
							args["header"..order] = {
								type = "header",
								name = " ",
								order = order,
							}
							order = order + 1
						end
						needBreak = nil

						any = true
						notDone = nil
						done = true
						local cName
						if (v.c) then
							cName = format("|cFF%s%s|r", v.c, k)
						else
							cName = k
						end

						args[k] = {
							type = "group",
							name = cName,
							desc = cName,
							order = order,
							isChecked = function() return template[k] end,
							onClick = setFunc,
							passValue = k,
							args = {
								header = {
									type = "header",
									name = cName,
									order = 1,
								},
								nolearn = {
									type = "toggle",
									name = L["Learnable"],
									desc = L["Remember this spell when it's cast manually?"],
									order = 100,
									get = getLearnable,
									set = setLearnable,
									passValue = k,
								}
							}
						}

						if ((v.duration or 0) > 0) then
							args[k].args.rebuff = {
								type = "range",
								name = L["Expiry Prelude"],
								desc = format(L["Rebuff prelude for %s (0=Module default)"], v.rebuff or cName),
								func = timeFunc,
								order = 10,
								get = getPrelude,
								set = setPrelude,
								passValue = v.rebuff or k,
								min = 0,
								max = (v.duration / 2) * 60,
								step = (v.duration <= 60 and 1) or 5,
								bigStep = (v.duration <= 60 and 5) or 60,
							}
						end

						local c = v.charges
						if (c) then
							if (type(c) == "function") then
								c = c()
							end
							args[k].args.charges = {
								type = "range",
								name = L["Minimum Charges"],
								desc = L["Rebuff if number of charges left is less than defined amount"],
								func = timeFunc,
								order = 20,
								get = getCharges,
								set = setCharges,
								passValue = v.rebuff or k,
								min = 0,
								max = c,
								step = 1,
							}
						end

						order = order + 1
						break
					end
				end
			end

			if (not done and not notDone) then
				needBreak = true
			end
		end

		if (any) then
			if (not zs.options.args.spells) then
				zs.options.args.spells = {
					type = "group",
					name = L["Class Spells"],
					desc = L["Class spell configuration"],
					order = 1,
					hidden = function() return not zs:IsModuleActive() end,
					args = {
					}
				}
			end
			zs.options.args.spells.args = args
		end

		del(list)

		local alc = GetSpellInfo(51304)
		if (GetSpellInfo(alc) and GetItemCount(47499, true) > 0) then
			-- Flask of the North tracking
			self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

			local m = zs.options.args.flaskOfNorth
			if (not m) then
				local function getFlask(v)
					return zs.db.char.flask == v
				end
				local function setFlask(v, val)
					zs.db.char.flask = val and v or nil
					z:SetupForSpell()
					zs:CheckBuffs()
				end

				m = {
					type = "group",
					name = L["Flask of the North"],
					desc = L["Special handling for Flask of the North"],
					order = 5,
					hidden = function() return not zs:IsModuleActive() end,
					args = {
						ap = {
							type = "toggle",
							name = ATTACK_POWER_TOOLTIP,		-- Attack Power
							desc = ATTACK_POWER_TOOLTIP,
							order = 10,
							hidden = function() return casterClasses[playerClass] end,
							get = getFlask,
							set = setFlask,
							passValue = "ap",
						},
						str = {
							type = "toggle",
							name = SPELL_STAT1_NAME,			-- Strength
							desc = SPELL_STAT1_NAME,
							order = 20,
							hidden = function() return not strClasses[playerClass] end,
							get = getFlask,
							set = setFlask,
							passValue = "str",
						},
						spell = {
							type = "toggle",
							name = ITEM_MOD_SPELL_POWER_SHORT,	-- Spell Power
							desc = ITEM_MOD_SPELL_POWER_SHORT,
							order = 30,
							hidden = function() return UnitPowerMax("player", 0) == 0 end,
							get = getFlask,
							set = setFlask,
							passValue = "spell",
						},
						spacer = {
							type = 'header',
							name = " ",
							order = 50,
						},
						rebuff = {
							type = "range",
							name = L["Expiry Prelude"],
							desc = L["Expiry prelude for flasks"],
							func = timeFunc,
							order = 60,
							get = getPrelude,
							set = setPrelude,
							passValue = "flask",
							min = 0,
							max = 15 * 60,
							step = 5,
							bigStep = 60,
						},
					}
				}
				self.options.args.flaskOfNorth = m
			end
		else
			if (self:IsEventRegistered("COMBAT_LOG_EVENT_UNFILTERED")) then
				self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
			end
			self.options.args.flaskOfNorth = nil
			self.db.char.activeFlaskOfTheNorth = nil
		end
	end
end

-- MakeItemOptions
function zs:MakeItemOptions()
	local any
	local args = {
	}

	local function getFunc(k)
		local a,b = strmatch(k, "^(%a+):(.+)$")
		if (a == "mainhand") then
			return b == template.mainhand
		elseif (a == "offhand") then
			return b == template.offhand
		end
	end
	local function setFunc(k,v)
		local a,b = strmatch(k, "^(%a+):(.+)$")
		self.activeEnchant = nil
		self:ModifyTemplate(a, v and b)
	end

	local function hideOHWeapon()
		return GetInventoryItemLink("player", 17) == nil
	end

	for k,v in pairs(self.classBuffs) do
		if (v.who == "weapon") then
			local spell, item
			local t1, t2 = IsUsableSpell(k)
			spell = (t1 or t2) and k
			if (not spell) then
				item = GetExistingItemWithSequence(k,v)
			end
			if (spell or item) then
				local e1, e2, e3
				e1 = "mainhand:"..k
				e2 = "offhand:"..k
				e3 = "both:"..k

				local spellIcon
				if (item) then
					spellIcon = select(10, GetItemInfo(item))
				else
					spellIcon = v.id and select(3, GetSpellInfo(v.id))
				end

				any = true
				args[k] = {
					type = "group",
					name = spell or item,
					desc = spell or item,
					order = v.o,
					get = function(k) return template[spell or item] end,
					set = function(k,v) end,
					icon = spellIcon,
					passValue = k,
					args = {
						mainhand = {
							type = "toggle",
							name = L["Main Hand"],
							desc = L["Use this item or spell on the main hand weapon"],
							order = 1,
							get = getFunc,
							set = setFunc,
							passValue = e1,
						},
						offhand = {
							type = "toggle",
							name = L["Off Hand"],
							desc = L["Use this item or spell on the off hand weapon"],
							order = 1,
							hidden = hideOHWeapon,
							get = getFunc,
							set = setFunc,
							passValue = e2,
						},
					}
				}
			end
		end
	end

	if (any) then
		args.learnable = {
			type = "toggle",
			name = L["Learnable"],
			desc = L["Learnable"],
			order = 1000,
			get = function() return self.db.char.itemsLearnable end,
			set = function(k,n) self.db.char.itemsLearnable = n end,
		}

		if (not zs.options.args.item) then
			zs.options.args.item = {
				type = "group",
				name = L["Items"],
				desc = L["Item configuration"],
				order = 2,
				hidden = function() return not zs:IsModuleActive() end,
				args = {
				}
			}
		end
		zs.options.args.item.args = args
	end

	del(list)
end

-- ValidateTemplate
-- Cleanup a bug that would put any casted spell into the template..
function zs:ValidateTemplate(template)
	if (template) then
		for key in pairs(template) do
			local buff = self.classBuffs[key]
			if (not buff) then
				if (key ~= "modified" and key ~= "mainhand" and key ~= "offhand") then
					template[key] = nil
				end
			elseif (buff.who == "weapon") then
				template[key] = nil
			end
		end
	end
end

-- SelectTemplate
function zs:OnSelectTemplate(templateName)
	template = self:GetTemplates().current
	self:ValidateTemplate()

	for key,buff in pairs(self.classBuffs) do
		if (template[key]) then
			if (buff.onEnable) then
				buff.onEnable(key)
			end
		end
	end
end

-- OnModifyTemplate
function zs:OnModifyTemplate(key, value)
	if (value) then
		local buff = self.classBuffs[key]
		if (buff and buff.dup) then
			for k,v in pairs(self.classBuffs) do
				if (v.dup == buff.dup and k ~= key) then
					self:ModifyTemplate(k, nil)
				end
			end
		end

		local buff = self.classBuffs[key]
		if (buff and buff.onEnable) then
			buff.onEnable(key)
		end
	end

	if (playerClass == "PALADIN") then
		for key2,info in pairs(z.auras) do
			if (info.name == key) then
				-- New aura set, notify blessings manager
				local aura = self:GetPaladinAuraKey()
				local bm = ZOMGBlessingsManager
				if (bm) then
					bm:OnReceiveAura(playerName, aura)
				end
				z:SendCommMessage("GROUP", "AURA", aura)
				break
			end
		end
	end
end

-- SpellCastFailed
function zs:SpellCastFailed(spell, rank, manual)
	if (not manual) then
		self.activeEnchant = nil
		self:CheckBuffs()
	end
end

-- ChecksAfterItemChanges
function zs:ChecksAfterItemChanges()
	self.activeEnchant = nil
	self:CheckBuffs()
	self:MakeItemOptions()
end

-- UNIT_INVENTORY_CHANGED
function zs:UNIT_INVENTORY_CHANGED(unit)
	if (unit == "player") then
		self:CancelScheduledEvent("ZOMGBuffs_ChecksAfterItemChanges")
		if (not any and minTimeLeft) then
			self:ScheduleEvent("ZOMGBuffs_ChecksAfterItemChanges", self.ChecksAfterItemChanges, 5, self)
		end
	
		if (self.checkReagentUsage) then
			if (self.checkReagentUsage.time + 5 >= GetTime()) then
				local count = GetItemCount(self.checkReagentUsage.reagent)
	
				if (count < self.checkReagentUsage.count) then
					local colourCount
					if (count < 2) then
						colourCount = "|cFFFF4040"
					elseif (count < 5) then
						colourCount = "|cFFFFFF40"
					else
						colourCount = "|cFF40FF40"
					end
	
					self:Print(L["%s, %s%d|r %s remain"], self.checkReagentUsage.spell, colourCount, count, self.checkReagentUsage.reagent)
					self.checkReagentUsage = del(checkReagentUsage)
				end
			else
				self.checkReagentUsage = del(checkReagentUsage)
			end
		end
	end
end

-- OnSpellsChanged
function zs:OnSpellsChanged()
	playerName = UnitName("player")
	playerClass = select(2, UnitClass("player"))
	playerGUID = UnitGUID("player")
	self:GetClassBuffs()
end

-- SpellCastSucceeded
function zs:SpellCastSucceeded(spell, rank, target, manual)
	if (self.db.char.itemsLearnable) then
		local ospell = spell
		local buff = self.classBuffs[spell]
		if (not buff and target == "") then
			rank = tonumber(strmatch(rank, "(%d+)"))
			if (rank) then
				for name,info in pairs(self.classBuffs) do
					local strrank = info.sequence and info.sequence[rank]
					if (strrank) then
						if (name .. strrank == spell) then
							spell = name
							buff = info
							break
						end
					end
				end
			end
		end
		if (buff and buff.who == "weapon") then
			if (z.icon.mod == self) then
				z:SetupForSpell()
			end
			self.activeEnchant = nil
		end

		if (manual) then
			if (z:CanLearn() and (not zs.db.char.notlearnable or not zs.db.char.notlearnable[spell])) then
				if (buff) then
					if (buff.who == "weapon") then
						--self:ModifyTemplate("mainhand", spell)
						--z:SetupForSpell()			-- Avoid race condition with weapon buffs not refreshing immediately
					else
						self:ModifyTemplate(spell, true)
					end
				end
			end
		end
	end

	-- Check for a spell used with a consumable reagent not covered in raid/blessings
	if (self.notifySpells and self.db.char.reagentNotices) then
		local found = self.notifySpells[spell]
		if (found) then
			local reagent
			if (type(found) == "table") then
				reagent = found[rank]
				if (not reagent) then
					reagent = found[#found]
				end
			else
				reagent = found
			end

			if (reagent) then
				self.checkReagentUsage = {
					reagent = reagent,
					spell = spell,
					time = GetTime(),
					count = GetItemCount(reagent)
				}
			end
		end
	end
end

-- GetPaladinAuraKey
function zs:GetPaladinAuraKey()
	if (playerClass == "PALADIN") then
		if (template) then
			for spell in pairs(template) do
				for key,info in pairs(z.auras) do
					if (info.name == spell) then
						return info.key
					end
				end
			end
		end
	end
end

-- SetPaladinAuraKey
function zs:SetPaladinAuraKey(key)
	local aura = key and z.auras[key]
	if (aura) then
		self:ModifyTemplate(aura.name, true)
	else
		local oldaura = self:GetPaladinAuraKey()
		if (oldaura) then
			self:ModifyTemplate(z.auras[oldaura].name, nil)
		end
	end
end

do
	-- Flask of the North tracking
	local flaskTypes = {
		[67016] = "spell",
		[67017] = "ap",
		[67018] = "str",
	}
	local events = {}

	function events:SPELL_AURA_APPLIED(spellId)
		local t = flaskTypes[spellId]
		if (t) then
			self.db.char.activeFlaskOfTheNorth = t
		end
	end

	function events:SPELL_AURA_REMOVED(spellId)
		if (flaskTypes[spellId]) then
			self.db.char.activeFlaskOfTheNorth = nil
		end
	end

	-- COMBAT_LOG_EVENT_UNFILTERED
	function zs:COMBAT_LOG_EVENT_UNFILTERED(timestamp, event, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, ...)
		if (sourceGUID == playerGUID) then
			local f = events[event]
			if (f) then
				f(self, ...)
			end
		end
	end
end

-- TooltipOnClick
function zs:TooltipOnClick(name)
	if (name) then
		if (name == "flask") then
			if (IsShiftKeyDown()) then
				self.db.char.flask = nil
			else
				local flask = new()
				local current = 0
				if (not casterClasses[playerClass]) then
					tinsert(flask, "ap")
					if (self.db.char.flask == "ap") then
						current = #flask
					end
				end
				if (strClasses[playerClass]) then
					tinsert(flask, "str")
					if (self.db.char.flask == "str") then
						current = #flask
					end
				elseif (UnitPowerMax("player", 0) > 0) then
					tinsert(flask, "spell")
					if (self.db.char.flask == "spell") then
						current = #flask
					end
				end

				current = current + 1
				if (current > #flask) then
					current = 0
				end

				self.db.char.flask = flask[current]

				z:SetupForSpell()
				zs:CheckBuffs()

				del(flask)
			end
		else
			if (IsShiftKeyDown()) then
				self:ModifyTemplate(name, nil)
			else
				local b
				if (name == "mainhand" or name == "offhand") then
					b = self.classBuffs[template[name]]
				else
					b = self.classBuffs[name]
				end

				local nextOne, firstOne, replaceTo
				local lowest = 99
				if (b and b.dup) then
					for find,s in pairs(self.classBuffs) do
						if (not s.exclude or s.exclude()) then
							if (b.dup == s.dup) then
								if (s.o < lowest) then
									lowest = s.o
									firstOne = find
								end
								if (s.o == b.o + 1) then
									replaceTo = find
								end
							end
						end
					end
				end

				if (replaceTo or firstOne) then
					if (name == "mainhand" or name == "offhand") then
						self.activeEnchant = nil
						self:ModifyTemplate(name, replaceTo or firstOne)
					else
						if (name ~= (replaceTo or firstOne)) then
							self:ModifyTemplate(name, nil)
							self:ModifyTemplate(replaceTo or firstOne, true)
						end
					end
				end
			end
		end
	end
end

-- AddItem
function zs:AddItem(cat, which, item)
	local name = (which == "mainhand" and L["Main Hand"]) or L["Off Hand"]
	local itemName = GetExistingItemWithSequence(item, self.classBuffs[item])
	local checkIcon
	if (itemName) then
		item = itemName
		checkIcon = select(10, GetItemInfo(itemName))
	end

	cat:AddLine(
		"text", name,
		"textR", 0.5,
		"textG", 1,
		"textB", 0.5,
		"text2", item,
		"text2R", 1,
		"text2G", 1,
		"text2B", 0.5,
		"func", "TooltipOnClick",
		"arg1", self,
		"arg2", which,
		"hasCheck", checkIcon and true,
		"checked", checkIcon and true,
		"checkIcon", checkIcon
	)
end

-- SortedBuffList
function zs:SortedBuffList()
	local list = new()
	for name,info in pairs(self.classBuffs) do
		if (info.who == "self") then
			local insertPos = #list + 1
			for i,key in ipairs(list) do
				if (self.classBuffs[key].who == "self" and self.classBuffs[key].o > info.o) then
					insertPos = i
					break
				end
			end
			tinsert(list, insertPos, name)
		end
	end
	return list
end

local flaskTypes = {
	ap = ATTACK_POWER_TOOLTIP,			-- Attack Power
	str = SPELL_STAT1_NAME,				-- Strength
	spell = ITEM_MOD_SPELL_POWER_SHORT,	-- Spell Power
}

-- TooltipUpdate
function zs:TooltipUpdate(cat)
	if (template and self.classBuffs) then
		cat:AddLine('text', " ")
		cat:AddLine(
			"text", L["Self Buffs Template: "].."|cFFFFFFFF"..(zs:GetSelectedTemplate() or L["none"]),
			"text2", (template and template.modified and "|cFFFF4040"..L["(modified)"].."|r") or ""
		)

		if (template.mainhand) then
			self:AddItem(cat, "mainhand", template.mainhand)
		end
		if (template.offhand) then
			self:AddItem(cat, "offhand", template.offhand)
		end

		local list = self:SortedBuffList()
		for i,key in ipairs(list) do
			if (template[key]) then
				local buff = self.classBuffs[key]
				local checkIcon = buff.id and select(3, GetSpellInfo(buff.id))
				local c = "|cFF"..((buff and buff.c) or "FFFF80")

				cat:AddLine(
					"text", c..key,
					"func", "TooltipOnClick",
					"arg1", self,
					"arg2", key,
					"hasCheck", checkIcon and true,
					"checked", checkIcon and true,
					"checkIcon", checkIcon
				)
			end
		end
		del(list)

		local alc = GetSpellInfo(51304)
		if (GetSpellInfo(alc) and GetItemCount(47499) > 0) then
			cat:AddLine(
				"text", GetSpellInfo(67016),
				"textR", 0,
				"textG", 0.44,
				"textB", 0.87,
				"text2", flaskTypes[self.db.char.flask] or NONE,
				"text2R", 1,
				"text2G", 1,
				"text2B", 1,
				"func", "TooltipOnClick",
				"arg1", self,
				"arg2", "flask",
				"hasCheck", true,
				"checked", true,
				"checkIcon", select(3, GetSpellInfo(67016))
			)
		end
	end
end

-- OnModuleInitialize
function zs:OnModuleInitialize()
	self.db = z:AcquireDBNamespace("SelfBuffs")
	z:RegisterDefaults("SelfBuffs", "char", {
		useauto = true,
		itemsLearnable = true,
		templates = {},
		reagents = {},
		combatnotice = true,
		rebuff = {
			default = 30,
			[L["Seals"]] = 60,
		},
		reagentNotices = true,
	} )

	z:RegisterChatCommand({"/zomgself", "/zomgselfbuffs"}, zs.options)
	self.OnMenuRequest = self.options
	z.options.args.ZOMGSelfBuffs = self.options

	template = self:GetTemplates().current
	if (not template) then
		template = {}
		self:GetTemplates().current = template
	end

	z:RegisterBuffer(self, 1)

	self.OnModuleInitialize = nil
end

-- OnResetDB
function zs:OnResetDB()
	template = self:GetTemplates().current
end

-- OnModuleEnable
function zs:OnModuleEnable()
	self:OnResetDB()

	playerName = UnitName("player")
	playerClass = select(2, UnitClass("player"))
	playerGUID = UnitGUID("player")

	if (playerClass == "ROGUE") then
		self.db.char.reagents.flashpowder = nil

		if (not self.db.char.hfbdone) then
			-- New default for Hunger for Blood
			self.db.char.hfbdone = true
			self.db.char.rebuff[GetSpellInfo(51662)] = 5
		end
	end

	self:OnSpellsChanged()
	z:MakeOptionsReagentList()

	self:RegisterEvent("UNIT_INVENTORY_CHANGED")
	z:CheckForChange(self)

	self:ValidateTemplate(template)

	local alc = GetSpellInfo(51304)
	if (GetSpellInfo(alc) and GetItemCount(47499, true) > 0) then
		-- Flask of the North tracking
		self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	end
end

-- OnModuleDisable
function zs:OnModuleDisable()
	z:CheckForChange(self)
	self.classBuffs = nil
	self.activeEnchant = nil
end
