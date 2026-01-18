-- Color scheme - Black/Slate with Orange accents
GUI_COLORS = {
	bg = { 0.06, 0.06, 0.08, 0.97 },
	headerBg = { 0.08, 0.08, 0.10, 1 },
	primary = { 1.0, 0.6, 0.2, 1 },     -- Orange
	primary_dark = { 0.8, 0.45, 0.1, 1 }, -- Darker orange
	primary_glow = { 1.0, 0.7, 0.3, 0.3 }, -- Orange glow
	text = { 0.9, 0.9, 0.9, 1 },
	textDim = { 0.55, 0.55, 0.55, 1 },
	success = { 0.4, 0.9, 0.4, 1 },
	warning = { 1.0, 0.8, 0.2, 1 },
	danger = { 0.9, 0.3, 0.3, 1 },
	cardBg = { 0.09, 0.09, 0.11, 0.95 },
	cardBorder = { 0.18, 0.18, 0.2, 1 },
	sliderBg = { 0.12, 0.12, 0.14, 1 },
	sliderFill = { 1.0, 0.6, 0.2, 0.9 }, -- Orange
	ember = { 1.0, 0.4, 0.1, 1 },     -- Ember orange
	Anguish = { 0.9, 0.3, 0.3, 1 },   -- Anguish red
	tabInactive = { 0.1, 0.1, 0.12, 1 },
	tabActive = { 0.15, 0.15, 0.18, 1 }
}

--- @param name string
--- @param width number
--- @param height number
--- @param parent any
--- @param options {isScrollable:boolean, isMovable:boolean, isDismissable:boolean, hasTitle: boolean, hasBorder: boolean, hasBackdrop: boolean}
function OpenModal(name, width, height, parent, options)
	name = name or "Modal"
	name = "Cultivation - " .. name
	parent = parent or UIParent

	local isScrollable = options.isScrollable or false
	local isMovable = options.isMovable or false
	local isDismissable = options.isDismissable or false
	local hasTitle = options.hasTitle or false
	local hasBorder = options.hasBorder or false
	local hasBackdrop = options.hasBackdrop or false

	local PFrame = CreateFrame("Frame", name, parent, "BackdropTemplate")

	PFrame:SetSize(width or 100, height or 100)
	PFrame:SetPoint("CENTER", parent, "CENTER", 0, 0)
	local edgeSize = 2
	if hasBackdrop then
		PFrame:SetBackdrop({
			bgFile = TEXTURES.flat,
			edgeFile = TEXTURES.flat,
			edgeSize = edgeSize
		})
		PFrame:SetBackdropColor(0.06, 0.06, 0.08, 0.8)
	end

	if not hasBorder then
		PFrame:SetBackdropBorderColor(0.12, 0.12, 0.14, 0)
	else
		PFrame:SetBackdropBorderColor(0.12, 0.12, 0.14, .8)
	end

	if isMovable then
		PFrame:SetMovable(true)
		PFrame:RegisterForDrag("LeftButton")
		PFrame:SetScript("OnDragStart", PFrame.StartMoving)
		PFrame:SetScript("OnDragStop", PFrame.StopMovingOrSizing)
	end

	PFrame:EnableMouse(true)

	PFrame:SetScript("OnShow", function(self)
		PlaySound(808)
	end)

	PFrame:SetScript("OnHide", function(self)
		PlaySound(808)
	end)

	PFrame:SetFrameStrata("DIALOG")
	PFrame:SetClampedToScreen(true)

	-- Title
	if hasTitle then
		PFrame.title = PFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
		PFrame.title:SetPoint("TOPLEFT", PFrame, "TOPLEFT", 5, -5)
		PFrame.title:SetText(name)
	end

	-- ScrollFrame
	if isScrollable then
		local scrollFrame = CreateFrame("ScrollFrame", name, PFrame, "UIPanelScrollFrameTemplate")
		scrollFrame:SetSize(width, height)
		if hasTitle then
			scrollFrame:SetPoint("TOPLEFT", PFrame.title, "BOTTOMLEFT", 0, -5)
		else
			scrollFrame:SetPoint("TOPLEFT", PFrame, "TOPLEFT", 5, -5)
		end
		scrollFrame:SetPoint("BOTTOMRIGHT", PFrame, "BOTTOMRIGHT", -12, 5)
		PFrame.scrollFrame = scrollFrame

		local scrollBar = scrollFrame.ScrollBar
		if scrollBar then
			scrollBar:ClearAllPoints()
			scrollBar:SetPoint("TOPRIGHT", scrollFrame, "TOPRIGHT", 0, -21)
			scrollBar:SetPoint("BOTTOMRIGHT", scrollFrame, "BOTTOMRIGHT", 0, 16)
		end
	end

	-- This makes escape work to close this modal
	if isDismissable then
		table.insert(UISpecialFrames, name)
	end

	PFrame:Hide()

	return PFrame
end

--- @param frame any
function ToggleModal(frame)
	if frame:IsShown() then
		frame:Hide()
	else
		frame:Show()
	end
end

-- Create a single meter frame
function CreateMeter(name, parent, iconPath, color)
	local meter = CreateFrame("Frame", "Cultivation - " .. name .. " - Meter", parent, "BackdropTemplate")

	meter:RegisterEvent("MODIFIER_STATE_CHANGED")
	meter:SetSize(METER_WIDTH, METER_HEIGHT)
	meter:SetPoint("TOP", parent, "TOP", 0, 0)
	meter:SetIgnoreParentAlpha(true)
	meter:SetMovable(false)
	meter:EnableMouse(true)
	meter:SetPropagateMouseMotion(true)
	meter:SetPropagateMouseClicks(true)

	local edgeSize = 0
	local inset = 2
	local texture = TEXTURES.flat
	-- Background with shadow effect
	meter:SetBackdrop({
		bgFile = texture,
		edgeFile = nil,
		edgeSize = 0,
		insets = {
			left = inset,
			right = inset,
			top = inset,
			bottom = inset
		}
	})
	meter:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
	meter:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

	-- Status bar (lower frame level so icon/text appear above)
	meter.bar = CreateFrame("StatusBar", nil, meter)
	meter.bar:SetFrameLevel(meter:GetFrameLevel()) -- Same level as parent, textures will be below OVERLAY
	meter.bar:SetPoint("TOPLEFT", inset, -inset)
	meter.bar:SetPoint("BOTTOMRIGHT", -inset, inset)
	meter.bar:SetStatusBarTexture(texture)
	meter.bar:SetMinMaxValues(0, 100)
	meter.bar:SetValue(0)
	meter.bar:EnableMouse(false)

	-- Icon on top of the bar, floating at the left/starting position
	-- Created on meter frame with high draw layer to ensure visibility
	if iconPath then
		meter.icon = meter:CreateTexture(nil, "OVERLAY", nil, 7) -- Sub-layer 7 for highest priority
		meter.icon_rotation = 0
		meter.icon:SetSize(METER_ICON_SIZE, METER_ICON_SIZE)
		meter.icon:SetPoint("LEFT", meter.bar, "LEFT", inset + METER_PADDING, inset - METER_PADDING / 2)
		meter.icon:SetTexture(iconPath)
		meter.icon:EnableMouse(false)
	end

	local fontPath = GetFont("Arial") or FONTS.Arial

	meter.name = meter:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	meter.name:SetPoint("LEFT", meter.icon, "RIGHT", METER_PADDING, 0)
	meter.name:SetText(name)
	meter.name:EnableMouse(false)

	-- Glow frame (outlines the bar) - pass isAnguish to determine atlas color
	--meter.glow = CreateGlowFrame(meter, isAnguish)

	-- Percentage text (no label needed since icon identifies the bar)
	meter.percent = meter:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	meter.percent:SetPoint("RIGHT", meter.bar, "RIGHT", -METER_PADDING, 0)
	meter.percent:SetText(tostring(meter.bar:GetValue()) .. "%")
	meter.percent:EnableMouse(false)

	meter.percent:SetFont(fontPath, METER_FONT_SIZE)
	meter.name:SetFont(fontPath, METER_FONT_SIZE)

	meter.UpdateBgColor = function(self, bg)
		bg = NormalizedColor(bg or COLORS.ADDON)
		bg[4] = 0.8
		self.bgColor = bg
		self.bar:SetStatusBarColor(unpack(bg))
	end

	meter.UpdateFgColor = function(self, fg)
		fg = NormalizedColor(fg or COLORS.WHITE)
		fg[4] = 1

		self.fgColor = fg
		self.name:SetTextColor(unpack(fg))
		self.percent:SetTextColor(unpack(fg))
		self.icon:SetVertexColor(unpack(fg))
	end

	meter:UpdateBgColor(color)
	meter:UpdateFgColor(COLORS.WHITE)

	-- TODO convert to having a static update func that user can pass new update func to like a squid
	local function _OnEnter(self)
		-- TODO convert to custom panel, tooltip kinda sucks
		GameTooltip:SetOwner(parent or self or UIParent, "ANCHOR_CURSOR_RIGHT")
		GameTooltip:SetClampedToScreen(true)
		if self.tooltip then
			self:tooltip(self)
		else
			GameTooltip:SetText(name, unpack(NormalizedColor(color or COLORS.ADDON)))
		end
		GameTooltip:Show()
	end

	local function _OnLeave()
		GameTooltip:Hide()
	end

	meter:SetScript("OnEnter", _OnEnter)
	meter:SetScript("OnLeave", _OnLeave)
	return meter
end

function Squid(width, height, texture, parent, update)
	local squid = CreateFrame("Frame")
	squid.width = width or 32
	squid.height = height or 32
	squid.image = texture or TEXTURES.flat
	squid.parent = parent or UIParent
	squid.update = update
	squid.rotation = 0

	if squid.parent.GetFrameLevel then
		squid:SetFrameLevel((squid.parent:GetFrameLevel() or 1) + 1)
	end

	squid:SetHeight(squid.width)
	squid:SetWidth(squid.height)
	squid:SetPoint("CENTER", squid.parent)
	squid:SetScript("OnUpdate", squid.update)

	local t = squid:CreateTexture(nil, "BACKGROUND")
	t:SetTexture(squid.image)
	t:SetAllPoints(squid)

	squid.texture = t

	squid:Show()

	return squid
end
