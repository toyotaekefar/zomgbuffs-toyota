if (ZOMGLog) then
	ZOMGBuffs:Print("Installation error, duplicate copy of ZOMGBuffs_Log (Addons\ZOMGBuffs\ZOMGBuffs_Log and Addons\ZOMGBuffs_Log)")
	return
end

local L = LibStub("AceLocale-2.2"):new("ZOMGLog")
local ZFrame

local z = ZOMGBuffs
local mod = z:NewModule("ZOMGLog")
ZOMGLog = mod

z:CheckVersion("$Revision: 32 $")

local new, del, deepDel, copy = z.new, z.del, z.deepDel, z.copy

local function getOption(v)
	return mod.db.profile[v]
end

local function setOption(v, n)
	mod.db.profile[v] = n
end

mod.consoleCmd = L["Log"]
mod.options = {
	type = "group",
	order = 50,
	name = "|cFFFF8080Z|cFFFFFF80O|cFF80FF80M|cFF8080FFG|rLog",
	desc = L["Event Logging"],
	disabled = function() return z:IsDisabled() end,
	handler = mod,
	args = {
		open = {
			type = "execute",
			name = L["Open"],
			desc = L["View the log"],
			hidden = function() return not mod:IsModuleActive() end,
			func = "Open",
			order = 1,
		},
		clear = {
			type = "execute",
			name = L["Clear"],
			desc = L["Clear the log"],
			hidden = function() return not mod:IsModuleActive() end,
			func = "Clear",
			order = 2,
		},
		behaviour = {
			type = "group",
			name = L["Behaviour"],
			desc = L["Log behaviour"],
			order = 201,
			hidden = function() return not mod:IsModuleActive() end,
			args = {
				clear = {
					type = "toggle",
					name = L["Merge"],
					desc = L["Merge similar entries within 15 seconds. Avoids confusion with cycling through buffs to get to desired one giving multiple log entries."],
					get = getOption,
					set = setOption,
					passValue = "merge",
					order = 1,
				},
			},
		},
	},
}
mod.moduleOptions = mod.options

-- Register
function mod:Register(code, decodeFunc)
	self.registeredDecodes[code] = decodeFunc
end

-- TidyLog
function mod:TidyLog()
	local log = self.db.profile.log
	local index = #log - 1
	while (index > 0) do
		local log1 = log[index]
		local log2 = log[index + 1]
		if (not log1 or not log2) then
			return
		end

		if (log1[1] == log2[1] and log1[3] == log2[3] and log1[4] == log2[4] and log1[5] == log2[5] and log1[6] == log2[6]) then
			-- Same mod, same person, type, target

			if (log1[4] == "change" or log1[4] == "exception") then
				if (log1[2] - 15 < log2[2]) then
					-- change within 15 seconds of comparison
					log1[7] = log2[7]
					tremove(log, 2)
				end

				if (log1[7] == log1[8]) then
					-- No actual change, just cycled thru them all
					tremove(log, 1)
				end
			end
		end
		index = index - 1
	end
end

-- ActualAdd
function mod:ActualAdd(event)
	local log = self.db.profile.log
	tinsert(log, 1, event)

	self:TidyLog()

	while (#log > self.db.profile.max) do
		tremove(log, #log)
	end

	self:DrawLog()
end

-- OnReceiveEvent
function mod:OnReceiveEvent(event)
	if (self:IsModuleActive()) then
		self:ActualAdd(event)
	end
end

-- GetString
function mod:GetString(index)
	local a = self.db.profile.log[index]
	if (a and a[1] and self.registeredDecodes[a[1]]) then
		local lineColour = "|cFFFFFFFF"
		if (a[1] == "bless") then
			lineColour = "|cFFFF8080"
		end
		return format("%s%s|r %s> %s", lineColour, date("%X",a[2]), z:ColourUnitByName(a[3], true), self.registeredDecodes[a[1]](select(4, unpack(a))))
	end
end

-- CreateLogFrame
function mod:CreateLogFrame()
	ZFrame = LibStub("ZFrame-1.0")

	local logFrame = ZFrame:Create(self, "|cFFFF8080Z|cFFFFFF80O|cFF80FF80M|cFF8080FFG|cFFFFFFFFLog|r", "Log", 1, 0.7, 0)
	self.logFrame = logFrame

	logFrame:SetSize(580, 280)
	logFrame:RestorePosition()

	logFrame.line = {}

	local scrollBar = CreateFrame("ScrollFrame", "ZOMGLogScrollFrame", logFrame, "FauxScrollFrameTemplate")
	logFrame.scrollBar = scrollBar
	scrollBar:SetPoint("TOPLEFT", 0, 0)
	scrollBar:SetPoint("BOTTOMRIGHT", -25, 0)

	scrollBar.slider = ZOMGLogScrollFrameScrollBar

	-- Fix the odd slider graphic bug not hitting the ends:
	scrollBar.slider:GetThumbTexture():SetTexCoord(0.23, 0.75, 0.27, 0.73)
	scrollBar.slider:GetThumbTexture():SetHeight(16)

	scrollBar:SetScript("OnVerticalScroll", function() mod:DrawLog() end)
	scrollBar:SetScript("OnMouseWheel",
		function(self, delta)
			self.slider:SetValue(self.slider:GetValue() - delta)
			mod:DrawLog()
		end)

	local prev
	for i = 1,20 do
		local line = logFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		if (i == 1) then
			line:SetPoint("TOPLEFT")
			line:SetPoint("BOTTOMRIGHT", logFrame, "TOPRIGHT", 0, -14)
		else
			line:SetPoint("TOPLEFT", prev, "BOTTOMLEFT")
			line:SetPoint("BOTTOMRIGHT", prev, "BOTTOMRIGHT", 0, -14)
		end
		line:SetJustifyH("LEFT")
		line:SetTextColor(0.9, 0.9, 0.9)

		logFrame.line[i] = line

		prev = line
	end

	logFrame.OnOpen = function() mod:DrawLog() end

	self.CreateLogFrame = nil
	return logFrame
end

-- Open
function mod:Open()
	local logFrame = self.logFrame
	if (not logFrame) then
		logFrame = self:CreateLogFrame()
		self:DrawLog()
	else
		if (logFrame:IsOpen()) then
			logFrame:Close()
		else
			logFrame:Open()
		end
	end
end

-- Clear
function mod:Clear()
	del(self.db.profile.log)
	self.db.profile.log = new()
	self:DrawLog()
end

-- DrawLog
function mod:DrawLog()
	local logFrame = self.logFrame
	if (not logFrame or not logFrame:IsOpen()) then
		return
	end

	local a = self.db.profile.log

	local scrollFrame = self.logFrame.scrollBar
	
	if (a) then
		local offset
		if (#a > 20) then
			offset = max(0, min(#a - 20, floor(scrollFrame.slider:GetValue())))
			scrollFrame.slider:SetMinMaxValues(0, #a - 20)
			scrollFrame.slider:SetValue(offset)
			scrollFrame:Show()
		else
			offset = 0
			scrollFrame:Hide()
		end
	
		for i = 1,20 do
			local line = logFrame.line[i]
			local text = self:GetString(i + offset)
			if (not text) then
				line:Hide()
			else
				line:Show()
				line:SetText(text)
			end
		end
	else
		scrollFrame:Hide()
		self.logFrame.line[1]:SetText("Nothing to show")
		self.logFrame.line[1]:Show()
		for i = 2,20 do
			self.logFrame.line[i]:Hide()
		end
	end
end

-- OnModuleInitialize
function mod:OnModuleInitialize()
	self.db = z:AcquireDBNamespace("Log")
	z:RegisterDefaults("Log", "profile", {
		log = {},
		max = 100,
		merge = true,
	} )
	z:RegisterChatCommand({"/zomglog"}, self.options)
	self.OnMenuRequest = self.options
	z.options.args.ZOMGLog = self.options

	z.OnCommReceive.EVENT = function(self, prefix, sender, channel, event)
		mod:OnReceiveEvent(event)
	end

	self.OnModuleInitialize = nil
end

-- OnModuleEnable
function mod:OnModuleEnable()
	self.registeredDecodes = {}

	self:Register("bless",
		function(code, a, b, c, d)
			if (code == "change") then
				return format(L["Changed %s's template - %s from %s to %s"], z:ColourUnitByName(a), z:ColourClass(b), (c and z:ColourBlessing(c,nil,true)) or "none", (d and z:ColourBlessing(d,nil,true)) or "none")
			elseif (code == "exception") then
				return format(L["Changed %s's exception - %s from %s to %s"], z:ColourUnitByName(a), z:ColourUnitByName(b), (c and z:ColourBlessing(c,nil,true)) or "none", (d and z:ColourBlessing(d,nil,true)) or "none")
			elseif (code == "select") then
				return format(L["Loaded template '%s'"], tostring(a))
			elseif (code == "save") then
				return format(L["Saved template '%s'"], tostring(a))
			end
		end
	)

	self:Register("man",
		function(code, a, b, c, d, remote)
			if (code == "gen") then
				return format(L["Generated automatic template"])
			elseif (code == "change") then
				return format(L["%s %s's template - %s from %s to %s"], remote and L["Remotely changed"] or L["Changed"], z:ColourUnitByName(a), z:ColourClass(b), (c and z:ColourBlessing(c,nil,true)) or "none", (d and z:ColourBlessing(d,nil,true)) or "none")
			elseif (code == "exception") then
				return format(L["%s %s's exception - %s from %s to %s"], remote and L["Remotely changed"] or L["Changed"], z:ColourUnitByName(a), z:ColourUnitByName(b), (c and z:ColourBlessing(c,nil,true)) or "none", (d and z:ColourBlessing(d,nil,true)) or "none")
			elseif (code == "clearcell") then
				return format(L["Cleared %s's exceptions for %s"], z:ColourUnitByName(a), z:ColourClass(b))
			end
		end
	)
end

-- OnModuleDisable
function mod:OnModuleDisable()
	registeredModules = nil
	registeredCodes = nil
end
