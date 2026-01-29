-- TODO: convert to a module that requires ZERO utils
function UpdatePlayerThirst(elapsed)
	local rate = GetThirstRate()
	SetCharSetting("thirst_rate", rate)

	local floor = GetCultivationFloor()
	-- Floor = min satiation %; thirst 0 = full, 100 = empty, so max thirst = 100 - floor (never worse than floor% full).
	local thirst = Clamp(Addon.thirstCache.current + rate * elapsed, 0, 100 - floor)
	SetCharSetting("thirst_current", thirst)
end

--- @param elapsed number the amount of time elapsed since last frame
function GetPlayerThirst(elapsed)
	return Addon.thirstCache.current
end

function GetThirstRate()
	-- drinking overrides everything; cultivation makes drink more effective
	if Addon.playerCache.activity == "idle" and Addon.playerCache.drinking then
		return -(100 / 16) * GetCultivationFoodEfficiency()
	end

	local tts = Addon.thirstCache.timeToDehydrationInHours or ONE_THIRD
	local rate = tts

	if Addon.playerCache.activity == "idle" then
		rate = tts
	end

	if Addon.playerCache.activity == "mounted" then
		rate = tts / 2
	end

	if Addon.playerCache.activity == "walking" then
		rate = tts / 4
	end

	if Addon.playerCache.activity == "running" or Addon.playerCache.activity == "flying" then
		rate = tts / 6
	end

	if Addon.playerCache.activity == "swimming" then
		rate = tts / 8
	end

	if Addon.playerCache.activity == "combat" then
		-- ~30 minutes of active combat to go from 100% to 0%
		rate = 0.3
	end

	if not rate then
		return 0
	end

	if Addon.playerCache.resting then
		rate = rate * 2
	end

	rate = RateAfterCultivation(rate)

	-- resting recovery: cultivate to slowly fill thirst while resting (not drinking, not combat)
	if Addon.playerCache.resting and not Addon.playerCache.drinking and Addon.playerCache.activity ~= "combat" then
		rate = rate - GetCultivationRestingRecoveryPerSecond()
	end

	return rate
end
