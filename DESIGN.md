# Riftwardens - Game Design Document

## Overview

**Riftwardens** is a turn-based roguelike deckbuilder with horde pressure mechanics and **Brotato-style buildcraft**. Players defend against waves of enemies approaching in concentric rings, using cards to deal damage, apply debuffs, and survive.

### Design Philosophy

- **Shared, mostly generic card pool** usable by all wardens
- **Rich tag and stat systems** so builds emerge from **artifacts + wardens**, not bespoke class decks
- **Shop-centric runs** where most of the "game" is in **fast build commits and synergies**
- **Ring-based tactics and horde pressure** with power coming from your *build* rather than micro-optimizing each turn

### Core Loop (Brotato Economy)

1. **Select Warden** - Choose from 4 characters with stat modifiers
2. **Select Starter Weapon** - Pick 1 of 7 starter weapons (your only starting card!)
3. **Combat** - Survive waves of enemies using your deck
4. **Shop** - Buy cards, artifacts, stat upgrades, services (primary build driver)
5. **Repeat** - Progress through 20 waves to victory

**Note:** Health restores to full after each wave. Scrap comes from killing enemies during combat.

### Brotato Economy Overview

Inspired by Brotato, this economy system emphasizes shop-driven progression:

| Feature | Value | Notes |
|---------|-------|-------|
| Starting HP | 50 | +20 from typical warden bonus |
| Starting Energy | 1 | Buy more in shop |
| Starting Draw | 1 | Buy more in shop |
| Starting Cards | 3 | Picked weapon + 2 bundle cards |
| Weapon Slots | ∞ | V2: No limit (removed) |
| Total Waves | 20 | Extended from 12 |
| Interest Rate | 5% | Up to 25 scrap/wave |

**Interest System**: After each wave, earn 5% of your scrap (max 25). Encourages saving!

**V2 Changes**:
- Weapons stay deployed (out of deck) while in play
- Weapon slot limit removed - limited by hand/energy instead
- Weapons have varied durations (infinite, turns, kills, burn_out)
- Each warden gets a starter bundle (weapon pick + 2 fixed cards)

---

## Game Mechanics

### Ring Battlefield

Enemies spawn in the **FAR** ring and advance toward the player each turn:

```
[MELEE] ← [CLOSE] ← [MID] ← [FAR]
   0         1        2       3
```

- Enemies in **MELEE** deal damage to the player
- Cards can target specific rings
- Some enemies stop at certain rings (ranged attackers)

#### Visual Layout + Scaling

- `scenes/Combat.tscn` anchors `BattlefieldArena` across the full viewport with 70px margins
- `BattlefieldArena.gd` sets `max_radius = min(size.x, size.y) * 0.58`
- Enemy panels scale with viewport: width = `clamp(shortest_side * 0.11, 70, 150)`

#### Enemy Display System (Horde Handling)

**Multi-Row Distribution** (5-8 enemies in a ring):
- Enemies distributed across inner (35% depth) and outer (75% depth) rows

**Overflow Stacking** (3+ of same enemy type):
- Identical enemies collapse into a "stack" panel with count badge (e.g., "x5")
- Stack shows aggregate HP bar
- **Expand on Hover**: Hovering fans out mini-panels showing individual HP

### Turn Structure

1. **Draw Phase** - Draw cards to hand (5 by default)
2. **Player Phase** - Play cards using Energy (3 by default)
3. **Enemy Phase** - Enemies move inward and attack
4. **Wave Check** - Win if all enemies dead, lose if player HP reaches 0

### Card Types

| Type | Description |
|------|-------------|
| Weapon/Gun | Deal damage, some persist across turns |
| Skill | Buffs, healing, utility, draw, energy |
| Hex | Apply stacking damage-over-time to enemies |
| Defense | Gain armor, create barriers |
| Engine | Persistent effects (turrets, auras) |

### Core Mechanics

**Energy**: Resource spent to play cards. Refills to max each turn.

**Armor**: Absorbs damage before HP. Persists between turns until used.

**Hex**: Stacking debuff on enemies. When a hexed enemy takes damage, they take bonus damage equal to their hex stacks, then hex is consumed.

**Persistent Weapons**: Stay in play and trigger automatically at end of each turn before enemy phase.

**Barriers**: Ring-based traps that damage enemies when crossed. Have HP/duration and can trigger multiple times.

---

## Tag System

Every card has tags that define its behavior and synergies:

### Core Type Tags (exactly 1)

- `gun` – direct damage weapons
- `hex` – curse / debuff / DoT
- `barrier` – ring traps and movement-triggered effects
- `defense` – armor, shields, direct HP manipulation
- `skill` – instant effects: draw, energy, utility
- `engine` – non-weapon persistent effects

### Timing Tags (exactly 1)

- `instant` – resolve once on play
- `persistent` – stays in play and triggers each turn

### Behavior Tags (0-3)

- `shotgun` – many weak hits in Melee/Close
- `sniper` – prefers Far/Mid
- `aoe` – hits many enemies or full rings
- `ring_control` – push, pull, slow, reposition
- `swarm_clear` – specifically good vs multiple low-HP enemies
- `single_target` – focus on one enemy

### Build-Family Tags (0-3)

- `lifedrain` – heals/sustain / HP manipulation
- `hex_ritual` – spends/uses hex and HP for big power spikes
- `fortress` – heavy armor/barrier stacking and turtling
- `barrier_trap` – barriers that act like damage-dealing traps
- `volatile` – self-damage, risky payoffs
- `engine_core` – draw/energy/economy engines

---

## Player Stat Sheet

Stats that artifacts and wardens can modify:

### Offense
- `gun_damage_percent` (default 100)
- `hex_damage_percent` (default 100)
- `barrier_damage_percent` (default 100)
- `generic_damage_percent` (fallback)

### Defense & Sustain
- `max_hp` (e.g., 70 for Veteran)
- `armor_gain_percent` (scales armor card values)
- `barrier_strength_percent` (duration/HP of barriers)

### Economy / Tempo
- `energy_per_turn` (default 3)
- `draw_per_turn` (default 5)
- `hand_size_max` (default 7)
- `scrap_gain_percent` (extra scrap from kills/rewards)
- `shop_price_percent` (cheaper/more expensive shops)

### Ring Interaction
- `damage_vs_melee_percent`
- `damage_vs_close_percent`
- `damage_vs_mid_percent`
- `damage_vs_far_percent`

---

## Build Families

The game supports 4 distinct build archetypes:

### Gun Board

Build a board of persistent guns that automatically clear the horde. Strong vs spread-out waves, wants to control Mid/Far.

- **Core**: Persistent `gun` weapons (shotgun/sniper variants)
- **Support**: Sharpened Rounds, damage scaling artifacts

### Hex Ritualist

Stack hex across the horde, trade HP/tempo for enormous delayed damage. Strong vs large waves.

- **Core**: `hex` + `hex_ritual` cards
- **Support**: Occult Focus, Creeping Doom, HP-sacrificing artifacts

### Barrier Fortress

Turn the rings into a minefield. Barriers deal damage and generate armor/hex.

- **Core**: `barrier`, `barrier_trap`, `fortress` cards
- **Support**: Trap Engineer, Runic Bastion, Punishing Walls

### Lifedrain Bruiser

Trade damage for sustain. Constantly healing and converting sustain into armor/damage via artifacts.

- **Core**: `lifedrain`-tagged defense/weapon cards
- **Support**: Leech Core, Hemorrhage Engine

---

## Card Pool (48 Cards)

### Gun Board Family (12 cards)

| Card | Cost | Tags | Effect |
|------|------|------|--------|
| Rusty Pistol | 1 | gun, persistent, single_target | At end of turn, deal 3 damage to random enemy |
| Infernal Pistol | 1 | gun, persistent, sniper | At end of turn, deal 4 damage to random enemy in Mid/Far |
| Choirbreaker Shotgun | 1 | gun, persistent, shotgun, swarm_clear | At end of turn, deal 2 damage to up to 3 enemies in Melee/Close |
| Riftshard Rifle | 2 | gun, instant, sniper | Deal 8 damage to enemy in Far. If it dies, apply 2 hex to another |
| Scatter Volley | 1 | gun, instant, shotgun, swarm_clear | Deal 2 damage to 4 random enemies |
| Storm Carbine | 2 | gun, persistent, mid_focus | At end of turn, deal 3 damage to 2 enemies in Close/Mid |
| Overcharged Revolver | 1 | gun, instant, volatile | Deal 6 damage to random enemy. Lose 1 HP |
| Suppressing Fire | 1 | gun, instant, ring_control | Deal 3 damage to all enemies in Mid. Slow them |
| Twin Pistols | 1 | gun, persistent, close_focus | At end of turn, deal 2 damage to 2 enemies in Melee/Close |
| Salvo Drone | 2 | gun, engine, persistent, aoe | At end of turn, deal 3 damage to a random ring |
| Ammo Cache | 1 | skill, instant, engine_core, gun | Draw 2 cards. Next gun card costs 1 less |
| Iron Bastion | 2 | defense, instant, fortress | Gain 6 armor |

### Hex Ritualist Family (12 cards)

| Card | Cost | Tags | Effect |
|------|------|------|--------|
| Minor Hex | 1 | hex, instant, hex_ritual | Apply 3 hex to a random enemy |
| Plague Cloud | 2 | hex, instant, aoe, swarm_clear, hex_ritual | Apply 2 hex to all enemies |
| Withering Mark | 1 | hex, instant, single_target, hex_ritual | Apply 5 hex to a single enemy |
| Plague Turret | 2 | hex, engine, persistent, aoe, hex_ritual | At end of turn, apply 2 hex to all enemies in random ring |
| Soul Brand | 1 | hex, instant, hex_ritual | Apply 3 hex. If target dies this turn, gain 2 armor |
| Rotting Gale | 2 | hex, instant, aoe, ring_control, hex_ritual | Apply 2 hex to Close/Mid. Push Far enemies into Mid |
| Ritual Focus | 0 | skill, instant, hex_ritual, engine_core | Lose 2 HP; next hex card has +100% hex value |
| Blood Sigil Bolt | 1 | hex, instant, lifedrain, hex_ritual | Apply 3 hex to random enemy. Heal 1 HP |
| Cursed Miasma | 2 | hex, instant, aoe, swarm_clear | Apply 1 hex to all. Draw 1 card per 3 hex applied |
| Doom Clock | 2 | hex, engine, persistent, hex_ritual | At end of turn, increase hex on all hexed enemies by 1 |
| Last Rite | 2 | hex, instant, volatile, hex_ritual | Consume target's hex, deal that damage to all other enemies |
| Hex-Tipped Rounds | 1 | gun, instant, hex_ritual, sniper | Deal 3 damage. Apply 2 hex |

### Barrier Fortress Family (12 cards)

| Card | Cost | Tags | Effect |
|------|------|------|--------|
| Minor Barrier | 1 | barrier, instant, ring_control, barrier_trap | Place barrier: 3 damage when crossed, 1 use |
| Ring Ward | 2 | barrier, engine, persistent, barrier_trap, fortress | Place barrier: 3 damage, 3 uses |
| Barrier Sigil | 1 | barrier, instant, ring_control, barrier_trap | Place barrier: 4 damage, enemies don't move this turn |
| Glass Ward | 1 | defense, instant, fortress | Gain 5 armor |
| Runic Rampart | 2 | barrier, instant, fortress | Place barrier in Melee and Close: 3 HP, 2 damage each |
| Reinforced Circle | 1 | barrier, instant, fortress | Existing barriers in chosen ring gain +2 HP |
| Ward Shock | 1 | skill, instant, barrier_trap, ring_control | All enemies that crossed a barrier this turn take 2 damage |
| Lockdown Field | 2 | barrier, instant, ring_control, fortress | Enemies can't move Close→Melee this turn. Place barrier in Close |
| Guardian Circle | 1 | defense, instant, fortress | Gain 3 armor. +2 if you control 3+ barriers |
| Repulsion Wave | 1 | skill, instant, ring_control, swarm_clear, volatile | Push all Melee/Close enemies back 1 ring. Barrier crossers take 2 |
| Cursed Bulwark | 2 | defense, instant, fortress, hex_ritual | Gain 6 armor. Apply 1 hex to all enemies in Melee |
| Barrier Leech | 1 | barrier, instant, lifedrain, barrier_trap | Place barrier: 2 damage. Heal 1 HP when it triggers |

### Lifedrain Bruiser Family (7 cards)

| Card | Cost | Tags | Effect |
|------|------|------|--------|
| Blood Shield | 1 | defense, instant, lifedrain, fortress | Gain 3 armor. This turn, heal 1 HP per kill |
| Blood Bolt | 1 | gun, instant, lifedrain | Deal 5 damage to random enemy. Heal 2 HP |
| Leeching Slash | 1 | gun, instant, lifedrain, close_focus | Deal 4 damage to Melee/Close enemy. Heal 2 HP |
| Crimson Guard | 1 | defense, instant, lifedrain | Gain 4 armor. Heal 1 HP |
| Sanguine Aura | 2 | engine, persistent, lifedrain | At end of turn, heal 1 HP per enemy killed this turn |
| Martyr's Vow | 0 | skill, instant, lifedrain, volatile | Lose 3 HP. This turn, heal 3 HP per kill |
| Vampiric Volley | 2 | gun, instant, lifedrain, swarm_clear | Deal 3 damage to 3 random enemies. Heal 1 HP each |

### Overlap/Engine Cards (5 cards)

| Card | Cost | Tags | Effect |
|------|------|------|--------|
| Precision Strike | 1 | gun, instant, single_target | Deal 7 damage to target enemy. If stacked, hits all enemies in the stack |
| Guard Stance | 1 | defense, instant, fortress | Gain 4 armor |
| Shove | 1 | skill, instant, ring_control, volatile | Push 1 enemy back 1 ring. Barrier hit = 2 damage |
| Ritual Cartridge | 1 | skill, instant, engine_core, gun, hex_ritual | Next gun and hex card cost 1 less |
| Blood Ward Turret | 2 | engine, persistent, lifedrain, barrier_trap | At end of turn, deal 2 to Melee/Close enemy, heal 1 HP |

---

## Rarity System

Both cards and artifacts use a 4-tier rarity system:

| Rarity | Tier | Color | Shop Weight | Notes |
|--------|------|-------|-------------|-------|
| Common | 1 | Gray | High | All starter weapons, basic cards |
| Uncommon | 2 | Green | Medium | Solid upgrades |
| Rare | 3 | Blue | Low | Powerful synergy pieces |
| Legendary | 4 | Gold | Very Low | Build-defining power |

### Rarity Distribution

- **Common (17 cards)**: Starter weapons, basic skills, foundation pieces
- **Uncommon (25 cards)**: Most instant skills, mid-tier engines
- **Rare (15 cards)**: Persistent weapons, powerful AoE, synergy payoffs
- **Legendary (TBD)**: Reserved for future powerful cards

### Shop Appearance Rates (by wave)

| Wave | Common | Uncommon | Rare | Legendary |
|------|--------|----------|------|-----------|
| 1-3 | 70% | 25% | 5% | 0% |
| 4-8 | 50% | 35% | 13% | 2% |
| 9-14 | 30% | 40% | 25% | 5% |
| 15-20 | 20% | 35% | 35% | 10% |

---

## Artifact System (26 Artifacts)

Artifacts are **Brotato-style items**: small, often stackable stat and tag boosts with clear tradeoffs.

### Core Stat Artifacts (10)

| Artifact | Rarity | Stackable | Effect |
|----------|--------|-----------|--------|
| Sharpened Rounds | Common | ✓ | Gun damage +10% |
| Hex Lens | Common | ✓ | Hex damage +10% |
| Reinforced Plating | Common | ✓ | Armor gained +15% |
| Barrier Alloy | Common | ✓ | Barriers +20% HP/duration |
| Tactical Pack | Uncommon | ✗ | Draw +1 card per turn |
| Surge Capacitor | Uncommon | ✗ | Energy per turn +1 |
| Glass Core | Uncommon | ✓ | Gun damage +20%. Max HP -5 |
| Runic Plating | Uncommon | ✓ | Armor gained +25%. Heal power -10% |
| Forward Bastion | Uncommon | ✓ | Damage vs Melee/Close +15%. Damage vs Mid/Far -10% |
| Scrap Magnet | Common | ✓ | Scrap gained +15% |

### Lifedrain Family Artifacts (4)

| Artifact | Rarity | Stackable | Effect |
|----------|--------|-----------|--------|
| Leech Core | Common | ✓ | Lifedrain cards heal +1 HP |
| Sanguine Reservoir | Uncommon | ✗ | Max HP +10. Heal power -10% |
| Hemorrhage Engine | Rare | ✗ | When you heal, deal that damage split among Melee/Close enemies |
| Red Aegis | Uncommon | ✗ | Heals at full HP give 2 armor instead |

### Hex Ritual Family Artifacts (4)

| Artifact | Rarity | Stackable | Effect |
|----------|--------|-----------|--------|
| Occult Focus | Common | ✓ | hex_ritual cards apply +1 hex |
| Blood Pact | Uncommon | ✗ | Wave start: lose 3 HP, gain +1% hex damage per wave |
| Creeping Doom | Rare | ✗ | When hex consumed, apply 1 hex to all enemies in that ring |
| Ritual Anchor | Uncommon | ✗ | Playing hex_ritual card grants 1 armor |

### Barrier/Fortress Family Artifacts (4)

| Artifact | Rarity | Stackable | Effect |
|----------|--------|-----------|--------|
| Trap Engineer | Common | ✓ | barrier_trap barriers deal +2 damage |
| Runic Bastion | Uncommon | ✗ | fortress barriers grant 1 armor when triggered |
| Punishing Walls | Rare | ✗ | Barrier damage applies 1 hex |
| Nested Circles | Uncommon | ✗ | Start each wave with Minor Barrier in Close |

### Volatile/Push Family Artifacts (4)

| Artifact | Rarity | Stackable | Effect |
|----------|--------|-----------|--------|
| Kinetic Harness | Common | ✗ | Push deals 1 damage |
| Shock Collars | Uncommon | ✗ | Enemies moving Mid→Close take 1 damage |
| Last Stand Protocol | Rare | ✗ | Turn start with 3+ enemies in Melee: +1 energy, 3 armor |
| Overloader | Uncommon | ✗ | Volatile cards deal +2 damage. Wave end: lose 3 HP |

---

## Shop System

The shop is the **primary build driver**:

### Shop Structure

Per wave, when you open the shop:
- **4 cards** from the card pool
- **3 artifacts** (stat and family items)
- **2 services** (heal, remove card)

### Reroll Cost

- Base cost: 3 scrap
- Scaling: `reroll_cost = 3 + floor((wave - 1) / 3) + (reroll_count * 2)`

### Family Biasing

**Early Waves (1-3)**: Shops aggressively push you into a build family
- 70% of shops: 2+ cards from same focus family
- Creates clear build commitment opportunities

**Mid/Late Waves (4+)**: Bias toward your committed build
- Primary family: +2.0 weight
- Secondary family: +1.0 weight
- Guarantees 2+ primary family cards when committed

### Services

| Service | Effect | Cost |
|---------|--------|------|
| Remove Card | Remove chosen card from deck | `10 + 3 * wave` scrap |

**Note:** No heal service - HP restores to full after each wave.

### Shop UI Panels

The shop screen displays several information panels:

| Panel | Position | Content |
|-------|----------|---------|
| Stats Panel | Left side | Full player stats (HP, Armor, damage %, etc.) |
| Tag Tracker | Center-left | Count of each tag in your deck (Gun, Hex, etc.) |
| Owned Artifacts | Center-left (below tags) | Grid of all artifacts you own with hover tooltips |
| Card Collection | Bottom | All cards in your deck organized by category (fan layout) |
| Dev Panel | Top-right | Debug buttons (+scrap, skip wave, full heal) |

**Owned Artifacts Panel:**
- Shows icon grid (4 columns) of all artifacts owned
- Stackable artifacts show "x2", "x3" badge
- Border color indicates rarity (gray/blue/purple/gold)
- Hovering shows tooltip with artifact name and effect

**Card Collection Panel:**
- Displays all deck cards at bottom of screen in a single horizontal row
- Cards sorted by core type (gun → hex → barrier → defense → skill → engine)
- Cards overlap slightly (45px spacing) and are scaled to 50%
- Horizontally centered in the visible area
- **Hover behavior**: When hovering a card:
  - The hovered card pops up (lifts 40px) and scales larger (65%)
  - Neighboring cards spread apart (60px extra spacing)
  - Hovered card comes to front (z-index 100)
  - Smooth tween animation (0.15s) for all movements
- Scrollable horizontally for large decks

---

## Starter Weapons (Brotato Economy)

Player picks 1 starter weapon after selecting their warden. All cost 1 energy and are persistent. **Every starter MUST be able to kill enemies solo.**

### V2 Weapon Duration System

Weapons now have varied durations instead of all being permanent:

| Duration Type | Behavior | Example |
|---------------|----------|---------|
| `infinite` | Stays deployed until wave ends | Rusty Pistol, Mini Turret |
| `turns` | Lasts X turns then discards/banishes | Shock Prod (5 turns) |
| `kills` | Destroys after X kills | Volatile Handgun (4 kills) |
| `burn_out` | Strong but short, then banished | Spark Coil (3 turns) |

On expiry, weapons can:
- `discard` - Return to deck, can draw again
- `banish` - Gone for rest of wave
- `destroy` - Gone from run entirely

### Starter Weapon Table

| Weapon | Tags | Effect | Duration | On Expire |
|--------|------|--------|----------|-----------|
| Rusty Pistol | gun, persistent | Deal 3 damage to random enemy | Infinite | - |
| Worn Hex Staff | hex, persistent, hex_ritual | Deal 1 damage + apply 2 Hex | Infinite | - |
| Shock Prod | shock, persistent | Deal 3 shock to closest enemy | 5 turns | Discard |
| Leaky Siphon | gun, persistent, lifedrain | Deal 2 damage, heal 1 HP | Infinite | - |
| Volatile Handgun | gun, persistent, volatile | Deal 4 damage, lose 1 HP | 4 kills | Banish |
| Mini Turret | gun, engine, persistent, aoe | Deal 2 damage to 2 enemies | Infinite | - |
| Spark Coil | shock, persistent, aoe | Deal 3 damage to all Melee | 3 turns | Banish |

### Warden Starter Bundles

Each warden gets **bonus cards** alongside the weapon they pick:

| Warden | Weapon Pick | Bundle Cards |
|--------|-------------|--------------|
| Veteran | Pick 1 of 7 | Guard Stance + Ammo Cache |
| Ash | Pick 1 of 7 | Minor Hex + Guard Stance |
| Gloom | Pick 1 of 7 | Minor Hex + Guard Stance |
| Glass | Pick 1 of 7 | Guard Stance + Minor Barrier |

**Veteran starts with 3 cards**: 1 picked weapon + Guard Stance (defense) + Ammo Cache (draw/utility)

---

## Stat Upgrades (Brotato Economy)

Buyable stat upgrades appear in the shop (1-2 per refresh). Prices scale exponentially with purchases.

**V2 Note**: Weapon Slot upgrade removed - no limit on deployed weapons now.

| Upgrade | Base Price | Effect | Cap |
|---------|------------|--------|-----|
| +1 Max Energy | 60 | energy_per_turn +1 | 5 |
| +1 Draw | 50 | draw_per_turn +1 | 7 |
| +10 Max HP | 25 | max_hp +10 | None |
| +5% Gun Damage | 20 | gun_damage_percent +5 | None |
| +5% Hex Damage | 20 | hex_damage_percent +5 | None |
| +10% Armor Gain | 15 | armor_gain_percent +10 | None |
| +10% Scrap Gain | 30 | scrap_gain_percent +10 | None |
| -5% Shop Prices | 40 | shop_price_percent -5 | -30% |
| +10% XP Gain | 25 | xp_gain_percent +10 | None |

---

## XP / Leveling System (Brotato-style)

Killing enemies grants XP. Accumulate enough XP to level up and gain permanent bonuses.

### XP Formula (Brotato-style)
- **XP Required for Level N** = `(N + 3)²`
- Level 1: 16 XP
- Level 2: 25 XP  
- Level 3: 36 XP
- Level 4: 49 XP
- Level 5: 64 XP
- etc.

### Level Up Rewards
- **+1 Max HP** (permanent)
- HP is also healed by that amount
- Displayed at end of wave in post-wave reward screen

### Enemy XP Values
| Enemy | XP Value | Notes |
|-------|----------|-------|
| Weakling | 1 | Fodder, minimal XP |
| Cultist | 1 | Fodder |
| Husk | 2 | Basic grunt |
| Spitter | 2 | Basic ranged |
| Spinecrawler | 3 | Fast threat |
| Bomber | 3 | Risky target |
| Stalker | 5 | Mid-tier |
| Torchbearer | 6 | Elite buffer |
| Reaver | 6 | Elite shredder |
| Titan | 8 | Elite tank |
| Channeler | 8 | Elite spawner |
| Ember Saint | 50 | Boss - massive XP |

### XP Modifiers
- `xp_gain_percent` stat (default 100%) - multiplies all XP gained
- Can be increased via shop upgrades or artifacts

---

## Wardens (4 Playable Characters)

Wardens now provide stat MODIFIERS (bonuses) rather than setting absolute stats. Base stats come from PlayerStats defaults (50 HP, 1 energy, 1 draw).

### Veteran Warden (Neutral Baseline)

- **Fantasy**: Battle-hardened generalist
- **Stat Bonuses**: +20 HP, +2 energy
- **Passive**: None (balanced stats, no special bonuses)
- **Starting Cards**: None - player picks starter weapon

#### Starter Deck (board-synergy proposal, not implemented yet)
- Goal: put the lane to work immediately, then amplify it with tempo and tag infusion.
- Proposed 10 cards:
	- Rusty Pistol ×2 (gun, persistent) – baseline auto-clear and tag targets
	- Storm Carbine ×1 (gun, persistent, close/mid) – pushes lane presence without overshooting damage
	- Ammo Cache ×1 (skill, instant, engine_core, gun) – fuels cheap gun curve and early rerolls
	- Minor Hex ×1 (hex, instant) – single-target setup for beam/hex synergies
	- Minor Barrier ×1 (barrier, instant) – early ring control and fortress hooks
	- Guard Stance ×1 (defense, instant, fortress) – stabilizer
	- Precision Strike ×1 (gun, instant, single_target) – stack breaker, works with future tags
	- Shove ×1 (skill, instant, ring_control, volatile) – movement control and barrier trigger
	- **Overclock (new card)** ×1 – skill, instant, engine_core: "All deployed guns fire immediately for 75% damage; draw 1." (board tempo lever)
	- **Tag Infusion: Piercing (new card/service)** ×1 – skill, instant: "Add `piercing` tag to a chosen gun. Piercing shots continue through a stack to hit a second enemy (overflow applies)." (turns Rusty Pistol into two-hit in stacks)
- Early shop priorities: another persistent gun (Twin Pistols/Choirbreaker/Infernal Pistol), one barrier enabler (Ring Ward or Barrier Sigil), and a second ammo/tempo piece (Ammo Cache or Ritual Cartridge) to keep lane-filling fast.

### Ash Warden

- **Focus**: Guns/Fire
- **Stat Bonuses**: +10 HP, +2 energy, +15% gun damage, +10% damage vs Close/Melee

### Gloom Warden

- **Focus**: Hexes
- **Stat Bonuses**: +15 HP, +2 energy, +20% hex damage, -10% heal power

### Glass Warden

- **Focus**: Defense/Risk
- **Stat Bonuses**: +20 HP, +1 energy, +25% armor gain
- **Passive**: Survive fatal hit once per wave at 1 HP

---

## Enemy Definitions (11 Enemies)

### Enemy Archetypes

| Archetype | Description | Build Matchup |
|-----------|-------------|---------------|
| Rusher | Fast melee threats | Food for Lifedrain, tests Gun Board |
| Fast Rusher | Very fast, low HP | Punishes slow Hex builds |
| Ranged Anchor | Stops at Mid, shoots | Counters pure Barrier |
| Tank | High HP + armor | Rewards Hex and multi-hit Barriers |
| Bomber | Explodes on death | Volatile/Barrier synergy |
| Buffer | Amps nearby enemies | Priority target for all |
| Spawner | Generates enemies each turn | Engine food or overwhelming |
| Ambusher | Spawns in Close/Melee | Punishes greedy builds |
| Armor Shredder | Attacks armor efficiently | Counters Fortress |
| Boss | Multi-ability encounter | Tests all builds |

### Enemy Stats

| Enemy | HP | Damage | Speed | Armor | Archetype | Behavior |
|-------|-----|--------|-------|-------|-----------|----------|
| Weakling | 3 | 2 | 1 | 0 | Rusher | Trivially easy Wave 1 enemy |
| Husk | 8 | 4 | 1 | 0 | Rusher | Basic melee, walks to player |
| Spinecrawler | 6 | 3 | 2 | 0 | Fast Rusher | Moves 2 rings/turn |
| Cultist | 4 | 2 | 1 | 0 | Rusher (Swarm) | Spawns in groups |
| Spitter | 7 | 3 | 1 | 0 | Ranged Anchor | Stops at Mid, ranged attacks |
| Shell Titan | 22 | 8 | 1 | 3 | Tank | High HP + armor, slow |
| Bomber | 9 | 0 | 1 | 0 | Bomber | Explodes: 6 to player, 4 to ring enemies |
| Torchbearer | 10 | 2 | 1 | 0 | Buffer | At Close: +2 damage to adjacent enemies |
| Channeler | 12 | 3 | 1 | 0 | Spawner | At Close: spawns 1 Husk in Far per turn |
| Stalker | 9 | 6 | 1 | 0 | Ambusher | Spawns directly in Close |
| Armor Reaver | 10 | 3 | 1 | 0 | Shredder | Deals 3 damage + shreds 3 armor |
| Ember Saint | 60 | 10 | 0 | 4 | Boss | Ranged AoE, spawns Bombers/Husks |

### Wave Bands (20 Waves - Brotato Economy)

**Waves 1-3: Onboarding (Trivially Easy)**
- Wave 1: Just 3 Weaklings (3 HP, 2 damage each)
- Waves 2-3: Weaklings + Cultists, transitioning to Husks
- Survive and collect scrap for your first shop visit

**Waves 4-6: Build Check**
- Introduce Spinecrawlers (Fast Rushers)
- More Spitters, first Torchbearer/Channeler
- Tests that builds are coming online

**Waves 7-9: Stress Mix**
- Theme waves:
  - Bomber Storm (great for Barrier/Volatile)
  - Ranged Wall (counters pure Barrier)
  - Tank Corridor (tests Hex/Barrier scaling)

**Waves 10-12: Late Game**
- Heavy elite pressure
- Multiple elite types per wave
- Build should be strong now

**Waves 13-16: Endgame**
- Shredder Rush, Double Buffer, Tank Line
- All-out assault with mixed elite compositions
- Build is complete, survive the onslaught

**Waves 17-20: Boss Rush**
- Gauntlet waves with massive pressure
- Wave 20: Ember Saint boss + enhanced support

---

## Combat Clarity System

A multi-layer UX system to reduce cognitive overload when tracking hordes:

### Behavior Badges

Each enemy panel shows an archetype badge in top-left corner:

| Badge | Archetype | Color | Meaning |
|-------|-----------|-------|---------|
| 🏃 | Rusher | Red | Advances every turn until melee |
| ⚡ | Fast | Orange | Moves 2 rings per turn |
| 🏹 | Ranged | Blue | Stops at distance, attacks from afar |
| 💣 | Bomber | Yellow | Explodes when killed |
| 📢 | Buffer | Purple | Increases nearby enemy damage +2 |
| ⚙️ | Spawner | Cyan | Creates additional enemies each turn |
| 🛡️ | Tank | Gray | High health and armor, slow |
| 🗡️ | Ambush | Pink | Spawns directly in close range |
| 👑 | Boss | Gold | Powerful with special abilities |

### Ring Threat Colors

Ring borders dynamically color-coded by threat level:

| Threat Level | Color | Criteria |
|--------------|-------|----------|
| Safe | Green | 0 damage expected |
| Low | Yellow | 1-10 damage expected |
| Medium | Orange | 11-20 damage expected |
| High | Red | 21+ damage OR bomber present |
| Critical | Pulsing Red | Lethal damage (would kill player) |

### Aggregated Intent Bar

Top bar summarizing battlefield state:
- **⚔️ X Incoming**: Total damage from melee enemies
- **💣 X Bombers**: Count of living bombers
- **📢 Buff Active (+X)**: Active buffer bonus
- **⚙️ Spawning**: Active spawners
- **⚡ X Fast**: Count of fast enemies

### Danger Highlighting

Pulsing glow effects on high-priority threats:

| Priority | Color | Pulse | Criteria |
|----------|-------|-------|----------|
| CRITICAL | Red | 0.4s | Bombers about to explode |
| HIGH | Orange | 0.6s | Enemies reaching melee next turn |
| MEDIUM | Purple | 0.8s | Active buffers/spawners at target ring |
| LOW | Cyan | 1.0s | Fast enemies not yet close |

### Card Targeting Hints

On card hover:
- Yellow overlay on targetable enemies
- Damage preview (-X) on each target
- Skull icon (💀) + red highlight on enemies that would die

### Event Callouts

Flash banners for important events:
- Buffer activates: Purple banner
- Spawner spawns: Cyan banner
- Bomber reaches melee: Yellow warning
- Bomber explodes: Red-orange banner

---

## Combat Lane System

A Hearthstone-style "board" for deployed persistent weapons, positioned between the battlefield and hand.

### Visual Design

```
┌─────────────────────────────────────────────────────┐
│                    BATTLEFIELD                       │
│              (Concentric enemy rings)                │
├─────────────────────────────────────────────────────┤
│  ⚡ DEPLOYED WEAPONS (3/7)                          │
│  ┌──────┐  ┌──────┐  ┌──────┐                       │
│  │ 🔫   │  │ 🔫   │  │ 🔫   │  (fills ~80% of lane) │
│  │Rusty │  │Pistol│  │Turret│                       │
│  │ ⚔3  │  │ ⚔4  │  │ ⚔3  │                       │
│  └──────┘  └──────┘  └──────┘                       │
├─────────────────────────────────────────────────────┤
│                   CARD HAND                          │
│    [Card 1] [Card 2] [Card 3] [Card 4] [Card 5]     │
└─────────────────────────────────────────────────────┘
```

### Features

| Feature | Description |
|---------|-------------|
| Deployment Animation | Cards fly from hand to lane with shrink effect |
| Weapon Fire Effect | Cards pulse briefly when triggering (no glow borders) |
| Damage Floater | "-X⚔" rises from card when damage dealt |
| Capacity Limit | Maximum 7 weapons deployed at once |
| Card Scale | Cards auto-resize to ~80% of lane height whenever the lane resizes |
| Lane Visibility | Lane frame always visible; label indicates empty/full |
| Hover Preview | Hover spawns full-size preview card above lane without altering base card scale |

### Timing

- Weapons deploy **instantly** when persistent card is played
- Weapons **fire at end of turn** (before enemy phase)
- Weapons phase has subtle yellow glow overlay while processing

### Implementation

- `scripts/ui/CombatLane.gd` - Main lane controller (dynamic card scaling + preview logic)
- Scaled `CardUI.tscn` instances sized to ~80% of lane height (computed from control size)
- Connected to `CombatManager.weapon_triggered` signal
- Cards stored in `deployed_weapons: Array[Dictionary]`

---

## Technical Architecture

### Autoloads (Singletons)

| Script | Purpose |
|--------|---------|
| SettingsManager | User settings persistence |
| GameManager | Scene transitions, game state |
| RunManager | Current run: HP, scrap, deck, wave, PlayerStats |
| CombatManager | Turn flow, card playing, enemy AI, artifact triggers |
| CardDatabase | All card definitions (48 cards) |
| EnemyDatabase | All enemy definitions (11 enemies) |
| MergeManager | Triple-merge card upgrades |
| ArtifactManager | Artifact effects (26 artifacts) |
| ShopGenerator | V2 shop generation with family biasing |
| AudioManager | Sound effect handling |
| CombatAnimationManager | Combat visual effects and animation sequencing |

### Key Scenes

| Scene | Path |
|-------|------|
| Main Menu | `scenes/MainMenu.tscn` |
| Settings | `scenes/Settings.tscn` |
| Warden Select | `scenes/WardenSelect.tscn` |
| Starter Weapon Select | `scenes/StarterWeaponSelect.tscn` |
| Combat | `scenes/Combat.tscn` |
| Shop | `scenes/Shop.tscn` |
| Run End | `scenes/RunEnd.tscn` |
| Meta Menu | `scenes/MetaMenu.tscn` |

### Resource Classes

| Class | File | Purpose |
|-------|------|---------|
| CardDefinition | `scripts/resources/CardDefinition.gd` | Card stats and effects |
| EnemyDefinition | `scripts/resources/EnemyDefinition.gd` | Enemy stats and behavior |
| WardenDefinition | `scripts/resources/WardenDefinition.gd` | Character stats and passives |
| WaveDefinition | `scripts/resources/WaveDefinition.gd` | Wave spawn scripts |
| ArtifactDefinition | `scripts/resources/ArtifactDefinition.gd` | Artifact effects |
| PlayerStats | `scripts/resources/PlayerStats.gd` | V2 stat sheet |

### Combat Classes

| Class | File | Purpose |
|-------|------|---------|
| BattlefieldState | `scripts/combat/BattlefieldState.gd` | Ring management, enemy tracking |
| EnemyInstance | `scripts/combat/EnemyInstance.gd` | Runtime enemy state |
| DeckManager | `scripts/combat/DeckManager.gd` | Deck, hand, discard zones |
| CardEffectResolver | `scripts/combat/CardEffectResolver.gd` | Execute card effects |

### Constants

| File | Purpose |
|------|---------|
| TagConstants | `scripts/constants/TagConstants.gd` | Canonical tag names |

---

## Card UI Specification

### Card Layout (220x320 pixels)

```
┌─────────────────────────────┐
│ [1] Card Name Here      T2  │  ← Header: Cost, Name, Tier
├─────────────────────────────┤
│           ⚔️                │  ← Type Icon (large)
│                             │
│  ┌───────────────────────┐  │
│  │   EFFECT STATS ROW    │  │  ← Stats: DMG/HEX/HEAL/ARMOR
│  │   ⚔ 4    ☠ 0    ♥ 0  │  │
│  └───────────────────────┘  │
│                             │
│  Persistent: Deal 3 to a    │  ← Description with timing label
│  random enemy at turn end.  │
│                             │
├─────────────────────────────┤
│  🎯 1 Random │ ALL Rings    │  ← Target Row
├─────────────────────────────┤
│  🔁 PERSISTENT │ gun        │  ← Footer: Timing Badge + Tags
└─────────────────────────────┘
```

### Timing Badges

| Timing | Badge | Color |
|--------|-------|-------|
| Instant | ⚡ INSTANT | White |
| Persistent | 🔁 PERSISTENT | Gold |
| Buff | ✦ BUFF | Blue |

### Effect Stats Row

| Stat | Icon | Color |
|------|------|-------|
| Damage | ⚔ | Red |
| Hex | ☠ | Purple |
| Heal | ♥ | Green |
| Armor | 🛡 | Cyan |
| Draw | 📜 | Blue |
| Energy | ⚡ | Yellow |

### Card Background by Type

| Type | Background | Border |
|------|------------|--------|
| Weapon | Dark Red `#2a1515` | Red `#e66450` |
| Skill | Dark Blue `#151a2a` | Blue `#50a0e6` |
| Hex | Dark Purple `#1f152a` | Purple `#9050e6` |
| Defense | Dark Green `#152a1f` | Green `#50e690` |

### Tier Border Colors

| Tier | Border Color |
|------|--------------|
| Tier 1 | Gray `#b0b0b0` |
| Tier 2 | Blue `#4d99ff` |
| Tier 3 | Gold `#ffcc33` |

---

## Triple-Merge System

- Collect 3 copies of the same card at the same tier
- Merge into a stronger version (Tier 1 → 2 → 3)
- Higher tiers have improved stats (~1.5x T2, ~2x T3)
- Tags remain unchanged
- Shop UI shows available merges

---

## File Structure

```
DeckHorde/
├── scenes/
│   ├── MainMenu.tscn
│   ├── WardenSelect.tscn
│   ├── Combat.tscn
│   ├── BattlefieldArena.tscn
│   ├── Shop.tscn
│   ├── PostWaveReward.tscn  # Unused - kept for reference
│   ├── RunEnd.tscn
│   ├── MetaMenu.tscn
│   ├── Settings.tscn
│   └── ui/
│       └── CardUI.tscn
├── scripts/
│   ├── autoloads/
│   │   ├── GameManager.gd
│   │   ├── RunManager.gd
│   │   ├── CombatManager.gd
│   │   ├── CardDatabase.gd
│   │   ├── EnemyDatabase.gd
│   │   ├── MergeManager.gd
│   │   ├── ArtifactManager.gd
│   │   ├── ShopGenerator.gd
│   │   ├── AudioManager.gd
│   │   ├── SettingsManager.gd
│   │   └── CombatAnimationManager.gd
│   ├── resources/
│   │   ├── CardDefinition.gd
│   │   ├── EnemyDefinition.gd
│   │   ├── WardenDefinition.gd
│   │   ├── WaveDefinition.gd
│   │   ├── ArtifactDefinition.gd
│   │   └── PlayerStats.gd
│   ├── constants/
│   │   └── TagConstants.gd
│   ├── combat/
│   │   ├── BattlefieldState.gd
│   │   ├── BattlefieldArena.gd
│   │   ├── EnemyInstance.gd
│   │   ├── DeckManager.gd
│   │   └── CardEffectResolver.gd
│   ├── tests/
│   │   └── TestRunner.gd
│   └── ui/
│       ├── MainMenu.gd
│       ├── WardenSelect.gd
│       ├── CombatScreen.gd
│       ├── CardUI.gd
│       ├── Shop.gd
│       ├── RunEnd.gd
│       ├── MetaMenu.gd
│       ├── Settings.gd
│       ├── DebugStatPanel.gd
│       └── CardDebugOverlay.gd
├── data/
│   ├── cards/
│   ├── enemies/
│   ├── wardens/
│   ├── waves/
│   └── artifacts/
├── textures/
├── project.godot
├── AGENTS.md          # Agent guidelines
├── DESIGN.md          # This file
└── PROGRESS.md        # Status tracker
```

---

## How to Test

### Visual Test
1. Open project in Godot 4.5+
2. Press F5
3. New Run → Select Warden → Start
4. Play cards, end turns, watch enemies
5. Press F3 to view debug stat panel

### Debug Features
- **F3**: Toggle debug stat panel (shows all PlayerStats)
- Cards show tags in tooltips
- Intent bar shows battlefield summary

---

## Agent Quick Start

### To add a new card:
1. Open `scripts/autoloads/CardDatabase.gd`
2. Find `_create_default_cards()` function
3. Copy an existing card block and modify
4. Add appropriate tags from TagConstants

### To add a new enemy:
1. Open `scripts/autoloads/EnemyDatabase.gd`
2. Find `_create_default_enemies()` function
3. Copy an existing enemy block and modify
4. Set appropriate `behavior_type`

### To add a new artifact:
1. Open `scripts/autoloads/ArtifactManager.gd`
2. Add artifact definition with `stackable` property
3. Set `required_tags` for family-specific effects
4. Wire trigger into CombatManager if needed
