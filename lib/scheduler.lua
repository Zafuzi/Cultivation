--[[
  Scheduler: separates calculations (event-driven / slow tick) from animations (chunked, smooth).
  - Simulation: runs at 1s normally, 2.5s in combat/instance. For hunger/thirst/cultivation math + CVars.
  - Animation: runs at 15 FPS normally, 10 FPS in combat/instance. For meter bars and auras only.
  CPU is reduced in combat/instances by lengthening intervals, not by turning off.
  Uses one frame with OnUpdate and accumulated time so intervals can change dynamically.
]]

Scheduler = Scheduler or {}

-- Intervals (seconds)
local SIM_INTERVAL_NORMAL = 1.0
local SIM_INTERVAL_COMBAT = 2.5
local ANIM_INTERVAL_NORMAL = 1 / 15 -- ~15 FPS
local ANIM_INTERVAL_COMBAT = 1 / 10 -- ~10 FPS

local simulationCallbacks = {}
local animationCallbacks = {}
local simAccum = 0
local animAccum = 0
local inCombat = false
local inInstance = false
local schedulerFrame = nil

function Scheduler.IsInCombat()
	return inCombat
end

function Scheduler.IsInInstance()
	return inInstance
end

function Scheduler.RefreshThrottleState()
	inCombat = UnitAffectingCombat("player")
	inInstance = IsInInstance()
end

function Scheduler.GetSimulationInterval()
	return (inCombat or inInstance) and SIM_INTERVAL_COMBAT or SIM_INTERVAL_NORMAL
end

function Scheduler.GetAnimationInterval()
	return (inCombat or inInstance) and ANIM_INTERVAL_COMBAT or ANIM_INTERVAL_NORMAL
end

function Scheduler.RegisterSimulationTick(callback)
	table.insert(simulationCallbacks, callback)
end

function Scheduler.RegisterAnimationTick(callback)
	table.insert(animationCallbacks, callback)
end

local function runSimulation(elapsed)
	for _, cb in ipairs(simulationCallbacks) do
		pcall(cb, elapsed)
	end
end

local function runAnimation(elapsed)
	for _, cb in ipairs(animationCallbacks) do
		pcall(cb, elapsed)
	end
end

function Scheduler.Start()
	simAccum = 0
	animAccum = 0
	Scheduler.RefreshThrottleState()
	if not schedulerFrame then
		schedulerFrame = CreateFrame("Frame", "CultivationScheduler")
		schedulerFrame:SetScript("OnUpdate", function(_, elapsed)
			if not Addon or not Addon.isLoaded then return end
			Scheduler.RefreshThrottleState()
			local simInterval = Scheduler.GetSimulationInterval()
			local animInterval = Scheduler.GetAnimationInterval()
			simAccum = simAccum + elapsed
			animAccum = animAccum + elapsed
			if simAccum >= simInterval then
				runSimulation(simAccum)
				simAccum = 0
			end
			if animAccum >= animInterval then
				runAnimation(animAccum)
				animAccum = 0
			end
		end)
	end
	schedulerFrame:Show()
end

function Scheduler.Stop()
	if schedulerFrame then
		schedulerFrame:Hide()
	end
end
