# Riftwardens - Development Progress

## Legend
- ✅ Complete
- 🔄 In Progress
- ⏳ Pending

## Current Status: V5 System Implementation ✅

### V5 Implementation (Dec 5, 2025)
| Phase | Name | Status |
|-------|------|--------|
| Phase 1 | PlayerStats.gd + TagConstants.gd rewrite for V5 stat system | ✅ COMPLETE |
| Phase 2 | CardDefinition.gd + V5 damage formula in CardEffectResolver | ✅ COMPLETE |
| Phase 3 | FamilyBuffManager for category-based tier bonuses | ✅ COMPLETE |
| Phase 4 | All 54 V5 weapons in CardDatabase | ✅ COMPLETE |
| Phase 5 | All 24 V5 instant cards in CardDatabase | ✅ COMPLETE |
| Phase 6 | 4-tier system with 2-to-1 merging | ✅ COMPLETE |
| Phase 7 | 12 V5 enemies + armor mechanic (1 hit = 1 armor) | ✅ COMPLETE |
| Phase 8 | Hex, Burn, Barrier status effects with V5 potency | ✅ COMPLETE |
| Phase 9 | All 20 wave compositions with turn-based spawning | ✅ COMPLETE |
| Phase 10 | V5 economy (interest 5%, shop pricing, stat upgrades) | ✅ COMPLETE |
| Phase 11 | V5 artifacts (50 total) | ✅ COMPLETE |
| Phase 12 | Card UI layout per DESIGN_V5 specs | ✅ COMPLETE |
| Phase 13 | Damage breakdown tooltip system | ✅ COMPLETE |
| Phase 14 | V5 starter deck (already matches V5 spec) | ✅ COMPLETE |
| Phase 15 | Final polish, integration testing, documentation | ✅ COMPLETE |

### V5 Key Changes

#### Damage System
- **3 Damage Types**: Kinetic, Thermal, Arcane with type-specific multipliers
- **8 Weapon Categories**: Kinetic, Thermal, Arcane, Fortress, Shadow, Utility, Control, Volatile
- **V5 Damage Formula**: `(Base + Stat Scaling) × Type Mult × Global Mult × Crit`
- **Family Buffs**: 3 tiers (3-5, 6-8, 9+ cards) give category-specific bonuses

#### Card System
- **54 Weapons**: All damage-dealing cards with categories, scaling stats, crit bonuses
- **24 Instants**: Support cards for buffs, healing, status application
- **4-Tier System**: Tier 1-4 with base +50/100/150% damage scaling
- **2-to-1 Merging**: Combine 2 same-tier cards → 1 higher tier

#### Status Effects
- **Hex**: Stacks on enemies, triggers on damage (+stacks × hex_potency), consumed
- **Burn**: Stacks on enemies, deals damage each turn (× burn_potency), reduces by 1
- **Barriers**: Placed on rings, deal damage on enemy crossing, lose 1 use per trigger

#### Enemy System
- **12 Enemies**: 6 grunts, 5 elites, 1 boss (Ember Saint)
- **V5 Armor**: Each HIT removes 1 armor (no damage spillover)
- **Behavior Types**: Rusher, Fast, Ranged, Bomber, Buffer, Spawner, Tank, Ambush, Shredder, Boss

#### Economy (Brotato-Style)
- **Interest**: 5% of scrap per wave, capped at 25
- **Card Pricing**: Common 15, Uncommon 38, Rare 75 (× tier multiplier 1.0/1.8/3.0/4.5)
- **Reroll**: Base 2, +2 per reroll in same shop
- **Stat Upgrades**: 13 upgrade types with linear price scaling

#### Artifact System (50 Total)
- **16 Common**: Stackable stat boosts (Kinetic Rounds, Thermal Core, Lucky Coin, etc.)
- **16 Uncommon**: Category synergies (Precision Scope, Pyromaniac, Soul Leech, etc.)
- **12 Rare**: Cross-type enablers (Burning Hex, Crit Shockwave, Executioner, etc.)
- **6 Legendary**: Build definers (Infinity Engine, Blood Pact, Glass Cannon, etc.)

#### Card UI Updates
- **V5 Type Icons**: 🔫 Kinetic, 🔥 Thermal, ✨ Arcane
- **V5 Tier Colors**: Gray (T1), Green (T2), Blue (T3), Gold (T4)
- **Category Display**: Icons and names for all 8 categories
- **Damage Tooltip**: Full breakdown of damage calculation on hover

### V5 Test Coverage
| Test File | Tests | Status |
|-----------|-------|--------|
| TestV5Stats.gd | 69 | ✅ All Pass |
| TestV5DamageFormula.gd | 38 | ✅ All Pass |
| TestFamilyBuffs.gd | 28 | ✅ All Pass |
| TestV5Weapons.gd | 20 | ✅ All Pass |
| TestV5Merge.gd | 22 | ✅ All Pass |
| TestV5Enemies.gd | 93 | ✅ All Pass |
| TestV5StatusEffects.gd | 43 | ✅ All Pass |
| TestV5Waves.gd | 74 | ✅ All Pass |
| TestV5Economy.gd | 38 | ✅ All Pass |
| TestV5Artifacts.gd | 80 | ✅ All Pass |
| TestV5CardUI.gd | 48 | ✅ All Pass |
| TestV5Tooltip.gd | 21 | ✅ All Pass |

**Total: 574 tests passing**

---

## V5 Content Summary

### V5 Starter Deck (10 cards)
| Card | Categories | Count |
|------|------------|-------|
| Pistol | Kinetic | 3 |
| Shotgun | Kinetic, Thermal | 1 |
| Hex Bolt | Arcane | 2 |
| Shield Bash | Fortress, Control | 2 |
| Quick Shot | Utility, Kinetic | 2 |

### V5 Stats (PlayerStats.gd)
- **Flat Damage**: kinetic, thermal, arcane
- **Multipliers**: kinetic_percent, thermal_percent, arcane_percent, damage_percent, aoe_percent
- **Crit**: crit_chance (5%), crit_damage (150%)
- **Status**: hex_potency, burn_potency, lifesteal_percent
- **Barrier**: barrier_damage_bonus, barrier_uses_bonus
- **Defense**: max_hp (100), armor, armor_start, self_damage_reduction
- **Economy**: draw_per_turn (5), energy_per_turn (3), hand_size (7)

### V5 Family Buffs
| Category | Tier 1 (3-5) | Tier 2 (6-8) | Tier 3 (9+) |
|----------|--------------|--------------|-------------|
| Kinetic | +3 Kinetic | +6 Kinetic | +10 Kinetic |
| Thermal | +3 Thermal | +6 Thermal | +10 Thermal |
| Arcane | +3 Arcane | +6 Arcane | +10 Arcane |
| Fortress | +3 Armor/wave | +6 Armor/wave | +10 Armor/wave |
| Shadow | +5% Crit | +10% Crit | +15% Crit |
| Utility | +1 Draw/wave | +2 Draw/wave | +3 Draw/wave |
| Control | +1 Barrier | +1 Barrier | +2 Barriers |
| Volatile | +5 Max HP | +12 Max HP | +20 Max HP |

---

## How to Test V5

1. Open project in Godot 4.5+
2. Run individual test scenes:
   - `scenes/tests/TestV5Stats.tscn`
   - `scenes/tests/TestV5DamageFormula.tscn`
   - `scenes/tests/TestFamilyBuffs.tscn`
   - `scenes/tests/TestV5Weapons.tscn`
   - `scenes/tests/TestV5Merge.tscn`
   - `scenes/tests/TestV5Enemies.tscn`
   - `scenes/tests/TestV5StatusEffects.tscn`
   - `scenes/tests/TestV5Waves.tscn`
   - `scenes/tests/TestV5Economy.tscn`
   - `scenes/tests/TestV5Artifacts.tscn`
   - `scenes/tests/TestV5CardUI.tscn`
   - `scenes/tests/TestV5Tooltip.tscn`
3. All tests should output "PASSED ✓" with exit code 0
