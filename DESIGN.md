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
2. **Combat** - Survive waves of enemies using your deck
3. **Shop** - Buy cards, artifacts, stat upgrades, services (primary build driver)
4. **Repeat** - Progress through 20 waves to victory

**Note:** Health restores to full after each wave. Scrap comes from killing enemies during combat.

### Brotato Economy Overview

Inspired by Brotato, this economy system emphasizes shop-driven progression:

| Feature | Value | Notes |
|---------|-------|-------|
| Starting HP | 50 | +20 from typical warden bonus |
| Starting Energy | 3 | Buy more in shop |
| Starting Draw | 5 | Buy more in shop |
| Starting Cards | 10 | Predefined starter deck |
| Total Waves | 20 | Extended from 12 |
| Interest Rate | 5% | Up to 25 scrap/wave |

**Interest System**: After each wave, earn 5% of your scrap (max 25). Encourages saving!

---

## V3 Combat System: Queue and Execute

### Overview

The V3 combat system replaces persistent weapons with a **queue and execute** model:

1. **Staging Phase**: Player plays cards to a "combat lane" staging area
2. **Cards Queue**: Cards appear from left to right in the order played
3. **Reordering**: Player can drag-and-drop cards to reorder them before execution
4. **Execution**: When player ends turn, all staged cards execute left-to-right
5. **Discard**: All weapon cards are "one and done" - they go to discard after use

### Key Differences from V2

| Feature | V2 (Old) | V3 (New) |
|---------|----------|----------|
| Weapons | Persistent, stay deployed | One-and-done, return to discard |
| Turn Flow | Play 1 card → immediate effect | Queue multiple cards → execute all at once |
| Combat Lane | Displayed deployed weapons | Staging area for cards to execute |
| Card Synergies | Limited, via artifacts | Core mechanic via lane buffs and execution order |
| Duration System | turns, kills, burn_out, infinite | Removed entirely |

### Synergy System

The V3 system emphasizes **card synergies** through execution order:

**Lane Buffs**: Some cards apply temporary buffs that affect cards played after them:
- "Gun Amplifier" - All gun cards after this gain +2 damage
- "Hex Catalyst" - All hex cards after this apply +1 hex
- "Armor Forge" - All defense cards after this gain +2 armor

**Scaling Cards**: Some cards get stronger based on what's already been played:
- "Armored Tank" - Gains +2 damage for every gun already fired this turn
- "Chain Lightning" - Deals +1 damage per enemy already damaged this turn

**Example Turn**:
1. Play "Gun Amplifier" (buff: +2 gun damage)
2. Play "Pistol" (3 → 5 damage due to buff)
3. Play "Shotgun" (4 → 6 damage due to buff)
4. Play "Armored Tank" (2 + 4 = 6 damage, 2 guns already fired)

### Turn Structure (V3)

1. **Draw Phase** - Draw cards to hand (5 by default)
2. **Staging Phase** - Play cards to combat lane (costs energy)
3. **Execute Phase** - Cards execute left-to-right when turn ends
4. **Enemy Phase** - Enemies move inward and attack
5. **Wave Check** - Win if all enemies dead, lose if player HP reaches 0

### Combat Lane UI

```
┌─────────────────────────────────────────────────────────────┐
│                       BATTLEFIELD                            │
│                 (Concentric enemy rings)                     │
├─────────────────────────────────────────────────────────────┤
│  STAGING LANE - Drag to reorder                 [EXECUTE]   │
│  ┌──────┐  ┌──────┐  ┌──────┐  ┌──────┐                     │
│  │ Amp  │  │ 🔫   │  │ 🔫   │  │ Tank │                     │
│  │+2dmg │  │Pistol│  │Shot  │  │ +4  │                      │
│  │ →    │  │ 5⚔  │  │ 6⚔  │  │ 6⚔  │                      │
│  └──────┘  └──────┘  └──────┘  └──────┘                     │
├─────────────────────────────────────────────────────────────┤
│                      CARD HAND                               │
│       [Card 1] [Card 2] [Card 3] [Card 4] [Card 5]          │
└─────────────────────────────────────────────────────────────┘
```

Features:
- Cards can be dragged left/right to reorder
- Visual preview shows damage with lane buffs applied
- Execute button triggers all cards in sequence
- Cards animate flying to their target when executed

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

- `scenes/Combat.tscn` now anchors `BattlefieldArena` from `offset_top = 50` down to `offset_bottom = -585`, so the semicircle center lands a few pixels above the Combat Lane regardless of resolution.
- `BattlefieldRings.gd` dropped its padding to 18px and now consumes 98% of the available half-width/height, making the rings visibly larger without bleeding into the lane.
- Enemy panels scale with viewport: width = `clamp(shortest_side * 0.11, 70, 150)`

#### Enemy Display System (Horde Handling)

**Lane-Based Placement System** (12 fixed lanes):
- Groups occupy specific lane slots (0-11) distributed evenly across 180° semicircle
- Lane 0 = far left (angle PI), Lane 11 = far right (angle 2*PI), Lane 6 = center top
- New groups assigned random available lane
- Lane index persists when groups move between rings (Far→Mid→Close→Melee)
- Maintains relative left/right ordering at all times

**Collision Prevention**:
- 12px pixel buffer between group panels
- Size clamping: panels scale to 0.7x minimum when >6 groups in a ring
- Adjacent panels nudged apart if overlap detected after positioning

**Z-Order by Ring**:
- Melee (ring 0): z_index = 4 (renders on top)
- Close (ring 1): z_index = 3
- Mid (ring 2): z_index = 2
- Far (ring 3): z_index = 1
- Ensures groups in closer rings render above groups in farther rings

**Multi-Row Distribution** (5-8 enemies in a ring):
- Enemies distributed across inner (35% depth) and outer (75% depth) rows

**Overflow Stacking** (3+ of same enemy type):
- Identical enemies collapse into a "stack" panel with count badge (e.g., "x5")
- Stack shows aggregate HP bar
- **Expand on Hover**: Hovering fans out mini-panels showing individual HP

##### Mini Enemy Stack Panels
- `MiniEnemyPanel.gd` waits for the node's `ready` signal before laying out child controls so `@onready` references exist even when created via factories and added to the tree later.
- Enemy metadata (icon glyph, behavior badge tooltip) always resolves through the `EnemyDatabase` autoload rather than `Engine.get_singleton`, matching the rest of combat systems and preventing null singletons.
- Regression coverage lives in `scenes/tests/TestMiniEnemyPanel.tscn` (`scripts/tests/TestMiniEnemyPanel.gd`), which instantiates a panel with a stub husk enemy, awaits `setup`, and asserts both the icon text and behavior badge match the database definition.
- Stack hover/layout regression coverage lives in `scenes/tests/TestBattlefieldUI.tscn` (`scripts/tests/TestBattlefieldUI.gd`), which asserts mini-panels remain above the stack card and verifies only the parent stack (not mini-panels) spawns the info card tooltip.
- Expanded mini-panels now fan out **above** their parent stack card with a fixed 16px gap so the group panel stays fully visible.
- Hovering the main stack card spawns the encyclopedia-style info card immediately, anchored to the right edge of the stack card and vertically aligned just below the mini-panel row; hovering individual mini-panels still suppresses info cards to keep the UI clean.
- **Real-time HP updates**: When an enemy in an expanded stack takes damage, its individual mini-panel HP bar updates immediately alongside the stack's aggregate HP bar.
- **Death animation**: When a unit dies, its mini-panel flashes red, scales up briefly, then fades out. Remaining mini-panels reposition smoothly to fill the gap. Enemy HP is clamped to 0 (never shows negative).
- **Lane-based group positioning**: Groups use a fixed 12-lane system instead of dynamic angular distribution. Lane 0 = far left, Lane 11 = far right. New groups randomly assigned to available lanes in their ring.
- **Ring movement lane preservation**: When a group moves between rings, its lane index is preserved. The group moves radially (same angle, different radius) without lateral drift. `_occupied_lanes[ring][lane] = group_id` tracks occupancy.
- **Non-overlap enforcement**: 12px collision buffer, panels nudged apart if overlapping. Size clamping (min 0.7x scale) when >6 groups per ring.
- **Z-order by ring**: Melee groups render above Close, above Mid, above Far (z_index = 4, 3, 2, 1 respectively).
- **Encyclopedia card lifecycle**: Info cards properly hide when: (1) stacks are removed, (2) hover state is lost, (3) `_refresh_all_visuals()` is called. The hover system clears pending timers and anchor rects when `clear()` is called.

#### Enemy Center Targeting & Damage Numbers
- `BattlefieldEnemyManager.get_enemy_center_position(instance_id: int)` resolves centers using only the integer `instance_id`, matching how `CombatManager.deal_damage_to_random_enemy()` references targets.
- Destroyed visuals linger in `destroyed_visuals`, and the helper now falls back to those panels so late projectiles and death particles still aim at the correct coordinates instead of `(0,0)`.
- Regression coverage lives in `scenes/tests/TestEnemyCenterPosition.tscn` (`scripts/tests/TestEnemyCenterPosition.gd`), which instantiates the manager, spawns an enemy, and asserts the helper matches the panel midpoint.

### Card Types (V3)

| Type | Description |
|------|-------------|
| Weapon/Gun | Deal damage, one-and-done (returns to discard) |
| Skill | Buffs, healing, utility, draw, energy |
| Hex | Apply stacking damage-over-time to enemies |
| Defense | Gain armor, create barriers |
| Lane Buff | Apply temporary buffs to subsequent cards in execution |

### Card Play Modes

**Combat Cards** (`play_mode = "combat"`):
- Dragged to the **Staging Lane** at the bottom of screen
- Queue up left-to-right, can be reordered
- Execute all at once when "End Turn" is clicked

**Instant Cards** (`play_mode = "instant"`):
- Resolve **immediately** when played, don't go to staging lane
- Most instant cards can be dragged anywhere outside the hand area
- **Instant Ring-Targeting Cards**: Cards with `requires_target = true` and `target_type = "ring"` must be dragged directly to the battlefield
  - Valid target rings **highlight green** when the card is dragged over them
  - Drop on a valid ring to play the card targeting that ring
  - Example: **Shield Barrier** - drag to Close/Mid/Far ring to place the barrier there

### Core Mechanics

**Energy**: Resource spent to play cards. Refills to max each turn.

**Armor**: Absorbs damage before HP. Persists between turns until used.

**Hex**: Stacking debuff on enemies. When a hexed enemy takes damage, they take bonus damage equal to their hex stacks, then hex is consumed.

**Lane Buffs**: Temporary effects that modify cards executed after them in the same turn. Reset after execution completes.

**Barriers**: Ring-based traps that damage enemies when crossed. Have a set number of uses (e.g., 2 uses). Each enemy that crosses consumes 1 use, and the barrier disappears when uses reach 0.

---

## V4 Card Pool (Starter Deck + Core Cards)

### Card Design Principles

1. **All weapons are one-and-done** - No persistence tracking needed
2. **Lane buffs encourage ordering** - Playing buff first maximizes value
3. **Scaling cards reward setup** - Building a strong turn feels satisfying
4. **V4 Tag Compliance** - Every card has exactly 1 core type tag, 0-2 family tags, 0-1 damage type
5. **Clear synergy tags** - "gun" cards benefit from gun buffs, etc.

### Veteran Starter Deck (10 cards)

| Card | Type | Cost | Tags | Effect |
|------|------|------|------|--------|
| Pistol ×3 | Weapon | 1 | gun | Deal 3 damage to random enemy |
| Shotgun ×2 | Weapon | 2 | gun, aoe | Deal 4 damage to random enemy in Melee/Close, +2 splash to group |
| Guard Stance ×2 | Skill | 1 | defense | Gain 4 armor |
| Minor Hex ×1 | Skill | 1 | hex | Apply 3 hex to random enemy |
| Gun Amplifier ×1 | Skill | 1 | buff, gun | All gun cards after this gain +2 damage this turn |
| Tactical Reload ×1 | Skill | 0 | draw | Draw 2 cards |

### Lane Buff Cards

| Card | Cost | Tags | Effect |
|------|------|------|--------|
| Gun Amplifier | 1 | buff, gun | All gun cards after this gain +2 damage this turn |
| Hex Catalyst | 1 | buff, hex | All hex cards after this apply +1 hex this turn |
| Armor Forge | 1 | buff, defense | All defense cards after this gain +2 armor this turn |
| Energy Surge | 0 | buff | Refund 1 energy for the next card played |
| Momentum | 1 | buff | Next 3 cards cost 1 less energy (min 0) |

### Scaling Weapon Cards

| Card | Cost | Tags | Effect |
|------|------|------|--------|
| Armored Tank | 2 | gun, defense, scaling | Deal 2 damage (+2 per gun already fired), convert damage to armor |
| Chain Lightning | 2 | shock, scaling | Deal 3 damage (+1 per enemy already damaged this turn) |
| Finishing Shot | 1 | gun, execute | Deal 5 damage to lowest HP enemy. +3 if target has hex |
| Volley | 2 | gun, aoe | Deal 2 damage × number of cards staged after this |

### Basic Weapon Cards

| Card | Cost | Tags | Effect |
|------|------|------|--------|
| Pistol | 1 | gun | Deal 3 damage to random enemy |
| Shotgun | 2 | gun, aoe | Deal 4 damage + 2 splash to target's group |
| Rifle | 2 | gun, sniper | Deal 6 damage to random enemy in Mid/Far |
| SMG | 1 | gun, rapid | Deal 2 damage to 2 random enemies |
| Grenade | 2 | explosive, aoe | Deal 3 damage to all enemies in target ring |

### Hex Cards

| Card | Cost | Tags | Effect |
|------|------|------|--------|
| Minor Hex | 1 | hex | Apply 3 hex to random enemy |
| Plague Cloud | 2 | hex, aoe | Apply 2 hex to all enemies |
| Withering Mark | 1 | hex, single | Apply 5 hex to target enemy |
| Hex Explosion | 2 | hex, consume | Consume all hex on target, deal that damage to all adjacent |

### Defense Cards

| Card | Cost | Tags | Effect |
|------|------|------|--------|
| Guard Stance | 1 | defense | Gain 4 armor |
| Iron Wall | 2 | defense | Gain 8 armor |
| Minor Barrier | 1 | barrier | Place barrier: deals 3 damage when crossed |
| Reactive Armor | 1 | defense | Gain 2 armor. +2 for each enemy in Melee |

### Utility Cards

| Card | Cost | Tags | Effect |
|------|------|------|--------|
| Tactical Reload | 0 | draw | Draw 2 cards |
| Adrenaline | 1 | energy | Gain 2 energy |
| Focus Fire | 1 | target | Next weapon deals double damage |
| Shove | 1 | control | Push 1 enemy back 1 ring |

---

## V4 Tag System (3-Layer Design)

Every card has tags that define its behavior and synergies. V4 uses a strict 3-layer tag system:

### Core Type Tags (exactly 1 per card)

Every card must have exactly one core type tag:

- `gun` – direct damage weapons
- `hex` – curse / debuff / DoT
- `barrier` – ring traps and movement-triggered effects
- `defense` – armor, shields, direct HP manipulation
- `skill` – instant effects: draw, energy, utility, buff cards
- `engine` – persistent non-weapon effects (turrets, auras)

### Build-Family Tags (0-2 per card)

These define Brotato-style build families for synergies and shop biasing:

- `lifedrain` – heals/sustain / HP manipulation
- `hex_ritual` – spends/uses hex and HP for big power spikes
- `fortress` – heavy armor/barrier stacking and turtling
- `barrier_trap` – barriers that act like damage-dealing traps
- `volatile` – self-damage, risky payoffs
- `engine_core` – draw/energy/economy engines

### Damage-Type Tags (0-1 per card)

These define how damage behaves for synergies and artifact scaling:

- `explosive` – splash damage to adjacent rings
- `piercing` – overkill flows to next target
- `beam` – chain damage through targets
- `shock` – slow/stun chance on hit
- `corrosive` – armor shred, doubled on hexed

### Mechanical Tags (0-2 per card)

These define card mechanics for targeting and artifact interactions:

- `shotgun` – many weak hits in Melee/Close
- `sniper` – prefers Far/Mid
- `aoe` – hits many enemies or full rings
- `ring_control` – pushes/moves enemies between rings
- `swarm_clear` – effective against multiple enemies

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

## V4 Build Families (8 Primary Families)

The game supports 8 distinct build archetypes with clear tag identities:

### Gunline (Primary)
Build up massive turn combos with gun synergies. Play buff cards first, then unleash a volley of amplified shots.
- **Tags**: `gun` (core type)
- **Stat Focus**: `gun_damage_percent`
- **Play Pattern**: Buff stacking → gun chain execution
- **Key Artifacts**: Sharpened Rounds, Glass Core, Gun Volley

### Hex Ritual
Stack hex across the horde, trade HP/tempo for enormous delayed damage. Strong vs large waves.
- **Tags**: `hex` (core type), `hex_ritual` (family)
- **Stat Focus**: `hex_damage_percent`
- **Play Pattern**: Spread hex → consume for burst damage
- **Key Artifacts**: Hex Lens, Occult Focus, Creeping Doom

### Fortress
Tank builds with heavy armor/barrier stacking and turtling.
- **Tags**: `defense` (core type), `fortress` (family)
- **Stat Focus**: `armor_gain_percent`, `barrier_strength_percent`
- **Play Pattern**: Armor layering, survive attrition
- **Key Artifacts**: Reinforced Plating, Runic Bastion

### Barrier Traps
Offensive barriers that deal damage when crossed.
- **Tags**: `barrier` (core type), `barrier_trap` (family)
- **Stat Focus**: `barrier_damage_percent`
- **Play Pattern**: Place traps → funnel enemies through them
- **Key Artifacts**: Barrier Alloy, Trap Engineer, Punishing Walls

### Lifedrain
Trade damage for sustain. Constantly healing and converting sustain into armor/damage.
- **Tags**: `lifedrain` (family), any core type
- **Stat Focus**: `heal_power_percent`, `max_hp`
- **Play Pattern**: Sustain through damage, overheal synergies
- **Key Artifacts**: Leech Core, Hemorrhage Engine, Red Aegis

### Volatile
Glass cannon builds with self-damage and risky payoffs.
- **Tags**: `volatile` (family), typically `gun` core
- **Stat Focus**: `explosive_damage_percent`
- **Play Pattern**: High risk/reward, explosive burst
- **Key Artifacts**: Overloader, Volatile Reactor

### Engine/Economy
Draw/energy/economy engines that cycle through the deck rapidly.
- **Tags**: `skill` (core type), `engine_core` (family)
- **Stat Focus**: `draw_per_turn`, `energy_per_turn`, `scrap_gain_percent`
- **Play Pattern**: Cycle cards, build resources
- **Key Artifacts**: Tactical Pack, Surge Capacitor, Engine Core Regulator

### Control (Soft Package)
Ring manipulation and movement denial - pairs with other families.
- **Tags**: `ring_control` (mechanic)
- **Play Pattern**: Push enemies, delay threats
- **Artifacts**: Kinetic Harness, Shock Collars

---

## Rarity System

Both cards and artifacts use a 4-tier rarity system:

| Rarity | Tier | Color | Shop Weight | Notes |
|--------|------|-------|-------------|-------|
| Common | 1 | Gray | High | Starter deck cards, basic pieces |
| Uncommon | 2 | Green | Medium | Solid upgrades |
| Rare | 3 | Blue | Low | Powerful synergy pieces |
| Legendary | 4 | Gold | Very Low | Build-defining power |

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

### V3 Lane Synergy Artifacts (New)

| Artifact | Rarity | Stackable | Effect |
|----------|--------|-----------|--------|
| Chain Loader | Uncommon | ✗ | Each gun fired this turn gives the next gun +1 damage |
| Combo Master | Rare | ✗ | If you play 5+ cards in one turn, all deal +2 damage |
| Lane Commander | Uncommon | ✓ | Lane buffs are +50% more effective |
| Execution Protocol | Rare | ✗ | Last card executed each turn deals +50% damage |

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

## Shop System (V4)

The shop is the **primary build driver**:

### Shop Structure

Per wave, when you open the shop:
- **4 cards** from the card pool
- **3 artifacts** (stat and family items)
- **2 services** (heal, remove card)

### V4 Reroll Cost

Per-reroll scaling encourages thoughtful reroll usage:
- Base wave cost: `base_wave_cost = 3 + floor((wave - 1) / 3)`
- Full formula: `reroll_cost = base_wave_cost + 2 * reroll_count`
- `reroll_count` resets each shop visit (entering a new shop)

| Wave | First Reroll | Second Reroll | Third Reroll |
|------|--------------|---------------|--------------|
| 1-3  | 3 scrap      | 5 scrap       | 7 scrap      |
| 4-6  | 4 scrap      | 6 scrap       | 8 scrap      |
| 7-9  | 5 scrap      | 7 scrap       | 9 scrap      |
| 10+  | 6 scrap      | 8 scrap       | 10 scrap     |

### V4 Shop-Clearing Reward

When you buy ALL card slots AND ALL artifact slots (clearing the shop), you earn **one free reroll**:
- Free reroll does NOT consume scrap
- Free reroll does NOT increment `reroll_count`
- Only card + artifact slots count; services don't need to be purchased
- Visual feedback: "🛒 Shop Cleared! Free Reroll Available!"

### Family Biasing

**Early Waves (1-3)**: Shops aggressively push you into a build family
- 70% of shops: 2+ cards from same focus family
- **V4**: If warden has `preferred_tags`, those tags are used for early biasing
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

## Stat Upgrades (Brotato Economy)

Buyable stat upgrades appear in the shop (1-2 per refresh). Prices scale exponentially with purchases.

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

**V4**: Wardens can have `preferred_tags` to bias early shop offerings toward specific build families.

### Veteran Warden (Neutral Baseline)

- **Fantasy**: Battle-hardened generalist
- **Stat Bonuses**: +20 HP, +2 energy
- **Passive**: None (balanced stats, no special bonuses)
- **Preferred Tags**: `[]` (empty - no shop bias, random family each run)
- **Starter Deck**: 10 predefined cards (see V4 Card Pool section)

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

Threat evaluation pulls directly from each `EnemyInstance` via `will_attack_this_turn()` and `get_predicted_attack_damage()`: melee foes only count when already in ring 0, ranged enemies only count once they reach their target ring and are within `attack_range`, and suicide/bomber types are explicitly excluded so they only flip the "bomber present" flag, not the damage total. The same prediction helper drives stack intent panels so every attack indicator mirrors the actual combat resolution rules.

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

## Technical Architecture

### Autoloads (Singletons)

| Script | Purpose |
|--------|---------|
| SettingsManager | User settings persistence |
| GameManager | Scene transitions, game state |
| RunManager | Current run: HP, scrap, deck, wave, PlayerStats |
| CombatManager | Turn flow, card staging, execution, enemy AI |
| CardDatabase | All card definitions |
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
| DeckManager | `scripts/combat/DeckManager.gd` | Deck, hand, discard zones (no deployed) |
| CardEffectResolver | `scripts/combat/CardEffectResolver.gd` | Execute card effects with lane context |
| BattlefieldArena | `scripts/combat/BattlefieldArena.gd` | Orchestrator for battlefield visuals |
| BattlefieldEffectsNode | `scripts/combat/nodes/BattlefieldEffectsNode.gd` | Projectiles, damage numbers, particle effects |

### Combat Visual Feedback

When effects are applied to enemies, visual feedback is triggered via signals:

| Signal | Handler | Visual Effect |
|--------|---------|---------------|
| `enemy_damaged` | `_on_enemy_damaged()` | Shake enemy, flash red, show damage number |
| `enemy_hexed` | `_on_enemy_hexed()` | Purple flash, hex particles, floating "+☠X" indicator, update hex display |
| `enemy_targeted` | `_on_enemy_targeted()` | Fire projectile at enemy |
| `barrier_placed` | `_on_barrier_placed()` | Green wave effect along ring, shield particles, ring barrier indicator |
| `barrier_triggered` | `_on_barrier_triggered()` | Shield burst at barrier, sparks to enemy, stack expands to show damaged unit |
| `player_damaged` | `_on_player_damaged()` | Show player damage number |

**Barrier Visual Feedback**:

1. **Persistent Barrier Indicator** (while barrier is active):
   - Pulsing green arc along the ring edge
   - Label displays "🛡️ X dmg × Y" showing damage amount and remaining uses
   - Updates immediately when uses are consumed

2. **Barrier Placement** (when Shield Barrier or similar card is played):
   - Green wave effect sweeps along the targeted ring arc
   - Shield particles spawn and pulse along the barrier position
   - Persistent indicator appears showing barrier stats

3. **Barrier Trigger** (when enemy crosses barrier):
   - Shield burst flash at the barrier impact point
   - Green sparks fly from barrier toward the enemy
   - Floating "🛡️ -X" damage text appears at barrier position
   - **Stack expands** to show individual enemies - the damaged unit is visible
   - Stack shakes and flashes green to draw attention
   - Barrier uses decrement (label updates)

4. **Barrier Consumed** (when uses reach 0):
   - Barrier indicator disappears
   - "Break" particle effect - shield shards fall and fade

**Hex Visual Feedback** (applied when hex cards are played):
1. Enemy flashes purple (0.2 seconds)
2. Purple particles spawn around enemy and float upward
3. Floating "+☠X" text appears showing hex amount applied
4. Enemy panel hex display updates immediately (shows ☠ icon + stack count)

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
│  Deal 3 damage to random    │  ← Description
│  enemy.                     │
│                             │
├─────────────────────────────┤
│  🎯 1 Random │ ALL Rings    │  ← Target Row
├─────────────────────────────┤
│  ⚡ INSTANT │ gun           │  ← Footer: Timing Badge + Tags
└─────────────────────────────┘
```

### Timing Badges (V3)

| Timing | Badge | Color |
|--------|-------|-------|
| Instant | ⚡ INSTANT | White |
| Lane Buff | ✦ BUFF | Blue |

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
│       ├── CombatLane.gd
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
4. Play cards to staging lane, end turn to execute
5. Press F3 to view debug stat panel

### Debug Features
- **F3**: Toggle debug stat panel (shows all PlayerStats)
- Cards show tags in tooltips
- Intent bar shows battlefield summary

---

## Agent Quick Start

### To add a new card:
1. Open `scripts/autoloads/CardDatabase.gd`
2. Find `_create_v3_cards()` function
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
