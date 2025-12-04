# Riftwardens - Development Progress

## Legend
- ✅ Working/Complete
- 🔶 Partial/Minimal
- ❓ Untested
- ⏳ Future/Planned
- 🔄 In Progress

## Current Status: V3 Queue & Execute System ✅

### V3 Combat System Implementation
| Phase | Name | Status |
|-------|------|--------|
| Phase 1 | CardDefinition cleanup (remove duration fields, add lane_buff) | ✅ COMPLETE |
| Phase 2 | CombatManager staging logic (staged_cards array, execute method) | ✅ COMPLETE |
| Phase 3 | CombatLane staging UI (drag-reorder, execute button) | ✅ COMPLETE |
| Phase 4 | CardEffectResolver lane context (buffs, guns_fired tracking) | ✅ COMPLETE |
| Phase 5 | CardDatabase V3 cards (starter deck, lane buffs, scaling) | ✅ COMPLETE |
| Phase 6 | CombatScreen wire-up (staging signals, execute flow) | ✅ COMPLETE |
| Phase 7 | DeckManager cleanup (remove deployed zone) | ✅ COMPLETE |
| Phase 8 | Remove old files (StarterWeaponSelect, PistolVisual3D) | ✅ COMPLETE |
| Phase 9 | DESIGN.md documentation update | ✅ COMPLETE |

### V3 Key Changes
- **Two card types**: Combat cards go to staging lane, Instant cards resolve immediately
- **All weapons one-and-done** - No more persistence, weapons return to discard
- **Queue & Execute** - Play multiple cards, then execute all at once from left to right
- **Lane Buffs** - Instant buff cards modify cards already in staging lane
- **Scaling Cards** - Some cards get stronger based on what's already been played
- **Fixed Starter Deck** - No more starter weapon selection, predefined 10-card deck
- **Tag Tracker** - UI panel showing which tags have been played and how many times
- **Removed**: duration_type, duration_turns, duration_kills, on_expire, deployed zone

---

## V3 Content Summary

### Veteran Starter Deck (10 cards)
| Card | Type | Cost | Effect |
|------|------|------|--------|
| Pistol ×3 | Weapon | 1 | Deal 3 damage to random enemy |
| Shotgun ×2 | Weapon | 2 | Deal 4 damage + 2 splash |
| Guard Stance ×2 | Skill | 1 | Gain 4 armor |
| Minor Hex ×1 | Skill | 1 | Apply 3 hex |
| Gun Amplifier ×1 | Skill | 1 | +2 damage to guns this turn |
| Tactical Reload ×1 | Skill | 0 | Draw 2 cards |

### New Effect Types
- `lane_buff_damage` - Buff subsequent gun damage
- `lane_buff_hex` - Buff subsequent hex application
- `lane_buff_armor` - Buff subsequent armor gain
- `scales_with_lane` - Card scales with guns fired this turn

### Removed Systems
- Persistent weapon deployment
- Weapon duration tracking (turns, kills, burn_out)
- StarterWeaponSelect scene
- PistolVisual3D weapon visuals
- deployed/banished zones in DeckManager

---

## Battlefield UI (Unchanged from V2)

### Lane-Based Placement System
- ✅ 12 fixed lanes for enemy positioning
- ✅ Lane preservation on ring movement
- ✅ Non-overlap enforcement (12px buffer)
- ✅ Z-order by ring (Melee on top)

### Stack System
- ✅ Mini-panel expansion on hover
- ✅ Real-time HP updates
- ✅ Death animations
- ✅ Encyclopedia cards

### Combat Clarity
- ✅ Behavior badges on enemies
- ✅ Ring threat colors
- ✅ Aggregated intent bar
- ✅ Danger highlighting
- ✅ Card targeting hints

---

## Quick Reference

### Scenes & Navigation
| Scene | Status | Notes |
|-------|--------|-------|
| Main Menu | ✅ Working | Title, buttons functional |
| Settings | ✅ Working | Audio/Gameplay/Display settings |
| Warden Select | ✅ Working | 4 wardens → starts with fixed deck |
| Combat | ✅ Working | V3 staging system |
| Shop | ✅ Working | Cards, artifacts, stat upgrades |
| Run End | ✅ Working | Victory/Defeat screens |

### Removed Scenes
- StarterWeaponSelect.tscn (replaced by fixed starter deck)
- TestPistolVisual.tscn (weapon visuals removed)

### Full Content Summary
| Content | Count | Notes |
|---------|-------|-------|
| Cards | ~30 | V3 cards (starter + lane buffs + scaling) |
| Artifacts | 26+ | Core stat + family artifacts |
| Stat Upgrades | 8 | Energy, Draw, HP, Gun%, Hex%, Armor%, Scrap%, Shop% |
| Enemies | 11 | Weakling, Husk, Spitter, Spinecrawler, Bomber, etc. |
| Wardens | 4 | Ash, Gloom, Glass, Veteran |
| Waves | 20 | Brotato Economy |
| Build Families | 4 | Gun Board, Hex Ritualist, Barrier Fortress, Lifedrain |

---

## Recently Fixed (Dec 4, 2025)

### Shield Barrier Visual Effects (Latest)
- ✅ **Persistent Barrier Indicator** - Active barriers show on the ring the entire time:
  - Pulsing green arc along the ring edge
  - Label shows "🛡️ X dmg × Y" (damage amount and remaining uses)
  - Updates when uses are consumed
  - Clear visual feedback so player knows barrier is active
- ✅ **Barrier Placement Visual** - When placing a Shield Barrier, the ring shows visual feedback:
  - Green wave effect sweeps along the targeted ring arc
  - Shield particles spawn and pulse along the barrier position
- ✅ **Barrier Trigger Visual** - When enemies cross a barrier and take damage:
  - Shield burst flash effect at the barrier impact point
  - Green sparks fly from barrier toward the damaged enemy
  - Floating "🛡️ -X" damage text appears at barrier position
  - **Enemy stack expands** to show individual units so player can see which enemy was hit
  - Stack shakes and flashes green to draw attention to the damaged unit
- ✅ **Barrier Consumption** - Barriers now properly consume uses:
  - Each enemy crossing consumes 1 use
  - When uses reach 0, barrier disappears with "break" particle effect
  - Visual updates immediately to show remaining uses
- ✅ **Barrier State Sync** - Visual always matches actual barrier state

### Files Changed (Barrier Visuals)
- `scripts/combat/BattlefieldArena.gd` - Added signal handlers for `barrier_placed`, `barrier_triggered`, `barrier_consumed`; added `_sync_barrier_visual()`, `_create_barrier_break_effect()` methods
- `scripts/combat/nodes/BattlefieldEffectsNode.gd` - Added `create_barrier_wave()`, `create_barrier_hit_effect()` methods
- `scripts/combat/nodes/BattlefieldRings.gd` - Enhanced `_draw_barrier_ring()` to show damage/uses label with background
- `scripts/combat/BattlefieldState.gd` - Added `barrier_consumed` signal, barriers now decrement uses when triggered
- `scripts/autoloads/CombatManager.gd` - Added `barrier_consumed` signal relay

### Instant Ring-Targeting Cards - Drag to Battlefield (Earlier)
- ✅ **New feature**: Instant cards that affect specific rings can now be dragged to the battlefield
  - Added `requires_ring_target()` helper method to CardDefinition
  - Cards with `play_mode = "instant"`, `target_type = "ring"`, and `requires_target = true` trigger this behavior
  - When dragging such a card, the valid target ring highlights green when hovered
  - Drop on a valid ring to play the card targeting that ring
  - Example: **Shield Barrier** - drag to Close/Mid/Far ring to place the barrier there

### Files Changed (Ring-Targeting)
- `scripts/resources/CardDefinition.gd` - Added `requires_ring_target()` helper
- `scripts/ui/CombatScreen.gd` - Added ring highlighting during drag for instant ring-targeting cards
- `scripts/autoloads/CombatManager.gd` - Added optional `target_ring` parameter to `stage_card()`

### Hex Visual Feedback System (Earlier)
- ✅ **Fixed missing hex visuals** - Hex cards now show proper visual feedback when applied
  - Connected `enemy_hexed` signal in BattlefieldArena (was emitted but never listened to)
  - Added `_on_enemy_hexed()` handler with:
    - **Purple flash** on affected enemies (0.2 second duration)
    - **Floating hex indicator** (+☠X number that floats up and fades)
    - **Purple particles** spawn around affected enemies
    - **Panel update** - Enemy panels and mini-panels now show hex status immediately

### Files Changed (Hex Visual Fix)
- `scripts/combat/BattlefieldArena.gd` - Added `enemy_hexed` signal connection and handler
- `scripts/combat/nodes/BattlefieldEffectsNode.gd` - Added `spawn_hex_particles()` method

### Card Types & Tag System Overhaul (Earlier)
- ✅ **Combat vs Instant cards** - Added `play_mode` field to CardDefinition ("combat" or "instant")
  - **Combat cards**: Go to staging lane, execute in order when "End Turn" is clicked
  - **Instant cards**: Resolve immediately when played, don't go to staging lane
- ✅ **Fixed Gun Amplifier bug** - Was showing +0 damage due to wrong placeholder (`{scaling}` → `{lane_buff_value}`)
- ✅ **Tag Tracker Panel** - New UI panel on right side of combat screen showing tag counts
  - Updates instantly when tags are played (either instant or combat card execution)
  - Shows all tags with icons and colors (gun, hex, aoe, piercing, etc.)
- ✅ **Card UI shows all tags** - Cards now display damage type tags (piercing, explosive, beam) and mechanical tags (aoe, sniper, scaling)
- ✅ **Instant/Combat badge** - Cards show "⚡ INSTANT" (cyan) or "⚔️ COMBAT" (orange) in footer

### Instant Cards (12 total)
| Card | Type | Effect |
|------|------|--------|
| Gun Amplifier | buff | +2 damage to guns in lane |
| Power Surge | buff | +3 damage to all cards in lane |
| Rapid Fire Protocol | buff | Next gun fires twice |
| Hex Infusion | buff | Guns in lane apply 2 hex |
| Armor Plating | buff | Guns grant 1 armor on execute |
| Iron Shell | defense | Gain 4 armor |
| Heavy Armor | defense | Gain 8 armor |
| Reactive Armor | defense | Gain 4 armor + heal 3 |
| Healing Surge | skill | Heal 5 HP |
| Quick Draw | skill | Draw 2 cards |
| Double Time | skill | Draw 3 cards |
| Shove | skill | Push enemy back 1 ring |
| Push Back | skill | Push all melee back 1 ring |
| Shield Barrier | defense | Place barrier trap |

### Combat Cards (All weapons and damage-dealing cards)
Pistol, Shotgun, Heavy Pistol, Assault Rifle, Sniper Rifle, Armored Tank, Chain Gun, Rocket Launcher, Beam Cannon, Piercing Shot, Finisher, Hex Bolt, Hex Cloud, Concentrated Hex, etc.

### V3 System Cleanup (Earlier)
- ✅ **Added `can_play_card()` alias** - CombatManager now has `can_play_card()` that delegates to `can_stage_card()` for backward compatibility
- ✅ **Updated all warden starter decks** - All 4 wardens now use V3 card IDs (pistol, shotgun, hex_bolt, iron_shell, etc.)
- ✅ **Updated TestRunner.gd** - All tests now use V3 card IDs and correct function names
- ✅ **Removed overclock_capacitor artifact** - Replaced with `staging_capacitor` (first card staged is free)
- ✅ **Fixed test references** - Updated `_calculate_enemy_attack_damage()` to `calculate_incoming_damage()`

### Files Changed (V3 Cleanup)
- `scripts/autoloads/CombatManager.gd` - Added `can_play_card()` compatibility alias
- `scripts/ui/WardenSelect.gd` - Updated all 4 warden starter decks with V3 card IDs
- `scripts/tests/TestRunner.gd` - Updated all card references and test logic for V3
- `scripts/autoloads/ArtifactManager.gd` - Replaced obsolete `overclock_capacitor` with `staging_capacitor`

### Critical Bug Fixes (Earlier)
- ✅ **Fixed `active_weapons` crash** - CombatManager no longer uses `active_weapons` property (removed in V3), updated `DebugStatPanel.gd` and `TestRunner.gd` to use `staged_cards` instead
- ✅ **Fixed deck initialization type mismatch** - `RunManager.initialize_starter_deck()` was storing CardDefinition objects instead of `{card_id, tier}` dictionaries, causing DeckManager to crash

---

## In Progress / Future Work

### V3 Testing Needed
- [x] Test staging lane drag-and-drop reordering - PASSED
- [x] Test execute button triggers all cards - PASSED
- [x] Test lane buffs apply to subsequent cards - PASSED
- [ ] Test scaling cards (Armored Tank, Chain Lightning)
- [x] Verify cards return to discard after execution - PASSED
- [x] Test enemy phase runs after execution completes - PASSED

### Future Card Pool Expansion
- [ ] Add more lane buff varieties
- [ ] Add more scaling weapons
- [ ] Balance starter deck difficulty

---

## How to Test V3

1. Open project in Godot 4.5+
2. Press F5 to run
3. Click "New Run" → Select a Warden → Combat starts with fixed deck
4. In Combat:
   - Drag cards to the staging lane (bottom area)
   - Reorder cards by dragging left/right
   - Click "End Turn" or "Execute" to trigger all staged cards
   - Watch cards execute left-to-right with lane buffs applied
5. Verify cards go to discard pile after execution
