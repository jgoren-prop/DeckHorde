# Brotato-Style Economy Brainstorm

## The Vision

Shift from "start with a deck, add cards" to **"start with nothing, build everything through the shop."**

Brotato's magic:
1. **Wave 1 is trivially easy** - just survive and collect
2. **Start with 1 weapon** - gives immediate agency and synergy direction
3. **Interest system** - saving money is rewarded, creates meaningful tension between buying now vs. banking
4. **Build identity emerges from choices**, not character selection

---

## Core Changes to Make

### 1. Starter Weapon Selection (Pre-Run)

Instead of starting with a 10-card deck, player picks **1 starting weapon** from a selection of ~7 options:

| Weapon | Cost | Tags | Effect | Synergy Direction |
|--------|------|------|--------|-------------------|
| Rusty Pistol | 1 | gun, persistent, single_target | End of turn: deal 3 damage to random enemy | Generic gun scaling |
| Worn Hex Staff | 1 | hex, persistent, hex_ritual | End of turn: apply 2 hex to random enemy | Hex/ritual builds |
| Cracked Barrier Gem | 1 | barrier, persistent, barrier_trap | End of turn: place 1-damage barrier in random ring | Fortress/trap builds |
| Leaky Siphon | 1 | gun, persistent, lifedrain | End of turn: deal 2 damage, heal 1 HP | Lifedrain sustain |
| Volatile Handgun | 1 | gun, persistent, volatile | End of turn: deal 4 damage, lose 1 HP | High-risk/high-reward |
| Mini Turret | 1 | gun, engine, persistent, aoe | End of turn: deal 1 damage to 2 random enemies | Engine/board builds |
| Barrier Mine Layer | 1 | barrier, engine, persistent, barrier_trap | End of turn: 20% chance to place a 2-damage barrier | Passive trap generation |

**All are weak** - barely enough to clear Wave 1 - but telegraph different synergy paths.

### 2. Starting Resources

**Instead of:**
- 10 cards
- 3 energy/turn
- 5 draw/turn
- 0 scrap

**Start with:**
- **1 card** (the chosen weapon)
- **1 energy/turn** (enough to play your 1 weapon)
- **1 draw/turn** (you always draw your 1 card)
- **0 scrap**
- **50 HP** (lower stakes early, scales with upgrades)

### 3. Wave Count Discussion

**Current game:** 12 waves
**Brotato:** 20 waves

With a Brotato economy, more waves = more value:
- More shop visits for build development
- Interest has time to compound
- Power curve can be smoother (not rushing to "online" by wave 3)
- Each individual wave lower stakes

**Possible wave structures:**

| Waves | Pros | Cons |
|-------|------|------|
| 12 (current) | Faster runs (~15 min?) | Feels rushed with 1-weapon start |
| 16 | Middle ground | Might be awkward pacing |
| 20 (Brotato) | Full economy experience, ~25 min runs | Could feel grindy if content is thin |

**Recommendation:** Try 20 waves but with faster individual waves. Brotato waves are ~30-60 seconds. If our combat drags, trim enemy counts rather than wave count.

### 4. Resource Scaling Per Wave

Energy and draw scale up as the run progresses (assuming 20 waves):

| Wave | Energy/Turn | Draw/Turn | Notes |
|------|-------------|-----------|-------|
| 1-2 | 1 | 1 | Tutorial phase |
| 3-5 | 1 | 2 | Early build |
| 6-8 | 2 | 3 | Build taking shape |
| 9-12 | 2 | 4 | Mid-game |
| 13-16 | 3 | 5 | Late-game |
| 17-20 | 3 | 5 | Final stretch |

**Alternative: Buy-Your-Stats**
Keep energy/draw static at 1/1, but let players buy upgrades:
- +1 Energy: 50 scrap (can buy multiple)
- +1 Draw: 40 scrap (can buy multiple)

This makes resource scaling a **choice** rather than automatic. More Brotato-authentic.

---

## Buy-Your-Stats Deep Dive

### Approach A: Brotato Direct (Stats Mixed in Shop)

Stats appear **mixed with weapons and items** in the same shop pool. RNG determines which stats show up.

| Stat | Price | Effect | Stackable? |
|------|-------|--------|------------|
| +1 Max Energy | 60 | Energy per turn +1 | Yes (cap 5) |
| +1 Draw | 50 | Cards drawn per turn +1 | Yes (cap 7) |
| +10 Max HP | 25 | Increase max HP | Yes |
| +5% Gun Damage | 20 | All gun damage +5% | Yes |
| +5% Hex Damage | 20 | All hex damage +5% | Yes |
| +10% Armor Gain | 15 | Armor from cards +10% | Yes |
| +1 Weapon Slot | 80 | Deploy 1 more weapon | Yes (cap 8) |
| +10% Scrap Gain | 30 | More scrap from kills | Yes |
| -5% Shop Prices | 40 | Everything cheaper | Yes (cap -30%) |

**Pros:** Simple, proven (it's Brotato), variety every shop
**Cons:** RNG on which stats appear, shop gets crowded

---

### Approach B: Dedicated Upgrade Tab

Shop has **two tabs**: Weapons/Items and Upgrades.

Upgrades tab shows **all stats always available**, prices scale with purchases:

| Upgrade | 1st | 2nd | 3rd | 4th | 5th |
|---------|-----|-----|-----|-----|-----|
| Energy +1 | 40 | 60 | 90 | 130 | 180 |
| Draw +1 | 35 | 50 | 75 | 110 | 150 |
| Max HP +10 | 20 | 25 | 30 | 35 | 40 |
| Damage +5% | 25 | 35 | 50 | 70 | 95 |
| Weapon Slots +1 | 60 | 100 | 150 | 220 | -- |

**Pros:** No RNG, always know what's available, clear progression
**Cons:** Less exciting (same every time), two tabs = more UI

---

### Approach C: Stat Crates (Bundled Random)

After each wave, offered **1 upgrade crate** with 2-3 themed stats:

- "Scavenger Crate" (40 scrap): +5% Scrap, +5 Max HP, +1 Draw
- "Assault Crate" (50 scrap): +10% Gun Damage, +5% vs Melee
- "Ritualist Crate" (45 scrap): +10% Hex Damage, +5 Max HP
- "Fortress Crate" (45 scrap): +15% Armor, +10 Max HP
- "Tempo Crate" (55 scrap): +1 Energy, +1 Draw

One crate offered per wave (random), alongside normal shop.

**Pros:** Simple decision (buy crate or not), themed synergies
**Cons:** Less control over specific stats, feels random

---

### Approach D: Passive Stat Growth + Choice Points

Stats grow **automatically** in small increments, but you get **choice points** at milestones:

**Auto-growth:** Every 3 waves: +5 Max HP, +2% all damage
**Choice points:** Waves 5, 10, 15, 20 - pick one major upgrade:
- +1 Energy
- +2 Draw  
- +1 Weapon Slot
- +15% damage type of choice
- +30 Max HP

**Pros:** Guaranteed progression, meaningful big choices
**Cons:** Less Brotato, more "level up" RPG feel

---

### Approach E: Investment Pools

**Invest** scrap into stat pools. Investments grow 10% per wave. Cash out anytime.

Example:
- Wave 3: Invest 30 scrap into "Damage Pool"
- Wave 8: Pool has grown to ~48 value
- Cash out: Get +24% damage (2 scrap value = +1%)

Can have multiple pools growing simultaneously.

**Pros:** Interesting long-term planning, rewards patience
**Cons:** Complex, math-heavy, UI challenge

---

### Approach F: Upgrade Artifacts Only

**Remove direct stat purchases.** All stats come from artifacts, which are more common/cheap.

Artifacts like:
- Rusty Cog (Common, 15 scrap): +1 Draw
- Power Cell (Common, 20 scrap): +1 Energy  
- Thick Skin (Common, 15 scrap): +10 Max HP
- Sharp Rounds (Common, 20 scrap): +5% Gun Damage

Artifacts ARE the stat system. Makes artifacts feel more impactful.

**Pros:** Unified system (no separate "stats"), artifacts matter more
**Cons:** More RNG dependent, can't guarantee core stats

---

### Approach G: Hybrid - Core Always, Extras Random

**Core stats** (Energy, Draw, Weapon Slots) are ALWAYS available in a side panel.
**Extra stats** (damage %, HP, etc.) appear randomly in normal shop pool.

Side Panel (always visible):
```
┌─────────────────────┐
│ UPGRADES            │
│ +1 Energy    [60]   │
│ +1 Draw      [50]   │
│ +1 Slot      [80]   │
└─────────────────────┘
```

This ensures you can always buy the "must-have" progression stats, while minor stats add shop variety.

**Pros:** Best of both - reliability for core, variety for extras
**Cons:** Slightly more complex UI

---

## Pricing Philosophy

**First purchases should be cheap** (getting from 1→2 energy is huge)
**Later purchases should be expensive** (4→5 energy is marginal)

### Scaling Options:

**Linear:** `base + (level × increment)`
```
Energy: 40, 60, 80, 100, 120
```

**Exponential:** `base × 1.5^level`
```
Energy: 40, 60, 90, 135, 200
```

**Tiered jumps:**
```
Energy: 40, 50, 75, 120, 200
```

**Recommendation:** Exponential feels most Brotato - early is accessible, late is a luxury you only buy if swimming in scrap.

---

## My Take

**If you want true Brotato feel:** Approach A or G
- Stats compete with weapons for scrap
- Sometimes you see Energy upgrade, sometimes you don't
- Creates tension and variety

**If you want player control:** Approach B
- Always know Energy is available
- Can plan around guaranteed access
- More strategic, less chaotic

**If you want simplicity:** Approach F
- Artifacts ARE stats
- One system, not two
- But more RNG-dependent

---

### 5. Wave 1 Design (Trivially Easy)

**Current Wave 1:** 6 Husks (8 HP, 4 damage each) - actually quite threatening

**Brotato Wave 1:** 2-3 Weaklings
- 3 HP, 2 damage
- Ensures any starter weapon can clear them
- Drops ~15 scrap total

Purpose: **Not a challenge** - just an introduction to your weapon working. The "game" starts at the shop.

### 5. Interest System

**After each wave, before shopping:**
1. Gain base scrap from kills (~10-15 per wave early, scales up)
2. **Interest bonus**: +5% of current scrap, capped at +25 scrap (so 500 scrap = max interest)

This creates the classic Brotato tension:
- **Spend now**: Get stronger immediately
- **Save**: Hit interest thresholds for long-term value

| Scrap Saved | Interest Earned |
|-------------|-----------------|
| 0-20 | +0 |
| 20-40 | +1 |
| 40-60 | +2 |
| 60-80 | +3 |
| ... | ... |
| 500+ | +25 (cap) |

### 6. Shop Restructure

**Current shop:** Cards, artifacts, services

**Brotato-style shop:**
- **Weapons** (cards) - still the core
- **Items** (artifacts) - passive stat boosts
- **Upgrades** (new!) - permanent stat increases:
  - +1 Max Energy: 50 scrap
  - +1 Draw/Turn: 50 scrap  
  - +10 Max HP: 30 scrap
  - +10% Gun Damage: 40 scrap
  - +1 Weapon Slot (if capped): 100 scrap

**Lock/Unlock mechanic:**
- Pay 1 scrap to lock an item until next wave
- Lets you save for expensive items while banking interest

### 7. Weapon Slot Limit

Currently: 7 deployed weapons max

**Brotato approach:**
- Start with **4 weapon slots**
- Can buy more slots in shop (expensive)
- Creates meaningful "deck size" without actual deck management

---

## What This Changes

### Removes
- Fixed starter decks per warden
- Early deck-building complexity
- "Which cards to mulligan" decisions

### Adds
- **Shop as THE game** - every wave is just "survive then shop"
- **Banking vs. spending** tension
- **Build identity from item 1** - your starter weapon sets the trajectory
- **Power curve clarity** - you're weak then strong, not "medium" the whole time

### Keeps
- Wardens (as stat/passive modifiers, not deck definers)
- Ring battlefield
- Tag system and synergies
- Artifacts
- Wave pressure

---

## Questions to Resolve

### Q1: What about the deck/draw system?

**Option A: Keep traditional deck**
- Your 1 starter weapon + shop purchases form a deck
- Draw normally, shuffle, etc.
- Issue: With 1-2 cards, "deck" feels weird

**Option B: Brotato pure (no deck)**
- Weapons are just "equipped" - always available
- Hand = all owned weapons
- Energy limits what you play per turn
- Simpler, more Brotato-authentic

**Option C: Hybrid**
- Persistent weapons stay deployed (no re-draw needed)
- Instant cards go to a mini-deck
- Best of both?

### Q2: How do Wardens fit?

**Option A: Wardens as passive modifiers only**
- Pick warden, then pick starter weapon
- Warden gives stat bonuses (+HP, +damage%, etc.)
- No starter deck influence

**Option B: Warden determines starter weapon pool**
- Each warden has 3 "themed" starter weapons
- More variety, but limits choice

**Option C: Remove wardens entirely**
- Starter weapon IS your identity
- Simpler, more Brotato-like

### Q3: Where do instant cards fit?

Brotato is all passive weapons. Our game has instant spells.

**Option A: Instants are consumables**
- Buy them, use them once, gone
- Like Brotato's consumable items

**Option B: Instants recharge**
- Use once per wave
- More value, fits card-game feel

**Option C: Keep deck for instants only**
- Persistent weapons = always available
- Instant cards = drawn from small deck
- Could work, adds depth

### Q4: What about card upgrades / merges?

**Option A: Keep triple-merge**
- Buy 3 of same weapon → upgrades
- Works naturally with shop focus

**Option B: Direct upgrades in shop**
- "Upgrade Rusty Pistol → Iron Pistol" appears as shop option
- More direct progression

---

## Minimum Viable Changes (Phase 1)

If we want to TEST this concept quickly:

1. **New scene: StarterWeaponSelect.tscn**
   - Shows 7 weapon options
   - Player picks 1
   - Sets `RunManager.current_deck = [chosen_weapon]`

2. **Modify RunManager**
   - `energy_per_turn = 1` (was 3)
   - `draw_per_turn = 1` (was 5)
   - `max_hp = 50` (was 70)
   - `scrap = 0`

3. **Add interest calculation**
   - In post-wave reward screen
   - `interest = min(floor(scrap * 0.05), 25)`
   - Show "+X interest" in UI

4. **Nerf Wave 1**
   - Create new wave definition with 2-3 weak enemies
   - 3 HP, 2 damage, no abilities

5. **Keep everything else the same**
   - Shop still works
   - Combat still works
   - Just different starting state

This gets us playing with the core loop change fast.

---

## Open Design Space

Things that could be cool but aren't essential:

- **Character unlock system** - beat runs to unlock more starter weapons
- **Weapon "evolutions"** - certain combos create special weapons
- **Challenge modifiers** - Brotato-style run modifiers
- **Endless mode** - how long can you survive?
- **Leaderboards** - score tracking

---

## Next Steps

1. Decide on Q1-Q4 above
2. Implement Phase 1 minimal changes
3. Playtest the feel
4. Iterate on economy numbers

