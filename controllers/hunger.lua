function UpdatePlayerHunger(elapsed)
	local rate = GetHungerRate()
	local floor = GetCultivationFloor()
	-- Floor = min satiation %; hunger 0 = full, 100 = empty, so max hunger = 100 - floor (never worse than floor% full).
	local hunger = Clamp(Addon.hungerCache.current + rate * elapsed, 0, 100 - floor)

	SetCharSetting("hunger_rate", rate)
	SetCharSetting("hunger_current", hunger)
end

--- @param elapsed number the amount of time elapsed since last frame
function GetPlayerHunger(elapsed)
	return Addon.hungerCache.current
end

function GetHungerRate()
	-- eating overrides everything; cultivation makes food more effective
	if Addon.playerCache.eating then
		return -(100 / 20) * GetCultivationFoodEfficiency()
	end

	local tts = Addon.hungerCache.timeToStarveInHours
	local rate = tts

	if Addon.playerCache.activity == "idle" then
		rate = tts
	end

	if Addon.playerCache.activity == "mounted" then
		rate = tts / 2
	end

	if Addon.playerCache.activity == "walking" then
		rate = tts / 3
	end

	if Addon.playerCache.activity == "running" or Addon.playerCache.activity == "flying" then
		rate = tts / 4
	end

	if Addon.playerCache.activity == "swimming" then
		rate = tts / 6
	end

	if Addon.playerCache.activity == "combat" then
		-- ~30 minutes of active combat to go from 100% to 0%
		rate = 0.3
	end

	if not rate then
		rate = 1
	end

	if Addon.playerCache.resting then
		rate = rate * 2
	end

	rate = RateAfterCultivation(rate)

	-- resting recovery: cultivate to slowly fill hunger while resting (not eating, not combat)
	if Addon.playerCache.resting and not Addon.playerCache.eating and Addon.playerCache.activity ~= "combat" then
		rate = rate - GetCultivationRestingRecoveryPerSecond()
	end

	return rate
end
