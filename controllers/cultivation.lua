CultivationMilestones = { 1e2, 1e4, 1e6, 1e8, 1e10, 1e12, 1e14, 1e20 }
Cultivation_colors = { "#FF0000", "#FF9900", "#ffff00", "#00ff00", "#0000ff", "#ff00ff", "#ffffff", "#000000" }
Cultivation_tiers = { "Red", "Orange", "Yellow", "Green", "Blue", "Violet", "White", "Black" }
-- these slow down all other meters by xRate -> Higher cultivation = less dmg, less hunger, etc...
CultivationMultipliers = { 1, 0.9, 0.8, 0.7, 0.6, 0.5, 0.4, 0.2 }

local currentMilestone = 1

function GetCultivationMultiplier()
	return CultivationMultipliers[GetCurrentMilestone()] or 1
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

	return rate
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

		Debug("milestone reached! new milestone: " .. milestone_value)
		SetCharSetting("cultivation_milestone", currentMilestone)
		MilestoneReached(next)
	end

	SetCharSetting("cultivation_current", cultivation)
	SetCharSetting("gamma", Clamp((1.2 * cultivation / milestone_value), 1, 1.2))
end
