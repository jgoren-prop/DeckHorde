## Riftwardens Design V2 – Brotato-Style Buildcraft

This document defines the **new primary design direction** for Riftwardens that leans heavily into **Brotato-style buildcraft**:

- **Shared, mostly generic card pool** usable by all wardens.
- **Rich tag and stat systems** so builds emerge from **items/artifacts + wardens**, not bespoke class decks.
- **Shop-centric runs** where most of the “game” is in **fast build commits and synergies**.
- **Preserved ring-based tactics and horde pressure**, but with more power coming from your *build* than from micro-optimizing each turn.

V1 (documented in `DESIGN.md`) remains the reference for the current working prototype. This V2 document replaces it as the **authoritative target design** for this branch; the codebase is free to be refactored or rewritten to match V2 without needing to keep V1 runtime-compatible.

---

## 0. High-Level Goals & Constraints

### 0.1 Goals

- **Brotato-like build expression**:
  - Same card pool for (most) wardens.
  - Tags + items + passives create *very* different runs.
  - Early shops heavily influence the build you lock into.
- **Multiple viable builds on the base class alone**:
  - At least 3–4 distinct build families even before adding “crazy” wardens.
- **Keep what’s already fun**:
  - Ring tactics, movement pressure, Bomber/Channeler/Torchbearer interactions.
  - Triple-merge system remains a core progression mechanic.
- **Modular, testable rollout**:

### 0.2 Constraints / Non-Goals (for now)

- V1 runtime behavior does **not** need to be preserved on this branch:
  - Old cards/wardens can be repurposed, retagged, or removed as needed.
  - V1 can live on a separate git branch if we ever want to reference it.
- No assumption of large art/UX overhauls up front:
  - Use current UI where possible; only add what’s required (e.g. tag display, stat sheet).
- Meta progression stays minimal:
  - Focus is on **core run feel**, not unlock trees (those can adapt later).

> **Note**: V2 is intended to fully replace V1 on this branch. Mode toggles and parallel systems are not required unless explicitly reintroduced later.

---

## 1. Phase Plan Overview

Each phase below is **design-first** (spec in this file), then **implementation** (code + data). A future LLM should be able to implement each phase independently.

- **Phase 1** – Tag & Stat Model Spec (no behavior changes).
- **Phase 2** – Base “Veteran Warden” (V2 baseline class).
- **Phase 3** – Core V2 Card Pool (generic weapons, hex, barriers, skills).
- **Phase 4** – V2 Artifact/Item System (stackable, tag-based).
- **Phase 5** – Shop & Reward Rework (Brotato-style build commits, strong early pushes).
- **Phase 6** – Balance & Content Expansion (multiple viable builds on Veteran).
- **Phase 7+** – New “Extreme” Wardens built on top of V2 systems.

Each phase gets:
- **Design spec** (here).
- **Implementation checklist** (for agents).
- **Test plan** (how to verify in-game).

---

## 2. Phase 1 – Tag & Stat Model

### 2.1 Design Intent

Create a **unified language** of tags and stats that:
- Makes cards generic but expressive.
- Lets artifacts and wardens hook into **families** of cards (like Brotato’s medical/elemental/etc.).
- Surfaces a **player stat sheet** that players can read and plan around.

### 2.2 Card Tag Taxonomy

Every card may have:

- **Core type tag** (exactly 1):
  - `gun` – direct damage weapons.
  - `hex` – curse / debuff / DoT.
  - `barrier` – ring traps and movement-triggered effects.
  - `defense` – armor, shields, direct HP manipulation.
  - `skill` – instant effects: draw, energy, utility, minor damage.
  - `engine` – non-weapon persistent effects (turrets, auras, global buffs).

- **Timing tag** (exactly 1):
  - `instant` – resolve once on play.
  - `persistent` – stays in play and triggers each turn or on conditions.

- **Geometry / behavior tags** (0–3):
  - `shotgun` – many weak hits in Melee/Close.
  - `sniper` – prefers Far/Mid.
  - `aoe` – hits many enemies or full rings.
  - `ring_control` – push, pull, slow, reposition.
  - `swarm_clear` – specifically good vs multiple low-HP enemies.
  - `single_target` – focus on one enemy.

- **Build-family tags** (0–3) – Brotato-like lines:
  - `lifedrain` – heals/sustain / HP manipulation.
  - `hex_ritual` – spends/uses hex and HP for big power spikes.
  - `fortress` – heavy armor/barrier stacking and turtling.
  - `barrier_trap` – barriers that act like damage-dealing traps.
  - `volatile` – self-damage, risky payoffs, Bomber synergies.
  - `engine_core` – draw/energy/economy engines.

> **Implementation Note (future agent)**:  
> - Extend `CardDefinition` to store an `Array[String] tags` field (if not present) containing these tags.  
> - Prefer enums/constants for known tag names to avoid typos.

### 2.3 Player Stat Sheet

Define the **player-facing stats** that artifacts and wardens can modify:

- **Offense**
  - `gun_damage_percent` (default 100).
  - `hex_damage_percent` (default 100).
  - `barrier_damage_percent` (default 100).
  - `generic_damage_percent` (fallback for anything else).

- **Defense & Sustain**
  - `max_hp` (e.g. 70 for Veteran).
  - `armor_gain_percent` (scales armor card values).
  - `heal_power_percent` (scales HP gain).
  - `barrier_strength_percent` (duration/HP of barriers).

- **Economy / Tempo**
  - `energy_per_turn` (default 3).
  - `draw_per_turn` (default 5).
  - `hand_size_max` (default 7).
  - `scrap_gain_percent` (extra scrap from kills/rewards).
  - `shop_price_percent` (cheaper/more expensive shops).
  - `reroll_base_cost` (e.g. 5 scrap).

- **Ring Interaction**
  - `damage_vs_melee_percent`.
  - `damage_vs_close_percent`.
  - `damage_vs_mid_percent`.
  - `damage_vs_far_percent`.

> **Implementation Note (future agent)**:  
> - Extend `WardenDefinition` and/or `RunManager` to track these stats.  
> - Add derived/stat accessors (e.g. `get_gun_damage_multiplier()`) to avoid scattered math.

### 2.4 Phase 1 Implementation Checklist (for future LLM)

- [ ] Update `CardDefinition` to include a `tags: Array[String]`.
- [ ] Create a central `TagConstants.gd` (or similar) with canonical tag names.
- [ ] Extend `WardenDefinition` / `RunManager` with the stat fields above (with safe defaults).
- [ ] Add a **debug-only stat panel** to Combat UI (can be simple labels) showing:
  - Gun/Hex/Barrier damage %.
  - Max HP, Armor Gain %, Heal Power %.
  - Energy/Draw/Hand size, Scrap Gain %, Shop Price %.
  - Damage vs each ring %.
- [ ] No gameplay changes yet beyond reading from these stats where easy (e.g. use `gun_damage_percent` in gun damage calculations).

### 2.5 Phase 1 Test Plan

- In a dev build:
  - [ ] Confirm cards show expected tags in debug tooltips/logs.
  - [ ] Confirm the stat panel in Combat updates when you manually tweak a Warden’s starting stats.
  - [ ] Verify that changing `gun_damage_percent` in `RunManager` visibly affects gun card damage numbers.

---

## 3. Phase 2 – Veteran Warden (V2 Base Class)

### 3.1 Design Intent

Create a **neutral, Brotato-style baseline warden** that:
- Has **no strong built-in bias** toward any build.
- Uses the new **stat sheet** and **tag system**.
- Starts with a **small, flexible deck** that can pivot into multiple builds via shop choices.

### 3.2 Veteran Warden Spec (Design)

- **Name**: `Veteran Warden` (placeholder).
- **Fantasy**: Battle-hardened generalist; has seen every kind of horror, can adapt to any strategy.

**Base Stats** (all via the Phase 1 stat sheet):

- Max HP: 70
- Starting HP: 70
- Energy / turn: 3
- Cards drawn / turn: 5
- Max hand size: 7
- Base armor at wave start: 0
- Scrap gain: 100% (no modifier).
- Shop prices: 100% baseline.
- Reroll cost: 5 scrap.
- All damage and defense multipliers: 100% (neutral).
- Damage vs rings: 100% for all rings.

### 3.3 Veteran Starting Deck (Design)

Ten weak but flexible cards, touching guns, hex, barriers, defense, and control:

- 2x `Rusty Pistol`
  - Tags: `gun`, `instant`, `single_target`, `sniper`.
  - Effect: Deal 4 damage to a random enemy in Mid/Far.

- 1x `Minor Hex`
  - Tags: `hex`, `instant`, `single_target`, `hex_ritual`.
  - Effect: Apply 3 hex to a random enemy.

- 1x `Minor Barrier`
  - Tags: `barrier`, `instant`, `ring_control`, `barrier_trap`.
  - Effect: Place a barrier in a chosen ring that deals 3 damage when crossed and lasts for 1 crossing.

- 2x `Guard Stance`
  - Tags: `defense`, `instant`, `fortress`.
  - Effect: Gain 4 armor.

- 2x `Quick Draw`
  - Tags: `skill`, `instant`, `engine_core`.
  - Effect: Draw 1 card.

- 2x `Shove`
  - Tags: `skill`, `instant`, `ring_control`, `volatile`.
  - Effect: Push 1 enemy in Melee/Close back 1 ring; if they hit a barrier, they take 2 damage.

> **Implementation Note (future agent)**:  
> - Add a new WardenDefinition resource for Veteran.  
> - Hook it into the Warden Select scene (even if hidden initially behind a debug flag).

### 3.4 Phase 2 Implementation Checklist

- [ ] Create `Veteran Warden` as a new `WardenDefinition` with V2 stat fields populated.
- [ ] Populate the starting deck list with the 10 cards above (using their internal IDs).
- [ ] Wire Veteran into `WardenSelect.tscn` (optionally behind a hidden toggle/cheat button at first).
- [ ] Ensure `RunManager` initializes player stats from `WardenDefinition` (not hard-coded).

### 3.5 Phase 2 Test Plan

- [ ] Launch game, select Veteran, verify:
  - Starting HP/energy/draw/hand size match spec.
  - Starting deck contains only the 10 V2 cards.
  - Stat panel shows all 100%/neutral values.

---

## 4. Phase 3 – Core V2 Card Pool

### 4.1 Design Intent

Create a **small but expressive** shared card pool around Veteran that:
- Uses the new tag taxonomy.
- Already supports multiple builds:
  - Gun board (persistent weapons).
  - Hex/ritual.
  - Barrier/fortress.
  - Volatile push/control.
- Remains **numerically simple** so the complexity comes from tags + artifacts.

### 4.2 Minimal Core Card Set (Example, ~12 Cards)

> **Note**: Exact numbers are placeholders; future balancing passes will tune them.

**Persistent Weapons / Engines**

- `Infernal Pistol`
  - Tags: `gun`, `persistent`, `single_target`, `sniper`.
  - Effect: At end of your turn, deal 4 damage to a random enemy in Mid/Far.

- `Choirbreaker Shotgun`
  - Tags: `gun`, `persistent`, `shotgun`, `close_focus`, `swarm_clear`.
  - Effect: At end of your turn, deal 2 damage to up to 3 random enemies in Melee/Close.

- `Plague Turret`
  - Tags: `hex`, `engine`, `persistent`, `aoe`, `hex_ritual`.
  - Effect: At end of your turn, apply 2 hex to all enemies in a random ring.

- `Ring Ward`
  - Tags: `barrier`, `engine`, `persistent`, `ring_control`, `barrier_trap`, `fortress`.
  - Effect: Place a barrier in a chosen ring that deals 3 damage to enemies crossing it and can trigger 3 times.

**Instant Hex / Barrier**

- `Plague Cloud`
  - Tags: `hex`, `instant`, `aoe`, `swarm_clear`, `hex_ritual`.
  - Effect: Apply 2 hex to all enemies.

- `Withering Mark`
  - Tags: `hex`, `instant`, `single_target`, `sniper`, `hex_ritual`.
  - Effect: Apply 5 hex to a single enemy.

- `Barrier Sigil`
  - Tags: `barrier`, `instant`, `ring_control`, `barrier_trap`.
  - Effect: Place a barrier in a chosen ring that deals 4 damage and prevents enemies from moving this turn when they cross it.

**Defense / Sustain**

- `Glass Ward`
  - Tags: `defense`, `instant`, `fortress`.
  - Effect: Gain 5 armor.

- `Blood Shield`
  - Tags: `defense`, `instant`, `lifedrain`, `fortress`.
  - Effect: Gain 3 armor. This turn, heal 1 HP whenever you kill an enemy.

**Skills / Utility**

- `Ritual Focus`
  - Tags: `skill`, `instant`, `hex_ritual`, `engine_core`.
  - Effect: Lose 2 HP; the next hex card you play this turn has +50% hex.

- `Adrenal Surge`
  - Tags: `skill`, `instant`, `engine_core`.
  - Effect: Gain +1 energy and draw 1 card.

- `Repulsion Wave`
  - Tags: `skill`, `instant`, `ring_control`, `swarm_clear`, `volatile`.
  - Effect: Push all enemies in Melee/Close back 1 ring; enemies that cross a barrier take 2 damage.

### 4.3 Phase 3 Implementation Checklist

- [ ] Add these V2 example cards to CardDatabase as new definitions (it is fine to remove/retire old V1 cards on this branch).

### 4.4 Phase 3 Test Plan

- [ ] In a V2-only test mode:
  - Shops and rewards should only offer the new V2 cards.
  - Verify that each card’s behavior and targeting matches its description.
  - Check that gameplay text/UX shows tags in some form (tooltip, debug log, etc.).

### 4.5 Full Card Families and Cards (V2 Baseline)

The lists below expand the minimal examples into a full ~40-card pool for the Veteran Warden, organized by family.

#### 4.5.1 Gun Board Family – 10 Cards

**Theme**: Build a board of persistent guns that automatically clear the horde. Strong vs spread-out waves, wants to control Mid/Far and soften enemies before they reach Melee.

- **Infernal Pistol** – Cost 1  
  - Tags: `gun`, `persistent`, `single_target`, `sniper`  
  - Effect: At end of your turn, deal 4 damage to a random enemy in Mid/Far.

- **Choirbreaker Shotgun** – Cost 1  
  - Tags: `gun`, `persistent`, `shotgun`, `close_focus`, `swarm_clear`  
  - Effect: At end of your turn, deal 2 damage to up to 3 random enemies in Melee/Close.

- **Riftshard Rifle** – Cost 2  
  - Tags: `gun`, `instant`, `sniper`, `single_target`  
  - Effect: Deal 8 damage to a random enemy in Far. If it dies, apply 2 hex to another random enemy.

- **Scatter Volley** – Cost 1  
  - Tags: `gun`, `instant`, `shotgun`, `swarm_clear`  
  - Effect: Deal 2 damage to 4 random enemies.

- **Storm Carbine** – Cost 2  
  - Tags: `gun`, `persistent`, `single_target`, `mid_focus`  
  - Effect: At end of your turn, deal 3 damage to 2 random enemies in Close/Mid.

- **Overcharged Revolver** – Cost 1 (spicy)  
  - Tags: `gun`, `instant`, `volatile`, `single_target`  
  - Effect: Deal 6 damage to a random enemy. Lose 1 HP.

- **Suppressing Fire** – Cost 1  
  - Tags: `gun`, `instant`, `ring_control`, `mid_focus`  
  - Effect: Deal 3 damage to all enemies in Mid. Enemies hit move 1 ring slower next turn.

- **Twin Pistols** – Cost 1  
  - Tags: `gun`, `persistent`, `single_target`, `close_focus`  
  - Effect: At end of your turn, deal 2 damage to 2 random enemies in Melee/Close.

- **Salvo Drone** – Cost 2  
  - Tags: `gun`, `engine`, `persistent`, `aoe`  
  - Effect: At end of your turn, deal 3 damage to a random ring.

- **Ammo Cache** – Cost 1 (support)  
  - Tags: `skill`, `instant`, `engine_core`, `gun`  
  - Effect: Draw 2 cards. The next `gun` card you play this turn costs 1 less energy.

#### 4.5.2 Hex Ritualist Family – 10 Cards

**Theme**: Stack hex across the horde, trade HP/tempo for enormous delayed damage. Strong vs large waves, weaker vs fast, small elite fights unless properly set up.

- **Plague Cloud** – Cost 2  
  - Tags: `hex`, `instant`, `aoe`, `swarm_clear`, `hex_ritual`  
  - Effect: Apply 2 hex to all enemies.

- **Withering Mark** – Cost 1  
  - Tags: `hex`, `instant`, `single_target`, `sniper`, `hex_ritual`  
  - Effect: Apply 5 hex to a single enemy.

- **Plague Turret** – Cost 2  
  - Tags: `hex`, `engine`, `persistent`, `aoe`, `hex_ritual`  
  - Effect: At end of your turn, apply 2 hex to all enemies in a random ring.

- **Soul Brand** – Cost 1  
  - Tags: `hex`, `instant`, `single_target`, `hex_ritual`  
  - Effect: Apply 3 hex. If the target dies this turn, gain 2 armor.

- **Rotting Gale** – Cost 2  
  - Tags: `hex`, `instant`, `aoe`, `ring_control`, `hex_ritual`  
  - Effect: Apply 2 hex to all enemies in Close/Mid. Push Far enemies into Mid.

- **Ritual Focus** – Cost 0 (spicy)  
  - Tags: `skill`, `instant`, `hex_ritual`, `engine_core`  
  - Effect: Lose 2 HP; the next hex card you play this turn has +100% hex value.

- **Blood Sigil Bolt** – Cost 1  
  - Tags: `hex`, `instant`, `lifedrain`, `hex_ritual`  
  - Effect: Apply 3 hex to a random enemy. Heal 1 HP.

- **Cursed Miasma** – Cost 2  
  - Tags: `hex`, `instant`, `aoe`, `swarm_clear`  
  - Effect: Apply 1 hex to all enemies. Draw 1 card for every 3 hex stacks applied.

- **Doom Clock** – Cost 2 (engine)  
  - Tags: `hex`, `engine`, `persistent`, `hex_ritual`  
  - Effect: At end of your turn, increase hex on all hexed enemies by 1.

- **Last Rite** – Cost 2 (finisher, spicy)  
  - Tags: `hex`, `instant`, `single_target`, `volatile`, `hex_ritual`  
  - Effect: Choose a hexed enemy. Consume its hex and deal that much damage to all other enemies.

#### 4.5.3 Barrier Fortress / Traps Family – 10 Cards

**Theme**: Turn the rings into a minefield. Barriers deal damage and generate armor/hex; you win by making movement lethal. Strong when enemies must cross rings, weaker vs stationary/ranged threats unless supported.

- **Minor Barrier** – Cost 1  
  - Tags: `barrier`, `instant`, `ring_control`, `barrier_trap`  
  - Effect: Place a barrier in a chosen ring that deals 3 damage when crossed and lasts 1 crossing.

- **Ring Ward** – Cost 2  
  - Tags: `barrier`, `engine`, `persistent`, `ring_control`, `barrier_trap`, `fortress`  
  - Effect: Place a barrier in a chosen ring that deals 3 damage when crossed and can trigger 3 times.

- **Barrier Sigil** – Cost 1  
  - Tags: `barrier`, `instant`, `ring_control`, `barrier_trap`  
  - Effect: Place a barrier in a chosen ring that deals 4 damage and enemies that cross it do not move this turn.

- **Glass Ward** – Cost 1  
  - Tags: `defense`, `instant`, `fortress`  
  - Effect: Gain 5 armor.

- **Runic Rampart** – Cost 2  
  - Tags: `barrier`, `instant`, `fortress`  
  - Effect: Place a barrier in Melee and Close that each have 3 HP and deal 2 damage when crossed.

- **Reinforced Circle** – Cost 1  
  - Tags: `barrier`, `instant`, `fortress`  
  - Effect: Choose a ring. Existing barriers in that ring gain +2 HP/duration.

- **Ward Shock** – Cost 1  
  - Tags: `skill`, `instant`, `barrier_trap`, `ring_control`  
  - Effect: All enemies that crossed a barrier this turn take 2 damage.

- **Lockdown Field** – Cost 2 (spicy)  
  - Tags: `barrier`, `instant`, `ring_control`, `fortress`  
  - Effect: For this turn, enemies cannot move from Close into Melee. Place a barrier in Close.

- **Guardian Circle** – Cost 1  
  - Tags: `defense`, `instant`, `fortress`  
  - Effect: Gain 3 armor. If you control 3 or more barriers, gain 2 additional armor.

- **Repulsion Wave** – Cost 1  
  - Tags: `skill`, `instant`, `ring_control`, `swarm_clear`, `volatile`  
  - Effect: Push all enemies in Melee/Close back 1 ring; enemies that cross a barrier take 2 damage.

#### 4.5.4 Lifedrain Bruiser Family – 7 Cards

**Theme**: Trade damage and positioning for sustain. You want to be constantly healing and turning that sustain into armor/damage via artifacts. Plays well in Melee/Close, comfortable taking some hits.

- **Blood Shield** – Cost 1  
  - Tags: `defense`, `instant`, `lifedrain`, `fortress`  
  - Effect: Gain 3 armor. This turn, heal 1 HP whenever you kill an enemy.

- **Blood Bolt** – Cost 1  
  - Tags: `gun`, `instant`, `lifedrain`, `single_target`  
  - Effect: Deal 5 damage to a random enemy. Heal 2 HP.

- **Leeching Slash** – Cost 1  
  - Tags: `gun`, `instant`, `lifedrain`, `close_focus`  
  - Effect: Deal 4 damage to an enemy in Melee/Close. Heal 2 HP.

- **Crimson Guard** – Cost 1  
  - Tags: `defense`, `instant`, `lifedrain`  
  - Effect: Gain 4 armor. Heal 1 HP.

- **Sanguine Aura** – Cost 2 (engine)  
  - Tags: `engine`, `persistent`, `lifedrain`  
  - Effect: At end of your turn, heal 1 HP for each enemy killed this turn.

- **Martyr’s Vow** – Cost 0 (spicy)  
  - Tags: `skill`, `instant`, `lifedrain`, `volatile`  
  - Effect: Lose 3 HP. This turn, whenever you kill an enemy, heal 3 HP.

- **Vampiric Volley** – Cost 2  
  - Tags: `gun`, `instant`, `lifedrain`, `swarm_clear`  
  - Effect: Deal 3 damage to up to 3 random enemies. Heal 1 HP for each enemy hit.

#### 4.5.5 Overlap / Engine Cards – 5 Cards

These cards intentionally bridge families so builds can blend:

- **Hex-Tipped Rounds** – Cost 1  
  - Tags: `gun`, `instant`, `hex_ritual`, `sniper`  
  - Effect: Deal 3 damage to a random enemy. Apply 2 hex to it.

- **Barrier Leech** – Cost 1  
  - Tags: `barrier`, `instant`, `lifedrain`, `barrier_trap`  
  - Effect: Place a barrier that deals 2 damage when crossed. Heal 1 HP when it triggers.

- **Ritual Cartridge** – Cost 1  
  - Tags: `skill`, `instant`, `engine_core`, `gun`, `hex_ritual`  
  - Effect: The next `gun` and the next `hex` card you play this turn each cost 1 less energy.

- **Cursed Bulwark** – Cost 2  
  - Tags: `defense`, `instant`, `fortress`, `hex_ritual`  
  - Effect: Gain 6 armor. Apply 1 hex to all enemies in Melee.

- **Blood Ward Turret** – Cost 2  
  - Tags: `engine`, `persistent`, `lifedrain`, `barrier_trap`  
  - Effect: At end of your turn, deal 2 damage to a random enemy in Melee/Close and heal 1 HP.

### 4.6 Phase 3 Implementation Checklist (Updated)

- [ ] Add all V2 cards above to `CardDatabase` as new definitions (it is fine to remove/retire old V1 cards on this branch).
- [ ] Ensure each card has all relevant tags in its definition.
- [ ] Provide a simple way (dev-only is fine) to restrict shops/rewards to **V2 cards only** while testing.

### 4.7 Phase 3 Test Plan (Updated)

- [ ] In a V2-only test mode:
  - Shops and rewards should only offer V2 cards.
  - Verify that each card’s behavior and targeting matches its description.
  - Check that gameplay text/UX shows tags in some form (tooltip, debug log, etc.).
  - Confirm that each family has enough low-rarity cards to form a recognizable build by wave 3–4.

---

## 5. Phase 4 – V2 Artifact / Item System

### 5.1 Design Intent

Reorient artifacts toward **Brotato-style items**:
- Small, stackable stat and tag boosts.
- Clear tradeoffs (+X for tag, -Y for something else).
- A second layer of artifacts that **convert “side stats” (heal, armor, barrier triggers, hex ticks)** back into **damage or economy**.

### 5.2 Core Stat Artifacts (Tag-Agnostic)

These are mostly pure or mild-upside items that shape stats.

- **Sharpened Rounds** (common, stackable)  
  - Effect: `Gun damage +10%.`

- **Hex Lens** (common, stackable)  
  - Effect: `Hex damage +10%.`

- **Reinforced Plating** (common, stackable)  
  - Effect: `Armor gained +15%.`

- **Barrier Alloy** (common, stackable)  
  - Effect: `Barriers have +20% HP/duration.`

- **Tactical Pack** (uncommon, non-stackable)  
  - Effect: `Draw +1 card per turn.`

- **Surge Capacitor** (uncommon, non-stackable)  
  - Effect: `Energy per turn +1.`

- **Glass Core** (uncommon, stackable)  
  - Effect: `Gun damage +20%. Max HP -5%.`

- **Runic Plating** (uncommon, stackable)  
  - Effect: `Armor gained +25%. Heal power -10%.`

- **Forward Bastion** (uncommon)  
  - Effect: `Damage vs enemies in Melee/Close +15%. Damage vs Mid/Far -10%.`

### 5.3 Family Artifacts – Lifedrain

- **Leech Core** (common, stackable)  
  - Effect: `lifedrain cards heal +1 HP.`

- **Sanguine Reservoir** (uncommon)  
  - Effect: `Max HP +10. Heal power -10%.`

- **Hemorrhage Engine** (rare, non-stackable)  
  - Effect: `Whenever you heal HP, deal that much damage split among random enemies in Melee/Close.`

- **Red Aegis** (uncommon)  
  - Effect: `When you heal while at full HP, gain 2 armor instead.`

### 5.4 Family Artifacts – Hex Ritual

- **Occult Focus** (common, stackable)  
  - Effect: `hex_ritual cards apply +1 additional hex.`

- **Blood Pact** (uncommon)  
  - Effect: `At the start of each wave, lose 3 HP and gain +1% hex damage per wave completed.`

- **Creeping Doom** (rare, non-stackable)  
  - Effect: `When hex is consumed on an enemy, apply 1 hex to all other enemies in that ring.`

- **Ritual Anchor** (uncommon)  
  - Effect: `When you play a hex_ritual card, gain 1 armor.`

### 5.5 Family Artifacts – Barrier Trap / Fortress

- **Trap Engineer** (common, stackable)  
  - Effect: `Barriers with barrier_trap deal +2 damage.`

- **Runic Bastion** (uncommon)  
  - Effect: `Barriers with fortress grant 1 armor when they trigger (once per enemy per turn).`

- **Punishing Walls** (rare, non-stackable)  
  - Effect: `Whenever a barrier deals damage, apply 1 hex to that enemy.`

- **Nested Circles** (uncommon)  
  - Effect: `Start each wave with a Minor Barrier in Close.`

### 5.6 Family Artifacts – Volatile / Push

- **Kinetic Harness** (common)  
  - Effect: `When you push an enemy, deal 1 damage to it.`

- **Shock Collars** (uncommon)  
  - Effect: `Enemies that move from Mid to Close take 1 damage.`

- **Last Stand Protocol** (rare, non-stackable)  
  - Effect: `At the start of your turn, if there are 3 or more enemies in Melee, gain +1 energy and 3 armor.`

- **Overloader** (uncommon)  
  - Effect: `Your volatile cards deal +2 damage. At the end of each wave, lose 3 HP.`

### 5.7 Phase 4 Implementation Checklist

- [ ] Add new artifacts to `ArtifactDefinition` / `ArtifactManager`.
- [ ] Ensure each artifact:
  - References tags (e.g. checks `card.tags`) instead of specific card IDs where possible.
  - Applies its effects by modifying the appropriate stats or hooking into existing signals (on_card_play, on_hex_consumed, on_barrier_trigger, etc.).
- [ ] Allow duplicates where intended (and mark key rares as non-stackable).

### 5.8 Phase 4 Test Plan

- [ ] In a dev run, spawn specific artifacts via debug:
  - Stack multiple `Sharpened Rounds`, confirm gun damage scales.
  - Stack `Leech Core`, check `lifedrain` heals increase and non-lifedrain gun damage decreases.
  - Equip `Hemorrhage Engine`, `Blood Shield`, verify heals cause extra damage.
  - Equip `Creeping Doom`, confirm hex spreads when consumed.
  - Equip `Trap Engineer` + `Punishing Walls`, confirm barriers deal extra damage and apply hex on hit.

---

## 6. Phase 5 – Shop & Reward Rework

### 6.1 Design Intent

Make the **shop the primary build driver**, echoing Brotato:
- Early waves should **very aggressively push you into a lane** via repeated offers in 1–2 families.
- Rerolls are cheap enough that you can *fish* for the line you want.
- Duplicates and stackable items are common, so committing feels powerful.

### 6.2 Shop Structure (V2 Mode)

Per wave, when you open the shop:
- **4 cards** from the V2 card pool.
- **3 artifacts/items** (stat and family items).
- **2 services** (heal, remove card, etc.).

**Rerolls:**
- Base cost: 3 scrap.
- Scaling: `reroll_cost = 3 + floor((wave - 1) / 3)`.

### 6.3 Family Biasing Logic

**Families**: At minimum, treat these as families for weighting: `gun`, `hex_ritual`, `barrier` (barrier_trap/fortress), `lifedrain`, plus a `neutral` bucket for generic/stat items.

At runtime, track:
- `owned_family_counts[family]`: how many cards + artifacts with that family tag the player owns.

#### Step 1 – Determine Current Lean

- Compute `score[family] = owned_family_counts[family]`.
- `primary_family` = family with highest `score` (ties broken arbitrarily).
- `secondary_family` = second-highest, or `null` if all scores are 0.

#### Step 2 – Early-Wave Strong Push (Waves 1–3)

For **waves 1–3**:

- **Cards**:
  - 70% of shops: pick a random `focus_family` from `[gun, hex_ritual, barrier, lifedrain]` (ignore owned counts).
    - Slot 1–2: must be from `focus_family` (if pool has enough cards).
    - Slot 3: 50% `focus_family`, 50% any other family.
    - Slot 4: unbiased random from all families.
  - 30% of shops: no explicit focus (all card slots drawn uniformly from all families).

- **Items**:
  - 60% of shops: ensure at least one item from the same `focus_family` as cards (if such items exist).
  - Otherwise: items drawn uniformly from all families.

This makes it very common to see **2+ offers from the same family** in the first few shops.

#### Step 3 – Mid/Late-Wave Adaptive Push (Waves 4+)

For **waves 4+**, bias offers based on what the player already owns:

- Define base weights:
  - `base_weight[family] = 1.0` for all families (including neutral).
  - If `primary_family` exists: `base_weight[primary_family] += 2.0`.
  - If `secondary_family` exists: `base_weight[secondary_family] += 1.0`.
  - Normalize weights per draw so they sum to 1.

- **Cards (4 slots)**:
  - For each slot, sample a family using `base_weight[family]`, then pick a random card from that family not already shown.
  - If `owned_family_counts[primary_family] >= 2`, enforce that **at least 2 of 4** card slots are from `primary_family` (resample the last slot if needed).

- **Items (3 slots)**:
  - Same family weighting; no hard guarantees, but in practice the player should see more items from their primary/secondary families.

### 6.4 Reward Nodes

After each wave, offer **3 reward choices**:
- 2 card slots.
- 1 flex slot (card or item).

Flex slot behavior:
- Waves 1–3: 70% chance to be an item, 30% card.
- Waves 4+: 50% item, 50% card.

Family weighting:
- Use the same `base_weight[family]` as in the shop.
- Guarantee: if `owned_family_counts[primary_family] >= 2`, at least **1 of 3** rewards comes from `primary_family`.

### 6.5 Services

Examples (numbers can be tuned later):

- **Heal**  
  - Effect: Restore 30% of missing HP.  
  - Cost: `10 + 2 * wave` scrap.

- **Remove Card**  
  - Effect: Remove a chosen card from your deck.  
  - Cost: `10 + 3 * wave` scrap.

- Optional third service (future): card upgrade, scrap-for-HP trade, etc.

Services ignore family weighting and are always present.

### 6.6 Phase 5 Implementation Checklist

- [ ] Implement the shop generator with the structure and weighting rules above.
- [ ] Ensure shops and rewards draw only from V2 card and artifact pools.
- [ ] Surface card tags in the shop UI (even minimal, e.g. a small text row: `Tags: gun, shotgun, aoe`).
- [ ] Implement reroll cost scaling by wave and verify it updates correctly.

### 6.7 Phase 5 Test Plan

- [ ] Start several runs as Veteran; by wave 3, verify:
  - It is easy to commit into at least one of: gun, hex, barrier, lifedrain builds.
  - Shops frequently show 2+ offers from the same family in early waves.
  - Rerolls feel impactful (you can reasonably hunt for your family).
- [ ] By waves 4–6, confirm that:
  - Shops and rewards noticeably favor your primary/secondary families.
  - Off-lane options still appear often enough to pivot or splash.

## 7. Phase 6 – Balance & Content Expansion

### 7.1 Design Intent

Once Phases 1–5 are implemented end-to-end, focus on:
- Ensuring **multiple builds are truly viable** on Veteran (not just theoretically possible).
- Expanding/tuning the V2 card and artifact pool where needed to support those builds.
- Tightening numbers so runs feel fair but lethal, with strong build identity.

### 7.2 Target Build Families (Initial)

At minimum, the following builds should be **fully viable** on Veteran:

- **Gun Board**
  - Core: persistent `gun` weapons (`shotgun` / `sniper`), with some instant gun support.
  - Support: `Sharpened Rounds`-style damage items, generic draw/energy, possibly some `volatile` push.

- **Hex Ritualist**
  - Core: `hex` + `hex_ritual` cards (e.g. Plague Turret, Plague Cloud, Withering Mark, Ritual Focus variants).
  - Support: `Occult Focus`, `Creeping Doom`, HP-sacrificing scaling items.

- **Barrier Fortress / Traps**
  - Core: `barrier`, `barrier_trap`, `fortress` cards (Ring Ward, Barrier Sigil-line, armor cards).
  - Support: `Trap Engineer`, `Runic Bastion`, `Punishing Walls`, generic armor scaling.

- **Lifedrain Bruiser**
  - Core: `lifedrain`-tagged defense/weapon cards (Blood Shield-line, lifesteal guns, sustain engines).
  - Support: `Leech Core`, `Hemorrhage Engine`, HP/armor scaling items.

Intentional **overlaps are allowed** (e.g. a `lifedrain` gun that also has `hex_ritual`), but each family should have at least a few cards and items that clearly reward committing to that line.

### 7.3 Phase 6 Implementation Checklist

- [ ] Playtest and adjust numbers on:
  - Veteran’s base stats (HP, energy, draw) for appropriate difficulty.
  - Card base values (damage, hex, armor, etc.) for each family.
  - Artifact tradeoffs so choices feel meaningful (no obvious must-picks).
- [ ] Add/remix cards or artifacts if a target build family feels under-supported.
- [ ] Document tuned numbers in this file so future agents know the intended baseline.

### 7.4 Phase 6 Test Plan

- [ ] For each target build family:
  - Play multiple runs deliberately forcing that line in shops/rewards.
  - Confirm it can reasonably defeat the full run with good, but not perfect, tactical play.
  - Verify that early shops **strongly push** you into that line if you start buying its pieces.

---

## 8. Phase 7+ – Future Extreme Wardens (Outline Only)

Once V2 systems are stable, design new wardens that:
- Share the same **card pool**.
- Have **extreme stat packages and passive rules** that make otherwise fringe builds viable:

Examples (conceptual, not final spec):

- **The Plaguer**
  - Massive buffs to `hex_ritual` and hex damage, huge penalties to guns.
  - Hex stacks don’t get consumed but deal damage each turn.

- **The Architect**
  - Starts each wave with free barriers in each ring.
  - Severely reduced draw/energy, forcing a barrier/trap-centric playstyle.

- **The Sanguine**
  - Cannot gain armor; heals are doubled and deal damage to enemies.
  - Naturally suited for `lifedrain` families.

These will get their own section once we have the base V2 loop feeling good.

---

## 9. Notes for Future Implementers

- This document assumes V2 fully replaces V1 on this branch; there is no need to preserve Classic Mode unless reintroduced later.
- Card text should be **simple in the majority of cases** (single-effect, Brotato-style), with a minority of “spicier” cards in families like `hex_ritual`, `lifedrain`, and `volatile` to create depth.
- Shops should **heavily cluster** offers in 1–2 families in early waves so players naturally get pushed into clear builds, while still leaving some room for off-lane picks and overlaps.
- When in doubt, favor:
  - More power in **stats/tags/items/wardens**.
  - Less complexity in individual card rules.
  - Strong, flavorful tradeoffs (+X for a tag, -Y elsewhere).

---

## 10. Enemies & Waves – V2 Design

### 10.1 Goals

- Enemies should **stress different builds in different ways**:
  - Some waves are ideal for Gun Board but dangerous for Hex, and vice versa.
  - No single build family is “best at everything”.
- Preserve the **ring movement fantasy**:
  - Rushers that crash into Melee quickly.
  - Ranged anchors that sit at Mid/Far.
  - Special enemies that interact with hex, barriers, and lifedrain in interesting ways.
- Reuse existing enemy flavors (Husk, Spitter, Bomber, etc.) but retune them for V2 builds and pacing.

### 10.2 Archetype Summary

Enemy archetypes and which build families they primarily test:

- **Rusher** – Fast melee threats that punish slow setups, good food for Lifedrain.
- **Fast Rusher** – Very fast, low-HP enemies that reward Gun Board, punish greedy Hex.
- **Ranged Anchor** – Enemies that stop at Mid/Close and shoot, counter pure barrier-only setups.
- **Tank** – High-HP, often armored enemies that reward Hex and multi-hit Barrier builds.
- **Bomber** – On-death AoE that can hurt you and other enemies; great for Volatile/Barrier plays.
- **Buffer** – Low-HP supports that amp nearby enemies; priority targets for all builds.
- **Spawner** – Units that generate new enemies each turn until killed; great for sustain/engines if controlled.
- **Ambusher** – Enemies that appear in Close/Melee, punishing decks with no emergency tools.
- **Armor Shredder** – Enemies that attack armor/barriers more efficiently than HP; natural counter-pressure to Fortress builds.
- **Boss** – Multi-ability encounters that all four build families must be able to solve via different lines.

### 10.3 Concrete Enemy Designs (First Pass)

Numbers are tuning baselines and can be adjusted during Phase 6.

#### 10.3.1 Husk – Basic Rusher

- **Archetype**: Rusher  
- **Rings**: Spawns in Far, moves 1 ring per turn toward Melee.  
- **Stats**:
  - HP: 8
  - Damage: 4
  - Speed: 1 ring/turn
  - Armor: 0
- **Behavior**:
  - Moves inward each enemy phase until Melee, then attacks the player.
- **Build Interactions**:
  - Easy targets for **Gun Board** and **Lifedrain** (lots of kills, heal triggers).
  - Hex can stack them but may be overkill; good early hex fodder.
  - Barriers are strong if placed early so they cross multiple times.

#### 10.3.2 Spinecrawler – Fast Rusher

- **Archetype**: Fast Rusher  
- **Rings**: Spawns in Far, moves 2 rings/turn.  
- **Stats**:
  - HP: 6
  - Damage: 3
  - Speed: 2 rings/turn
  - Armor: 0
- **Behavior**:
  - Moves 2 rings per enemy phase (Far → Mid → Close → Melee).
  - Attacks immediately when in Melee.
- **Build Interactions**:
  - Punishes **slow Hex** and greedy builds that don’t pack early interaction.
  - Very good test for **Gun Board** – your persistent weapons should ideally pick them off.
  - Barrier builds must have at least one barrier online early to tag them.

#### 10.3.3 Cultist Swarm – Weak Rusher

- **Archetype**: Rusher (Swarm)  
- **Rings**: Spawns in Mid/Close in small groups.  
- **Stats**:
  - HP: 4
  - Damage: 2
  - Speed: 1 ring/turn
  - Armor: 0
- **Behavior**:
  - Moves 1 ring per turn toward Melee.
  - Often spawns 3–5 at a time.
- **Build Interactions**:
  - Great for **swarm_clear** weapons and AOE Hex (Plague Cloud, Scatter Volley).
  - Excellent sustain for **Lifedrain** (many small kills, many small heals).
  - Encourages barrier setups that punish multiple crossings.

#### 10.3.4 Spitter – Ranged Anchor

- **Archetype**: Ranged Anchor  
- **Rings**: Spawns in Far, moves inward until Mid, then stops.  
- **Stats**:
  - HP: 7
  - Damage: 3
  - Speed: 1 ring/turn
  - Armor: 0
- **Behavior**:
  - Moves toward Mid; once in Mid, stops moving and performs ranged attacks each turn.
  - If forced out of Mid (e.g. pushed), will try to return to Mid.
- **Build Interactions**:
  - Counters pure **Barrier Fortress** if you only rely on crossings in Melee/Close.
  - Hex loves them as long-lived hex stacks.
  - Gun Board must include some `sniper` or `mid_focus` tools (Riftshard Rifle, Suppressing Fire).

#### 10.3.5 Shell Titan – Tank

- **Archetype**: Tank  
- **Rings**: Spawns in Far, moves 1 ring/turn.  
- **Stats**:
  - HP: 22
  - Armor: 3
  - Damage: 8
  - Speed: 1 ring/turn
- **Behavior**:
  - Slow, inevitable threat; high HP + armor.
  - No special abilities; just hits very hard if it reaches Melee.
- **Build Interactions**:
  - Relatively bad for pure **flat-damage Guns** without scaling items.
  - Perfect target for **Hex** builds (Doom Clock, Last Rite).
  - Barrier builds want to force multiple crossings (Ring Ward, Runic Rampart).
  - Lifedrain can chip at it, converting chip damage into sustain if you have Hemorrhage Engine.

#### 10.3.6 Bomber – Volatile Exploder

- **Archetype**: Bomber  
- **Rings**: Spawns in Mid/Close.  
- **Stats**:
  - HP: 9
  - Damage: 0 (direct)
  - Explosion: 6 damage to player and 4 damage to all other enemies in its ring
  - Speed: 1 ring/turn
- **Behavior**:
  - Moves inward; on death, explodes.
  - Explosion damages player and all enemies in the same ring.
- **Build Interactions**:
  - **Volatile/Barrier** builds can push Bombers into dense rings or into barriers before popping them.
  - Hex builds can stack hex on Bombers and then use their death for wave-clearing.
  - Lifedrain can afford to eat a controlled number of explosions and heal back.

#### 10.3.7 Torchbearer – Buffer

- **Archetype**: Buffer  
- **Rings**: Spawns in Far, stops at Close.  
- **Stats**:
  - HP: 10
  - Damage: 2
  - Speed: 1 ring/turn
- **Behavior**:
  - When in Close, each turn grants +2 damage to all adjacent enemies until it is killed.
  - If no adjacent enemies, it attacks the player instead.
- **Build Interactions**:
  - Priority target for **all** builds.
  - Hex/Barrier/Gun all have ways to reach it; failure to do so makes waves much more dangerous.
  - Lifedrain enjoys killing it for sustain but must respect buffed enemies.

#### 10.3.8 Channeler – Spawner

- **Archetype**: Spawner  
- **Rings**: Spawns in Far, stops at Close.  
- **Stats**:
  - HP: 12
  - Damage: 3
  - Speed: 1 ring/turn
- **Behavior**:
  - When at Close, each enemy phase spawns 1 Husk in Far, up to a cap of 3 active spawns at a time.
  - If stunned or silenced (future status), skips spawning that turn.
- **Build Interactions**:
  - If left alone, overwhelms slower builds with extra bodies.
  - Great for **Lifedrain** and **Hex** late, once your engine is online (infinite fodder).
  - Barrier builds can lean into spawns by farming barrier crossings.

#### 10.3.9 Stalker – Ambusher

- **Archetype**: Ambusher  
- **Rings**: Spawns directly in Close (or occasionally Melee) with an intent to strike quickly.  
- **Stats**:
  - HP: 9
  - Damage: 6
  - Speed: 1 ring/turn
- **Behavior**:
  - Appears in Close, moves to Melee next turn if not controlled, then attacks.
  - Sometimes spawns in Melee in later waves as a spike.
- **Build Interactions**:
  - Punishes **greedy Hex-only** or slow Barrier builds with no emergency removal.
  - Strong moment for Repulsion Wave, Overcharged Revolver, Leeching Slash, etc.
  - Lifedrain can take hits but must be careful not to get overwhelmed.

#### 10.3.10 Armor Reaver – Armor Shredder

- **Archetype**: Armor Shredder  
- **Rings**: Spawns in Mid, moves 1 ring/turn.  
- **Stats**:
  - HP: 10
  - Damage: 3 (plus extra armor/barrier damage)
  - Speed: 1 ring/turn
- **Behavior**:
  - Attacks: Deals 3 HP damage and removes an additional 3 armor from the player (ignoring barrier HP).
  - When crossing a barrier, deals +1 extra damage to that barrier.
- **Build Interactions**:
  - Natural counter-pressure to **Fortress/Barrier** builds that rely heavily on armor and long-lived walls.
  - Guns and Hex should prioritize it to avoid losing defensive layers.
  - Lifedrain builds are less impacted but still dislike the extra barrier damage.

#### 10.3.11 Ember Saint – Boss

- **Archetype**: Boss  
- **Rings**: Spawns in Far, typically stays at Far or Mid.  
- **Stats**:
  - HP: 60
  - Armor: 4
  - Damage: 10 (aoe patterns)
  - Speed: 0–1 ring/turn (primarily ranged)
- **Behavior**:
  - Every turn:
    - Either performs a large AoE attack (e.g. hit all enemies in a ring, or hit player) or
    - Spawns 1 Bomber in Far and 1 Husk in Mid.
  - Occasionally pulls all enemies 1 ring inward or pushes them outward (ring manipulation).
- **Build Interactions**:
  - **Gun Board**: Needs sustained DPS from persistent guns plus control tools to clean up Bombers.
  - **Hex Ritualist**: Stacks huge hex via Plague Turret, Doom Clock, then finishes with Last Rite.
  - **Barrier Fortress**: Uses repeated Bomber/Husk crossings with Punishing Walls and Trap Engineer to grind boss HP and adds.
  - **Lifedrain**: Survives chip damage, converts healing (Hemorrhage Engine, Red Aegis) into damage, and stays alive through long fights.

### 10.4 Wave Bands & Composition Guidelines

Define four wave bands and how they should feel:

- **Waves 1–3: Onboarding & Early Commit**
  - Composition:
    - Mostly Husks and Cultist Swarms.
    - Occasional Spitter or a single Bomber by wave 3.
  - Goals:
    - Teach ring movement and basic targeting.
    - Allow shops to strongly push into a family without punishing “wrong” choices yet.

- **Waves 4–6: Build Check 1**
  - Composition:
    - Introduce Spinecrawlers (Fast Rushers).
    - More frequent Spitters, first Torchbearer or Channeler appearances.
  - Goals:
    - Check that Gun Board can kill fast movers consistently.
    - Check that Hex builds can stabilize against growing waves.
    - Check that Barrier builds can get traps online in time.
    - Check that Lifedrain has some damage, not just sustain.

- **Waves 7–9: Stress Mix & Counter-Waves**
  - Composition:
    - Regular Tanks (Shell Titans), Bombers, Buffers, Spawners, Ambushers, Armor Reavers.
    - Include “theme waves” such as:
      - Bomber-heavy wave (great for Barrier/Volatile, scary for low-HP Glass builds).
      - Ranged-heavy wave (Spitters + Buffers) that counters pure barrier.
      - Tank corridor (Shell Titans + Torchbearers) that tests Hex and Barrier scaling.
  - Goals:
    - Ensure each build has **good** and **bad** matchups across waves.
    - Emphasize that some waves require tactical play even with a strong build.

- **Waves 10–12: Boss & Pre-Boss**
  - Composition:
    - Pre-boss: concentrated archetypes (e.g. “Last Stand” with lots of Ambushers and Armor Reavers).
    - Final wave: Ember Saint boss + supporting spawns.
  - Goals:
    - Let each build **show off its core pattern** in the boss fight, while still needing some tactical adaptation.

### 10.5 Phase 8 Implementation Checklist

- [ ] For each existing enemy in `EnemyDatabase`, map it to one of the archetypes above and retune HP/damage/speed/armor to match these specs.
- [ ] Add any missing enemies (e.g. Armor Reaver variant) as new `EnemyDefinition` resources.
- [ ] Update `WaveDefinition` generation logic to:
  - Use wave bands (1–3, 4–6, 7–9, 10–12).
  - Define spawn weight tables for each archetype per band.
  - Include a few explicit “theme waves” per band (Bomber storm, Ranged wall, Tank corridor, etc.).
- [ ] Ensure intent UI (badges, telegraphs) clearly indicates each enemy’s role and threat.

### 10.6 Phase 8 Test Plan

- [ ] Play multiple full runs with each build family (Gun Board, Hex Ritualist, Barrier Fortress, Lifedrain Bruiser):
  - Confirm that each has:
    - Waves where it feels very strong.
    - Waves where it feels pressured but still viable with good play.
  - Verify that no build trivially breezes through all waves without adaptation.
- [ ] Adjust enemy counts, HP, and special abilities based on early balance impressions and notes in this document.


## 11. Future Open Questions

These are intentionally left for later tuning once the first V2 implementation is playable:

- **Rarity & Drop Rates**
  - Exact counts of common/uncommon/rare cards per family.
  - How rarity affects shop and reward probabilities.
  - Whether some families (e.g. Hex Ritual, Barrier Fortress) should have more rares vs commons.

- **Merge / Tier System in V2**
  - How triple-merge interacts with stat-scaling items and wardens.
  - Whether certain families (e.g. Gun Board) should lean more heavily on merges than others.
  - How merged cards scale numerically relative to artifact stat boosts.

- **Difficulty Curve Targets**
  - Target average run length and expected loss rate (especially mid-waves vs boss).
  - Per-wave HP/damage scaling guidelines for enemies by band (1–3, 4–6, 7–9, 10–12).
  - How much variance we want between “easy” and “spike” waves.

- **Meta-Progression**
  - How unlocks (if any) should interact with families, items, and wardens.
  - Whether meta progression should bias toward “more content” (new cards/items) or “small starting boosts.”

These should be revisited after initial V2 implementation and playtesting.
