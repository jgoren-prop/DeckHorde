# Riftwardens - Development Progress

## Current Status: Mechanically Complete Prototype ✅

### Scenes & Navigation
| Scene | Status | Notes |
|-------|--------|-------|
| Main Menu | ✅ Working | Title, buttons functional |
| Settings | ✅ Working | Audio/Gameplay/Display settings with persistence |
| Warden Select | ✅ Working | 3 wardens, difficulty slider |
| Combat | ✅ Working | Full card system, 27 cards, 10 enemies |
| Shop | ✅ Working | Buy cards, remove cards, heal, reroll |
| Post-Wave Reward | ✅ Working | Card/Scrap/Heal choices |
| Run End | ✅ Working | Victory/Defeat screens |
| Meta Menu | ❓ Untested | Scene exists |

### Core Systems
| System | Status | Notes |
|--------|--------|-------|
| SettingsManager | ✅ Working | Persistent settings (audio, display, gameplay) saved to user://settings.cfg |
| GameManager | ✅ Working | Scene transitions, state management |
| RunManager | ✅ Working | HP, scrap, wave tracking, damage/healing, warden passives |
| CombatManager | ✅ Working | Full turn flow, enemy spawning, card playing, artifact triggers |
| CardDatabase | ✅ Complete | 27 cards across 4 types |
| EnemyDatabase | ✅ Complete | 10 enemies (5 grunts, 4 elites, 1 boss) |
| MergeManager | ✅ Working | Full implementation with shop UI integration |
| ArtifactManager | ✅ Complete | 10 artifacts with ALL triggers wired |
| AudioManager | ✅ Working | Procedural placeholder SFX, volume control |

### Combat Features
| Feature | Status | Notes |
|---------|--------|-------|
| Ring Battlefield | ✅ Working | 4 rings, enemies spawn and move |
| Card Hand UI | ✅ Working | Cards display, clickable, hover effects |
| Turn System | ✅ Working | Draw → Play → End Turn → Enemy Phase |
| Enemy AI | ✅ Working | Movement, melee/ranged attacks, special abilities |
| Card Effects | ✅ Full | 18 effect types implemented |
| Damage System | ✅ Working | Player/enemy damage, death handling |
| Threat Preview | ✅ Working | Shows incoming damage calculation |
| Enemy Display | ✅ Working | Multi-row distribution + overflow stacking |
| Enemy Abilities | ✅ Working | Bomber explodes, Channeler spawns, Torchbearer buffs |
| Artifact Triggers | ✅ Working | All 10 artifacts hooked into combat |
| Warden Passives | ✅ Working | All 3 wardens have functional passives |

### Content
| Content | Status | Count |
|---------|--------|-------|
| Cards | ✅ Complete | 27 (9 weapons, 6 skills, 6 hexes, 6 defense) |
| Enemies | ✅ Complete | 10 (5 grunts, 4 elites, 1 boss) with special abilities |
| Wardens | ✅ Complete | 3 (Ash, Gloom, Glass) with working passives |
| Artifacts | ✅ Complete | 10 artifacts with ALL triggers wired |
| Waves | ✅ Generator | WaveDefinition auto-generates based on wave # |

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
- [x] Phase 1: Project setup, resources, state classes
- [x] Phase 2: Combat system (battlefield, turns, cards, enemies)
- [x] Phase 3: Deck management, merge system
- [x] Phase 4: Combat UI (arena, card hand, threat preview)
- [x] Phase 5: Wardens (3 with passives - NOW WORKING)
- [x] Phase 6: Enemy archetypes, wave scripting
- [x] Phase 7: Reward/Shop/Artifact systems (scenes exist)
- [x] Phase 8: Meta progression (structure exists)
- [x] Phase 9: Polish (animations, particles, effects)
- [x] Phase 10: Content expansion (26 cards, 10 enemies, 10 artifacts)
- [x] Phase 11: Enemy special abilities (Bomber, Channeler, Torchbearer, Ember Saint)
- [x] Phase 12: Artifact trigger wiring (all 10 artifacts functional)
- [x] Phase 13: Warden passive implementation (all 3 wardens functional)
- [x] Phase 14: MergeManager UI integration (shop merge section, merge detection)
- [x] Phase 15: AudioManager (placeholder procedural SFX for all events)
- [x] Phase 16: Screen transitions (fade effect on scene changes)
- [x] Phase 17: Combat Clarity system (behavior badges, threat colors, intent bar)
- [x] Phase 18: Combat Visual Feedback (attack indicators, projectiles, shake, card fly animation, weapon icons, barrier visuals)

## Next Steps
1. Balance tuning (difficulty curve, artifact costs)
2. Replace placeholder audio with real sound files
3. More visual polish (real textures, UI improvements)
4. Meta progression save/load

## Recently Completed (This Session)
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
