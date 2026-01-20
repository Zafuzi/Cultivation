local ADDON, _Version = ...
local f = CreateFrame("Frame", "Cultivation")
Toasts = LibStub("Toasts-0.1")

RegisterdEvents = {
	{ name = "PLAYER_ENTERING_WORLD",       enabled = true },
	{ name = "ADDON_LOADED",                enabled = true },
	{ name = "UNIT_ENTERED_VEHICLE",        enabled = true },
	{ name = "UNIT_EXITED_VEHICLE",         enabled = true },
	{ name = "PLAYER_STOPPED_MOVING",       enabled = true },
	{ name = "PLAYER_STARTED_MOVING",       enabled = true },
	{ name = "PLAYER_UPDATE_RESTING",       enabled = true },
	{ name = "COMBAT_LOG_EVENT_UNFILTERED", enabled = true },
	{ name = "CHAT_MSG_COMBAT_XP_GAIN",     enabled = true },
	{ name = "WORLD_MAP_OPEN",              enabled = true },
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
			-- first time update
			local version = C_AddOns.GetAddOnMetadata(ADDON, "Version")
			Addon.version = version
			Addon.name = ADDON
			Addon.isLoaded = true
			UpdateAddon(0)
			OpenMeters()
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

	if nameOfEvent == "COMBAT_LOG_EVENT_UNFILTERED" then
		local playerGUID = UnitGUID("player")
		local MSG_CRITICAL_HIT = "Your %s critically hit %s for %d damage!"
		local _, subevent, _, sourceGUID, _, _, _, _, destName = CombatLogGetCurrentEventInfo()
		local spellId, amount, critical

		if subevent == "SWING_DAMAGE" then
			amount, _, _, _, _, _, critical = select(12, CombatLogGetCurrentEventInfo())
		elseif subevent == "SPELL_DAMAGE" then
			spellId, _, _, amount, _, _, _, _, _, critical = select(12, CombatLogGetCurrentEventInfo())
		end

		if critical and sourceGUID == playerGUID then
			-- get the link of the spell or the MELEE globalstring
			local action = spellId and GetSpellLink(spellId) or MELEE
			print(MSG_CRITICAL_HIT:format(action, destName, amount))
		end
	end

	if nameOfEvent == "CHAT_MSG_COMBAT_XP_GAIN" then
		local xpGained = select(1, ...)
		print("XP Gained: " .. tostring(xpGained))
	end
end)

hooksecurefunc(WorldMapFrame, "Show", function()
	if not Addon.playerCache.resting then
		WorldMapFrame:Hide()
		Toasts.UI.Toasts.Push({
			title = "Adventuring",
			text = "Map is disabled outside of towns",
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
			title = "Adventuring",
			text = "Minimap is disabled outside of towns",
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

local t = 0
UPDATE_DELAY = 1 / 60
function UpdateAddon(elapsed)
	Addon.playerCache.name = GetPlayerProp("name")
	Addon.playerCache.level = GetPlayerProp("level")
	Addon.playerCache.health = GetPlayerProp("health")
	Addon.playerCache.speed = GetPlayerProp("speed")

	Addon.playerCache.resting = IsResting()
	Addon.playerCache.eating = IsPlayerEating()
	Addon.playerCache.activity = GetMovementState()
	Addon.playerCache.cultivating = IsPlayerCultivating()
	Addon.playerCache.camping = IsPlayerCamping()
	Addon.playerCache.drinking = IsPlayerDrinking()
	Addon.playerCache.wellFed = IsPlayerWellFed()

	Addon.settingsCache = {
		brightness = GetCharSetting("brightness"),
		contrast = GetCharSetting("contrast"),
		gamma = GetCharSetting("gamma")
	}

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

	-- TODO: move this into a onetime event, not here in the update!
	if not Addon.playerCache.resting then
		if WorldMapFrame:IsShown() or Minimap:IsShown() then
			HideUIPanel(WorldMapFrame)
			HideUIPanel(Minimap)
		end
	end

	UpdatePlayerHunger(elapsed)
	UpdatePlayerThirst(elapsed)
	UpdatePlayerCultivation(elapsed)
end

f:SetScript("OnUpdate", function(self, elapsed)
	if Addon.isLoaded and t >= UPDATE_DELAY then
		UpdateAddon(elapsed)
		-- update CVars
		SetCVar("RenderScale", Addon.settingsCache.renderScale)
		SetCVar("Brightness", Addon.settingsCache.brightness)
		SetCVar("Contrast", Addon.settingsCache.contrast)
		SetCVar("Gamma", Addon.settingsCache.gamma)
		t = 0
	end

	t = t + elapsed
end)

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
