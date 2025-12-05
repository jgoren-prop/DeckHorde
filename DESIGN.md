# Riftwardens - Game Design Document

## Overview

**Riftwardens** is a turn-based roguelike deckbuilder with **Brotato-style horde slaughter**. Players defend against massive waves of enemies using multi-hit weapons and powerful artifacts to achieve the satisfying "kill hundreds of enemies per run" power fantasy.

### Core Power Fantasy

**"Mass amounts of enemies dying by my hands."**

- Early waves: Learn the systems, start building
- Mid waves (4-10): Build comes online, enemies melt
- Late waves (15+): Feel godlike, unleash total destruction

### Core Loop

1. **Combat** - Survive waves of enemies using your deck
2. **Shop** - Buy weapons, artifacts, stat upgrades (primary build driver)
3. **Repeat** - Progress through 20 waves to victory

**HP restores to full after each wave. Scrap comes from killing enemies.**

---

## Combat System (V6)

### Turn Structure

1. **Draw Phase** - Draw cards to hand (5 by default)
2. **Staging Phase** - Play weapons to combat lane (costs energy)
3. **Execute Phase** - Cards execute left-to-right when turn ends
4. **Enemy Phase** - Enemies move inward and attack
5. **Wave Check** - Win if all enemies dead, lose if HP reaches 0

### Multi-Hit System (Attack Speed Equivalent)

Since we're turn-based, **hit count** replaces attack speed:

- Most weapons hit **2+ times**
- Each hit removes 1 enemy armor (before damage)
- Multi-hit weapons shred armor and deal consistent damage
- Artifacts can add bonus hits to all weapons

**Example**: Minigun (8 hits × 1 damage) vs armored enemy with 4 armor:
- Hits 1-4: Remove all armor
- Hits 5-8: Deal 4 damage

### Ring Battlefield

Enemies spawn in FAR and advance toward the player:

```
[MELEE] ← [CLOSE] ← [MID] ← [FAR]
   0         1        2       3
```

- Enemies in **MELEE** deal damage to the player
- Cards can target specific rings or random enemies

### Status Effects

| Status | Effect |
|--------|--------|
| **Burn** | Damage over time (ticks each turn) |
| **Hex** | When enemy takes damage, +hex damage consumed |
| **Execute** | If HP falls below threshold, die instantly |

### Armor System

- Each **hit** removes 1 armor
- Damage only applies after armor is stripped
- Multi-hit weapons are essential against armored enemies

---

## Card Pool (50 Cards)

### Weapon Categories (35 Weapons)

| Category | Cards | Specialty |
|----------|-------|-----------|
| **Kinetic** | 10 | Raw multi-hit damage, armor shredding |
| **Thermal** | 7 | Burn, AOE, ring damage |
| **Arcane** | 8 | Hex, execute, lifesteal |
| **Volatile** | 5 | High risk/reward, self-damage |
| **Utility** | 5 | Draw, energy, support |

### Kinetic Weapons (10)

| Weapon | Cost | Base | Hits | Special |
|--------|------|------|------|---------|
| Pistol | 1 | 2 | 2 | Starter weapon |
| SMG | 1 | 1 | 4 | Can repeat target |
| Assault Rifle | 2 | 2 | 3 | Reliable |
| Minigun | 3 | 1 | 8 | Armor shredder |
| Shotgun | 2 | 2 | 3 | +2 splash |
| Sniper Rifle | 2 | 6 | 1 | High crit |
| Burst Fire | 1 | 2 | 3 | Cheap |
| Heavy Rifle | 2 | 4 | 2 | High damage |
| Railgun | 3 | 10 | 1 | Ignores armor |
| Machine Pistol | 1 | 1 | 5 | Budget multi-hit |

### Thermal Weapons (7)

| Weapon | Cost | Base | Hits | Special |
|--------|------|------|------|---------|
| Flamethrower | 2 | 2 | 3 | Apply 2 Burn |
| Firebomb | 2 | 3 | 1 | Ring + 3 Burn |
| Rocket Launcher | 3 | 5 | 1 | +4 splash |
| Napalm Strike | 3 | 2 | 1 | ALL enemies + 2 Burn |
| Incendiary Rounds | 2 | 2 | 2 | Apply 4 Burn |
| Molotov | 1 | 2 | 1 | Ring + 2 Burn |
| Inferno | 3 | 4 | 1 | ALL enemies |

### Arcane Weapons (8)

| Weapon | Cost | Base | Hits | Special |
|--------|------|------|------|---------|
| Hex Bolt | 1 | 2 | 2 | Apply 3 Hex |
| Curse | 2 | 2 | 3 | Apply 4 Hex |
| Soul Drain | 2 | 3 | 2 | Heal 3 |
| Void Strike | 2 | 4 | 1 | Execute 4 HP |
| Mind Shatter | 2 | 2 | 4 | Pure damage |
| Arcane Barrage | 3 | 2 | 5 | Multi-hit |
| Death Mark | 2 | 2 | 3 | Execute 3 HP each |
| Life Siphon | 1 | 2 | 2 | Heal 2 |

### Volatile Weapons (5)

| Weapon | Cost | Base | Hits | Special |
|--------|------|------|------|---------|
| Blood Cannon | 2 | 3 | 4 | Take 3 damage |
| Pain Spike | 2 | 4 | 3 | High damage |
| Chaos Bolt | 2 | 2 | 6 | Random targets |
| Berserker Strike | 2 | 3 | 3 | +1 per 5 missing HP |
| Overcharge | 1 | 2 | 5 | Take 4 damage |

### Utility Weapons (5)

| Weapon | Cost | Base | Hits | Special |
|--------|------|------|------|---------|
| Quick Shot | 0 | 1 | 2 | Draw 1 |
| Scanner | 1 | 2 | 2 | Next weapon +2 |
| Rapid Fire | 1 | 1 | 4 | Cheap multi-hit |
| Precision Strike | 2 | 4 | 1 | Always crits |
| Energy Siphon | 1 | 2 | 2 | +1 Energy |

### Instant Cards (15)

| Card | Cost | Effect |
|------|------|--------|
| Amplify | 1 | +3 damage to all weapons this turn |
| Focus Fire | 1 | Next weapon +3 hits |
| Execute Order | 2 | Apply Execute 5 HP to 3 enemies |
| Ripple Charge | 1 | Next kill: 3 damage to group |
| Shred Armor | 1 | All enemies -3 armor |
| Barrier | 2 | Place barrier (3 dmg, 2 uses) |
| Armor Up | 1 | Gain 5 armor |
| Heal | 1 | Restore 8 HP |
| Shield Wall | 2 | Gain 3 armor, Draw 1 |
| Reload | 1 | Draw 3 |
| Surge | 0 | +2 Energy this turn |
| Scavenge | 1 | Gain 8 scrap |
| Mass Hex | 2 | Apply 3 Hex to ALL enemies |
| Ignite | 1 | Apply 4 Burn to ring |
| Weaken | 1 | Enemies in ring take +2 damage |

---

## Artifact System (30 Artifacts)

### Common Artifacts (10) - Stackable Stat Bonuses

| Artifact | Cost | Effect |
|----------|------|--------|
| Kinetic Rounds | 25 | +3 Kinetic damage |
| Thermal Core | 25 | +3 Thermal damage |
| Arcane Focus | 25 | +3 Arcane damage |
| Lucky Coin | 30 | +5% Crit chance |
| Heavy Hitter | 30 | +20% Crit damage |
| Extra Rounds | 35 | +1 hit to all weapons |
| Iron Skin | 25 | +10 Max HP |
| Steel Plate | 25 | +3 Armor at wave start |
| Vampiric Fang | 35 | +5% Lifesteal |
| AOE Amplifier | 30 | +15% AOE damage |

### Uncommon Artifacts (10) - Synergy Enablers

| Artifact | Cost | Effect |
|----------|------|--------|
| Hunter's Instinct | 45 | On kill: heal 2 HP |
| Bounty Hunter | 45 | On kill: +2 scrap |
| Rapid Fire Module | 50 | Multi-hit weapons +20% damage |
| Crit Chain | 55 | Crits grant +1 hit this turn |
| Executioner's Blade | 50 | Execute kills: +1 energy |
| Execute Threshold | 55 | Execute threshold +2 HP |
| Burn Spreader | 50 | Burn kills: spread burn to group |
| Hex Amplifier | 50 | Hex consumed +50% |
| Armor Crusher | 50 | First hit each turn shreds +2 armor |
| Chain Kill | 55 | Each kill this turn: next weapon +1 damage |

### Rare Artifacts (6) - Build Definers

| Artifact | Cost | Effect |
|----------|------|--------|
| Overkill | 85 | Excess damage chains to next enemy |
| Execute Mastery | 90 | Execute threshold +4, on execute heal 3 |
| Multi-Hit Mastery | 85 | +2 hits, multi-hit +10% damage |
| Burn Engine | 80 | Burn kills: +3 scrap, +1 energy |
| Hex Detonation | 85 | When hex consumed: 2 AOE damage |
| Kill Streak | 80 | 3+ kills/turn: +10 scrap, draw 1 |

### Legendary Artifacts (4) - Run Changers

| Artifact | Cost | Effect |
|----------|------|--------|
| Genocide Protocol | 150 | On kill: 1 damage to ALL enemies |
| Infinite Ammo | 160 | Weapons can be played twice |
| Death Touch | 140 | Execute threshold +8, kills heal 5 |
| Bullet Storm | 145 | +3 hits to all weapons, -1 base damage |

---

## Enemy Roster (16 Enemies)

### Fodder (4) - High Volume, Low HP

| Enemy | HP | Damage | Speed | Notes |
|-------|-----|--------|-------|-------|
| Mite | 1 | 1 | 1 | 🐜 Ultra-weak fodder |
| Swarmling | 2 | 1 | 1 | 🪲 Spawns in masses |
| Weakling | 2 | 2 | 1 | 🐀 Swarm enemy |
| Cultist | 3 | 2 | 1 | 👤 Large groups |

### Grunts (3) - Standard Enemies

| Enemy | HP | Damage | Speed | Notes |
|-------|-----|--------|-------|-------|
| Husk | 5 | 3 | 1 | 💀 Basic rusher |
| Spinecrawler | 4 | 3 | 2 | 🕷️ Fast, moves 2/turn |
| Spitter | 4 | 2 | 1 | 🦎 Ranged, stops at Mid |

### Elites (8) - Dangerous Threats

| Enemy | HP | Damage | Armor | Notes |
|-------|-----|--------|-------|-------|
| Drone | 3 | 2 | 0 | 🦟 Fast fodder |
| Shell Titan | 14 | 5 | 4 | 🛡️ Tank, needs multi-hit |
| Bomber | 6 | 5 | 0 | 💣 Explodes on death |
| Torchbearer | 7 | 2 | 0 | 🔥 Buffs same ring +2 |
| Channeler | 8 | 2 | 0 | 🧙 Spawns 2 Mites/turn |
| Stalker | 6 | 4 | 0 | 👁️ Spawns in Close |
| Armor Reaver | 7 | 3 | 0 | 🪓 Shreds YOUR armor |

### Boss (1)

| Enemy | HP | Damage | Armor | Notes |
|-------|-----|--------|-------|-------|
| Ember Saint | 80 | 8 | 4 | 👹 Stays Far, spawns Swarmlings |

---

## Wave Structure (20 Waves)

### Waves 1-3: Onboarding
- Small groups of fodder (Mites, Swarmlings, Weaklings)
- Learn basic mechanics
- ~5-15 enemies per wave

### Waves 4-6: Build Check
- Mix fodder with grunts (Husks, Cultists)
- First Spinecrawlers appear
- ~20-30 enemies per wave

### Waves 7-9: Stress Test
- Elite enemies introduced
- Higher volumes
- ~35-50 enemies per wave

### Waves 10-12: Build Online
- Heavy elite presence
- Mixed enemy types
- ~50-65 enemies per wave

### Waves 13-16: Horde Mode
- Massive enemy counts
- All enemy types
- ~70-85 enemies per wave

### Waves 17-19: Endgame
- Peak difficulty
- Multi-elite waves
- ~85-100 enemies per wave

### Wave 20: Boss
- Ember Saint + constant reinforcements
- Ultimate test of your build

---

## Economy (Brotato-Style)

### Starting Resources
| Resource | Value |
|----------|-------|
| HP | 50 |
| Energy | 3 |
| Draw | 5 |
| Starter Deck | 1 Pistol |

### Interest System
- **5% of scrap** after each wave
- **Maximum 25 scrap** from interest
- Encourages banking!

### Shop Structure
Per wave:
- **4 cards** (family-biased)
- **3 artifacts** (rarity-scaled)
- **2 stat upgrades**
- **Services** (remove card)

### Reroll Cost
`reroll_cost = 3 + floor((wave - 1) / 3) + (reroll_count * 2)`

### Shop Appearance Rates (by wave)

| Wave | Common | Uncommon | Rare | Legendary |
|------|--------|----------|------|-----------|
| 1-3 | 70% | 25% | 5% | 0% |
| 4-8 | 50% | 35% | 13% | 2% |
| 9-14 | 30% | 40% | 25% | 5% |
| 15-20 | 20% | 35% | 35% | 10% |

---

## Damage System

### Damage Formula
```
Final = (Base + Scaling) × Type Bonus × Crit
```

### Scaling Stats
| Stat | Effect |
|------|--------|
| `kinetic` | +damage per Kinetic stat |
| `thermal` | +damage per Thermal stat |
| `arcane` | +damage per Arcane stat |
| `missing_hp` | +damage per missing HP |
| `cards_played` | +damage per card played |
| `crit_chance` | % chance to crit |
| `crit_damage` | % damage on crit |

### Three Damage Types
1. **Kinetic** - Pure damage
2. **Thermal** - Burn synergy
3. **Arcane** - Hex/Execute synergy

---

## Technical Architecture

### Autoloads
| Script | Purpose |
|--------|---------|
| GameManager | Scene transitions |
| RunManager | Run state: HP, scrap, deck |
| CombatManager | Turn flow, execution |
| CardDatabase | 50 card definitions |
| EnemyDatabase | 16 enemy definitions |
| ArtifactManager | 30 artifact definitions |
| ShopGenerator | Shop generation |
| MergeManager | Triple-merge upgrades |

### Key Scenes
| Scene | Purpose |
|-------|---------|
| MainMenu | Start game |
| Combat | Main gameplay |
| Shop | Between-wave shopping |
| RunEnd | Victory/defeat |

### Resource Classes
| Class | Purpose |
|-------|---------|
| CardDefinition | Card stats and effects |
| EnemyDefinition | Enemy stats and behavior |
| ArtifactDefinition | Artifact effects |
| WaveDefinition | Wave spawn scripts |
| PlayerStats | Player stat sheet |

---

## File Structure

```
DeckHorde/
├── scenes/
│   ├── Combat.tscn
│   ├── Shop.tscn
│   ├── MainMenu.tscn
│   ├── RunEnd.tscn
│   └── ui/
│       └── CardUI.tscn
├── scripts/
│   ├── autoloads/
│   │   ├── CardDatabase.gd
│   │   ├── EnemyDatabase.gd
│   │   ├── ArtifactManager.gd
│   │   ├── CombatManager.gd
│   │   └── RunManager.gd
│   ├── resources/
│   │   ├── CardDefinition.gd
│   │   ├── EnemyDefinition.gd
│   │   └── PlayerStats.gd
│   └── combat/
│       ├── CardEffectResolver.gd
│       └── EnemyInstance.gd
├── AGENTS.md
└── DESIGN.md
```

---

## Quick Reference

### Adding a New Weapon
1. Open `scripts/autoloads/CardDatabase.gd`
2. Find the appropriate category function (e.g., `_create_kinetic_weapons`)
3. Use `_create_weapon()` helper
4. Call `_register_card()` to add it

### Adding a New Artifact
1. Open `scripts/autoloads/ArtifactManager.gd`
2. Find the appropriate rarity function
3. Use `_create_artifact()` with effect dictionary
4. Wire triggers if needed

### Adding a New Enemy
1. Open `scripts/autoloads/EnemyDatabase.gd`
2. Create new `EnemyDef.new()` instance
3. Set all properties
4. Call `_register_enemy()` with archetype

---

## Design Philosophy

1. **Multi-hit is king** - Most weapons should hit 2+ times
2. **Horde fantasy** - Waves should feel overwhelming until you're powerful
3. **Shop-driven builds** - Cards + artifacts create synergies
4. **Simple mechanics** - Each system should be easy to understand
5. **Clear power curve** - Wave 4 = build forming, Wave 10 = locked in, Wave 15+ = godlike

