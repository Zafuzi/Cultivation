CultivationMilestones = { 1e2, 1e4, 1e6, 1e8, 1e10, 1e12, 1e14, 1e20 }
Cultivation_colors = { "#FF0000", "#FF9900", "#ffff00", "#00ff00", "#0000ff", "#ff00ff", "#ffffff", "#000000" }
Cultivation_tiers = { "Red", "Orange", "Yellow", "Green", "Blue", "Violet", "White", "Black" }
-- these slow down all other meters by xRate -> Higher cultivation = less dmg, less hunger, etc...
CultivationMultipliers = { 1, 0.9, 0.8, 0.7, 0.6, 0.5, 0.4, 0.2 }

local currentMilestone = 1
-- Combat summary: accumulated cultivation this combat (our own counter; never read secret API values for display).
-- COMBAT_LOG_EVENT is protected; we use time-in-combat (rate * elapsed) only.
local cultivationGainedThisCombat = 0
local combatTotalDamage = 0
local combatDamagePerTarget = {}

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

-- Offline catch-up: if player was cultivating at logout, grant 80% of resting cultivation rate (like rested XP).
local CATCH_UP_RATE = 5 * 0.8         -- resting cultivating rate * 80%
local CATCH_UP_CAP_SECONDS = 2 * 3600 -- max 2 hours of catch-up

function ApplyCultivationCatchUp()
	if not GetCharSetting("cultivation_active") then return end
	local logoutTime = GetCharSetting("cultivation_logout_time")
	if not logoutTime or logoutTime <= 0 then return end

	local now = time()
	local elapsed = math.max(0, now - logoutTime)
	elapsed = math.min(elapsed, CATCH_UP_CAP_SECONDS)
	SetCharSetting("cultivation_logout_time", nil)

	if elapsed <= 0 then return end

	local catchUp = elapsed * CATCH_UP_RATE
	local current = GetCharSetting("cultivation_current") or 0
	local milestone = GetCurrentMilestone()
	if milestone >= #CultivationMilestones then return end

	local nextTier = GetNextMilestone()
	local nextValue = GetMilestoneValue(nextTier)
	local milestoneValue = GetMilestoneValue(milestone)

	while catchUp > 0 and milestone < #CultivationMilestones do
		local space = nextValue - current
		local add = math.min(catchUp, space)
		current = current + add
		catchUp = catchUp - add

		if current >= milestoneValue then
			milestone = nextTier
			SetCharSetting("cultivation_milestone", milestone)
			SetCharSetting("cultivation_color", Cultivation_colors[milestone])
			Addon.cultivationCache.milestone = milestone
			MilestoneReached(milestone)
			AnnounceMilestoneToCommunity(milestone)
			nextTier = milestone < #CultivationMilestones and (milestone + 1) or milestone
			nextValue = GetMilestoneValue(nextTier)
			milestoneValue = GetMilestoneValue(milestone)
		end
	end

	SetCharSetting("cultivation_current", current)
	Addon.cultivationCache.current = current
	Addon.cultivationCache.milestone = milestone
end

-- Steady Mountain Sect = community channel 5
local COMMUNITY_CHANNEL_NAME = "Steady Mountain Sect"
local COMMUNITY_CHANNEL_ID = 5

function AnnounceMilestoneToCommunity(milestone)
	local channelId = GetChannelName(COMMUNITY_CHANNEL_NAME)
	if not channelId then
		channelId = COMMUNITY_CHANNEL_ID
	end
	local msg = "This one has forged a " .. (Cultivation_tiers[milestone] or "?") .. " core. The heavens take notice."
	pcall(SendChatMessage, msg, "CHANNEL", nil, channelId)
end

--- Returns cultivation gained this combat and clears the counter. Safe to display (our own accumulated number).
function GetAndClearCombatCultivationGain()
	local gain = cultivationGainedThisCombat
	cultivationGainedThisCombat = 0
	return gain
end

--- Add lump qi from combat (kills or damage); handles milestones and cache. Never passes secret values.
function AddCultivationFromCombat(amount)
	if not amount or amount <= 0 then return end
	if not Addon or not Addon.cultivationCache then return end
	local milestone = GetCurrentMilestone()
	if milestone >= #CultivationMilestones then return end

	local current = GetCharSetting("cultivation_current") or 0
	local nextTier = GetNextMilestone()
	local nextValue = GetMilestoneValue(nextTier)
	local milestoneValue = GetMilestoneValue(milestone)

	local remaining = amount
	while remaining > 0 and milestone < #CultivationMilestones do
		local space = nextValue - current
		local add = math.min(remaining, space)
		current = current + add
		remaining = remaining - add

		if current >= milestoneValue then
			milestone = nextTier
			SetCharSetting("cultivation_milestone", milestone)
			SetCharSetting("cultivation_color", Cultivation_colors[milestone])
			if Addon.cultivationCache then Addon.cultivationCache.milestone = milestone end
			MilestoneReached(milestone)
			AnnounceMilestoneToCommunity(milestone)
			nextTier = milestone < #CultivationMilestones and (milestone + 1) or milestone
			nextValue = GetMilestoneValue(nextTier)
			milestoneValue = GetMilestoneValue(milestone)
		end
	end

	SetCharSetting("cultivation_current", current)
	if Addon.cultivationCache then Addon.cultivationCache.current = current end
end

--- Clear combat tracker state at combat end (damage/kill tracking removed; COMBAT_LOG_EVENT is protected).
function OnCombatEnd()
	combatTotalDamage = 0
	combatDamagePerTarget = {}
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

	-- companion (non-combat pet) grants a slight cultivation boost
	if IsCompanionActive() then
		rate = rate * 1.05
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
	-- Combat qi from time in combat (COMBAT_LOG_EVENT is protected so we don't use damage/kills).
	if Addon.playerCache.activity == "combat" then
		cultivationGainedThisCombat = cultivationGainedThisCombat + (rate * elapsed)
	end

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
		AnnounceMilestoneToCommunity(next)
	end

	SetCharSetting("cultivation_current", cultivation)
end
