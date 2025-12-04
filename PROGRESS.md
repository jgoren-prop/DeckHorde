# Riftwardens - Development Progress

## Legend
- ✅ Working/Complete
- 🔶 Partial/Minimal
- ❓ Untested
- ⏳ Future/Planned
- 🔄 In Progress

## Current Status: V2 Weapon Duration System ✅

### Brotato Economy Implementation Status
| Phase | Name | Status |
|-------|------|--------|
| Phase 1 | Starter Weapon Selection | ✅ COMPLETE |
| Phase 2 | Starting Resources (1 energy, 1 draw, 50 HP) | ✅ COMPLETE |
| Phase 3 | Interest System (5% scrap, max 25) | ✅ COMPLETE |
| Phase 4 | Wave System (20 waves, Weakling enemy) | ✅ COMPLETE |
| Phase 5 | Stat Upgrades in Shop | ✅ COMPLETE |
| Phase 6 | Weapon Slot Limit | ❌ REMOVED (V2) |
| Phase 7 | Documentation | ✅ COMPLETE |

### V2 Weapon Duration System (NEW)
| Phase | Name | Status |
|-------|------|--------|
| Phase 1 | Duration types on CardDefinition | ✅ COMPLETE |
| Phase 2 | DeckManager deployed/banished zones | ✅ COMPLETE |
| Phase 3 | CombatManager duration countdown | ✅ COMPLETE |
| Phase 4 | Remove weapon slot limit | ✅ COMPLETE |
| Phase 5 | Update starter weapons with durations | ✅ COMPLETE |
| Phase 6 | Warden starter bundles | ✅ COMPLETE |

### V2 Brainstorm Implementation Status
| Phase | Name | Status |
|-------|------|--------|
| Phase 1 | Foundation (Stats, Tags, Triggers) | ✅ COMPLETE |
| Phase 2 | Effect System (CardEffectResolver) | ✅ COMPLETE |
| Phase 3 | Starter Deck (10 cards) | ✅ COMPLETE |
| Phase 4 | Persistent Cards (17 cards) | ✅ COMPLETE |
| Phase 5 | Instant Cards (24 cards) | ✅ COMPLETE |
| Phase 6 | Damage-Type Artifacts (8) | ✅ COMPLETE |
| Phase 7 | Deployed Gun Artifacts (7) | ✅ COMPLETE |
| Phase 8 | Kill Chain & Cross-Tag Artifacts (12) | ✅ COMPLETE |
| Phase 9 | Tempo Artifacts (5) | ✅ COMPLETE |
| Phase 10 | CombatManager Wiring | ✅ COMPLETE |
| Phase 11 | Balance & Testing | 🔄 IN PROGRESS |

---

## Brotato Economy Content Summary

### Starter Weapons (CardDatabase.gd)
| Weapon | Duration | On Expire |
|--------|----------|-----------|
| Rusty Pistol | Infinite | - |
| Worn Hex Staff | Infinite | - |
| Shock Prod | 5 turns | Discard |
| Leaky Siphon | Infinite | - |
| Volatile Handgun | 4 kills | Banish |
| Mini Turret | Infinite | - |
| Spark Coil | 3 turns | Banish |

### Warden Starter Bundles
| Warden | Bundle Cards |
|--------|--------------|
| Veteran | Guard Stance + Ammo Cache |
| Ash | Minor Hex + Guard Stance |
| Gloom | Minor Hex + Guard Stance |
| Glass | Guard Stance + Minor Barrier |

### New Enemy (EnemyDatabase.gd)
- Weakling: 3 HP, 2 damage - trivially easy Wave 1 enemy

### CardDefinition V2 Duration Fields
- `duration_type`: infinite, turns, kills, burn_out
- `duration_turns`: Number of turns before expiry
- `duration_kills`: Number of kills before expiry
- `on_expire`: discard, banish, destroy

### DeckManager V2 Zones
- `deployed`: Cards currently on the battlefield (out of deck)
- `banished`: Cards removed for rest of wave

### New Scene
- StarterWeaponSelect.tscn - pick starter weapon after warden

### Shop Stat Upgrades (ShopGenerator.gd)
- +1 Energy, +1 Draw, +10 HP
- +5% Gun Damage, +5% Hex Damage, +10% Armor Gain
- +10% Scrap Gain, -5% Shop Prices, +10% XP Gain
- ~~+1 Weapon Slot~~ (REMOVED in V2)

### System Changes
- 20 waves (was 12), 6 wave bands (was 4)
- Wardens use stat_modifiers instead of setting absolute stats
- Interest system: 5% of scrap after each wave (max 25)
- **V2**: No weapon slot limit - unlimited deployed weapons
- **V2**: Weapons are DEPLOYED (out of deck while in play)
- **V2**: Weapon durations: infinite, turns, kills, burn_out

---

## V2 Brainstorm Content Summary

### New Tags (TagConstants.gd)
- **Damage-Type Tags**: explosive, piercing, beam, shock, corrosive
- **Mechanical Tags**: ammo, reload, swarm_clear, single_target, sniper, shotgun, aoe, ring_control

### New Stats (PlayerStats.gd)
- explosive_damage_percent, piercing_damage_percent, beam_damage_percent
- shock_damage_percent, corrosive_damage_percent
- deployed_gun_damage_percent, engine_damage_percent

### New Trigger Types (ArtifactDefinition.gd)
- on_explosive_hit, on_piercing_overflow, on_beam_chain
- on_shock_hit, on_corrosive_hit, on_gun_deploy
- on_gun_fire, on_gun_out_of_ammo, on_engine_trigger
- on_self_damage, on_overkill

### New Effect Types (CardEffectResolver.gd)
- fire_all_guns, target_sync, barrier_trigger, tag_infusion
- explosive_damage, beam_damage, piercing_damage
- shock_damage, corrosive_damage, energy_refund, hex_transfer

### Cards (CardDatabase.gd)
| Category | Count | Examples |
|----------|-------|----------|
| Starter | 10 | Rusty Pistol, Overclock, Tag Infusion: Piercing |
| Persistent Guns/Engines | 17 | Mortar Team, Arc Conductor, Volley Rig |
| Instant Skills | 24 | Target Sync, Barrier Channel, Rail Piercer |
| **Total V2 Brainstorm** | **51** | Plus existing V1-era cards |

### Artifacts (ArtifactManager.gd)
| Category | Count | Examples |
|----------|-------|----------|
| Damage-Type | 8 | Blast Shielding, Arc Coil, Chain Lightning Module |
| Deployed Gun | 7 | Turret Oil, Quick Draw, Autoloader |
| Kill Chain | 6 | Hunter's Quota, Rampage Core, Blood Harvest |
| Cross-Tag | 6 | Detonation Matrix, Hex Conductor, Tesla Casing |
| Tempo | 5 | Overclock Capacitor, Burst Amplifier, Coolant System |
| **Total V2 Brainstorm** | **32** | Plus existing core artifacts |

---

## In Progress

### Code Refactoring (Best Practices)
Extracted UI panel builders, helpers, and scene components to keep files under 500 lines:

| File | Before | After | Change | Status |
|------|--------|-------|--------|--------|
| Shop.gd | 1628 | 1081 | -547 | ✅ Complete |
| CombatScreen.gd | 1664 | 1300 | -364 | ✅ Complete |
| BattlefieldArena.gd | 5171 | 4096 | -1075 (-21%) | 🔶 Partial - needs architecture change |

**New Helper Files Created:**
- `scripts/ui/shop/ShopPanelBuilder.gd` - Shop panel creation (~420 lines)
- `scripts/ui/shop/ShopStatsFormatter.gd` - Stats/tag formatting (~75 lines)
- `scripts/ui/combat/CombatOverlayBuilder.gd` - Combat overlay creation (~296 lines)
- `scripts/ui/combat/GlossaryData.gd` - Glossary entries data (~110 lines)
- `scripts/combat/BattlefieldEffects.gd` - Visual effects helpers (~312 lines)
- `scripts/combat/BattlefieldInfoCards.gd` - Enemy info card/tooltip creation (~320 lines)
- `scripts/combat/BattlefieldStackManager.gd` - Stack/group management (~480 lines)
- `scripts/combat/BattlefieldRingManager.gd` - Ring drawing/barriers (~260 lines)
- `scripts/combat/BattlefieldDangerSystem.gd` - Danger highlighting (~180 lines)
- `scripts/combat/BattlefieldTargetingHints.gd` - Card targeting hints (~170 lines)

**New Reusable UI Scenes Created:**
- `scenes/combat/components/DamageNumber.tscn` + `.gd` - Floating damage/hex/heal numbers
- `scenes/combat/components/MiniEnemyPanel.tscn` + `.gd` - Mini panels in expanded stacks
- `scenes/combat/components/EnemyStackPanel.tscn` + `.gd` - Stack panel with count, HP, intent
- `scenes/combat/components/IndividualEnemyPanel.tscn` + `.gd` - Individual enemy panel

**BattlefieldArena Refactoring Status:**
- ✅ Created 6 manager classes (Stack, Ring, Danger, Targeting, Effects, Banners)
- ✅ Extracted 4 UI components to scene composition
- ✅ Reduced file from 5171 → 4096 lines (21% reduction)
- ✅ All visual components now use dedicated scenes for easier editing
- 🔶 Still 4096 lines - reaching 500 lines would require splitting into multiple Node scenes

**Why 500 lines isn't achievable with current architecture:**
BattlefieldArena manages complex shared state (enemy_visuals, stack_visuals, position tweens, etc.) that all systems need access to. The helper classes reduce code duplication but the orchestration logic must remain in the main file. To reach ~500 lines would require:
1. Converting managers from RefCounted to Node children
2. Making enemy_visuals/stack_visuals into signals or shared state managers
3. Splitting BattlefieldArena.tscn into multiple sub-scenes with their own scripts
This is a significant architectural overhaul beyond simple refactoring.

**Future Refactoring (Optional):**
- [ ] CardEffectResolver.gd - 1019 lines, consider splitting by effect type
- [ ] CombatManager.gd - 1180 lines, consider extracting phase handlers
- [ ] BattlefieldArena.gd - Continue migration to managers for full <500 line target

### Phase 11: Balance & Testing
- [ ] Test weapon duration system (turns, kills, burn_out)
- [ ] Test deployed weapon tracking (cards out of deck while deployed)
- [ ] Test weapon expiry behavior (discard, banish, destroy)
- [ ] Test warden starter bundles
- [ ] Test explosive damage and splash mechanics
- [ ] Test beam chaining with hex spread
- [ ] Test piercing overflow mechanics
- [ ] Test shock slow application
- [ ] Test corrosive armor shred
- [ ] Test all 32 new artifact triggers
- [ ] Verify Overclock fires all deployed guns
- [ ] Verify Tag Infusion adds tags to guns
- [ ] Test cross-tag synergies (beam+hex, explosive+barrier, etc.)

---

## Quick Reference

### Scenes & Navigation
| Scene | Status | Notes |
|-------|--------|-------|
| Main Menu | ✅ Working | Title, buttons functional |
| Settings | ✅ Working | Audio/Gameplay/Display settings with persistence |
| Warden Select | ✅ Working | 4 wardens (Ash, Gloom, Glass, Veteran) |
| Starter Weapon Select | ✅ Working | 7 starter weapons (Brotato Economy) |
| Combat | ✅ Working | V2 system, 90+ cards, 12 enemies |
| Shop | ✅ Working | Cards, artifacts, stat upgrades, interest/XP, owned artifacts display, card collection view |
| Post-Wave Reward | ❌ Removed | Skipped - go directly from combat to shop |
| Run End | ✅ Working | Victory/Defeat screens |
| Meta Menu | ❓ Untested | Scene exists |

### Economy Changes (Latest)
- **Healing removed** - No heal service in shop
- **HP restores to full** after each successful wave
- **No reward screen** - Combat goes directly to Shop
- **Interest/XP display** moved to Shop screen

### Full Content Summary
| Content | Count | Notes |
|---------|-------|-------|
| Cards | 97+ | V1 cards + 51 V2 brainstorm + 7 starter weapons |
| Artifacts | 58+ | V1 artifacts + 32 V2 brainstorm artifacts |
| Stat Upgrades | 8 | Energy, Draw, HP, Gun%, Hex%, Armor%, Scrap%, Shop% (Slots REMOVED) |
| Enemies | 12 | Weakling, Husk, Spitter, Spinecrawler, Bomber, etc. |
| Wardens | 4 | Ash, Gloom, Glass, Veteran (each with starter bundle) |
| Waves | 20 | Brotato Economy (was 12) |
| Build Families | 6 | Gun Board, Hex Ritualist, Barrier Fortress, Lifedrain, + damage-type builds |
| Weapon Durations | 4 | infinite, turns, kills, burn_out |

---

## How to Test
1. Open project in Godot 4.5+
2. Press F5 to run
3. Click "New Run" → Select a Warden → "Start"
4. In Combat: Click cards to play, "End Turn" to progress
5. Test V2 cards: Overclock, Tag Infusion: Piercing, Mortar Team, etc.

