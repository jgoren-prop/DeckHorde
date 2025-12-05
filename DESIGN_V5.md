# Riftwardens V5 – Synergy & Economy Redesign

## Design Philosophy

Inspired by **Brotato's** build-driven gameplay:

1. **Everything deals damage** – No "setup" cards. Every card contributes to kills.
2. **Stats do the synergizing** – Card text is simple. Stats multiply everything.
3. **Build in shop, execute in combat** – Decisions happen between waves, not during.
4. **3 damage types, 8 weapon categories** – Types determine bonuses, categories determine scaling.
5. **Family buffs reward commitment** – Stack a category, get scaling bonuses.

---

## The Damage System

### 3 Damage Types

These determine which `%_bonus` multipliers apply to damage:

| Type | Fantasy | Multiplier Stat |
|------|---------|-----------------|
| **KINETIC** | Physical projectiles | `kinetic_percent` |
| **THERMAL** | Fire, explosions, burn | `thermal_percent` |
| **ARCANE** | Curses, magic, hex | `arcane_percent` |

### 8 Weapon Categories

These determine what stats the weapon SCALES with:

| Category | Primary Type | Scales With | Fantasy |
|----------|--------------|-------------|---------|
| **Kinetic** | Kinetic | Kinetic stat | Reliable guns |
| **Thermal** | Thermal | Thermal stat, AOE | Explosions |
| **Arcane** | Arcane | Arcane stat, Hex | Curses |
| **Fortress** | Kinetic | Armor | Tanky offense |
| **Shadow** | Kinetic | Crit stats | Assassin |
| **Utility** | Mixed | Cards Played, Draw | Combo engine |
| **Control** | Mixed | Barriers, Ring position | Tower defense |
| **Volatile** | Thermal | Missing HP, Self-damage | Glass cannon |

### Damage Formula

```
Final Damage = (Base + Stat Scaling) × Type Multiplier × Global Multiplier × Crit
```

**Example: Siege Cannon**
```
Base: 3 + (80% Kinetic) + (50% ArmorStart)
Type: Kinetic
```

Player has:
- Kinetic stat: 20
- ArmorStart stat: 12
- kinetic_percent: +30%

Calculation:
- Base: 3
- Kinetic scaling: 20 × 0.80 = 16
- ArmorStart scaling: 12 × 0.50 = 6
- Subtotal: 25
- × Kinetic bonus (1.30): 32.5 → **32 damage**

---

## Core Stats

### Flat Damage Stats (For Weapon Scaling)

| Stat | Default | Effect |
|------|---------|--------|
| `kinetic` | 0 | Flat Kinetic damage for scaling |
| `thermal` | 0 | Flat Thermal damage for scaling |
| `arcane` | 0 | Flat Arcane damage for scaling |

### Percentage Multipliers (Applied to Final Damage)

| Stat | Default | Effect |
|------|---------|--------|
| `kinetic_percent` | 100% | Multiplier on Kinetic-type damage |
| `thermal_percent` | 100% | Multiplier on Thermal-type damage |
| `arcane_percent` | 100% | Multiplier on Arcane-type damage |
| `damage_percent` | 100% | Multiplier on ALL damage |
| `aoe_percent` | 100% | Multiplier on AOE attacks |

### Crit Stats

| Stat | Default | Effect |
|------|---------|--------|
| `crit_chance` | 5% | Chance to crit |
| `crit_damage` | 150% | Damage multiplier on crit |

### Status Effect Stats

| Stat | Default | Effect |
|------|---------|--------|
| `hex_potency` | 0% | Bonus damage from Hex stacks (+X%) |
| `burn_potency` | 0% | Bonus damage from Burn ticks (+X%) |
| `lifesteal_percent` | 0% | Heal for X% of damage dealt |

### Barrier Stats

| Stat | Default | Effect |
|------|---------|--------|
| `barrier_damage_bonus` | 0 | Flat damage added to barrier hits |
| `barrier_uses_bonus` | 0 | Extra uses for barriers you place |

### Defense Stats

| Stat | Default | Effect |
|------|---------|--------|
| `max_hp` | 50 | Maximum health |
| `armor` | 0 | Current armor (blocks damage) |
| `armor_start` | 0 | Armor gained at wave start |
| `self_damage_reduction` | 0 | Reduce self-damage by X |

### Economy/Tempo Stats

| Stat | Default | Effect |
|------|---------|--------|
| `draw_per_turn` | 5 | Cards drawn at turn start |
| `energy_per_turn` | 3 | Energy per turn |
| `hand_size` | 7 | Maximum hand size |

### Special Stats (For Scaling)

| Stat | What It Is |
|------|------------|
| `cards_played` | Cards played this turn (resets each turn) |
| `barriers` | Number of active barriers |
| `missing_hp` | Max HP - Current HP |
| `kills_this_turn` | Enemies killed this turn |

---

## Family Buffs

Stacking weapons of a category grants bonuses:

| Category | Tier 1 (3-5) | Tier 2 (6-8) | Tier 3 (9+) |
|----------|--------------|--------------|-------------|
| Kinetic | +3 Kinetic | +6 Kinetic | +10 Kinetic |
| Thermal | +3 Thermal | +6 Thermal | +10 Thermal |
| Arcane | +3 Arcane | +6 Arcane | +10 Arcane |
| Fortress | +3 Armor/wave | +6 Armor/wave | +10 Armor/wave |
| Shadow | +5% Crit | +10% Crit | +15% Crit |
| Utility | +1 Draw/wave | +2 Draw/wave | +3 Draw/wave |
| Control | +1 Barrier (2dmg) | +1 Barrier (3dmg) | +2 Barriers (3dmg) |
| Volatile | +5 Max HP | +12 Max HP | +20 Max HP |

---

## Full Card List (54 Weapons)

Every weapon has **1-2 Categories** (determines family buff eligibility) and **1-2 Damage Types** (determines which % multipliers apply).

**Distribution:** ~20 single-category (37%), ~34 dual-category (63%) - matching Brotato's hybrid ratio.

**Rarity:** All base weapons are **Common** at Tier 1. Higher tiers can appear in shop at higher rarities based on wave (see Card Tier System).

### Category Legend
- **Categories:** Which family buffs the card counts toward
- **Type:** Which damage % multipliers apply
- **Scaling:** What flat stats add damage

---

### KINETIC-PRIMARY WEAPONS (10 Cards)
*Reliable guns. Pure Kinetic or Kinetic + one other category.*

| Card | Cost | Base | Scaling | Type | Categories | Crit | Effect |
|------|------|------|---------|------|------------|------|--------|
| Pistol | 1 | 2 | +100% Kinetic | Kinetic | Kinetic | 5%/150% | — |
| Heavy Pistol | 2 | 3 | +120% Kinetic | Kinetic | Kinetic | 5%/150% | — |
| Shotgun | 2 | 2 | +80% Kinetic | Kinetic | Kinetic, Thermal | 5%/150% | +2 splash to group |
| Assault Rifle | 2 | 1 | +60% Kinetic | Kinetic | Kinetic, Utility | 5%/150% | Hits 3 random |
| Sniper Rifle | 2 | 4 | +150% Kinetic | Kinetic | Kinetic, Shadow | 15%/200% | Far/Mid only |
| Burst Fire | 2 | 1 | +50% Kinetic | Kinetic | Kinetic, Utility | 5%/150% | Hits 3× |
| Chain Gun | 2 | 0 | +40% Kinetic | Kinetic | Kinetic, Utility | 5%/150% | Hits 5×, can repeat |
| Double Tap | 1 | 1 | +70% Kinetic | Kinetic | Kinetic, Shadow | 12%/175% | Hits 2× |
| Marksman | 2 | 2 | +100% Kinetic | Kinetic | Kinetic, Shadow | 18%/200% | +50% vs Far |
| Railgun | 3 | 5 | +180% Kinetic | Kinetic | Kinetic, Fortress | 5%/150% | Ignores armor |

**Synergy Notes:**
- Shotgun (Kinetic+Thermal): Benefits from both family buffs, splash synergizes with Thermal AOE builds
- Sniper/Double Tap/Marksman (Kinetic+Shadow): Precision weapons want both flat damage AND crit bonuses
- Assault/Burst/Chain (Kinetic+Utility): Multi-hit weapons reward card combo builds
- Railgun (Kinetic+Fortress): Heavy siege weapon for armor tank builds

---

### THERMAL-PRIMARY WEAPONS (7 Cards)
*AOE and burn. Thermal or Thermal + one other category.*

| Card | Cost | Base | Scaling | Type | Categories | Crit | Effect |
|------|------|------|---------|------|------------|------|--------|
| Frag Grenade | 2 | 2 | +100% Thermal | Thermal | Thermal, Volatile | 5%/150% | Hits entire ring |
| Rocket | 3 | 3 | +120% Thermal | Thermal | Thermal | 5%/150% | +3 splash to group |
| Incendiary | 2 | 1 | +80% Thermal | Thermal | Thermal, Arcane | 5%/150% | Apply 3 Burn |
| Firebomb | 2 | 1 | +70% Thermal | Thermal | Thermal, Control | 5%/150% | Ring, apply 2 Burn each |
| Cluster Bomb | 2 | 1 | +60% Thermal | Thermal | Thermal, Utility | 5%/150% | Hits 4 random |
| Inferno | 3 | 2 | +100% Thermal | Thermal | Thermal | 5%/150% | Ring, apply 3 Burn each |
| Napalm Strike | 3 | 2 | +90% Thermal | Thermal | Thermal, Volatile | 5%/150% | ALL enemies, apply 2 Burn |

**Synergy Notes:**
- Frag/Napalm (Thermal+Volatile): Dangerous explosives, benefits from max HP for survival
- Incendiary (Thermal+Arcane): DoT stacking, Burn + Hex builds
- Firebomb (Thermal+Control): Fire zone denial, barrier synergy
- Cluster (Thermal+Utility): Multi-hit explosive for combo builds

---

### ARCANE-PRIMARY WEAPONS (7 Cards)
*Hex and lifesteal. Arcane or Arcane + one other category.*

| Card | Cost | Base | Scaling | Type | Categories | Crit | Effect |
|------|------|------|---------|------|------------|------|--------|
| Hex Bolt | 1 | 1 | +80% Arcane | Arcane | Arcane | 5%/150% | Apply 3 Hex |
| Curse Wave | 2 | 1 | +60% Arcane | Arcane | Arcane, Control | 5%/150% | Ring, apply 2 Hex each |
| Soul Drain | 2 | 2 | +100% Arcane | Arcane | Arcane, Volatile | 5%/150% | Heal 3 |
| Hex Detonation | 2 | 1 | +70% Arcane | Arcane | Arcane, Shadow | 20%/200% | Consumes Hex: +1 dmg per stack |
| Life Siphon | 1 | 1 | +60% Arcane | Arcane | Arcane | 5%/150% | Heal 2 |
| Dark Ritual | 2 | 1 | +50% Arcane | Arcane | Arcane, Volatile | 5%/150% | Ring, apply 3 Hex. Take 2 damage |
| Spreading Plague | 2 | 2 | +90% Arcane | Arcane | Arcane, Control | 5%/150% | 4 Hex, on kill spread 2 to ring |

**Synergy Notes:**
- Curse Wave/Spreading Plague (Arcane+Control): Zone control with curses
- Soul Drain/Dark Ritual (Arcane+Volatile): Blood magic theme, self-damage for power
- Hex Detonation (Arcane+Shadow): Burst damage potential with crit

---

### FORTRESS-PRIMARY WEAPONS (6 Cards)
*Armor scaling. Kinetic damage that grows with ArmorStart stat.*

| Card | Cost | Base | Scaling | Type | Categories | Crit | Effect |
|------|------|------|---------|------|------------|------|--------|
| Shield Bash | 1 | 2 | +50% Kinetic, +20% ArmorStart | Kinetic | Fortress, Control | 5%/150% | Gain 2 armor |
| Iron Volley | 2 | 2 | +60% Kinetic, +25% ArmorStart | Kinetic | Fortress | 5%/150% | Gain 3 armor |
| Bulwark Shot | 2 | 1 | +40% Kinetic, +35% ArmorStart | Kinetic | Fortress, Control | 5%/150% | +1 armor per Melee enemy |
| Fortified Barrage | 3 | 2 | +50% Kinetic, +40% ArmorStart | Kinetic | Fortress | 5%/150% | Ring. Gain 4 armor |
| Reactive Shell | 2 | 2 | +70% Kinetic, +30% ArmorStart | Kinetic | Fortress, Shadow | 15%/175% | — |
| Siege Cannon | 3 | 3 | +80% Kinetic, +50% ArmorStart | Kinetic | Fortress, Volatile | 5%/150% | Costs 2 armor to play |

**Synergy Notes:**
- Shield Bash/Bulwark (Fortress+Control): Defensive positioning, barrier synergy
- Reactive Shell (Fortress+Shadow): Counter-sniper, armored precision
- Siege Cannon (Fortress+Volatile): High risk siege, costs armor to fire

---

### SHADOW-PRIMARY WEAPONS (6 Cards)
*Crit scaling. High crit chance and crit damage.*

| Card | Cost | Base | Scaling | Type | Categories | Crit | Effect |
|------|------|------|---------|------|------------|------|--------|
| Assassin's Strike | 1 | 1 | +60% Kinetic, +15% CritDmg | Kinetic | Shadow, Utility | 20%/200% | — |
| Shadow Bolt | 1 | 2 | +70% Kinetic, +10% CritDmg | Kinetic | Shadow | 15%/175% | — |
| Precision Shot | 2 | 2 | +80% Kinetic, +20% CritDmg | Kinetic | Shadow, Kinetic | 25%/200% | Mid/Far only |
| Backstab | 2 | 2 | +90% Kinetic, +25% CritDmg | Kinetic | Shadow, Control | 30%/175% | Far only, +2 vs Far |
| Killing Blow | 3 | 2 | +100% Kinetic, +35% CritDmg | Kinetic | Shadow | 35%/250% | — |
| Shadow Barrage | 2 | 1 | +50% Kinetic, +15% CritDmg | Kinetic | Shadow, Utility | 20%/175% | Hits 3×, each crits separately |

**Synergy Notes:**
- Assassin's Strike/Shadow Barrage (Shadow+Utility): Quick combo assassinations
- Precision Shot (Shadow+Kinetic): Pure gun precision build
- Backstab (Shadow+Control): Positioning-based assassination

---

### UTILITY-PRIMARY WEAPONS (6 Cards)
*Cards-played scaling. Rewards playing many cards per turn.*

| Card | Cost | Base | Scaling | Type | Categories | Crit | Effect |
|------|------|------|---------|------|------------|------|--------|
| Quick Shot | 0 | 1 | +50% Kinetic, +1×CardsPlayed | Kinetic | Utility, Kinetic | 5%/150% | Draw 1 |
| Flurry | 1 | 1 | +40% Kinetic, +2×CardsPlayed | Kinetic | Utility | 5%/150% | — |
| Chain Strike | 1 | 2 | +60% Kinetic, +1×CardsPlayed | Kinetic | Utility, Shadow | 12%/175% | Next card -1 cost |
| Momentum | 1 | 0 | +30% Kinetic, +3×CardsPlayed | Kinetic | Utility | 5%/150% | — |
| Rapid Fire | 2 | 0 | +40% Kinetic, +1×CardsPlayed | Kinetic | Utility, Kinetic | 5%/150% | Hits 4× |
| Overdrive | 2 | 2 | +70% Kinetic, +2×CardsPlayed | Kinetic | Utility, Volatile | 5%/150% | Draw 2, discard 1. Take 1 damage |

**Synergy Notes:**
- Quick Shot/Rapid Fire (Utility+Kinetic): Combo enablers for gun builds
- Chain Strike (Utility+Shadow): Combo into big crit finisher
- Overdrive (Utility+Volatile): Risky card draw engine

---

### CONTROL-PRIMARY WEAPONS (6 Cards)
*Barrier and positioning scaling. Zone control.*

| Card | Cost | Base | Scaling | Type | Categories | Crit | Effect |
|------|------|------|---------|------|------------|------|--------|
| Repulsor | 1 | 2 | +60% Kinetic, +2×Barriers | Kinetic | Control, Kinetic | 5%/150% | Push target 1 ring |
| Barrier Shot | 2 | 2 | +50% Kinetic, +3×Barriers | Kinetic | Control | 5%/150% | Place barrier (2dmg, 2 uses) |
| Lockdown | 2 | 1 | +40% Kinetic, +2×Barriers | Kinetic | Control, Fortress | 5%/150% | Ring, enemies can't advance |
| Far Strike | 1 | 2 | +80% Kinetic | Kinetic | Control, Shadow | 15%/175% | +3 vs Far, +2 if no Melee enemies |
| Killzone | 3 | 2 | +70% Kinetic, +4×Barriers | Kinetic | Control | 5%/150% | Hits all that moved this turn |
| Perimeter | 2 | 1 | +40% Kinetic, +5×Barriers | Kinetic | Control, Fortress | 5%/150% | — |

**Synergy Notes:**
- Lockdown/Perimeter (Control+Fortress): Defensive zone control
- Far Strike (Control+Shadow): Positioning precision, sniper backup
- Repulsor (Control+Kinetic): Gun control hybrid

---

### VOLATILE-PRIMARY WEAPONS (6 Cards)
*Missing HP scaling. Glass cannon self-damage builds.*

| Card | Cost | Base | Scaling | Type | Categories | Crit | Effect |
|------|------|------|---------|------|------------|------|--------|
| Overcharge | 1 | 2 | +80% Thermal, +15% MissingHP | Thermal | Volatile, Thermal | 5%/150% | Take 2 damage |
| Reckless Blast | 2 | 3 | +100% Thermal, +20% MissingHP | Thermal | Volatile, Thermal | 5%/150% | +3 splash. Take 3 damage |
| Blood Rocket | 2 | 2 | +70% Thermal, +25% MissingHP | Thermal | Volatile, Arcane | 5%/150% | Ring. Take 2 damage. Heal 1 per kill |
| Unstable Core | 2 | 4 | +120% Thermal, +15% MissingHP | Thermal | Volatile | 5%/150% | Take 4 damage. Kill = no self-damage |
| Kamikaze Swarm | 3 | 2 | +80% Thermal, +30% MissingHP | Thermal | Volatile, Thermal | 5%/150% | ALL enemies. Take 5 damage |
| Desperation | 1 | 1 | +60% Thermal, +40% MissingHP | Thermal | Volatile, Shadow | 25%/200% | — |

**Synergy Notes:**
- Overcharge/Reckless/Kamikaze (Volatile+Thermal): Pure explosive self-damage
- Blood Rocket (Volatile+Arcane): Blood magic rocket, heal on kill
- Desperation (Volatile+Shadow): High risk assassination, crit when low HP

---

## Card Category Distribution

| Primary | Single-Cat | Dual-Cat | Total |
|---------|-----------|----------|-------|
| Kinetic | 2 | 8 | 10 |
| Thermal | 2 | 5 | 7 |
| Arcane | 2 | 5 | 7 |
| Fortress | 2 | 4 | 6 |
| Shadow | 2 | 4 | 6 |
| Utility | 2 | 4 | 6 |
| Control | 2 | 4 | 6 |
| Volatile | 1 | 5 | 6 |
| **TOTAL** | **15 (28%)** | **39 (72%)** | **54** |

---

## Cross-Category Combinations (Which Cards Belong to Both)

| Combination | Weapons | Instants | Synergy Theme |
|-------------|---------|----------|---------------|
| **Kinetic + Shadow** | Sniper Rifle, Double Tap, Marksman, Precision Shot | — | Precision gunplay |
| **Kinetic + Utility** | Assault Rifle, Burst Fire, Chain Gun, Quick Shot, Rapid Fire | — | Multi-hit combos |
| **Kinetic + Fortress** | Railgun | — | Heavy siege weapons |
| **Kinetic + Control** | Repulsor | — | Gun zone control |
| **Kinetic + Thermal** | Shotgun | Incendiary Rounds | Explosive projectiles |
| **Kinetic + Arcane** | — | Cursed Ammo | Gun + curse hybrid |
| **Thermal + Volatile** | Frag Grenade, Napalm Strike, Overcharge, Reckless Blast, Kamikaze Swarm | — | Dangerous explosives |
| **Thermal + Arcane** | Incendiary | — | DoT stacking |
| **Thermal + Control** | Firebomb | Burning Barrier | Fire zone denial |
| **Thermal + Utility** | Cluster Bomb | — | Multi-hit explosives |
| **Arcane + Control** | Curse Wave, Spreading Plague | — | Curse zones |
| **Arcane + Volatile** | Soul Drain, Dark Ritual, Blood Rocket | — | Blood magic |
| **Arcane + Shadow** | Hex Detonation | — | Burst curse damage |
| **Fortress + Control** | Shield Bash, Bulwark Shot, Lockdown, Perimeter | — | Tank defense |
| **Fortress + Shadow** | Reactive Shell | — | Armored precision |
| **Fortress + Volatile** | Siege Cannon | — | Costly siege |
| **Shadow + Utility** | Assassin's Strike, Shadow Barrage, Chain Strike | — | Combo assassinations |
| **Shadow + Control** | Backstab, Far Strike | — | Positioning crits |
| **Shadow + Volatile** | Desperation | Desperate Strike | Risky crits |
| **Utility + Volatile** | Overdrive | — | Risky card engine |

---

## Instant Cards (24 Cards)

Instants are non-weapon cards that provide utility, buffs, and support. They:
- **Don't deal direct damage** (weapons do that)
- **Have category tags** (count toward family buffs)
- **Enable combos** (buff weapons, apply status, gain resources)
- **No tiers** - Instants cannot be merged and don't have tier upgrades

### Design Tiers
- **Universal (4):** No category tag, useful for any build
- **Single-Category (16):** 2 per category, count toward that family buff
- **Dual-Category (4):** Enable cross-build synergies

---

### UNIVERSAL INSTANTS (4 Cards)
*No category tag. Pure utility for any build.*

| Card | Cost | Rarity | Effect | Categories |
|------|------|--------|--------|------------|
| Bandage | 1 | Common | Heal 5 | — |
| Med Kit | 2 | Common | Heal 10 | — |
| Stim Pack | 1 | Common | +2 Energy this turn | — |
| Tactical Draw | 1 | Common | Draw 2 | — |

---

### KINETIC INSTANTS (2 Cards)

| Card | Cost | Rarity | Effect | Categories |
|------|------|--------|--------|------------|
| Focus Fire | 1 | Common | Next weapon +3 damage | Kinetic |
| Reload | 1 | Uncommon | If hand < 3 cards, draw to 3 | Kinetic |

**Synergy:** Focus Fire is great for any gun build. Reload helps when you're running low on cards mid-turn.

---

### THERMAL INSTANTS (2 Cards)

| Card | Cost | Rarity | Effect | Categories |
|------|------|--------|--------|------------|
| Ignite | 1 | Common | Apply 4 Burn to target | Thermal |
| Heat Wave | 2 | Uncommon | Apply 2 Burn to ALL enemies | Thermal |

**Synergy:** Pure Burn application. Stack with Thermal weapons for massive DoT.

---

### ARCANE INSTANTS (2 Cards)

| Card | Cost | Rarity | Effect | Categories |
|------|------|--------|--------|------------|
| Curse | 1 | Common | Apply 4 Hex to target | Arcane |
| Mass Hex | 2 | Uncommon | Apply 2 Hex to ALL enemies | Arcane |

**Synergy:** Setup Hex stacks for weapons like Hex Detonation to consume.

---

### FORTRESS INSTANTS (2 Cards)

| Card | Cost | Rarity | Effect | Categories |
|------|------|--------|--------|------------|
| Reinforce | 1 | Common | Gain 5 armor | Fortress |
| Fortify | 2 | Uncommon | Gain armor = your ArmorStart stat | Fortress |

**Synergy:** Fortify scales with your ArmorStart stat. At 10 ArmorStart, it gives 10 armor for 2 energy.

---

### SHADOW INSTANTS (2 Cards)

| Card | Cost | Rarity | Effect | Categories |
|------|------|--------|--------|------------|
| Mark Target | 1 | Uncommon | Next weapon guaranteed crit | Shadow |
| Setup Kill | 2 | Uncommon | Next weapon +50% crit damage | Shadow |

**Synergy:** Mark Target → Killing Blow = guaranteed 250% crit. Setup Kill makes it even deadlier.

---

### UTILITY INSTANTS (2 Cards)

| Card | Cost | Rarity | Effect | Categories |
|------|------|--------|--------|------------|
| Quick Hands | 0 | Common | Draw 1 | Utility |
| Tempo | 1 | Uncommon | Draw 2. Next card costs 1 less | Utility |

**Synergy:** Quick Hands at 0 cost increases your cards_played counter for free. Tempo enables big combos.

---

### CONTROL INSTANTS (2 Cards)

| Card | Cost | Rarity | Effect | Categories |
|------|------|--------|--------|------------|
| Deploy Barrier | 2 | Common | Place barrier (2 dmg, 3 uses) on any ring | Control |
| Hold the Line | 2 | Uncommon | Enemies can't advance this turn | Control |

**Synergy:** Deploy Barrier increases your barrier count for weapons that scale with it. Hold the Line buys time.

---

### VOLATILE INSTANTS (2 Cards)

| Card | Cost | Rarity | Effect | Categories |
|------|------|--------|--------|------------|
| Adrenaline | 1 | Common | Take 3 damage. +3 Energy this turn | Volatile |
| Pain Threshold | 1 | Common | Take 2 damage. Draw 2 | Volatile |

**Synergy:** Self-damage increases your missing HP for Volatile weapons. Also triggers max HP family buff value.

---

### DUAL-CATEGORY INSTANTS (4 Cards)
*Cross-build enablers. Count toward TWO family buffs.*

| Card | Cost | Rarity | Effect | Categories |
|------|------|--------|--------|------------|
| Incendiary Rounds | 1 | Uncommon | Next weapon applies 2 Burn | Kinetic, Thermal |
| Cursed Ammo | 1 | Uncommon | Next weapon applies 2 Hex | Kinetic, Arcane |
| Burning Barrier | 2 | Rare | Place barrier (2 dmg, 2 uses) that applies 3 Burn when hit | Control, Thermal |
| Desperate Strike | 1 | Rare | Next weapon +1 damage per 5 missing HP | Volatile, Shadow |

**Synergy Notes:**
- **Incendiary Rounds:** Kinetic guns can now apply Burn. Counts toward BOTH family buffs.
- **Cursed Ammo:** Kinetic guns can now apply Hex. Enables gun + curse hybrid builds.
- **Burning Barrier:** Fire-based zone control. Counts toward Control AND Thermal family.
- **Desperate Strike:** Low HP crit build. At 25 missing HP, next weapon gets +5 damage AND you're building Shadow family.

---

### Instant Card Summary

| Rarity | Count | Examples |
|--------|-------|----------|
| Common | 12 | Bandage, Focus Fire, Ignite, Quick Hands |
| Uncommon | 10 | Reload, Heat Wave, Mark Target, Tempo |
| Rare | 2 | Burning Barrier, Desperate Strike |
| **TOTAL** | **24** | |

---

### Combined Card Pool

| Card Type | Count | Has Tiers? | Can Merge? |
|-----------|-------|------------|------------|
| Weapons | 54 | Yes (1-4) | Yes |
| Instants | 24 | No | No |
| **TOTAL** | **78** | | |

---

## Example Builds with Scaling

### Pure Kinetic Gunner
- Stack Kinetic weapons
- Buy `kinetic` stat (+flat damage)
- Buy `kinetic_percent` (+multiplier)
- Family buff: +10 Kinetic at 9 cards
- All weapons hit harder

### Fortress Tank
- Stack Fortress weapons
- Buy `kinetic` + `armor_start`
- Weapons scale with both!
- Family buff: +10 Armor/wave
- Start wave tanky, deal damage based on tankiness

### Shadow Assassin
- Stack Shadow weapons + Shadow instants (Mark Target, Setup Kill)
- Buy `crit_chance` + `crit_damage`
- Weapons scale with crit damage stat
- Family buff: +15% crit chance
- Combo: Mark Target → Killing Blow = guaranteed 250% crit
- Every card can delete enemies

### Volatile Glass Cannon
- Stack Volatile weapons + Volatile instants (Adrenaline, Pain Threshold)
- Buy `thermal` + `max_hp`
- Use Adrenaline/Pain Threshold to intentionally lower HP for scaling
- Family buff: +20 Max HP (more HP to lose!)
- Low HP = nuclear damage

### Utility Combo Master
- Stack Utility weapons + Utility instants (Quick Hands, Tempo)
- Buy `kinetic` + `draw_per_turn` + `energy_per_turn`
- Quick Hands (0 cost) adds to cards_played for free!
- Family buff: +3 draw/wave
- Play 8 cards, 8th weapon deals +24 bonus damage

### Control Tower Defense
- Stack Control weapons
- Buy `barrier_damage` + `barrier_uses`
- Weapons scale with active barriers
- Family buff: 2 barriers at wave start
- Barriers deal damage AND buff your weapons

### Hybrid Arcane/Thermal DoT
- Use Incendiary (Thermal+Arcane) as core
- Buy `arcane` + `thermal` + both percents
- Add Blood Rocket (Volatile+Arcane) for ring clear
- Stack Hex AND Burn on enemies
- Everything dies to DoT

### Dual-Category Precision Build
- Stack Kinetic+Shadow cards: Sniper Rifle, Double Tap, Marksman, Precision Shot
- 4 cards = 4 Kinetic (Tier 1 buff: +3 Kinetic) AND 4 Shadow (Tier 1 buff: +5% Crit)
- Buy `kinetic` + `crit_damage`
- Get BOTH family buffs from same cards
- Every shot benefits from flat damage AND crits

---

## Status Effects

### Hex
- Stacks on enemies
- When hexed enemy takes damage: +damage equal to Hex stacks
- Hex consumed on trigger
- Scales with `hex_potency` stat

### Burn  
- Stacks on enemies
- End of each turn: deal Burn damage to enemy
- Burn reduces by 1 each turn
- Scales with `burn_potency` stat

### Barriers
- Placed on rings (Close, Mid, Far)
- Enemy crosses ring: barrier deals damage, loses 1 use
- Disappears at 0 uses
- Scales with `barrier_damage_bonus` and `barrier_uses_bonus`

---

## Starter Deck (10 Cards)

| Card | Categories | Count |
|------|------------|-------|
| Pistol | Kinetic | 3 |
| Shotgun | Kinetic, Thermal | 1 |
| Hex Bolt | Arcane | 2 |
| Shield Bash | Fortress, Control | 2 |
| Quick Shot | Utility, Kinetic | 2 |

**Starting Category Counts:**
- Kinetic: 6 (Pistol ×3, Shotgun ×1, Quick Shot ×2)
- Thermal: 1 (Shotgun)
- Arcane: 2 (Hex Bolt ×2)
- Fortress: 2 (Shield Bash ×2)
- Control: 2 (Shield Bash ×2)
- Utility: 2 (Quick Shot ×2)

Gives taste of 6 categories immediately, with Kinetic being the foundation to build from.

---

## Artifacts (50 Total)

### Common (16) - Stackable Stat Boosts

**Flat Damage Boosters:**
| Artifact | Effect | Cost |
|----------|--------|------|
| Kinetic Rounds | +3 Kinetic | 25 |
| Thermal Core | +3 Thermal | 25 |
| Arcane Focus | +3 Arcane | 25 |

**Percentage Boosters:**
| Artifact | Effect | Cost |
|----------|--------|------|
| Kinetic Amplifier | Kinetic damage +10% | 30 |
| Thermal Amplifier | Thermal damage +10% | 30 |
| Arcane Amplifier | Arcane damage +10% | 30 |
| Sharp Edge | ALL damage +5% | 35 |

**Other Stats:**
| Artifact | Effect | Cost |
|----------|--------|------|
| Lucky Coin | Crit chance +3% | 30 |
| Heavy Hitter | Crit damage +15% | 30 |
| Vampiric Fang | Lifesteal +3% | 35 |
| Blast Amplifier | AOE damage +10% | 30 |
| Iron Skin | +5 Max HP | 20 |
| Steel Plate | +2 Armor at wave start | 25 |
| Scrap Collector | Scrap gain +10% | 25 |
| Card Sleeve | +1 Hand Size | 30 |
| Hex Potency | Hex deals +15% | 30 |

---

### Uncommon (16) - Category Synergies

| Artifact | Effect | Cost |
|----------|--------|------|
| Precision Scope | Kinetic weapons: +5% crit | 45 |
| Pyromaniac | Thermal kills: 2 Burn to adjacent | 50 |
| Soul Leech | Arcane damage: heal 10% dealt | 55 |
| Reactive Armor | Fortress cards: +1 armor gained | 45 |
| Assassin's Mark | Shadow crits: +25% crit damage | 50 |
| Nimble Fingers | First Utility each turn costs 0 | 55 |
| Fortified Walls | Control barriers: +1 use | 45 |
| Pain Conduit | Volatile self-damage -1 | 40 |
| Hunter's Instinct | On kill: heal 1 HP | 45 |
| Bounty Hunter | On kill: +1 scrap | 40 |
| Rapid Loader | +1 draw per turn | 60 |
| Power Cell | +1 energy per turn | 65 |
| Far Sight | Damage to Far/Mid +15% | 45 |
| Close Quarters | Damage to Melee/Close +15% | 45 |
| Thick Skin | Damage reduction +1 | 50 |
| Combo Training | +2 damage per card played | 55 |

---

### Rare (12) - Cross-Type Enablers

| Artifact | Effect | Cost |
|----------|--------|------|
| Burning Hex | Hex consumed: apply 2 Burn | 80 |
| Crit Shockwave | Crits push target 1 ring | 75 |
| Armor to Arms | Gain armor: deal 1 to random enemy | 70 |
| Pain Reflection | Take damage: deal 2 to random enemy | 85 |
| Draw Power | Draw card: +1 damage this turn (max +5) | 75 |
| Hex Detonator | Enemy with 5+ Hex dies: Hex damage to ring | 90 |
| Executioner | +50% damage to enemies below 25% HP | 80 |
| Overkill | Excess kill damage hits random enemy | 85 |
| Combo Finisher | 5th+ card each turn: +3 damage | 70 |
| Barrier Master | Barriers deal double damage | 90 |
| Critical Mass | After 3 crits/turn: next crit +100% | 85 |
| Survivor | Below 25% HP: +30% all damage | 75 |

---

### Legendary (6) - Build Definers

| Artifact | Effect | Cost |
|----------|--------|------|
| Infinity Engine | Cards that kill refund 1 energy | 120 |
| Blood Pact | All damage heals 15%. Max HP -20 | 100 |
| Glass Cannon | All damage +50%. Max HP = 25 | 90 |
| Bullet Time | First card each turn hits twice | 130 |
| Chaos Core | All cards +10% crit. Crits deal 1 to you | 110 |
| Immortal Shell | Once/wave: survive lethal at 1 HP, +10 armor | 140 |

---

## Enemies

### Design Philosophy

Enemies are **simple obstacles** for your build to overcome:
- Walk toward player, attack when in range
- No complex AI or mechanics
- Variety comes from HP, damage, speed, and behavior
- The interesting part is YOUR build, not enemy mechanics

### Enemy Armor (Special Mechanic)

**Armor = No Damage Spillover**

When an enemy has armor:
- Each HIT removes 1 armor (regardless of damage amount)
- Excess damage does NOT spill over to HP
- Once armor is depleted, damage hits HP normally

**Example: Shell Titan (5 Armor, 20 HP)**

| Weapon | Hits to Strip Armor | Efficiency |
|--------|---------------------|------------|
| Sniper (12 dmg × 1) | 5 hits wasted | BAD |
| Chain Gun (1 dmg × 5) | 1 card strips all | GOOD |
| Burn (3 ticks) | 3 ticks strip 3 | GOOD |

**This creates natural counters:**
- Big single-hit weapons → BAD vs armor
- Multi-hit weapons → GOOD vs armor
- DOT effects (Burn, Hex ticks) → GOOD vs armor

**Used sparingly** - only 1-2 enemy types have armor.

---

### Enemy Types (11 Enemies)

| Enemy | HP | Armor | Damage | Speed | Archetype |
|-------|-----|-------|--------|-------|-----------|
| Weakling | 3 | 0 | 2 | 1 | Rusher |
| Husk | 8 | 0 | 4 | 1 | Rusher |
| Cultist | 4 | 0 | 2 | 1 | Swarm |
| Spinecrawler | 6 | 0 | 3 | 2 | Fast |
| Spitter | 7 | 0 | 3 | 1 | Ranged |
| Shell Titan | 20 | 5 | 8 | 1 | Tank |
| Bomber | 9 | 0 | 0 | 1 | Bomber |
| Torchbearer | 10 | 0 | 2 | 1 | Buffer |
| Channeler | 12 | 0 | 3 | 1 | Spawner |
| Stalker | 9 | 0 | 6 | 1 | Ambusher |
| Armor Reaver | 10 | 0 | 3 | 1 | Shredder |

---

### Archetypes

| Archetype | Behavior | Threat Level |
|-----------|----------|--------------|
| **Rusher** | Walks toward player, attacks in Melee | Basic |
| **Swarm** | Spawns in groups, low HP | Fodder |
| **Fast** | Moves 2 rings per turn | Pressure |
| **Ranged** | Stops at Mid ring, shoots from distance | Sustained |
| **Tank** | High HP + Armor, slow | Sponge |
| **Bomber** | Explodes on death: 6 damage to player | Risk |
| **Buffer** | At Close: +2 damage to all nearby enemies | Priority |
| **Spawner** | At Close: spawns 1 Husk in Far each turn | Snowball |
| **Ambusher** | Spawns directly in Close ring | Surprise |
| **Shredder** | Shreds 3 player armor on hit | Anti-Fortress |

---

### Enemy Details

**Weakling**
- The Wave 1 tutorial enemy
- Dies to anything, teaches basic combat

**Husk**
- Standard melee threat
- The "baseline" enemy everything scales from

**Cultist**
- Spawns in groups of 3-5
- Tests AOE / Thermal builds

**Spinecrawler**
- Moves 2 rings per turn
- Reaches Melee fast, tests Control builds

**Spitter**
- Stops at Mid ring, attacks from range
- Can't be ignored, tests Far-targeting weapons

**Shell Titan**
- 5 Armor blocks big hits
- Forces multi-hit weapons or sustained damage
- The "armor check" enemy

**Bomber**
- Deals 0 damage normally
- Explodes when killed: 6 damage to player
- Must be killed at range or with planning

**Torchbearer**
- Weak on its own
- At Close ring: all nearby enemies deal +2 damage
- Priority target - kill before it reaches Close

**Channeler**
- At Close ring: spawns 1 Husk in Far each turn
- Snowballs if left alive
- Priority target

**Stalker**
- Spawns directly in Close (skips Far/Mid)
- High damage, surprise threat
- Punishes greedy builds that ignore Close

**Armor Reaver**
- Shreds 3 player armor on hit
- Direct counter to Fortress builds
- Forces Fortress players to kill quickly or lose armor

---

### Wave Structure (20 Waves)

**Waves 1-3: Onboarding**
- Wave 1: 3 Weaklings
- Wave 2-3: Weaklings + Cultists, then Husks
- Learn the game, earn first scrap

**Waves 4-6: Build Check**
- Introduce Spinecrawlers (speed pressure)
- First Spitters (ranged threat)
- First Torchbearer/Channeler (elite preview)
- Your build should be forming

**Waves 7-9: Stress Test**
- Themed waves:
  - Cultist Swarm (AOE test)
  - Spitter Wall (range test)
  - Shell Titan + support (armor test)
- Multiple threats per wave

**Waves 10-14: Scaling Pressure**
- More enemies, higher HP
- Multiple elite types per wave
- Build should be strong

**Waves 15-19: Endgame**
- Heavy elite presence
- Armor Reavers appear (Fortress check)
- Channeler + Stalker combos
- All-out assault

**Wave 20: Boss Wave**
- Ember Saint (Boss) + support enemies
- Final test of your build

---

### Boss: Ember Saint

| Stat | Value |
|------|-------|
| HP | 60 |
| Armor | 0 |
| Damage | 10 |
| Speed | 0 (stationary) |

**Behavior:**
- Stays in Far ring (doesn't advance)
- Attacks from range every turn
- Every 3 turns: spawns 2 Husks + 1 Bomber
- At 50% HP: spawns Shell Titan

**Design:** Tests sustained damage + horde management. Can't burst down easily, must handle spawns.

---

## Economy (Brotato-Style)

### Design Goals
- Get weapons FAST, start synergizing immediately
- Spend vs Save tension (interest system)
- Real choices every shop visit
- Wave 1 = buy 2 cheap cards OR save

---

### Scrap Earnings

**Enemy Drops:**
| Enemy | Scrap |
|-------|-------|
| Weakling | 1 |
| Husk | 2 |
| Cultist | 1 |
| Spinecrawler | 2 |
| Spitter | 2 |
| Shell Titan | 6 |
| Bomber | 2 |
| Torchbearer | 4 |
| Channeler | 5 |
| Stalker | 3 |
| Armor Reaver | 3 |
| Ember Saint | 25 |

**Wave Completion Bonus:**
| Wave | Bonus | Expected Total |
|------|-------|----------------|
| 1 | 30 | ~35 |
| 2 | 32 | ~45 |
| 3 | 35 | ~55 |
| 5 | 40 | ~70 |
| 10 | 55 | ~110 |
| 15 | 70 | ~150 |
| 20 | 90 | ~200 |

---

### Interest System

- Earn **5% of current scrap** after each wave
- **Capped at 25** per wave
- Encourages strategic saving

| Saved | Interest |
|-------|----------|
| 40 | 2 |
| 100 | 5 |
| 200 | 10 |
| 300 | 15 |
| 400 | 20 |
| 500+ | 25 (cap) |

---

### Card Costs

**By Rarity (Base = Tier 1):**
| Rarity | Cost |
|--------|------|
| Common | 12-18 |
| Uncommon | 30-45 |
| Rare | 65-85 |

**By Tier (Multiplier):**
| Tier | Multiplier | Common Card |
|------|------------|-------------|
| Tier 1 | ×1.0 | 15 |
| Tier 2 | ×1.8 | 27 |
| Tier 3 | ×3.0 | 45 |
| Tier 4 | ×4.5 | 68 |

---

### Artifact Costs

| Rarity | Cost |
|--------|------|
| Common | 18-28 |
| Uncommon | 40-60 |
| Rare | 75-100 |
| Legendary | 110-140 |

---

### Stat Upgrade Costs

| Upgrade | Base | +Per Buy |
|---------|------|----------|
| +3 Kinetic/Thermal/Arcane | 12 | +4 |
| +5% Type Damage | 18 | +6 |
| +5% All Damage | 22 | +8 |
| +3% Crit Chance | 25 | +8 |
| +5 Max HP | 12 | +4 |
| +2 Armor/Wave | 15 | +5 |
| +1 Draw/Turn | 45 | +20 |
| +1 Energy/Turn | 55 | +25 |

---

### Shop Structure

| Category | Slots | Contents |
|----------|-------|----------|
| Cards | 4 | Weapons (rarity × tier weighted) |
| Artifacts | 3 | Items (rarity weighted) |
| Stat Upgrades | 3 | Direct purchases |
| Services | 2 | Merge, Remove Card |

**Reroll Cost:** 2 base, +2 per reroll, resets each shop visit

---

### Services

| Service | Cost | Effect |
|---------|------|--------|
| **Merge** | FREE | Combine 2 same-name, same-tier cards → next tier |
| **Remove Card** | 15 + (wave × 3) | Remove card from deck |

---

## Card Tier System

### No Deck Cap
- Take as many cards as you want
- Natural punishment: bloated deck = diluted draws
- Player self-regulates

### Merging

**2 cards of same name + same tier → 1 card of next tier**

```
2x Pistol (Tier 1) → 1x Pistol (Tier 2)
2x Pistol (Tier 2) → 1x Pistol (Tier 3)
2x Pistol (Tier 3) → 1x Pistol (Tier 4)
```

To reach Tier 4 from scratch:
- 8x Tier 1 → 4x Tier 2 → 2x Tier 3 → 1x Tier 4
- OR find higher tiers directly in shop

### Tier Stat Scaling

| Tier | Base Damage | Scaling Bonus | Border Color |
|------|-------------|---------------|--------------|
| Tier 1 | 100% | 100% | Gray |
| Tier 2 | +50% | +25% | Green |
| Tier 3 | +100% | +50% | Blue |
| Tier 4 | +150% | +75% | Gold |

**Example: Pistol**
```
Tier 1: Base 2 + (100% Kinetic)
Tier 2: Base 3 + (125% Kinetic)
Tier 3: Base 4 + (150% Kinetic)
Tier 4: Base 5 + (175% Kinetic)
```

### Tier Appearance by Wave

| Wave | Tier 1 | Tier 2 | Tier 3 | Tier 4 |
|------|--------|--------|--------|--------|
| 1-3 | 100% | 0% | 0% | 0% |
| 4-6 | 75% | 25% | 0% | 0% |
| 7-9 | 50% | 40% | 10% | 0% |
| 10-12 | 30% | 45% | 20% | 5% |
| 13-15 | 15% | 35% | 35% | 15% |
| 16-18 | 5% | 25% | 45% | 25% |
| 19-20 | 0% | 15% | 50% | 35% |

### Rarity Appearance by Wave

| Wave | Common | Uncommon | Rare | Legendary |
|------|--------|----------|------|-----------|
| 1-3 | 70% | 25% | 5% | 0% |
| 4-7 | 55% | 35% | 9% | 1% |
| 8-12 | 40% | 40% | 17% | 3% |
| 13-17 | 25% | 40% | 28% | 7% |
| 18-20 | 15% | 35% | 38% | 12% |

---

## Progression Feel

**Wave 1-3:**
- Buy cheap Tier 1 cards quickly
- Start seeing synergies form
- 4+ weapons fast, like Brotato

**Wave 4-6:**
- Merge Tier 1s → Tier 2s
- Tier 2 appearing in shop
- Build identity solidifying

**Wave 10+:**
- Multiple Tier 2-3 weapons
- Core build online
- Hunting specific upgrades

**Wave 15+:**
- Tier 3-4 weapons dominant
- Build is powerful
- Optimizing final pieces

---

## Card UI Design

### Card Layout

```
┌─────────────────────────────────┐
│                                 │
│  ⚡2                    🔫 ✨   │ ← Cost (left), Type icons (right)
│                           22    │ ← Calculated damage
│                                 │
│  ─────────────────────────────  │
│                                 │
│          CARD NAME              │ ← Name
│                                 │
│    ┌───────────────────────┐    │
│    │                       │    │
│    │      [ ART AREA ]     │    │ ← Art
│    │                       │    │
│    └───────────────────────┘    │
│                                 │
│       Effect text here.         │ ← Effect (if any)
│                                 │
│  ─────────────────────────────  │
│                                 │
│  🎯 Random     │   📍 Any Ring  │ ← Target + Ring
│                                 │
├─────────────────────────────────┤
│  CATEGORY              Tier 🟩  │ ← Category tag(s) + Tier
└─────────────────────────────────┘
```

### Type Icons

| Type | Icon |
|------|------|
| Kinetic | 🔫 |
| Thermal | 🔥 |
| Arcane | ✨ |

### Tier Borders

| Tier | Color |
|------|-------|
| Tier 1 | Gray ⬜ |
| Tier 2 | Green 🟩 |
| Tier 3 | Blue 🟦 |
| Tier 4 | Gold 🟨 |

---

## Standardized Card Effects

### Damage Modifiers

| Effect | Format | Icon |
|--------|--------|------|
| Splash | +X splash | 💥 |
| Multi-hit | Hits X times | 🔄 |
| Multi-target | Hits X enemies | 👥 |
| Can repeat | Can hit same target | 🔁 |

### Debuffs

| Effect | Format | Icon |
|--------|--------|------|
| Hex | Apply X Hex | ☠️ |
| Burn | Apply X Burn | 🔥 |

### Self Effects (Positive)

| Effect | Format | Icon |
|--------|--------|------|
| Heal | Heal X | ❤️ |
| Gain Armor | Gain X armor | 🛡️ |
| Draw | Draw X | 📜 |
| Energy | +X energy | ⚡ |
| Cost reduce | Next card -X cost | ⬇️ |

### Self Effects (Negative)

| Effect | Format | Icon |
|--------|--------|------|
| Self-damage | Take X damage | 💔 |
| Armor cost | Costs X armor | 🛡️⬇️ |
| Discard | Discard X | 🗑️ |

### Control Effects

| Effect | Format | Icon |
|--------|--------|------|
| Push | Push X ring(s) | ➡️ |
| Pull | Pull X ring(s) | ⬅️ |
| Place Barrier | Place barrier | 🚧 |
| Lock | Can't advance | 🔒 |

### Conditionals

| Effect | Format | Icon |
|--------|--------|------|
| HP threshold | +X if below Y% HP | ❤️❓ |
| Ring check | +X if no enemies in Y | 📍❓ |
| Status check | +X if target has Y | ❓ |
| Kill check | If kill: X | 💀 |
| Armor check | +X if you have armor | 🛡️❓ |

### On-Kill Effects

| Effect | Format | Icon |
|--------|--------|------|
| Spread Hex | On kill: spread X Hex | ☠️➡️ |
| Refund | On kill: no self-damage | 💔❌ |
| Chain | On kill: hit another | 🔗 |

### Effect Display Rules

1. **No text needed for:** Basic damage, target type, ring restriction (shown elsewhere)
2. **Text needed for:** Riders (Hex, Burn, Heal), self-costs, conditionals, special mechanics
3. **Simple cards have empty effect area**

---

## Card Tooltip (Hold/Tap Detail View)

When player holds or taps a card, show expanded info:

### Damage Breakdown

```
┌─────────────────────────────────┐
│  SIEGE CANNON - Damage          │
├─────────────────────────────────┤
│  Base Damage:              3    │
│  ─────────────────────────────  │
│  Scaling:                       │
│    80% of Kinetic (20)    +16   │
│    50% of Armor (12)       +6   │
│  ─────────────────────────────  │
│  Subtotal:                 25   │
│  ─────────────────────────────  │
│  Multipliers:                   │
│    Kinetic Bonus (+15%)   ×1.15 │
│    Global Damage (+10%)   ×1.10 │
│  ─────────────────────────────  │
│  FINAL DAMAGE:             31   │
└─────────────────────────────────┘
```

### Effect Glossary

Below the damage breakdown, show glossary entries for any effects on the card:

```
┌─────────────────────────────────┐
│  EFFECT GLOSSARY                │
├─────────────────────────────────┤
│  ☠️ HEX                         │
│  Stacks on enemy. When enemy    │
│  takes damage, deal bonus       │
│  damage equal to Hex stacks.    │
│  Hex is consumed on trigger.    │
├─────────────────────────────────┤
│  🔥 BURN                        │
│  Stacks on enemy. At end of     │
│  each turn, deal Burn damage.   │
│  Burn reduces by 1 each turn.   │
├─────────────────────────────────┤
│  🚧 BARRIER                     │
│  Placed on a ring. When enemy   │
│  crosses, barrier deals damage  │
│  and loses 1 use.               │
└─────────────────────────────────┘
```

### Full Glossary Reference

| Effect | Description |
|--------|-------------|
| ☠️ **Hex** | Stacks on enemy. When damaged, deal bonus damage = Hex stacks. Consumed on trigger. |
| 🔥 **Burn** | Stacks on enemy. End of turn: deal Burn damage. Reduces by 1 each turn. |
| 🚧 **Barrier** | Placed on ring. Enemy crosses: deal damage, lose 1 use. Gone at 0 uses. |
| 🛡️ **Armor** | Blocks damage before HP. Persists until used. |
| ➡️ **Push** | Move enemy 1 ring away from player (toward Far). |
| ⬅️ **Pull** | Move enemy 1 ring toward player (toward Melee). |
| 🔒 **Lock** | Affected enemies cannot advance this turn. |
| 💔 **Self-Damage** | You take this damage when playing the card. |
| 💥 **Splash** | Bonus damage dealt to other enemies in same group. |
| 🔄 **Multi-hit** | Card hits multiple times. Each hit can crit separately. |

### Tooltip Shows Only Relevant Entries

- Hex Bolt tooltip shows: Damage breakdown + Hex glossary
- Barrier Shot tooltip shows: Damage breakdown + Barrier glossary
- Pistol tooltip shows: Damage breakdown only (no special effects)

---

## Wave Compositions (Level 1)

### Wave Format
- **Groups**: Enemies spawn in separate groups across lanes
- **Spawn Timing**: Not all enemies at once - reinforcements on later turns
- **Horde Feel**: Multiple groups create surrounded feeling

---

### Wave 1 - Tutorial
```
Turn 1:
└── Group A: 3× Weakling (Far, spread)
```

### Wave 2 - Introduction
```
Turn 1:
├── Group A: 2× Weakling (Far, Lane 3)
└── Group B: 2× Weakling (Far, Lane 9)
Turn 2:
└── Group C: 2× Cultist (Far, Lane 6)
```

### Wave 3 - First Real Wave
```
Turn 1:
├── Group A: 2× Husk (Far, Lane 2)
├── Group B: 2× Husk (Far, Lane 6)
└── Group C: 2× Husk (Far, Lane 10)
Turn 3:
└── Group D: 3× Cultist (Far, Lane 6)
```

### Wave 4 - Speed Pressure
```
Turn 1:
├── Group A: 2× Husk (Far, Lane 3)
└── Group B: 2× Husk (Far, Lane 9)
Turn 2:
├── Group C: 1× Spinecrawler (Far, Lane 1)
└── Group D: 1× Spinecrawler (Far, Lane 11)
Turn 4:
└── Group E: 2× Husk (Far, Lane 6)
```

### Wave 5 - Ranged Introduction
```
Turn 1:
├── Group A: 2× Spitter (Far, Lane 4)
└── Group B: 2× Spitter (Far, Lane 8)
Turn 2:
├── Group C: 2× Husk (Far, Lane 2)
└── Group D: 2× Husk (Far, Lane 10)
Turn 4:
└── Group E: 3× Cultist (Far, Lane 6)
```

### Wave 6 - Pincer
```
Turn 1:
├── Group A: 3× Husk (Far, Lane 1)
└── Group B: 3× Husk (Far, Lane 11)
Turn 2:
└── Group C: 2× Spinecrawler (Far, Lane 6)
Turn 4:
├── Group D: 1× Spitter (Far, Lane 4)
└── Group E: 1× Spitter (Far, Lane 8)
```

### Wave 7 - Bomber Introduction
```
Turn 1:
├── Group A: 2× Husk (Far, Lane 3)
├── Group B: 2× Husk (Far, Lane 9)
└── Group C: 1× Bomber (Far, Lane 6)
Turn 3:
├── Group D: 3× Cultist (Far, Lane 2)
└── Group E: 3× Cultist (Far, Lane 10)
Turn 5:
└── Group F: 1× Bomber (Far, Lane 6)
```

### Wave 8 - Buffer Introduction
```
Turn 1:
├── Group A: 2× Husk (Far, Lane 4)
├── Group B: 2× Husk (Far, Lane 8)
└── Group C: 1× Torchbearer (Far, Lane 6)
Turn 3:
├── Group D: 1× Spinecrawler (Far, Lane 2)
└── Group E: 1× Spinecrawler (Far, Lane 10)
Turn 5:
└── Group F: 2× Husk (Far, Lane 6)
```

### Wave 9 - Stress Test
```
Turn 1:
├── Group A: 2× Spitter (Far, Lane 3)
├── Group B: 2× Spitter (Far, Lane 9)
└── Group C: 2× Bomber (Far, Lane 6)
Turn 2:
├── Group D: 2× Husk (Far, Lane 1)
└── Group E: 2× Husk (Far, Lane 11)
Turn 4:
└── Group F: 1× Torchbearer (Far, Lane 6)
```

### Wave 10 - Spawner Introduction (HORDE)
```
Turn 1:
├── Group A: 3× Husk (Far, Lane 2)
├── Group B: 3× Husk (Far, Lane 6)
├── Group C: 3× Husk (Far, Lane 10)
└── Group D: 1× Channeler (Far, Lane 6)
Turn 3:
├── Group E: 3× Cultist (Far, Lane 1)
└── Group F: 3× Cultist (Far, Lane 11)
```

### Wave 11 - Tank Introduction
```
Turn 1:
├── Group A: 1× Shell Titan (Far, Lane 6)
├── Group B: 2× Husk (Far, Lane 3)
└── Group C: 2× Husk (Far, Lane 9)
Turn 3:
├── Group D: 1× Spitter (Far, Lane 2)
└── Group E: 1× Spitter (Far, Lane 10)
Turn 5:
└── Group F: 2× Husk (Far, Lane 6)
```

### Wave 12 - Ambush Wave
```
Turn 1:
├── Group A: 2× Husk (Far, Lane 4)
└── Group B: 2× Husk (Far, Lane 8)
Turn 2:
├── Group C: 1× Stalker (Close, Lane 2)
└── Group D: 1× Stalker (Close, Lane 10)
Turn 4:
└── Group E: 2× Spinecrawler (Far, Lane 6)
```

### Wave 13 - Elite Mix
```
Turn 1:
├── Group A: 1× Torchbearer (Far, Lane 4)
├── Group B: 1× Channeler (Far, Lane 8)
└── Group C: 2× Husk (Far, Lane 6)
Turn 2:
├── Group D: 2× Spitter (Far, Lane 2)
└── Group E: 2× Spitter (Far, Lane 10)
Turn 4:
├── Group F: 1× Bomber (Far, Lane 4)
└── Group G: 1× Bomber (Far, Lane 8)
```

### Wave 14 - Fortress Breaker
```
Turn 1:
├── Group A: 2× Armor Reaver (Far, Lane 6)
├── Group B: 2× Husk (Far, Lane 3)
└── Group C: 2× Husk (Far, Lane 9)
Turn 3:
├── Group D: 2× Spinecrawler (Far, Lane 2)
└── Group E: 2× Spinecrawler (Far, Lane 10)
```

### Wave 15 - Heavy Assault
```
Turn 1:
├── Group A: 1× Shell Titan (Far, Lane 3)
├── Group B: 1× Shell Titan (Far, Lane 9)
└── Group C: 1× Torchbearer (Far, Lane 6)
Turn 2:
├── Group D: 3× Husk (Far, Lane 1)
└── Group E: 3× Husk (Far, Lane 11)
Turn 4:
└── Group F: 3× Cultist (Far, Lane 6)
```

### Wave 16 - Cultist Horde (HORDE)
```
Turn 1:
├── Group A: 4× Cultist (Far, Lane 2)
├── Group B: 4× Cultist (Far, Lane 6)
└── Group C: 4× Cultist (Far, Lane 10)
Turn 2:
├── Group D: 2× Bomber (Far, Lane 4)
└── Group E: 2× Bomber (Far, Lane 8)
Turn 3:
└── Group F: 1× Channeler (Far, Lane 6)
```

### Wave 17 - Double Tank
```
Turn 1:
├── Group A: 1× Shell Titan (Far, Lane 4)
├── Group B: 1× Shell Titan (Far, Lane 8)
├── Group C: 1× Torchbearer (Far, Lane 6)
└── Group D: 2× Spitter (Far, Lane 1)
Turn 3:
└── Group E: 2× Armor Reaver (Far, Lane 6)
Turn 5:
└── Group F: 2× Stalker (Close, Lane 3, Lane 9)
```

### Wave 18 - Gauntlet (HORDE)
```
Turn 1:
├── Group A: 3× Husk (Far, Lane 2)
├── Group B: 3× Husk (Far, Lane 6)
├── Group C: 3× Husk (Far, Lane 10)
└── Group D: 1× Channeler (Far, Lane 6)
Turn 2:
├── Group E: 2× Spinecrawler (Far, Lane 1)
└── Group F: 2× Spinecrawler (Far, Lane 11)
Turn 3:
├── Group G: 1× Torchbearer (Far, Lane 4)
└── Group H: 1× Torchbearer (Far, Lane 8)
Turn 5:
└── Group I: 2× Stalker (Close, spread)
```

### Wave 19 - Pre-Boss
```
Turn 1:
├── Group A: 1× Shell Titan (Far, Lane 6)
├── Group B: 2× Bomber (Far, Lane 4)
└── Group C: 2× Bomber (Far, Lane 8)
Turn 2:
├── Group D: 2× Spinecrawler (Far, Lane 2)
└── Group E: 2× Spinecrawler (Far, Lane 10)
Turn 3:
└── Group F: 1× Channeler (Far, Lane 6)
Turn 5:
├── Group G: 1× Armor Reaver (Far, Lane 3)
└── Group H: 1× Armor Reaver (Far, Lane 9)
```

### Wave 20 - BOSS: Ember Saint
```
Turn 1:
├── Group A: 1× Ember Saint (Far, Lane 6)
├── Group B: 2× Husk (Far, Lane 4)
└── Group C: 2× Husk (Far, Lane 8)

Boss Spawns (every 3 turns):
└── 2× Husk + 1× Bomber (Far, random lanes)

At 50% HP:
└── 1× Shell Titan (Far, Lane 6)
```

---

### Wave Summary

| Wave | Enemies | Groups | Spawn Turns | Feel |
|------|---------|--------|-------------|------|
| 1 | 3 | 1 | 1 | Tutorial |
| 2 | 6 | 3 | 1, 2 | Easy |
| 3 | 9 | 4 | 1, 3 | Medium |
| 4 | 8 | 5 | 1, 2, 4 | Medium |
| 5 | 11 | 5 | 1, 2, 4 | Medium |
| 6 | 10 | 5 | 1, 2, 4 | Medium |
| 7 | 12 | 6 | 1, 3, 5 | High |
| 8 | 8 | 6 | 1, 3, 5 | Medium |
| 9 | 11 | 6 | 1, 2, 4 | High |
| 10 | 16 | 6 | 1, 3 | HORDE |
| 11 | 9 | 6 | 1, 3, 5 | Medium |
| 12 | 8 | 5 | 1, 2, 4 | Ambush |
| 13 | 11 | 7 | 1, 2, 4 | High |
| 14 | 10 | 5 | 1, 3 | Medium |
| 15 | 12 | 6 | 1, 2, 4 | High |
| 16 | 17 | 6 | 1, 2, 3 | HORDE |
| 17 | 12 | 6 | 1, 3, 5 | High |
| 18 | 18 | 9 | 1, 2, 3, 5 | HORDE |
| 19 | 12 | 8 | 1, 2, 3, 5 | High |
| 20 | 5+ | Boss | Ongoing | BOSS |

---

## Next Steps

1. **Wardens** - Starting stats and passives
