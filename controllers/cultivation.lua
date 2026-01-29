CultivationMilestones = { 1e2, 1e4, 1e6, 1e8, 1e10, 1e12, 1e14, 1e20 }
Cultivation_colors = { "#FF0000", "#FF9900", "#ffff00", "#00ff00", "#0000ff", "#ff00ff", "#ffffff", "#000000" }
Cultivation_tiers = { "Red", "Orange", "Yellow", "Green", "Blue", "Violet", "White", "Black" }
-- these slow down all other meters by xRate -> Higher cultivation = less dmg, less hunger, etc...
CultivationMultipliers = { 1, 0.9, 0.8, 0.7, 0.6, 0.5, 0.4, 0.2 }

local currentMilestone = 1

function GetCultivationMultiplier()
	return CultivationMultipliers[GetCurrentMilestone()] or 1
end

-- Rewards: higher cultivation = more benefits beyond decay reduction

--- Hunger/thirst cannot drop below this % (0 at tier 1, +5% per tier, e.g. tier 8 = 35%)
function GetCultivationFloor()
	local m = GetCurrentMilestone()
	return math.max(0, (m - 1) * 5)
end

--- % per second recovered while resting (not eating/drinking). Scales with tier.
local RESTING_RECOVERY_BASE = (0.5 / 60) -- 0.5% per minute at tier 1
function GetCultivationRestingRecoveryPerSecond()
	local m = GetCurrentMilestone()
	return RESTING_RECOVERY_BASE * m
end

--- Multiplier for eating/drinking fill rate (1.0 at tier 1, +5% per tier, e.g. tier 8 = 1.35)
function GetCultivationFoodEfficiency()
	local m = GetCurrentMilestone()
	return 1 + (m - 1) * 0.05
end

--- Display: decay reduction % compared to tier 1 (e.g. tier 2 = 10%, tier 8 = 80%)
function GetCultivationDecayReductionPercent()
	local mult = GetCultivationMultiplier()
	return math.floor((1 - mult) * 100 + 0.5)
end

function GetCurrentMilestone()
	return Addon.cultivationCache.milestone or 1
end

function GetNextMilestone()
	local milestone = GetCurrentMilestone()
	local next = milestone + 1
	return next > #CultivationMilestones and milestone or next
end

function GetPrevMilestone()
	local milestone = GetCurrentMilestone() - 1
	local prev = milestone - 1
	return prev < 1 and milestone or prev
end

function GetMilestoneValue(milestone)
	milestone = milestone or Addon.cultivationCache.milestone or 1
	return CultivationMilestones[milestone] or 0
end

function GetPlayerCultivation()
	return Addon.cultivationCache.current
end

function GetCultivationRate()
	local rate = 1

	if IsPlayerCultivating() then
		if IsResting() then
			rate = 5
		else
			-- stop cultivating in open world, too dangerous, unless near a campfire
			if Addon.playerCache.camping then
				rate = 4
			else
				rate = 2
			end
		end
	end

	if Addon.playerCache.activity == "combat" then
		rate = 3
	end

	if not rate then
		rate = 1
	end

	if Addon.playerCache.resting then
		-- 10% boost when resting
		rate = rate * 1.1
	end

	-- campfire adds a small 10% boost
	if Addon.playerCache.camping then
		rate = rate * 1.1
	end

	-- 10% boost while traveling
	if Addon.playerCache.onVehicle then
		rate = rate * 1.1
	end

	return rate * (Addon.playerCache.wellFed and 1.1 or 1)
end

function UpdatePlayerCultivation(elapsed)
	-- load into caches
	Addon.cultivationCache = {
		current = GetCharSetting("cultivation_current"),
		rate = GetCharSetting("cultivation_rate"),
		milestone = GetCharSetting("cultivation_milestone"),
		color = GetCharSetting("cultivation_color"),
		active = GetCharSetting("cultivation_active"),
	}

	currentMilestone = Addon.cultivationCache.milestone or 1
	if currentMilestone == #CultivationMilestones then
		return
	end

	local rate = GetCultivationRate()
	local current = Addon.cultivationCache.current
	local milestone_value = GetMilestoneValue(currentMilestone)
	local next = GetNextMilestone()
	local next_value = GetMilestoneValue(next)

	SetCharSetting("cultivation_rate", rate)
	local cultivation = Clamp(current + (rate * elapsed), 0, next_value)

	if cultivation >= milestone_value then
		currentMilestone = next
		milestone_value = next_value

		Toasts.UI.Toasts.Push({
			title = "Breakthrough",
			text = "This one has forged a " .. Cultivation_tiers[next] .. " core. The heavens take notice.",
			icon = Toasts.UI.Icons.LOOT,
			progress = 1,
			duration = 4,
			onClick = function()
				print("Toast clicked")
			end,
		})

		Toasts.UI.Toasts.SetAnchor("TOP", 0, -20)

		SetCharSetting("cultivation_milestone", currentMilestone)
		MilestoneReached(next)
	end

	SetCharSetting("cultivation_current", cultivation)
end
