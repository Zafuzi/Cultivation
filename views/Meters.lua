-- Meter configuration
METER_WIDTH = 300
METER_HEIGHT = 32
METER_FONT_SIZE = METER_HEIGHT / 2
METER_SPACING = 8
METER_PADDING = 4
METER_ICON_SIZE = METER_FONT_SIZE

MetersContainer = nil
function OpenMeters()
	MetersContainer = OpenModal("Meters", METER_WIDTH, METER_HEIGHT, UIParent,
		{ isMovable = true, hasBorder = false, hasBackdrop = false })
	MetersContainer:SetFrameStrata("LOW")
	MetersContainer:SetScale(1)
	MetersContainer:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, 0)
	MetersContainer:SetScript("OnMouseDown", function(self, button)
		if button == "LeftButton" then
			ToggleModal(DebugPanel)
		end

		if button == "RightButton" then
			ReloadUI()
		end
	end)

	HungerMeter = CreateMeter("Five Grains", MetersContainer, ICONS.food, COLORS.HUNGER)
	HungerMeter:SetPoint("TOPLEFT", MetersContainer, "TOPLEFT", METER_PADDING, -METER_PADDING)
	SetupHungerTooltip(HungerMeter)

	ThirstMeter = CreateMeter("Jade Spring", MetersContainer, ICONS.drink, COLORS.THIRST)
	ThirstMeter:SetPoint("TOPLEFT", HungerMeter, "BOTTOMLEFT", 0, -METER_PADDING)
	SetupThirstTooltip(ThirstMeter)

	CultivationMeter = CreateMeter("Golden Core", MetersContainer, ICONS.cultivation, Cultivation_colors[1])
	CultivationMeter:SetPoint("TOPLEFT", ThirstMeter, "BOTTOMLEFT", 0, -METER_PADDING)

	SetupCultivationTooltip(CultivationMeter)

	local children = #{ MetersContainer:GetChildren() }

	MetersContainer:SetWidth(METER_WIDTH + (METER_PADDING * 2))
	MetersContainer:SetHeight((children * METER_HEIGHT) + (children * METER_PADDING) + (METER_PADDING))
	MetersContainer:Show()

	-- One-time initial display; calculations run on simulation tick (Core), animation on scheduler
	OnAnimationTick(0)

	Scheduler.RegisterAnimationTick(OnAnimationTick)
end

-- Chunked animation only: meters + auras. Called by scheduler at ~15 FPS (10 in combat/instance).
function OnAnimationTick(elapsed)
	if Addon.cultivationCache then
		CultivationMeter:UpdateBgColor(Addon.cultivationCache.color)
	end
	UpdateHungerMeter(elapsed)
	UpdateThirstMeter(elapsed)
	UpdateCultivationMeter(elapsed)
	if HungerAura and HungerAura.update then
		HungerAura.update(HungerAura, elapsed)
	end
	if ThirstAura and ThirstAura.update then
		ThirstAura.update(ThirstAura, elapsed)
	end
	if CultivationAura and CultivationAura.update then
		CultivationAura.update(CultivationAura, elapsed)
	end
end
