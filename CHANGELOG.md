
# Changelog
## [0.4.1]
### Patch
- **Cultivation on reload:** Cultivation aura and state (on/off) restore after reload; no need to toggle manually.
- **Offline catch-up:** If you were cultivating when you logged out, you receive up to 2 hours of “rested” cultivation at 80% rate when you log back in (like rested XP).
- **Community chat:** Reaching a cultivation milestone announces to Steady Mountain Sect (channel 5): “This one has forged a [tier] core. The heavens take notice.”
- **Companion bonus:** Having a non-combat pet (companion) summoned grants +5% cultivation rate.
- **Combat qi summary:** After combat, a single “Battle Refinement” toast shows qi refined (time-in-combat based). Multiple combats are combined into one notification 10 seconds after the last combat end; the toast never shows while you are still in combat.
- **Hunger/thirst floor fix:** You can reach 100% satiation again. The cultivation floor is the minimum satiation you can fall to (e.g. tier 2 = 5%), not a cap on fullness.
- **Combat log removed:** COMBAT_LOG_EVENT is protected; combat qi is time-based only (no damage/kill scaling).

## [0.4.0]
### Minor Release
- **Performance:** Separated calculations from animations. Calculations run on a simulation tick (1s normally, 2.5s in combat/instance); meter and aura animations run at ~15 FPS (~10 in combat/instance). CPU use reduced, especially in combat and instances.
- **Removed:** Gamma, brightness, and contrast CVar control. Auras handle atmosphere instead.
- **Balance:** Hunger and thirst in combat now decay from 100% to 0% in ~30 minutes of active combat (was far faster).
- **Cultivation rewards:** Beyond slower decay, cultivation now grants: a floor so hunger/thirst never drop below a tier-based minimum; resting recovery (slow refill while resting); and improved food/drink efficiency. All scale with cultivation tier.
- **Theme:** All in-game messaging (meter labels, tooltips, toasts) rewritten in an arrogant, Chinese cultivation-mythology tone. Meters renamed to Five Grains, Jade Spring, and Golden Core; tooltips and notifications use “this one,” dantian, qi, refinement, and breakthrough language.

## [0.3.1]
### Patch 
- Removed LibStub

## [0.3.0]
### Minor Release 
- Removed support for classic 

## [0.2.1]
### Patch 
- Added LibStub and Toasts 

## [0.2.0]
### Minor Release
- Added Well Fed buff tracking
- Added dialog for messages from the add-on
- Made map / minimap hide when not resting

## [0.1.0]
### Minor Release
- added auras (overlays) for Cultivation, Hunger, and Thirst
- added brightness, gamma, and contrast settings when meters get low
- improved controls for debug_panel
- added auto cultivation when on a vehicle
- added /c cultivate to manually start cultivating
- added tooltips to meters

## [0.0.5]

### Alpha
- fixed gamma and added classic support 

## [0.0.4]

### Alpha
- added brightness, contrast, and gamma setting when values change
- added animations while cultivating

## [0.0.3]

### Alpha

- Added cultivation
- Updated README
- Got project ready for CurseForge
- Improved assets and algoritms for Hunger / Thirst 

## [0.0.2]

### Alpha

- Rename and complete rewrite

## [0.0.1]

### Alpha

- Fork from CozyCamps
