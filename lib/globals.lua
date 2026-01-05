-- Shared constants for colors (reduces string allocations)
COLORS = {
	ADDON = "|cff88CCFF",
	PROXIMITY = "|cff88FF88",
	EXHAUSTION = "|cffFFAA88",
	ANGUISH = "|cffFF6688",
	HUNGER = "|cffFFBB44",
	THIRST = "|cff66B8FF",
	TEMPERATURE = "|cffFFCC55",
	WARNING = "|cffFF6600",
	SUCCESS = "|cff00FF00",
	ERROR = "|cffFF0000"
}

-- Debug category to setting mapping (optimization for Debug function)
DEBUG_SETTINGS = {
	general = "debug_general",
	hunger = "debug_hunger",
}

-- Debug category to color mapping
DEBUG_COLORS = {
	general = COLORS.ADDON,
	proximity = COLORS.PROXIMITY,
	exhaustion = COLORS.EXHAUSTION,
	Anguish = COLORS.ANGUISH,
	hunger = COLORS.HUNGER,
	thirst = COLORS.THIRST,
	temperature = COLORS.TEMPERATURE
}

-- Addon defaults
DEFAULT_SETTINGS = {
	debug_general = true,
	debug_hunger = true,
}

-- Initialize character-specific saved variables
DEFAULT_CHAR_SETTINGS = {
	hunger_current = 0,
	hunger_rate = 0,
	hunger_timeToStarveInHours = 1,
}

EATING_AURAS = {
	["Food"] = true,
	["Refreshment"] = true,
	["Food & Drink"] = true,
}

Addon = {
	version = "0.0.1",
	name = "CozierCamps",

	isLoaded = false,

	callbacks = {},

	playerCache = {
		name = "Player",
		level = 0,
		health = 0,
		speed = 0,
		resting = false,
		eating = false,
		activity = "idle"
	},
}

