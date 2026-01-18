local smoothedThirstDisplay = nil
local THIRST_DISPLAY_LERP_SPEED = 3.0 -- How fast display catches up to actual value

-- Update thirst meter
-- TODO: move to draw / update calls and remove dependence on platform where you can
function UpdateThirstMeter(elapsed)
	if not ThirstMeter or not Addon.thirstCache then
		return
	end

	local thirst = 100 - (Addon.thirstCache.current or 0)

	-- Smooth the display value to prevent flickering from exhaustion-scaled calculations
	local targetDisplay = thirst
	if smoothedThirstDisplay == nil then
		smoothedThirstDisplay = targetDisplay
	else
		-- Lerp toward target value
		local diff = targetDisplay - smoothedThirstDisplay
		smoothedThirstDisplay = smoothedThirstDisplay + diff * math.min(1, THIRST_DISPLAY_LERP_SPEED * elapsed)
	end
	local displayValue = smoothedThirstDisplay

	-- Update bar value (inverted: full bar = 0% thirst, empty bar = 100% thirst)
	ThirstMeter.bar:SetValue(displayValue)
	ThirstMeter.percent:SetText(Dump(ThirstMeter.bar:GetValue()) .. "%")
end

ThirstAura = Squid(2000, 2000, TEXTURES.aura, UIParent, function(self, elapsed)
	local pct = Addon.thirstCache.current / 100
	self.opacity = pct
	self.rotation = self.rotation + self.rotation_rate
	self.texture:SetRotation(math.rad(self.rotation))
	self:SetAlpha(Clamp(self.opacity, 0, 1))
end)

ThirstAura.rotation = 0
ThirstAura.rotation_rate = 0.5
ThirstAura.opacity = 0
ThirstAura:SetFrameStrata("TOOLTIP")
ThirstAura:SetFrameLevel(99)
ThirstAura:SetPoint("TOPLEFT", UIParent, "TOPLEFT", -1000, 500)
ThirstAura:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", 1000, -500)
ThirstAura.texture:SetVertexColor(unpack(NormalizedColor(COLORS.THIRST)))
