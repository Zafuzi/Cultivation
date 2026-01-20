function MilestoneReached(next)
	local next_color = Cultivation_colors[next]
	SetCharSetting("cultivation_color", next_color)
	CultivationMeter:UpdateBgColor(next_color)
end

function GetCultivationColor()
	if not Addon.cultivationCache then
		return Cultivation_colors[1]
	end

	return Addon.cultivationCache.color
end

local smoothedCultivationDisplay = nil
local CULTIVATION_DISPLAY_LERP_SPEED = 3.0 -- How fast display catches up to actual value

-- Update cultivation meter
-- TODO: move to draw / update calls and remove dependence on platform where you can
local nameText = ""
local milestone = 1
local milestone_value = GetMilestoneValue(milestone)
local cultivation = 0
local multiplier = 1

function UpdateCultivationMeter(elapsed)
	milestone = GetCurrentMilestone()
	milestone_value = GetMilestoneValue(milestone)

	cultivation = GetPlayerCultivation()

	-- Smooth the display value to prevent flickering from exhaustion-scaled calculations
	local targetDisplay = 100 * (cultivation / milestone_value)

	if smoothedCultivationDisplay == nil then
		smoothedCultivationDisplay = targetDisplay
	else
		-- Lerp toward target value
		local diff = targetDisplay - smoothedCultivationDisplay

		smoothedCultivationDisplay = smoothedCultivationDisplay +
			diff * math.min(1, CULTIVATION_DISPLAY_LERP_SPEED * elapsed)
	end

	local displayValue = smoothedCultivationDisplay

	-- Update bar value (inverted: full bar = 0% cultivation, empty bar = 100% cultivation)
	CultivationMeter.bar:SetValue(displayValue)

	-- Apply text based on hideVialText setting
	CultivationMeter.name:SetText("Cultivation")

	if CultivationMeter.icon then
		local rot = GetCultivationRate()
		local scale = METER_ICON_SIZE * Clamp(0.8 + (cultivation / milestone_value * multiplier), 0.8, 1.2)
		CultivationMeter.icon_rotation = (CultivationMeter.icon_rotation or 0) - rot
		CultivationMeter.icon:SetRotation(math.rad(CultivationMeter.icon_rotation))
		CultivationMeter.icon:SetSize(scale, scale)
	end

	local cutoff = 5
	CultivationMeter.percent:SetText(Dump(cultivation, 0, false))
end

function SetupCultivationTooltip(self)
	self.tooltip = function(_self)
		local color = NormalizedColor(Cultivation_colors[milestone])
		local nextMilestone = GetNextMilestone()
		local nextColor = NormalizedColor(Cultivation_colors[nextMilestone])
		GameTooltip:AddLine("Cultivation", unpack(NormalizedColor(COLORS.CULTIVATION)))
		GameTooltip:AddLine("Core: " .. Dump(Cultivation_tiers[milestone]), unpack(color))
		GameTooltip:AddLine("Next: " .. Dump(Cultivation_tiers[nextMilestone]), unpack(nextColor))
		GameTooltip:AddLine("Current: " .. Dump(cultivation), 1, 1, 1)
		GameTooltip:AddLine("Reduction: " .. Dump(GetCultivationMultiplier()), 1, 1, 1)
		GameTooltip:AddLine("Rate: " .. Dump(GetCultivationRate()), 1, 1, 1)
	end
end

CultivationAura = Squid(2000, 2000, TEXTURES.aura, UIParent, function(self, elapsed)
	if self.fadeIn then
		self.opacity = Clamp(self.opacity, self.opacity + self.fade_rate, 1)
	end

	if self.fadeOut then
		self.opacity = Clamp(self.opacity, 0, self.opacity - self.fade_rate)
	end

	if self.opacity >= 1 then
		self.fadeIn = false
		self.fadeOut = true
	end

	if self.opacity <= 0 then
		self.fadeOut = false
		if not self.hidden then
			self.fadeIn = true
		end
	end

	local low = self.hidden and 0.1 or 0.2
	self:SetAlpha(Clamp(self.opacity, low, 0.8))

	if not self.hidden then
		local color = Cultivation_colors[GetCurrentMilestone()]
		local nextColor = Cultivation_colors[GetNextMilestone()]

		self.rotation = self.rotation + self.rotation_rate
		self.texture:SetRotation(math.rad(self.rotation))
		self.texture:SetVertexColor(unpack(NormalizedColor(color)))
		self.texture:SetGradient("VERTICAL", WowColor(nextColor), WowColor(color))
		self.color_needs_set = false
	end
end)

CultivationAura.opacity = 0
CultivationAura.rotation = 0
CultivationAura.rotation_rate = -0.5
CultivationAura.fadeIn = false
CultivationAura.fade_rate = 0.0025
CultivationAura.hidden = true
CultivationAura:SetFrameStrata("TOOLTIP")
CultivationAura:SetFrameLevel(99)
CultivationAura:SetPoint("TOPLEFT", UIParent, "TOPLEFT", -1000, 500)
CultivationAura:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", 1000, -500)
CultivationAura:Hide()

CultivationAura.doShow = function(self, silent)
	print(Dump(Toasts.UI.Toasts))
	if not silent then
		Toasts.UI.Toasts.Push({
			title = "Cultivating",
			text = "Your cultivation rate has increased",
			icon = Toasts.UI.Icons.INFO,
			progress = 1,
			duration = 4,
			onClick = function()
				print("Toast clicked")
			end,
		})

		Toasts.UI.Toasts.SetAnchor("TOP", 0, -20)
	end
	self:Show()
	self.hidden = false
end

CultivationAura.doHide = function(self, silent)
	if not silent then
		Toasts.UI.Toasts.Push({
			title = "Cultivation Fades",
			text = "Your cultivation rate has decreased",
			icon = Toasts.UI.Icons.INFO,
			progress = 1,
			duration = 4,
			onClick = function()
				print("Toast clicked")
			end,
		})

		Toasts.UI.Toasts.SetAnchor("TOP", 0, -20)
	end
	self.hidden = true
end
