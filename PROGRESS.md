# Riftwardens - Development Progress

## Current Status: V2 Buildcraft System - Phase 6 Balance Testing 🔄

### V2 System Status
| Phase | Name | Status |
|-------|------|--------|
| Phase 1 | Tag & Stat Model | ✅ COMPLETE |
| Phase 2 | Veteran Warden | ✅ COMPLETE |
| Phase 3 | V2 Card Pool | ✅ COMPLETE (48 cards) |
| Phase 4 | V2 Artifact System | ✅ COMPLETE (26 artifacts) |
| Phase 5 | Shop & Reward Rework | ✅ COMPLETE |
| Phase 6 | Balance & Integration | 🔄 IN PROGRESS |
| Phase 7 | Enemy & Wave Rework | ✅ COMPLETE |
| Phase 8 | New Wardens | ⏳ FUTURE |

### Scenes & Navigation
| Scene | Status | Notes |
|-------|--------|-------|
| Main Menu | ✅ Working | Title, buttons functional |
| Settings | ✅ Working | Audio/Gameplay/Display settings with persistence |
| Warden Select | ✅ Working | **4 wardens** (Ash, Gloom, Glass, Veteran) |
| Combat | ✅ Working | **V2 card system, 48 cards**, 10 enemies |
| Shop | ✅ Working | **V2 structure** (4 cards, 3 artifacts, 2 services) |
| Post-Wave Reward | ✅ Working | Card/Scrap/Heal choices |
| Run End | ✅ Working | Victory/Defeat screens |
| Meta Menu | ❓ Untested | Scene exists |

### Core Systems
| System | Status | Notes |
|--------|--------|-------|
| SettingsManager | ✅ Working | Persistent settings saved to user://settings.cfg |
| GameManager | ✅ Working | Scene transitions, state management |
| RunManager | ✅ Working | **V2 PlayerStats**, damage multipliers, stat modifiers |
| CombatManager | ✅ Working | Full turn flow, enemy spawning, card playing, artifact triggers |
| CardDatabase | ✅ Complete | **48 V2 cards** across 5 build families |
| EnemyDatabase | ✅ Complete | 10 enemies (5 grunts, 4 elites, 1 boss) |
| MergeManager | ✅ Working | Full implementation with shop UI integration |
| ArtifactManager | ✅ Complete | **26 V2 artifacts** with tag-based effects |
| ShopGenerator | ✅ **NEW** | V2 family biasing, dynamic pricing |
| AudioManager | ✅ Working | Procedural placeholder SFX, volume control |

### V2 Content Summary
| Content | Count | Notes |
|---------|-------|-------|
| Cards | 48 | Gun (12), Hex (12), Barrier (12), Lifedrain (7), Overlap (5) |
| Artifacts | 26 | Core (10), Lifedrain (4), Hex (4), Barrier (4), Volatile (4) |
| Enemies | 11 | Husk, Spitter, Spinecrawler, Bomber, Cultist, Shell Titan, Torchbearer, Channeler, Stalker, **Armor Reaver**, Ember Saint |
| Wardens | 4 | Ash, Gloom, Glass, **Veteran** (V2 baseline) |
| Build Families | 4 | Gun Board, Hex Ritualist, Barrier Fortress, Lifedrain Bruiser |
| Wave Bands | 4 | Onboarding (1-3), Build Check (4-6), Stress (7-9), Boss (10-12) |

### Combat Features
| Feature | Status | Notes |
|---------|--------|-------|
| Ring Battlefield | ✅ Working | 4 rings, enemies spawn and move |
| Card Hand UI | ✅ Working | Cards display, clickable, hover effects |
| Turn System | ✅ Working | Draw → Play → End Turn → Enemy Phase |
| Enemy AI | ✅ Working | Movement, melee/ranged attacks, special abilities |
| Card Effects | ✅ Full | 18+ effect types implemented |
| Damage System | ✅ Working | **V2 stat multipliers applied** |
| Threat Preview | ✅ Working | Shows incoming damage calculation |
| Enemy Display | ✅ Working | Multi-row distribution + overflow stacking |
| Enemy Abilities | ✅ Working | Bomber explodes, Channeler spawns, Torchbearer buffs |
| Artifact Triggers | ✅ Working | **26 V2 artifacts** hooked into combat |
| Warden Passives | ✅ Working | **4 wardens** with functional passives |
| Debug Stat Panel | ✅ Working | Press F3 in combat to view all PlayerStats |
| **Combat Lane** | ✅ **NEW** | Hearthstone-style board for persistent weapons |

### Art & Polish
| Item | Status |
|------|--------|
| Placeholder Art | 🔶 Colored shapes (no textures) |
| Animations | ✅ Card hover, turn banners, enemy movement, card fly, attack indicators |
| Particles | ✅ Death burst effects, projectile trails, impact flashes |
| Screen Effects | ✅ Damage shake, floating numbers, screen transitions, enemy shake on hit |
| Sound Effects | ✅ Placeholder procedural audio (AudioManager) |
| Visual Feedback | ✅ Attack targeting, projectiles, hex flash, barrier glow, weapon icons |

---

## Completed Implementation Phases

### V1 Foundation (Complete)
- [x] Phase 1: Project setup, resources, state classes
- [x] Phase 2: Combat system (battlefield, turns, cards, enemies)
- [x] Phase 3: Deck management, merge system
- [x] Phase 4: Combat UI (arena, card hand, threat preview)
- [x] Phase 5: Wardens (4 with passives)
- [x] Phase 6: Enemy archetypes, wave scripting
- [x] Phase 7: Reward/Shop/Artifact systems
- [x] Phase 8: Meta progression (structure exists)
- [x] Phase 9: Polish (animations, particles, effects)
- [x] Phase 10: Content expansion
- [x] Phase 11: Enemy special abilities
- [x] Phase 12: Artifact trigger wiring
- [x] Phase 13: Warden passive implementation
- [x] Phase 14: MergeManager UI integration
- [x] Phase 15: AudioManager
- [x] Phase 16: Screen transitions
- [x] Phase 17: Combat Clarity system
- [x] Phase 18: Combat Visual Feedback

### V2 Buildcraft Rework (In Progress)
- [x] V2 Phase 1: Tag & Stat Model (TagConstants, PlayerStats, DebugStatPanel)
- [x] V2 Phase 2: Veteran Warden (V2 baseline, 10-card starter)
- [x] V2 Phase 3: V2 Card Pool (48 cards, V1 cards removed)
- [x] V2 Phase 4: V2 Artifact System (26 artifacts, stackable, tag-based)
- [x] V2 Phase 5: Shop & Reward Rework (ShopGenerator, family biasing)
- [ ] V2 Phase 6: Balance & Integration Testing
- [x] V2 Phase 7: Enemy & Wave Rework ✅
- [ ] V2 Phase 8: New Extreme Wardens

## Remaining Work (V2 Buildcraft)
1. **Phase 6**: Balance testing - verify all 4 build families are viable
2. **Phase 8**: New extreme wardens (Plaguer, Architect, Sanguine)
3. See `V2_IMPLEMENTATION_PLAN.md` for full details

## Recently Completed (V2 Implementation)

- ### Combat Lane System ✅ COMPLETE
- ✅ **CombatLane.gd** - UI component for persistent weapon display
  - Positioned between battlefield and card hand
  - Cards auto-scale to fill ~80% of the lane height (recomputed on resize)
  - Lane frame always visible; label shows slot usage (0/7 → 7/7)
  - Maximum 7 weapons deployed at once

- ✅ **Deploy Animation**:
  - Cards fly from hand to lane with shrink effect
  - Bounce effect when card lands in lane (no glow border)
  
- ✅ **Fire Effects**:
  - Weapon cards pulse when triggering (no persistent highlight)
  - Damage floater (-X⚔) rises from fired weapon
  
- ✅ **Integration**:
  - Connected to CombatManager.weapon_triggered signal
  - Weapons auto-deploy when persistent card played
  - Hovering a deployed weapon spawns a separate canvas-layer preview without altering base card scale
  
- ✅ **Unit Tests**:
  - Deploy/remove weapon tests
  - Fire animation tests
  - Capacity limit tests

### V2 Phase 5: Shop & Reward Rework ✅ COMPLETE
- ✅ **ShopGenerator.gd** - New autoload for V2 shop generation
  - 4 card slots (was 3), 3 artifact slots (was 2), 2 services
  - Family tracking: counts cards/artifacts by build family
  - `get_primary_secondary_families()` for build lean detection
  
- ✅ **Family Biasing**:
  - Early waves (1-3): 70% focused shops, 2+ cards from same family
  - Mid/late waves (4+): Primary family +2.0 weight, secondary +1.0
  - Guarantees 2+ primary family cards when player is committed
  
- ✅ **Dynamic Pricing**:
  - Reroll cost: `3 + floor((wave - 1) / 3) + reroll_count * 2`
  - Heal service: 30% missing HP, cost = `10 + 2 * wave`
  - Remove card: cost = `10 + 3 * wave`

### V2 Phase 4: Artifact System ✅ COMPLETE
- ✅ **26 V2 Artifacts** organized by family:
  - Core Stat (10): Sharpened Rounds, Hex Lens, Reinforced Plating, etc.
  - Lifedrain (4): Leech Core, Hemorrhage Engine (rare), etc.
  - Hex Ritual (4): Occult Focus, Creeping Doom (rare), etc.
  - Barrier (4): Trap Engineer, Punishing Walls (rare), etc.
  - Volatile (4): Kinetic Harness, Last Stand Protocol (rare), etc.
  
- ✅ **Stackable System**: `stackable: bool` per artifact, unlimited stacking
- ✅ **Tag-based Effects**: `required_tags` for family-specific bonuses

### V2 Phase 3: Card Pool ✅ COMPLETE
- ✅ **48 V2 Cards** across 5 build families:
  - Gun Board (12): Persistent weapons, shotgun/sniper variants
  - Hex Ritualist (12): Hex stacking, ritual synergies
  - Barrier Fortress (12): Barriers, armor, fortress effects
  - Lifedrain Bruiser (7): Healing on damage/kill
  - Overlap/Engine (5): Multi-family synergy cards
  
- ✅ **V1 Cards Removed**: All legacy cards deleted

### V2 Phase 2: Veteran Warden ✅ COMPLETE
- ✅ **Veteran** - V2 baseline warden (HP 70, Energy 3, all stats neutral)
- ✅ **10-card Starter Deck**: Rusty Pistol×2, Minor Hex, Minor Barrier, Guard Stance×2, Precision Strike×2, Shove×2

### V2 Phase 1: Tag & Stat Model ✅ COMPLETE
- ✅ **TagConstants.gd** - Canonical tag names
- ✅ **PlayerStats.gd** - V2 stat sheet with additive multipliers
- ✅ **RunManager.gd** - Uses PlayerStats, `get_damage_multiplier_for_card()`
- ✅ **DebugStatPanel.gd** - Press F3 in combat to view all stats

---

## Previous Session
- ✅ **Restored Persistent Weapon Fun** - Starter deck now has auto-firing weapons:
  - **Rusty Pistol** converted from instant to **persistent** (3 dmg to ANY ring at turn end)
  - Veteran starter deck has **2x Rusty Pistol** that auto-fire every turn
  - This creates the "ramp up" fun of deploying weapons early that auto-fire every turn

## Previous Session (Group Animation Fix)
- ✅ **Fixed Group Card Movement Animation Bug** - Groups no longer fly from (0,0):
  - Root cause: When groups moved between rings, the stack_key changed (includes ring number)
  - Old position was stored under old key (e.g., `3_husk_group_1`) but new stack used new key (`2_husk_group_1`)
  - **Fix**: Added `_group_positions` dictionary to track positions by group_id (which persists across rings)
  - When destroying a stack, position is saved to `_group_positions[group_id]`
  - When creating new stack, position is restored from `_group_positions` if no stack_key position exists
  - First-time placements now skip animation (appear directly at target position)
  - Cross-ring movements now smoothly animate from old position to new position

- ✅ **Danger Highlighting** - Pulsing glow effects on high-priority threats:
  - **CRITICAL (Red, fast pulse)**: Bombers about to explode
  - **HIGH (Orange)**: Enemies reaching melee next turn
  - **MEDIUM (Purple)**: Active buffers/spawners at target ring
  - **LOW (Cyan)**: Fast enemies (speed 2+) not yet close
  - Glowing border with outer shadow effect
  - Pulse speed varies by urgency
  - Updates on turn start and enemy movement

- ✅ **Turn Countdown Badges** - Shows how many turns until each enemy reaches melee:
  - Badge appears on every enemy panel (top-right corner for regular, below behavior badge for stacks)
  - Color coding: Red "⚔️" (in melee), Orange "→1" (1 turn away), Yellow "→2", Green "→3+", Blue "—" (ranged)
  - Tooltips explain what each badge means
  - Updates dynamically as enemies move between rings
  - Works with individual enemies, stacked enemies, and mini-panels

## Previously Completed
- ✅ **Combat Visual Feedback System** - Slay the Spire-style animations and telegraphing:
  - **CombatAnimationManager**: New autoload for sequencing combat animations
  - **Attack Indicators**: Target reticles (┌┐└┘) appear around enemies before being hit
  - **Projectile Effects**: Bullets fly from warden (center) to targets with trailing effects
  - **Enemy Shake**: Hit enemies shake with intensity proportional to damage dealt
  - **Hex Flash**: Purple flash when hex damage triggers (vs red for normal damage)
  - **Stack Targeting**: When attacking stacked enemies, stack expands to show which one was hit
  - **Card Fly Animation**: Cards animate from hand position to target (or weapon panel/HP bar based on effect)
  - **Weapon Icons Panel**: Active persistent weapons displayed as visual icons with damage values
  - **Weapon Fire Animation**: Icons pulse when weapons trigger, label shows "🔫 WeaponName fires!"
  - **Barrier Ring Visuals**: Rings with barriers show pulsing green glow, 🚧 icons along arc, damage/duration display
  - **Signal System**: Added `enemy_targeted`, `barrier_placed`, `barrier_triggered` signals for visual coordination
  - **Timing Constants**: Animation delays similar to Slay the Spire (0.15s card play, 0.25s target highlight, etc.)

## Previous Session Completions
- ✅ **Card Description Labels** - Cards now explicitly show "Instant:" and "Persistent:" labels:
  - Added `instant_description` and `persistent_description` fields to `CardDefinition`
  - CardUI now displays labeled effect descriptions with colored prefixes (blue=Instant, gold=Persistent)
  - Cards with both effects display both labeled sections
  - Auto-generates labels for existing cards via fallback system
  - New card: **Rift Turret** (2 cost, deals instant damage + persists firing each turn)

- ✅ **Combat Clarity System** - Three-layer UX improvement to reduce cognitive overload:
  - **Layer 1: Behavior Badges** - Enemy panels now show archetype badges (🏃⚡🏹💣📢⚙️🛡️🗡️👑) in top-left corner
  - **Layer 2: Ring Threat Colors** - Ring borders dynamically color-coded by threat level (green/yellow/orange/red), pulses for lethal damage
  - **Layer 3: Aggregated Intent Bar** - Top bar shows: ⚔️ incoming damage, 💣 bomber count, 📢 buff status, ⚙️ spawner status, ⚡ fast enemies
  - Added `behavior_type` enum to EnemyDefinition with 9 archetypes
  - All 10 enemies assigned appropriate behavior types
  - Unit tests added: `_run_behavior_type_tests()` and `_run_intent_bar_tests()` (64 tests passing)
  - Design document: `Combat_Clarity.md` with future enhancement roadmap

## Previous Session Completions
- ✅ **Settings Menu**:
  - Created `SettingsManager.gd` autoload for persistent settings
  - Settings saved to `user://settings.cfg` using ConfigFile
  - Audio settings: Master/SFX/Music volume sliders (0-100%), Mute toggle
  - Gameplay settings: Screen Shake, Damage Numbers, Auto End Turn toggles
  - Display settings: Fullscreen, VSync toggles
  - Settings UI at `scenes/Settings.tscn` with `scripts/ui/Settings.gd`
  - Main Menu "Settings" button now navigates to Settings screen
  - Reset to Defaults button restores all settings
  - All settings apply immediately and persist across sessions

## Previous Session Completions
- ✅ **MergeManager UI Integration**:
  - Shop now shows "Available Merges" section when 3 copies of a card exist
  - Merge/Decline buttons with cost display
  - Auto-detects merges after buying cards or removing cards
  - `MergeManager.execute_merge()` removes 3 cards, adds 1 upgraded
- ✅ **AudioManager Autoload**:
  - Created `scripts/autoloads/AudioManager.gd`
  - 8-channel audio pool for overlapping sounds
  - Procedurally generated placeholder tones for all events
  - Sound effects: card_play, damage_dealt, damage_taken, enemy_death, heal, armor_gain, hex_apply, turn_start, turn_end, wave_complete, wave_fail, button_click, merge_complete, shop_purchase, error
  - Hooks in CombatManager, RunManager, and Shop
- ✅ **Screen Transitions**:
  - GameManager now has fade transition system
  - All scene changes use 0.3s fade out/in
  - Dark purple overlay on CanvasLayer 100

## Previous Session Completions
- ✅ Wired enemy special abilities (Bomber, Channeler, Torchbearer, Ember Saint)
- ✅ Wired ALL artifact triggers into CombatManager
- ✅ Implemented Warden passives (Ash, Gloom, Glass)

## Previous Session Completions
- ✅ Implemented enemy display system with multi-row distribution and overflow stacking
- ✅ Added expand-on-hover for stacked enemies showing individual HP bars
- ✅ Added damage feedback on stacked enemies (brief expand, flash, counter update)
- ✅ Expanded CardDatabase from 4 to 26 cards
- ✅ Expanded EnemyDatabase from 2 to 10 enemies
- ✅ Added 10 artifacts to ArtifactManager
- ✅ Added 6 new card effect types to CardEffectResolver
- ✅ Fixed Combat UI battlefield rendering and restored enemy tooltips
- ✅ Enlarged the combat arena so rings + enemy panels scale to the full screen height/width
- ✅ Centered the arena on screen and expanded ring/enemy sizing to use the new space
- ✅ Fixed armor consumption - armor now properly absorbs damage before being depleted
- ✅ Fixed enemy positioning - enemies now appear inside ring zones instead of on ring borders
- ✅ Implemented drag-and-drop card targeting - drag cards to rings instead of using popup selector
- ✅ Fixed persistent weapons (Infernal Pistol) now trigger at end of turn (before enemy phase)
- ✅ Added hex visual indicator - enemies with hex now show "☠️ X" above them
- ✅ Doubled card size from 120x170 to 220x320 with all fonts scaled up
- ✅ Redesigned HP/Armor UI - now shown near battlefield center (Slay the Spire style)
- ✅ Added HP bar with color gradient (green → yellow → red)
- ✅ Armor now updates immediately when gained/lost (with flash animation)
- ✅ Added armor_changed signal for reactive UI updates

## How to Test
1. Open project in Godot 4.5+
2. Press F5 to run
3. Click "New Run" → Select a Warden → "Start"
4. In Combat: Click cards to play, "End Turn" to progress

## Legend
- ✅ Working/Complete
- 🔶 Partial/Minimal
- ❓ Untested
- ❌ Not implemented
