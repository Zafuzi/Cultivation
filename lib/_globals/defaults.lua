--[[ KEEP AT TOP JUST CUS I LIKE IT HERE ]] --
--[[ Addon defaults ]]                      --
Addon = {
	version = "0.1.0",
	name = "Cultivation",

	isLoaded = false,

	callbacks = {},

	playerCache = {
		name = "Player",
		level = 0,
		health = 0,
		speed = 0,

		resting = false,
		eating = false,
		activity = "idle",
		cultivating = false,
		camping = false,
		drinking = false,
		wellFed = false,
	},

	settingsCache = {
		brightness = 50,
		contrast = 50,
		gamma = 1.0,
	}
}

-- Debug category to setting mapping (optimization for Debug function)
DEFAULT_SETTINGS = {
	debug_general = true,
	debug_event = false,
	debug_panel = false,
	debug_player = true,
	debug_database = true,
	debug_hunger = true,
	debug_thirst = true,
	debug_cultivation = true,
	debug_settings = true,
}

-- Initialize character-specific saved variables
DEFAULT_CHAR_SETTINGS = {
	hunger_current = 0,
	hunger_rate = 0,
	hunger_timeToStarveInHours = 1,

	thirst_current = 0,
	thirst_rate = 0,
	thirst_timeToDehydrationInHours = 1 / 3,

	cultivation_current = 0,
	cultivation_rate = 0,
	cultivation_milestone = 1,
	cultivation_color = "#FF0000",
	cultivation_active = true,

	brightness = 50,
	constrast = 50,
	gamme = 1.0
}
--[[ END DEFAULTS ]] --
