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

### Lane Battlefield

Enemies spawn in FAR and advance toward the player:

```
[MELEE] ← [CLOSE] ← [MID] ← [FAR]
   0         1        2       3
```

- Enemies in **MELEE** deal damage to the player
- **Weapons** (combat cards) auto-target the closest lane with enemies
- **Instants** can require manual lane/target selection

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

### Synergy System (Brotato-Style)

Cards have **1-2 categories** that determine synergy eligibility:
- **Pure Archetypes** (1 category): Quintessential expression of a playstyle, may have stronger base stats
- **Hybrids** (2 categories): Enable build crossover, benefit from multiple stat investments

| Category | Pure | Hybrid | Total | Specialty |
|----------|------|--------|-------|-----------|
| **Kinetic** | 5 | 15 | 20 | Raw multi-hit damage, armor shredding |
| **Thermal** | 3 | 8 | 11 | Burn, AOE, lane damage |
| **Arcane** | 4 | 14 | 18 | Hex, execute, lifesteal |
| **Volatile** | 1 | 14 | 15 | High risk/reward, self-damage |
| **Utility** | 6 | 11 | 17 | Draw, energy, support, precision |

### Weapon Categories (35 Weapons)

### Kinetic Weapons (10)

| Weapon | Cost | Base | Hits | Categories | Special |
|--------|------|------|------|------------|---------|
| Pistol | 1 | 2 | 2 | Kinetic | Pure starter |
| SMG | 1 | 1 | 4 | Kinetic, Utility | Repeat target |
| Assault Rifle | 2 | 2 | 3 | Kinetic | Pure reliable |
| Minigun | 3 | 1 | 8 | Kinetic, Utility | Armor shredder |
| Shotgun | 2 | 2 | 3 | Kinetic, Volatile | +2 splash |
| Sniper Rifle | 2 | 6 | 1 | Kinetic, Utility | High crit |
| Burst Fire | 1 | 2 | 3 | Kinetic | Pure burst |
| Heavy Rifle | 2 | 4 | 2 | Kinetic, Volatile | High damage |
| Railgun | 3 | 10 | 1 | Kinetic, Arcane | Ignores armor |
| Machine Pistol | 1 | 1 | 5 | Kinetic, Utility | Budget multi-hit |

### Thermal Weapons (7)

| Weapon | Cost | Base | Hits | Categories | Special |
|--------|------|------|------|------------|---------|
| Flamethrower | 2 | 2 | 3 | Thermal, Kinetic | Apply 2 Burn |
| Firebomb | 2 | 3 | 1 | Thermal | Pure fire AOE |
| Rocket Launcher | 3 | 5 | 1 | Thermal, Volatile | +4 splash |
| Napalm Strike | 3 | 2 | 1 | Thermal, Arcane | ALL + 2 Burn |
| Incendiary Rounds | 2 | 2 | 2 | Thermal, Kinetic | Apply 4 Burn |
| Molotov | 1 | 2 | 1 | Thermal | Pure cheap fire |
| Inferno | 3 | 4 | 1 | Thermal, Arcane | ALL enemies |

### Arcane Weapons (8)

| Weapon | Cost | Base | Hits | Categories | Special |
|--------|------|------|------|------------|---------|
| Hex Bolt | 1 | 2 | 2 | Arcane | Pure hex |
| Curse | 2 | 2 | 3 | Arcane, Volatile | Apply 4 Hex |
| Soul Drain | 2 | 3 | 2 | Arcane, Volatile | Heal 3 |
| Void Strike | 2 | 4 | 1 | Arcane | Pure execute |
| Mind Shatter | 2 | 2 | 4 | Arcane, Kinetic | Psychic bullets |
| Arcane Barrage | 3 | 2 | 5 | Arcane, Kinetic | Magic spray |
| Death Mark | 2 | 2 | 3 | Arcane, Volatile | Execute 3 HP each |
| Life Siphon | 1 | 2 | 2 | Arcane | Pure lifesteal |

### Volatile Weapons (5)

| Weapon | Cost | Base | Hits | Categories | Special |
|--------|------|------|------|------------|---------|
| Blood Cannon | 2 | 3 | 4 | Volatile, Thermal | Take 3 damage |
| Pain Spike | 2 | 4 | 3 | Volatile, Kinetic | High damage |
| Chaos Bolt | 2 | 2 | 6 | Volatile, Arcane | Random targets |
| Berserker Strike | 2 | 3 | 3 | Volatile | Pure rage |
| Overcharge | 1 | 2 | 5 | Volatile, Thermal | Take 4 damage |

### Utility Weapons (5)

| Weapon | Cost | Base | Hits | Categories | Special |
|--------|------|------|------|------------|---------|
| Quick Shot | 0 | 1 | 2 | Utility | Pure cantrip |
| Scanner | 1 | 2 | 2 | Utility, Arcane | Next +2 damage |
| Rapid Fire | 1 | 1 | 4 | Utility, Kinetic | Cheap multi-hit |
| Precision Strike | 2 | 4 | 1 | Utility | Pure precision |
| Energy Siphon | 1 | 2 | 2 | Utility, Arcane | +1 Energy |

### Instant Cards (15)

| Card | Cost | Categories | Effect |
|------|------|------------|--------|
| Amplify | 1 | Kinetic, Utility | +3 damage to all weapons this turn |
| Focus Fire | 1 | Kinetic | Next weapon +3 hits |
| Execute Order | 2 | Arcane, Volatile | Apply Execute 5 HP to 3 enemies |
| Ripple Charge | 1 | Volatile, Thermal | Next kill: 3 damage to group |
| Shred Armor | 1 | Kinetic | All enemies -3 armor |
| Barrier | 2 | Utility | Place barrier (3 dmg, 2 uses) |
| Armor Up | 1 | Utility | Gain 5 armor |
| Heal | 1 | Arcane, Utility | Restore 8 HP |
| Shield Wall | 2 | Utility, Kinetic | Gain 3 armor, Draw 1 |
| Reload | 1 | Utility | Draw 3 |
| Surge | 0 | Utility, Volatile | +2 Energy this turn |
| Scavenge | 1 | Utility | Gain 8 scrap |
| Mass Hex | 2 | Arcane | Apply 3 Hex to ALL enemies |
| Ignite | 1 | Thermal | Apply 4 Burn to lane |
| Weaken | 1 | Arcane, Volatile | Enemies in lane take +2 damage |

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
| Torchbearer | 7 | 2 | 0 | 🔥 Buffs same lane +2 |
| Channeler | 8 | 2 | 0 | 🧙 Spawns 2 Mites/turn |
| Stalker | 6 | 4 | 0 | 👁️ Spawns in Close |
| Armor Reaver | 7 | 3 | 0 | 🪓 Shreds YOUR armor |

### Boss (1)

| Enemy | HP | Damage | Armor | Notes |
|-------|-----|--------|-------|-------|
| Ember Saint | 80 | 8 | 4 | 👹 Stays Far, spawns Swarmlings |

---

## Wave Structure (20 Waves) - V8 Encounter Design

### Philosophy: Kill Satisfaction First
Early waves use **small groups (1s and 2s)** so players feel like they're killing LOTS of enemies individually. Later waves use larger groups when screen real estate matters.

Each wave has **3 preset variations** that pick randomly for encounter variety without affecting difficulty.

### Waves 1-3: Onboarding (Individual Enemies)
- **Mostly groups of 1** with some pairs
- Spread across MID and FAR rings for depth
- Players experience killing many individual targets
- ~8-12 enemies per wave

**Wave 1 Example Variation A:**
- Turn 1: 2× Weakling (MID) + 3× Weakling (FAR) = 5 individual groups
- Turn 2: 3× Weakling (FAR) = 3 more individual groups

### Waves 4-6: Build Check (Small Groups)
- Mix of individuals and pairs
- Introduce Husks, Spinecrawlers, Spitters
- Groups of 1-2 per spawn entry
- ~12-16 enemies per wave

### Waves 7-12: Mid Game (Growing Groups)
- Mix of small and medium groups (2-4 per entry)
- Full enemy variety: elites, bombers, support
- ~20-40 enemies per wave

### Waves 13-16: Horde Mode (Large Groups)
- Larger groups (4-8 per entry) for screen management
- Multiple elite types simultaneously
- ~50-80 enemies per wave

### Waves 17-19: Endgame
- Peak difficulty, massive hordes
- Multi-elite combinations
- ~80-100 enemies per wave

### Wave 20: Boss
- Ember Saint + constant reinforcements
- Ultimate test of your build

---

## Enemy Group System

### Spawn Batches (V8)
Each wave spawn entry creates a **distinct group** of enemies. Groups are permanent - they **never merge** even when same enemy types end up in the same ring.

**Example Wave 1 Variation:**
```gdscript
# Each entry = separate group, even with count: 1
var variations: Array = [
    [
        {"turn": 1, "enemy_id": "weakling", "count": 1, "ring": MID},   # Individual 1
        {"turn": 1, "enemy_id": "weakling", "count": 1, "ring": MID},   # Individual 2
        {"turn": 1, "enemy_id": "weakling", "count": 1, "ring": FAR},   # Individual 3
        {"turn": 1, "enemy_id": "weakling", "count": 1, "ring": FAR},   # Individual 4
        {"turn": 1, "enemy_id": "weakling", "count": 1, "ring": FAR},   # Individual 5
    ],
]
```

This creates **5 individual enemies** spread across the battlefield - player kills them one by one for satisfying early-game feel.

### Early vs Late Wave Groups
| Wave Band | Typical Group Size | Purpose |
|-----------|-------------------|---------|
| 1-3 | 1-2 | Maximum kill satisfaction |
| 4-6 | 1-3 | Still feels like many targets |
| 7-12 | 2-4 | Groups forming, moderate density |
| 13+ | 4-8 | Screen management, horde feel |

### Variation Pools
Early waves use `_pick_and_apply_variation()` to randomly select from 3 preset encounter compositions. All variations have **similar total enemy count** but different group distributions.

### Visual Behavior
- Groups of 1 = individual enemy panel
- Groups ≥2 = stack panel with count indicator
- Groups maintain their assigned lane position across ring transitions
- Hover to expand and see individual enemies within a group

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
│   │   ├── CardDatabase.gd      # Loads from CardData.gd
│   │   ├── EnemyDatabase.gd
│   │   ├── ArtifactManager.gd   # Loads from ArtifactData.gd
│   │   ├── CombatManager.gd
│   │   └── RunManager.gd
│   ├── data/                    # MODULAR DATA FILES
│   │   ├── CardData.gd          # All card definitions (edit here!)
│   │   └── ArtifactData.gd      # All artifact definitions (edit here!)
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

### Modular Data System

Card and artifact definitions are stored in dedicated data files for easy redesign:

- **`scripts/data/CardData.gd`** - All weapon and instant card definitions
- **`scripts/data/ArtifactData.gd`** - All artifact definitions

To redesign cards or artifacts, edit the data files directly. The autoload scripts (`CardDatabase.gd`, `ArtifactManager.gd`) will automatically load from these files.

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

