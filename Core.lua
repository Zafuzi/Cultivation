local ADDON, _Version = ...
local f = CreateFrame("Frame", "Cultivation")
local combatSummaryPendingAt = nil -- GetTime() when we're allowed to show (10s after last combat end)
local combatSummaryTicker = nil    -- single ticker; cancelable so we only ever have one

RegisterdEvents = {
	{ name = "PLAYER_ENTERING_WORLD", enabled = true },
	{ name = "ADDON_LOADED",          enabled = true },
	{ name = "PLAYER_LOGOUT",         enabled = true },
	{ name = "PLAYER_REGEN_ENABLED",  enabled = true },
	{ name = "UNIT_ENTERED_VEHICLE",  enabled = true },
	{ name = "UNIT_EXITED_VEHICLE",   enabled = true },
	{ name = "PLAYER_STOPPED_MOVING", enabled = true },
	{ name = "PLAYER_STARTED_MOVING", enabled = true },
	{ name = "PLAYER_UPDATE_RESTING", enabled = true },
	{ name = "WORLD_MAP_OPEN",        enabled = true },
}

for idx, event in pairs(RegisterdEvents) do
	if event.enabled and event.name ~= nil then
		f:RegisterEvent(event.name)
	end
end

f:SetScript("OnEvent", function(self, nameOfEvent, ...)
	if nameOfEvent == "ADDON_LOADED" then
		local addonName = select(1, ...)
		if addonName == Addon.name then
			local version = C_AddOns.GetAddOnMetadata(ADDON, "Version")
			Addon.version = version
			Addon.name = ADDON
			Addon.isLoaded = true
			RefreshCaches()
			ApplyCultivationCatchUp()
			OpenMeters()
			Scheduler.RegisterSimulationTick(OnSimulationTick)
			Scheduler.Start()
			-- Restore cultivation aura/state after reload (caches and UI now exist)
			C_Timer.After(0.5, function()
				if GetCharSetting("cultivation_active") then
					Cultivate(true, true)
				else
					Cultivate(false, true)
				end
			end)
		end
		return
	end

	if nameOfEvent == "PLAYER_ENTERING_WORLD" then
		return
	end

	if nameOfEvent == "PLAYER_LOGOUT" then
		SetCharSetting("cultivation_logout_time", time())
		return
	end

	if nameOfEvent == "PLAYER_REGEN_ENABLED" then
		OnCombatEnd()
		-- Push show time to 10s from now; multiple combat-ends combine into one window.
		combatSummaryPendingAt = GetTime() + 10
		if not combatSummaryTicker then
			combatSummaryTicker = C_Timer.NewTicker(1, function()
				if not combatSummaryPendingAt or GetTime() < combatSummaryPendingAt then
					return
				end
				if UnitAffectingCombat("player") then
					-- Still in combat; never show. Push back 5s and try again.
					combatSummaryPendingAt = GetTime() + 5
					return
				end
				combatSummaryPendingAt = nil
				local ticker = combatSummaryTicker
				combatSummaryTicker = nil
				if ticker then ticker:Cancel() end
				local gain = GetAndClearCombatCultivationGain()
				if gain and gain > 0 then
					local display = WithCommas(string.format("%.0f", gain))
					Toasts.UI.Toasts.Push({
						title = "Battle Refinement",
						text = "Qi refined in combat: " .. display,
						icon = Toasts.UI.Icons.LOOT,
						progress = 1,
						duration = 30,
						onClick = function()
							print("Toast clicked")
						end,
					})
					Toasts.UI.Toasts.SetAnchor("TOP", 0, -20)
				end
			end)
		end
		return
	end

	if nameOfEvent == "UNIT_ENTERED_VEHICLE" then
		local unitName = select(1, ...)
		if unitName == "player" then
			Addon.playerCache.onVehicle = true
			Cultivate(true)
		end
		return
	end

	if nameOfEvent == "UNIT_EXITED_VEHICLE" then
		local unitName = select(1, ...)
		if unitName == "player" then
			Addon.playerCache.onVehicle = false
			Cultivate(false)
		end
		return
	end

	if nameOfEvent == "PLAYER_STARTED_MOVING" then
		if GetCharSetting("cultivation_active") then
			Cultivate(false)
		end
		return
	end
end)

hooksecurefunc(WorldMapFrame, "Show", function()
	if not Addon.playerCache.resting then
		WorldMapFrame:Hide()
		Toasts.UI.Toasts.Push({
			title = "Mortal Ground",
			text = "The map is sealed beyond rest. Only the refined may wander with clarity.",
			icon = Toasts.UI.Icons.ERROR,
			progress = 1,
			duration = 4,
			onClick = function()
				print("Toast clicked")
			end,
		})

		Toasts.UI.Toasts.SetAnchor("TOP", 0, -20)
	end
end)

hooksecurefunc(Minimap, "Show", function()
	if not Addon.playerCache.resting then
		Minimap:Hide()
		Toasts.UI.Toasts.Push({
			title = "Mortal Ground",
			text = "The minimap is sealed beyond rest. This one must refine before venturing blind.",
			icon = Toasts.UI.Icons.ERROR,
			progress = 1,
			duration = 4,
			onClick = function()
				print("Toast clicked")
			end,
		})

		Toasts.UI.Toasts.SetAnchor("TOP", 0, -20)
	end
end)

f:SetPropagateKeyboardInput(true)

-- Event-driven cache refresh: only run when simulation tick fires (or on first load).
-- Calculations (hunger/thirst/cultivation) run only on simulation tick, not every frame.
function RefreshCaches()
	Addon.playerCache.name = GetPlayerProp("name")
	Addon.playerCache.level = GetPlayerProp("level")
	Addon.playerCache.health = GetPlayerProp("health")
	Addon.playerCache.speed = GetPlayerProp("speed")

	Addon.playerCache.resting = IsResting() or IsPlayerCamping()
	Addon.playerCache.eating = IsPlayerEating()
	Addon.playerCache.activity = GetMovementState()
	Addon.playerCache.cultivating = IsPlayerCultivating()
	Addon.playerCache.camping = IsPlayerCamping()
	Addon.playerCache.drinking = IsPlayerDrinking()
	Addon.playerCache.wellFed = IsPlayerWellFed()

	Addon.hungerCache = {
		current = GetCharSetting("hunger_current"),
		rate = GetCharSetting("hunger_rate"),
		timeToStarveInHours = GetCharSetting("hunger_timeToStarveInHours"),
	}

	Addon.thirstCache = {
		current = GetCharSetting("thirst_current"),
		rate = GetCharSetting("thirst_rate"),
		timeToDehydrationInHours = GetCharSetting("thirst_timeToDehydrationInHours"),
	}

	Addon.cultivationCache = {
		current = GetCharSetting("cultivation_current"),
		rate = GetCharSetting("cultivation_rate"),
		milestone = GetCharSetting("cultivation_milestone"),
		color = GetCharSetting("cultivation_color"),
		active = GetCharSetting("cultivation_active"),
	}

	if not Addon.playerCache.resting then
		if WorldMapFrame:IsShown() or Minimap:IsShown() then
			HideUIPanel(WorldMapFrame)
			HideUIPanel(Minimap)
		end
	end
end

-- Called by scheduler at simulation interval (1s normal, 2.5s in combat/instance).
function OnSimulationTick(elapsed)
	RefreshCaches()
	UpdatePlayerHunger(elapsed)
	UpdatePlayerThirst(elapsed)
	UpdatePlayerCultivation(elapsed)
end

SLASH_CULTIVATION1 = "/cultivation"
SLASH_CULTIVATION2 = "/c"
SlashCmdList["CULTIVATION"] = function(msg)
	msg = string.lower(msg or "")
	local command, value = msg:match("([^%s]+)%s*(.*)")
	command = string.lower(command or "")
	value = string.lower(value)

	if command == "clear" then
		if value == "db" then
			ResetDB()
			return
		end

		if value == "char" then
			ResetChar()
			return
		end

		if value == "all" then
			ResetSettings()
			return
		end

		Debug("USAGE: DB|CHAR|ALL")
		return
	end

	if command == "dbg" then
		if value ~= nil then
			local key = "debug_" .. tostring(value)
			-- Check if the key exists in DEFAULT_SETTINGS before toggling
			if DEFAULT_SETTINGS[key] == nil then
				Debug("Unknown debug key: " .. tostring(key))
				return
			end

			local isOn = not GetSetting(key)
			SetSetting(key, isOn)

			Debug("Toggled " .. tostring(key) .. ": " .. tostring(isOn))
			if key == "debug_panel" then
				ToggleModal(DebugPanel)
			end
		end

		return
	end

	if command == "panel" then
		-- Shorthand for /c dbg panel
		local key = "debug_panel"
		if DEFAULT_SETTINGS[key] == nil then
			Debug("Unknown debug key: " .. tostring(key))
			return
		end

		local isOn = not GetSetting(key)
		SetSetting(key, isOn)

		Debug("Toggled " .. tostring(key) .. ": " .. tostring(isOn))
		ToggleModal(DebugPanel)
		return
	end

	if command == "cultivate" then
		Cultivate(true)
		return
	end
end
