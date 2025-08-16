--[[
Name: ZFrame-1.0
Revision: $Revision: 2 $
Author(s): Zek (zeksie@ntlworld.com)
Description: A simple window library. Gives you the usable area inside the border to anchor with to save messing around with variable border sizes and calcs in main code.
Dependencies: Ace2
License: LGPL v2.1

The returned frame is the usable area you are interested in to place items into, rather than the whole frame.
Setting the size of your area is then easy as it automatically makes the whole size larger.
]]

local CLICKTOSCALE, ALTCLICKTOSIZE

CLICKTOSCALE		= "Click to scale window"
ALTCLICKTOSIZE		= "Alt-Click to size window"

--if (GetLocale() == "deDE") then
--	CLICKTOSCALE	=
--	ALTCLICKTOSIZE	=
--end

local MAJOR_VERSION = "ZFrame-1.0"
local MINOR_VERSION = "$Revision: 2 $"

if not LibStub then error(MAJOR_VERSION .. " requires LibStub") end
local ZFrame, oldLib = LibStub:NewLibrary(MAJOR_VERSION, MINOR_VERSION)
if (not ZFrame) then
	return
end

local scaleIndication

local function scaleMouseDown(self)

	GameTooltip:Hide()

	if (self.resizable and IsAltKeyDown()) then
		self.sizing = true
	elseif (self.scalable) then
		self.scaling = true
	end

	if (not scaleIndication) then
		scaleIndication = CreateFrame("Frame", nil, UIParent)
		scaleIndication:SetWidth(100)
		scaleIndication:SetHeight(18)
		scaleIndication.text = scaleIndication:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		scaleIndication.text:SetAllPoints()
		scaleIndication.text:SetJustifyH("LEFT")
	end

	scaleIndication:Show()
	scaleIndication:ClearAllPoints()
	scaleIndication:SetPoint("LEFT", self, "RIGHT", 4, 0)

	if (self.scaling) then
		scaleIndication.text:SetText(format("%.1f%%", self.frame:GetScale() * 100))
	else
		scaleIndication.text:SetText(format("%dx%d", self.frame:GetWidth(), self.frame:GetHeight()))
	end

	self.anchor:StartSizing()

	self.oldBdBorder = {self.frame:GetBackdropBorderColor()}
	self.frame:SetBackdropBorderColor(1, 1, 0.5, 1)
end

local function zSwitchAnchor(self, new)
	local a = self.anchor
	if (not a:GetPoint(2)) then
		local a1, f, a2, x, y = a:GetPoint(1)

		if (a1 == a2 and new ~= a1) then
			local parent = a:GetParent()
			local newV = strmatch(new, "TOP") or strmatch(new, "BOTTOM")
			local newH = strmatch(new, "LEFT") or strmatch(new, "RIGHT")

			if (newV == "TOP") then
				y = -(768 - (a:GetTop() * a:GetEffectiveScale())) / a:GetEffectiveScale()
			elseif (newV == "BOTTOM") then
				y = a:GetBottom()
			else
				y = a:GetBottom() + a:GetHeight() / 2
			end

			if (newH == "LEFT") then
				x = a:GetLeft()
			elseif (newV == "RIGHT") then
				x = a:GetRight()
			else
				x = a:GetLeft() + a:GetWidth() / 2
			end

			a:ClearAllPoints()
			a:SetPoint(new, f, new, x, y)
		end
	end
end

local function scaleMouseUp(self)
	self.anchor:StopMovingOrSizing()

	scaleIndication:Hide()

	if (self.scaling) then
		if (self.onScaleChanged) then
			self:onScaleChanged(self.frame:GetScale())
		elseif (self.onSizeChanged) then
			self:onSizeChanged(self.frame:GetWidth(), self.frame:GetHeight())
		end
	end

	self.area:SavePosition()
	zSwitchAnchor(self, "TOPLEFT")

	if (self.oldBdBorder) then
		self.frame:SetBackdropBorderColor(unpack(self.oldBdBorder))
		self.oldBdBorder = nil
	end

	self.scaling = nil
	self.sizing = nil
end

local function scaleMouseChange(self)
	if (self.corner.sizing) then
		self.corner.frame:SetWidth(self:GetWidth() / self.corner.frame:GetScale())
		self.corner.frame:SetHeight(self:GetHeight() / self.corner.frame:GetScale())

		self.corner.startSize.w = self.corner.frame:GetWidth()
		self.corner.startSize.h = self.corner.frame:GetHeight()

		if (scaleIndication and scaleIndication:IsShown()) then
			scaleIndication.text:SetText(format("|c00FFFF80%d|c00808080x|c00FFFF80%d", self.corner.frame:GetWidth(), self.corner.frame:GetHeight()))
		end

	elseif (self.corner.scaling) then
		local w = self:GetWidth()
		if (w) then
			self.corner.scaling = nil
			local ratio = self.corner.frame:GetWidth() / self.corner.frame:GetHeight()
			local s = min(self.corner.maxScale, max(self.corner.minScale, w / self.corner.startSize.w))	-- New Scale

			w = self.corner.startSize.w * s		-- Set height and width of anchor window to match ratio of actual
			self:SetWidth(w)
			self:SetHeight(w / ratio)

			if (scaleIndication and scaleIndication:IsShown()) then
				scaleIndication.text:SetText(format("%.1f%%", s * 100))
			end

			self.corner.frame:SetScale(s)
			self.corner.scaling = true
		end
	end
end

-- scaleMouseEnter
local function scaleMouseEnter(self)
	self.tex:SetVertexColor(1, 1, 1, 1)
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	if (self.scalable) then
		GameTooltip:SetText(CLICKTOSCALE, nil, nil, nil, nil, 1)
	end
	if (self.resizable) then
		GameTooltip:AddLine(ALTCLICKTOSIZE, nil, nil, nil, 1)
	end
	GameTooltip:Show()
end

-- scaleMouseLeave
local function scaleMouseLeave(self)
	self.tex:SetVertexColor(1, 1, 1, 0.5)
	GameTooltip:Hide()
end

local function zIsShown(self)
	local main = self.ZMain
	if (main) then
		return main.anchor:IsShown()
	else
		error("No ZMain")
	end
end

local function zHide(self)
	local main = self.ZMain
	if (main) then
		main.anchor:Hide()
		if (self.OnClose) then
			self:OnClose()
		end
	else
		error("No ZMain")
	end
end

local function zShow(self)
	local main = self.ZMain
	if (main) then
		main.anchor:Show()
		if (self.OnOpen) then
			self:OnOpen()
		end
	else
		error("No ZMain")
	end
end

local function zSetSize(self, w, h)
	local main = self.ZMain
	if (main) then
		-- Add extra for our borders
		w = w + 10
		h = h + 40

		main.anchor:SetWidth(w * main:GetScale())
		main.anchor:SetHeight(h * main:GetScale())

		main.corner.startSize = {["w"] = w, ["h"] = h}
		main:SetWidth(w)
		main:SetHeight(h)

		self:SavePosition()
		if (self.OnResize) then
			self:OnResize()
		end
	else
		error("No ZMain")
	end
end

local function zRestorePosition(self)
	local main = self.ZMain
	if (main) then
		local pos = main.handler and main.handler.db and main.handler.db.char and main.handler.db.char.position
		if (pos) then
			local name = main.title and main.title:GetText():gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
			if (name) then
				pos = pos[name]
				if (pos) then
					main.anchor:ClearAllPoints()
					main.anchor:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", pos.left, pos.top)
					main:SetScale(pos.scale or 1)
					if (main.anchor:IsResizable() and pos.width and pos.height) then
						main.anchor:SetWidth(pos.width)
						main.anchor:SetHeight(pos.height)
					end
					if (self.OnResize) then
						self:OnResize()
					end
				end
			end
		end
	end
end

local function zSavePosition(self)
	local main = self.ZMain
	if (main) then
		local db = main.handler and main.handler.db and main.handler.db.char
		if (db) then
			local name = main.title:GetText():gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
			if (name) then
				if (not db.position) then
					db.position = {}
				end
				db.position[name] = {left = main.anchor:GetLeft(), top = main.anchor:GetTop(), scale = main:GetScale()}
				if (main.anchor:IsResizable()) then
					db.position[name].width = main.anchor:GetWidth()
					db.position[name].height = main.anchor:GetHeight()
				end
			end
		end
	else
		error("No ZMain")
	end
end

local function zSetTitle(self, title)
	local main = self.ZMain
	if (main) then
		main.title:SetText(title)
	else
		error("No ZMain")
	end
end

local function zCloseButton(self)
	self.ZMain.area:Close()
end

local function zStartMoving(self)
	local dewdrop = LibStub("Dewdrop-2.0", true)
	if (dewdrop) then
		dewdrop:Close()
	end

	if (not self.onStartMoving or self.onStartMoving(self.handler, self.area)) then
		self.anchor:StartMoving()
		if (self.OnStartMoving) then
			self:OnStartMoving()
		end
	end
end

local function zStopMoving(self)
	self.anchor:StopMovingOrSizing()
	zSwitchAnchor(self, "TOPLEFT")
	self.area:SavePosition()

	if (self.onStopMoving) then
		self.onStopMoving(self.handler, self.area)
		if (self.OnStopMoving) then
			self:OnStopMoving()
		end
	end
end

-- zOnMouseUp
local function zOnMouseUp(self, button)
	if (self.area.OnClick) then
		self.area:OnClick(button)
	end
end

local function zSetSizable(self, opt)
	self.ZMain.corner.resizable = opt
end

local function zSetScalable(self, opt)
	self.ZMain.corner.scalable = opt
end

function ZFrame:Create(handler, titleText, name, r, g, b)
	local anchor = CreateFrame("Frame", name and name.."Anchor", UIParent)
	anchor:SetPoint("CENTER")
	anchor:SetMovable(true)
	anchor:SetResizable(true)
	anchor:SetClampedToScreen(true)
	anchor:SetClampRectInsets(0, 0, -12, 0)
	anchor:SetMinResize(30, 20)

	local main = CreateFrame("Frame", name and name.."Parent", anchor)
	main:SetPoint("TOPLEFT")
	main:EnableMouse(true)
	main:RegisterForDrag("LeftButton")
	main:SetScript("OnDragStart", zStartMoving)
	main:SetScript("OnDragStop", zStopMoving)
	main:SetScript("OnMouseUp", zOnMouseUp)
	main:SetFrameStrata("HIGH")

	main:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = true, tileSize = 16,
		edgeFile = "Interface\\AddOns\\ZOMGBuffs\\Textures\\otravi-semi-full-border-grey", edgeSize = 32,
		insets = {left = 1, right = 1, top = 20, bottom = 1},
	})
	main:SetBackdropColor(0, 0, 0, 1)
	if (r and g and b) then
		main:SetBackdropBorderColor(r, g, b, 1)
	else
		main:SetBackdropBorderColor(1, 0.8, 0, 1)
	end

	local close = CreateFrame("Button", name and name.."CloseButton", main, "UIPanelCloseButton")
	close:SetPoint("TOPRIGHT", 1, -9)
	close:SetWidth(24)
	close:SetHeight(24)
	close:SetScript("OnClick", zCloseButton)

	local corner = CreateFrame("Frame", name and name.."Corner", main)
	corner:SetScript("OnMouseDown", scaleMouseDown)
	corner:SetScript("OnMouseUp", scaleMouseUp)
	corner:SetScript("OnEnter", scaleMouseEnter)
	corner:SetScript("OnLeave", scaleMouseLeave)
	corner:EnableMouse(true)
	corner:SetHeight(12)
	corner:SetWidth(12)
	corner.tex = corner:CreateTexture(nil, "BORDER")
	corner.tex:SetTexture("Interface\\AddOns\\ZOMGBuffs\\Textures\\Elements")
	corner.tex:SetAllPoints()
	corner.tex:SetVertexColor(1, 1, 1, 0.5)
	corner.tex:SetTexCoord(0.78125, 1, 0.78125, 1)
	corner:SetPoint("BOTTOMRIGHT", -1, 1)
	corner:SetHitRectInsets(-2, -2, -2, -2)		-- So the click area extends over the tooltip border

	local title = main:CreateFontString(nil, "BORDER", "GameFontNormal")
	title:SetPoint("TOPLEFT", 5, -5)
	title:SetPoint("BOTTOMRIGHT", main, "TOPRIGHT", -5, -35)
	title:SetJustifyH("LEFT")
	title:SetText(titleText)
	title:SetTextColor(1, 1, 1)

	local area = CreateFrame("Frame", name, main)
	area:SetPoint("TOPLEFT", 5, -35)
	area:SetPoint("BOTTOMRIGHT", -5, 5)

	anchor.corner = corner
	anchor:SetScript("OnSizeChanged", scaleMouseChange)

	main.title = title
	main.close = close
	main.corner = corner
	main.area = area
	main.anchor = anchor
	main.handler = handler

	corner.handler = handler
	corner.area = area
	corner.main = main
	corner.frame = main
	corner.anchor = anchor

	main.zframe = self
	area.zframe = self
	close.zframe = self
	corner.zframe = self

	area.ZMain = main
	close.ZMain = main
	corner.ZMain = main

	area.Close = zHide					-- Hide
	area.Open = zShow					-- Show
	area.IsOpen = zIsShown
	area.SetSize = zSetSize					-- SetSize(height, width) - set size of area you need, window is made x/y bigger for border.
	area.SavePosition = zSavePosition
	area.RestorePosition = zRestorePosition
	area.SetTitle = zSetTitle				-- SetTitle(title)
	area.SetSizable = zSetSizable				-- SetSizable(bool) - Can it be sized?
	area.SetScalable = zSetScalable				-- SetScalable(bool) - Can it be scaled?
	area.SwitchAnchor = zSwitchAnchor

	-- Options
	corner.resizable = nil
	corner.scalable = true
	corner.maxScale = 2
	corner.minScale = 0.3
	corner.startSize = {w = 0, h = 0}

	area:RestorePosition()

	return area
end
