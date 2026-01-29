local smoothedHungerDisplay = nil
local HUNGER_DISPLAY_LERP_SPEED = 3.0 -- How fast display catches up to actual value

-- Update hunger meter
function UpdateHungerMeter(elapsed)
	if not HungerMeter or not Addon.hungerCache then
		return
	end

	local hunger = 100 - (Addon.hungerCache.current or 0)

	-- Smooth the display value to prevent flickering from exhaustion-scaled calculations
	local targetDisplay = hunger
	if smoothedHungerDisplay == nil then
		smoothedHungerDisplay = targetDisplay
	else
		-- Lerp toward target value
		local diff = targetDisplay - smoothedHungerDisplay
		smoothedHungerDisplay = smoothedHungerDisplay + diff * math.min(1, HUNGER_DISPLAY_LERP_SPEED * elapsed)
	end
	local displayValue = smoothedHungerDisplay

	-- Update bar value (inverted: full bar = 0% hunger, empty bar = 100% hunger)
	HungerMeter.bar:SetValue(displayValue)

	HungerMeter.percent:SetText(Dump(HungerMeter.bar:GetValue()) .. "%")
end

function SetupHungerTooltip(self)
	self.tooltip = function(_self)
		local pct = Addon.hungerCache and (100 - (Addon.hungerCache.current or 0)) or 0
		GameTooltip:AddLine("Five Grains", unpack(NormalizedColor(COLORS.HUNGER)))
		GameTooltip:AddLine("The mortal vessel's attachment to earthly sustenance.", 0.7, 0.65, 0.5)
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine("This one's body retains " .. Dump(pct) .. "% fullness.", 0.9, 0.85, 0.7)
		GameTooltip:AddLine("As your core refines, mere grain holds less sway.", 0.55, 0.5, 0.45)
	end
end

HungerAura = Squid(2000, 2000, TEXTURES.aura, UIParent, function(self, elapsed)
	local pct = Addon.hungerCache.current / 100
	self.opacity = pct
	self.rotation = self.rotation + self.rotation_rate
	self.texture:SetRotation(math.rad(self.rotation))
	self:SetAlpha(Clamp(self.opacity, 0, 1))
end)

HungerAura.rotation = 0
HungerAura.rotation_rate = 0.5
HungerAura.opacity = 0
HungerAura:SetFrameStrata("TOOLTIP")
HungerAura:SetFrameLevel(99)
HungerAura:SetPoint("TOPLEFT", UIParent, "TOPLEFT", -1000, 500)
HungerAura:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", 1000, -500)
HungerAura.texture:SetVertexColor(unpack(NormalizedColor(COLORS.HUNGER)))
