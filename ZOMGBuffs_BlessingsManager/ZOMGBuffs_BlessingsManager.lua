if (ZOMGBlessingsManager) then
	ZOMGBuffs:Print("Installation error, duplicate copy of ZOMGBuffs_BlessingsManager (Addons\ZOMGBuffs\ZOMGBuffs_BlessingsManager and Addons\ZOMGBuffs_BlessingsManager)")
	return
end

local L = LibStub("AceLocale-2.2"):new("ZOMGBlessingsManager")
local LGT = LibStub("LibGroupTalents-1.0")
local dewdrop = LibStub("Dewdrop-2.0")
local ZFrame
local template
local playerName, playerClass
local split = true					-- Disable to turn off new thing
local abCount = 0

-- Constants
local SHOW_CELL_EXCEPTIONS_COUNT = 3

local blessingCycle = {"BOM", "BOK", "BOW", "SAN"}

local blessingCycleIndex = {}
for k,v in ipairs(blessingCycle) do blessingCycleIndex[v] = k end

local z = ZOMGBuffs
local man = z:NewModule("ZOMGBlessingsManager")
ZOMGBlessingsManager = man

z:CheckVersion("$Revision: 156 $")

do
	local frostPresence = GetSpellInfo(48263)
	local specWeight1p2 = function(unit, t1, t2, t3) return (t1 + t2) > t3 end
	local specWeight1or3 = function(unit, t1, t2, t3) return t1 > t2 or t3 > t2 end
	local specDKTank = function(unit, t1, t2, t3) return UnitAura(unit, frostPresence) ~= nil end
	local specNotDKTank = function(unit, t1, t2, t3) return UnitAura(unit, frostPresence) == nil end
	local specBearTank = function(unit, t1, t2, t3) return LGT:UnitHasTalent(unit, (GetSpellInfo(33853))) end

	man.classSplits = {
		WARRIOR	= {[1] = {title = L["Tank"], discover = 3},	[2] = {title = L["Melee DPS"],	code = "m", discover = specWeight1p2}},
		DEATHKNIGHT = {[1] = {title = L["Tank"], discover = specDKTank}, [2] = {title = L["Melee DPS"],	code = "c", discover = specNotDKTank}},
		DRUID	= {[1] = {title = L["Healer"], discover = 3},	[2] = {title = L["Tank"],		code = "t", discover = specBearTank}, [3] = {title = L["Melee DPS"], code = "m", discover = 2}, [4] = {title = L["Caster DPS"], code = "c", discover = 1}},
		SHAMAN	= {[1] = {title = L["Healer"], discover = 3},	[2] = {title = L["Melee DPS"],	code = "m", discover = 2}, [3] = {title = L["Caster DPS"], code = "c", discover = 1}},
		PALADIN	= {[1] = {title = L["Healer"], discover = 1},	[2] = {title = L["Tank"],		code = "t", discover = 2}, [3] = {title = L["Melee DPS"], code = "m", discover = 3}},
		PRIEST	= {[1] = {title = L["Healer"], discover = specWeight1p2}, [2] = {title = L["Caster DPS"],code = "c", discover = 3}},
	}
end

local new, del, deepDel, copy = z.new, z.del, z.deepDel, z.copy
local classOrder, classIndex = z.classOrder, z.classIndex
local GetNumRaidMembers	= GetNumRaidMembers
local IsRaidLeader		= IsRaidLeader
local IsRaidOfficer		= IsRaidOfficer
local UnitClass			= UnitClass
local UnitIsConnected	= UnitIsConnected
local UnitInParty		= UnitInParty
local UnitInRaid		= UnitInRaid
local UnitName			= UnitName

do
local function getOption(v)
	return man.db.profile[v]
end

local function setOption(v, n)
	man.db.profile[v] = n
end

man.consoleCmd = L["Manager"]
man.options = {
	type = "group",
	order = 10,
	name = "|cFFFF8080Z|cFFFFFF80O|cFF80FF80M|cFF8080FFG|rBlessings Manager",
	desc = L["Blessings Manager configuration"],
	handler = man,
	disabled = function() return z:IsDisabled() end,
	args = {
		open = {
			type = "execute",
			name = L["Open"],
			desc = L["Open Blessings Manager"],
			func = "Open",
			hidden = function() return (man.frame and man.frame:IsOpen()) or not man:IsModuleActive() end,
			order = 1,
		},
		unlock = {
			type = "execute",
			name = L["Unlock"],
			desc = L["Unlock undetected mod users for editing"],
			func = "Unlock",
			order = 2,
			hidden = function() return man:NoneLocked() end,
		},
		template = {
			type = "group",
			name = L["Templates"],
			desc = L["Template configuration"],
			order = 10,
			hidden = function() return not man:IsModuleActive() end,
			args = {
			}
		},
		chat = {
			type = "group",
			name = L["Chat Interface"],
			desc = L["Chat interface configuration"],
			order = 20,
			hidden = function() return not man:IsModuleActive() end,
			args = {
				remote = {
					type = "toggle",
					name = L["Remote Buff Requests"],
					desc = L["Allow remote buff requests via the !zomg whisper command"],
					get = getOption,
					set = setOption,
					passValue = "remotechanges",
					order = 1,
				},
			},
		},
		clean = {
			type = "group",
			name = L["Cleanup"],
			desc = L["Cleanup options"],
			order = 50,
			hidden = function() return not man:IsModuleActive() or man.db.profile.playerCodes == nil end,
			args = {
				nonguild = {
					type = "execute",
					name = L["Non-Guildies"],
					desc = L["Strip non-guildies from the stored sub-class definitions"],
					func = function() man:Clean("guild") end,
					order = 1,
				},
				nonraid = {
					type = "execute",
					name = L["Non-Raid Members"],
					desc = L["Strip non-existant raid members from the stored sub-class definitions"],
					func = function() man:Clean("raid") end,
					order = 1,
				}
			},
		},
		send = {
			type = "group",
			name = L["Send"],
			desc = L["Send options"],
			order = 98,
			hidden = function() return not man:IsModuleActive() end,
			args = {
				template = {
					type = "text",
					name = L["Template"],
					desc = L["Send Blessings Manager master template to another player"],
					usage = L["<player name>"],
					input = true,
					get = false,
					set = function(name) man:Send("template", name) end,
					order = 1,
				},
				subclasses = {
					type = "text",
					name = L["Sub-Class Assignments"],
					desc = L["Send Blessings Manager sub-class assignments"],
					usage = L["<player name>"],
					input = true,
					get = false,
					set = function(name) man:Send("subclass", name) end,
					order = 2,
				},
			}
		},
		display = {
			type = "group",
			name = L["Display"],
			desc = L["Display configuration"],
			order = 99,
			hidden = function() return not man:IsModuleActive() end,
			args = {
				autoopen = {
					type = "toggle",
					name = L["Auto-Open Class Split"],
					desc = L["Automatically open the class split frame when defining the sub-class buff assignments"],
					get = getOption,
					set = setOption,
					passValue = "autoOpen",
					order = 1,
				},
				highlights = {
					type = "toggle",
					name = L["Highlights"],
					desc = L["Highlight the selected row and column in the manager"],
					get = getOption,
					set = setOption,
					passValue = "highlights",
					order = 5,
				},
				greyout = {
					type = "toggle",
					name = L["Greyouts"],
					desc = L["Grey out invalid Drag'n'Drop target cells"],
					get = getOption,
					set = setOption,
					passValue = "greyout",
					order = 10,
				},
				showexceptions = {
					type = "toggle",
					name = L["Show Exceptions"],
					desc = L["Show first 3 exception icons if any exist for a cell. Note that this option is automatically enabled for cells which do not have a greater blessing defined"],
					get = getOption,
					set = function(k,v) setOption(k,v) if (man.frame and man.frame:IsOpen()) then man:DrawAll() end end,
					passValue = "showexceptions",
					order = 15,
				},
			}
		},
		behaviour = {
			type = 'group',
			name = L["Behaviour"],
			desc = L["Other behaviour"],
			order = 201,
			args = {
				whispers = {
					type = "toggle",
					name = L["Whispers"],
					desc = L["Send assignments to paladins without ZOMGBuffs or PallyPower via whispers?"],
					get = getOption,
					set = setOption,
					passValue = "whispers",
					order = 1,
				},
			},
		},
	},
}
man.moduleOptions = man.options
man.hideMenuTitle = true
end

-- SetClassIcon
local classButtons = CLASS_BUTTONS
local function SetClassIcon(icon, class)
	local b = classButtons[class]
	if (b) then
		local l, r, t, b = unpack(b)
		icon:SetTexCoord(l + 0.025, r - 0.025, t + 0.025, b - 0.025)
	else
		icon:SetTexCoord(0.75, 1, 0.75, 1)
	end
end

-- DefaultTemplateSubclass
local function DefaultTemplateSubclass()
	return {
		WARRIOR = {
			m = {"BOM", "BOK", "SAN"},
		},
		DEATHKNIGHT = {
			m = {"BOM", "BOK", "SAN"},
		},
		DRUID = {
			c = {"BOW", "BOK", "SAN"},
			m = {"BOM", "BOK", "SAN", "BOW"},
			t = {"BOK", "BOM", "SAN", "BOW"},
		},
		SHAMAN = {
			c = {"BOK", "BOW", "SAN"},
			m = {"BOM", "BOK", "BOW", "SAN"},
		},
		PALADIN = {
			m = {"BOM", "BOK", "BOW", "SAN"},
			t = {"BOK", "BOW", "SAN", "BOM"},
		},
		PRIEST = {
			c = {"BOW", "BOK", "SAN"},
		},
	}
end

-- DefaultTemplate
local function DefaultTemplate()
	return {
		WARRIOR	= {"BOK", "BOM", "SAN"},
		DEATHKNIGHT = {"BOK", "BOM", "SAN"},
		ROGUE	= {"BOM", "BOK", "SAN"},
		HUNTER	= {"BOM", "BOK", "BOW", "SAN"},
		DRUID	= {"BOW", "BOK", "SAN"},
		SHAMAN	= {"BOW", "BOK", "SAN", "BOM"},
		PALADIN	= {"BOW", "BOK", "SAN", "BOM"},
		PRIEST	= {"BOW", "BOK", "SAN"},
		MAGE	= {"BOW", "BOK", "SAN"},
		WARLOCK	= {"BOW", "BOK", "SAN"},
		subclass = DefaultTemplateSubclass(),
	}
end

-- SetSelf
function man:SetSelf()
	playerName = UnitName("player")
	playerClass = select(2, UnitClass("player"))
	self.canEdit = playerClass == "PALADIN" or (GetNumRaidMembers() > 0 and (IsRaidLeader() or IsRaidOfficer())) or (GetNumPartyMembers() > 0 and IsPartyLeader())
end

-- OnModuleInitialize
local should
function man:OnModuleInitialize()
	self.db = z:AcquireDBNamespace("BlessingsManager")
	z:RegisterDefaults("BlessingsManager", "profile", {
		templates = {
			[L["Default"]] = DefaultTemplate(),
		},
		defaultTemplate = L["Default"],
		highlights = true,
		autoOpen = true,
		remotechanges = false,
		whispers = false,
		groups = 5,
		greyout = true,
		showexceptions = true,
	} )
	z:RegisterChatCommand({"/zomgman", "/zomgmanager", "/zomgbm"}, self.options)
	self.OnMenuRequest = self.options
	z.options.args.ZOMGBlessingsManager = self.options

	self:SetSelf()

	-- ACK - Comes from Blessings module to acknowledge receipt of new template
	z.OnCommReceive.ACK = function(self, prefix, sender, channel)
		man:OnReceiveAck(sender)
	end
	-- NACK - Comes from Blessings module to acknowledge receipt of BAD template
	z.OnCommReceive.NACK = function(self, prefix, sender, channel, retry)
		man:OnReceiveNack(sender, retry)
	end
	-- MODIFIEDTEMPLATE - Comes from Blessings module to indicate change of assisngment
	z.OnCommReceive.MODIFIEDTEMPLATE = function(self, prefix, sender, channel, template, response)
		man:OnReceiveTemplate(sender, template, true)
	end
	-- TEMPLATE - Comes from Blessings module in response to a REQUESTTEMPLATE query from Manager
	z.OnCommReceive.TEMPLATE = function(self, prefix, sender, channel, template)
		man:OnReceiveTemplate(sender, template)
	end
	-- AURA - Comes from Blessings module in response to a REQUESTTEMPLATE query from Manager
	z.OnCommReceive.AURA = function(self, prefix, sender, channel, aura)
		man:OnReceiveAura(sender, aura)
	end
	-- GIVEMASTERTEMPLATE - Triggered from menu to send Manager template to another player
	z.OnCommReceive.GIVEMASTERTEMPLATE = function(self, prefix, sender, channel, template)
		man:OnReceiveMasterTemplate(sender, template)
	end
	-- GIVEMASTERTEMPLATE - Triggered from menu to send Manager sub-class assignments to another player
	z.OnCommReceive.GIVESUBCLASSES = function(self, prefix, sender, channel, playerCodes)
		man:OnReceiveSubClassDefinitions(sender, playerCodes)
	end
	-- SYMBOLCOUNT - Broadcasted on RAID addon channel when sym count changes
	z.OnCommReceive.SYMBOLCOUNT = function(self, prefix, sender, channel, count)
		man:OnReceiveSymbolCount(sender, count)
	end
	-- GIVETEMPLATEPART - Sent from Manager when a user changes a single assignment
	z.OnCommReceive.GIVETEMPLATEPART = function(self, prefix, sender, channel, name, class, Type)
		man:OnReceiveBroadcastTemplatePart(sender, name, class, Type)
	end
	-- GIVEAURA - Sent from Manager when a user changes an aura assignment
	z.OnCommReceive.GIVEAURA = function(self, prefix, sender, channel, name, aura)
		man:OnReceiveBroadcastAura(sender, name, aura)
	end
	-- SYNCGROUPS - Sets your effective groups setting to match the senders (after a template generation)
	z.OnCommReceive.SYNCGROUPS = function(self, prefix, sender, channel, groups)
		if (groups ~= man.db.profile.groups and z.db.profile.info) then
			man.db.profile.groups = groups
			man:Print(L["Synchronised group count with %s to %d because of pending blessing assignments"], z:ColourUnitByName(sender), groups)
			man:AssignPaladins()
			if (man.frame and man.frame:IsOpen()) then
				man:DrawAll()
			end
		end
	end

	self.OnModuleInitialize = nil
end

-- CreateDragDropItem
function man:CreateDragDropItem()
	local icon = CreateFrame("GameTooltip", "ZOMGBuffsTooltipDragger", UIParent, "GameTooltipTemplate")
	icon.tex = icon:CreateTexture(nil, "OVERLAY")
	icon.tex:SetAllPoints()
	icon.text = icon:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	icon.text:SetAllPoints(true)
	self.dragIcon = icon

	self.SplitCreateDragDropItem = nil
	return icon
end

-- StartDrag
function man:StartDrag(text, r, g, b)
	local icon = man.dragIcon
	if (not icon) then
		icon = man:CreateDragDropItem()
	end

	icon:SetBackdropBorderColor(0, 0, 0, 0)
	icon:SetOwner(UIParent, "ANCHOR_CURSOR")
	icon:SetText(" ")
	icon:Show()
	icon:SetAlpha(0.7)

	if (type(text) == "string") then
		icon.tex:Hide()
		icon.text:Show()
		icon.text:SetText(text)
		if (type(r) == "number") then
			icon.text:SetTextColor(r, g, b)
		end
		icon:SetWidth(icon.text:GetStringWidth() + 10)
		icon:SetHeight(icon.text:GetStringHeight() + 10)
	else
		icon.text:Hide()
		icon.tex:Show()
		icon.tex:SetTexture(r)
		icon:SetWidth(24)
		icon:SetHeight(24)
	end

	return icon
end

-- onCellClick
local function onCellClick(self, button)
	man:OnCellClick(self.row, self.col, button, self.split)
end

local function onCellMouseWheel(self, value)
	man:OnCellClick(self.row, self.col, value > 0 and "MOUSEWHEELUP" or "MOUSEWHEELDOWN", self.split)
end

local function onCellDrag(self)
	man:OnCellDrag(self, self.row, self.col, self.split)
end

local function onCellDragStop(self)
	man:OnCellDragStop(self)
end

local function onCellEnter(self)
	if (man.dragIcon and man.dragIcon:IsShown()) then
		return
	end
	if (man.configuring and self.split) then
		man:HighlightClass(man.expandpanel.class, self.row)
	else
		man:OnCellEnter(self, self.row, self.col)
	end
end

local function onCellLeave(self)
	if (man.dragIcon and man.dragIcon:IsShown()) then
		return
	end
	GameTooltip:Hide()
	man:HighlightClass()
end

-- GenericCheckBox
function man:GenericCheckBox(name, parent, str, onClick)
	local tick = CreateFrame("CheckButton", name, parent, "UICheckButtonTemplate")
	tick:SetHeight(20)
	tick:SetWidth(20)
	tick:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up")
	tick:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down")
	tick:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight", "ADD")
	tick:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check")
	tick:SetDisabledCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check-Disabled")
	tick:RegisterForClicks("LeftButtonUp", "RightButtonUp")

	local text = getglobal(tick:GetName().."Text")
	text:SetText(str)
	tick:SetHitRectInsets(0, -(text:GetStringWidth()), 0, 0)

	tick:SetScript("OnClick", onClick)
	
	return tick
end

-- CreateSplitFrame
function man:SplitCreateFrame()
	if (not ZFrame) then
		ZFrame = LibStub("ZFrame-1.0")
	end
	local f = ZFrame:Create(self, L["SPLITTITLE"], nil, 0.7, 0, 0.7)
	self.splitframe = f
	f.ZMain:SetFrameStrata("DIALOG")

	self.frame.OnClose = function(self)
		local f = man.splitframe
		if (f and f:IsOpen()) then
			f:Close()
		end
		if (man.expandpanel) then
			man.expandpanel:Hide()
		end
	end

	f:SetSize(120, 200)

	local cell = CreateFrame("Button", nil, f)
	f.classIcon = cell
	cell:SetWidth(36)
	cell:SetHeight(36)
	cell:SetNormalTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")
	cell:EnableMouse(false)
	cell:SetPoint("TOPLEFT")

	f.talentIcon = {}
	local function MakeTalentDescriptor(i)
		local icon
		icon = f:CreateTexture(nil, "BACKGROUND")
		icon:SetPoint("TOPLEFT", cell, "TOPRIGHT", 2, -((i - 1) * 12))
		icon:SetHeight(12)
		icon:SetWidth(12)
		icon:SetTexCoord(0.09375, 0.90625, 0.09375, 0.90625)

		local text = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		text:SetPoint("LEFT", icon, "RIGHT", 2, 0)
		text:SetTextColor(1, 1, 1)

		f.talentIcon[i] = icon
		f.talentIcon[i].text = text
	end

	MakeTalentDescriptor(1)
	MakeTalentDescriptor(2)
	MakeTalentDescriptor(3)

	self.SplitCreateFrame = nil
end

-- SetMinRank
local rankInfoOptions
function man:SplitSetMinRank()
	if (not rankInfoOptions) then
		rankInfoOptions = {
			type	= 'group',
			name	= L["Ranks"],
			desc	= L["Ranks"],
			args	= {
				title = {
					type = 'header',
					name = L["Ranks"],
					order = 1
				},
			},
		}

		local function getRank(myRank)
			local ranks = self.db.profile.useguildranks
			local rankName = GuildControlGetRankName(myRank)
			return not ranks or ranks[rankName]
		end
		local function setRank(newRank, onoff)
			local ranks = self.db.profile.useguildranks
			if (not ranks) then
				ranks = {}
				for i = 1,GuildControlGetNumRanks() do
					ranks[GuildControlGetRankName(i)] = true
				end
				self.db.profile.useguildranks = ranks
			end
			local rankName = GuildControlGetRankName(newRank)
			ranks[rankName] = onoff
			man:SplitPopulate()
		end

		local doneRanks = new()						-- For guilds that have duplicate named ranks (Mine)
		for i = 1,GuildControlGetNumRanks() do
			local rankName = GuildControlGetRankName(i)
			if (not doneRanks[rankName]) then
				doneRanks[rankName] = true

				rankInfoOptions.args["rank"..i] = {
					type	= 'toggle',
					name	= rankName,
					desc	= rankName,
					get		= getRank,
					set		= setRank,
					passValue = i,
					order	= i + 10,
				}
			end
		end
		del(doneRanks)
	end

	dewdrop:Close()
	dewdrop:Open(self.splitframe.rankButton, 'children', rankInfoOptions, 'point', "TOPLEFT", 'relativePoint', "BOTTOMLEFT")
end

-- SplitInitialize
function man:SplitInitialize()
	local f = self.splitframe
	SetClassIcon(f.classIcon:GetNormalTexture(), f.class)

	self:SplitCreateColumns()

	local columns = self:SplitColumnCount(f.class)
	f:SetSize(120 * columns + 5 * (columns - 1), self.db.profile.useguild and 240 or 215)

	for i = 1,#f.column do
		if (i > columns) then
			f.column[i]:Hide()
		else
			f.column[i]:Show()
			f.column[i].offset = 0
		end
	end

	self:SplitTitles()
end

-- SplitColumnCount
function man:SplitColumnCount(class)
	local splits = self.classSplits[class]
	if (splits) then
		local count = 0
		for k,v in pairs(splits) do
			count = count + 1
		end
		return count
	end

	return 1
end

-- SplitTitles
function man:SplitTitles()
	local f = self.splitframe
	local splits = self.classSplits[f.class]
	if (splits) then
		for i,split in ipairs(splits) do
			local column = f.column[i]
			if (not column) then
				error("Missing column number "..i)
			end
			column.title:SetText(split.title)
		end
	else
		if (f.column[1]) then
			f.column[1].title:SetText("")
		end
	end
end

-- splitDragStart
local function splitDragStart(self)
	local r, g, b = self.text:GetTextColor()
	local name = self.text:GetText()
	local drag = man:StartDrag(name, r, g, b)
	drag.row, drag.col = self.row, self.col
	drag.name = name
end

-- splitDragStop
local function splitDragStop(self)
	local icon = man.dragIcon
	if (not icon) then
		return
	end
	icon:Hide()
	
	local f = man.splitframe

	local focus = GetMouseFocus()

	for n = 1,man:SplitColumnCount(f.class) do
		local column = f.column[n]
		if (column:IsMouseOver()) then
			target = n
			break
		end
	end

	if (target and target ~= self.col) then
		man:SplitMovePlayer(icon.name, icon.col, target)
		man:SplitPopulate()
	end
end

-- splitMouseWheel
local function splitMouseWheel(self, delta)
	local col = self:GetParent()
	local oldOffset = col.offset
	col.offset = max(0, col.offset - delta)
	if (col.offset ~= oldOffset) then
		man:SplitPopulateColumn(col)
	end
end

-- splitOnVerticalScroll
local function splitOnVerticalScroll(self, value)
	local col = self:GetParent()

	local scrollbar = getglobal(self:GetName().."ScrollBar")
	scrollbar:SetValue(value)
	col.offset = floor(value)

	man:SplitPopulateColumn(col)
end

-- SplitMovePlayer
function man:SplitMovePlayer(name, from, to)
	local f = self.splitframe
	local codes = self.db.profile.playerCodes
	if (not codes) then
		codes = new()
		self.db.profile.playerCodes = codes
	end
	if (not codes[f.class]) then
		codes[f.class] = new()
	end

	if (to == 1) then
		codes[f.class][name] = nil
	else
		codes[f.class][name] = self.classSplits[f.class][to].code
	end

	if (not next(codes[f.class])) then
		codes[f.class] = del(codes[f.class])
	end
	if (not next(codes)) then
		self.db.profile.playerCodes = del(codes)
	end
end

-- SplitSetIcons
function man:SplitCreateColumns()
	local f = self.splitframe

	if (not f.column) then
		f.column = {}
	end
	for n = 1,self:SplitColumnCount(f.class) do
		local column = f.column[n]
		if (not column) then
			column = CreateFrame("Frame", nil, f)
			f.column[n] = column

			if (n == 1) then
				column:SetPoint("TOPLEFT", 0, -54)
			else
				column:SetPoint("TOPLEFT", f.column[n - 1], "TOPRIGHT", 5, 0)
			end
			column:SetWidth(120)
			column:SetHeight(140)

			column:SetBackdrop({
				bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = true, tileSize = 64,
				edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 16,
				insets = {left = 4, right = 4, top = 4, bottom = 4},
			})
			column:SetBackdropColor(0, 0, 0, 1)
			column:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)

			local title = column:CreateFontString(nil, "BACKGROUND", "GameFontHighlight")
			column.title = title
			title:SetPoint("BOTTOM", column, "TOP")
			title:SetHeight(14)

			local scroll = CreateFrame("ScrollFrame", "ZOMGClassSplitColumn"..n.."ScrollFrame", column, "FauxScrollFrameTemplate")
			scroll:SetPoint("TOPRIGHT", -26, -4)
			scroll:SetPoint("BOTTOMLEFT", column, "BOTTOMRIGHT", -36, 3)
			scroll:Hide()
			scroll:SetScript("OnVerticalScroll", splitOnVerticalScroll)
			scroll.bar = getglobal(scroll:GetName().."ScrollBar")

			-- Make the slider go to ends
			scroll.bar:GetThumbTexture():SetTexCoord(0.23, 0.75, 0.27, 0.73)
			scroll.bar:GetThumbTexture():SetHeight(16)

			column.scroll = scroll

			local list = {}
			column.list = list

			for i = 1,10 do
				local line = CreateFrame("Frame", nil, column)
				line.col = n
				line.row = i
				list[i] = line

				line:EnableMouse(true)
				line:EnableMouseWheel(true)

				line.icon = line:CreateTexture(nil, "BACKGROUND")
				line.icon:SetPoint("TOPLEFT")
				line.icon:SetWidth(12)
				line.icon:SetHeight(12)
				line.icon:Hide()
				line.icon:SetTexCoord(0.09375, 0.90625, 0.09375, 0.90625)

				line.text = line:CreateFontString(nil, "OVERLAY", "GameFontNormal")
				line.text:SetJustifyH("LEFT")
				line.text:SetPoint("TOPLEFT", 14, 0)
				line.text:SetPoint("BOTTOMRIGHT")

				if (i == 1) then
					line:SetPoint("TOPLEFT", 5, -5)
				else
					line:SetPoint("TOPLEFT", list[i - 1], "BOTTOMLEFT")
				end

				line:SetWidth(110)
				line:SetHeight(13)

				line.highlight = line:CreateTexture(nil, "HIGHLIGHT")
				line.highlight:SetAllPoints(true)
				line.highlight:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
				line.highlight:SetBlendMode("ADD")

				line:RegisterForDrag("LeftButton")
				line:SetScript("OnDragStart", splitDragStart)
				line:SetScript("OnDragStop", splitDragStop)
				line:SetScript("OnMouseWheel", splitMouseWheel)
			end

			if (n == 1) then
				local tick = self:GenericCheckBox("ZOMGClassSplitGuildCheck", column, L["Use Guild Roster"],
					function(self)
						man.db.profile.useguild = self:GetChecked() and true or false
						man:SplitPopulate()
						local columns = man:SplitColumnCount(f.class)
						if (man.db.profile.useguild) then
							f.rankButton:Show()
							f:SetSize(120 * columns + 5 * (columns - 1), 240)
						else
							f.rankButton:Hide()
							f:SetSize(120 * columns + 5 * (columns - 1), 215)
						end
					end)
				tick:SetChecked(self.db.profile.useguild)
				tick:SetPoint("TOPLEFT", column, "BOTTOMLEFT")
				f.useGuild = tick
				if (not IsInGuild()) then
					tick:Disable()
					getglobal(tick:GetName().."Text"):SetTextColor(0.5, 0.5, 0.5)
				end

				f.rankButton = self:MakeButton(column, L["Ranks"], L["Select the guild ranks to include"], man.SplitSetMinRank)
				f.rankButton:SetPoint("TOPLEFT", tick, "BOTTOMLEFT", 0, 0)
				
				if (not self.db.profile.useguild) then
					f.rankButton:Hide()
				end
				
			elseif (n == 2) then
				if (not f.autoButton) then
					f.autoButton = self:MakeButton(column, L["Auto Assign"], L["Automatically assign players to sub-classes based on talent spec"], man.SplitAutoAssign)
					f.autoButton:SetPoint("BOTTOM", column, "TOP", 0, 20)
				end
			end
		end
		del(column.members)
		column.members = new()
	end
end

-- SplitClass
function man:SplitClass(class, dontClose)
	-- Create frame
	if (not self.splitframe) then
		self:SplitCreateFrame()
	end
	local f = self.splitframe

	-- Toggle it on OnClick
	if (f:IsOpen()) then
		if (f.class == class and not dontClose) then
			f:Close()
			return
		end
	else
		f:Open()
	end

	f.class = class
	self:SplitInitialize()

	self:SplitPopulate()
end

-- SplitPopulateColumn
function man:SplitPopulateColumn(i)
	local f = self.splitframe
	local column = type(i) == "number" and f.column[i] or i

	local sortList = new()
	for name in pairs(column.members) do
		tinsert(sortList, name)
	end
	sort(sortList)

	for i,line in ipairs(column.list) do
		line:Hide()
	end

	if (column.offset > #sortList - 10) then
		column.offset = #sortList - 10
	end
	if (column.offset < 0) then
		column.offset = 0
	end

	FauxScrollFrame_Update(column.scroll, #sortList, 10, 1)
	column.scroll.bar:SetValue(column.offset)

	local c = z:GetClassColour(f.class)
	local j = 1
	--for n,name in ipairs(sortList) do
	for n = 1 + column.offset,10 + column.offset do
		local name = sortList[n]
		if (not name) then
			break
		end

		local line = column.list[j]
		line.text:SetText(name)

		line.icon:Hide()

		if (column.members[name] == "guild") then
			line.text:SetTextColor(c.r * 0.6, c.g * 0.6, c.b * 0.6)
		else
			line.text:SetTextColor(c.r, c.g, c.b)

			local spec, s1, s2, s3 = LGT:GetUnitTalentSpec(name)
			if (spec and s1 and s2 and s3) then
				local icon1, icon2, icon3 = LGT:GetTreeIcons(f.class)
				if (icon1) then
					local tex
					if (s1 > s2 and s1 > s3) then
						tex = icon1
					elseif (s2 > s1 and s2 > s3) then
						tex = icon2
					elseif (s3 > s1 and s3 > s2) then
						tex = icon3
					end

					if (tex) then
						line.icon:SetTexture(tex)
						line.icon:Show()
					end
				end
			end
		end

		line:Show()

		j = j + 1
		if (j > 10) then
			break
		end
	end

	del(sortList)
end

-- SplitPopulate
function man:SplitPopulate()
	local f = self.splitframe
	if (not f or not f:IsOpen()) then
		return
	end
	local class = f.class

	local splits = self.classSplits[f.class]
	local codes = self.db.profile.playerCodes

	for i,column in ipairs(f.column) do
		column.members = del(column.members)
		column.members = new()
	end
	
	for unit, unitname, unitclass, subgroup, index in z:IterateRoster() do
		if (unitclass == class and subgroup <= self.db.profile.groups) then
			local code = codes and codes[class] and codes[class][unitname]

			if (code) then
				local assigned
				for i,split in ipairs(splits) do
					if (split.code == code) then
						f.column[i].members[unitname] = true
						assigned = true
						break
					end
				end
				if (not assigned) then
					error("Could not assign "..unitname.." to a column for "..class.." with player code of '"..code.."'")
				end
			else
				f.column[1].members[unitname] = true
			end
		end
	end
	
	if (self.db.profile.useguild) then
		local minLevel = floor(UnitLevel("player") / 10) * 10

		for index = 1,GetNumGuildMembers(true) do
			local name, rank, rankIndex, level, gclass, zone, note, officernote, online, status = GetGuildRosterInfo(index)
			if (not name) then
				break
			end
			
			if (not self.db.profile.useguildranks or self.db.profile.useguildranks[rank]) then
				if (level >= minLevel) then
					gclass = z.classReverse[gclass]
					if (gclass == class) then
						local code = codes and codes[class] and codes[class][name]
						if (code) then
							local assigned
							for i,split in ipairs(splits) do
								if (split.code == code) then
									if (not f.column[i].members[name]) then
										f.column[i].members[name] = "guild"
									end
									assigned = true
									break
								end
							end
							if (not assigned) then
								error("Could not assign "..name.." from guild roster to a column for "..class.." with player code of '"..code.."'")
							end
						else
							if (not f.column[1].members[name]) then
								f.column[1].members[name] = "guild"
							end
						end
					end						
				end
			end
		end
	end

	self:SplitColumnDrawAll()
	self:SplitDrawTalentDescriptors()
end

-- SplitAutoRoles
function man:SplitAutoRoles()
	self:SplitAutoAssignClass()
	self:SplitPopulate()
	self.splitframe:Close()
end

-- SplitAutoAssignClass
-- nil class will auto assign all roles for whole roster
function man:SplitAutoAssignClass(class)
	for unit, unitname, unitclass, subgroup, index in z:IterateRoster() do
		if ((not class or unitclass == class) and subgroup <= self.db.profile.groups) then
			local splitDefs = self.classSplits[unitclass]
			if (splitDefs) then
				local spec, s1, s2, s3 = LGT:GetUnitTalentSpec(unit)
				if (spec and s1 and s2 and s3) then
					local belongsTo
					for i,def in ipairs(splitDefs) do
						if (type(def.discover) == "number") then
							if (def.discover == 1 and s1 > s2 and s1 > s3) then
								belongsTo = i
								break
							elseif (def.discover == 2 and s2 > s1 and s2 > s3) then
								belongsTo = i
								break
							elseif (def.discover == 3 and s3 > s1 and s3 > s2) then
								belongsTo = i
								break
							end
						else
							if (def.discover(unit, s1, s2, s3)) then
								belongsTo = i
								break
							end
						end
					end
					if (belongsTo) then
						self:SplitClass(unitclass)
						self:SplitMovePlayer(unitname, nil, belongsTo)
					end
				end
			end
		end
	end
end

-- SplitAutoAssign
function man:SplitAutoAssign()
	local f = self.splitframe
	if (not f or not f:IsOpen()) then
		return
	end

	self:SplitAutoAssignClass(f.class)
	self:SplitPopulate()
end

-- SplitDrawTalentDescriptors
function man:SplitDrawTalentDescriptors()
	local f = self.splitframe
	if (not f or not f:IsOpen()) then
		return
	end

	local icon = new()
	local name = new()
	name[1], name[2], name[3] = LGT:GetTreeNames(f.class)
	icon[1], icon[2], icon[3] = LGT:GetTreeIcons(f.class)
	for i = 1,3 do
		if (name[i] and icon[i]) then
			f.talentIcon[i]:Show()
			f.talentIcon[i].text:Show()

			f.talentIcon[i]:SetTexture(icon[i])
			f.talentIcon[i].text:SetText(name[i])
		else
			f.talentIcon[i]:Hide()
			f.talentIcon[i].text:Hide()
		end
	end

	del(icon)
	del(name)
end

-- SplitColumnDrawAll
function man:SplitColumnDrawAll()
	local f = self.splitframe
	if (f and f:IsOpen()) then
		for i = 1,self:SplitColumnCount(f.class) do
			self:SplitPopulateColumn(i)
		end
	end
end

-- scaleTitleTex
local function scaleTitleTex(icon, scale)
	icon:SetHeight(36 * (scale or 1))
	icon:SetWidth(36 * (scale or 1))
	icon:ClearAllPoints()
	icon:SetPoint("TOPLEFT")
end

-- SplitPositionCells
function man:SplitPositionCells()
	local extraWidth = 0
	for i,class in ipairs(classOrder) do
		local exp = self.expanding and self.expanding[class]
		local size

		local titleCell = self.frame.classTitle.cell[i]
		local nextTitleCell = self.frame.classTitle.cell[i + 1]

		scaleTitleTex(titleCell.normalTex, exp and exp.titleScale)
		scaleTitleTex(titleCell.highlightTex, exp and exp.titleScale)

		if (nextTitleCell and i < #classOrder) then
			local offset = (exp and exp.offset) or 0
			extraWidth = extraWidth + offset
			nextTitleCell:SetPoint("TOPLEFT", titleCell, "TOPRIGHT", 6 + offset, 0)
		end

		for j,row in ipairs(self.frame.row) do
			local cell = row.cell[i]
			local nextCell = row.cell[i + 1]
			if (nextCell and not nextCell.aura) then
				nextCell:SetPoint("TOPLEFT", cell, "TOPRIGHT", 6 + ((exp and exp.offset) or 0), 0)
			end
		end
	end

	local h, w
	h = 66 + #blessingCycle * 42
	w = 136 + 42 * (#classOrder + 1) + extraWidth

	self.frame:SetSize(w, h)
end

-- splitExpandOnUpdate
local function splitExpandOnUpdate(self, elapsed)
	local any
	self.inOffset = nil
	for c,d in pairs(man.expanding) do
		if (c == man.expandpanel.inOffsetClass) then
			self.inOffset = d.offset
		end

		if (d.dir ~= "done") then
			local finishedThisOne
			local distanceToMove = min(d.targetOffset, d.targetOffset * elapsed * 2)
			if (d.dir == "in") then
				d.offset = d.offset - distanceToMove
				if (d.offset <= 0) then
					d.offset = 0
					finishedThisOne = true
					d.dir = "done"
					man.expanding[c] = nil
				end

				d.titleScale = min(1, (d.titleScale or 0.7) + elapsed)
			else
				d.offset = d.offset + distanceToMove
				if (d.offset >= d.targetOffset) then
					d.offset = d.targetOffset
					finishedThisOne = true
					d.dir = "done"
				end
				self.outOffset = d.offset

				d.titleScale = max(0.7, (d.titleScale or 1) - elapsed)
			end

			if (not finishedThisOne) then
				any = true
			end
		end

		man:SplitPositionCells()
	end

	-- See how much space we have from d.offset and start fading in one column at a time
	local panel = man.expandpanel
	if (panel) then
		local c = man:SplitColumnCount(panel.class) - 1

		if (panel.targetClass) then
			if (panel.class) then
				local anyFaders
				for i = 1,c do
					local col = panel.column[i]
					local a = col:GetAlpha()
					if (a > 0) then
						if (self.inOffset and (i + 1) * 36 > self.inOffset) then		-- not self.inOffset or
							col:SetAlpha(max(0, a - (elapsed * 6)))
						end
						any = true
						anyFaders = true
					end
				end

				if (not anyFaders) then
					man:SplitPanelSetClass()
					any = true
				end
			else
				man:SplitPanelSetClass()
				any = true
			end
		else
			if (self.outOffset) then
				for i = 1,c do
					local col = panel.column[i]
					if (col) then
						local a = col:GetAlpha()
						if (a < 1) then
							if (self.outOffset > i * 36 - 18) then
								col:SetAlpha(min(1, a + (elapsed * 4)))
							end
							any = true
						end
					end
				end
			end
		end
	end

	if (not any) then
		self:SetScript("OnUpdate", nil)
	end
end

-- CreatePanelTitle
function man:CreatePanelTitle()
	local panel = self.expandpanel
	panel.title1 = panel.column[1]:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	panel.title1:SetPoint("BOTTOM", panel, "TOPLEFT", -24, 5)
	panel.title1:SetHeight(40)
	panel.title1:SetWidth(38)
	panel.title1:SetTextColor(1, 1, 1)
	panel.title1:SetJustifyV("BOTTOM")
	self.CreatePanelTitle = nil
end

-- SplitPanelColumnPopulate
function man:SplitPanelColumnPopulate(col)
	local panel = self.expandpanel
	local class = panel.class
	if (class) then
		for i = 1,#blessingCycle do
			local Type = self:GetCell(i, col.col, true)
			local cell = col.cell[i]
			if (Type) then
				local singleSpell, classSpell = z:GetBlessingFromType(Type)
				local info = z.blessings[classSpell or singleSpell]
				local icon = info.icon

				cell.icon:SetTexture(icon)
				if (self:CellHasError(i, col.col, true)) then
					self.anyErrors = true
					cell.icon:SetVertexColor(1, 0.5, 0.5)
				else
					cell.icon:SetVertexColor(1, 1, 1)
				end
			else
				cell.icon:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")		-- Blank for errors/missing
				cell.icon:SetVertexColor(0, 0, 0)
			end
		end
	end
end

-- SplitPanelSetClass
function man:SplitPanelSetClass()
	local panel = self.expandpanel

	panel.class = panel.targetClass
	panel.targetClass = nil

	if ((self.splitframe and self.splitframe:IsOpen()) or (self.db.profile.autoOpen and (not self.splitframe or not self.splitframe:IsOpen()))) then
		self:SplitClass(panel.class, true)
	end

	local c = self:SplitColumnCount(panel.class) - 1
	for i = 1,c do
		local col = panel.column[i]
		if (col) then
			col:Show()
			col.title:SetText(self.classSplits[panel.class][i + 1].title)
			self:SplitPanelColumnPopulate(col)
		end
	end
	for i = c + 1,#panel.column do
		local col = panel.column[i]
		col:Hide()
	end

	if (not panel.title1) then
		self:CreatePanelTitle()
	end
	if (c > 0) then
		panel.title1:SetText((self.classSplits[panel.class] and self.classSplits[panel.class][1].title) or "")
	else
		panel.title1:SetText("")
	end

	panel:SetWidth(42 * c)

	local ind = classIndex[panel.class]
	local parent = self.frame.classTitle.cell[ind]
	panel:SetPoint("TOPLEFT", parent, "BOTTOMRIGHT", 6, -8)
end

-- SplitCreateExpandPanelColumn
function man:SplitCreateExpandPanelColumns()
	local panel = self.expandpanel
	if (not panel.column) then
		panel.column = {}
	end

	local function CreateColumn(colNumber)
		local col = CreateFrame("Frame", "ZOMGBMExpandColumn"..colNumber, panel)
		panel.column[colNumber] = col
		col.col = colNumber
		col.cell = {}
		col:SetWidth(42)
		col:SetHeight(42 * 6)

		col.title = col:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		col.title:SetPoint("BOTTOM", col, "TOP", -3, 5)
		col.title:SetHeight(40)
		col.title:SetWidth(38)
		col.title:SetTextColor(1, 1, 1)
		col.title:SetJustifyV("BOTTOM")

		if (colNumber == 1) then
			col:SetPoint("TOPLEFT")
		else
			col:SetPoint("TOPLEFT", panel.column[colNumber - 1], "TOPRIGHT")
		end

		local cell
		for i = 1,#blessingCycle do
			prev = cell

			abCount = abCount + 1
			cell = CreateFrame("Button", "ZOMGActionButton"..abCount, col, "ActionButtonTemplate")
			tinsert(col.cell, cell)
			if (i == 1) then
				cell:SetPoint("TOPLEFT")
			else
				cell:SetPoint("TOPLEFT", prev, "BOTTOMLEFT", 0, -6)
			end

			cell.icon = getglobal(cell:GetName().."Icon")
			cell.text = getglobal(cell:GetName().."Text")

			cell.col = colNumber
			cell.row = i
			cell.split = true

			cell:SetHitRectInsets(-4, -4, -4, -4)
			cell:EnableMouseWheel(true)

			cell:SetScript("OnEnter", onCellEnter)
			cell:SetScript("OnLeave", onCellLeave)
			cell:SetScript("OnClick", onCellClick)
			cell:SetScript("OnDragStart", onCellDrag)
			cell:SetScript("OnDragStop", onCellDragStop)
			cell:SetScript("OnMouseWheel", onCellMouseWheel)
			cell:RegisterForDrag("LeftButton")
			cell:RegisterForClicks("AnyUp")
		end
		col:SetAlpha(0)
		return col
	end

	for i = 1,3 do
		local col = panel.column[i]
		if (not col) then
			col = CreateColumn(i)
		end
	end

	self.SplitCreateExpandPanelColumns = nil
end

-- SplitCreateExpandPanel
function man:SplitCreateExpandPanel()
	local panel = CreateFrame("Frame", "ZOMGBMExpandPanel", self.frame)
	self.expandpanel = panel

	self.expandpanel:SetScript("OnHide",
		function(self)
			man:SplitExpand("reset")
			if (self.title1) then
				self.title1:SetText("")
			end
			self.class = nil
			self.targetClass = nil
			for i = 1,3 do
				local col = self.column[i]
				if (col) then
					col:SetAlpha(0)
				end
			end
		end)

	panel:SetHeight(36 * 6 + 20)
	panel:SetWidth(42)

	self.SplitCreateExpandPanel = nil
	return panel
end

-- SplitExpand
function man:SplitExpand(class)
	if (self.dragIcon and self.dragIcon:IsShown()) then
		return
	end

	if (class == "reset") then
		self.frame:SetScript("OnUpdate", nil)
		self.expanding = del(self.expanding)
		self:SplitPositionCells()
		return
	end

	if (not self.configuring) then
		return
	end

	if (not self.expanding) then
		self.expanding = new()
	end
	if (self.expanding[class] and self.expanding[class].dir == "out") then
		return
	end

	for cl,d in pairs(self.expanding) do
		if (cl ~= class) then
			local exp = self.expanding[cl]
			if (exp.dir ~= "in") then
				exp.dir = "in"
			end
		end
	end

	local c = self:SplitColumnCount(class) - 1
	if (c > 0) then
		if (not self.expanding[class]) then
			self.expanding[class] = {dir = "out", cols = c, targetOffset = c * 42, offset = 0}
		else
			self.expanding[class].dir = "out"
		end
	end
	self.frame:SetScript("OnUpdate", splitExpandOnUpdate)

	if (not self.expandpanel) then
		self:SplitCreateExpandPanel()
	end
	self.expandpanel:Show()

	if (self.SplitCreateExpandPanelColumns) then
		self:SplitCreateExpandPanelColumns()
	end

	if (self.expandpanel.class ~= class) then
		self.expandpanel.targetClass = class
		if (self.expandpanel.class) then
			local c1 = self:SplitColumnCount(self.expandpanel.class)
			if (c1 > 1) then
				self.expandpanel.inOffsetClass = self.expandpanel.class
			else
				self:SplitPanelSetClass()
			end
		else
			self:SplitPanelSetClass()
		end
	else
		self.expandpanel.targetClass = nil
	end
end

-- ReadPaladinSpec
function man:ReadPaladinSpec(pala, name)
	pala.canKings = UnitLevel(name) >= 20
	local t, s1, s2, s3 = LGT:GetUnitTalentSpec(name)
	if (t and s1) then
		pala.canSanctuary = LGT:UnitHasTalent(name, (GetSpellInfo(20911)))
		pala.improvedWisdom = LGT:UnitHasTalent(name, (GetSpellInfo(20245)))
		pala.improvedMight = LGT:UnitHasTalent(name, (GetSpellInfo(20045)))
		pala.improvedDevotion = LGT:UnitHasTalent(name, (GetSpellInfo(20140)))
		pala.improvedConcentration = LGT:UnitHasTalent(name, (GetSpellInfo(20254)))
		pala.improvedRetribution = LGT:UnitHasTalent(name, (GetSpellInfo(31869)))
		pala.spec = {s1, s2, s3}
		pala.gotCapabilities = true
		pala.canEdit = true
	end
	local ver = ZOMGBuffs.versionRoster and ZOMGBuffs.versionRoster[name]
	if (type(ver) == "number") then
		if (not pala.spec) then
			z:SendComm(name, "REQUESTCAPABILITY", nil)
			if (pala.canEdit == nil) then
				pala.canEdit = false
			end
		end
		if (not pala.template or not next(pala.template)) then
			z:SendComm(name, "REQUESTTEMPLATE", nil)
		end
	end
end

-- AssignPaladins
-- Create a self.pala list
-- Each entry contains the row number for display, and their part of the template
function man:AssignPaladins()
	local names, oldNames = {}, {}
	local groups = self.db.profile.groups
	for unit, name, class, subgroup, index in z:IterateRoster() do
		if (class == "PALADIN" and subgroup <= groups) then
			tinsert(names, name)
		end
	end
	sort(names)

	if (not self.pala) then
		self.pala = {}
	else
		for palaName,info in pairs(self.pala) do
			oldNames[palaName] = true
		end
	end

	-- Make unique initials for the paladins we have
	-- If first two letters match something we already
	-- have, then take first and last, then try first
	-- plus each letter thru name until unique one found
	local temp = new()
	for i,name in ipairs(names) do
		local n = name:utf8sub(1, 2)
		if (temp[n]) then
			n = name:utf8sub(1,1) .. name:utf8sub(-1, -1)
			if (temp[n]) then
				for i = 3,name:utf8len(name) - 1 do
					n = name:utf8sub(1,1) .. name:utf8sub(i, i)
					if (not temp[n]) then
						break
					end
				end
			end
		end
		temp[n] = name
	end
	local initials = new()
	for ini,ori in pairs(temp) do
		initials[ori] = ini
	end
	del(temp)

	del(self.paladinOrder)
	self.paladinOrder = names

	for k,name in ipairs(names) do
		oldNames[name] = nil
		if (self.pala[name]) then
			self.pala[name].row = k
		else
			self.pala[name] = {
				row = k,
				template = {}
			}
		end
		local pala = self.pala[name]
		pala.initials = initials[name]

		if (not UnitIsConnected(name)) then
			pala.offline = true
		else
			self:ReadPaladinSpec(pala, name)

			local ver = ZOMGBuffs.versionRoster and ZOMGBuffs.versionRoster[name]
			if (type(ver) == "string" and strfind(ver, "PallyPower")) then
				pala.gotCapabilities = true
				pala.canEdit = true
				if (ZOMGBlessingsPP) then
					if (not pala.template or not next(pala.template)) then
						ZOMGBlessingsPP:Announce()
					end
				end
			elseif (not ver) then
				self.coveringHellos = self.coveringHellos or new()
				if ((self.coveringHellos[name] or 0) < GetTime() - 60) then
					self.coveringHellos[name] = GetTime()

					-- Cover occasional times when the pala misses the hello, and doesn't send one
					z:SendComm(name, "HELLO", z.version)
				end
			end
		end
	end
	self.paladins = #names
	
	for name in pairs(oldNames) do
		del(self.pala[name])
		self.pala[name] = nil
	end

	ZOMGBuffs:DrawGroupNumbers()			-- Update the names on paladin columns

	del(initials)
	del(oldNames)
	
	if (self.replyQueue and next(self.replyQueue)) then
		for name,msg in pairs(self.replyQueue) do
			self:BuffResponse(name, msg)
		end
		self.replyQueue = nil
	end
end

-- OnReceiveTemplate
-- A paladin has changed their template, so we receive that and update it into our display
function man:OnReceiveTemplate(sender, template, modified)
	-- Paladin changed their template, so we'll reflect this in the manager

	local pala = self.pala and self.pala[sender]
	if (pala) then
		pala.template = copy(template) or {}
		pala.template.modified = nil

		local def = pala.template.default
		pala.template.default = nil
		if (def) then
			for k,v in pairs(classOrder) do
				if (not pala.template[v]) then
					pala.template[v] = def
				end
			end
		end

		pala.modified = modified and true		-- Flagged when a paladin changes their own template
		pala.canEdit = true
		if (self.frame and self.frame:IsOpen()) then
			self:DrawAll()
		end
	end
end

-- OnReceiveTemplate
-- A paladin has changed their template, so we receive that and update it into our display
function man:OnReceiveAura(sender, aura)
	-- Paladin changed their aura, so we'll reflect this in the manager
	local pala = self.pala and self.pala[sender]
	if (pala) then
		assert(aura == nil or z.auraIndex[aura])
		pala.aura = aura
		if (self.frame and self.frame:IsOpen()) then
			self:DrawAll()
		end
	end
end

-- OnReceiveMasterTemplate
function man:OnReceiveMasterTemplate(sender, newTemplate)
	local i = 1
	local templates = self.db.profile.templates
	local name
	while true do
		name = format("Received_%03d", i)
		if (not templates[name]) then
			break
		end
		i = i + 1
	end

	if (name) then
		newTemplate.modified = nil
		templates[name] = copy(newTemplate)
		self:MakeTemplateOptions()

		self:Print(L["Blessings Manager master template received from %s. Stored in local templates as |cFFFFFF80%s|r"], z:ColourUnitByName(sender), name)
	end
end

-- OnReceiveSubClassDefinitions
function man:OnReceiveSubClassDefinitions(sender, playerCodes)
	local codes = self.db.profile.playerCodes
	if (not codes) then
		self.db.profile.playerCodes = copy(playerCodes)
	else
		for class,list in pairs(playerCodes) do
			for name,code in pairs(list) do
				if (not codes[class]) then
					codes[class] = {}
				end
				codes[class][name] = code
			end
		end
	end
	self:Print(L["Player sub-class assignments received from %s"], z:ColourUnitByName(sender))
end

-- OnReceiveSymbolCount
function man:OnReceiveSymbolCount(sender, count)
	local pala = self.pala and self.pala[sender]
	if (pala) then
		pala.symbols = count
		self:DrawPaladinByName(sender)
	end
end

-- ClearCells
function man:ClearCells()
	for k,v in pairs(self.pala) do
		v.template = {}
	end
end

-- Generate
function man:Generate()
	if (self.canEdit) then
		self.whoGenerated, self.whenGenerated = UnitName("player"), time()
		self:AssignTemplateToPaladins()
		self:AssignAurasToPaladins()
		self:BroadcastTemplates()
		self:DrawAll()

		z:Log("man", nil, "gen")
	end
end

-- GetCodeIndex
function man:GetCodeIndex(class, code)
	local splits = self.classSplits[class]
	if (splits) then
		for i,info in ipairs(splits) do
			if (info.code == code) then
				return i
			end
		end
	end
end

-- GetSplitClassCounts
function man:GetSplitClassCounts()
	local ret = new()
	local codes = self.db.profile.playerCodes

	for unit, name, class, subgroup, index in z:IterateRoster() do
		if (subgroup <= self.db.profile.groups) then
			local code = codes and codes[class] and codes[class][name]

			if (not ret[class]) then
				local splits = self.classSplits[class]
				if (splits and #splits > 0) then
					ret[class] = new()
					for i = 1,#splits do
						tinsert(ret[class], 0)
					end
				else
					ret[class] = new(0)
				end
			end
			local c = ret[class]

			if (code) then
				local codeIndex = self:GetCodeIndex(class, code)
				if (not codeIndex) then
					self:Print("%s has code '%s', but there is not code definitions for his class", z:ColourUnitByName(name), code)
					c[1] = c[1] + 1
				else
					c[codeIndex] = (c[codeIndex] or 0) + 1
				end
			else
				c[1] = c[1] + 1
			end
		end
	end

	return ret
end

-- FillNFromList
function man:FillNFromList(dest, source, n, kingList, sancList, needBOL)
	if (dest and source) then
		local got, i = 0, 1

		local copyKings = copy(kingList)
		local copySanc = copy(sancList)
		
		while (got < n) do
			local Type = source[i]
			if (Type) then
				--if ((Type == "BOK" and canK) or (Type == "SAN" and canS) or (Type ~= "BOK" and Type ~= "SAN")) then
				local ok
				if (Type == "BOK" or Type == "SAN") then
					-- We need to see if we have enough people to do kings + sanc if it's required,
					-- else exclude the second priority buff if not
					-- This covers occasions like having 2 palas, only 1 can do Kings+Sanc, and both buffs are wanted.
					local countK, countS = 0, 0
					local firstK, firstS
					for name in pairs(copyKings) do
						firstK = name
						countK = countK + 1
					end
					for name in pairs(copySanc) do
						firstS = name
						countS = countS + 1
					end
					if (countK == 1 and countS == 1) then
						if (firstK == firstS) then
							-- We have 1 paladin that can do Kings and Sanc, so we'll lose one of the buffs
							if (Type == "BOK") then
								if (copySanc[firstK]) then
									copySanc[firstK] = nil
									countS = countS - 1
								end
							else
								if (copyKings[firstS]) then
									copyKings[firstS] = nil
									countK = countK - 1
								end
							end
						end
					end

					if ((Type == "BOK" and countK > 0) or (Type == "SAN" and countS > 0)) then
						ok = true
					end
				elseif (Type == "BOL") then
					if (needBOL) then
						ok = true
					else
						if (not self.bolWarned) then
							self.bolWarned = true
							self:Print(L["%s skipped because no %s present"], z:ColourBlessing("BOL"), z:ColourClass("PALADIN", L["Holy"]))
						end
					end
				else
					ok = true
				end

				if (ok) then
					got = got + 1
					dest[Type] = got
				end
			else
				break
			end
			i = i + 1
		end
		
		del(copyKings)
		del(copySanc)
	end
end

-- CanKingsCanSanc
function man:CanKingsCanSanc()
	local canK, canS, kingList, sancList
	kingList = new()
	sancList = new()
	for k,v in pairs(self.pala) do
		canK = true
		kingList[k] = true
		if (v.canSanctuary) then
			canS = true
			sancList[k] = true
		end
	end

	return canK, canS, kingList, sancList
end

-- GetPopularSubClass
function man:GetPopularSubClass(class, scc)
	local popularSubClass = 1
	local counts = scc[class]			-- Work out which sub-class is the most popular.
	if (counts) then					-- Note that this is the most popular from who is currently in the raid
		local max = 0					-- and this may well change if other people from other sub-classes join
		for i,num in ipairs(counts) do	-- the raid later. This is a minor issue we can discard.
			if (num > max) then			-- The only problem will be if the most popular is not the first type
				popularSubClass = i		-- and members join later who are of first type, who would have needed exceptions
				max = num
			end
		end
	end
	
	return popularSubClass
end

-- GetRelavantTemplatePart
function man:GetRelavantTemplatePart()
	-- For the split version, we check which is the most common sub-class per class, and make that the group blessing
	-- Then create on-the-fly exceptions for all the less populated sub-classes
	if (not template) then
		return
	end

	self.bolWarned = nil
	local scc = self:GetSplitClassCounts()
	local needBOL = scc.PALADIN and scc.PALADIN[1] > 0
	local p = self.paladins
	local canK, canS, kingList, sancList = self:CanKingsCanSanc()
	local ret = new()
	
	for classNo,class in ipairs(classOrder) do
		local index = self:GetPopularSubClass(class, scc)

		if (not ret[class]) then
			ret[class] = new()
		end

		if (index > 1) then
			local subclassList = self.db.profile.templates.current.subclass
			if (subclassList) then
				local subclass = subclassList[class]
				if (subclass) then
					-- subclass will contain a list if codes, with attached buff definitions
					local splits = self.classSplits[class]
					if (splits) then
						local code = splits[index].code
						self:FillNFromList(ret[class], subclass[code], p, kingList, sancList, needBOL)
					else
						error("Wanted codes for %s, but they don't exist in self.classSplits", class)
					end
				else
					index = 1	-- No alternatives defined for this class
				end
			else
				index = 1		-- No alternatives defined for this class
			end
		end

		if (index == 1) then
			self:FillNFromList(ret[class], template[class], p, kingList, sancList, needBOL)
		end
		self.bolWarned = nil

		-- Build exceptions for this class based on which subclasses we have
		local codes = self.db.profile.playerCodes
		if (codes and self.classSplits and self.classSplits[class]) then
			local e = ret.exceptions
			if (not e) then
				e = new()
				ret.exceptions = e
			end

			local groupBuffCode
			if (index > 1) then
				groupBuffCode = self.classSplits[class][index].code
			else
				groupBuffCode = " "
			end

			local codeIndex = new()
			for i = 1,#self.classSplits[class] do
				codeIndex[self.classSplits[class][i].code or " "] = i
			end

			-- We need all codes, even ones in sub-class 1, which are implied by their absence
			local c = codes[class]
			local tempCodes = (c and copy(c)) or new()
			for unit, unitname, unitclass, subgroup, index in z:IterateRoster() do
				if (unitclass == class) then
					if (not tempCodes[unitname]) then
						tempCodes[unitname] = " "
					end
				end
			end

			-- Insert any players from subclass types (whether in raid or not)
			for name,code in pairs(tempCodes) do
				if (code ~= groupBuffCode) then
					if (not e[class]) then
						e[class] = new()
					end
					local ind = codeIndex[code or " "]

					local source
					if (ind == 1 or not template.subclass or not template.subclass[class]) then
						source = template[class]
					else
						source = template.subclass[class][code]
					end
					if (source) then
						local got, i = 0, 1
						while (got < p) do
							local Type = source[i]
							if (Type) then
								if ((Type == "BOK" and canK) or (Type == "SAN" and canS) or (Type ~= "BOK" and Type ~= "SAN")) then
									got = got + 1
									if (not e[class][got]) then
										e[class][got] = new()
									end
									e[class][got][name] = Type
								end
							else
								break
							end
							i = i + 1
						end
					end
				end
			end

			del(tempCodes)
			del(codeIndex)
		end
	end

	del(kingList)
	del(sancList)
	deepDel(scc)

	if (ret.exceptions and not next(ret.exceptions)) then
		ret.exceptions = del(ret.exceptions)
	end

	return ret
end

-- DupRow
function man:DupRow(small, pala, class, buff)
	-- Here we'll now put the same buff for the same paladin wherever possible
	-- merely to make it look clearer in the manager, and so people can easier
	-- identify which pala does which buffs
	for class,list in pairs(small) do
		if (not pala.template[class]) then
			if (list[buff]) then
				pala.template[class] = buff
				list[buff] = nil
			end
		end
	end
end

-- SyncGroupCount
function man:SyncGroupCount()
	z:SendCommMessage("GROUP", "SYNCGROUPS", self.db.profile.groups)
end

-- AssignTemplateToPaladins
-- TODO - Recode all of this, it still relies on legacy code from early
-- alphas that had per player exception setup in main template
function man:AssignTemplateToPaladins()
	local p = self.paladins
	if (p == 0) then
		return
	end

	self:SyncGroupCount()
	if (z.db.profile.info) then
		self:Print(L["Generating Blessing Assignments for groups 1 to %d"], self.db.profile.groups)
	end
	
	local kingCount, sancCount = 0, 0
	local canKings = new()
	local canSanctuary = new()
	local palaList = new()
	for k,pala in pairs(self.pala) do
		kingCount = kingCount + 1
		canKings[k] = true
		if (pala.canSanctuary) then
			sancCount = sancCount + 1
			canSanctuary[k] = true
		end
		tinsert(palaList, k)
	end
	sort(palaList)

	if (#palaList == 0) then
		-- Nothing to do
		del(palaList)
		del(canKings)
		del(canSanctuary)
		return
	end

	self:ClearCells()
	local small = self:GetRelavantTemplatePart()
	local smallCopy = copy(small)

	local function HowManyMoreCanDo(buff, startPala)
		local count = 0
		for i = startPala,#palaList do
			local pala = self.pala[palaList[i]]

			if (buff == "BOK") then
				count = count + 1

			elseif (buff == "SAN") then
				if (pala.canSanctuary) then
					count = count + 1
				end
			end
		end
		return count
	end
	
	-- First pass will assign certain blessings to paladins based on talent spec (kings, sanctuary, imp wisdom, imp might)
	for i,palaName in ipairs(palaList) do
		local pala = self.pala[palaName]
		pala.template = {}

		for class,list in pairs(small) do
			if (pala.canSanctuary and list.SAN and (sancCount == 1 or not pala.canKings or kingCount > 1 or not list.BOK)) then
				list.SAN = nil
				pala.template[class] = "SAN"
			elseif (pala.canKings and list.BOK and (kingCount == 1 or (HowManyMoreCanDo("BOK", i + 1) == 0 or ((not list.BOM or pala.improvedMight == 0) and (not list.BOW or pala.improvedWisdom == 0))))) then
				list.BOK = nil
				pala.template[class] = "BOK"
			elseif ((kingCount > 1 or not pala.canKings or not list.BOK) and (sancCount > 1 or not pala.canSanctuary or not list.SAN)) then
				if ((pala.improvedMight or 0) > 0 and list.BOM) then
					list.BOM = nil
					pala.template[class] = "BOM"
				elseif ((pala.improvedWisdom or 0) > 0 and list.BOW) then
					list.BOW = nil
					pala.template[class] = "BOW"
				end
			end
		end

		if (pala.canKings and canKings[palaName]) then
			canKings[palaName] = nil
			kingCount = kingCount - 1
		end
		if (pala.canSanctuary and canSanctuary[palaName]) then
			canSanctuary[palaName] = nil
			sancCount = sancCount - 1
		end
	end

	-- Second pass to do improved wisdom and might that we missed first time
	for i,palaName in ipairs(palaList) do
		local pala = self.pala[palaName]
		pala.canEdit = true

		for class,list in pairs(small) do
			if (not pala.template[class]) then
				if ((pala.improvedMight or 0) > 0 and list.BOM) then
					list.BOM = nil
					pala.template[class] = "BOM"
					self:DupRow(small, pala, class, "BOM")
				elseif ((pala.improvedWisdom or 0) > 0 and list.BOW) then
					list.BOW = nil
					pala.template[class] = "BOW"
					self:DupRow(small, pala, class, "BOW")
				end
			end
		end
	end

	-- Third pass to give out the remaining ones
	for j,class in ipairs(classOrder) do
		for i,palaName in ipairs(palaList) do
			local pala = self.pala[palaName]
			if (not pala.template[class]) then
				local list = small[class]
				local canK, canS, impM, impW = pala.canKings, pala.canSanctuary, pala.improvedMight, pala.improvedWisdom
				for buff in pairs(list) do
					if ((buff == "BOK" and canK) or (buff == "SAN" and canS) or (buff ~= "BOK" and buff ~= "SAN")) then
						pala.template[class] = buff
						list[buff] = nil
						self:DupRow(small, pala, class, buff)
						break
					end
				end
			end
		end
	end

	deepDel(small)					-- Should be empty anyway

	-- Now, we'll go through any single exceptions
	-- A lot of this involves comparing the desired buffs with the wanted exceptions.
	-- In the case of re-ordered buffs that would ultimately end up being the same, we can just skip the exceptions.
	-- ie: We have 2 paladins and the template for paladins says BOW, BOS and one paladin is defined as BOS, BOW
	--	then we just skip the exceptions because the result is the same
	small = smallCopy
	local e = (split and small.exceptions) or template.exceptions
	if (e) then
		--self:Print("Exceptions")
		for class,list in pairs(e) do
			--self:Print("- "..class)

			-- Build a list of all players with exceptions for this class, we only want to do each player once
			local playerList = new()
			for row,players in pairs(list) do
				for name,Type in pairs(players) do
					playerList[name] = true
				end
			end

			local swapList

			for playerName in pairs(playerList) do
				--self:Print("--  "..z:ColourUnitByName(playerName))

				-- Build a list of what this player wants as buffs
				local wants = new()
				local dontReplace = new()
				for row = 1,p do
					-- Buff type to be replaced by this exception
					local buff = (list[row] and list[row][playerName]) or (small[row] and small[row][class])
					if (buff) then
						--self:Print("--- wants "..z:ColourBlessing(buff))
						wants[buff] = true
					end
				end

				-- Now delete any that they're already going to get as class buffs
				for buff2 in pairs(small[class]) do
					if (wants[buff2]) then
						--self:Print("---- Already getting: "..z:ColourBlessing(buff2))
						wants[buff2] = nil
						dontReplace[buff2] = true
					end
				end

				-- First pass will assign BOK and SAN where needed
				for i,palaName in ipairs(palaList) do
					local pala = self.pala[palaName]
					local thisPalasBuff = pala.template[class]

					if (not dontReplace[thisPalasBuff]) then
						if (pala.canKings and wants.BOK) then
							wants.BOK = nil
							pala.template[playerName] = "BOK"
						elseif (pala.canSanctuary and wants.SAN) then
							wants.SAN = nil
							pala.template[playerName] = "SAN"
						end
					end
				end

				-- Second pass to give out Imp Might/Wis where possible to appropriate paladins
				for i,palaName in ipairs(palaList) do
					local pala = self.pala[palaName]
					if (not pala.template[playerName]) then
						local thisPalasBuff = pala.template[class]

						if (not dontReplace[thisPalasBuff]) then
							if ((pala.improvedMight or 0) > 0 and wants.BOM) then
								wants.BOM = nil
								pala.template[playerName] = "BOM"
							elseif ((pala.improvedWisdom or 0) > 0 and wants.BOW) then
								wants.BOW = nil
								pala.template[playerName] = "BOW"
							end
						end
					end
				end

				-- Finally, go through what's left and fill them in
				for i,palaName in ipairs(palaList) do
					local pala = self.pala[palaName]
					if (not pala.template[playerName]) then
						local thisPalasBuff = pala.template[class]

						if (not dontReplace[thisPalasBuff]) then
							for buff in pairs(wants) do
								if ((buff == "BOK" and pala.canKings) or (buff == "SAN" and pala.canSanctuary) or (buff ~= "BOK" and buff ~= "SAN")) then
									--self:Print("        Assigned "..z:ColourBlessing(buff).." to Paladin "..z:ColourUnitByName(palaName))
									pala.template[playerName] = buff
									wants[buff] = nil
									break
								end
							end
						end
					end
				end

				if (next(wants)) then
					for buff in pairs(wants) do
					--self:Print("Didn't match %s's %s on first pass", z:ColourUnitByName(playerName), z:ColourBlessing(buff))
						if (buff == "BOK" or buff == "SAN") then
							for i,palaName in ipairs(palaList) do
								local pala = self.pala[palaName]
								local thisPalasBuff = pala.template[class]
								local changed
					--z.PrintLiteral(self, "dontReplace", dontReplace, "thisPalasBuff", thisPalasBuff, "buff", buff)

								if ((buff == "BOK" and pala.canKings) or (buff == "SAN" and pala.canSanctuary)) then
									-- Reallocate previously assigned buff to match up with exception

					--self:Print(" Want to reallocate %s's %s to %s who is currently doing %s as main buff", z:ColourUnitByName(playerName), z:ColourBlessing(buff), z:ColourUnitByName(palaName), z:ColourBlessing(thisPalasBuff))

									-- First see if we can simply re-allocate the current exceptions without breaking any previously assigned ones
									for j,palaName2 in ipairs(palaList) do
										local pala2 = self.pala[palaName2]

										if (pala2 ~= pala and pala2.template[class] and not dontReplace[pala2.template[class]]) then
											if ((thisPalasBuff == "BOK" and pala2.canKings) or (thisPalasBuff == "SAN" and pala2.canSanctuary) or (thisPalasBuff ~= "BOK" and thisPalasBuff ~= "SAN")) then
					--self:Print("  Potential target: %s", z:ColourUnitByName(palaName2))
												local fail
												if (pala2.template.exceptions) then
													-- See if the new target paladin can do the exceptions already given to old paladin
													for exName,exBuff in pairs(pala2.template.exceptions) do
														if ((exBuff == "BOK" and not pala2.canKings) or (exBuff == "SAN" and not pala2.canSanctuary)) then
															if (exBuff == "BOK" and not pala2.canKings) then
																fail = z:ColourUnitByName(palaName2).." can't do BOK"
															else
																fail = z:ColourUnitByName(palaName2).." can't do SANCTUARY"
															end
															break
														end
													end
												end

												if (not fail) then
													if (swapList and swapList[palaName] and swapList[palaName][class]) then
					--self:Print("  Already swapped buffs for %s and %s", z:ColourUnitByName(palaName), z:ColourUnitByName(palaName2))
													else
					--self:Print("  Swapping main buffs for %s and %s", z:ColourUnitByName(palaName), z:ColourUnitByName(palaName2))
														pala.template[class] = pala2.template[class]
														pala2.template[class] = thisPalasBuff
														if (not swapList) then
															swapList = new()
														end
														if (not swapList[palaName]) then
															swapList[palaName] = new()
														end
														swapList[palaName][class] = true

					--self:Print("  Swapping exceptions %s and %s", z:ColourUnitByName(palaName), z:ColourUnitByName(palaName2))
														if (pala.template or pala2.template) then
															local temp = new()
															if (pala2.template) then
																for exName, exBuff in pairs(pala2.template) do
																	if (exName == playerName) then
					--self:Print("1: Re-Added want of %s for %s", exBuff, playerName)
																		wants[exBuff] = true
																		pala2.template[exName] = nil
																	else
																		local c = self:GetClassFromCodesList(exName)
																		if (c == class or (unit and select(2,UnitClass(exName)) == class)) then
					--self:Print("  Moving %s's exception for %s from %s to temp", z:ColourUnitByName(exName), z:ColourBlessing(exBuff), z:ColourUnitByName(palaName2))
																			temp[exName] = exBuff
																			pala2.template[exName] = nil
																		end
																	end
																end
															end
															if (pala.template) then
																for exName, exBuff in pairs(pala.template) do
																	if (exName == playerName) then
					--self:Print("2: Re-Added want of %s for %s", exBuff, playerName)
																		wants[exBuff] = true
																		pala.template[exName] = nil
																	else
																		local c = self:GetClassFromCodesList(exName)
																		if (c == class or (unit and select(2,UnitClass(exName)) == class)) then
					--self:Print("  Moving %s's exception for %s from %s to %s", z:ColourUnitByName(exName), z:ColourBlessing(exBuff), z:ColourUnitByName(palaName), z:ColourUnitByName(palaName2))
																			if (not pala2.template) then
																				pala2.template = new()
																			end
																			pala2.template[exName] = exBuff
																			pala.template[exName] = nil
																		end
																	end
																end
															end
															for exName, exBuff in pairs(temp) do
																local c = self:GetClassFromCodesList(exName)
																if (c == class or (unit and select(2,UnitClass(exName)) == class)) then
					--self:Print("  Moving %s's exception for %s from temp to %s", z:ColourUnitByName(exName), z:ColourBlessing(exBuff), z:ColourUnitByName(palaName))
																	if (not pala.template) then
																		pala.template = new()
																	end
																	pala.template[exName] = exBuff
																end
															end
														end
													end

													if (pala.template[playerName]) then
														-- New want, because it's just been replaced in the swap
														wants[pala.template[playerName]] = true
					--self:Print("3: Re-Added want of %s for %s", pala.template[playerName], playerName)
													end
													pala.template[playerName] = buff
													wants[buff] = nil

													changed = true
													break
					--else
					--self:Print("   Potential failed because %s", fail)
												end
											end
										end
									end
								end
								if (changed) then
									break
								end
							end
						end
					end

					if (next(wants)) then
						-- Now go through what we need and make assignments
						for i,palaName in ipairs(palaList) do
							local pala = self.pala[palaName]
							local thisPalasBuff = pala.template[class]

							if (not dontReplace[thisPalasBuff] and not pala.template[playerName]) then
								for buff in pairs(wants) do
									if ((buff == "BOK" and pala.canKings) or (buff == "SAN" and pala.canSanctuary) or (buff ~= "BOK" and buff ~= "SAN")) then
										pala.template[playerName] = buff
										wants[buff] = nil
										break
									end
								end
							end
						end

						-- Something left over because an exception tried to end up on a pala who can't cast it
						if (UnitInParty(playerName) or UnitInRaid(playerName)) then
							for buff in pairs(wants) do
								self:Print("|cffff8080WARNING|r Didn't allocate %s to %s", z:ColourBlessing(buff), z:ColourUnitByName(playerName))
							end
						end
					end
				end

				del(wants)
				del(dontReplace)
			end

			del(playerList)
			deepDel(swapList)
		end
	end

	deepDel(small)
	del(palaList)
	del(canKings)
	del(canSanctuary)
end

-- AssignAurasToPaladins
function man:AssignAurasToPaladins()
	local p = self.paladins
	if (p == 0 or not template.AURA) then
		return
	end

	local palaList = new()
	for k,pala in pairs(self.pala) do
		pala.aura = nil
		tinsert(palaList, k)
	end
	sort(palaList)

	local wants = new()
	for i = 1,self.paladins do
		local key = template.AURA[i]
		wants[key] = true
	end

	-- Score the paladins abilities
	local scores = new()
	for i,palaName in ipairs(palaList) do
		local pala = self.pala[palaName]
		local score = 0
		if (pala.improvedDevotion and wants.DEVOTION) then
			score = score + 1
		end
		if (pala.improvedConcentration and wants.CONCENTRATION) then
			score = score + 1
		end
		if (pala.improvedRetribution and wants.RETRIBUTION) then
			score = score + 1
		end
		tinsert(scores, format("%d,%s", score, palaName))
	end
	sort(scores)

	-- Now iterate from worst to best assigning any non-talent dependant auras
	local list = new("SHADOW", "FROST", "FIRE", "CRUSADER")
	for i,combo in ipairs(scores) do
		local score, palaName = strsplit(",", combo)
		local pala = self.pala[palaName]
		assert(pala)

		for j,key in ipairs(list) do
			if (wants[key]) then
				wants[key] = nil
				pala.aura = key
			end
		end
	end
	del(list)

	-- Now iterate from worst to best assigning the talent dependant auras we have remaining
	for i,combo in ipairs(scores) do
		local score, palaName = strsplit(",", combo)
		local pala = self.pala[palaName]
		assert(pala)

		if (wants.DEVOTION and pala.improvedDevotion) then
			pala.aura = "DEVOTION"
			wants.DEVOTION = nil

		elseif (wants.CONCENTRATION and pala.improvedConcentration) then
			pala.aura = "CONCENTRATION"
			wants.CONCENTRATION = nil

		elseif (wants.RETRIBUTION and pala.improvedRetribution) then
			pala.aura = "RETRIBUTION"
			wants.RETRIBUTION = nil
		end
	end

	-- Finally, re-assign best auras again to any paladins left over without an assignment. Overlaps are fine
	local cycle = 1
	local list = new("DEVOTION", "CONCENTRATION", "RETRIBUTION")
	for palaName,pala in pairs(self.pala) do
		if (not pala.aura) then
			pala.aura = list[cycle]
			cycle = cycle + 1
			if (cycle > #list) then
				cycle = 1
			end
		end
	end
	del(list)

	del(palaList)
	del(wants)
	del(scores)
end

-- GetClassFromCodesList
function man:GetClassFromCodesList(find)
	for class,list in pairs(self.db.profile.playerCodes) do
		for name,code in pairs(list) do
			if (name == find) then
				return class
			end
		end
	end
end

-- BroadcastTemplatePart
function man:BroadcastTemplatePart(name, class, Type)
	if (playerClass == "PALADIN" or IsRaidLeader() or IsRaidOfficer()) then
		if (ZOMGBlessingsPP) then
			ZOMGBlessingsPP:GiveTemplatePart(name, class, Type)
		end
		z:SendCommMessage("GROUP", "GIVETEMPLATEPART", name, class, Type)
		if (name == playerName) then
			man:OnReceiveBroadcastTemplatePart(name, name, class, Type)

			ZOMGBlessings:ModifyTemplate(class, Type)
		end
	end
end

-- BroadcastTemplateAura
function man:BroadcastTemplateAura(name, Type)
	if (playerClass == "PALADIN" or IsRaidLeader() or IsRaidOfficer()) then
		assert(Type == nil or z.auras[Type])
		if (ZOMGBlessingsPP) then
			ZOMGBlessingsPP:GiveTemplateAura(name, Type)
		end
		z:SendCommMessage("GROUP", "GIVEAURA", name, Type)
		if (name == playerName and ZOMGSelfBuffs) then
			ZOMGSelfBuffs:SetPaladinAuraKey(Type)
		end
	end
end

-- OnReceiveBroadcastTemplatePart
function man:OnReceiveBroadcastTemplatePart(sender, name, class, buff)
--[===[@debug@
	self:argCheck(sender, 1, "string")
	self:argCheck(name, 2, "string")
	self:argCheck(class, 3, "string")
	self:argCheck(buff, 4, "string", "nil")
--@end-debug@]===]
	if (select(2,UnitClass(sender)) == "PALADIN" or z:UnitRank(sender) > 0 or (sender == name)) then
		local pala = self.pala[name]
		if (pala) then
			pala.template[class] = buff
			self:DrawIconsByName(name)
			if (name == playerName) then
				ZOMGBlessings:ModifyTemplate(class, buff)
			end
		end
	end
end

-- OnReceiveBroadcastAura
function man:OnReceiveBroadcastAura(sender, name, aura)
--[===[@debug@
	self:argCheck(sender, 1, "string")
	self:argCheck(name, 2, "string")
	self:argCheck(buff, 3, "string", "nil")
--@end-debug@]===]

	if (select(2,UnitClass(sender)) == "PALADIN" or z:UnitRank(sender) > 0 or (sender == name)) then
		local pala = self.pala[name]
		if (pala) then
			pala.aura = aura
			self:DrawIconsByName(name)
			if (name == playerName) then
				if (ZOMGSelfBuffs) then
					ZOMGSelfBuffs:SetPaladinAuraKey(aura)
				end
			end
		end
	end
end

-- OnReceiveTemplatePart
-- PallyPower support only
function man:OnReceiveTemplatePart(sender, name, classOrName, spell)
--[===[@debug@
	self:argCheck(sender, 1, "string")
	self:argCheck(name, 2, "string")
	self:argCheck(classOrName, 3, "string")
	self:argCheck(spell, 4, "string", "nil")
--@end-debug@]===]
	if (select(2,UnitClass(sender)) == "PALADIN" or z:UnitRank(sender) > 0 or (sender == name)) then
		local pala = self.pala and self.pala[name]
		if (pala) then
			pala.template[classOrName] = spell
			if (self.frame and self.frame:IsOpen()) then
				self:DrawAll()
			end

			if (name == playerName) then
				ZOMGBlessings:ModifyTemplate(classOrName, spell)
			end
		end
	end
end

-- GiveTemplate
function man:GiveTemplate(name, quiet, playerRequested, retry)
	if (playerClass == "PALADIN" or IsRaidLeader() or IsRaidOfficer()) then
		local pala = self.pala[name]
		if (pala) then
			if (ZOMGBlessingsPP) then
				-- PallyPower assignments are broadcast over the RAID/PARTY addon channels, instead of via whisper, so always send them
				ZOMGBlessingsPP:GiveTemplate(name, pala.template)
			end

			if (UnitIsConnected(name)) then
				local v = z.versionRoster[name]
				if (v) then
					if (type(v) ~= "string" and not strfind(v, "PallyPower")) then
						if (select(2, UnitClass(name)) == "PALADIN") then
							z:SendComm(name, "GIVETEMPLATE", pala.template, quiet, playerRequested, retry)
							z:SendComm(name, "GIVEAURA", name, pala.aura)
							pala.waitingForAck = GetTime()
							self:DrawPaladinByName(name)
						end
					end
				elseif (self.db.profile.whispers) then
					-- They don't have the mod, so ask them to do this instead
					SendChatMessage(format(L["%s %s, Please use these buff settings:"], z.chatAnswer, name), "WHISPER", nil, name)

					for i,Type in ipairs(blessingCycle) do
						local str
						for j,class in ipairs(classOrder) do
							if (pala.template[class] == Type) then
								if (str) then
									str = str..", "..class
								else
									str = format("%s %s : %s", z.chatAnswer, z:GetBlessingFromType(Type), class)
								end
							end
						end
						if (str) then
							SendChatMessage(str, "WHISPER", nil, name)
						end
					end

					local ex

					for k,v in pairs(pala.template) do
						if (k ~= "modified" and k ~= "state" and not classIndex[k]) then
							if (UnitInRaid(k)) then
								if (not ex) then
									ex = new()
								end
								if (ex[v]) then
									tinsert(ex[v], k)
								else
									ex[v] = new(k)
								end
							end
						end
					end

					if (ex) then
						SendChatMessage(format(L["%s And these single buffs afterwards:"], z.chatAnswer), "WHISPER", nil, name)

						for k,v in pairs(ex) do
							SendChatMessage(format("%s %s : %s", z.chatAnswer, z:GetBlessingFromType(k), table.concat(v, ", ")), "WHISPER", nil, name)
						end

						deepDel(ex)
					end
				end
			elseif (z.db.profile.info) then
				self:Print(L["%s is offline, template not sent"], z:ColourUnitByName(name))
			end
		end
	end
end

-- GiveAllTemplates
function man:GiveAllTemplates()
	if (ZOMGBlessingsPP) then
		ZOMGBlessingsPP:SignalClear()
	end
	for name in pairs(self.pala) do
		self:GiveTemplate(name)
	end
end

do
	local function onButtonClick(self)
		self.func(man)
	end
	local function onButtonEnter(self)
		if (self.tooltipText) then
			GameTooltip:SetOwner(self, "ANCHOR_LEFT")
			GameTooltip:SetText(self:GetText(), 1, 1, 1)
			GameTooltip:AddLine(self.tooltipText, nil, nil, nil, 1)
			GameTooltip:Show()
		end
	end
	local function onButtonLeave(self)
		GameTooltip:Hide()
	end

	-- MakeButton
	function man:MakeButton(parent, text, tooltip, func)
		local b = CreateFrame("Button", nil, parent, "OptionsButtonTemplate")
		b:GetRegions():SetAllPoints(b)			-- Makes the text part (first region) fit all over button, instead of just centered and fuxed when scaled
		b.func = func
		b:SetScript("OnClick", onButtonClick)
		b:SetScript("OnEnter", onButtonEnter)
		b:SetScript("OnLeave", onButtonLeave)
		b:SetText(text)
		b.tooltipText = tooltip
		b:SetWidth(max(80, b:GetRegions():GetStringWidth() + 25))
		return b
	end
end

-- TalentsMissingFromSelectedGroups
function man:TalentsMissingFromSelectedGroups()
	local names = LGT:GetTalentMissingNames()
	if (names) then
		local temp = new(strsplit(",", names))
		local list = new()
		for i,name in pairs(temp) do
			list[name] = true
		end
		del(temp)

		for unit, unitname, unitclass, subgroup, index in z:IterateRoster() do
			if (subgroup > self.db.profile.groups) then
				list[unitname] = nil
			end
		end

		local ret = next(list) ~= nil
		del(list)
		return ret
	end
end

-- CreateMainMainFrame
function man:CreateMainMainFrame()
	if (not ZFrame) then
		ZFrame = LibStub("ZFrame-1.0")
	end
	local main = ZFrame:Create(self, L["TITLE"], "ZOMGBMFrame", 1, 0.5, 0.1)
	self.frame = main

	main.OnClick = function(self, button)
		if (button == "RightButton") then
			dewdrop:Open(man.frame, "children", man.options, 'cursorX', true, 'cursorY', true)
		else
			dewdrop:Close()
		end
	end

	local prevButton, rightButtons
	local function AddButton(text, tooltip, func)
		local b = self:MakeButton(main, text, tooltip, func)
		if (not prevButton) then
			if (rightButtons) then
				b:SetPoint("BOTTOMRIGHT")
			else
				b:SetPoint("BOTTOMLEFT")
			end
		else
			if (rightButtons) then
				b:SetPoint("TOPRIGHT", prevButton, "TOPLEFT", -5, 0)
			else
				b:SetPoint("TOPLEFT", prevButton, "TOPRIGHT", 5, 0)
			end
		end
		prevButton = b
		return b
	end

	main.configure	= AddButton(L["Configure"],	L["Configure the automatic template generation"], man.ToggleConfigure)
	main.help		= AddButton(L["Help"],		L["What the hell am I looking at?"], man.Help)

	prevButton = nil
	rightButtons = true
	main.generate	= AddButton(L["Generate"],	L["Generate automatic templates from manager's main template. This will broadcast new templates to all paladins, so only use at start of raid to set initial configuration. Changes made later by individual paladins will be reflected in the blessings grid."], man.Generate)
	main.broadcast	= AddButton(L["Broadcast"],	L["Broadcast these templates to all paladins (Simply a refresh)"], man.BroadcastTemplates)
	main.groups		= AddButton("8 Groups",		L["Change how many groups are included in template generation and Paladin inclusion"], man.GroupsMenu)
	main.autoroles	= AddButton(L["Auto Roles"],L["Automatically assign all player roles"], man.SplitAutoRoles)
	if (self:TalentsMissingFromSelectedGroups()) then
		main.autoroles:Disable()
	end

	main.classTitle = CreateFrame("Frame", "ZOMGBMClassTitle", main)
	main.classTitle.cell = {}
	main.classTitle:SetPoint("TOPLEFT")
	main.classTitle:SetPoint("BOTTOMRIGHT", main, "TOPRIGHT", 0, -40)

	local splitFunc, splitExpandFunc, splitOnLeaveFunc
	splitFunc = function(self)
		man:SplitClass(self.class)
	end
	splitExpandFunc = function(self)
		if (man.dragIcon and man.dragIcon:IsShown()) then
			return
		end
		man:SplitExpand(self.class)
		man:HighlightClass(self.class)
		if (not man.configuring and man.splitframe and man.splitframe:IsOpen()) then
			man:SplitClass(self.class, true)
		end
	end
	splitOnLeaveFunc = function(self)
		if (man.dragIcon and man.dragIcon:IsShown()) then
			return
		end
		man:HighlightClass()
	end

	local order = copy(classOrder)
	tinsert(order, "AURA")

	for k,v in pairs(order) do
		local cell = CreateFrame("Button", "ZOMGBMClassTitle"..v, main)
		main.classTitle.cell[k] = cell
		cell:SetWidth(36)
		cell:SetHeight(36)

		if (v == "AURA") then
			cell:SetNormalTexture("Interface\\Icons\\Spell_Nature_WispSplode")
		else
			cell:SetNormalTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")
		end

		cell:SetHitRectInsets(-4, -4, -4, -4)

		if (v ~= "AURA") then
			local count = cell:CreateFontString(nil, "OVERLAY", "NumberFontNormalLarge")
			cell.classcount = count
			count:SetPoint("TOPRIGHT")
			count:SetText("0")
			count:SetTextColor(1, 1, 0, 1)
		end

		cell.class = v
		cell:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
		cell:SetScript("OnClick", splitFunc)
		cell:SetScript("OnEnter", splitExpandFunc)
		cell:SetScript("OnLeave", splitOnLeaveFunc)
		cell:EnableMouse(true)

		if (k == 1) then
			cell:SetPoint("TOPLEFT", 126, 0)
		else
			if (v == "AURA") then
				cell:SetPoint("TOPLEFT", prev, "TOPRIGHT", 18, 0)
			else
				cell:SetPoint("TOPLEFT", prev, "TOPRIGHT", 6, 0)
			end
		end

		cell.normalTex = cell:GetNormalTexture()
		cell.highlightTex = cell:GetHighlightTexture()
		if (v == "AURA") then
			cell.normalTex:SetTexCoord(0.06, 0.94, 0.06, 0.94)
		else
			SetClassIcon(cell.normalTex, v)
		end
		prev = cell
	end

	del(order)

	self.CreateMainMainFrame = nil
	return main
end

-- CreateMainFrame
function man:CreateMainFrame()
	local f = self.frame
	if (not f) then
		f = self:CreateMainMainFrame()
		f.row = {}
	end

	local function CreateClassRow(rowNumber)
		local row = CreateFrame("Frame", "ZOMGBMClassRow"..rowNumber, self.frame)
		row:SetID(rowNumber)
		row.row = rowNumber
		row.cell = {}
		row:SetWidth(100 + 36 * #classOrder)
		row:SetHeight(40)

		local cell = CreateFrame("Frame", nil, row)
		row.title = cell
		cell:SetPoint("TOPLEFT", 0, -2)
		cell:SetWidth(120)
		cell:SetHeight(36)
		cell.name = cell:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
		cell.name:SetAllPoints()
		local c = (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS).PALADIN
		cell.name:SetTextColor(c.r, c.g, c.b)

		cell.spec = cell:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		cell.spec:SetAllPoints()
		cell.spec:SetJustifyH("RIGHT")
		cell.spec:SetJustifyV("BOTTOM")
		cell.spec:SetTextColor(0, 1, 0)

		cell.symbols = cell:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		cell.symbols:SetAllPoints()
		cell.symbols:SetJustifyH("RIGHT")
		cell.symbols:SetJustifyV("MIDDLE")
		cell.symbols:SetTextColor(1, 1, 1)

		cell.ackWait = cell:CreateTexture(nil, "OVERLAY")
		cell.ackWait:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
		cell.ackWait:SetTexCoord(0, 0.25, 0, 0.25)
		cell.ackWait:SetPoint("BOTTOMLEFT")
		cell.ackWait:SetWidth(14)
		cell.ackWait:SetHeight(14)
		--cell.ackWait:Hide()

		cell.offline = cell:CreateTexture(nil, "OVERLAY")
		cell.offline:SetPoint("CENTER")
		cell.offline:SetHeight(48)
		cell.offline:SetWidth(48)
		cell.offline:SetTexture("Interface\\CharacterFrame\\Disconnect-Icon")
		cell.offline:Hide()

		cell.version = cell:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		cell.version:SetTextColor(0.5, 0.5, 0.5)
		cell.version:SetAllPoints()
		cell.version:SetJustifyH("RIGHT")
		cell.version:SetJustifyV("TOP")
		cell.version:Hide()

		cell.icons = {}
		cell.bottomicons = {}

		local order = copy(classOrder)
		tinsert(order, "AURA")

		for i = 1,#order do
			prev = cell

			abCount = abCount + 1
			cell = CreateFrame("Button", "ZOMGActionButton"..abCount, row, "ActionButtonTemplate")
			tinsert(row.cell, cell)
			cell:SetPoint("TOPLEFT", prev, "TOPRIGHT", order[i] == "AURA" and 18 or 6, 0)

			cell.icon = getglobal(cell:GetName().."Icon")
			cell.text = getglobal(cell:GetName().."Text")

			cell:SetID(i)
			cell.aura = order[i] == "AURA"
			cell.col = i
			cell.row = rowNumber

			cell:SetHitRectInsets(-4, -4, -4, -4)
			cell:EnableMouseWheel(true)

			cell:SetScript("OnEnter", onCellEnter)
			cell:SetScript("OnLeave", onCellLeave)
			cell:SetScript("OnClick", onCellClick)
			cell:SetScript("OnDragStart", onCellDrag)
			cell:SetScript("OnDragStop", onCellDragStop)
			cell:SetScript("OnMouseWheel", onCellMouseWheel)
			cell:RegisterForDrag("LeftButton")
			cell:RegisterForClicks("AnyUp")
		end

		del(order)

		return row
	end

	local rowSort = new()
	if (self.configuring) then
		for i = 1,#blessingCycle do
			tinsert(rowSort, tostring(i))
		end
	else
		rowSort = self.paladinOrder
	end

	local prevrow = f.classTitle
	for i,name in ipairs(rowSort) do

		local row = f.row[i]
		if (not row) then
			row = CreateClassRow(i)
			f.row[i] = row
		end

		row:Show()

		if (self.configuring) then
			row.pala = nil
			row.title.name:SetText(i)
		else
			if (not self.pala[name]) then
				error("No self.pala for "..name)
			end

			self.pala[name].row = i
			row.pala = name
			row.title.name:SetText(name)
		end

		row:SetPoint("TOPLEFT", prevrow, "BOTTOMLEFT", 0, -2)
		prevrow = row
	end

	-- Hide now un-used rows
	for i = #rowSort + 1,#f.row do
		f.row[i]:Hide()
	end

	if (split and self.configuring) then
		self:SplitPositionCells()
	else
		local h, w
		h = 66 + #rowSort * 42
		w = 136 + 42 * (#classOrder + 1)

		f:SetSize(w, h)
	end

	if (self.configuring) then
		del(rowSort)
	end

	self:SetButtons()
end

-- CellHasError
function man:CellHasError(row, col, panel)
	local Type = self:GetCell(row, col, panel)

	for i = 1,row - 1 do
		if (self:GetCell(i, col, panel) == Type) then
			return true
		end
	end

	if (not self.configuring) then
		local pala = self:GetPalaFromRow(row)
		if (pala) then
			if (Type == "BOK" and not pala.canKings) then
				return true
			elseif (Type == "SAN" and not pala.canSanctuary) then
				return true
			end
		end
	end
end

-- DrawIcons
function man:DrawIcons(row)
	local rowNumber = row:GetID()

	local order = copy(classOrder)
	tinsert(order, "AURA")

	if (self.configuring) then
		for k,v in pairs(order) do
			local cell = row.cell[k]
			if (v ~= "AURA") then
				self:HideExceptionsForCell(cell)
			end
			local temp = template[v]
			if (temp and temp[rowNumber]) then
				if (v == "AURA") then
					local a = z.auras[temp[rowNumber]]
					if (not a) then
						error("Unkown aura "..tostring(temp[rowNumber]))
					end

					cell.icon:SetTexture(a.icon)
					cell.icon:SetVertexColor(1, 1, 1)
				else
					local singleSpell, classSpell = z:GetBlessingFromType(temp[rowNumber])
					local icon = z.blessings[classSpell or singleSpell].icon

					cell.icon:SetTexture(icon)
					if (self:CellHasError(rowNumber, k)) then
						self.anyErrors = true
						cell.icon:SetVertexColor(1, 0.5, 0.5)
					elseif (self:HasException(rowNumber, k)) then
						cell.icon:SetVertexColor(0.5, 0.5, 1)
					else
						cell.icon:SetVertexColor(1, 1, 1)
					end
				end
			else
				cell.icon:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")		-- Blank for errors/missing
				cell.icon:SetVertexColor(0, 0, 0)
			end
			cell:Enable()
		end
	else
		local pala = self.pala[row.pala]
		if (not pala) then
			-- Probably leaving raid and invalid atm
			return
		end

		if (rowNumber ~= pala.row) then
			error("Row number mismatch for "..tostring(who))
		end

		local template = pala.template

		for k,v in pairs(order) do
			local cell = row.cell[k]
			if (not cell) then
				error("Missing cell "..tostring(index).."x"..tostring(k))
			end
			if (v ~= "AURA") then
				self:HideExceptionsForCell(cell)
			end

			local Type
			if (v == "AURA") then
				Type = pala.aura
			else
				Type = template and template[v]
			end
			if (Type) then
				if (v == "AURA") then
					local a = z.auras[Type]
					if (not a) then
						error("Unkown aura "..tostring(Type))
					end

					cell.icon:SetTexture(a.icon)
					cell.icon:SetVertexColor(1, 1, 1)
				else
					local singleSpell, classSpell = z:GetBlessingFromType(Type)
					if (not singleSpell) then
						error("Unknown type "..tostring(Type))
					end

					local icon = z.blessings[classSpell or singleSpell].icon
					cell.icon:SetTexture(icon)

					if (self:CellHasError(rowNumber, k)) then
						self.anyErrors = true
						cell.icon:SetVertexColor(1, 0.5, 0.5)
					else
						local exception = self:HasException(rowNumber, k)
						if (exception) then
							cell.icon:SetVertexColor(0.5, 0.5, 1)
							index = 2
							repeat
								self:ShowException(cell, exception)
								exception = self:HasException(rowNumber, k, index)
								index = index + 1
							until (not exception or index >= 4)
						else
							cell.icon:SetVertexColor(1, 1, 1)
						end
					end
				end
			else
				cell.icon:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")		-- Blank for errors/missing
				cell.icon:SetVertexColor(0, 0, 0)
				
				if (v ~= "AURA") then
					local exception = self:HasException(rowNumber, k, cell.exceptions and #cell.exceptions + 1)
					if (exception) then
						index = 2
						repeat
							self:ShowException(cell, exception, true)
							exception = self:HasException(rowNumber, k, index)
							index = index + 1
						until (not exception or index >= 4)
					end
				end
			end
			if (pala.canEdit) then
				cell:Enable()
			else
				cell:Disable()
			end
		end
	end

	del(order)
end

-- ShowException
function man:HideExceptionsForCell(cell)
	if (cell.exceptions) then
		while (#cell.exceptions > 0) do
			local icon = tremove(cell.exceptions, 1)

			if (not self.exceptionTextures) then
				self.exceptionTextures = new()
			end

			tinsert(self.exceptionTextures, icon)
			icon:Hide()
		end

		cell.exceptions = del(cell.exceptions)
	end
end

-- ShowException
function man:ShowException(cell, exception, force)
	if (force or self.db.profile.showexceptions) then
		local newIndex = (cell.exceptions and #cell.exceptions or 0) + 1
		if (newIndex <= SHOW_CELL_EXCEPTIONS_COUNT) then
			local tex = cell.exceptions and cell.exceptions[newIndex]
			if (not tex) then
				tex = self:GetExceptionTexture(cell)
				if (not cell.exceptions) then
					cell.exceptions = new()
				end
				cell.exceptions[newIndex] = tex
			end
	
			tex:SetPoint("BOTTOMLEFT", -1 + (newIndex - 1) * 12, 0)
	
			local texture = z.blessingsIndex[exception] and z.blessingsIndex[exception].icon
			tex:SetTexture(texture)
		end
	end
end

-- GetExceptionTexture
function man:GetExceptionTexture(cell)
	local tex
	if (self.exceptionTextures) then
		tex = tremove(self.exceptionTextures, 1)
	end
	if (not tex) then
		tex = cell:CreateTexture(nil, "OVERLAY")
		tex:SetWidth(12)
		tex:SetHeight(12)
		tex:SetTexCoord(0.05, 0.95, 0.05, 0.95)
	else
		tex:SetParent(cell)
		tex:ClearAllPoints()
	end
	tex:Show()
	return tex
end

-- DrawIconsByName
function man:DrawIconsByName(who)
	if (self.frame) then
		local pala = self.pala[who]
		if (not pala) then
			return
		end

		local row = self.frame.row[pala.row]
		if (not row) then
			return
		end

		self:DrawIcons(row)
	end
end

-- PalaIcon
local function PalaIcon(self, index, tex, bottom)
	local key = bottom and "bottomicons" or "icons"
	local icon = self[key][index]
	if (not icon and tex) then
		icon = self:CreateTexture(nil, "OVERLAY")
		self[key][index] = icon
		icon:SetWidth(14)
		icon:SetHeight(14)

		if (index == 1) then
			if (bottom) then
				icon:SetPoint("BOTTOMLEFT", 4, 1)
			else
				icon:SetPoint("TOPLEFT", 4, -1)
			end
		else
			icon:SetPoint("TOPLEFT", self[key][index - 1], "TOPRIGHT", 0, 0)
		end
	end
	if (icon) then
		if (tex) then
			icon:SetTexture(tex)
			icon:Show()
		else
			icon:Hide()
		end
	end
end

-- ConvertVersion
-- Converts (for example) "0.9a" to "0.009a" internally so we can compare versions properly
function man:ConvertVersion(ver)
	local major, minor, letter = strmatch(ver, "([0-9]+)\.([0-9]+)([a-z]*)")
	return format("%s.%03d%s", major, tonumber(minor), letter)
end

-- DrawPaladin
function man:DrawPaladin(row)
	local bicon, icon = 1, 1

	row.title.offline:Hide()
	row.title.ackWait:Hide()
	row.title.version:Hide()
	row.title.symbols:Hide()
	row.title.spec:Hide()

	if (self.configuring) then
		row.title.name:SetText(row:GetID())
	else
		local who = row.pala
		local pala = self.pala[who]
		if (not pala) then
			return			-- error("No self.pala for "..who)
		end
		row.title.name:SetText(who)

		local v = z.versionRoster and z.versionRoster[who]
		if (v) then
			local vn = tonumber(v)
			if (vn and vn > 50000) then
				-- So we can compare new vs. old SVN repositories
				v = vn - 82090		-- 82089 was last ZOMG on old SVN
			end

			row.title.version:Show()
			if (type(v) == "string") then
				row.title.version:SetText(v)
				if (strfind(v, "PallyPower")) then
					row.title.version:SetTextColor(0.5, 0.5, 0.5)
				else
					row.title.version:SetTextColor(1, 0, 0)
				end
			else
				row.title.version:SetFormattedText("r%d", v)
				if (v < z.versionCompat) then
					row.title.version:SetTextColor(1, 0, 0)
				elseif (v == z.maxVersionSeen) then
					row.title.version:SetTextColor(0.5, 1, 0.5)
				elseif (v < z.maxVersionSeen) then
					row.title.version:SetTextColor(1, 0.5, 0.5)
				else
					row.title.version:SetTextColor(0.5, 0.5, 0.5)
				end
			end
		else
			row.title.version:Hide()
		end

		if (pala.symbols) then
			row.title.symbols:SetText(pala.symbols)
			if (pala.symbols < 20) then
				row.title.symbols:SetTextColor(1, 0.5, 0.5)
			else
				row.title.symbols:SetTextColor(1, 1, 0.5)
			end
			row.title.symbols:Show()
		end

		if (pala.spec) then
			row.title.spec:SetText(table.concat(pala.spec, " / "))
			row.title.spec:Show()
		end

		if (UnitIsConnected(who)) then
			local c = (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS).PALADIN
			row.title.name:SetTextColor(c.r, c.g, c.b)
			row.title.spec:SetTextColor(0, 1, 0)
		else
			row.title.offline:Show()
			row.title.name:SetTextColor(0.5, 0.5, 0.5)
			row.title.version:SetTextColor(0.5, 0.5, 0.5)
			row.title.spec:SetTextColor(0.5, 0.5, 0.5)
			row.title.symbols:SetTextColor(0.5, 0.5, 0.5)
		end

		if (type(pala.improvedWisdom) ~= "number") then
			pala.improvedWisdom = pala.improvedWisdom and 2 or 0
		end
		if (type(pala.improvedMight) ~= "number") then
			pala.improvedMight = pala.improvedMight and 5 or 0
		end

		if (pala.canKings) then
			PalaIcon(row.title, icon, (select(3, GetSpellInfo(25898)))) 		-- Interface\\Icons\\Spell_Magic_GreaterBlessingofKings
			icon = icon + 1
		end
		if (pala.canSanctuary) then
			PalaIcon(row.title, icon, (select(3, GetSpellInfo(25899)))) 		-- Interface\\Icons\\Spell_Holy_GreaterBlessingofSanctuary
			icon = icon + 1
		end
		if ((pala.improvedMight or 0) > 0) then
			PalaIcon(row.title, icon, (select(3, GetSpellInfo(27141)))) 		-- Interface\\Icons\\Spell_Holy_GreaterBlessingofMight
			icon = icon + 1
		end
		if ((pala.improvedWisdom or 0) > 0) then
			PalaIcon(row.title, icon, (select(3, GetSpellInfo(27143)))) 		-- Interface\\Icons\\Spell_Holy_GreaterBlessingofWisdom
			icon = icon + 1
		end

		if ((pala.improvedDevotion or 0) > 0) then
			PalaIcon(row.title, bicon, (select(3, GetSpellInfo(48942))), true)	-- Interface\\Icons\\Spell_Holy_DevotionAura
			bicon = bicon + 1
		end
		if ((pala.improvedRetribution or 0) > 0) then
			PalaIcon(row.title, bicon, (select(3, GetSpellInfo(54043))), true)	-- Interface\\Icons\\Spell_Holy_AuraOfLight
			bicon = bicon + 1
		end
		if ((pala.improvedConcentration or 0) > 0) then
			PalaIcon(row.title, bicon, (select(3, GetSpellInfo(19746))), true)	-- Interface\\Icons\\Spell_Holy_MindSooth
			bicon = bicon + 1
		end

		if (pala.waitingForAck) then
			row.title.ackWait:Show()
		end
	end
	for i = icon,4 do
		PalaIcon(row.title, i)
	end
	for i = bicon,3 do
		PalaIcon(row.title, i, nil, true)
	end
end

-- OnReceiveVersion
function man:OnReceiveVersion(sender, version)
	self:DrawPaladinByName(sender)
end

-- UnitFullName
local function UnitFullName(unit)
	local name, realm = UnitName(unit)
	if (realm and realm ~= "") then
		return format("%s-%s", name, realm)
	end
	return name
end

-- LibGroupTalents_Update
function man:LibGroupTalents_Update(e, guid, unit, newSpec, n1, n2, n3, oldSpec, o1, o2, o3)
	local name = UnitFullName(unit)
	local pala = self.pala[name]
	if (pala) then
		self:ReadPaladinSpec(pala, name)
		self:DrawPaladinByName(name)
	end

	if (self.frame and self.frame.autoroles) then
		if (not self:TalentsMissingFromSelectedGroups()) then
			self.frame.autoroles:Enable()
		end
	end
end

-- DrawPaladinByName
function man:DrawPaladinByName(who)
	if (not self.frame or not self.pala) then
		return
	end

	local pala = self.pala[who]
	if (not pala) then
		return	-- error("No self.pala for "..tostring(who))
	end
	row = pala.row
	if (not row) then
		return	-- error("No row for "..tostring(who))
	end

	local row = self.frame.row[row]
	if (not row) then
		return	-- error("No frame row for "..tostring(who))
	end

	self:DrawPaladin(row)
end

-- SetButtons
function man:SetButtons()
	if (self.configuring) then
		self.frame.configure:SetText(L["Finish"])
		self.frame.configure.tooltipText = L["Finish configuring template"]
		self.frame.broadcast:Hide()
		self.frame.generate:Hide()
		self.frame.groups:Hide()
		self.frame.autoroles:Hide()
	else
		self.frame.configure:SetText(L["Configure"])
		self.frame.configure.tooltipText = L["Configure the automatic template generation"]

		if (self.canEdit) then
			self.frame.broadcast:Show()
			self.frame.generate:Show()
			self.frame.autoroles:Show()
		else
			self.frame.broadcast:Hide()
			self.frame.generate:Hide()
			self.frame.autoroles:Hide()
		end
		self.frame.groups:Show()
	end
end

-- ToggleConfigure
function man:ToggleConfigure()
	self.configuring = not self.configuring
	if (self.frame) then
		self:SetButtons()
		if (not self.configuring) then
			self:AssignPaladins()
		end

		if (not self.configuring and self.expandpanel) then
			self.expandpanel:Hide()
		end

		self:DrawAll()
	end
end

-- EnableBroadcast
function man:EnableBroadcast()
	self.frame.broadcast:Enable()
	self.frame.generate:Enable()
end

-- AssumeControl
function man:BroadcastTemplates()
	if (self.canEdit) then
		self.frame.broadcast:Disable()
		self.frame.generate:Disable()
		self:ScheduleEvent("ZOMGBlessings_EnableBroadcast", self.EnableBroadcast, 5, self)

		self:GiveAllTemplates()
	end
end

-- GroupsMenu
local groupsMenu
function man:GroupsMenu()
	local button = self.frame.groups
	
	if (not groupsMenu) then
		local function getGroups(i)
			return self.db.profile.groups == i
		end
		local function setGroups(i)
			self.db.profile.groups = i
			self:AssignPaladins()
			if (self.frame and self.frame:IsOpen()) then
				self:DrawAll()
			end
			dewdrop:Close()
		end

		groupsMenu = {
			type = 'group',
			name = " ",
			desc = " ",
			args = {
				spacer = {
					type = 'header',
					name = " ",
					order = 100,
				}
			}
		}
		
		for i = 1,8 do
			groupsMenu.args["group"..i] = {
				type = 'toggle',
				name = format(i == 1 and L["%d Group"] or L["%d Groups"], i),
				desc = format(i == 1 and L["%d Group"] or L["%d Groups"], i),
				get = getGroups,
				set = setGroups,
				passValue = i,
				isRadio = true,
				order = i,
			}
		end
	end

	if (dewdrop:IsOpen(button)) then
		dewdrop:Close()
	else
		dewdrop:Open(button, 'children', groupsMenu, 'point', "TOPLEFT", 'relativePoint', "BOTTOMLEFT")
	end
end

-- GetCell
function man:GetCell(row, col, panel)
	if (panel) then
		local class = self.expandpanel.class
		if (row and col and template.subclass) then
			if (template.subclass[class]) then
				local t = template.subclass[class]

				local code = self.classSplits[class][col + 1].code
				if (not code) then
					error("No code for "..class)
				end

				if (t[code]) then
					return t[code][row]
				end
			end
		end
		return template[class] and template[class][row]
	else
		local class = classOrder[col]
		if (class) then
			if (man.configuring) then
				if (template[class]) then
					return template[class][row]
				end
			else
				local pala = self:GetPalaFromRow(row)
				if (pala) then
					return pala.template and pala.template[class]
				end
			end
		else
			if (man.configuring) then
				if (template.AURA) then
					return template.AURA[row]
				end
			else
				local pala, palaName = self:GetPalaFromRow(row)
				if (pala) then
					return pala.aura
				end
			end
		end
	end
end

-- SetCell
function man:SetCell(row, col, Type, panel)
--[===[@debug@
	self:argCheck(row, 1, "number")
	self:argCheck(col, 2, "number")
	self:argCheck(Type, 3, "string", "nil")
--@end-debug@]===]
	if (panel) then
		if (row and col) then
			local class = self.expandpanel.class

			if (not template.subclass) then
				template.subclass = {}
			end
			if (not template.subclass[class]) then
				template.subclass[class] = {}
			end
			local t = template.subclass[class]

			local code = self.classSplits[class][col + 1].code
			if (not code) then
				error("No code for "..class)
			end

			if (not t[code]) then
				t[code] = copy(template[class])
			end
			t[code][row] = Type
			template.modified = true

			local diff
			for i = 1,#blessingCycle do
				if (t[code][row] ~= template[class][row]) then
					diff = true
					break
				end
			end

			if (not diff) then
				if (not next(t[code])) then
					t[code] = del(t[code])
				end
				if (not next(template.subclass[class])) then
					template.subclass[class] = nil
				end
				if (not next(template.subclass)) then
					template.subclass = nil
				end
			end
		end
	else
		local class = classOrder[col]
		if (class) then
			if (man.configuring) then
				if (template[class]) then
					template[class][row] = Type
					template.modified = true
					self:MakeTemplateOptions()
				end
			else
				local pala, palaName = self:GetPalaFromRow(row)
				if (pala and pala.template) then
					z:Log("man", nil, "change", palaName, class, pala.template[class], Type)

					pala.template[class] = Type

					self:BroadcastTemplatePart(palaName, class, Type)
				end
			end
		else
			if (man.configuring) then
				if (not template.AURA and Type) then
					template.AURA = new()
				end
				if (template.AURA) then
					template.AURA[row] = Type
					template.modified = true
					self:MakeTemplateOptions()
				end
				if (template.AURA and not next(template.AURA)) then
					template.AURA = del(template.AURA)
				end
			else
				local pala, palaName = self:GetPalaFromRow(row)
				if (pala) then
					pala.aura = Type
					self:BroadcastTemplateAura(palaName, Type)
				end
			end
		end
	end
end

-- GetException
function man:GetException(name, row, col)
	if (not man.configuring) then
		local pala = self:GetPalaFromRow(row)
		if (pala) then
			return pala.template[name]
		end
	end
end

-- HasException
function man:HasException(row, col, index)
	if (not man.configuring) then
		local t = self:GetPalaTemplateFromRow(row)
		if (t) then
			local class = classOrder[col]
			local i = 1
			for nameClass,blessing in pairs(t) do
				if (nameClass ~= "modified" and nameClass ~= "state" and not classIndex[nameClass]) then
					local found = self:NameToClass(nameClass)
					if (found == class) then
						if (not index or index == i) then
							return blessing
						end
						i = i + 1
					end
				end
			end
		end
	end
end

-- SetException
function man:SetException(name, row, col, n)
--[===[@debug@
	self:argCheck(name, 1, "string")
	self:argCheck(row, 2, "number")
	self:argCheck(col, 3, "number")
	self:argCheck(n, 4, "string", "nil")
--@end-debug@]===]
	local class = classOrder[col]
	if (not man.configuring and self.canEdit) then
		local pala, palaName = self:GetPalaFromRow(row)
		if (pala and pala.canEdit) then
			if (n ~= pala.template[name]) then
				pala.template[name] = n

				z:Log("man", nil, "exception", palaName, name, oldType, pala.template[name])

				self:DrawIcons(self.frame.row[row])
				self:BroadcastTemplatePart(palaName, name, n)
			end
		end
	end
end

-- ClearCellExceptions
function man:ClearCellExceptions(row, col)
	local class = classOrder[col]
	if (not man.configuring) then
		local pala, palaName = self:GetPalaFromRow(row)
		if (pala and pala.canEdit) then
			for nameClass,blessing in pairs(pala.template) do
				local found = self:NameToClass(nameClass)
				if (found == classOrder[col]) then
					pala.template[nameClass] = nil
					self:DrawIcons(self.frame.row[row])
					if (ZOMGBlessingsPP) then
						ZOMGBlessingsPP:GiveTemplatePart(palaName, nameClass, nil)
					end
				end
			end
			self:GiveTemplate(palaName, true)
			z:Log("man", nil, "clearcell", palaName, classOrder[col])
		end
	end
end

-- UnitContextMenu
local contextMenu = {
	type = "group",
	order = 2,
	name = L["Exceptions"],
	desc = L["Unit exceptions"],
	handler = man,
}
local contextRow, contextCol
function man:UnitContextMenu(row, col)
	local class = classOrder[col]
	local list

	for unit, unitname, unitclass, subgroup, index in z:IterateRoster() do
		if (unitclass == class and subgroup <= self.db.profile.groups) then
			if (not list) then
				list = new()
			end
			tinsert(list, unit)
		end
	end
	if (list or self:HasException(row, col)) then
		if (list) then
			sort(list,
				function(a,b)
					a = UnitName(a)
					b = UnitName(b)
					return a < b
				end)
		end

		local function getFunc(k, ...)
			local name, buff = strsplit(",", k)
			return self:GetException(name, contextRow, contextCol) == buff
		end
		local function setFunc(k, onoff, ...)
			local name, buff = strsplit(",", k)
			self:SetException(name, contextRow, contextCol, buff)
		end

		local mainBuff = self:GetCell(row, col)
		local pala = self:GetPalaFromRow(row)

		contextMenu.args = {
			header = {
				type = "header",
				name = L["Exceptions"],
				order = 1,
			},
			remove = {
				type = "execute",
				name = L["Clear"],
				desc = L["Remove all exceptions for this cell"],
				func = function() man:ClearCellExceptions(contextRow, contextCol) end,
				order = 100,
				hidden = function() return not self:HasException(row, col) end,
			}
		}

		if (list) then
			for i,unit in ipairs(list) do
				local unitname = UnitName(unit)
				local cName = z:ColourUnit(unit)
				local cDesc = format(L["Single target exception for %s"], cName)
				contextMenu.args[unitname] = {
					type = "group",
					order = i + 2,
					name = z:ColourUnit(unit),
					desc = cDesc,
					get = getFunc,
					set = setFunc,
					pass = true,
					args = {
						none = {
							type = "toggle",
							order = 1,
							name = L["None"],
							desc = cDesc,
							passValue = unitname,
							isRadio = true,
						},
					},
				}

				for j,buff in ipairs(blessingCycle) do
					if (buff ~= mainBuff and (z.manaClasses[class] or buff ~= "BOW") and (not pala.gotCapabilities or (buff == "SAN" and pala.canSanctuary) or (buff == "BOK" and pala.canKings) or (buff ~= "SAN" and buff ~= "BOK"))) then
						contextMenu.args[unitname].args[buff] = {
							type = "toggle",
							order = j + 2,
							name = z:ColourBlessing(buff),
							desc = cDesc,
							passValue = unitname..","..tostring(buff),
							isRadio = true,
						}
					end
				end
			end
			del(list)
		end

		contextRow, contextCol = row, col
		dewdrop:Open(self.frame, "children", contextMenu, 'cursorX', true, 'cursorY', true)
	end
end

-- OnCellClick
function man:OnCellClick(row, col, button, panel)
	if (button == "RightButton" and not self.configuring and not panel and self.canEdit) then
		self:UnitContextMenu(row, col)
	else
		if (self.configuring or self.canEdit) then
			local pala = self:GetPalaFromRow(row)
			if (not self.configuring and (not pala or not pala.canEdit)) then
				return
			end
			if (self.canEdit and pala and pala.waitingForAck) then
				if (pala.waitingForAck + 10 > GetTime()) then
					return
				else
					pala.waitingForAck = nil
				end
			end

			local Type = self:GetCell(row, col, panel)
			local ind, class
			if (col > #classOrder) then
				ind = z.auraIndex[Type] or 0
				class = "AURA"
			else
				ind = blessingCycleIndex[Type] or 0
				class = classOrder[col]
			end

			for i = 1,20 do		-- Just in case we get stuck.
				if (button == "LeftButton" or button == "MOUSEWHEELDOWN") then
					if (ind == (class == "AURA" and #z.auraCycle or #blessingCycle)) then
						ind = 0
					else
						ind = ind + 1
					end
				else
					if (ind == 0) then
						ind = class == "AURA" and #z.auraCycle or #blessingCycle
					else
						ind = ind - 1
					end
				end
				if (class == "AURA") then
					Type = z.auraCycle[ind]
				else
					Type = blessingCycle[ind]
				end

				if (self.configuring or class == "AURA") then
					break
				elseif ((Type == "BOK" and pala.canKings) or
						(Type == "SAN" and pala.canSanctuary) or
						(Type == "BOW" and z.manaClasses[class]) or
						(Type ~= "BOK" and Type ~= "SAN" and Type ~= "BOW")) then
					break
				end
			end

			self:SetCell(row, col, Type, panel)
			self:DrawAll(panel)
		end
	end
end

-- DimNonDraggables
function man:DimNonDraggables(row, col, panel, onoff)
	if (not self.db.profile.greyout or (not self.canDesaturate and not row)) then
		return
	end

	local rows = self.frame.row

	for i,cellrow in ipairs(rows) do
		for j,class in ipairs(classOrder) do
			local cell = cellrow.cell[j]
			local cellTex = cell.icon:GetTexture()

			if (onoff and (panel or j ~= col or i == row) and cellTex ~= "Interface\\Tooltips\\UI-Tooltip-Background") then
				if (not cell.icon:SetDesaturated(true)) then
					return				-- User's gfx card can't do this, so just return now
				end
			else
				cell.icon:SetDesaturated(nil)
			end
		end
	end

	local p = self.expandpanel
	if (p) then
		for column,cellcolumn in ipairs(p.column) do
			for rownum,cell in ipairs(cellcolumn.cell) do
				local cellTex = cell.icon:GetTexture()
				if (onoff and (not panel or column ~= col or rownum == row) and cellTex ~= "Interface\\Tooltips\\UI-Tooltip-Background") then
					cell.icon:SetDesaturated(true)
				else
					cell.icon:SetDesaturated(nil)
				end
			end
		end
	end

	self.canDesaturate = true
end

-- OnCellDrag
function man:OnCellDrag(cell, row, col, panel)
	if (self.configuring or self.canEdit) then
		if (not self.configuring) then
			local pala = self:GetPalaFromRow(row)
			if (not pala or not pala.canEdit) then
				return
			end
		end

		GameTooltip:Hide()
		dewdrop:Close()
		local icon = self:StartDrag(true, cell.icon:GetTexture())
		icon.dragRow = row
		icon.dragCol = col
		icon.dragPanel = panel

		man:DimNonDraggables(row, col, panel, true)
	end
end

-- OnCellDragStop
function man:OnCellDragStop(cell)
	man:DimNonDraggables()

	local icon = self.dragIcon
	if (not icon) then
		return
	end

	icon:ClearAllPoints()
	icon:Hide()

	if (self.configuring or self.canEdit) then
		local f = GetMouseFocus()

		if (f ~= cell and f:GetParent() and cell:GetParent() and f:GetParent():GetParent() == cell:GetParent():GetParent()) then
			local row = f.row
			local col = f.col
			local panel = f.split

			if (cell.col == f.col and cell.row ~= f.row and f.split == cell.split) then
				local pala = self:GetPalaFromRow(cell.row)
				if (pala) then
					if (not self.configuring and not pala.canEdit) then
						return
					end
				end
				pala = self:GetPalaFromRow(f.row)
				if (pala) then
					if (not self.configuring and not pala.canEdit) then
						return
					end
				end

				-- Shuffle the order up or down depending on direction of drag
				local save = self:GetCell(cell.row, col, panel)
				if (row > cell.row) then
					for i = cell.row,row - 1 do
						self:SetCell(i, col, self:GetCell(i + 1, col, panel), panel)
					end
				else
					for i = cell.row,row + 1,-1 do
						self:SetCell(i, col, self:GetCell(i - 1, col, panel), panel)
					end
				end
				self:SetCell(row, col, save, panel)
				self:DrawAll()
			end
		end
	end
end

-- man:GetPalaFromRow(row)
function man:GetPalaFromRow(row)
	for name,pala in pairs(self.pala) do
		if (pala.row == row) then
			return pala, name
		end
	end
	return nil
end

-- GetPalaTemplateFromRow
function man:GetPalaTemplateFromRow(row)
	local pala = self:GetPalaFromRow(row)
	return pala and pala.template
end

-- NameToClass
function man:NameToClass(nameClass)
	if (nameClass ~= "modified" and nameClass ~= "state" and not classIndex[nameClass]) then
		return select(2, UnitClass(nameClass))
	end
	return nil
end

-- SplitPositionCells
function man:HighlightClass(highlightClass, highlightRow)
	for i,class in ipairs(classOrder) do
		local titleCell = self.frame.classTitle.cell[i]
		if (not self.db.profile.highlights or not highlightClass or class == highlightClass) then
			titleCell:SetAlpha(1)
		else
			titleCell:SetAlpha(0.5)
		end

		for j,row in ipairs(self.frame.row) do
			local cell = row.cell[i]
			if (not self.db.profile.highlights or not highlightClass or class == highlightClass) then
				cell:SetAlpha(1)
			else
				cell:SetAlpha(0.5)
			end
		end
	end

	for j,row in pairs(self.frame.row) do
		if (not self.db.profile.highlights or not highlightRow or j == highlightRow) then
			row.title:SetAlpha(1)
		else
			row.title:SetAlpha(0.5)
		end
	end
end

-- OnCellEnter
function man:OnCellEnter(cell, row, col)
	local class = classOrder[col]

	if (self.dragIcon and self.dragIcon:IsShown()) then
		return
	end

	self:HighlightClass(class, row)
	if (self.splitframe and self.splitframe:IsOpen()) then
		self:SplitClass(class, true)
	end

	if (col < #classOrder) then
		local eclass = classOrder[col]	
		if (eclass) then
			local e
			if (man.configuring) then
				e = template.exceptions and template.exceptions[class] and template.exceptions[class][row]
			else
				local pala = self:GetPalaFromRow(row)
				if (not pala) then
					return
				end

				for nameClass,blessing in pairs(pala.template) do
					if (nameClass ~= "modified" and nameClass ~= "state" and not classIndex[nameClass]) then
						-- Must be a name
						if (self:NameToClass(nameClass) == eclass) then
							if (not e) then
								e = new()
							end
							e[nameClass] = blessing
						end
					end
				end
			end

			if (e) then
				GameTooltip:SetOwner(cell, "ANCHOR_BOTTOMLEFT")
				GameTooltip:SetText(L["Exceptions"], 1, 1, 1)

				for k,v in pairs(e) do
					GameTooltip:AddDoubleLine(z:ColourUnitByName(k), z:ColourBlessing(v))
				end
				GameTooltip:Show()
			end

			if (not man.configuring) then
				del(e)
			end
		end
	end

	self:SplitExpand(class)
end

-- SendAll
function man:SendAll(...)
	for k,v in pairs(self.pala) do
		if (k ~= playerName) then
			z:SendComm(k, ...)
		end
	end
end

-- DoTitle
function man:DoTitle()
	if (self.frame) then
		if (self.configuring) then
			self.frame:SetTitle(L["TITLE_CONFIGURE"])
		else
			local str
			if (self.whoGenerated) then
				str = format("%s (%s @ %s)", L["TITLE"], z:ColourUnitByName(self.whoGenerated), date("%X", self.whenGenerated))
			else
				str = L["TITLE"]
			end
			self.frame:SetTitle(str)
		end
	end
end

-- DrawAll
function man:DrawAll()
	self:CreateMainFrame()
	self:DoTitle()

	self.anyErrors = nil
	if (self.configuring) then
		for i = 1,#blessingCycle do
			local row = self.frame.row[i]
			self:DrawPaladin(row)
			self:DrawIcons(row)
		end
	else
		for k,v in pairs(self.pala) do
			self:DrawPaladinByName(k)
			self:DrawIconsByName(k)
		end
	end

   	if (self.configuring and self.expandpanel and self.expandpanel.class) then
		for i = 1,3 do
			local col = self.expandpanel.column[i]
			if (col and col:IsShown()) then
				self:SplitPanelColumnPopulate(col)
			end
		end
	end

	self:DoButtons()
end

-- CreatePPWarning
function man:CreatePPWarning()
	local f = CreateFrame("Frame", nil, self.frame.classTitle)
	self.frame.ppWarning = f
	
	f:SetPoint("TOPLEFT")
	f:SetPoint("BOTTOMRIGHT", self.frame.classTitle, "BOTTOMLEFT", 120, 0)
	f:EnableMouse(true)

	local tex = f:CreateTexture(nil, "OVERLAY")
	f.tex = tex
	tex:SetTexture("Interface\\DialogFrame\\DialogAlertIcon")
	tex:SetWidth(32)
	tex:SetHeight(32)
	tex:SetPoint("LEFT", 5, 0)
	tex:SetTexCoord(0.2, 0.8, 0.2, 0.8)

	local text = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	f.text = text
	text:SetPoint("LEFT", tex, "RIGHT", 0, 0)
	text:SetText(L["Warning!"])
	
	f:SetScript("OnEnter",
		function(self)
			GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
			GameTooltip:SetText(L["PallyPower users are in the raid and you are NOT promoted\rPallyPower only accepts assignment changes from promoted players"])
		end)
	f:SetScript("OnLeave",
		function(self)
			GameTooltip:Hide()
		end)

	self.CreatePPWarning = nil
end

-- AnyPPUsers
function man:AnyPPUsersAndNotPromoted()
	local leader = true
	if (GetNumRaidMembers() > 0) then
		leader = IsRaidOfficer() or IsRaidLeader()
	else	--if (GetNumPartyMembers() > 0) then
		leader = true	-- IsPartyLeader()		-- PP Seems to work for anyone in party
	end
	if (not leader) then
		for palaName,pala in pairs(self.pala) do
			if (palaName ~= playerName) then
				local ver = z.versionRoster[palaName]
				if (ver and type(ver) == "string" and ver == "PallyPower") then
					return true
				end
			end
		end
	end
end

-- ValidatePP
function man:ValidatePP()
	self:SetSelf()
	if (self.frame) then
		if (self:AnyPPUsersAndNotPromoted()) then
			if (not self.frame.ppWarning) then
				self:CreatePPWarning()
			else
				self.frame.ppWarning:Show()
			end
		else
			if (self.frame.ppWarning) then
				self.frame.ppWarning:Hide()
			end
		end
	end
end

-- DoButtons
function man:DoButtons()
	if (self.frame) then
		if (self.configuring and self.anyErrors) then
			self.frame.configure:Disable()
		else
			self.frame.configure:Enable()
		end
		self:ValidatePP()

		self.frame.groups:SetFormattedText(self.db.profile.groups == 1 and L["%d Group"] or L["%d Groups"], self.db.profile.groups)
	end
end

-- Open
function man:ToggleFrame()
	if (self.frame and self.frame:IsOpen()) then
		self:Close()
	else
		self:Open()
	end
end

-- Open
function man:Open()
	dewdrop:Close()
	self:AssignPaladins()

	self:CreateMainFrame()
	self.frame:Open()
	self:DrawAll()
	self:DrawClassCounts()

	self.frame.broadcast:Enable()
end

-- Close
function man:Close()
	self.frame:Close()
	dewdrop:Close()
end

-- Unlock
function man:Unlock()
	local any
	for palaName,pala in pairs(self.pala) do
		if (not pala.canEdit or not pala.gotCapabilities) then
			pala.gotCapabilities = true
			pala.canEdit = true
			any = true
		end
	end
	if (any) then
		if (self.frame and self.frame:IsOpen()) then
			self:DrawAll()
		end
	end
end

-- Unlock
function man:NoneLocked()
	for palaName,pala in pairs(self.pala) do
		if (not pala.gotCapabilities) then
			return false
		end
	end
	return true
end

-- Send
function man:Send(type, name)
	if (type == "template") then
		if (template) then
			z:SendComm(name, "GIVEMASTERTEMPLATE", template)
		end
	else
		local codes = self.db.profile.playerCodes
		if (codes) then
			z:SendComm(name, "GIVESUBCLASSES", codes)
		end
	end
end

-- IsGuildMember
function man:IsGuildMember(find)
	for i = 1,GetNumGuildMembers(true) do
		local name, rank, rankIndex, level, class, zone, note, officernote, online = GetGuildRosterInfo(i)
		if (name == find) then
			return i, online, rank
		end
	end
end

-- Clean
function man:Clean(mode)		-- guild or raid
	local cleaned = 0
	local codes = self.db.profile.playerCodes
	if (codes) then
		for class,list in pairs(codes) do
			for name,code in pairs(list) do
				if (mode == "guild") then
					if (not self:IsGuildMember(name)) then
						list[name] = nil
						cleaned = cleaned + 1
					end

				elseif (mode == "raid") then
					if (not UnitInRaid(name) and not UnitInParty(name)) then
						list[name] = nil
						cleaned = cleaned + 1
					end
				end
			end
		end
	end

	self:SplitColumnDrawAll()

	self:Print(L["Cleaned %d players from the stored sub-class list"], cleaned)
end

-- GetClassBuffs
function man:GetShouldHaveBuffs(playerName, playerClass)
	-- Get list of buff types for a class
	local ret = new()

	if (self.paladinOrder) then
		for i,name in ipairs(self.paladinOrder) do
			local pala = self.pala[name]
			if (pala) then
				local single = pala.template[playerName]
				if (single) then
					ret[i] = new(1, single)
				else
					local group = pala.template[playerClass]
					if (group) then
						ret[i] = new(2, group)
					else
						ret[i] = new(0)
					end
				end
			end
		end
	end

	return ret
end

-- OnReceiveCapability
function man:OnReceiveCapability(sender, cap)
	if (not cap or select(2, UnitClass(sender)) ~= "PALADIN") then
		return
	end

	if (type(cap.impWisdom) ~= "number") then
		cap.impWisdom = cap.impWisdom and 2 or 0
	end
	if (type(cap.impMight) ~= "number") then
		cap.impMight = cap.impMight and 5 or 0
	end

	self:AssignPaladins()

	local psender = self.pala and self.pala[sender]
	if (psender) then
		psender.canKings = true
		psender.canSanctuary = cap.canSanctuary		-- true/nil
		psender.improvedMight = cap.impMight			-- 0 - 5
		psender.improvedWisdom = cap.impWisdom		-- 0 - 2
		psender.improvedDevotion = cap.improvedDevotion
		psender.improvedConcentration = cap.improvedConcentration
		psender.improvedRetribution = cap.improvedRetribution
		self.pala[sender].gotCapabilities = true
	end

	if (self.frame and self.frame:IsOpen()) then
		self:DrawAll()
	end
end

-- OnReceiveSpec
function man:OnReceiveSpec(sender, spec)
	if (self.pala and self.pala[sender]) then
		self.pala[sender].spec = spec			-- { n, n, n }
		self:DrawPaladinByName(sender)
	end
	self:SplitColumnDrawAll()
end

-- OnSelectTemplate
function man:OnSelectTemplate()
	template = self.db.profile.templates.current
	if (not template) then
		if (not self.db.profile.templates[L["Default"]]) then
			self.db.profile.templates[L["Default"]] = DefaultTemplate()
			self:SelectTemplate(L["Default"])
		end
	end
	self:ValidateTemplate(template)

	self:AssignPaladins()

	if (self.frame and self.frame:IsOpen()) then
		self:DrawAll()
	end
end

-- ValidateSubClassTemplate
function man:ValidateSubClassTemplate(list)
	for i = #list,1,-1 do
		if (list[i] == "BOL" or list[i] == "BOS") then
			tremove(list, i)
		end
	end
end

-- ValidateTemplate
function man:ValidateTemplate(template)
	for class, buffs in pairs(template) do
		if (class ~= "modified" and class ~= "state" and class ~= "subclass") then
			self:ValidateSubClassTemplate(buffs)
		end
	end

	for class, list in pairs(template.subclass) do
		for class, codes in pairs(list) do
			self:ValidateSubClassTemplate(codes)
		end
	end

	local defTemp
	for i,class in pairs(classOrder) do
		if (not template[class]) then
			if (not defTemp) then
				defTemp = DefaultTemplate()
			end
			template[class] = copy(defTemp[class])
		end
	end
	deepDel(defTemp)
end

-- OnModifyTemplate
function man:OnModifyTemplate(key, value)
--[===[@debug@
	self:argCheck(key, 1, "string")
	self:argCheck(value, 2, "string", "nil")
--@end-debug@]===]
end

-- OnReceiveAck
function man:OnReceiveAck(sender)
	if (self.pala and self.pala[sender]) then
		self.pala[sender].waitingForAck = nil
		self:DrawPaladinByName(sender)
	elseif (z.db.profile.info) then
		self:Print("Unexpected ACK from %s", z:ColourUnitByName(sender))
	end
end

-- OnReceiveAck
function man:OnReceiveNack(sender, retry)
	if (self.pala and self.pala[sender]) then
		self.pala[sender].waitingForAck = nil
		self:DrawPaladinByName(sender)
		if (retry) then
			self:Print("Failed to send template to %s, retrying...", z:ColourUnitByName(sender))
			self:GiveTemplate(sender, false, false, true)
		end
	end
end

-- OnRaidRosterUpdate
function man:OnRaidRosterUpdate()
	local newPalas = new()
	local oldPalas = new()
	local anyCameOnline

	if (GetNumPartyMembers() == 0 and GetNumRaidMembers() == 0) then
		self.whoGenerated = nil
		self:DoTitle()
		
		if (self.wasInGroup) then
			self.wasInGroup = nil
			self.whoGenerated = nil
		end
	else
		if (not self.wasInGroup) then
			self.wasInGroup = true
			self.whoGenerated = nil
		end
	end

	self:SetSelf()

	if (not self.pala) then
		self:AssignPaladins()
	end

	for name,v in pairs(self.pala) do
		oldPalas[name] = true
	end

	for unit, unitname, unitclass, subgroup, index in z:IterateRoster() do
		if (unitclass == "PALADIN" and subgroup <= self.db.profile.groups) then
			if (oldPalas[unitname]) then
				oldPalas[unitname] = nil
			else
				newPalas[unitname] = true
			end

			local pala = self.pala[unitname]
			if (pala) then
				if (UnitIsConnected(unit)) then
					if (pala.offline) then
						pala.offline = nil
						anyCameOnline = true
					end
				else
					if (not pala.offline) then
						pala.offline = true
						self:DrawPaladinByName(unitname)
					end
				end
			end
		end
	end

	if (next(oldPalas) or next(newPalas)) then
		if (next(newPalas)) then
			local any
			for name in pairs(newPalas) do
				if (not z.versionRoster[name] or type(z.versionRoster[name]) ~= "number") then
					any = true
					break
				end
			end

			if (any) then
				-- If there's any PallyPower users, they should respond immediately to the 'REQ'
				local dist
				if (select(2, IsInInstance()) == "pvp") then
					dist = "BATTLEGROUND"
				elseif (GetNumRaidMembers() > 0) then
					dist = "RAID"
				elseif (GetNumPartyMembers() > 0) then
					dist = "PARTY"
				end
				SendAddonMessage("PLPWR", "ZOMG", dist)
				SendAddonMessage("PLPWR", "REQ", dist)
			end
		end

		self:AssignPaladins()
		if (self.frame and self.frame:IsOpen()) then
			self:DrawAll()
		end
	elseif (anyCameOnline) then
		self:ScheduleEvent("ZOMGBlessings_AssignPaladins", self.AssignPaladins, 5, self)
	end

	if (self.frame) then
		if (self:TalentsMissingFromSelectedGroups()) then
			self.frame.autoroles:Disable()
		else
			self.frame.autoroles:Enable()
		end
	end

	self:DrawClassCounts()
	self:SplitPopulate()

	del(oldPalas)
	del(newPalas)
end

-- DrawClassCounts
function man:DrawClassCounts()
	if (self.frame and self.frame:IsOpen()) then
		for k,v in pairs(classOrder) do
			local cell = self.frame.classTitle.cell[k]
			local count = z.classcount[v]
			if (count == 0) then
				cell.classcount:Hide()
			else
				cell.classcount:Show()
				cell.classcount:SetText(count)
			end
		end
	end
end

--function man:RosterUnitChanged(newID, newName, newClass, newGroup, newRank, oldName, oldID, oldClass, oldGroup, oldRank)
--	if (self.frame and self.frame:IsVisible()) then
--		if (newClass == "PALADIN" or oldClass == "PALADIN") then
--			self:AssignPaladins()
--			if (self.frame and self.frame:IsOpen()) then
--				self:DrawAll()
-- 			end
--		end
--	end
--end

-- ChatConvertBlessing
function man:ChatConvertBlessing(code)
	code = strlower(code)
	if (code == L["bow"] or code == L["wisdom"] or code == L["wis"]) then
		return "BOW"
	elseif (code == L["bom"] or code == L["might"]) then
		return "BOM"
	elseif (code == L["san"] or code == L["sanc"] or code == L["sanctuary"]) then
		return "SAN"
	elseif (code == L["bok"] or code == L["kings"] or code == L["king"]) then
		return "BOK"
	end
end

-- ChatReplaceBuff(minus, plus)
function man:ChatReplaceBuff(sender, Minus, Plus)
	if (not UnitInRaid(sender) and not UnitInParty(sender)) then
		return
	end

	if (not self.db.profile.remotechanges) then
		SendChatMessage(format(L["%s Remote control of buff settings is not enabled"], z.chatAnswer), "WHISPER", nil, sender)
		return
	end

	if (playerClass ~= "PALADIN" and not IsRaidLeader() and not IsRaidOfficer()) then
		SendChatMessage(format(L["%s %s is not allowed to do that"], z.chatAnswer, UnitName("player")), "WHISPER", nil, sender)
		return
	end

	local minus = self:ChatConvertBlessing(Minus)
	if (not minus) then
		SendChatMessage(format(L["%s Could not interpret %s"], z.chatAnswer, "-"..Minus), "WHISPER", nil, sender)
		return
	end
	local plus = self:ChatConvertBlessing(Plus)
	if (not plus) then
		SendChatMessage(format(L["%s Could not interpret %s"], z.chatAnswer, "+"..Plus), "WHISPER", nil, sender)
		return
	end

	local _, senderclass = UnitClass(sender)
	for i,paladinName in ipairs(self.paladinOrder) do
		local pala = self.pala[paladinName]
		if (pala) then
			local blessingType = pala.template[sender] or pala.template[senderclass]
			if (blessingType == minus) then
				local oldClassBuff = pala.template[senderclass]
				local targetString

				if (z.classcount[senderclass] == 1) then
					-- Only one of the requesting class, so set the class buff
					targetString = z:ColourClass(senderclass)
					z:Log("man", sender, "change", paladinName, senderclass, pala.template[senderclass], plus, true)
					pala.template[sender] = nil
					pala.template[senderclass] = plus
				else
					if (plus ~= oldClassBuff) then
						-- Set a single exception for this buff
						targetString = z:ColourUnitByName(sender)
						z:Log("man", sender, "exception", paladinName, sender, pala.template[sender], plus, true)
						pala.template[sender] = plus
					else
						-- It's being set to the same as the class buff, so just remove the exception
						targetString = z:ColourClass(senderclass)
						z:Log("man", sender, "change", paladinName, senderclass, pala.template[senderclass], plus, true)
						pala.template[sender] = nil
					end
				end

				self:GiveTemplate(paladinName, true, true)
				if (z.db.profile.info) then
					self:Print(format(L["Assigned %s to buff %s on %s (by request of %s)"], z:ColourUnitByName(paladinName), z:ColourBlessing(plus), targetString, z:ColourUnitByName(sender)))
				end

				local singleBuff, classBuff = z:GetBlessingFromType(blessingType)
				local buff = (pala.template[sender] and singleBuff) or classBuff
				local spellName = z:GetBlessingFromType(plus)
				SendChatMessage(format(L["%s Assigned %s to %s"], z.chatAnswer, GetSpellLink and GetSpellLink(spellName) or spellName, paladinName), "WHISPER", nil, sender)
				return
			end
		end
	end

	local spellName = z:GetBlessingFromType(minus)
	SendChatMessage(format(L["%s You don't get %s from anyone"], z.chatAnswer, GetSpellLink and GetSpellLink(spellName) or spellName), "WHISPER", nil, sender)
end

-- BuffResponse
function man:BuffResponse(sender, msg)
	if (not UnitInRaid(sender) and not UnitInParty(sender)) then
		-- Only reply to people in raid/party
		return
	end

	if (not self.paladinOrder or not self.pala) then
		if (not self.replyQueue) then
			self.replyQueue = {}
		end
		self.replyQueue[sender] = msg
		return
	end

	local _, unitclass = UnitClass(sender)
	
	local showSyntax
	if (not msg or msg == "") then
		SendChatMessage(format(L["%s Your Paladin buffs come from:"], z.chatAnswer), "WHISPER", nil, sender)

		for i,paladinName in ipairs(self.paladinOrder) do
			local pala = self.pala[paladinName]
			if (pala) then
				local blessingType = pala.template[sender] or pala.template[unitclass]
				if (blessingType) then
					local singleBuff = z:GetBlessingFromType(blessingType)
					if (singleBuff) then
						SendChatMessage(format("%s %s - %s", z.chatAnswer, GetSpellLink and GetSpellLink(singleBuff) or singleBuff, paladinName), "WHISPER", nil, sender)
					end
				end
			end
		end
	elseif (msg == "?" or strlower(msg) == L["CHATHELP"]) then
		showSyntax = true
	else
		-- -bow +bom			-- Wants to have bom instead of bow
		local one, two = strmatch(msg, "([-\+%a]+) +([-\+%a]+)")
		if (one and two) then
			local plus, minus

			if (strsub(one, 1, 1) == "+") then
				plus = one
				minus = two
			elseif (strsub(two, 1, 1) == "+") then
				plus = two
				minus = one
			end
			if (plus and minus) then
				if (strsub(minus, 1, 1) == "-") then
					self:ChatReplaceBuff(sender, strsub(minus, 2), strsub(plus, 2))
				else
					showSyntax = true
				end
			else
				showSyntax = true
			end
		else
			showSyntax = true
		end
	end

	if (showSyntax) then
		local i = 1
		while (true) do
			if (not L:HasTranslation("CHATHELPRESPONSE"..i)) then
				break
			end
			SendChatMessage(format("%s %s", z.chatAnswer, L["CHATHELPRESPONSE"..i]), "WHISPER", nil, sender)
			i = i + 1
		end
	end
end

-- AceDB20_ResetDB
function man:OnResetDB()
	self:OnSelectTemplate()
end

-- OnEnable
function man:OnModuleEnable()
	self:OnResetDB()
	self:RegisterEvent("PARTY_MEMBERS_CHANGED", "ValidatePP")

	LGT.RegisterCallback(self, "LibGroupTalents_Update")
end

-- OnDisable
function man:OnModuleDisable()
	self:Close()
	if (self.splitframe) then
		self.splitframe:SetScript("OnUpdate", nil)
		self:SplitExpand("reset")
	end
end

-- Help
function man:Help(n)
	local helpFrame = z:GetHelpFrame()
	helpFrame:SetHelp(L["HELP_TITLE"], L["HELP_TEXT"])
end
