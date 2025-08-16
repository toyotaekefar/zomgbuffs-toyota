local L = LibStub("AceLocale-2.2"):new("ZOMGBuffs")
local Sink, SinkVersion = LibStub("LibSink-2.0", true)
local SM = LibStub("LibSharedMedia-3.0")

local wowVersion = tonumber((select(2, GetBuildInfo())))

BINDING_HEADER_ZOMGBUFFS = L["TITLECOLOUR"]
BINDING_NAME_ZOMGBUFFS_PORTAL = L["PORTALZ_HOTKEY"]

local tablet = LibStub("Tablet-2.0")
local dewdrop = LibStub("Dewdrop-2.0")
local LGT = LibStub("LibGroupTalents-1.0")
local FrameArray = {}
local AllFrameArray = {}
local secureCalls = {}
local playerClass, playerName
local buffClass, lastCheckFail

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

local classIcons = {
	WARRIOR	= "Interface\\Icons\\Ability_Warrior_BattleShout",
	ROGUE	= "Interface\\Icons\\Ability_Stealth",
	HUNTER	= "Interface\\Icons\\Ability_TrueShot",
	DRUID	= "Interface\\Icons\\Spell_Nature_Regeneration",
	SHAMAN	= "Interface\\Icons\\Spell_Nature_SkinofEarth",
	PALADIN	= "Interface\\Icons\\Spell_Holy_FistOfJustice",
	PRIEST	= "Interface\\Icons\\Spell_Holy_WordFortitude",
	MAGE	= "Interface\\Icons\\Spell_Holy_MagicalSentry",
	WARLOCK	= "Interface\\Icons\\Spell_Shadow_DemonBreath",
	DEATHKNIGHT = "Interface\\Icons\\Spell_DeathKnight_Subversion",
}

local classOrder = {"WARRIOR", "DEATHKNIGHT", "ROGUE", "HUNTER", "DRUID", "SHAMAN", "PALADIN", "PRIEST", "MAGE", "WARLOCK"}
if (type(CLASS_BUTTONS) == "table") then
	for class in pairs(CLASS_BUTTONS) do
		local got
		for i = 1,#classOrder do
			if (classOrder[i] == class) then
				got = true
			end
		end
		if (not got) then
			if (class ~= "PET" and class ~= "MAINASSIST" and class ~= "MAINTANK") then
				tinsert(classOrder, class)
			end
		end
	end
end
local classIndex = {}
for k,v in pairs(classOrder) do classIndex[v] = k end

local CellOnEnter, IconOnEnter, CellOnLeave, CellBarOnUpdate, CellOnMouseUp, CellOnMouseDown

local specChangers = {
	[GetSpellInfo(63645) or "Fake"] = true,			-- Activate Primary Spec
	[GetSpellInfo(63644) or "Fake"] = true,			-- Activate Secondary Spec
}

-- ShortDesc
local function ShortDesc(a)
	if (a == "MARK") then		return L["Mark"]
	elseif (a == "STA") then	return L["Stamina"]
	elseif (a == "INT") then	return L["Intellect"]
	elseif (a == "SHADOWPROT") then return L["Shadow Protection"]
	elseif (a == "SPIRIT") then	return L["Spirit"]
	elseif (a == "BLESSINGS") then	return L["Blessings"]
	end
end

local kiru = GetSpellInfo(46302)			-- Counts as INT (Ignoring STA because talented is still better)
local dalbless1 = GetSpellInfo(61024)		-- Dalaran Intellect
local dalbless2 = GetSpellInfo(61316)		-- Dalaran Brilliance
local felint = GetSpellInfo(57567)			-- Fel Intelligence
local battleshout = GetSpellInfo(6673)		-- Battle Shout
local manaspring = GetSpellInfo(58777)		-- Mana Spring (totem buff)

local new, del, copy, deepDel
do
--[===[@debug@
	local errorTable = setmetatable({},{
		__newindex = function(self) error("Attempt to assign to a recycled table (2)") end,
		__index = function(self) return "bad table" end,
	})
	local protect = {
		__newindex = function(self) error("Attempt to assign to a recycled table") end,
		__index = function(self) return errorTable end,		--error("Attempt to access a recycled table") end,
	}
--@end-debug@]===]

	local next, select, pairs, type = next, select, pairs, type
	local list = setmetatable({},{__mode='k'})

	function new(...)
		local t = next(list)
		if t then
			list[t] = nil
--[===[@debug@
			setmetatable(t, nil)
			assert(not next(t))
--@end-debug@]===]
			for i = 1, select('#', ...) do
				t[i] = select(i, ...)
			end
			return t
		else
			t = {...}
			return t
		end
	end
	function del(t)
		if (t) then
			setmetatable(t, nil)

			wipe(t)
			t[''] = true
			t[''] = nil
			list[t] = true
--[===[@debug@
			assert(not next(t))
			setmetatable(t, protect)
--@end-debug@]===]
		end
	end
	function deepDel(t)
		if (t) then
			setmetatable(t, nil)

			for k,v in pairs(t) do
				if type(v) == "table" then
					deepDel(v)
				end
				t[k] = nil
			end
			t[''] = true
			t[''] = nil
			list[t] = true
--[===[@debug@
			assert(not next(t))
			setmetatable(t, protect)
--@end-debug@]===]
		end
	end
	function copy(old)
		if (not old) then
			return
		end
		local n = new()
		for k,v in pairs(old) do
			if (type(v) == "table") then
				n[k] = copy(v)
			else
				n[k] = v
			end
		end
		setmetatable(n, getmetatable(old))
		return n
	end
end

ZOMGBuffs = LibStub("AceAddon-2.0"):new("AceConsole-2.0", "AceDB-2.0", "AceEvent-2.0", "AceModuleCore-2.0", "AceHook-2.1", "FuBarPlugin-2.0", "AceComm-2.0")
ZOMGBuffs:SetModuleMixins("AceEvent-2.0", "AceHook-2.1")
local z = ZOMGBuffs
local btr
local bm

if (Sink) then
	Sink:Embed(z)
end

z.new, z.del, z.deepDel, z.copy = new, del, deepDel, copy
z.classOrder = classOrder
z.classIndex = classIndex
z.manaClasses = {HUNTER = true, DRUID = true, SHAMAN = true, PALADIN = true, PRIEST = true, MAGE = true, WARLOCK = true}
if (select(4, GetBuildInfo()) >= 40000) then
	z.manaClasses.HUNTER = nil
end

z.blessingColour = {BOK = "|cFFFF80FF", BOM = "|cFFFF5050", BOL = "|cFF80FF80", BOS = "|cFFFFA0A0", BOW = "|cFF8080FF", SAC = "|cFFFF0000", SAN = "|cFF4040C0", BOF = "|cFFFFCC19", BOP = "|cFF00FF00"}
do
	local allBuffs = {
		{opt = "mark",	ids = {26990, 26991},	class = "DRUID",	type = "MARK", runescroll = true},		-- Mark of the Wild, Gift of the Wild
		{opt = "sta",	ids = {25389, 25392, 69377},	class = "PRIEST",	type = "STA", runescroll = true},	-- Power Word: Fortitude, Prayer of Fortitude, Fortitude
		{opt = "int",	ids = {27126, 27127},	class = "MAGE",		type = "INT", manaOnly = true},	-- Arcane Intellect, Arcane Brilliance
		{opt = "spirit",ids = {25312, 32999},	class = "PRIEST",	type = "SPIRIT", manaOnly = true},	-- Divine Spirit, Prayer of Spirit
		{opt = "shadow",ids = {25433, 39374},	class = "PRIEST",	type = "SPIRIT"},	-- Shadow Protection, Prayer of Shadow Protection
		{opt = "food",	ids = {46899, 433},							type = "FOOD"},		-- Well Fed (Food = 433)
		{opt = "flask",												type = "FLASK",		icon = "Interface\\Icons\\INV_Potion_1"},
	}

	z.buffsLookup = {}
	z.allBuffs = {}
	for i,info in pairs(allBuffs) do
		if (info.ids) then
			local name, _, icon = GetSpellInfo(info.ids[1])
			assert(name and icon)
			info.icon = icon
			info.list = {}
			for j,id in ipairs(info.ids) do
				local name = GetSpellInfo(id)
				info.list[name] = true
				z.buffsLookup[name] = info
			end
			info.list[name] = true
		end
		tinsert(z.allBuffs, info)
	end
	z.buffs = {}
	for i,info in pairs(z.allBuffs) do
		z.buffs[i] = info
	end

	z.auras = {
		DEVOTION		= {id = 465},		-- Devotion Aura
		RETRIBUTION		= {id = 7294},		-- Retribution Aura
		CONCENTRATION	= {id = 19746},		-- Concentration Aura
		SHADOW			= {id = 19876},		-- Shadow Resistance Aura
		FROST			= {id = 19888},		-- Frost Resistance Aura
		FIRE			= {id = 19891},		-- Fire Resistance Aura
		CRUSADER		= {id = 32223},		-- Crusader Aura
	}
	for key,info in pairs(z.auras) do
		local _
		info.name, _, info.icon = GetSpellInfo(info.id)
		info.key = key
	end
	z.auraCycle = {"DEVOTION", "RETRIBUTION", "CONCENTRATION", "SHADOW", "FROST", "FIRE", "CRUSADER"}
	z.auraIndex = {}
	for i,name in ipairs(z.auraCycle) do
		z.auraIndex[name] = i
	end

	local blessings	= {
		{id = 27142, type = "BOW", dur = 5,					short = L["Wisdom"]},	-- Blessing of Wisdom
		{id = 27143, type = "BOW", dur = 30,	class = true},						-- Greater Blessing of Wisdom
		{id = 27140, type = "BOM", dur = 5,					short = L["Might"]},	-- Blessing of Might
		{id = 27141, type = "BOM", dur = 30,	class = true},						-- Greater Blessing of Might
		{id = 20217, type = "BOK", dur = 5,					short = L["Kings"]},	-- Blessing of Kings
		{id = 25898, type = "BOK", dur = 30,	class = true},						-- Greater Blessing of Kings
		{id = 20911, type = "SAN", dur = 5,					short = L["Sanctuary"]}, -- Blessing of Sanctuary
		{id = 25899, type = "SAN", dur = 30,	class = true},						-- Greater Blessing of Sanctuary
		{id = 10278, type = "BOP", dur = 0.2, noTemplate = true},					-- Hand of Protection
	}

	z.blessings = {}
	for i,info in pairs(blessings) do
		local name, _, icon = GetSpellInfo(info.id)
		if (not name) then
			error("No spell for ID "..info.id)
		end

		info.icon = icon
		z.blessings[name] = info
	end
	
	z.blessingsIndex = {}
	for k,v in pairs(z.blessings) do
		if (not z.blessingsIndex[v.type]) then
			z.blessingsIndex[v.type] = {}
		end
		if (v.class) then
			z.blessingsIndex[v.type].class = k
		else
			z.blessingsIndex[v.type].single = k
		end
		if (v.short) then
			z.blessingsIndex[v.type].short = v.short
		end
		if (v.icon) then
			z.blessingsIndex[v.type].icon = v.icon
		end
	end
end

z.version = tonumber(string.sub("$Revision: 152 $", 12, -3)) or 1
z.versionCompat = 65478 - 82090				-- 65478 is the compat version check
z.title = L["TITLE"]
z.titleColour = L["TITLECOLOUR"]
z.mainIcon = "Interface\\AddOns\\ZOMGBuffs\\Textures\\Icon"
z.defaultMinimapPosition = 330
z.cannotDetachTooltip = true
z.clickableTooltip = true
z.hasIcon = nil
z.hasNoText = true						-- Reset later should we have Fubar icon enabled
z.cannotAttachToMinimap = true
z.versionRoster = {}
z.zoneFlag = GetTime()

-- propercase
local function propercase(str)
	return str and (strupper(strsub(str, 1, 1))..strlower(strsub(str, 2)))
end

z.classReverse = new()
for i,class in pairs(z.classOrder) do
	z.classReverse[LOCALIZED_CLASS_NAMES_MALE[class]] = class
end

-- CheckVersion
function z:CheckVersion(ver)
	ver = tonumber(string.sub(ver, 12, -3))
	if (ver) then
		if (ver > z.version) then
			z.version = ver
		end
	end
end

--[===[@debug@
-- err
local function err(self, message, ...)
	if type(self) ~= "table" then
		return error(("Bad argument #1 to `err' (table expected, got %s)"):format(type(self)), 2)
	end
	
	local stack = debugstack(self == z and 2 or 3)
	if not message then
		local second = stack:match("\n(.-)\n")
		message = "error raised! " .. second
	else
		local arg = { ... } -- not worried about table creation, as errors don't happen often
		
		for i = 1, #arg do
			arg[i] = tostring(arg[i])
		end
		for i = 1, 10 do
			table.insert(arg, "nil")
		end
		message = message:format(unpack(arg))
	end
	
	if getmetatable(self) and getmetatable(self).__tostring then
		message = ("%s: %s"):format(tostring(self), message)
	elseif type(rawget(self, 'GetLibraryVersion')) == "function" and AceLibrary:HasInstance(self:GetLibraryVersion()) then
		message = ("%s: %s"):format(self:GetLibraryVersion(), message)
	elseif type(rawget(self, 'class')) == "table" and type(rawget(self.class, 'GetLibraryVersion')) == "function" and AceLibrary:HasInstance(self.class:GetLibraryVersion()) then
		message = ("%s: %s"):format(self.class:GetLibraryVersion(), message)
	end
	
	local first = stack:gsub("\n.*", "")
	local file = first:gsub(".*\\(.*).lua:%d+: .*", "%1")
	file = file:gsub("([%(%)%.%*%+%-%[%]%?%^%$%%])", "%%%1")
	
	
	local i = 0
	for s in stack:gmatch("\n([^\n]*)") do
		i = i + 1
		if not s:find(file .. "%.lua:%d+:") and not s:find("%(tail call%)") then
			file = s:gsub("^.*\\(.*).lua:%d+: .*", "%1")
			file = file:gsub("([%(%)%.%*%+%-%[%]%?%^%$%%])", "%%%1")
			break
		end
	end
	local j = 0
	for s in stack:gmatch("\n([^\n]*)") do
		j = j + 1
		if j > i and not s:find(file .. "%.lua:%d+:") and not s:find("%(tail call%)") then
			return error(message, j+1)
		end
	end
	return error(message, 2)
end

-- argCheck
function z.argCheck(self, arg, num, kind, kind2, kind3, kind4, kind5)
	if type(num) ~= "number" then
		return err(self, "Bad argument #3 to `argCheck' (number expected, got %s)", type(num))
	elseif type(kind) ~= "string" then
		return err(self, "Bad argument #4 to `argCheck' (string expected, got %s)", type(kind))
	end
	arg = type(arg)
	if arg ~= kind and arg ~= kind2 and arg ~= kind3 and arg ~= kind4 and arg ~= kind5 then
		local stack = debugstack(self == z and 2 or 3)
		local func = stack:match("`argCheck'.-([`<].-['>])")
		if not func then
			func = stack:match("([`<].-['>])")
		end
		if kind5 then
			return err(self, "Bad argument #%s to %s (%s, %s, %s, %s, or %s expected, got %s)", tonumber(num) or 0/0, func, kind, kind2, kind3, kind4, kind5, arg)
		elseif kind4 then
			return err(self, "Bad argument #%s to %s (%s, %s, %s, or %s expected, got %s)", tonumber(num) or 0/0, func, kind, kind2, kind3, kind4, arg)
		elseif kind3 then
			return err(self, "Bad argument #%s to %s (%s, %s, or %s expected, got %s)", tonumber(num) or 0/0, func, kind, kind2, kind3, arg)
		elseif kind2 then
			return err(self, "Bad argument #%s to %s (%s or %s expected, got %s)", tonumber(num) or 0/0, func, kind, kind2, arg)
		else
			return err(self, "Bad argument #%s to %s (%s expected, got %s)", tonumber(num) or 0/0, func, kind, arg)
		end
	end
end
--@end-debug@]===]

local function getOption(v)
	return z.db.profile[v]
end
local function getPCOption(v)
	return z.db.char[v]
end
local function setOption(v, n)
	z.db.profile[v] = n
end
local function setOptionUpdate(v, n)
	z.db.profile[v] = n
	z:SetupForSpell()
	z:RequestSpells()
end
local function setPCOption(v, n, s)
	z.db.char[v] = n
	if (s) then
		z:SetupForSpell()
		z:RequestSpells()
	end
end

local function getTrackOption(p)
	return z.db.profile.track[p]
end
local function setTrackOption(p,v)
	z.db.profile.track[p] = v
	z:SetBuffsList()
	z:OptionsShowList()
end

do
	local points = {"TOPLEFT", "TOP", "TOPRIGHT", "RIGHT", "BOTTOMRIGHT", "BOTTOM", "BOTTOMLEFT", "LEFT"}
	local outlines = {[""] = L["None"], ["OUTLINE"] = L["Outline"], ["THICKOUTLINE"] = L["Thick Outline"]}
	local function notRebuffer()
		return not z:IsRebuffer()
	end
	local function hideReagentOpts()
		return z.hideReagentOptions
	end
	local function noNoticeOptions()
		return not z.db.profile.notice
	end
z.options = {
	handler = z,
	type = 'group',
	args = {
		space = {
			type = 'header',
			desc = " ",
			order = 200,
		},
		behaviour = {
			type = 'group',
			name = L["Behaviour"],
			desc = L["General buffing behaviour"],
			order = 220,
			disabled = "IsDisabled",
			args = {
				reagentautobuy = {
					type = 'toggle',
					name = L["Auto Buy Reagents"],
					desc = L["Automatically purchase required reagents from Reagents Vendor"],
					get = getPCOption,
					set = function(v,n) setPCOption(v,n) end,
					hidden = hideReagentOpts,
					passValue = "autobuyreagents",
					order = 1,
					args = {
					}
				},
				reagentlevels = {
					type = 'group',
					name = L["Reagents Levels"],
					desc = L["Purchase levels for reagents"],
					disabled = function() return not z.db.char.autobuyreagents end,
					hidden = hideReagentOpts,
					order = 2,
					args = {
					}
				},
				space2 = {
					type = 'header',
					desc = " ",
					order = 30,
					hidden = hideReagentOpts,
				},
				mousewheel = {
					type = 'toggle',
					name = L["Mousewheel Buff"],
					desc = L["Use mousewheel to trigger auto buffing"],
					get = getOption,
					set = function(v,n)
						setOption(v,n)
						z.db.profile.keybinding = nil
						z:SetKeyBindings()
					end,
					passValue = "mousewheel",
					order = 50,
				},
				keybinding = {
					type = 'text',
					name = L["Key-Binding"],
					desc = L["Define the key used for auto buffing"],
					validate = "keybinding",
					get = getOption,
					set = function(v,n)
						if (n == "MOUSEWHEELUP" or n == "MOUSEWHEELDOWN") then
							z.db.profile.mousewheel = true
							z.db.profile.keybinding = nil
						else
							setOption(v,n)
						end
						z:SetKeyBindings()
					end,
					passValue = "keybinding",
					disabled = function() return z.db.profile.mousewheel end,
					order = 51,
				},
				space4 = {
					type = 'header',
					desc = " ",
					order = 100,
				},
				waitforraid = {
					type = 'range',
					name = L["Wait for Raid"],
					desc = L["Wait for certain amount of the raid to arrive before group and class buffing commences. Zero to always buff."],
					hidden = notRebuffer,
					get = getOption,
					set = setOptionUpdate,
					passValue = "waitforraid",
					isPercent = true,
					min = 0,
					max = 1,
					step = 0.01,
					bigStep = 0.1,
					order = 102,
				},
				waitforclass = {
					type = 'toggle',
					name = L["Wait for Class/Group"],
					desc = L["Wait for all of a class or group to arrive before buffing them"],
					hidden = notRebuffer,
					get = getOption,
					set = setOptionUpdate,
					passValue = "waitforclass",
					order = 103,
				},
				ignoreabsent = {
					type = 'toggle',
					name = L["Ignore Absent"],
					desc = L["If players are offline, AFK or in another instance, count them as being present and buff everyone else"],
					hidden = notRebuffer,
					get = getOption,
					set = setOptionUpdate,
					passValue = "ignoreabsent",
					order = 105,
				},
				skippvp = {
					type = 'toggle',
					name = L["Skip PVP Players"],
					desc = L["Don't directly buff PVP flagged players, unless you're already flagged for PVP"],
					hidden = notRebuffer,
					get = getOption,
					set = setOptionUpdate,
					passValue = "skippvp",
					order = 108,
				},
				notresting = {
					type = 'toggle',
					name = L["Not When Resting"],
					desc = L["Don't auto buff when Resting"],
					get = getOption,
					set = setOptionUpdate,
					passValue = "notresting",
					order = 112,
				},
				restingpvp = {
					type = 'toggle',
					name = L["...unless PvP"],
					desc = L["Allow auto buffing when resting when your PvP is enabled"],
					get = getOption,
					set = setOptionUpdate,
					passValue = "restingpvp",
					order = 113,
				},
				notmounted = {
					type = 'toggle',
					name = L["Not When Mounted"],
					desc = L["Don't auto buff when Mounted"],
					get = getOption,
					set = setOptionUpdate,
					passValue = "notmounted",
					order = 114,
				},
				notstealthed = {
					type = 'toggle',
					name = L["Not When Stealthed"],
					desc = L["Don't auto buff when Stealthed"],
					get = getOption,
					set = setOptionUpdate,
					hidden = function() return playerClass ~= "DRUID" and playerClass ~= "ROGUE" end,
					passValue = "notstealthed",
					order = 115,
				},
				notshifted = {
					type = 'toggle',
					name = L["Not When Shapeshifted"],
					desc = L["Don't auto buff when Shapeshifted"],
					get = getOption,
					set = setOptionUpdate,
					hidden = function() return playerClass ~= "DRUID" and playerClass ~= "SHAMAN" end,
					passValue = "notshifted",
					order = 116,
				},
				notWithSpiritTap = {
					type = 'toggle',
					name = L["Not with Spirit Tap"],
					desc = L["Don't auto buff when you have Spirit Tap, so you can maximise your regeneration"],
					get = getOption,
					set = setOptionUpdate,
					hidden = function() return playerClass ~= "PRIEST" end,
					passValue = "notWithSpiritTap",
					order = 119,
				},
				minmana = {
					type = 'range',
					name = L["Minimum Mana %"],
					desc = L["How much mana should you have before considering auto buffing"],
					get = getPCOption,
					set = setPCOption,
					passValue = "minmana",
					min = 0,
					max = 100,
					step = 1,
					bigStep = 5,
					order = 120,
				},
				space3 = {
					type = 'header',
					desc = " ",
					order = 150,
					hidden = notRebuffer,
				},
				singlesAlways = {
					type = 'toggle',
					name = L["Singles Always"],
					desc = L["Only use single target buffs"],
					hidden = notRebuffer,
					get = getOption,
					set = setOptionUpdate,
					passValue = "singlesAlways",
					order = 160,
				},
				singlesInBG = {
					type = 'toggle',
					name = L["Singles in BGs"],
					desc = L["Only use single target buffs in battlegrounds"],
					hidden = notRebuffer,
					disabled = function() return z.db.profile.singlesAlways end,
					get = getOption,
					set = setOptionUpdate,
					passValue = "singlesInBG",
					order = 161,
				},
				singlesInArena = {
					type = 'toggle',
					name = L["Singles in Arena"],
					desc = L["Only use single target buffs in arenas"],
					hidden = notRebuffer,
					disabled = function() return z.db.profile.singlesAlways end,
					get = getOption,
					set = setOptionUpdate,
					passValue = "singlesInArena",
					order = 162,
				},
				pets = {
					type = 'toggle',
					name = L["Buff Pets"],
					desc = L["Perform extra checks for pets in case any missed the group buffs when they were done"],
					get = getPCOption,
					set = setPCOption,
					passValue = "buffpets",
					hidden = notRebuffer,
					order = 200,
				},
			},
		},
		learn = {
			order = 250,
			type = 'group',
			name = L["Learning"],
			desc = L["Setup spell learning behaviour"],
			disabled = "IsDisabled",
			args = {
				ooc = {
					type = 'toggle',
					name = L["Out of Combat"],
					desc = L["Learn buff changes out of combat"],
					get = getPCOption,
					set = setPCOption,
					passValue = "learnooc",
					order = 1,
				},
				combat = {
					type = 'toggle',
					name = L["In-Combat"],
					desc = L["Learn buff changes in combat"],
					get = getPCOption,
					set = setPCOption,
					passValue = "learncombat",
					order = 2,
				},
			},
		},
		reminder = {
			order = 280,
			type = 'group',
			name = L["Reminders"],
			desc = L["Options to help you notice when things need doing"],
			disabled = "IsDisabled",
			args = {
				sound = {
					type = 'text',
					name = L["Rebuff Sound"],
					desc = L["Give audible feedback when someone needs rebuffing"],
					get = getOption,
					set = function(k,v)
						setOption(k,v)
						PlaySoundFile(SM:Fetch("sound", v))
					end,
					validate = SM:List("sound"),
					hidden = function() return not SM end,
					passValue = "buffreminder",
					order = 1,
				},
				spacer = {
					type = 'header',
					name = " ",
					order = 2,
				},
				notice = {
					type = 'toggle',
					name = L["Notice"],
					desc = L["Show notice on screen for buff needs"],
					get = getOption,
					set = setOption,
					passValue = "notice",
					order = 5,
				},
				movenotice = {
					type = 'execute',
					name = L["Notice Anchor"],
					desc = L["Show the Notice area anchor"],
					func = "MovableNoticeWindow",
					disabled = noNoticeOptions,
					order = 6,
				},
				sink = {
					type = 'toggle',
					name = L["Sink Output"],
					desc = L["Route notification messages through SinkLib"],
					get = getOption,
					set = setOption,
					hidden = function() return not Sink end,
					disabled = noNoticeOptions,
					passValue = "usesink",
					order = 7,
				},
				spacer2 = {
					type = 'header',
					name = " ",
					order = 14,
				},
				info = {
					type = 'toggle',
					name = L["Information"],
					desc = L["Give feedback about events"],
					get = getOption,
					set = setOption,
					passValue = "info",
					order = 15,
				},
			},
		},
		display = {
			order = 302,
			type = 'group',
			name = L["Display"],
			desc = L["Display options"],
			disabled = "IsDisabled",
			args = {
				manager = {
					type = 'toggle',
					name = L["Always Load Manager"],
					desc = L["Always load the Blessings Manager, even when not eligable to modify blessings"],
					get = getOption,
					set = function(v,n) setOption(v,n) if (z.MaybeLoadManager) then z:MaybeLoadManager() end end,
					hidden = function() return select(6,GetAddOnInfo("ZOMGBuffs_BlessingsManager")) == "MISSING" end,
					passValue = "alwaysLoadManager",
					order = 20,
				},
				portalz = {
					type = 'toggle',
					name = L["Always Load Portalz"],
					desc = L["Always load the Portalz module, even when not a Mage"],
					get = getOption,
					set = function(v,n) setOption(v,n) if (z.MaybeLoadPortalz) then z:MaybeLoadPortalz() end end,
					hidden = function() return select(2,UnitClass("player")) == "MAGE" or select(6,GetAddOnInfo("ZOMGBuffs_Portalz")) == "MISSING" end,
					passValue = "alwaysLoadPortalz",
					order = 21,
				},
				raidmod = {
					type = 'toggle',
					name = L["Load Raid Module"],
					desc = L["Load the Raid Buff module. Usually for Mages, Druids & Priests, this module can also track single target spells such as Earth Shield & Blessing of Sacrifice, and allow raid buffing of Undending Breath and so on"],
					get = getPCOption,
					set = function(k,v)
						z.db.char.loadraidbuffmodule = v
						if (v) then
							LoadAddOn("ZOMGBuffs_BuffTehRaid")
							self.actions = nil
							self:SetClickConfigMenu()
						end
					end,
					hidden = function() return not z.canloadraidbuffmodule end,
					passValue = "loadraidbuffmodule",
					order = 25,
				},
				space = {
					type = 'header',
					desc = " ",
					order = 30,
				},
				spellicons = {
					type = 'toggle',
					name = L["Spell Icons"],
					desc = L["Show spell icons with spell names in messages"],
					get = getOption,
					set = setOption,
					passValue = "spellIcons",
					order = 35,
				},
				short = {
					type = 'toggle',
					name = L["Short Names"],
					desc = L["Use short spell names where appropriate"],
					get = getOption,
					set = setOption,
					passValue = "short",
					order = 40,
				},
				space2 = {
					type = 'header',
					desc = " ",
					order = 100,
				},
				icon = {
					type = 'group',
					name = L["Icon"],
					desc = L["Settings for the mouseover icon used by the popup player buff list"],
					order = 101,
					args = {
						enable = {
							type = 'toggle',
							name = L["Enable"],
							desc = L["Display the mouseover icon used by the popup player buff list"],
							get = getPCOption,
							set = function(k,v) setPCOption(k,v) z:SetIconSize() end,
							disabled = InCombatLockdown,
							passValue = "showicon",
							order = 1,
						},
						lock = {
							type = 'toggle',
							name = L["Lock"],
							desc = L["Lock floating icon position"],
							get = getPCOption,
							set = setPCOption,
							passValue = "iconlocked",
							order = 2,
						},
						class = {
							type = 'toggle',
							name = L["Class Icon"],
							desc = L["Uses your main ZOMGBuffs spell for the floating icon, instead of the ZOMGBuffs default"],
							get = getPCOption,
							set = function(k,v) setPCOption(k,v) z:SetIconSize() z:CanCheckBuffs() end,
							passValue = "classIcon",
							order = 5,
						},
						name = {
							type = 'toggle',
							name = L["Name"],
							desc = L["Display the ZOMGBuffs logo on icon"],
							get = getOption,
							set = function(k,v) setOption(k,v) z:SetIconSize() end,
							passValue = "iconname",
							order = 8,
						},
						swirl = {
							type = 'toggle',
							name = L["Swirl"],
							desc = L["Display the spell ready swirl when an autocast spell is loaded on the main icon"],
							get = getOption,
							set = function(k,v) setOption(k,v) end,
							passValue = "iconswirl",
							order = 8,
						},
						size = {
							type = 'range',
							name = L["Icon Size"],
							desc = L["Size of main icon"],
							get = getPCOption,
							set = function(k,v) setPCOption(k,v) z:SetIconSize() end,
							disabled = function() return InCombatLockdown() or not z.db.char.showicon end,
							passValue = "iconsize",
							min = 20,
							max = 64,
							step = 1,
							bigStep = 5,
							order = 10,
						},
						space = {
							type = 'header',
							desc = " ",
							order = 300,
						},
						reset = {
							type = 'execute',
							name = L["Reset Icon Position"],
							desc = L["Reset the icon position to the centre of the screen"],
							func = function() z.icon:ClearAllPoints() z.icon:SetPoint("CENTER") end,
							order = 301,
							disabled = InCombatLockdown,
						},
					},
				},
				list = {
					type = 'group',
					name = L["List"],
					desc = L["Settings for the popup buff list"],
					order = 102,
					args = {
						timer = {
							type = 'toggle',
							name = L["Buff Timer"],
							desc = L["Show buff time remaining with bar"],
							get = getOption,
							set = function(k,v) setOption(k,v) z:DrawAllCells() z:OptionsShowList() end,
							passValue = "bufftimer",
							order = 10,
						},
						size = {
							type = 'range',
							name = L["Timer Size"],
							desc = L["Adjust the size of the timer text"],
							get = getOption,
							set = function(k,v) setOption(k,v) z:DrawAllCells() z:OptionsShowList() end,
							passValue = "bufftimersize",
							min = 0.3,
							max = 2,
							step = 0.05,
							order = 11,
						},
						threshold = {
							type = 'range',
							name = L["Timer Threshold"],
							desc = L["Buff times over this number of minutes will not be shown"],
							get = function() return floor(z.db.profile.bufftimerthreshold / 60 + 0.5) end,
							set = function(v)
								z.db.profile.bufftimerthreshold = v * 60
								z:DrawAllCells()
								z:OptionsShowList()
							end,
							min = 0,
							max = 120,
							step = 1,
							bigStep = 10,
							order = 12,
						},
						track = {
							type = 'group',
							name = L["Columns"],
							desc = L["Columns to show in buff list"],
							order = 50,
							args = {
								sta = {
									type = 'toggle',
									name = GetSpellInfo(36004),		-- Power Word: Fortitude
									desc = GetSpellInfo(36004),		-- Power Word: Fortitude
									get = getTrackOption,
									set = setTrackOption,
									passValue = "sta",
									order = 1,
								},
								mark = {
									type = 'toggle',
									name = GetSpellInfo(39233),		-- Mark of the Wild
									desc = GetSpellInfo(39233),		-- Mark of the Wild
									get = getTrackOption,
									set = setTrackOption,
									passValue = "mark",
									order = 2,
								},
								int = {
									type = 'toggle',
									name = GetSpellInfo(39235),		-- Arcane Intellect
									desc = GetSpellInfo(39235),		-- Arcane Intellect
									get = getTrackOption,
									set = setTrackOption,
									passValue = "int",
									order = 3,
								},
								spirit = {
									type = 'toggle',
									name = GetSpellInfo(39234),		-- Divine Spirit
									desc = GetSpellInfo(39234),		-- Divine Spirit
									get = getTrackOption,
									set = setTrackOption,
									passValue = "spirit",
									order = 4,
								},
								shadow = {
									type = 'toggle',
									name = GetSpellInfo(28537),		-- Shadow Protection
									desc = GetSpellInfo(28537),		-- Shadow Protection
									get = getTrackOption,
									set = setTrackOption,
									passValue = "shadow",
									order = 5,
								},
								blessings = {
									type = 'toggle',
									name = L["Blessings"],
									desc = L["Blessings"],
									get = getTrackOption,
									set = setTrackOption,
									passValue = "blessings",
									order = 6,
								},
								food = {
									type = 'toggle',
									name = GetSpellInfo(46899),		-- Well Fed
									desc = GetSpellInfo(46899),		-- Well Fed
									get = getTrackOption,
									set = setTrackOption,
									passValue = "food",
									order = 7,
								},
								flask = {
									type = 'toggle',
									name = L["Flask"],
									desc = L["Is player flasked or potted"],
									get = getTrackOption,
									set = setTrackOption,
									passValue = "flask",
									order = 8,
								},
								spacer = {
									type = 'header',
									name = " ",
									order = 10,
								},
								runescroll = {
									type = 'toggle',
									name = L["RuneScroll/Drums"],
									desc = L["Always show Stamina and Mark of the Wild Columns"],
									get = getOption,
									set = function(p,v) z.db.profile[p] = v z:SetBuffsList() z:OptionsShowList() end,
									passValue = "runescroll",
									order = 20,
								},
							},
						},
						invert = {
							type = 'toggle',
							name = L["Invert"],
							desc = L["Invert the need/got alpha values"],
							get = getOption,
							set = function(k,v) setOption(k,v) z:OptionsShowList() z:PLAYER_ENTERING_WORLD() end,
							passValue = "invert",
							order = 110,
						},
						sort = {
							type = 'text',
							name = L["Sort Order"],
							desc = L["Select sorting order for buff overview (can't be changed during combat)"],
							get = getPCOption,
							set = function(k,v) setPCOption(k,v) z:SetSort(true) end,
							validate = {ALPHA = L["Alphabetical"], CLASS = L["Class"], GROUP = L["Group"], INDEX = L["Unsorted"]},
							disabled = InCombatLockdown,
							passValue = "sort",
							order = 111,
						},
						groupno = {
							type = 'toggle',
							name = L["Group Number"],
							desc = L["Show the group number next to list"],
							get = getOption,
							set = function(k,v) setOption(k,v) z:DrawGroupNumbers() end,
							passValue = "groupno",
							order = 112,
							hidden = function() return z.db.char.sort ~= "GROUP" end,
						},
						show = {
							type = 'group',
							name = L["Show"],
							desc = L["Visiblity options"],
							order = 120,
							args = {
								solo = {
									type = 'toggle',
									name = L["Solo"],
									desc = L["Show the popup raid list when you are not in a raid or party"],
									get = getOption,
									set = function(k,v) setOption(k,v) z:SetVisibilityOption() z:DrawGroupNumbers() end,
									passValue = "showSolo",
									disabled = InCombatLockdown,
									order = 1,
								},
								party = {
									type = 'toggle',
									name = L["Party"],
									desc = L["Show the popup raid list when you are in a party"],
									get = getOption,
									set = function(k,v) setOption(k,v) z:SetVisibilityOption() z:DrawGroupNumbers() end,
									passValue = "showParty",
									disabled = InCombatLockdown,
									order = 2,
								},
								raid = {
									type = 'toggle',
									name = L["Raid"],
									desc = L["Show the popup raid list when you in a raid"],
									get = getOption,
									set = function(k,v) setOption(k,v) z:SetVisibilityOption() z:DrawGroupNumbers() end,
									passValue = "showRaid",
									disabled = InCombatLockdown,
									order = 3,
								},
							},
						},
						showroles = {
							type = 'toggle',
							name = L["Show Roles"],
							desc = L["Show player role icons"],
							get = getOption,
							set = setOption,
							passValue = "showroles",
							order = 125,
						},
						space2 = {
							type = 'header',
							desc = " ",
							order = 150,
						},
						border = {
							type = 'toggle',
							name = L["Border"],
							desc = L["Enable border on the list"],
							get = getPCOption,
							set = function(k,v) setPCOption(k,v) z:DrawGroupNumbers() end,
							passValue = "border",
							order = 200,
						},
						bartexture = {
							type = 'text',
							name = L["Bar Texture"],
							desc = L["Set the texture for the buff timer bars"],
							validate = SM and SM:List("statusbar") or {},
							order = 201,
							hidden = function() return not SM end,
							get = getOption,
							set = function(k,v) setOption(k,v) z:SetAllBarTextures() z:OptionsShowList() end,
							passValue = "bartexture",
						},
						width = {
							type = 'range',
							name = L["Width"],
							desc = L["Adjust width of unit list"],
							get = getPCOption,
							set = function(k,v) setPCOption(k,v) z:SetAllBarSizes() z:OptionsShowList() end,
							disabled = InCombatLockdown,
							passValue = "width",
							min = 100,
							max = 300,
							step = 1,
							bigStep = 10,
							order = 202,
						},
						height = {
							type = 'range',
							name = L["Bar Height"],
							desc = L["Adjust height of the bars"],
							get = getPCOption,
							set = function(k,v) setPCOption(k,v) z:SetAllBarSizes() z:OptionsShowList() end,
							disabled = InCombatLockdown,
							passValue = "height",
							min = 10,
							max = 30,
							step = 1,
							order = 203,
						},
						font = {
							type = 'group',
							name = L["Font"],
							desc = L["Font"],
							order = 204,
							args = {
								font = {
									type = 'text',
									name = L["Font"],
									desc = L["Font"],
									get = getPCOption,
									set = function(k,v) setPCOption(k,v) z:ApplyFont() z:OptionsShowList() end,
									validate = SM and SM:List("font") or {},
									passValue = "fontface",
								},
								size = {
									type = 'range',
									name = L["Size"],
									desc = L["Size"],
									min = 5,
									max = 25,
									step = 1,
									get = getPCOption,
									set = function(k,v) setPCOption(k,v) z:ApplyFont() z:OptionsShowList() end,
									passValue = "fontsize",
								},
								outlining = {
									type = 'text',
									name = L["Outlining"],
									desc = L["Outlining"],
									get = getPCOption,
									set = function(k,v) setPCOption(k,v) z:ApplyFont() z:OptionsShowList() end,
									validate = outlines,
									passValue = "fontoutline",
								},
							},
						},
						anchor = {
							type = 'text',
							name = L["Anchor"],
							desc = L["Choose the anchor to use for the player list"],
							validate = points,
							order = 220,
							get = getPCOption,
							set = function(k,v) z.db.char.anchor = v z:SetAnchors() z:OptionsShowList() end,
							disabled = InCombatLockdown,
							passValue = "anchor",
						},
						relpoint = {
							type = 'text',
							name = L["Relative Point"],
							desc = L["Choose the relative point for the anchor"],
							validate = points,
							order = 221,
							get = getPCOption,
							set = function(k,v) z.db.char.relpoint = v z:SetAnchors() z:OptionsShowList() end,
							disabled = InCombatLockdown,
							passValue = "relpoint",
						},
					},
				},
			},
		},
		report = {
			order = 400,
			type = 'group',
			name = L["Report"],
			desc = L["Report options"],
			hidden = function() return not IsRaidOfficer() or not IsRaidLeader() end,
			disabled = "IsDisabled",
			args = {
				missing = {
					type = 'execute',
					name = L["Report Missing"],
					desc = L["Report raid buffs currently missing"],
					func = "Report",
					passValue = "missing",
					order = 1,
				},
				space = {
					type = 'header',
					desc = " ",
					order = 500,
				},
				channel = {
					type = 'text',
					name = L["Channel"],
					desc = L["Output channel selection"],
					validate = {"Raid", "Party", "Guild", "Officer", "Say"},
					get = getOption,
					set = setOption,
					passValue = "channel",
					order = 501,
				},
			},
		},
		fubar = {
			type = "toggle",
			name = "Fubar Icon",
			desc = "Show on Fubar/Minimap",
			get = function() return z.db.profile.showFubar end,
			set = function(v) z.db.profile.showFubar = v z:SetMainIcon() end,
			hidden = function() return not z.ldbSource end,
			order = -5000,
		}
	},
}
	if (Sink and (SinkVersion >= 62534 or SinkVersion < 10000)) then
		-- Move the Sink options menu
		local temp = z:GetSinkAce2OptionsDataTable().output
		z.options.args.reminder.args.output = temp
		temp.order = 8
		temp.disabled = function() return not z.db.profile.usesink or not z.db.profile.notice end
	end
end

z.OnMenuRequest = z.options

-- IsRebuffer
function z:IsRebuffer()
	for name, module in self:IterateModulesWithMethod("RebuffQuery") do
		return true
	end
end


-- Custom roster iterator
do
	local unitCache, unitCacheMode
	
	local function SetCacheMode(m)
		if (unitCacheMode ~= m) then
			unitCacheMode = m
			local meta
			if (m == "raid") then
				meta = function(self, i)
					local n = "raid"..i
					self[i] = n
					return n
				end
			else
				meta = function(self, i)
					local n = i == 0 and "player" or "party"..i
					self[i] = n
					return n
				end
			end
			
			unitCache = setmetatable({}, {__mode = "kv", __index = meta})
		end
	end

	-- Speciallized Roster iterator to always put ME first
	-- Also benefits from not having any delay in setup between RAID_ROSTER_UPDATE and RosterLib's update
	local function iter(t)
		local index = t.index
		local pets = t.pets

		if (not index) then
			if (not playerClass) then
				playerClass = playerClass or select(2, UnitClass("player"))
			end

			if (GetNumRaidMembers() > 0) then
				SetCacheMode("raid")
				local End = GetNumRaidMembers()
				t.End = End
				t.type = "raid"
				t.index = 0
				local unit = unitCache[End]		-- YOU are always the last raid member
				t.unit = unit
				t.doPet = pets
				t.mine = pets
				local _, _, subgroup = GetRaidRosterInfo(End)
				return unit, playerName, playerClass, subgroup, End
			else
				SetCacheMode("party")
				t.End = GetNumPartyMembers()
				t.type = "party"
				t.index = 0
				t.doPet = pets
				t.unit = "player"
				return "player", playerName, playerClass, 1, 0
			end
		end

		local unit
		local class = "Unknown"
		if (pets and t.doPet) then
			if (t.unit == "player") then
				unit = "pet"
			elseif (t.mine) then
				t.mine = nil
				unit = "raidpet"..t.End
			else
				unit = format("%spet%d", t.type, index)
			end
			if (UnitExists(unit)) then
				class = "PET"
			else
				t.doPet = nil
			end
		end

		if (not pets or not t.doPet) then
			index = index + 1
			if (index > t.End) then
				t = del(t)
				return nil
			end

			unit = unitCache[index]
			if (UnitIsUnit(unit, "player")) then
				index = index + 1
				if (index > t.End) then
					t = del(t)
					return nil
				end

				unit = unitCache[index]
			end
			class = select(2, UnitClass(unit))
		end

		t.doPet = not t.doPet

		local name, server = UnitName(unit)
		if (server and server ~= "") then
			name = format("%s-%s", name, server)
		end
		t.unit = unit
		t.index = index
		t.unit = unit
		local _, subgroup
		if (t.type == "raid") then
			_, _, subgroup = GetRaidRosterInfo(index)
		else
			subgroup = 1
		end
		if (not class) then
			-- Unknown Unit at this time, so we'll wait for the UNIT_NAME_UPDATE and re-check any we're missing
			z:RegisterEvent("UNIT_NAME_UPDATE")
			if (not z.unknownUnits) then
				z.unknownUnits = new()
			end
			z.unknownUnits[unit] = true
			class = UNKNOWN
		end
		return unit, name, class, subgroup, index
	end

	-- IterateRoster
	function z:IterateRoster(pets)
		local t = new()
		t.pets = pets
		return iter, t
	end
	
	function z:UNIT_NAME_UPDATE(unit)
		if (self.unknownUnits[unit]) then
			self.unknownUnits[unit] = nil
			local _, class = UnitClass(unit)
			self.classcount[class] = self.classcount[class] + 1

			self:TriggerClickUpdate(unit)

			if (not next(self.unknownUnits)) then
				self.unknownUnits = del(self.unknownUnits)
				self:UnregisterEvent("UNIT_NAME_UPDATE")
				-- Got all now, do full roster update to be sure
				self:OnRaidRosterUpdate()
			end
		end
	end
	
	function z:UnitRank(who)
		local index = UnitInRaid(who)
		if (index) then
			local name, rank, group = GetRaidRosterInfo(index + 1)
			return rank or 0
		elseif (GetNumPartyMembers() > 0) then
			local index = GetPartyLeaderIndex()
			if (UnitIsUnit(who, "player")) then
				return index == 0 and 2 or 0
			else
				local name = UnitName("party"..index)
				return name == who and 2 or 0
			end
		end
		return 0
	end

	function z:GetUnitID(name)
		local unit = UnitInRaid(name)
		if (unit) then
			return "raid"..(unit + 1)
		end
		if (UnitIsUnit(name, "player")) then
			return "player"
		end
		if (UnitInParty(name)) then
			for i = 1,4 do
				local test = "party"..i
				if (UnitIsUnit(test, name)) then
					return test
				end
			end
		end
		for unit,unitname in z:IterateRoster(true) do
			if (UnitIsUnit(name, unit)) then
				return unit
			end
		end
	end
end

-- GetAllActions
function z:GetAllActions()
	if (not self.actions) then
		self.actions = {
			{name = L["Target"], desc = L["Targetting"], type = "target"},
		}
		for name, mod in self:IterateModulesWithMethod("GetActions") do
			if (mod:IsModuleActive()) then
				if (mod.ResetActions) then
					mod:ResetActions()
				end
				local moreActions = mod:GetActions()
				if (moreActions) then
					for i,action in ipairs(moreActions) do
						action.mod = mod
						tinsert(self.actions, action)
					end
				end
			end
		end
	end
end

-- DupKeybinds
function z:DupKeybinds(entry)
	local thisKey = self.db.profile.click and self.db.profile.click[entry.keycode]
	for name,menu in pairs(z.options.args.click.args)  do
		if (menu ~= entry and menu.basename) then
			local otherKey = self.db.profile.click and self.db.profile.click[menu.keycode]
			if (otherKey == thisKey) then
				return true
			end
		end
	end
end

-- CheckDupKeybindsForMenu
function z:CheckDupKeybindsForMenu()
	for name,menu in pairs(z.options.args.click.args)  do
		if (menu.basename) then
			if (self:DupKeybinds(menu)) then
				menu.name = format("|cFFFF8080%s|r", menu.basename)
			else
				menu.name = menu.basename
			end
		end
	end
end

-- SetDefaultKeybindings
function z:SetDefaultKeybindings()
	self.db.profile.click = z:DefaultClickBindings()
	z:CheckDupKeybindsForMenu()
	if (not InCombatLockdown()) then
		z:UpdateCellSpells()
	end
end

-- SetClickConfigMenu
function z:SetClickConfigMenu()
	if (self:IsRebuffer()) then
		z.options.args.click = {
			type = 'group',
			name = L["Click Config"],
			desc = L["Configure popup raid list click behaviour"],
			order = 250,
			disabled = InCombatLockdown,
			args = {
				default = {
					type = 'execute',
					name = L["Defaults"],
					desc = L["Restore default keybindings"],
					order = 1,
					func = "SetDefaultKeybindings",
				},
				spacer = {
					type = 'header',
					name = " ",
					order = 2,
				}
			}
		}

		local args = z.options.args.click.args

		local module
		self:GetAllActions()

		local function getClick(entry)
			return self.db.profile.click and self.db.profile.click[entry.keycode]
		end

		local function setClick(entry, value)
			local code = entry.keycode
			if (value and not strfind(value, "BUTTON")) then
				return
			end
			if (not self.db.profile.click) then
				self.db.profile.click = {}
			end
			self.db.profile.click[code] = value

			z:CheckDupKeybindsForMenu()

			if (not InCombatLockdown()) then
				z:UpdateCellSpells()
			end
		end

		if (self.actions) then
			for i,action in ipairs(self.actions) do
				args[action.type] = {
					type = 'text',
					name = action.name,
					basename = action.name,
					desc = format(L["Define the mouse click to use for |cFFFFFF80%s|r"], action.desc or action.name),
					validate = "keybinding",
					get = getClick,
					set = setClick,
					keycode = action.type,
					order = i + 10,
				}
				args[action.type].passValue = args[action.type]
			end
			self:CheckDupKeybindsForMenu()
		end
	end
end

-- GetActionClick
function z:GetActionClick(code)
	self:GetAllActions()
	for i,action in ipairs(self.actions) do
		if (action.type == code) then
			local click = self.db.profile.click and self.db.profile.click[code]

			if (click) then
				local mod, button = strmatch(click, "^([ALTSHIFCRL-]+)-BUTTON(%d)$")
				if (not mod and not button) then
					button = strmatch(click, "^BUTTON(%d)$")
				end
				if (mod) then
					mod = strlower(mod).."-"
				end

				return mod, tonumber(button)
			end
		end
	end
end

-- GetBlessingFromType
function z:GetBlessingFromType(t)
	local b = self.blessingsIndex[t]
	if (b) then
		return b.single, b.class, b.short
	end
end

-- LinkSpellRaw
function z:LinkSpellRaw(name, overrideName)
	if (z.linkSpells) then
		local spellLink = GetSpellLink(name)
		local spellID
		if (spellLink) then
			spellID = spellLink:match("|Hspell:(%d+)|h")

			if (spellID) then
				return format("|Hspell:%d|h%s|h|r", spellID, overrideName or name)
			end
		end
	end

	return overrideName or name
end

-- LinkSpell
function z:LinkSpell(name, hexColor, icon, overrideName)
	if (not name) then
		return "?"
	end
	
	if (z.linkSpells and icon) then
		local icon
		if (self.db.profile.spellIcons) then
			icon = select(3, GetSpellInfo(name))
			if (icon) then
				icon = format("|T%s:0|t", icon)
			else
				icon = ""
			end
		else
			icon = ""
		end

		return format("%s%s%s|r", icon, hexColor or "|cFFFFFF80", self:LinkSpellRaw(name, overrideName))
	end

	return format("%s%s|r", hexColor or "|cFFFFFF80", overrideName or name)
end

-- ColourBlessing
function z:ColourBlessing(Type, Class, short, icon)
	if (Type and z.blessingColour[Type]) then
		local singleName, greaterName, shortName = z:GetBlessingFromType(Type)
		local buffName = Class and greaterName or singleName
		return self:LinkSpell(buffName, z.blessingColour[Type], icon, short and shortName)
	else
		return "none"
	end
end

-- HideMeLaterz
local function HideMeLaterz()
	if (not InCombatLockdown()) then
		z.members:Hide()
	end
end

-- OptionsShowList
function z:OptionsShowList()
	if (not InCombatLockdown()) then
		self.members:Show()
		self:ScheduleEvent("ZOMGBuffs_HideMeLaterz", HideMeLaterz, 5)
	end
end

-- OptionsReagentList
function z:MakeOptionsReagentList()
	local place = z.options.args.behaviour.args.reagentlevels
	place.args = {}
	for name, module in z:IterateModules() do
		if (module.reagents) then
			module:MakeReagentsOptions(place.args)
		end
	end
end

-- UnitHasBuff
function z:UnitHasBuff(unit, buffName)
	if (type(buffName) == "number") then
		buffName = GetSpellInfo(buffName)
		assert(buffName, "Invalid spell ID")
	end
	return UnitBuff(unit, buffName)
	--for i = 1,40 do
	--	local name = UnitBuff(unit, i)
	--	if (not name) then
	--		break
	--	end
	--	if (name == buffName) then
	--		return true
	--	end
	--end
end

-- MediaCallback
function z:MediaCallback(mediatype, key)
	if (mediatype == "statusbar" and key == self.db.profile.bartexture and self.waitingForBarTex) then
		self.waitingForBarTex = nil
		self:SetAllBarTextures()
	elseif (mediatype == "font" and key == self.db.char.fontface and self.waitingForFont) then
		self.waitingForFont = nil
		self:ApplyFont()
	end

	if (not self.waitingForBarTex and not self.waitingForFont) then
		SM.UnregisterCallback(self, "LibSharedMedia_Registered")
		SM.UnregisterCallback(self, "LibSharedMedia_SetGlobal")
	end
end

-- GetBarTexture
function z:GetBarTexture()
	local tex = "Interface\\AddOns\\ZOMGBuffs\\Textures\\BantoBar"
	if (SM) then
		tex = SM:Fetch("statusbar", self.db.profile.bartexture)
		if (not tex) then
			self.waitingForBarTex = true
			SM.RegisterCallback(self, "LibSharedMedia_Registered", "MediaCallback")
			SM.RegisterCallback(self, "LibSharedMedia_SetGlobal", "MediaCallback")
		end
	end
	return tex
end

-- SetAllBarTextures()
function z:SetAllBarTextures()
	local tex = self:GetBarTexture()
	for k,cell in pairs(AllFrameArray) do
		cell.bar:SetStatusBarTexture(tex)
	end
end

-- GetFont
function z:GetFont()
	local font = SM and SM:Fetch("font", self.db.char.fontface)
	if (not font) then
		self.waitingForFont = true
		SM.RegisterCallback(self, "LibSharedMedia_Registered", "MediaCallback")
		SM.RegisterCallback(self, "LibSharedMedia_SetGlobal", "MediaCallback")
	end
	return font or "", self.db.char.fontsize, self.db.char.fontoutline
end

-- ApplyFont
function z:ApplyFont()
	local a, b, c = self:GetFont()
	for k,cell in pairs(AllFrameArray) do
		cell.name:SetFont(a, b, c)
	end
end

-- LinkPlayer
function z:LinkPlayer(name)
	return format("|Hplayer:%s|h%s|h", name)
end

-- HexColour
function z:HexColour(r, g, b)
	return format("|cFF%02X%02X%02X", r * 255, g * 255, b * 255)
end

-- ColourGroup
function z:ColourGroup(grp)
	local r, g, b = unpack(self.groupColours[grp])
	return format("|cFF%02X%02X%02XGroup %d|r", r * 255, g * 255, b * 255, grp)
end

-- ColourUnit
function z:ColourUnit(unitid)
	if (unitid) then
		local name = UnitName(unitid)
		if (not name) then
			return unitid
		end
		if (strfind(unitid, "pet")) then
			local ownerid = unitid:gsub("pet", "")
			if (ownerid and UnitExists(ownerid)) then
				return format(L["|cFF808080%s|r [|Hplayer:%s|h%s|h's pet]"], name, UnitName(ownerid), z:ColourUnit(ownerid))
			end
		end
		local c = z:GetClassColour(select(2, UnitClass(unitid)))
		return format("|cFF%02X%02X%02X|Hplayer:%s|h%s|h|r", c.r * 255, c.g * 255, c.b * 255, name, name)
	else
		return "badunit:"..tostring(unitid)
	end
end
z.ColourUnitByName = z.ColourUnit

-- ColourClass
function z:ColourClass(upperClass, prefix, suffix)
	if (upperClass) then
		if (upperClass == "PET") then
			return "Pet"
		else
			local properClass = LOCALIZED_CLASS_NAMES_MALE[upperClass] or upperClass
			local c = self:GetClassColour(upperClass)
			return format("|cFF%02X%02X%02X%s%s%s|r", c.r * 255, c.g * 255, c.b * 255, (prefix and prefix.." ") or "", properClass, (suffix and " "..suffix) or "")
		end
	end
	return "?"
end

-- ColourClassUnit
function z:ColourClassUnit(unit)
	local properClass, upperClass = UnitClass(unit)
	local c = self:GetClassColour(upperClass)
	return format("|cFF%02X%02X%02X%s|r", c.r * 255, c.g * 255, c.b * 255, properClass)
end

-- ReagentExpired
function z:ReagentExpired(reagent)
	if (not self.zoneFlag and z.db.profile.info) then
		if (type(reagent) == "number") then
			reagent = select(2, reagent)
		else
			reagent = format("|cFFFF8080%s|r", reagent)
		end
		if (reagent) then
			self:Print(L["You have run out of %s, now using single target buffs"], reagent)
		end
	end
end

-- noticeOnUpdate
local function noticeOnUpdate(self, elapsed)
	if (self.holdOff > 0) then
		self.holdOff = self.holdOff - elapsed
	else
		local a = max(0, self:GetAlpha() - elapsed)
		if (a <= 0) then
			self:Hide()
			self:SetAlpha(1)
		else
			self:SetAlpha(a)
		end
	end
end

-- CreateMovableNoticeWindow
function z:CreateMovableNoticeWindow()
	local f = self.noticeWindow
	f.finish = CreateFrame("Button", nil, f, "OptionsButtonTemplate")
	f.finish:SetWidth(80)
	f.finish:SetHeight(15)
	f.finish:SetText(L["Finish"])
	f.finish:SetScript("OnClick",
		function(self)
			z.noticeWindow:Hide()
		end)
	f.finish:SetPoint("BOTTOMRIGHT", f, "BOTTOM", -10, 10)

	f.default = CreateFrame("Button", nil, f, "OptionsButtonTemplate")
	f.default:SetWidth(80)
	f.default:SetHeight(15)
	f.default:SetText(DEFAULT)
	f.default:SetScript("OnClick",
		function(self)
			z.noticeWindow:ClearAllPoints()
			z.noticeWindow:SetPoint("CENTER")
			z.db.char.noticePoint = nil
		end)
	f.default:SetPoint("BOTTOMLEFT", f, "BOTTOM", 10, 10)
	self.CreateMovableNoticeWindow = nil
end

-- MovableNoticeWindow
function z:MovableNoticeWindow()
	local f = self.noticeWindow
	if (not f) then
		f = self:CreateNoticeWindow()
	end

	f.lastNotice = nil

	self:Notice(L["Position the notification area"])
	if (not f.finish) then
		self:CreateMovableNoticeWindow()
	else
		f.finish:Show()
		f.default:Show()
	end
		
	f:SetMovable(true)
	
	f:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = true, tileSize = 16,
	})
	f:SetBackdropColor(0, 0.5, 0, 1)
	f:EnableMouse(true)
	f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart",
		function(self)
			self:StartMoving()
		end)
	f:SetScript("OnDragStop",
		function(self)
			self:StopMovingOrSizing()
			z.db.char.noticePoint = {self:GetPoint(1)}
		end)

	f:SetScript("OnHide",
		function(self)
			self.finish:Hide()
			self.default:Hide()
			self:SetMovable(false)
			self:SetBackdrop(nil)
			self:SetScript("OnDragStart", nil)
			self:SetScript("OnDragStop", nil)
			self:EnableMouse(false)
			self:SetScript("OnHide", nil)
			self:SetScript("OnUpdate", noticeOnUpdate)
		end)

	f:SetScript("OnUpdate", nil)
end

-- CreateNoticeWindow
function z:CreateNoticeWindow()

	local f = CreateFrame("Frame", nil, UIParent)
	self.noticeWindow = f
	f.holdOff = 0
	f.lastNoticeTime = 0

	f:SetWidth(400)
	f:SetHeight(100)
	f:SetClampedToScreen(true)

	if (type(z.db.char.noticePoint) == "table") then
		f:SetPoint(unpack(z.db.char.noticePoint))
	else
		f:SetPoint("CENTER")
	end

	f.text = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	f.text:SetAllPoints()
	f.text:SetTextColor(1, 1, 1)
	f.text:SetJustifyH("CENTER")
	f.text:SetJustifyV("MIDDLE")

	f:SetScript("OnUpdate", noticeOnUpdate)

	self:RestorePosition(self.noticeWindow, self.db.profile.posNotice)

	self.CreateNoticeWindow = nil

	return f
end

-- ClearNotice
function z:ClearNotice()
	local f = self.noticeWindow
	if (f) then
		f.lastNoticeTime = 0
		f.lastNotice = nil
		f.holdOff = 0
		f:SetAlpha(1)
		f:Hide()
	end
end

-- Notice
function z:Notice(notice, sound)
	if (self.db.profile.notice) then
		if (notice ~= self.lastNotice or self.lastNoticeTime < GetTime() - 15) then
			self.lastNoticeTime = GetTime()
			self.lastNotice = notice

			if (sound and SM) then
				PlaySoundFile(SM:Fetch("sound", z.db.profile[sound]))
			end

			if (Sink and self.db.profile.usesink) then
				self:Pour(notice)
			else
				local f = self.noticeWindow
				if (not f) then
					f = self:CreateNoticeWindow()
				end
				f.holdOff = 3
				f.text:SetText(notice)
				f:SetAlpha(1)
				f:Show()
			end
		end
	end
end

-- Report
function z:Report(option)
	if (not IsRaidOfficer() and not IsRaidLeader()) then
		return
	end

	if (option == "missing") then
		local list = new()
		local flags = new()
		local groupCounts = new(0, 0, 0, 0, 0, 0, 0, 0)
		local groupList = new(new(), new(), new(), new(), new(), new(), new(), new())
		local blessingsMissing = new()
		local blessingsGot = new()

		for partyid, name, class, subgroup, index in self:IterateRoster() do
			flags.STA, flags.MARK, flags.INT, flags.SPIRIT, flags.BLESSINGS = nil, nil, nil, nil, nil
			if (UnitIsConnected(partyid) and not UnitIsDeadOrGhost(partyid)) then
				groupCounts[subgroup] = groupCounts[subgroup] + 1
				for i = 1,40 do
					local name, rank, buff, count, _, max, endTime = UnitBuff(partyid, i)
					if (not name) then
						break
					end

					for j,one in pairs(z.buffs) do
						if (z.classcount[one.class] > 0) then
							if (one.list[name]) then
								local t = one.type
								flags[t] = true
							end
						else
							flags[one.type] = true			-- Missing buff class, so flag it anyway
						end
					end

					local b = z.blessings[name]
					if (b) then
						flags.BLESSINGS = (flags.BLESSINGS or 0) + 1
					end
				end

				if (not flags.STA and self.classcount.PRIEST > 0) then
					if (not list.STA) then
						list.STA = new()
					end
					tinsert(list.STA, name)
					groupList[subgroup].STA = (groupList[subgroup].STA or 0) + 1
				end
				if (not flags.MARK and self.classcount.DRUID > 0) then
					if (not list.MARK) then
						list.MARK = new()
					end
					tinsert(list.MARK, name)
					groupList[subgroup].MARK = (groupList[subgroup].MARK or 0) + 1
				end
				if (self.manaClasses[class]) then
					if (not flags.INT and self.classcount.MAGE > 0) then
						if (not list.INT) then
							list.INT = new()
						end
						tinsert(list.INT, name)
						groupList[subgroup].INT = (groupList[subgroup].INT or 0) + 1
					end
					if (not flags.SPIRIT) then
						if (not list.SPIRIT) then
							list.SPIRIT = new()
						end
						tinsert(list.SPIRIT, name)
						groupList[subgroup].SPIRIT = (groupList[subgroup].SPIRIT or 0) + 1
					end
				end
				if ((flags.BLESSINGS or 0) < self.classcount.PALADIN) then
					if (not list.BLESSINGS) then
						list.BLESSINGS = new()
					end
					tinsert(list.BLESSINGS, name)
					blessingsMissing[class] = (blessingsMissing[class] or 0) + 1
				else
					blessingsGot[class] = (blessingsGot[class] or 0) + 1
				end
			end
		end

		-- Scan the groups for any who are completely missing a buff and replace the individual names with 'Group X'
		for i = 8,1,-1 do
			if (groupCounts[i] > 0) then
				for k,v in pairs(groupList[i]) do
					if (v == groupCounts[i]) then
						tinsert(list[k], 1, format(L["Group %d"], i))
						for unit, name, class, subgroup, index in self:IterateRoster() do
							if (subgroup == i) then
								for j = 1,#list[k] do
									if (list[k][j] == name) then
										tremove(list[k], j)
										break
									end
								end
							end
						end
					end
				end
			end
		end
		
		for i,class in ipairs(classOrder) do
			if ((blessingsMissing[class] or 0) > 0) then
				if ((blessingsGot[class] or 0) == 0) then
					tinsert(list.BLESSINGS, LOCALIZED_CLASS_NAMES_MALE[class] or class)

					for unit, unitname, unitclass, subgroup, index in self:IterateRoster() do
						if (class == unitclass) then
							for j,name in ipairs(list.BLESSINGS) do
								if (name == unitname) then
									tremove(list.BLESSINGS, j)
									break
								end
							end
						end
					end
				end
			end
		end

		for k,v in pairs(list) do
			sort(v)
			SendChatMessage(format(L["<ZOMG> Missing %s: %s"], ShortDesc(k), table.concat(v, ", ")), strupper(self.db.profile.channel) or "RAID")
		end

		del(list)
		deepDel(groupList)
		del(groupCounts)
		del(flags)
		del(blessingsMissing)
		del(blessingsGot)
	end
end

-- SetIconSize
function z:SetIconSize()
	if (self.db.char.showicon) then
		self.icon:Show()
		self.icon:SetScale(self.db.char.iconsize / 36)
		self.icon:SetAttribute("*childstate-OnEnter", "enter")
		self.icon:SetClampedToScreen(true)
		self:RestorePosition(self.icon, self.db.char.pos)
	else
		self.icon:Hide()
		self.icon:SetAttribute("*childstate-OnEnter", nil)
		self.icon:SetClampedToScreen(false)
		self.icon:ClearAllPoints()
		self.icon:SetPoint("TOPLEFT", UIParent, "BOTTOMRIGHT", 50, -50)		-- Push it off the screen
	end

	-- Border
	--local border
	--border = self.icon.border
	--if (self.db.char.iconborder) then
	--	if (not border) then
	--		border = self:CreateBorder(self.icon)
	--		self.icon.border = border
	--	end
	--	border:Show()
	--else
	--	if (border) then
	--		border:Hide()
	--	end
	--end

	if (self.db.profile.iconname) then
		self.icon.name:Show()
	else
		self.icon.name:Hide()
	end
end

-- CreateBorder
function z:CreateBorder(parent)
	local border = CreateFrame("Frame", nil, parent)
	border:SetPoint("TOPLEFT", -4, 4)
	border:SetPoint("BOTTOMRIGHT", 4, -4)
	border:SetFrameStrata("LOW")
	border:SetFrameLevel(parent:GetFrameLevel() + 1)

	border:SetBackdrop({
		--bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", tile = true, tileSize = 16,
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 16,
		insets = { left = 5, right = 5, top = 5, bottom = 5 }
	})
	border:SetBackdropColor(0,0,0,1)
	border:SetBackdropBorderColor(0.5,0.5,0.5,1)

	return border
end

-- GetPosition
function z:GetPosition(frame)
	if (frame) then
		if (frame:IsResizable()) then
			return {point = {frame:GetPoint(1)}, width = frame:GetWidth(), height = frame:GetHeight()}
		else
			return {point = {frame:GetPoint(1)}}
		end
	end
end

-- RestorePosition
function z:RestorePosition(frame, pos)
	if (pos and pos.point) then
		frame:ClearAllPoints()
		frame:SetPoint(unpack(pos.point))

		if (pos.height and pos.width and frame:IsResizable()) then
			frame:SetWidth(pos.width)
			frame:SetHeight(pos.height)
		end
	end
end

-- z:SetAnchors()
function z:SetAnchors()
	--local d = self.db.char.iconborder and 5 or 0
	local d = 0
	self.members:ClearAllPoints()
	self.members:SetPoint(self.db.char.anchor or "BOTTOMRIGHT", self.icon, self.db.char.relpoint or "TOPLEFT", 0, d)
	self.icon:SetHitRectInsets(-d, -d, -d, -d)
end

-- CanLearn
function z:CanLearn()
	return (InCombatLockdown() and self.db.char.learncombat) or self.db.char.learnooc
end

-- GlobalCDSchedule
function z:GlobalCDSchedule()
	self:CancelScheduledEvent("ZOMGBuffs_GlobalCooldownEnd")
	local when = self.globalCooldownEnd - GetTime() + 0.1
	if (when <= 0) then
		when = 0.1
	end
	self:ScheduleEvent("ZOMGBuffs_GlobalCooldownEnd", self.GlobalCooldownEnd, when, self)
end

local HasIllusionBuff
do
	local worgIllusion = GetSpellInfo(43369)			-- Worg Disguise
	local murlocIllusion = GetSpellInfo(45278)			-- King Mrgl-Mrgl's Spare Suit

	function HasIllusionBuff()
		return UnitAura("player", worgIllusion) or UnitAura("player", murlocIllusion)
	end
end

local invisibility = GetSpellInfo(32612)

-- CheckMounted
function z:CheckMounted()
	if (self.checkMountedCounter and self.checkMountedCounter > 0) then
		self.checkMountedCounter = self.checkMountedCounter - 1
		self:ScheduleEvent("ZOMGBuffs_CheckMounted", self.CheckMounted, 0.2, self)
	end

	if (not InCombatLockdown()) then
		local m = IsMounted()
		if (self.mounted ~= m) then
			self.mounted = m
			if (m) then
				self.checkMountedCounter = nil
				self:SetupForSpell()
				if (ZOMGSelfBuffs) then
					ZOMGSelfBuffs:CheckBuffs()
				end
				return
			end
		end
	end
end

-- StartCheckMounted
function z:StartCheckMounted()
	if (not InCombatLockdown()) then
		-- self:Print("UNIT_AURA - z.mounted = "..tostring(z.mounted)..", IsMounted() = "..tostring(IsMounted()))
		self:CancelScheduledEvent("ZOMGBuffs_CheckMounted")
		if (not IsMounted()) then
			-- Nasty hack, because IsMounted() does not work immediately after
			-- the player gains a mount buff, as it did with PLAYER_AURAS_CHANGED
			-- Currently, there are no events fired when IsMounted() is toggled on
			-- Might have to do an OnUpdate check
			self:ScheduleEvent("ZOMGBuffs_CheckMounted", self.CheckMounted, 0.2, self)
			self.checkMountedCounter = 4
		end
		self:CheckMounted()
		self:CheckForChange(self)
	end
end

-- CanCheckBuffs
function z:CanCheckBuffs(allowCombat, soloBuffs)
	lastCheckFail = nil
	local icon, icontex
	local p = self.db.profile

	if (self.atVendor) then
		return false, L["Selling"]
	elseif (self.atTrainer) then
		return false, L["Training"]
	elseif (self.rosterInvalid and not soloBuffs) then
		return false, "Waiting for RosterLib update"
	elseif (self.zoneFlag and self.zoneFlag > GetTime() - 5) then
		return false, L["ZONED"]
	elseif (UnitIsDeadOrGhost("player")) then
		lastCheckFail = L["DEAD"]
		icon = "skull"
	elseif (not self.icon) then
		lastCheckFail = L["ERRORICON"]
	elseif (not p.enabled) then
		lastCheckFail = L["DISABLED"]
		icon = "disabled"
	elseif (UnitOnTaxi("player")) then
		lastCheckFail = L["TAXI"]
		icon = "flying"
	elseif (UnitInVehicle("player")) then
		lastCheckFail = L["VEHICLE"]
		icon = "flying"
	elseif (InCombatLockdown() and not allowCombat) then
		lastCheckFail = L["COMBAT"]
		icon = "combat"
	elseif (HasIllusionBuff()) then		-- (UnitExists("pet") and (UnitIsCharmed("pet") or UnitIsPlayer("pet"))) or 
		lastCheckFail = L["REMOTECONTROL"]
		icon = "remote"
	elseif (UnitIsCharmed("player")) then
		lastCheckFail = L["NOCONTROL"]
		icon = "nocontrol"
	elseif (IsStealthed() and p.notstealthed) then
		lastCheckFail = L["STEALTHED"]
		icon = "stealth"
	elseif (UnitBuff("player", invisibility)) then
		lastCheckFail = L["INVIS"]
		icon = "icon"
		icontex = select(3, GetSpellInfo(32612))
	elseif (GetShapeshiftForm() > 0 and (playerClass == "DRUID" or playerClass == "SHAMAN") and p.notshifted) then
		lastCheckFail = L["SHAPESHIFTED"]
		icon = "icon"
		icontex = GetShapeshiftFormInfo(GetShapeshiftForm())
	elseif (self.icon:GetAttribute("spell") or self.icon:GetAttribute("item")) then
		return false, "Already have an icon"
	elseif (self.globalCooldownEnd > GetTime()) then
		self:GlobalCDSchedule()
		return false, "Waiting for global cooldown"
	end

	if (not lastCheckFail and not InCombatLockdown()) then
		if (IsResting() and p.notresting and not (p.restingpvp and UnitIsPVP("player"))) then
			lastCheckFail = L["RESTING"]
			icon = "resting"
		elseif ((IsMounted() or IsFlying()) and p.notmounted) then
			lastCheckFail = L["MOUNTED"]
			icon = "mounted"
		elseif (self:UnitHasBuff("player", 46755)) then		-- Drink
			lastCheckFail = L["DRINKING"]
			icon = "drink"
		elseif (self:UnitHasBuff("player", 46898)) then		-- Food
			lastCheckFail = L["EATING"]
			icon = "food"
		elseif (UnitChannelInfo("player")) then
			lastCheckFail = L["CHANNELING"]
			local name, nameSubtext, text, texture, startTime, endTime, isTradeSkill = UnitChannelInfo("player")
			icon = "icon"
			icontex = texture
		elseif (playerClass == "PRIEST" and p.notWithSpiritTap) then
			if (self:UnitHasBuff("player", 15271)) then		-- Spirit Tap
				lastCheckFail = L["SPIRITTAP"]
				icon = "spirittap"
			end
		elseif (self.db.char.minmana > 0) then
			local mana, manamax = UnitMana("player"), UnitManaMax("player")
			if (mana / manamax * 100 < self.db.char.minmana) then
				lastCheckFail = L["MANA"]
				icon = "mana"

				if (not self:IsEventRegistered("UNIT_MANA")) then
					self:RegisterEvent("UNIT_MANA")
				end
			end
		end
	end

	self:SetStatusIcon(icon, icontex)

	if (not lastCheckFail) then
		if (self:IsEventRegistered("UNIT_MANA")) then
			self:UnregisterEvent("UNIT_MANA")
		end
	end

	return not lastCheckFail, lastCheckFail
end

-- SetStatusIcon
function z:SetStatusIcon(t, spellIcon)
	if (not self.icon) then
		return
	end

	local coords, status

	if (t == "skull") then
		status = "Interface\\TargetingFrame\\UI-TargetingFrame-Skull"

	elseif (t == "resting") then
		status = "Interface\\CharacterFrame\\UI-StateIcon"
		coords = new(0, 0.5, 0, 0.49)

	elseif (t == "combat") then
		status = "Interface\\CharacterFrame\\UI-StateIcon"
		coords = new(0.5, 1, 0, 0.49)

	elseif (t == "flying") then
		status = "Interface\\Icons\\Ability_Mount_Wyvern_01"
		coords = new(0.05, 0.95, 0.05, 0.95)

	elseif (t == "vehicle") then
		status = "Interface\\Icons\\Ability_Mount_Wyvern_01"

	elseif (t == "mounted") then
		status = "Interface\\Icons\\Ability_Mount_Wyvern_01"
		coords = new(0.05, 0.95, 0.05, 0.95)

	elseif (t == "mana") then
		status = "Interface\\Icons\\INV_Potion_76"

	elseif (t == "drink") then
		status = "Interface\\Icons\\INV_Drink_07"

	elseif (t == "food") then
		status = "Interface\\Icons\\INV_Drink_07"

	elseif (t == "spirittap") then
		status = select(3, GetSpellInfo(15338))			-- Spirit Tap

	elseif (t == "remote") then
		status = select(3, GetSpellInfo(45112))			-- Mind Control

	elseif (t == "nocontrol") then
		status = "Interface\\Icons\\Ability_Rogue_BloodyEye"
		
	elseif (t == "stealth") then
		status = "Interface\\Icons\\Ability_Stealth"

	elseif (t == "icon") then
		status = spellIcon
		spellIcon = nil
		
	elseif (z.waitingForRaid or z.waitingForClass) then
		status = "Interface\\Addons\\ZOMGBuffs\\Textures\\Clock"
	end

	if (not spellIcon) then
		local icon
		if (self.db.profile.enabled) then
			icon = "Interface\\AddOns\\ZOMGBuffs\\Textures\\Icon"
		else
			icon = "Interface\\AddOns\\ZOMGBuffs\\Textures\\IconOff"
		end
		self:SetMainIcon(icon)

		local icon = self:GetMainIcon()
		if (self.db.char.classIcon) then
			local i = classIcons[playerClass]
			if (not i) then
				self.icon.name:Hide()
			else
				icon = i
				if (self.db.profile.iconname) then
					self.icon.name:Show()
				end
				if (self.db.profile.enabled) then
					self.icon.tex:SetVertexColor(1, 1, 1)
					self.icon.tex:SetDesaturated(nil)
					self.icon.name:SetDesaturated(nil)
				else
					self.icon.name:SetDesaturated()
					if (not self.icon.tex:SetDesaturated()) then
						self.icon.tex:SetVertexColor(0.5, 0.5, 0.5)
					end
				end
			end
		end

		self.icon.tex:SetTexture(icon)

		if (status and self.icon.tex:IsShown()) then
			self.icon.status:SetTexture(status)
			self.icon.status:Show()

			if (coords) then
				self.icon.status:SetTexCoord(unpack(coords))
				del(coords)
			else
				self.icon.status:SetTexCoord(0, 1, 0, 1)
			end
		else
			self.icon.status:Hide()
		end
	else
		self.icon.name:Hide()
		self.icon.tex:SetTexture(spellIcon)
		self.icon.status:Hide()
	end
end

-- Set1CellAttr
local cellAttributeChanges = nil
local function Set1CellAttr(self, k, v)
	if (self:GetAttribute(k) ~= v) then
		if (InCombatLockdown() and not z.canChangeFlagsIC) then		-- canChangeFlagsIC is active during a cells creation, the only valid time we can change attr in combat
			local unit = self:GetAttribute("unit")
			local name = unit and UnitName(unit)

			if (name) then
				if (not cellAttributeChanges) then
					cellAttributeChanges = new()
				end
				if (not cellAttributeChanges[name]) then
					cellAttributeChanges[name] = new()
				end
				cellAttributeChanges[name][k] = v
			end

			return true			-- true = invalid for the moment until out of combat
		else
			self:SetAttribute(k, v)
			if (not self.attr) then
				self.attr = new()
			end
			self.attr[k] = v
		end
	end
end

-- SetACellSpell
function z:SetACellSpell(cell, m, b, spell)
	if (b) then
		local mod = m or ""
		local spellType = spell and "spell"
		local i1 = Set1CellAttr(cell, mod.."type"..b, spellType)
		local i2 = Set1CellAttr(cell, mod.."spell"..b, spell)
		cell.invalidAttributes = (i1 or i2) and spell
	end
end

-- ClearClickSpells
function z:ClearClickSpells(cell)
	if (cell and cell.attr) then
		cell.invalidAttributes = nil
		if (not InCombatLockdown()) then
			-- If in combat, then unit is probably nil and we'll clear the cell when we need this cell again anyway
			for key,action in pairs(cell.attr) do
				if (Set1CellAttr(cell, key, nil)) then
					cell.invalidAttributes = L["Empty"]
				end
				cell.attr[key] = nil
			end
		end
	end
end

-- IsSpellReady
function z:IsSpellReady()
	return self.icon:GetAttribute("*type*") ~= nil
end

-- SetupForSpell
function z:SetupForSpell(unit, spell, mod, reagentCount)
	local icon = self.icon
	if (not icon) then
		return
	end
	if (spell) then
		if (icon:GetAttribute("spell") or self.icon:GetAttribute("item")) then
			return
		end
	end

	if (icon:GetAttribute("*type*") ~= spell and "spell") then
		icon:SetAttribute("*type*", spell and "spell")
	end
	if (icon:GetAttribute("spell") ~= spell) then
		icon:SetAttribute("spell", spell)
	end
	if (icon:GetAttribute("unit") ~= unit) then
		icon:SetAttribute("unit", unit)
	end
	if (icon:GetAttribute("item") ~= nil) then
		icon:SetAttribute("item", nil)
	end
	if (icon:GetAttribute("target-slot") ~= nil) then
		icon:SetAttribute("target-slot", nil)
	end

	icon.mod = mod or icon.mod
	icon.castTimeToGCD = castTime
	icon.autospell = nil

	if (spell) then
		if (reagentCount) then
			self.icon.count:SetText(reagentCount)
			self.icon.count:Show()
		else
			self.icon.count:Hide()
		end
		self:SetStatusIcon(t, mod:GetSpellIcon(spell))
		if (self.db.profile.iconswirl) then
			self.icon.auto:Show()
		else
			self.icon.auto:Hide()
		end
	else
		self:ClearNotice()
		self:SetStatusIcon()
		self.icon.auto:Hide()
		self.icon.count:Hide()
		--if (ZOMGSelfBuffs) then
		--	ZOMGSelfBuffs.activeEnchant = nil
		--end
	end
end

-- SetupForSpell
function z:SetupForItem(slot, item, mod, spell, castTime)
	local icon = self.icon
	if (item or spell) then
		if (icon:GetAttribute("spell") or icon:GetAttribute("item")) then
			return
		end
	end

	icon:SetAttribute("*type*", item and "item" or spell and "spell")
	icon:SetAttribute("item", item)
	icon:SetAttribute("target-slot", slot)
	icon:SetAttribute("spell", spell)
	icon:SetAttribute("unit", nil)
	icon.mod = mod or icon.mod
	icon.autospell = nil
	icon.castTimeToGCD = castTime

	if (item) then
		local itemName, itemString, itemQuality, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture = GetItemInfo(item)
		self:SetStatusIcon(nil, itemTexture)
		if (self.db.profile.iconswirl) then
			icon.auto:Show()
		else
			icon.auto:Hide()
		end

		local reagentCount = GetItemCount(item)
		if (reagentCount) then
			icon.count:SetText(reagentCount)
			icon.count:Show()
		else
			icon.count:Hide()
		end
	elseif (spell) then
		self:SetStatusIcon(nil, mod:GetSpellIcon(spell))
		if (self.db.profile.iconswirl) then
			icon.auto:Show()
		else
			icon.auto:Hide()
		end
		icon.count:Hide()
	else
		self:ClearNotice()
		self:SetStatusIcon()
		icon.auto:Hide()
		icon.count:Hide()
		--if (ZOMGSelfBuffs) then
		--	ZOMGSelfBuffs.activeEnchant = nil
		--end
	end
end

-- SetSort
function z:SetSort(show)
	if (show) then
		self.menu:SetAttribute("state", 0)
	end

	if (z.db.char.sort == "CLASS") then
		self.members:SetAttribute("sortMethod", "NAME")
		self.members:SetAttribute("groupingOrder", table.concat(classOrder, ","))
		self.members:SetAttribute("groupBy", "CLASS")

	elseif (z.db.char.sort == "ALPHA") then
		self.members:SetAttribute("sortMethod", "NAME")
		self.members:SetAttribute("groupBy", nil)
		self.members:SetAttribute("groupingOrder", nil)

	elseif (z.db.char.sort == "GROUP") then
		self.members:SetAttribute("sortMethod", nil)
		self.members:SetAttribute("groupingOrder", "1,2,3,4,5,6,7,8")
		self.members:SetAttribute("groupBy", "GROUP")

	else
		self.members:SetAttribute("sortMethod", nil)
		self.members:SetAttribute("groupBy", nil)
		self.members:SetAttribute("groupingOrder", nil)
	end

	if (show) then
		self:OptionsShowList()
	end
end

-- CreateAutoCast
function z:CreateAutoCast(icon)
	local a = CreateFrame("Frame", nil, icon)
	a:Hide()
	a:SetAllPoints()
	a.tex = {}
	for i = 1,2 do
		a.tex[i] = a:CreateTexture(nil, "OVERLAY")
		a.tex[i]:SetTexture("Interface\\BUTTONS\\UI-AutoCastableOverlay")
		a.tex[i]:SetTexCoord(0.1, 0.9, 0.1, 0.9)
		a.tex[i]:SetAllPoints()

		local g = a.tex[i]:CreateAnimationGroup()
		a.tex[i].anim = g
		local r = g:CreateAnimation("Rotation")
		g.rotate = r

		r:SetDuration(4 + i * 0.5)
		r:SetDegrees(i == 1 and 360 or -360)
		r:SetOrigin("CENTER", 0, 0)
		g:SetLooping("REPEAT")
	end
	a:SetScript("OnShow",
		function(self)
			for i,tex in ipairs(self.tex) do
				tex.anim:Play()		-- Bugfix for animations getting hidden (still in WoW 3.1.1a)
				tex.anim:Stop()
				tex.anim:Play()
			end
		end
	)
	return a
end

-- z:OnStartup
function z:OnStartup()
	local icon = CreateFrame("Button", "ZOMGBuffsButton", UIParent, "SecureUnitButtonTemplate,SecureHandlerEnterLeaveTemplate,ActionButtonTemplate")

	local LibButtonFacade = LibStub("LibButtonFacade",true)
	if (LibButtonFacade) then
		if (self.db.char.ButtonFacade) then
			LibButtonFacade:Group("ZOMGBuffs", "Buffs"):Skin(unpack(self.db.char.ButtonFacade))
		end
		LibButtonFacade:RegisterSkinCallback("ZOMGBuffs",
			function(_, skin, glossAlpha, gloss, _, _, colors)
				local db = self.db.char
				local bf = db.ButtonFacade
				if (bf) then		-- Don't create lots of tables. ever!
					bf[1] = skin
					bf[2] = glossAlpha
					bf[3] = gloss
					bf[4] = colors
				else
					db.ButtonFacade = {skin, glossAlpha, gloss, colors}
				end
			end
		)

		LibButtonFacade:Group("ZOMGBuffs", "Buffs"):AddButton(icon)
	end

	self:UpdateListWidth()

	self.icon = icon
	icon:SetClampedToScreen(true)
	icon:SetHeight(32)
	icon:SetWidth(32)
	icon.tex = ZOMGBuffsButtonIcon
	icon.tex:SetTexture("Interface\\AddOns\\ZOMGBuffs\\Textures\\Icon")
	icon:SetPoint("CENTER")
	icon:SetMovable(true)
	icon:RegisterForClicks("AnyUp")

	icon.name = icon:CreateTexture(nil, "OVERLAY")
	icon.name:SetAllPoints()
	icon.name:SetTexture("Interface\\AddOns\\ZOMGBuffs\\Textures\\IconText")

	icon.status = icon:CreateTexture(nil, "OVERLAY")
	icon.status:SetPoint("BOTTOMRIGHT", -1, 1)
	icon.status:SetWidth(18)
	icon.status:SetHeight(18)
	icon.status:Hide()

	icon.auto = self:CreateAutoCast(icon)

	icon.count = icon:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
	icon.count:Hide()
	icon.count:SetPoint("TOPLEFT")
	icon.count:SetPoint("BOTTOMRIGHT", -2, 2)
	icon.count:SetJustifyH("RIGHT")
	icon.count:SetJustifyV("BOTTOM")

	icon:SetScript("OnDragStart",
		function(self)
			if (not z.db.char.iconlocked) then
				self:StartMoving()
			end
		end)
	icon:SetScript("OnDragStop",
		function(self)
			self:StopMovingOrSizing()
			z.db.char.pos = z:GetPosition(self)
		end)
	icon:HookScript("OnEnter", IconOnEnter)
	icon:HookScript("OnLeave", IconOnLeave)
	icon:HookScript("OnClick",
		function(self, button)
			local command
			if (z.db.profile.mousewheel) then
				command = GetBindingAction(button)
			elseif (z.db.profile.keybinding) then
				command = GetBindingAction(z.db.profile.keybinding)
			end
			if (command) then
				pcall(RunBinding, command)
			end

			if (self:GetAttribute("*type*")) then
				z.clickCast = true
				z.clickList = nil

				if (z.noticeWindow) then
					z.noticeWindow:Hide()
				end

				z.globalCooldownEnd = GetTime() + (self.castTimeToGCD or 1.5)
				--if (ZOMGSelfBuffs) then
				--	ZOMGSelfBuffs.activeEnchant = nil
				--end
				z:GlobalCDSchedule()

				z:SetupForSpell()
			end
		end)

	icon.UpdateTooltip = IconOnEnter

	icon:RegisterForDrag("LeftButton")

	icon:SetAttribute("_onenter", [[
			local list = self:GetFrameRef("list")
			if (list) then
				list:Show()
			end
		]])
	icon:SetAttribute("_onleave", [[
			local list = self:GetFrameRef("list")
			if (list and not list:IsUnderMouse(true) and not self:IsUnderMouse(true)) then
				list:Hide()
			end
		]])

	local members = CreateFrame("Frame", "ZOMGBuffsList", icon, "SecureRaidGroupHeaderTemplate")
	members:Hide()
	self.members = members
	self:SetVisibilityOption()
	members:UnregisterEvent("UNIT_NAME_UPDATE")				-- Fix for that old lockup issue
	members:SetClampedToScreen(true)
	members:SetClampRectInsets(0, 8, z.db.char.height, 0)
	members:SetWidth(z.totalListWidth or self.db.char.width)
	members:SetHeight(self.db.char.height)
	members:SetFrameStrata("DIALOG")

	icon:SetFrameRef("list", members)				-- So the icon can access the list via GetFrameRef shown above

	members:HookScript("OnShow", function(self) z:DrawGroupNumbers() z:RegisterEvent("MODIFIER_STATE_CHANGED") end)
	members:HookScript("OnHide", function(self) z:UnregisterEvent("MODIFIER_STATE_CHANGED") end)

	self.onLeaveFuncString = [[
			local list = self:GetParent()
			if (list and not list:IsUnderMouse(true) and not list:GetParent():IsUnderMouse(true)) then
				list:Hide()
			end
		]]

	members.initialConfigFunction = function(self)
		-- This is the only place we're allowed to set attributes whilst in combat

		z:SetTargetClick(self, true)

		self:SetAttribute("initial-width", z.totalListWidth or z.db.char.width)
		self:SetAttribute("initial-height", z.db.char.height)

		z:InitCell(self)

		-- Get initial list item spell, even works in-combat! zomg
		z.canChangeFlagsIC = true
		z:UpdateOneCellSpells(self)
		z.canChangeFlagsIC = nil

		if (not InCombatLockdown()) then
			self.wrapped = true
			SecureHandlerWrapScript(self, "OnEnter", members, "")
			SecureHandlerWrapScript(self, "OnLeave", members, z.onLeaveFuncString)
		end
	end

	members:SetAttribute("template", "SecureUnitButtonTemplate")
	members:SetAttribute("sortMethod", "NAME")

	WorldFrame:HookScript("OnMouseDown", function()
		if (not InCombatLockdown()) then
			z.members:Hide()
		end
	end)

	self:SetAnchors()

	if (not InCombatLockdown()) then
		if (GetNumRaidMembers() > 0 or GetNumPartyMembers() > 0) then
			self.members:Hide()
			self.members:Show()
		end
		self.members:Hide()
	end

	self.OnStartup = nil
end

-- SetTargetClick
function z:SetTargetClick(cell, secure)
	local targetMod, targetButton = self:GetActionClick("target")
	if (targetButton) then
		targetMod = targetMod or ""

		-- TODO: *typeN for target if nothing else on that button
		if (secure) then
			cell:SetAttribute(targetMod.."type"..targetButton, "target")
			local key = targetMod.."type"..targetButton
			if (not cell.attr) then
				cell.attr = new()
			end
			cell.attr[key] = "target"
		else
			Set1CellAttr(cell, targetMod.."type"..targetButton, "target")
		end
	end
end

-- SetVisibilityOption
function z:SetVisibilityOption()
	if (not InCombatLockdown()) then
		self.members:SetAttribute("showRaid", self.db.profile.showRaid)					-- So it works for raid group
		self.members:SetAttribute("showParty", self.db.profile.showParty)				-- So it works in a party
		self.members:SetAttribute("showPlayer", self.db.profile.showParty)				-- So it works for self in party
		self.members:SetAttribute("showSolo", self.db.profile.showSolo)					-- So it works when solo
	end
end

-- SayWhatWeDid
function z:SayWhatWeDid(spell, name, rank)
	if (self.icon.mod and self.icon.mod.SayWhatWeDid) then
		self.icon.mod:SayWhatWeDid(self.icon, spell, name, rank)
	end
end

-- onAttrChanged
local function onCellAttrChanged(self, name, value)
	if (name == "unit") then
		-- Maintain a unitid -> unit frame table
		for k,v in pairs(FrameArray) do
			if (v == self) then
				FrameArray[k] = nil
				break
			end
		end
		self.partyid = value
		if (value) then
			FrameArray[value] = self
		end

		if (value) then
			if (self.lastID ~= value or self.lastName ~= UnitName(value)) then
				self.lastID = value
				self.lastName = UnitName(value)

				self:DrawCell()

				z:UpdateOneCellSpells(self)
			end
		else
			if (cellAttributeChanges and self.lastName) then
				cellAttributeChanges[self.lastName] = deepDel(cellAttributeChanges[self.lastName])
			end

			z:ClearClickSpells(self)

			self.lastID = nil
			self.lastName = nil
		end
	end
end

local defaultColour = {r = 0.5, g = 0.5, b = 1}
function z:GetClassColour(class)
	return (class and (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[class]) or defaultColour
end

-- MakePalaIcon
local function MakePalaIcons(self)
	local prev
	if (z.db.profile.track.blessings) then
		if (self.palaIcon and #self.palaIcon > 0) then
			prev = self.palaIcon[#self.palaIcon]
		end

		while (not self.palaIcon or #self.palaIcon < z.classcount.PALADIN) do
			local b = self:CreateTexture(nil, "ARTWORK")
			b:SetHeight(z.db.char.height)
			b:SetWidth(z.db.char.height)
			if (prev) then
				b:SetPoint("TOPLEFT", prev, "TOPRIGHT", 0, 0)
			end
			tinsert(self.palaIcon, b)
			prev = b
		end
	end

	prev = self.buff[#z.buffs]
	if (self.palaIcon[1]) then
		self.palaIcon[1]:ClearAllPoints()
		if (not prev) then
			self.palaIcon[1]:SetPoint("TOPLEFT")
		else
			self.palaIcon[1]:SetPoint("TOPLEFT", prev, "TOPRIGHT", 0, 0)
		end

		for i = 1,#self.palaIcon do
			self.palaIcon[i]:SetTexture(nil)
		end

		if (z.db.profile.track.blessings and z.classcount.PALADIN > 0) then
			prev = self.palaIcon[z.classcount.PALADIN]
		end
	end

	self.bar:ClearAllPoints()
	if (prev) then
		self.bar:SetPoint("TOPLEFT", prev, "TOPRIGHT")
	else
		self.bar:SetPoint("TOPLEFT")
	end
	self.bar:SetPoint("BOTTOMRIGHT")

	if (btr) then
		btr:CheckTickColumns(self)
	end
end

-- z:SetAllBarSizes()
function z:SetAllBarSizes()
	self:UpdateListWidth()
	if (AllFrameArray and not InCombatLockdown() and self.members) then
		local w = self.totalListWidth or self.db.char.width
		local h = self.db.char.height

		self.members:SetClampRectInsets(0, 8, h, 0)

		for k,v in pairs(AllFrameArray) do
			v:SetHeight(h)
			v:SetWidth(w)

			MakePalaIcons(v)

			for i,icon in pairs(v.palaIcon) do
				icon:SetWidth(h)
				icon:SetHeight(h)
			end

			for i,icon in pairs(v.buff) do
				icon:SetWidth(h)
				icon:SetHeight(h)
			end
		end
	end
end

-- PeriodicListCheck
function z:PeriodicListCheck()
	local any
	for unitid,frame in pairs(FrameArray) do
		local highlight, rebuffer
		for name, module in self:IterateModulesWithMethod("RebuffQuery") do
			rebuffer = true
			if (module:IsModuleActive()) then
				if (module:RebuffQuery(unitid)) then
					highlight = true
					any = true
					break
				end
			end
		end

		local c = self:GetClassColour(select(2, UnitClass(unitid)))
		if (not highlight or not rebuffer) then
			frame.name:SetTextColor(c.r / 3, c.g / 3, c.b / 3)
		else
			frame.name:SetTextColor(c.r, c.g, c.b)
		end
	end

	if (any and self.db.profile.iconswirl) then
		self.icon.auto:Show()
	else
		self.icon.auto:Hide()
	end
end

-- IsFlaskOrPot
local findFlask = L["FIND_FLASK"]
local findPot = L["FIND_POT"]
local function IsFlaskOrPot(name, icon)
	if (strfind(name, findFlask) or strfind(name, findPot)) then
		return true
	end
	return strfind(icon, "INV_Potion_")
end

-- DrawCell(self)
local palaFlags = {false, false, false, false, false, false, false}
local palaKeys = {BOK = 1, BOM = 2, BOS = 3, BOW = 4, BOL = 5, SAN = 6, SAC = 7}
local function DrawCell(self)
	local partyid = self:GetAttribute("unit")		-- self.partyid
	if (not partyid or not UnitExists(partyid)) then
		return
	end

	local onAlpha, offAlpha
	if (z.db.profile.invert) then
		onAlpha = 0.2
		offAlpha = 1
	else
		onAlpha = 1
		offAlpha = 0.2
	end

	local unitname = UnitName(partyid)
	local class = select(2, UnitClass(partyid))
	local c = z:GetClassColour(class)

	if (z.db.char.sort == "CLASS") then
		self.groupMarker:Show()
		self.groupMarker:SetVertexColor(c.r, c.g, c.b)
	else
		local id = strmatch(partyid, "^raid(%d+)$")
		if (id) then
			local _, _, group = GetRaidRosterInfo(tonumber(id))
			self.groupMarker:Show()
			self.groupMarker:SetVertexColor(unpack(z.groupColours[group]))
		else
			self.groupMarker:Hide()
		end
	end

	local got, need = 0, 0
	for j,icon in ipairs(self.buff) do
		icon.spellName = nil
		local b = z.buffs[j]
		if (not b or ((b.class and z.classcount[b.class] == 0) and (not b.runescroll or not z.db.profile.runescroll))) then
			icon:SetTexture(nil)
		else
			if (UnitIsDeadOrGhost(partyid) or not UnitIsConnected(partyid)) then
				icon:SetTexture(nil)
			else
				if (b.manaOnly and not z.manaClasses[class]) then
					icon:SetTexture(nil)
				else
					if (b.type == "FLASK") then
						local oldPot = z.oldPots and z.oldPots[unitname]
						if (oldPot) then
							icon:SetTexture(oldPot)
							icon:Show()
							icon:SetAlpha(offAlpha)
						else
							icon:SetTexture(nil)
						end
					else
						if (b.icon) then
							icon:SetTexture(b.icon)
						end
						icon:Show()
						icon:SetAlpha(offAlpha)
					end
					need = need + 1
				end

			end
		end
	end
	for j = 1,7 do
		palaFlags[j] = false
	end

	local myMax, myEnd

	MakePalaIcons(self)
	
	local gotPalaBuffs = 0
	local doBlessings = z.db.profile.track.blessings
	if (not UnitIsDeadOrGhost(partyid) and UnitIsConnected(partyid)) then
		for i = 1,40 do
			local name, rank, tex, count, _, maxDuration, endTime, caster = UnitBuff(partyid, i)
			if (not name) then
				break
			end

			if (name == kiru or name == dalbless1 or name == dalbless2 or name == felint) then
				name = GetSpellInfo(27126)
			end

			if ((caster == "player" or z.overrideBuffBar) and maxDuration and maxDuration > 0 and (not myMax or myMax > maxDuration)) then
				if (z:ShowBuffBar(self, name, tex)) then
					myMax, myEnd, mySource = maxDuration, endTime, caster
				end
			end

			for j,icon in pairs(self.buff) do
				local buff = z.buffs[j]
				if (buff and ((not buff.class or z.classcount[buff.class] > 0) or (buff.runescroll and z.db.profile.runescroll))) then
					if (not buff.manaOnly or z.manaClasses[class]) then
						if (buff.list and buff.list[name]) then
							icon:Show()
							icon:SetAlpha(onAlpha)
							icon:SetTexture(tex)			-- TEST
							icon.spellName = name
							got = got + 1
						elseif (buff.type == "FLASK") then
							if (IsFlaskOrPot(name, tex)) then
								if (not z.oldPots) then
									z.oldPots = new()
								end
								z.oldPots[unitname] = tex
								icon:SetTexture(tex)
								icon:Show()
								icon:SetAlpha(onAlpha)
								got = got + 1
							end
						end
					end
				end
			end

			if (doBlessings) then
				local b
				if (name == battleshout) then
					b = z.blessings[GetSpellInfo(47436)]			-- Blessing of Might
				elseif (name == manaspring) then
					b = z.blessings[GetSpellInfo(27142)]			-- Blessing of Wisdom
				else
					b = z.blessings[name]
				end
				if (b) then
					-- We use a flag system for the paladin buffs, so we can make them always display in the same order
					local key = palaKeys[b.type]
					if (key and key <= 7) then
						palaFlags[key] = tex
						gotPalaBuffs = gotPalaBuffs + 1

						--if (caster == "player") then
						--	if (maxDuration and maxDuration > 0 and (not myMax or myMax > maxDuration)) then
						--		myMax, myEnd = maxDuration, endTime
						--	end
						--end
					end
				end
			end
		end

		if (doBlessings) then
			local palaIcon = 1
			if (bm) then
				-- If we have access to blessings manager, then we know what buffs each person
				-- should have, and who should be buffing them, so we refine the display for this

				local shouldHave = bm:GetShouldHaveBuffs(unitname, class)

				for i,Type in ipairs(shouldHave) do
					local b = self.palaIcon[palaIcon]
					if (b) then
						local tex
						local single, class = z:GetBlessingFromType(Type[2])
						if (single and class) then
							b:Show()
							if (Type[1] == 1) then
								tex = z.blessings[single].icon
								b.spellName = single
							else
								tex = z.blessings[class].icon
								b.spellName = class
							end
							b:SetTexture(tex)

							local flagIndex = palaKeys[Type[2]]
							if (palaFlags[flagIndex]) then
								--palaFlags[flagIndex] = nil - Removed so that palas with duplicate blessings when players are buffed won't show as unbuffed
								b:SetAlpha(onAlpha)
							else
								b:SetAlpha(offAlpha)
							end

							if (Type == "BOW") then
								if (z.manaClasses[class]) then
									b:SetVertexColor(1, 1, 1)
								else
									b:SetVertexColor(1, 0.5, 0.5)
								end
							else
								b:SetVertexColor(1, 1, 1)
							end
						else
							b:SetTexture(nil)
							b.spellName = nil
						end
						palaIcon = palaIcon + 1
					end
				end

				deepDel(shouldHave)
				z.buffRoster = nil

			elseif (z.buffRoster) then
				-- No Blessings Manager loaded, so we'll make a guess at
				-- what they should have compared to what they did have

				local lastFlags = z.buffRoster[unitname]
				if (not lastFlags) then
					lastFlags = {}
					z.buffRoster[unitname] = lastFlags
				end

				if (gotPalaBuffs == z.classcount.PALADIN) then
					-- If all paladin buffs received by someone, then remember which ones so we can say what's missing later
					for i = 1,#palaKeys do
						lastFlags[i] = palaFlags[i]
					end
				end

				-- Strip out any extra ones (happens when ppl get exceptions)
				local count = 0
				for i = 1,#palaKeys do
					if (lastFlags[i]) then
						if (count >= z.classcount.PALADIN) then
							lastFlags[i] = nil
						end
						count = count + 1
					end
				end

				-- Show the ones they do have
				for i = 1,7 do
					local b = self.palaIcon[palaIcon]
					if (b) then
						local tex = palaFlags[i]
						if (tex and palaIcon <= z.classcount.PALADIN) then
							b:Show()
							b:SetTexture(tex)
							b:SetAlpha(onAlpha)
							palaIcon = palaIcon + 1
						else
							b:SetTexture(nil)
						end
					end
				end

				-- Show the ones we think they should have
				for i = 1,7 do
					local b = self.palaIcon[palaIcon]
					if (b) then
						local tex = not palaFlags[i] and lastFlags[i]
						if (tex and palaIcon <= z.classcount.PALADIN) then
							b:Show()
							b:SetTexture(tex)
							b:SetAlpha(offAlpha)
							palaIcon = palaIcon + 1
						else
							b:SetTexture(nil)
						end
					end
					lastFlags[i] = lastFlags[i] or palaFlags[i]
				end
			end

			-- Hide excess
			while (palaIcon <= #self.palaIcon) do
				self.palaIcon[palaIcon]:SetTexture(nil)
				palaIcon = palaIcon + 1
			end
		else
			lastFlags = nil
			z.buffRoster = nil
		end
	else
		-- Hide excess
		if (self.palaIcon) then
			for i = 1,#self.palaIcon do
				self.palaIcon[i]:SetTexture(nil)
			end
		end
	end

	local bar = self.bar
	if (myMax) then
		local now = GetTime()
		local startTime = myEnd - myMax
		local endTime = myEnd
		bar:SetMinMaxValues(startTime, endTime)
		bar:SetValue(endTime - now)
		bar:SetScript("OnUpdate", CellBarOnUpdate)
		if (z.db.profile.bufftimer) then
			bar.timer:Show()
			bar.timer:SetScale(z.db.profile.bufftimersize)
		else
			bar.timer:Hide()
		end
	else
		bar.timer:Hide()
		bar:SetMinMaxValues(0, 1)
		bar:SetValue(0)
		bar:SetScript("OnUpdate", nil)
	end

	local highlight, rebuffer
	for modname, module in z:IterateModulesWithMethod("RebuffQuery") do
		rebuffer = true
		if (module:IsModuleActive()) then
			if (module:RebuffQuery(partyid)) then
				highlight = true
				break
			end
		end
	end

	-- Wierdo check for UnitInParty/Raid here because of a bug with GetPartyAssignment that spams
	-- system messages during zoning for people that ARE in your party/raid
	local icon
	if (z.db.profile.showroles and not z.zoneFlag) then
		if (select(2, IsInInstance()) == "party") then
			-- No point getting it otherwise, as they can be wrong. Usually the values you had
			-- from previous instance if you're running more than one with the same people
			local isTank, isHealer, isDamage = UnitGroupRolesAssigned(partyid)
			if (isTank) then
				icon = "|TInterface\\GroupFrame\\UI-Group-MainTankIcon:0|t"
			elseif (isHealer) then
				icon = "|TInterface\\Addons\\ZOMGBuffs\\Textures\\RoleHealer:0|t"
			elseif (isDamage) then
				icon = "|TInterface\\GroupFrame\\UI-Group-MainAssistIcon:0|t"
			end
		else
			if (GetPartyAssignment("MAINTANK", partyid)) then
				icon = "|TInterface\\GroupFrame\\UI-Group-MainTankIcon:0|t"
			elseif (GetPartyAssignment("MAINASSIST", partyid)) then
				icon = "|TInterface\\GroupFrame\\UI-Group-MainAssistIcon:0|t"
			end
		end
	end
	if (icon) then
		self.name:SetFormattedText("%s %s", unitname, icon)
	else
		self.name:SetText(unitname)
	end

	if (UnitIsConnected(partyid) and not UnitIsDeadOrGhost(partyid)) then
		if (self.invalidAttributes or not highlight or (not rebuffer and got >= need)) then
			self.name:SetTextColor(c.r / 3, c.g / 3, c.b / 3)
		else
			self.name:SetTextColor(c.r, c.g, c.b)
			if (InCombatLockdown()) then
				if (z.db.profile.iconswirl) then
					z.icon.auto:Show()
				else
					z.icon.auto:Hide()
				end
			end
		end
	else
		self.name:SetTextColor(0.4, 0.4, 0.4)
	end
end

-- GetBuffRoster
function z:GetBuffRoster()			-- TODO - remove after testing
	return self.buffRoster
end

-- ShowGroupNumber
function z:ShowGroupNumber(group, cell)
	if (not self.groupNumbers) then
		self.groupNumbers = new()
	end
	local no = self.groupNumbers[group]
	if (not no) then
		no = cell:CreateFontString(nil, "BORDER", "NumberFontNormal")
		no:SetFont("Fonts\\ARIALN.ttf", 10, "OUTLINE")
		self.groupNumbers[group] = no
		no:SetJustifyH("LEFT")
	end

	no:SetParent(cell)
	no:ClearAllPoints()
	no:SetPoint("TOPLEFT", cell, "TOPRIGHT", 2, 0)
	no:SetPoint("BOTTOMRIGHT", cell, "BOTTOMRIGHT", 30, 0)

	no:SetText(group)
	no:SetTextColor(unpack(self.groupColours[group]))
	no:Show()
end

-- DrawGroupNumbers
function z:DrawGroupNumbers()
	if (self.members and self.groupColours) then
		if (self.groupNumbers) then
			for i = 1,8 do
				local no = self.groupNumbers[i]
				if (no) then
					no:Hide()
				end
			end
		end

		if (self.db.profile.groupno and self.db.char.sort == "GROUP") then
			local group = 0

			local list = new()
			for i = 1,40 do
				local name, rank, subgroup = GetRaidRosterInfo(i)
				if (name) then
					list[i] = subgroup
				else
					break
				end
			end

			-- We don't use RosterLib here because the group numebrs will get out of sync
			-- immediately after a group change until roster lib updates later
			for i = 1,40 do
				local cell = self.members:GetAttribute("child"..i)
				if (not cell) then
					break
				end

				local unitid = cell:GetAttribute("unit")
				if (unitid) then
					local idNumber = strmatch(unitid, "^raid(%d+)$")
					if (idNumber) then
						local no = list[tonumber(idNumber)]
						if (no and no > group) then
							group = list[tonumber(idNumber)]
							self:ShowGroupNumber(group, cell)
						end
					end
				end
			end

			del(list)
		end

		if (self.palaNames) then
			for i,name in pairs(self.palaNames) do
				name:Hide()
			end
		end

		if (self.db.profile.track.blessings) then
			if (bm and bm.pala) then
				-- Also draw the column headings for paladin names (two letters each)

				local topChild = self.members:GetAttribute("child1")
				if (topChild) then
					local show = topChild:IsShown()

					for name,pala in pairs(bm.pala) do
						local row = pala.row

						local relative = topChild.palaIcon and topChild.palaIcon[row]
						if (relative) then
							local fs
							if (not self.palaNames) then
								self.palaNames = {}
							end
							fs = self.palaNames[row]
							if (not fs) then
								fs = self.members:CreateFontString(nil, "BORDER", "NumberFontNormal")
								self.palaNames[row] = fs
								fs:SetFont("Fonts\\ARIALN.ttf", 10, "OUTLINE")
								fs:SetJustifyH("LEFT")
							end

							fs:SetText(pala.initials)

							fs:ClearAllPoints()
							fs:SetPoint("BOTTOM", relative, "TOP", 0, (self.db.char.border and 3) or 1)
							if show then
								fs:Show()
							else
								fs:Hide()
							end
						end
					end
				end
			end
		end
		
		if (btr) then
			btr:CheckTickTitles(self.members)
		end

		-- Border
		local border = self.members.border
		if (self.db.char.border) then
			local topChild = self.members:GetAttribute("child1")
			if (topChild) then
				if (not border) then
					border = self:CreateBorder(self.members)
					self.members.border = border
				end

				local bottomChild
				local i = 0
				repeat
					i = i + 1
					local unitButton = self.members:GetAttribute("child"..i)
					if (unitButton and unitButton:IsShown()) then
						bottomChild = unitButton
					end
				until not (unitButton)

				border:ClearAllPoints()
				border:SetPoint("TOPLEFT", topChild, "TOPLEFT", -5, 4)
				border:SetPoint("BOTTOMRIGHT", bottomChild, "BOTTOMRIGHT", 6, -4)

				border:Show()
			end
		else
			if (border) then
				self.members.border:Hide()
			end
		end
	end
end

-- UpdateOneCellSpells
function z:UpdateOneCellSpells(frame)
	self:ClearClickSpells(frame)
	self:SetTargetClick(frame)
	if (self.SetClickSpells) then
		self:SetClickSpells(frame)
	end

	if (self.members and not frame.wrapped) then
		if (not InCombatLockdown()) then
			frame.wrapped = true
			SecureHandlerWrapScript(frame, "OnEnter", self.members, "")
			SecureHandlerWrapScript(frame, "OnLeave", self.members, self.onLeaveFuncString)
		end
	end
end

-- UpdateCellSpells
function z:UpdateCellSpells()
	for unit,frame in pairs(FrameArray) do
		self:UpdateOneCellSpells(frame)
	end
end

-- TriggerClickUpdate
function z:TriggerClickUpdate(unit)
	local f = FrameArray[unit]
	if (f) then
		self:UpdateOneCellSpells(f)
	end
end

-- RegisterSetClickSpells
function z:RegisterSetClickSpells(mod, func)
	if (not z.SetClickSpells) then
		self.setClickSpellsList = {}
		function z:SetClickSpells(cell)
			for mod,func in pairs(self.setClickSpellsList) do
				func(mod, cell)
			end
		end
	end
	self.setClickSpellsList[mod] = func
end

-- GetSpellColour
function z:GetSpellColour(spellName)
	local colour
	for name, module in self:IterateModulesWithMethod("GetSpellColour") do
		colour = module:GetSpellColour(spellName)
		if (colour) then
			return colour
		end
	end
end

-- Shfit, Alt, Ctrl <--- order is important
do
	local leftModsDesc = {"", L["Shift-"], L["Alt-"], L["Ctrl-"]}
	local leftMods = {"", "shift-", "alt-", "ctrl-"}
	local combos = {"000", "010", "100", "001", "011", "110", "101", "111"}
	local rightModDesc = {L["Left Button"], L["Right Button"], L["Middle Button"], L["Button Four"], L["Button Five"]}
	rightModDesc["*"] = ""
	leftModsDesc["*"] = ""

	local function cellOrIconTooltip(self)
		GameTooltip:SetOwner(self, "ANCHOR_"..(z.db.char.anchor or "TOPLEFT"))

		local unit1 = self:GetAttribute("unit")
		local name = unit1 and UnitExists(unit1) and UnitName(unit1)

		if (unit1) then
			local c = z:GetClassColour(select(2, UnitClass(unit1)))
			GameTooltip:SetText(name or "", c.r, c.g, c.b)
		else
			GameTooltip:ClearLines()
		end

		local line = 1
		for rightMod = 1,5 do
			local lastSpell
			for ind,c in ipairs(combos) do
				local j = c:sub(1, 1) == "1" and 2 or 1
				local k = c:sub(2, 2) == "1" and 3 or 1
				local l = c:sub(3, 3) == "1" and 4 or 1
				local leftMod = format("%s%s%s", leftMods[j], leftMods[k], leftMods[l])
	
				local Type = self:GetAttribute(leftMod, "type", rightMod)
				if (not Type and self == z.icon) then
					Type = self:GetAttribute("*", "type", "*")
					if (Type) then
						leftMod = "*"
						rightMod = "*"
					end
				end
				if (Type) then
					local spell = self:GetAttribute(leftMod, "spell", rightMod)
					if (spell or Type == "target") then
						local unit = self:GetAttribute(leftMod, "unit", rightMod)
						if (spell ~= lastSpell or Type == "target") then
							local leftModDesc = format("%s%s%s", leftModsDesc[j], leftModsDesc[k], leftModsDesc[l])
							lastSpell = spell
	
							local match1 = tostring(strfind(leftMod, "ctrl-") and 1 or 0) .. tostring(strfind(leftMod, "shift-") and 1 or 0) .. tostring(strfind(leftMod, "alt-") and 1 or 0)
							local match2 = tostring(IsControlKeyDown() and 1 or 0) .. tostring(IsShiftKeyDown() and 1 or 0) .. tostring(IsAltKeyDown() and 1 or 0)
	
							local buttonColour = ((match1 == match2) and "|cFFFFFFFF") or "|cFF808080"
	
							local unitShow
							if (unit and unit ~= unit1) then
								unitShow = format(L[" on %s"], z:ColourUnit(unit))
							else
								unitShow = ""
							end
	
							if (spec and line == 1 and Type ~= "target") then
								GameTooltip:AddDoubleLine(" ", spec, nil, nil, nil, 0.5, 0.5, 0.5)
								spec = nil
							end
							
							local spellColour = z:GetSpellColour(spell) or "|cFFFFFF80"
							if (Type == "target") then
								if (spec and line == 1) then
									GameTooltip:AddDoubleLine(format(L["%s%s%s|r to target"], buttonColour, leftModDesc, rightModDesc[rightMod]), spec, nil, nil, nil, 0.5, 0.5, 0.5)
									spec = nil
								else
									GameTooltip:AddLine(format(L["%s%s%s|r to target"], buttonColour, leftModDesc, rightModDesc[rightMod]))
								end
							else
								--GameTooltip:AddLine(format(L["%s%s%s|r to cast %s%s|r%s"], buttonColour, leftModDesc, rightModDesc[rightMod], spellColour, spell, unitShow))
								GameTooltip:AddDoubleLine(format("%s%s%s|r", buttonColour, leftModDesc, rightModDesc[rightMod]),
														format("%s%s|r%s", spellColour, spell, unitShow))
							end
							line = line + 1
						end
					end
				end
				if (self == z.icon) then
					break
				end
			end
			if (self == z.icon) then
				break
			end
		end
	end

	-- IconOnEnter
	function IconOnEnter(self)
		cellOrIconTooltip(self)

		if (not z.db.profile.enabled) then
			GameTooltip:SetText(z.titleColour)
			GameTooltip:AddLine(L["Auto-casting is disabled"])
			GameTooltip:AddLine(L["You can re-enable it by single clicking the ZOMGBuffs minimap/fubar icon"])

		elseif (lastCheckFail) then
			if (GameTooltip:IsShown()) then
				GameTooltip:AddLine(" ")
			else
				GameTooltip:SetText(z.titleColour)
				GameTooltip:AddLine(L["Suspended"], 1, 1, 1)
			end
			GameTooltip:AddLine(format(L["Not Refreshing because %s"], lastCheckFail), nil, nil, nil, 1)
		elseif (z.waitingForRaid or z.waitingForClass) then
	    	if (GameTooltip:IsShown()) then
	    		GameTooltip:AddLine(" ")
			else
				GameTooltip:SetText(z.titleColour)
			end

			if (z.waitingForRaid) then
	    		GameTooltip:AddLine(format(L["Waiting for %d%% of raid to arrive before buffing commences (%d%% currently present)"], z.db.profile.waitforraid * 100, z.waitingForRaid), nil, nil, nil, 1)
			end
			if (z.waitingForClass) then
	    		GameTooltip:AddLine(format(L["Waiting for these groups or classes to arrive: %s"], z.waitingForClass), nil, nil, nil, 1)
			end
		end

		if (not GameTooltip:IsShown()) then
			GameTooltip:SetText(z.titleColour)
		end

		GameTooltip:Show()
	end

	-- IconOnLeave
	function IconOnLeave()
		GameTooltip:Hide()
	end

	-- ShowBuffBar
	function z:ShowBuffBar(cell, spellName, tex)
		if (z.overrideBuffBar) then
			if (z.overrideBuffBar == "tick") then
				local btr = ZOMGBuffTehRaid
				if (btr) then
					local found = btr.lookup[spellName]
					local key = btr.tickColumns[z.overrideBuffBarIndex]
					if (found and found.type == key) then
						return true
					end
				end

			elseif (z.overrideBuffBar == "buff") then
				local buff = z.buffs[z.overrideBuffBarIndex]
				if (buff) then
					if (buff.type == "FLASK") then
						if (IsFlaskOrPot(spellName, tex)) then
							return true
						end
					else
						if (z.buffsLookup[spellName] == buff) then
							return true
						end
					end
				end
			elseif (z.overrideBuffBar == "blessing") then
				local palaIcon = cell.palaIcon and cell.palaIcon[z.overrideBuffBarIndex]
				if (palaIcon) then
					local showSpell = palaIcon.spellName
					local blessing1 = showSpell and z.blessings[showSpell]
					local blessing2 = spellName and z.blessings[spellName]
					if (blessing1 and blessing2 and blessing1.type == blessing2.type) then
						return true
					end
				end
			end
		else
			for name, module in z:IterateModulesWithMethod("ShowBuffBar") do
				if (module:ShowBuffBar(cell, spellName, tex)) then
					return true
				end
			end
		end
	end

	-- onUpdateIconMouseover
	local function onUpdateIconMouseover(self)
		if (not self.buff) then
			return
		end

		-- Get's mouse position within the cell and works out which icon we're pointing at
		local l, b, w, h = self:GetRect()
		local x, y = GetCursorPosition()
		x = x / UIParent:GetScale()
		y = y / UIParent:GetScale()

		if (x > l and x < l + w) then
			if (y > b and y < b + h) then
				local offset = x - l
				if (self.ticks) then
					for i = 1,#self.ticks do
						if (self.ticks[i]:IsShown()) then
							offset = offset - self.ticks[i]:GetWidth()
						end
					end
				end

				local index = 1 + floor(offset / self.buff[1]:GetWidth())
				if (index > 0) then
					if (index ~= z.mouseIndex) then
						z.mouseIndex = index
						local oldBar, oldIndex = z.overrideBuffBar, z.overrideBuffBarIndex

						if (index <= #z.buffs) then
							-- One of the normal icons (raid buffs, food, pots)
							z.overrideBuffBar = "buff"
							z.overrideBuffBarIndex = index

						elseif (self.palaIcon) then
							-- One of the Paladin blessing icons
							local pindex = index - #z.buffs
							if (pindex <= #self.palaIcon) then
								z.overrideBuffBar = "blessing"
								z.overrideBuffBarIndex = pindex
							else
								z.overrideBuffBar = nil
								z.overrideBuffBarIndex = nil
							end
						else
							z.overrideBuffBar = nil
							z.overrideBuffBarIndex = nil
						end

						if (z.overrideBuffBar ~= oldBar or z.overrideBuffBarIndex ~= oldIndex) then
							z:DrawAllCells()
						end
					end
				end
			end
		end
	end

	-- CellOnEnter
	function CellOnEnter(self)
		z.mouseIndex = nil
		z.overrideBuffBar = nil
		z.overrideBuffBarIndex = nil

		self:SetScript("OnUpdate", onUpdateIconMouseover)
		cellOrIconTooltip(self)

		if (self.invalidAttributes) then
			GameTooltip:AddLine(format(L["Out-of-date spell (should be %s). Will be updated when combat ends"], self.invalidAttributes), 1, 0, 0, 1)
		end

		if (self ~= z.icon) then
			local unit = self:GetAttribute("unit")
			local spec, s1, s2, s3 = LGT:GetUnitTalentSpec(unit)
			if (spec) then
				local _, class = UnitClass(unit)
				if (class == "DEATHKNIGHT" or (class == "DRUID" and s2 > s1 + s3)) then
					local role = LGT:GetUnitRole(unit)
					spec = format("%s (%s)", spec, role == "tank" and TANK or DAMAGE)
				end

				GameTooltipTextRight1:SetText(spec)
				GameTooltipTextRight1:SetTextColor(0.5, 0.5, 0.5)
				GameTooltipTextRight1:Show()
			end
		end

		GameTooltip:Show()
	end

	-- CellOnLeave
	function CellOnLeave(self)
		z.mouseIndex = nil
		z.overrideBuffBar = nil
		z.overrideBuffBarIndex = nil
		self:SetScript("OnUpdate", nil)
		GameTooltip:Hide()
	end
end

function CellOnMouseDown(self, button)
	z:CallMethodOnAllModules("CellOnMouseDown", self, button)
end

function CellOnMouseUp(self, button)
	if (InCombatLockdown()) then
		z.icon.auto:Hide()
	end
	z.clickCast = true
	z.clickList = true
end

-- CellBarOnUpdate
function CellBarOnUpdate(self, elapsed)
	local startTime, endTime = self:GetMinMaxValues()
	if (GetTime() >= endTime) then
		self:SetMinMaxValues(0, 1)
		self:SetValue(0)
		self:SetScript("OnUpdate", nil)
		self.timer:Hide()
	else
		local remaining = endTime - GetTime()
		self:SetValue(startTime + remaining)

		if (remaining <= z.db.profile.bufftimerthreshold) then
			self.timer.text:SetText(date("%M:%S", remaining):gsub("^0", ""))
			self.timer:Show()
		else
			self.timer:Hide()
		end
	end
end

-- InitCell
function z:InitCell(cell)
	tinsert(AllFrameArray, cell)

	cell:SetNormalTexture("Interface\\AddOns\\ZOMGBuffs\\Textures\\FrameBack")
	local t = cell:GetNormalTexture()
	cell.bg = t

	cell.groupMarker = cell:CreateTexture(nil, "BORDER")
	cell.groupMarker:SetTexture("Interface\\AddOns\\ZOMGBuffs\\Textures\\FrameBack")
	cell.groupMarker:Hide()
	cell.groupMarker:SetPoint("TOPLEFT", cell, "TOPRIGHT", 0, 0)
	cell.groupMarker:SetPoint("BOTTOMRIGHT", cell, "BOTTOMRIGHT", 2, 0)

	t:SetVertexColor(0, 0, 0, 1)
	t:SetDrawLayer("BORDER")
	t:SetDrawLayer("BORDER")
	cell:SetHighlightTexture("Interface\\Buttons\\UI-Listbox-Highlight")

	cell:SetScript("OnEnter", CellOnEnter)
	cell:SetScript("OnLeave", CellOnLeave)
	cell:SetScript("OnMouseDown", CellOnMouseDown)
	cell:SetScript("OnMouseUp", CellOnMouseUp)
	cell:RegisterForClicks("AnyUp")
	--cell.UpdateTooltip = CellOnEnter

	local h = cell:GetHeight()
	local w = cell:GetWidth()

	local prev
	cell.buff = {}
	for i = 1,#self.allBuffs do
		local b = cell:CreateTexture(nil, "ARTWORK")
		b:SetHeight(z.db.char.height)
		b:SetWidth(z.db.char.height)

		if (i == 1) then
			b:SetPoint("TOPLEFT", 0, 0)
		else
			b:SetPoint("TOPLEFT", prev, "TOPRIGHT", 0, 0)
		end

		cell.buff[i] = b
		prev = b
	end

	cell.palaIcon = {}

	local tex = self:GetBarTexture()
	
	cell.bar = CreateFrame("StatusBar", nil, cell)
	cell.bar:SetStatusBarTexture(tex)
	cell.bar:SetStatusBarColor(1, 1, 0.5, 0.5)
	cell.bar:SetMinMaxValues(0, 1)
	cell.bar:SetValue(0)
	if (not prev) then
		cell.bar:SetPoint("TOPLEFT")
	else
		cell.bar:SetPoint("TOPLEFT", prev, "TOPRIGHT")
	end
	cell.bar:SetPoint("BOTTOMRIGHT")
	
	local timer = CreateFrame("Frame", nil, cell.bar)
	cell.bar.timer = timer
	timer:SetScale(self.db.profile.bufftimersize)
	timer:SetPoint("RIGHT")
	timer:SetWidth(1)
	timer:SetHeight(1)
	timer.text = timer:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
	timer.text:SetPoint("RIGHT")
	timer.text:SetJustifyH("RIGHT")

	local a, b, c = self:GetFont()
	cell.name = cell.bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	cell.name:SetFont(a, b, c)
	cell.name:SetPoint("TOPLEFT", 2, 0)
	cell.name:SetPoint("BOTTOMRIGHT")
	cell.name:SetJustifyH("LEFT")

	cell.DrawCell = DrawCell

	cell:SetScript("OnAttributeChanged", onCellAttrChanged)
	cell:SetScript("OnShow", DrawCell)
end

-- SecureCall
function z:SecureCall(f, s)
	if (InCombatLockdown()) then
		secureCalls[f] = s or self
	else
		local c = (s or self)[f]
		if (not c) then
			c = f
		end
		if (c) then
			c(s or self)
		end
	end
end

local dummy = CreateFrame("Frame")
dummy:Hide()
dummy:SetScript("OnUpdate",
	function(self)
		if (z.rosterInvalid) then
			z.rosterInvalid = nil
			z:OnRaidRosterUpdate()
		end
		self:Hide()
	end)

-- RAID_ROSTER_UPDATE
function z:RAID_ROSTER_UPDATE()
	self.unknownUnits = del(self.unknownUnits)
	if (self:IsEventRegistered("UNIT_NAME_UPDATE")) then
		self:UnregisterEvent("UNIT_NAME_UPDATE")
	end

	self:DrawGroupNumbers()
	self.rosterInvalid = true
	dummy:Show()
end

-- OnRaidRosterUpdate
function z:OnRaidRosterUpdate()
	self:CheckStateChange()
	local delList = copy(z.versionRoster)
	local any

	self.classcount = setmetatable({}, {__index = function() return 0 end})
	for unit, unitname, unitclass, subgroup, index in self:IterateRoster() do
		if (unitname ~= UNKNOWN) then
			self.classcount[unitclass] = self.classcount[unitclass] + 1
			delList[unitname] = nil
			any = true
		end
	end
	self:SetBuffsList()

	if (any) then
		for name,ver in pairs(delList) do
			z.versionRoster[name] = nil
			if (z.oldPots) then
				z.oldPots[name] = nil
			end
			if (z.buffRoster) then
				z.buffRoster[name] = nil
			end
		end
	end

	if (GetNumRaidMembers() == 0 and GetNumPartyMembers() == 0) then
		deepDel(self.buffRoster)
		self.buffRoster = new()
		
		if (self.wasInGroup) then
			reqHistorySpec = {}
			reqHistoryCap = {}
			reqHistoryBT = {}
			reqHistoryHello = {}
			self.wasInGroup = nil
		end
	else
		if (not self.wasInGroup) then
			reqHistorySpec = {}
			reqHistoryCap = {}
			reqHistoryBT = {}
			reqHistoryHello = {}
			self:SendCommMessage("GROUP", "HELLO", self.version)
			self.wasInGroup = true
		end
	end

	-- Roster changed, so trigger a check if nothing queued
	if (self.icon and self.icon:GetAttribute("*type*") == nil) then
		self:RequestSpells()
	end

	for name, module in self:IterateModulesWithMethod("OnRaidRosterUpdate") do
		if (module:IsModuleActive()) then
			module:OnRaidRosterUpdate()
		end
	end

	if (self.MaybeLoadManager) then
		self:MaybeLoadManager()
	end

	self.StartupDone = true
	self:UpdateCellSpells()
	if (self:UpdateListWidth()) then
		self:SetAllBarSizes()
	end

	del(delList)
end

-- UpdateListWidth
function z:UpdateListWidth()
	local old = self.totalListWidth
	-- Work out how wide the list will be in total. The width option now specifies the list of
	-- the name part only, the actual width varies based on how many icons will be shown
	if (not InCombatLockdown()) then
		local icons = z.db.profile.track.blessings and z.classcount.PALADIN or 0
		icons = icons + #self.buffs

		self.totalListWidth = self.db.char.width + icons * z.db.char.height
		if (self.members) then
			self.members:SetWidth(self.totalListWidth)
		end
	else
		self.updateListWidthOOC = true
	end

	return self.totalListWidth ~= old
end

-- RegisterBuffer
function z:RegisterBuffer(mod, priority)
	-- Priority if not given will be next one in list
	if (not self.registeredBuffers) then
		self.registeredBuffers = {}
	end
	if (priority) then
		tinsert(self.registeredBuffers, 1, mod)
	else
		tinsert(self.registeredBuffers, mod)
	end
end

-- z:RequestSpells()
function z:RequestSpells()
	if (self.registeredBuffers) then
		for i,module in ipairs(self.registeredBuffers) do
			module:CheckBuffs()
			if (self.icon and self.icon:GetAttribute("*type*")) then
				break
			end
		end
	end
end

-- CheckForChange
-- Will re-request buffs if the icon currently has one that
-- belongs to the calling module, else it'll leave it alone
function z:CheckForChange(mod)
	if (self.icon) then
		if (not self.icon.mod or self.icon.mod == mod) then
			self:SetupForSpell()
			self.icon.castTimeToGCD = nil
			self:RequestSpells()
		elseif (not self.icon:GetAttribute("*type*")) then
			self:RequestSpells()
		end
	end
end

-- IsBlacklisted
function z:IsBlacklisted(name)
	local skip
	local failedRecently = self.blackList and self.blackList[name]
	if (failedRecently) then
		if (GetTime() > failedRecently) then		-- We failed a cast recently on this person
			self.blackList[name] = nil
		else
			return true
		end
	end
end

-- Blacklist
function z:Blacklist(name)
	if (UnitIsUnit(name, "player")) then
		return
	end

	if (not self.blackList) then
		self.blackList = {}
	end

	self.blackList[name] = GetTime() + 10			-- Flag player as un-castable for 10 seconds
	if (z.db.profile.info) then
		self:Print(format(L["%s blacklisted for 10 seconds"], z:ColourUnitByName(name)))
		self.globalCooldownEnd = GetTime() + (self.castTimeToGCD or 1.5)
		self:GlobalCDSchedule()
	end
end

-- AnyBlacklisted
function z:AnyBlacklisted()
	return self.blackList and next(self.blackList)
end

-- GlobalCooldownEnd()
function z:GlobalCooldownEnd()
	self:RequestSpells()
end

-- UNIT_AURA
function z:UNIT_AURA(unit)
	local u = FrameArray[unit]
	if (u) then
		u:DrawCell()
	end

	if (unit == "player") then
		if (self:UnitHasBuff("player", 46755) or self:UnitHasBuff("player", 46898)) then	-- Food/Drink
			self:SetupForSpell()
		else
			self:StartCheckMounted()
		end
	end
end

-- UNIT_SPELLCAST_SENT
function z:UNIT_SPELLCAST_SENT(player, spell, rank, targetName)
	if (player == "player") then
		local start, dur = GetSpellCooldown(spell)
		if (start and dur <= 1.5) then
			self.globalCooldownEnd = start + dur
		else
			self.globalCooldownEnd = GetTime() + 1.5
		end
		if (ZOMGSelfBuffs and ZOMGSelfBuffs.activeEnchantLoaded) then
			self.globalCooldownEnd = self.globalCooldownEnd + ZOMGSelfBuffs.activeEnchantLoaded
			ZOMGSelfBuffs.activeEnchantLoaded = nil
			if (spell == ZOMGSelfBuffs.lastEnchantSet) then
				ZOMGSelfBuffs.activeEnchant = GetTime()
			end
		end

		self.lastCastS = spell
		self.lastCastR = rank
		self.lastCastN = targetName
	end
end

-- UNIT_SPELLCAST_SUCCEEDED
function z:UNIT_SPELLCAST_SUCCEEDED(player, spell, rank)
	if (player == "player") then
		if (self.clickCast) then
			z:SayWhatWeDid(spell, self.lastCastN, rank)
		end

		local curIconSpell = self.icon:GetAttribute("spell")
		local curIconTarget = self.icon:GetAttribute("unit")
		if (curIconSpell == spell and curIconTarget and ((self.lastCastN == "" and curIconTarget == "player") or (self.lastCastN and UnitIsUnit(curIconTarget, self.lastCastN)))) then
			-- We lagged a lot apparently, and we've just cast the spell that's on the icon, so clear it and re-check
			self:SetupForSpell()
			self.globalCooldownEnd = GetTime() + 0.5
		end

		if (spell == self.lastCastS and rank == self.lastCastR) then
			for name, module in self:IterateModulesWithMethod("SpellCastSucceeded") do
				if (module:IsModuleActive()) then
					module:SpellCastSucceeded(self.lastCastS, self.lastCastR, self.lastCastN, not self.clickCast, self.clickList)
				end
			end
		end

		if (self.globalCooldownEnd > GetTime()) then
			self:GlobalCDSchedule()
		else
			if (self.icon and not self.icon:GetAttribute("*type*")) then
				self:RequestSpells()
			end
		end

		self.lastCastS, self.lastCastR, self.lastCastN = nil, nil, nil
		self.clickCast = nil
		self.clickList = nil
	end
end

-- UNIT_SPELLCAST_FAILED
function z:UNIT_SPELLCAST_FAILED(player)
	if (player == "player") then
		self:CallMethodOnAllModules("SpellCastFailed", self.lastCastS, self.lastCastN, not self.clickCast)

		self.lastCastS, self.lastCastR, self.lastCastN = nil, nil, nil
		self.clickCast = nil
		self.clickList = nil

		self:CancelScheduledEvent("ZOMGBuffs_GlobalCooldownEnd")
		self:ScheduleEvent("ZOMGBuffs_GlobalCooldownEnd", self.GlobalCooldownEnd, 0.5, self)
	end
end

-- UNIT_SPELLCAST_STOP
function z:UNIT_SPELLCAST_STOP(player, spell, rank)
	if (player == "player") then
		self.clickCast = nil
		self.clickList = nil
	end
end

-- PLAYER_REGEN_ENABLED
function z:PLAYER_REGEN_ENABLED()
	z.canChangeFlagsIC = nil
	if (cellAttributeChanges) then
		for unitid,cell in pairs(FrameArray) do
			local name = UnitName(unitid)
			if (name) then
				local attr = cellAttributeChanges[name]
				if (attr) then
					if (not cell.attr) then
						cell.attr = new()
					end
					for k,v in pairs(attr) do
						cell:SetAttribute(k, v)
						cell.attr[k] = v
					end
					cell.invalidAttributes = nil
				end
			end
		end
		cellAttributeChanges = deepDel(cellAttributeChanges)
	end

	for k,v in pairs(secureCalls) do
		if (v[k]) then
			v[k](v)
		end
		secureCalls[k] = nil
	end
	if (buffClass) then
		self:CancelScheduledEvent("ZOMGBuffs_PeriodicListCheck")
		self.icon.auto:Hide()
	end
	self:RequestSpells()

	for name, module in self:IterateModulesWithMethod("OnRegenEnabled") do
		if (module:IsModuleActive()) then
			module:OnRegenEnabled()
		end
	end

	if (self.updateListWidthOOC) then
		self.updateListWidthOOC = nil
		self:UpdateListWidth()
	end

	if (not self:IsEventRegistered("COMBAT_LOG_EVENT_UNFILTERED")) then
		self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	end
end

-- PLAYER_REGEN_DISABLED
function z:PLAYER_REGEN_DISABLED()
	self:CancelScheduledEvent("ZOMGBuffs_HideMeLaterz")
	self:SetupForSpell()
	if (buffClass) then
		self:ScheduleRepeatingEvent("ZOMGBuffs_PeriodicListCheck", self.PeriodicListCheck, 10, self)
	end

	for name, module in self:IterateModulesWithMethod("OnRegenDisabled") do
		if (module:IsModuleActive()) then
			module:OnRegenDisabled()
		end
	end

	if (self:IsEventRegistered("COMBAT_LOG_EVENT_UNFILTERED")) then
		self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	end
end

-- PLAYER_CONTROL_LOST
function z:PLAYER_CONTROL_LOST()
	self.lostControl = true
	self:SetupForSpell()
end

-- PLAYER_CONTROL_GAINED
function z:PLAYER_CONTROL_GAINED()
	self.lostControl = nil
	self.globalCooldownEnd = 1.5
	self:GlobalCDSchedule()
end

-- UNIT_SPELLCAST_CHANNEL_START
function z:UNIT_SPELLCAST_CHANNEL_START(player, spell, rank)
	if (UnitIsUnit(player, "player")) then
		self:SetupForSpell()
	end
end

-- UNIT_PET
-- When a pet is activated, trigger a check for them.
-- Everyone else might be buffed and nothing scheduled for checking for a long time
function z:UNIT_PET(ownerid)
	if (self.icon and not self.icon:GetAttribute("*type*")) then
		local petid

		-- Since we'll get a UNIT_PET event for raid1 and party1 and potentially player all from
		-- the same unit, we'll limit those events here depending what sort of group we're in:
		if (GetNumRaidMembers() > 0 and strfind(ownerid, "^raid(%d+)$")) then
			petid = ownerid:gsub("^raid(%d+)", "raidpet%1")
		elseif (GetNumPartyMembers() > 0 and strfind(ownerid, "^party(%d+)$")) then
			petid = ownerid:gsub("^party(%d+)", "partypet%1")
		elseif (ownerid == "player") then
			petid = "pet"
		end

		if (petid and UnitExists(petid) and UnitCanAssist("player", petid)) then
			for name, module in self:IterateModulesWithMethod("RebuffQuery") do
				if (module:IsModuleActive()) then
					if (module:RebuffQuery(petid)) then
						module:CheckBuffs()
					end
				end
			end
		end
	end	
end

-- PLAYER_LEAVING_WORLD
function z:PLAYER_LEAVING_WORLD()
	self.zoneFlag = GetTime()
	self:CancelScheduledEvent("ZOMGBuffs_PeriodicListCheck")
	self:CancelScheduledEvent("ZOMGBuffs_GlobalCooldownEnd")
	self:SetupForSpell()
end

-- PLAYER_ENTERING_WORLD
function z:PLAYER_ENTERING_WORLD()
	if (self.minimapFrame) then
		self.minimapFrame:Hide()
	end
	self:SetMainIcon()
	self.zoneFlag = GetTime()
	self:SetupForSpell()
	self:CancelScheduledEvent("ZOMGBuffs_PeriodicListCheck")
	self:CancelScheduledEvent("ZOMGBuffs_GlobalCooldownEnd")
	self:ScheduleEvent("FinishedZoning", self.FinishedZoning, 5, self)
	-- Buff timers aren't available immediately upon zoning
	self:CheckStateChange()
	self:StartCheckMounted()
end

-- FinishedZoning
function z:FinishedZoning()
	self:OnRaidRosterUpdate()
	self.zoneFlag = false
	self:DrawAllCells()
	self:RequestSpells()
end

-- PLAYER_UPDATE_RESTING
function z:PLAYER_UPDATE_RESTING()
	if (IsResting() and z.db.profile.notresting) then
		self:SetupForSpell()
		self:CanCheckBuffs()
	else
		if (not self.icon:GetAttribute("spell") and not self.icon:GetAttribute("item")) then
			self:RequestSpells()
		end
	end
end

-- SetKeyBindings
function z:SetKeyBindings()
	if (not self.icon) then
		return
	end

	ClearOverrideBindings(self.icon)

	if (self.db.profile.mousewheel and self.enabled) then
		SetOverrideBindingClick(self.icon, true, "MOUSEWHEELUP", self.icon:GetName(), "MOUSEWHEELUP")
		SetOverrideBindingClick(self.icon, true, "MOUSEWHEELDOWN", self.icon:GetName(), "MOUSEWHEELDOWN")
	end

	if (self.db.profile.keybinding) then
		SetOverrideBindingClick(self.icon, true, self.db.profile.keybinding, self.icon:GetName(), "LeftButton")
	end
end

-- OnClick
function z:OnClick()
	if (self:IsDisabled()) then
		return
	end

	if (IsAltKeyDown()) then
		if (bm) then
			bm:ToggleFrame()
		end
	else
		self.db.profile.enabled = not self.db.profile.enabled
		if (self.db.profile.enabled) then
			self:RequestSpells()
		else
			self.atTrainer, self.atVendor = nil
			self:SetupForSpell()
			self:CancelScheduledEvent("ZOMGBuffs_GlobalCooldownEnd")
		end
		if (not self.icon:GetAttribute("spell") and not self.icon:GetAttribute("item")) then
			self:SetStatusIcon()
		end

		self:Print(L["Auto-casting %s"], (self.db.profile.enabled and L["|cFF80FF80Enabled"]) or L["|cFFFF8080Disabled"])
	end
end

-- OnTooltipUpdate
function z:OnTooltipUpdate()
	self.linkSpells = nil

	tablet:SetTitle(format("%s |cFF808080r%s|r", z.titleColour, tostring(z.version)))
	if (bm) then
		tablet:SetHint(L["HINTBM"])
	else
		tablet:SetHint(L["HINT"])
	end

	local cat = tablet:AddCategory('columns', 2)

	if (self.waitingForRaid) then
		cat:AddLine(
			"text", "|cFFFF8080"..format(L["Waiting for %d%% of raid to arrive before buffing commences (%d%% currently present)"], z.db.profile.waitforraid * 100, self.waitingForRaid),
			"wrap", true)
	elseif (self.waitingForClass) then
		cat:AddLine(
			"text", "|cFFFF8080"..format(L["Waiting for these groups or classes to arrive: %s"], self.waitingForClass),
			"wrap", true)
	end

	for name, module in self:IterateModulesWithMethod("TooltipUpdate") do
		if (module:IsModuleActive()) then
			module:TooltipUpdate(cat)
		end
	end

	--UpdateAddOnMemoryUsage()
	--local total = GetAddOnMemoryUsage("ZOMGBuffs")
	--for name, module in self:IterateModules() do
	--	total = total + GetAddOnMemoryUsage(name)
	--end
	--cat:AddLine('text', " ")
	--cat:AddLine("text", "|cFF808080Memory Usage", "text2", format("|cFF808080%.2dK", total))

	self.linkSpells = true
end

-- OnTextUpdate
function z:OnTextUpdate()
	if (not self.hasNoText) then
		if (self:IsTextColored()) then
			self:SetText(z.titleColour)
		else
			self:SetText(z.title)
  		end
  	end
end

-- GetMerchantBuyItemList
function z:GetMerchantBuyItemList()
	local list = new()
	local level = UnitLevel("player")
	for name, module in z:IterateModules() do
		if (module.reagents and module.db and module.db.char and module.db.char.reagents) then
			for item,info in pairs(module.reagents) do
				local itemname = item
				if (type(item) == "number") then
					itemname = GetItemInfo(item)
				end
				if (itemname and (not info.maxLevel or level <= info.maxLevel) and (not info.minLevel or level >= info.minLevel)) then
					local num = module.db.char.reagents[item]
					if (num and num > 0) then
						list[itemname] = num
					end
				end
			end
		end
	end
	return list
end

-- MERCHANT_SHOW
function z:MERCHANT_SHOW()
	self:SetupForSpell()
	self.atVendor = true
	if (not self.db.char.autobuyreagents) then
		return
	end

	if (self.lastMerchantBuy and GetTime() < self.lastMerchantBuy + 5) then
		return
	end
	self.lastMerchantBuy = GetTime()

	local list = z:GetMerchantBuyItemList()
	if (next(list)) then
		local numMerchantItems = GetMerchantNumItems()
		local doneItems = new()				-- Double check there's no error in what we buy

		for i = 1,numMerchantItems do
			local name, texture, price, quantity, numAvailable, isUsable, extendedCost = GetMerchantItemInfo(i)
			local required = list[name]
			if (required and not doneItems[name]) then
				doneItems[name] = true
				local bought = 0
				local got = GetItemCount(name)
				local get = quantity					-- Stacked vendor items come in this amount always
				if (got < required) then
					local stackSize = select(8, GetItemInfo(name))
					if (not stackSize) then
						-- Item is not in local cache
						stackSize = 5
					end

					while (got + quantity <= required) do
						if (quantity > 1) then
							BuyMerchantItem(i)		-- Buying stacked items (Symbol of Kings for example in 20s)
						else
							get = min(required - got, stackSize)
							BuyMerchantItem(i, get)		-- None stacked vendor can be bought to max of stackSize at a time
						end
						got = got + get
						bought = bought + get
					end
				end

				if (bought > 0) then
					local _, link = GetItemInfo(name)
					self:Print(L["Bought |cFF80FF80%d|cFFFFFF80 %s|r from vendor, you now have |cFF80FF80%d|r"], bought, link or name, got)
					-- TODO - Put newly bought stacks into same bag as matching reagents
				end
			end
		end

		del(doneItems)
	end

	del(list)
end

-- MERCHANT_CLOSED
function z:MERCHANT_CLOSED()
	self.atVendor = nil
	self:RequestSpells()
end

-- TRAINER_SHOW
function z:TRAINER_SHOW()
	self:SetupForSpell()
	self.atTrainer = true
end

-- TRAINER_CLOSED
function z:TRAINER_CLOSED()
	self.atTrainer = nil
	self:RequestSpells()
end

-- UNIT_MANA
-- This is enabled when we failed a mana check in self:CanCheckBuffs()
function z:UNIT_MANA(unit)
	if (unit == "player") then
		local mana, manamax = UnitMana("player"), UnitManaMax("player")
		if (mana / manamax * 100 >= self.db.char.minmana) then
			self:UnregisterEvent("UNIT_MANA")
			self:RequestSpells()
		end
	end
end

-- CHAT_MSG_ADDON
-- For PallyPower Load on Demand support
local ppPrefix = "PLPWR"
local ignoreMeList = {}
local ignoreMeToo
function z:CHAT_MSG_ADDON(prefix, message, distribution, sender)
	if (prefix == "PLPWR") then
		if (message == "ZOMG") then
			ignoreMeList[sender] = true
		elseif (not ignoreMeList[sender]) then
			if (type(z.versionRoster[sender]) == "number") then
				ignoreMeList[sender] = true
			else
				z.versionRoster[sender] = "PallyPower"
				if (not ZOMGBlessingsPP) then
					LoadAddOn("ZOMGBuffs_BlessingsPP")
					if (ZOMGBlessingsPP) then
						ZOMGBlessingsPP:CHAT_MSG_ADDON(prefix, message, distribution, sender)
					end
				end
			end
		end
	end
end

-- CHAT_MSG_WHISPER
function z:CHAT_MSG_WHISPER(msg, sender, language, d, e, status)
	if (self.chatMatch) then
	 	local got
		for match in pairs(self.chatMatch) do
			if (strsub(msg, 1, strlen(match)) == match) then
				msg = strsub(msg, strlen(match) + 1)
				while (strsub(msg, 1, 1) == " ") do
					msg = strsub(msg, 2)
				end
				got = true
				break
			end
		end
		if (not got) then
			return
		end

		for name, module in self:IterateModulesWithMethod("BuffResponse") do
			if (module:IsModuleActive()) then
				module:BuffResponse(sender, msg)
			end
		end
	end
end

do
	local function chatFilter(self, event, ...)
		local msg, sender = ...
		for match in pairs(z.chatMatch) do
			if (strsub(msg, 1, strlen(match)) == match) then
				return true
			end
		end
		return false
	end

	local function chatFilterInform(self, event, ...)
		local msg, sender = ...
		if (strsub(msg, 1, strlen(z.chatAnswer)) == z.chatAnswer) then
			return true
		end
		return false
	end

	-- MatchChat
	function z:MatchChat(event, msg)
		if (not msg or msg == "" or not self:IsActive()) then
			return
		end
		if (event == "CHAT_MSG_WHISPER") then
			return chatFilter(msg)
		elseif (event == "CHAT_MSG_WHISPER_INFORM") then
			return chatFilterInform(msg)
		end
	end

	-- HookChat
	function z:HookChat()
		ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER", chatFilter)
		ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER_INFORM", chatFilterInform)
	end

	-- z:UnhookChat
	function z:UnhookChat()
		ChatFrame_RemoveMessageEventFilter("CHAT_MSG_WHISPER", chatFilter)
		ChatFrame_RemoveMessageEventFilter("CHAT_MSG_WHISPER_INFORM", chatFilterInform)
	end
end

-- COMBAT_LOG_EVENT_UNFILTERED
local mask = COMBATLOG_OBJECT_AFFILIATION_PARTY + COMBATLOG_OBJECT_AFFILIATION_RAID
function z:COMBAT_LOG_EVENT_UNFILTERED(ev, timestamp, event, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, ...)
	if (event == "UNIT_DIES") then
		if (self.icon and band(srcFlags, mask)) then
			local loadedUnit = self.icon:GetAttribute("unit")
			if (UnitIsUnit(srcName, loadedUnit)) then
				self:SetupForSpell()
				self:RequestSpells()
			end
		end
	end
end

-- MODIFIER_STATE_CHANGED
function z:MODIFIER_STATE_CHANGED()
	self:DrawAllCells()
end

local reqHistorySpec = {}
local reqHistoryCap = {}
local reqHistoryBT = {}
local reqHistoryHello = {}
-- OnCommReceive
z.OnCommReceive = {
	HELLO = function(self, prefix, sender, channel, version)
		if (version) then
			if (not reqHistoryHello[sender] or reqHistoryHello[sender] < GetTime() - 15) then
				reqHistoryHello[sender] = GetTime()

				if (type(version) == "string") then
					version = 0		-- Flags as beta
				end
				z.versionRoster[sender] = version
				if (version > z.maxVersionSeen) then
					z.maxVersionSeen = version
				end
				z:SendComm(sender, "VERSION", z.version)
				z:OnReceiveVersion(sender, version)
			end
		end
	end,
	VERSION = function(self, prefix, sender, channel, version)
		if (version) then
			if (type(version) == "string") then
				version = 0		-- Flags as beta
			end
			z.versionRoster[sender] = version
			if (version > z.maxVersionSeen) then
				z.maxVersionSeen = version
			end
			z:OnReceiveVersion(sender, version)
		end
	end,
	REQUESTCAPABILITY = function(self, prefix, sender, channel)
		if (not reqHistoryCap[sender] or reqHistoryCap[sender] < GetTime() - 15) then
			reqHistoryCap[sender] = GetTime()

			if (playerClass == "PALADIN") then
				local cap = {
					canKings			= UnitLevel("player") >= 20,
					canSanctuary		= LGT:UnitHasTalent("player", (GetSpellInfo(20911))),
					impMight			= LGT:UnitHasTalent("player", (GetSpellInfo(20445))) or 0,
					impWisdom			= LGT:UnitHasTalent("player", (GetSpellInfo(20245))) or 0,
					improvedDevotion	= LGT:UnitHasTalent("player", (GetSpellInfo(20140))),
					improvedConcentration = LGT:UnitHasTalent("player", (GetSpellInfo(20254))),
					improvedRetribution = LGT:UnitHasTalent("player", (GetSpellInfo(31869)))
				}

				local _
				_, cap[1], cap[2], cap[3] = LGT:GetUnitTalentSpec("player")
				z:SendComm(sender, "CAPABILITY", cap)
				del(cap)
			end
		end
	end,
	CAPABILITY = function(self, prefix, sender, channel, cap)
		z:OnReceiveCapability(sender, cap)
	end,
	GIVETEMPLATEPART = function(self, prefix, sender, channel, name, class, buff)
		z:OnReceiveTemplatePart(sender, name, class, buff)
	end
}

-- OnReceiveSpec
function z:OnReceiveCapability(sender, cap)
	if (cap) then
		self:CallMethodOnAllModules("OnReceiveCapability", sender, cap)
	end
end

-- OnReceiveTemplatePart
function z:OnReceiveTemplatePart(sender, name, class, buff)
	self:CallMethodOnAllModules("OnReceiveTemplatePart", sender, name, class, buff)
end

-- OnReceiveVersion
function z:OnReceiveVersion(sender, version)
	self:CallMethodOnAllModules("OnReceiveVersion", sender, version)
end

function z:DefaultClickBindings()
	return {
		target = "BUTTON1",
		singleblessing = "ALT-BUTTON2",
		greaterblessing = "BUTTON2",
		stamina1 = "ALT-BUTTON2",
		stamina2 = "BUTTON2",
		spirit1 = "CTRL-ALT-BUTTON2",
		spirit2 = "CTRL-BUTTON2",
		shadowprot1 = "SHIFT-ALT-BUTTON2",
		shadowprot2 = "SHIFT-BUTTON2",
		fearward = "ALT-BUTTON1",
		mark1 = "ALT-BUTTON2",
		mark2 = "BUTTON2",
		thorns = "CTRL-BUTTON2",
		int1 = "ALT-BUTTON2",
		int2 = "BUTTON2",
		dampen = "CTRL-BUTTON2",
		amplify = "SHIFT-BUTTON2",
		focusmagic = "CTRL-BUTTON1",
		water = "ALT-BUTTON2",
		earthshield = "BUTTON2",
		seeinvis = "BUTTON2",
		breath = "SHIFT-BUTTON2",
		freedom = "CTRL-BUTTON1",
		sacrifice = "ALT-BUTTON1",
		beacon = "SHIFT-BUTTON1",
		sacredshield = "SHIFT-ALT-BUTTON1",
	}
end

-- OnInitialize
function z:OnInitialize()
	self.maxVersionSeen = 0
	self:RegisterDB("ZOMGBuffsDB", "ZOMGBuffsPerCharDB")
	self:RegisterDefaults("profile", {
		showMinimapButton = true,
		bufftimer = true,
		bufftimersize = 0.6,
		bufftimerthreshold = 10 * 60,
		invert = true,
		notice = true,
		usesink = false,
		sinkopts = {},
		info = true,
		mousewheel = true,
		notresting = true,
		notmounted = true,
		notstealthed = true,
		notshifted = true,
		enabled = true,
		bartexture = "BantoBar",
		waitforraid = 0,				-- Wait for % of raid
		waitforclass = true,			-- Wait for class/group to arrive
		ignoreabsent = true,			-- Ignore absent players (offline, afk, out of zone)
		channel = "Raid",				-- Report channel
		skippvp = true,					-- Don't directly buff PVP players
		singlesInBG = true,				-- Don't use greater blessings/class buffs in battlegrounds
		singlesInArena = true,			-- Don't use greater blessings/class buffs in arenas
		groupno = true,
		alwaysLoadManager = true,
		alwaysLoadPortalz = true,
		notWithSpiritTap = true,
		showSolo = true,
		showParty = true,
		showRaid = true,
		track = {
			sta = true,
			mark = true,
			int = true,
			spirit = true,
			shadow = false,
			blessings = true,
			food = true,
			flask = true,
		},
		click = z:DefaultClickBindings(),
		buffreminder = "None",
		spellIcons = true,
		showroles = true,
		iconname = true,
		iconswirl = true,
		showFubar = true,
	} )
	self:RegisterDefaults("char", {
		firstStartup = true,
		showicon = true,
		iconlocked = false,
		iconsize = 36,
		classIcon = false,
		anchor = "BOTTOMRIGHT",
		relpoint = "TOPRIGHT",
		sort = "GROUP",
		--iconborder = true,
		border = false,
		autobuyreagents = false,
		minmana = 0,
		width = 150,
		height = 14,
		fontface = "Arial Narrow",
		fontsize = 12,
		fontoutline = "",
		buffpets = true,
		learnooc = true,
		learncombat = true,
		loadraidbuffmodule = true,
	})

	self:RegisterChatCommand("/zomg", self.options, "ZOMGBUFFS")

	self:SetKeyBindings()

	self.commPrefix = "ZOMG"
	self:SetCommPrefix(self.commPrefix)

	local memo = {}
	for k,v in pairs(classOrder) do tinsert(memo, v) end
	for k,v in pairs({
			"REQUESTCAPABILITY", "CAPABILITY",
			"GIVETEMPLATE", "GIVETEMPLATEPART", "ACK",
			"REQUESTTEMPLATE", "TEMPLATE",
			"REQUESTSPEC", "SPEC",
			"HELLO", "VERSION",
			"default", "modified", "never", "solo", "party", "raid",
			"BOM", "BOK", "BOW", "BOL", "BOS", "SAN",
			"MODIFIEDTEMPLATE",
			"canKings", "canSanctuary", "impMight", "impWisdom", "canSpirit", "mark",
			"SPELLS_CHANGED", "GIVEMASTERTEMPLATE", "GIVESUBCLASSES", "SYMBOLCOUNT",
			"bless", "change", "exception", "gen", "save", "select",
			"AUTOGROUPASSIGNED", "SYNCGROUPS",
		}) do tinsert(memo, v) end

	self:RegisterMemoizations(memo)

	self.globalCooldownEnd = 0
	playerClass = playerClass or select(2, UnitClass("player"))

	if (self.minimapFrame) then
		self.minimapFrame:Hide()
	end

	self.OnInitialize = nil
end

-- IsInBattlegrounds
function z:IsInBattlegrounds()
	for i = 1,50 do
		local r = GetBattlefieldStatus(i)
		if (not r) then
			return nil
		end
		if (r == "active") then
			return true
		end
	end
end

-- GetGroupNumber
function z:GetGroupNumber(unit)
	-- Fix for rosterlib's occasional group barf
	if (GetNumRaidMembers() > 0) then
		local id = UnitInRaid(unit)		--strmatch(unit, "(%d+)")
		if (id) then
			id = id + 1
			local subgroup = select(3, GetRaidRosterInfo(id))
			return subgroup
		end
	end
	return 1
end

-- SendComm
function z:SendComm(fname, ...)
	if (UnitExists(fname) and UnitIsConnected(fname)) then
		if (UnitIsUnit("player", fname)) then
			local func = z.OnCommReceive[...]
			if (func) then
				func(self, self.commPrefix, fname, "WHISPER", select(2, ...))
			end
		else
			if (self:IsInBattlegrounds()) then
				local name, server = UnitName(fname)
				if (server and server ~= "") then
					self:SendCommMessage("WHISPER", format("%s-%s", name, server), ...)
				else
					self:SendCommMessage("WHISPER", name, ...)
				end
			else
				self:SendCommMessage("WHISPER", fname, ...)
			end
		end
	end
end

-- SendAll
function z:SendClass(class, ...)
	for unit, unitname, unitclass, subgroup, index in self:IterateRoster() do
		if (unitclass == class and UnitIsConnected(unit)) then
			local name, server = UnitName(unit)
			if (name ~= UNKNOWN) then
				if (server and server ~= "") then
					if (self:IsInBattlegrounds()) then
						self:SendCommMessage("WHISPER", format("%s-%s", name, server), ...)
					end
				else
					self:SendCommMessage("WHISPER", name, ...)
				end
			end
		end
	end
end

-- MaybeLoadManager
function z:MaybeLoadManager()
	if (playerClass == "PALADIN" or IsRaidLeader() or IsRaidOfficer() or self.db.profile.alwaysLoadManager) then
		if (not ZOMGBlessingsManager) then
			LoadAddOn("ZOMGBuffs_BlessingsManager")
			if (ZOMGBlessingsManager) then
				self.options.args["ZOMGBlessingsManager"] = ZOMGBlessingsManager:GetModuleOptions()
				bm = ZOMGBlessingsManager
			end
		end
		self.MaybeLoadManager = nil
	end
end

-- MaybeLoadPortalz
function z:MaybeLoadPortalz()
	if (ZOMGPortalz) then
		self.MaybeLoadPortalz = nil
		return
	end

	if (self.db.profile.alwaysLoadPortalz) then
		LoadAddOn("ZOMGBuffs_Portalz")
		if (ZOMGPortalz) then
			self.options.args["ZOMGPortalz"] = ZOMGPortalz:GetModuleOptions()
		end
		self.MaybeLoadPortalz = nil
	end
end

-- DrawAllCells
function z:DrawAllCells()
	for k,v in pairs(FrameArray) do
		v:DrawCell()
	end
end

-- SetBuffsList
function z:SetBuffsList()
	del(self.buffs)
	self.buffs = new()
	for k,v in pairs(self.allBuffs) do
		if (self.db.profile.track[v.opt] and (not v.class or self.classcount[v.class] > 0 or (v.runescroll and self.db.profile.runescroll))) then
			tinsert(self.buffs, v)
		end
	end
	if (self.icon and self.members and self.members:IsShown()) then
		self:DrawAllCells()
	end
end

-- Add
function z:Log(module, who, ...)
	if (GetNumPartyMembers() > 0 or GetNumRaidMembers() > 0) then
		local event = new(module, time(), who or UnitName("player"), ...)
		z:SendCommMessage("GROUP", "EVENT", event)
		if (ZOMGLog and ZOMGLog:IsModuleActive()) then
			ZOMGLog:ActualAdd(event)
		else
			del(event)
		end
	end
end

-- CreateHelpFrame
local helpFrame
function z:CreateHelpFrame()
	helpFrame = CreateFrame("Frame", nil, UIParent, "DialogBoxFrame")
	helpFrame:SetFrameStrata("TOOLTIP")
	helpFrame:SetWidth(600)
	helpFrame:SetPoint("CENTER", 0, 100)
	helpFrame:SetBackdrop({
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true, tileSize = 16, edgeSize = 16,
		insets = { left = 5, right = 5, top = 5, bottom = 5 }
	})
	helpFrame:SetBackdropColor(0,0,0,1)
	helpFrame:EnableMouse(true)
	helpFrame:RegisterForDrag("LeftButton")
	helpFrame:SetScript("OnDragStart", function(self) dewdrop:Close() self:StartMoving() end)
	helpFrame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
	helpFrame:SetScale(0.9)
	helpFrame:SetMovable(true)
	helpFrame:SetClampedToScreen(true)

	local text = helpFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
	helpFrame.title = text
	text:SetPoint("TOP", 0, -10)

	text = helpFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	helpFrame.text = text

	text:SetPoint("TOPLEFT", 10, -30)
	text:SetWidth(helpFrame:GetWidth() - 20)
	text:SetJustifyH("LEFT")
	text:SetJustifyV("TOP")

	local b = CreateFrame("Button", nil, main, "OptionsButtonTemplate")
	b:GetRegions():SetAllPoints(b)			-- Makes the text part (first region) fit all over button, instead of just centered and fuxed when scaled
	b:SetScript("OnClick", function(self) helpFrame:Hide() end)
	b:SetText(CLOSE)
	helpFrame.close = b
	
	helpFrame:Hide()
	z.CreateHelpFrame = nil

	function helpFrame:DoTokens(str)
		for i = 1,100 do
			local part = strmatch(str, "{[^{^}]*}")
			if (not part) then
				break
			end
			local subpart = part:sub(2, -2)
			local newpart
			if (subpart:lower() == "version") then
				newpart = "r"..z.version
			else
				newpart = GetAddOnMetadata("ZOMGBuffs", subpart)
				if (newpart) then
					newpart = format("|cFFFFFF80%s|r", newpart)
				else
					newpart = "|cFFFF8080nil|r"
				end
			end
			part = part:gsub("-", "--")
			str = str:gsub(part, newpart)
		end
		return str
	end

	function helpFrame:SetHelp(title, help)
		self:Hide()
		self.title:SetText(title)
		self.text:SetText(help)
		self:Show()
	end

	helpFrame:SetScript("OnShow",
		function(self)
			local title = self:DoTokens(self.title:GetText())
			local text = self:DoTokens(self.text:GetText())
			self.title:SetText(title)
			self.text:SetText(text)

			self:SetHeight(self.text:GetHeight() + 80)
		end)

	helpFrame:SetScript("OnHide",
		function(self)
			self.text:SetText("")
			self:SetHeight(80)
		end)

	return helpFrame
end

-- PrintAddonInfo
function z:PrintAddonInfo()
	local f = z:GetHelpFrame()
	f:SetHelp(L["TITLECOLOUR"].." r"..self.version, L["ABOUT"])
end

-- GetHelpFrame
function z:GetHelpFrame()
	if (not helpFrame) then
		self:CreateHelpFrame()
	end
	return helpFrame
end

-- LibGroupTalents_Update
function z:LibGroupTalents_Update(e, guid, unit, newSpec, n1, n2, n3, oldSpec, o1, o2, o3)
	if (UnitIsUnit("player", unit)) then
		self:CallMethodOnAllModules("OnSpellsChanged")
	end
end

-- ADDON_LOADED
function z:ADDON_LOADED(addon)
	if (addon == "ZOMGBuffs_BuffTehRaid") then
		btr = ZOMGBuffTehRaid
	elseif (addon == "ZOMGBuffs_BlessingsManager") then
		bm = ZOMGBlessingsManager
	end
end

-- CheckStateChange
function z:CheckStateChange()
	local party = GetNumPartyMembers() > 0
	local raid = GetNumRaidMembers() > 0
	local instance, Type = IsInInstance()

	local state, reason
	if (instance and Type == "pvp") then
		state, reason = "bg", L["You are now in a battleground"]
	elseif (instance and Type == "arena") then
		state, reason = "arena", L["You are now in an arena"]
	elseif (raid) then
		state, reason = "raid", L["You are now in a raid"]
	elseif (party) then
		state, reason = "party", L["You are now in a party"]
	else
		state, reason = "solo", L["You are now solo"]
	end

	if (state ~= self.state) then
		self.state = state
		self:CallMethodOnAllModules("OnStateChanged", state, reason)
	end
end

-- PARTY_MEMBERS_CHANGED
function z:PARTY_MEMBERS_CHANGED()
	self:CheckStateChange()
end

-- OnEnableOnce
function z:OnEnableOnce()
	if (SM) then
		SM:Register("statusbar", "BantoBar",	"Interface\\AddOns\\ZOMGBuffs\\Textures\\BantoBar")
		SM:Register("statusbar", "Blizzard",	"Interface\\TargetingFrame\\UI-StatusBar")
		SM:Register("sound", "Bats",			"Sound\\Doodad\\BatsFlyAway.wav")
		SM:Register("sound", "Firework",		"Sound\\Doodad\\G_FireworkBoomGeneral2.wav")
		SM:Register("sound", "Clockwork",		"Sound\\Doodad\\G_GasTrapOpen.wav")
		SM:Register("sound", "Gong",			"Sound\\Doodad\\G_GongTroll01.wav")
		SM:Register("sound", "Wisp",			"Sound\\Event Sounds\\Wisp\\WispPissed1.wav")
		SM:Register("sound", "Fog Horn",		"Sound\\Doodad\\ZeppelinHorn.wav")
		SM:Register("sound", "Error",			"Sound\\interface\\Error.wav")
		SM:Register("sound", "Drop",			"Sound\\interface\\DropOnGround.wav")
		SM:Register("sound", "Whisper",			"Sound\\interface\\igTextPopupPing02.wav")
		SM:Register("sound", "Friend Login",	"Sound\\interface\\FriendJoin.wav")
		SM:Register("sound", "Socket Clunk",	"Sound\\interface\\JewelcraftingFinalize.wav")
		SM:Register("sound", "Ping",			"Sound\\interface\\MapPing.wav")
	end

	if (Sink) then
		self:SetSinkStorage(self.db.profile.sinkopts)
	end

	self:SendCommMessage("GROUP", "HELLO", self.version)

	-- Table to make sure we don't re-load the same module again if someone screws up
	-- their installation and has a double set of folders in addons and in ZOMGBuffs proper
	local matchList = {
		ZOMGBuffs_BlessingsManager = ZOMGBlessingsManager,
		ZOMGBuffs_Blessings = ZOMGBlessings,
		ZOMGBuffs_SelfBuffs = ZOMGSelfBuffs,
		ZOMGBuffs_Log = ZOMGLog,
		ZOMGBuffs_BuffTehRaid = ZOMGBuffTehRaid,
		ZOMGBuffs_Portalz = ZOMGPortalz,
	}

	playerClass = playerClass or select(2, UnitClass("player"))
	for i = 1,GetNumAddOns() do
		local name,_,_,enabled,loadable = GetAddOnInfo(i)
		if (name and loadable and strfind(name, "ZOMGBuffs_")) then
			local d = GetAddOnMetadata(i, "X-ZOMGBuffs")
			if (d) then
				local load
				local c = GetAddOnMetadata(i, "X-Classes")
				if (c) then
					load = strfind(strupper(c), playerClass)
					if (not load) then
						c = GetAddOnMetadata(i, "X-Classes-Optional")
						if (c) then
							if (strfind(strupper(c), playerClass)) then
								self.canloadraidbuffmodule = true
								if (self.db.char.loadraidbuffmodule) then
									load = true
								end
							end
						end
					end
				else
					load = true
				end
				if (load) then
					local match = matchList[name]
					if (not match or not _G[matchList[match]]) then
						LoadAddOn(i)
					end
				end
			end
		end
	end
	
	btr = ZOMGBuffTehRaid

	self:MaybeLoadManager()
	self:MaybeLoadPortalz()

	if (not ZOMGLog) then
		LoadAddOn("ZOMGBuffs_Log")
	end

	for name, module in self:IterateModulesWithMethod("RebuffQuery") do
		buffClass = true
		break
	end

	self.actions = nil
	self:SetClickConfigMenu()

	-- Replace old keybindings with the defaults that we messed up before r69331
	local command = GetBindingAction("MOUSEWHEELUP")
	if (command == "CLICK ZOMGBuffsButton:MOUSEWHEELUP") then
		SetBinding("MOUSEWHEELUP", "CAMERAZOOMIN")
	end
	command = GetBindingAction("MOUSEWHEELDOWN")
	if (command == "CLICK ZOMGBuffsButton:MOUSEWHEELDOWN") then
		SetBinding("MOUSEWHEELDOWN", "CAMERAZOOMOUT")
	end

	local ldb = LibStub:GetLibrary("LibDataBroker-1.1", true)
	if (ldb) then
		self.ldbSource = ldb:NewDataObject("ZOMGBuffs", {
			type = "launcher",
			label = L["TITLECOLOUR"],
			icon = "Interface\\Addons\\ZOMGBuffs\\Textures\\Icon",
		})
	end

	if (self.ldbSource) then
		self.ldbSource.OnClick = function(self, button)
			if (button == "LeftButton") then
				z:OnClick(button)
			else
				dewdrop:Open(self,
					"children", function()
						dewdrop:FeedAceOptionsTable(z.options)
					end
				)
			end
		end
		self.ldbSource.OnEnter = function(self) z:UpdateTablet(self) end
	else
		self.db.profile.showFubar = true
	end

	self.mounted = IsMounted()

	self.linkSpells = true
	self.OnEnableOnce = nil
end

-- RegisterTablet
function z:RegisterTablet(ldbParent)
	if (not ldbParent) then
		return
	end

	if not tablet:IsRegistered(ldbParent) then
		tablet:Register(ldbParent,
			'children', function()
				tablet:SetTitle(self:GetTitle())
				if type(self.OnTooltipUpdate) == "function" then
					if not self:IsDisabled() then
						self:OnTooltipUpdate()
					end
				end
			end,
			'clickable', true,
			'point', function(frame)
				if frame:GetTop() > GetScreenHeight() / 2 then
					local x = frame:GetCenter()
					if x < GetScreenWidth() / 3 then
						return "TOPLEFT", "BOTTOMLEFT"
					elseif x < GetScreenWidth() * 2 / 3 then
						return "TOP", "BOTTOM"
					else
						return "TOPRIGHT", "BOTTOMRIGHT"
					end
				else
					local x = frame:GetCenter()
					if x < GetScreenWidth() / 3 then
						return "BOTTOMLEFT", "TOPLEFT"
					elseif x < GetScreenWidth() * 2 / 3 then
						return "BOTTOM", "TOP"
					else
						return "BOTTOMRIGHT", "TOPRIGHT"
					end
				end
			end
		)
	end
end

-- UpdateTablet
function z:UpdateTablet(ldbParent)
	if (not ldbParent) then
		return
	end

	self:RegisterTablet(ldbParent)
	tablet:Refresh(ldbParent)
end

-- SetMainIcon
function z:SetMainIcon(icon)
	self.mainIcon = icon or self.mainIcon

	if (self.ldbSource) then
		self.ldbSource.icon = self.mainIcon
	end

	if (self.db.profile.showFubar) then
		self.cannotAttachToMinimap = nil
		self.hasIcon = true
		self.hasNoText = nil
		self:SetIcon(self.mainIcon)
		self:Show()
	else
		self.cannotAttachToMinimap = true
		self.hasIcon = nil
		self.hasNoText = true
		self.hideWithoutStandby = true
		self:Hide()
		self.hideWithoutStandby = nil
	end
end
function z:GetMainIcon()
	return self.mainIcon
end

do	-- Brute force attack on FuBar minimap icon to hide it should it be disabled:
	local oneFrameOnly = CreateFrame("Frame")
	oneFrameOnly:SetScript("OnUpdate", function(self) self:SetScript("OnUpdate", nil) z:SetMainIcon() self:Hide() end)
end

-- OnEnable
function z:OnEnable()
	if (not self.buffRoster) then
		self.buffRoster = {}
	end
	playerName = UnitName("player")
	playerClass = playerClass or select(2, UnitClass("player"))
	z.versionRoster[playerName] = self.version
	z.maxVersionSeen = max(z.maxVersionSeen or 0, self.version)
	btr = ZOMGBuffTehRaid

	self.groupColours = {{1, 1, 0.5}, {1, 0.5, 1}, {0.5, 1, 1}, {1, 0.5, 0.5}, {0.5, 1, 0.5}, {0.5, 0.5, 1}, {0.5, 0.5, 0.5}, {1, 1, 0}, {1, 0, 1}, {0, 1, 1}}	

	if (self.OnEnableOnce) then
		self:OnEnableOnce()
	end

	self:RegisterComm(self.commPrefix, "WHISPER", "OnCommReceive")
	self:RegisterComm(self.commPrefix, "GROUP", "OnCommReceive")

	self:SetClickConfigMenu()
	self:OnRaidRosterUpdate()

	if (z.db.char.firstStartup) then
		z.db.char.firstStartup = false
		z.db.char.sort = (playerClass == "PALADIN" and "CLASS") or "GROUP"
	end

	if (not self.icon) then
		self:OnStartup()
		self:RestorePosition(self.icon, self.db.char.pos)
		self:SetIconSize()
	elseif (self.members) then
		self.members:RegisterEvent("PARTY_MEMBERS_CHANGED")
	end

	LGT.RegisterCallback(self, "LibGroupTalents_Update")

	self:MakeOptionsReagentList()
	self:SetSort()

	self.enabled = true
	self:SetKeyBindings()

	self:RegisterEvent("RAID_ROSTER_UPDATE")
	self:RegisterEvent("PARTY_MEMBERS_CHANGED", "RAID_ROSTER_UPDATE")
	self:RegisterEvent("UNIT_AURA")
	self:RegisterEvent("PARTY_MEMBERS_CHANGED")
	self:RegisterEvent("PLAYER_REGEN_ENABLED")
	self:RegisterEvent("PLAYER_REGEN_DISABLED")
	self:RegisterEvent("PLAYER_UPDATE_RESTING")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("PLAYER_LEAVING_WORLD")
	self:RegisterEvent("UNIT_SPELLCAST_SENT")
	self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	self:RegisterEvent("UNIT_SPELLCAST_FAILED")
	self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
	self:RegisterEvent("UNIT_SPELLCAST_STOP")
	self:RegisterEvent("ADDON_LOADED")
	self:RegisterEvent("UNIT_PET")
	self:RegisterEvent("MERCHANT_SHOW")
	self:RegisterEvent("MERCHANT_CLOSED")
	self:RegisterEvent("TRAINER_SHOW")
	self:RegisterEvent("TRAINER_CLOSED")

	self:RegisterEvent("PLAYER_CONTROL_LOST")
	self:RegisterEvent("PLAYER_CONTROL_GAINED")
	self:RegisterEvent("CHAT_MSG_ADDON")				-- For PallyPower Load on Demand support
	self:RegisterEvent("CHAT_MSG_WHISPER")
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

	self.chatMatch = {}
	local i = 1
	while (true) do
		if (L:HasTranslation("CHATMATCH"..i)) then
			z.chatMatch[L["CHATMATCH"..i]] = true
		else
			break
		end
		i = i + 1
	end
	self.chatAnswer = L["CHATANSWER"]

	self:HookChat()

	self.icon:Show()

	if (self.minimapFrame) then
		self.minimapFrame:Hide()
	end
end

-- OnDisable
function z:OnDisable()
	z.options.args.behaviour.args.reagentlevels.args = nil
	if (z.options.args.click) then
		z.options.args.click.args = nil
		z.options.args.click = nil
	end
	self.atTrainer, self.atVendor = nil
	self.oldPots = del(self.oldPots)
	self:SetupForSpell()
	self.enabled = nil
	self.icon:Hide()
	self.members:UnregisterAllEvents()
	self.buffRoster = nil
	self.blackList = nil
	self.chatMatch = nil
	self.chatAnswer = nil
	self.groupColours = nil
	self:UnhookAll()
	self:UnhookChat()
end
