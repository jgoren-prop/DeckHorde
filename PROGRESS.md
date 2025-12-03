# Riftwardens - Development Progress

## Legend
- ✅ Working/Complete
- 🔶 Partial/Minimal
- ❓ Untested
- ⏳ Future/Planned
- 🔄 In Progress

## Current Status: V2 Brainstorm System Implementation 🔄

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

### Phase 11: Balance & Testing
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
| Combat | ✅ Working | V2 system, 90+ cards, 10 enemies |
| Shop | ✅ Working | V2 structure (4 cards, 3 artifacts, 2 services) |
| Post-Wave Reward | ✅ Working | Card/Scrap/Heal choices |
| Run End | ✅ Working | Victory/Defeat screens |
| Meta Menu | ❓ Untested | Scene exists |

### Full Content Summary
| Content | Count | Notes |
|---------|-------|-------|
| Cards | 90+ | V1 cards + 51 V2 brainstorm cards |
| Artifacts | 58+ | V1 artifacts + 32 V2 brainstorm artifacts |
| Enemies | 11 | Husk, Spitter, Spinecrawler, Bomber, etc. |
| Wardens | 4 | Ash, Gloom, Glass, Veteran |
| Build Families | 6 | Gun Board, Hex Ritualist, Barrier Fortress, Lifedrain, + damage-type builds |

---

## How to Test
1. Open project in Godot 4.5+
2. Press F5 to run
3. Click "New Run" → Select a Warden → "Start"
4. In Combat: Click cards to play, "End Turn" to progress
5. Test V2 cards: Overclock, Tag Infusion: Piercing, Mortar Team, etc.

