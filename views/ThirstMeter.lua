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

function SetupThirstTooltip(self)
	self.tooltip = function(_self)
		local pct = Addon.thirstCache and (100 - (Addon.thirstCache.current or 0)) or 0
		GameTooltip:AddLine("Jade Spring", unpack(NormalizedColor(COLORS.THIRST)))
		GameTooltip:AddLine("The dantian's thirst for spiritual moisture.", 0.7, 0.65, 0.5)
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine("This one's vessel is " .. Dump(pct) .. "% replenished.", 0.9, 0.85, 0.7)
		GameTooltip:AddLine("Ascend the path—water becomes dew, dew becomes qi.", 0.55, 0.5, 0.45)
	end
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
