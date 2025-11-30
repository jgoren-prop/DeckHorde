# Combat Clarity System - Design Document

## Problem Statement

In horde-based combat, players face cognitive overload when tracking many enemy types simultaneously. Unlike Slay the Spire where you read 1-3 enemy intents, Riftwardens requires tracking hordes with varied behaviors:
- Rushers that advance until melee
- Ranged units that stop at mid-range
- Bombers that explode on death
- Buffers that strengthen others
- Spawners that create reinforcements

**Goal**: Make the battlefield instantly readable at a glance while preserving tactical depth.

---

## Implementation Checklist

### Layer 1: Behavior Badges ✅ IMPLEMENTED
- [x] Define badge icons for each enemy archetype
- [x] Add `behavior_type` enum to EnemyDefinition
- [x] Display badge icon on enemy panels in BattlefieldArena
- [x] Badge appears in top-left corner of enemy panel
- [x] Badge has tooltip data (tooltip text stored in meta)

### Layer 2: Ring Threat Colors ✅ IMPLEMENTED
- [x] Calculate threat level per ring (damage + special threats)
- [x] Color ring borders based on threat (green/yellow/orange/red)
- [x] Update ring colors each turn and after enemy deaths
- [x] Critical rings pulse red when damage would be lethal

### Layer 3: Aggregated Intent Bar ✅ IMPLEMENTED
- [x] Create intent bar UI element at top of combat screen
- [x] Show total incoming melee damage
- [x] Show bomber count and status (highlights if close!)
- [x] Show active buffer/spawner indicators
- [x] Show fast enemy count
- [x] Update intent bar each turn and after card plays

### Layer 4: Turn Preview Timeline (Future)
- [ ] Create expandable sidebar panel
- [ ] Calculate "next turn" events (movement, attacks, abilities)
- [ ] Calculate "in 2 turns" events
- [ ] Show as readable list of upcoming threats
- [ ] Toggle visibility with button or hotkey

### Layer 5: Danger Highlighting (Future)
- [ ] Define "high priority" threat criteria
- [ ] Add pulsing glow effect to high-priority enemies
- [ ] Priority: Bombers about to explode > Enemies reaching melee > Active buffers
- [ ] Configurable in settings (can be disabled)

### Layer 6: Turn Countdown Badges ❌ REMOVED
- Removed in favor of simpler danger highlighting system
- The colored border (Layer 5) provides enough visual feedback without cluttering the UI

### Layer 7: Card Targeting Hints ✅ IMPLEMENTED
- [x] On card hover, highlight effective targets with yellow overlay
- [x] Show damage preview (-X) on each targetable enemy
- [x] Show skull icon (💀) and red highlight on enemies that would die from the card
- [x] Works with stacked enemy groups too

### Layer 8: Event Callouts ✅ IMPLEMENTED
- [x] Flash banner when buffer activates (purple, "📢 TORCHBEARER - Enemies gain +2 damage!")
- [x] Flash banner when spawner creates enemy (cyan, "⚙️ CHANNELER spawned 1 Husk!")
- [x] Flash banner when bomber reaches melee (yellow, "💣 BOMBER in MELEE - will explode for 5 damage!")
- [x] Flash banner when bomber explodes (red-orange, "💥 BOMBER EXPLODED! 5 damage!")
- [x] Banners auto-dismiss after 1.5-2.5 seconds
- [x] Banners queue and display sequentially if multiple events happen at once

---

## Detailed Specifications

### Layer 1: Behavior Badges

Each enemy has a **behavior archetype** that determines its badge:

| Badge | Enum Value | Description | Color | Enemies |
|-------|------------|-------------|-------|---------|
| 🏃 | `RUSHER` | Moves every turn until melee | Red | Husk, Cultist |
| ⚡ | `FAST` | Moves 2+ rings per turn | Orange | Spinecrawler |
| 🏹 | `RANGED` | Stops early, attacks from distance | Blue | Spitter |
| 💣 | `BOMBER` | Explodes on death or reaching melee | Yellow | Bomber |
| 📢 | `BUFFER` | Strengthens nearby enemies | Purple | Torchbearer |
| ⚙️ | `SPAWNER` | Creates additional enemies | Cyan | Channeler |
| 🛡️ | `TANK` | High HP/armor, slow threat | Gray | Shell Titan |
| 🗡️ | `AMBUSH` | Spawns close to player | Pink | Stalker |
| 👑 | `BOSS` | Special mechanics, high danger | Gold | Ember Saint |

**Visual Design:**
- Badge size: 20x20 pixels (scales with panel)
- Position: Top-left corner of enemy panel, 4px padding
- Background: Semi-transparent dark circle
- Border: 1px matching badge color
- Tooltip on hover: "{Enemy Name} - {Behavior Description}"

**Badge Tooltips:**
| Badge | Tooltip Text |
|-------|-------------|
| 🏃 | "Rusher - Advances every turn until reaching melee" |
| ⚡ | "Fast - Moves 2 rings per turn" |
| 🏹 | "Ranged - Stops at distance and attacks from afar" |
| 💣 | "Bomber - Explodes when killed, dealing 6 damage" |
| 📢 | "Buffer - Increases nearby enemy damage by +2" |
| ⚙️ | "Spawner - Creates additional enemies each turn" |
| 🛡️ | "Tank - High health and armor, slow but deadly" |
| 🗡️ | "Ambush - Spawns directly in close range" |
| 👑 | "Boss - Powerful enemy with special abilities" |

---

### Layer 2: Ring Threat Colors

Each ring's border color reflects incoming threat level:

| Threat Level | Color | Hex Code | Criteria |
|--------------|-------|----------|----------|
| Safe | Green | `#50e650` | 0 damage expected |
| Low | Yellow | `#e6e650` | 1-10 damage expected |
| Medium | Orange | `#e69050` | 11-20 damage expected |
| High | Red | `#e65050` | 21+ damage OR bomber present |
| Critical | Pulsing Red | `#ff3030` | Lethal damage (would kill player) |

**Calculation per ring:**
```
ring_threat = sum of (enemy.damage for each enemy that will attack from this ring next turn)

if ring contains bomber about to explode:
    ring_threat += 100  # Force red status

if ring_threat >= player_hp:
    threat_level = CRITICAL
elif ring_threat > 20 or bomber_present:
    threat_level = HIGH
elif ring_threat > 10:
    threat_level = MEDIUM
elif ring_threat > 0:
    threat_level = LOW
else:
    threat_level = SAFE
```

**Visual Design:**
- Ring border thickness: 3px (normal) → 4px (high threat)
- Critical rings pulse between red and bright red (0.5s cycle)
- Color transition: Smooth 0.3s tween when threat changes

---

### Layer 3: Aggregated Intent Bar

A horizontal bar at the top of the combat screen summarizing battlefield state:

```
┌─────────────────────────────────────────────────────────────────────────┐
│  ⚔️ 24 Incoming  │  💣 2 Bombers  │  📢 Buff Active (+2)  │  ⚙️ Spawning  │
└─────────────────────────────────────────────────────────────────────────┘
```

**Sections:**

1. **Incoming Damage** `⚔️ X Incoming`
   - Total damage from all enemies in melee ring
   - Color: White (safe) → Yellow (moderate) → Red (lethal)

2. **Bomber Count** `💣 X Bombers`
   - Count of living bombers on field
   - Hidden if 0
   - Shows ring if any in Close/Melee: `💣 2 Bombers (1 in Close!)`

3. **Buffer Status** `📢 Buff Active (+X)`
   - Shows if any buffer enemy is active (at target ring)
   - Displays total buff amount
   - Hidden if no active buffers

4. **Spawner Status** `⚙️ Spawning`
   - Shows if any spawner will create enemies this turn
   - Hidden if no active spawners

5. **Fast Enemies** `⚡ X Fast Approaching`
   - Count of fast enemies (2+ speed) on field
   - Hidden if 0

**Visual Design:**
- Bar height: 32px
- Background: Semi-transparent dark (`#1a1a1a` at 80% opacity)
- Sections separated by vertical dividers
- Icons are 16x16
- Font: Bold, 14px
- Position: Top of combat area, below wave indicator

**Update Triggers:**
- Start of player turn
- After enemy dies
- After enemy spawns
- After card is played

---

### Layer 4: Turn Preview Timeline (Future Enhancement)

An expandable panel showing upcoming events:

```
┌─ NEXT TURN ──────────────────────────┐
│ → 3 Husks reach MELEE (12 dmg)       │
│ → 1 Bomber reaches CLOSE             │
│ → Channeler spawns 1 Husk            │
│ → Torchbearer buffs 4 enemies (+8)   │
├─ IN 2 TURNS ─────────────────────────┤
│ → 2 Bombers reach MELEE (explode!)   │
│ → Spinecrawler reaches MELEE (6 dmg) │
└──────────────────────────────────────┘
```

**Event Types to Track:**
- Enemy reaches new ring (especially melee)
- Bomber will explode
- Spawner will spawn
- Buffer will activate
- Total damage from ring

**Toggle:** Button in top-right "📅 Preview" or hotkey (Tab?)

---

### Layer 5: Danger Highlighting ✅ IMPLEMENTED

Automatic visual emphasis on high-priority threats:

**Priority Order:**
1. **CRITICAL** (Red glow, 0.4s pulse): Bombers about to explode (in melee or reaching next turn)
2. **HIGH** (Orange glow, 0.6s pulse): Any enemy reaching melee next turn
3. **MEDIUM** (Purple glow, 0.8s pulse): Active buffers/spawners at target ring
4. **LOW** (Cyan glow, 1.0s pulse): Fast enemies (speed 2+) not yet close

**Visual Effect:**
- [x] Pulsing glow border around enemy panel
- [x] Outer shadow glow effect for visibility
- [x] Glow color matches threat type
- [x] Pulse rate varies by urgency (faster = more dangerous)
- [x] Updates on turn start and enemy movement
- [x] Works with both individual and stacked enemy panels

---

### Layer 6: Movement Ghosts (Future Enhancement)

Show where enemies will be next turn:

- Semi-transparent (30% opacity) duplicate of enemy panel
- Positioned in the ring they will occupy next turn
- Small badge showing turns until melee: "→2" means "reaches melee in 2 turns"

**Alternative:** Just show the turn countdown badge without ghosts (simpler)

---

### Layer 7: Card Targeting Hints (Future Enhancement)

When hovering over a card in hand:

- Highlight enemies the card can target
- For AoE cards, show damage preview per ring
- Highlight enemies that would die (skull icon overlay)
- Show ring selection preview for "choose ring" cards

---

### Layer 8: Event Callouts (Future Enhancement)

Brief banner notifications for important events:

| Event | Banner Text | Duration |
|-------|-------------|----------|
| Buffer activates | "📢 TORCHBEARER - Enemies gain +2 damage!" | 2s |
| Spawner spawns | "⚙️ CHANNELER spawned a Husk!" | 1.5s |
| Bomber armed | "💣 BOMBER reaching melee - will explode!" | 2s |
| Boss phase change | "👑 EMBER SAINT - Phase 2!" | 2.5s |

**Visual Design:**
- Center-top of screen, below intent bar
- Slide in from top, fade out
- Background matches threat type color
- Can stack up to 2 banners

---

## Implementation Order

### Phase 1 (Current Sprint)
1. ✅ Create this design document
2. [ ] Add `behavior_type` to EnemyDefinition
3. [ ] Implement behavior badges on enemy panels
4. [ ] Implement ring threat color system
5. [ ] Implement aggregated intent bar

### Phase 2 (Next Sprint)
6. [ ] Add turn preview timeline
7. [ ] Add danger highlighting
8. [ ] Add movement ghost/countdown badges

### Phase 3 (Polish Sprint)
9. [ ] Add card targeting hints
10. [ ] Add event callout banners
11. [ ] Add settings toggles for all features
12. [ ] Tutorial/legend for first-time players

---

## Testing Checklist

After implementation, verify:

- [x] Badges display correctly for all 10 enemy types (unit tests pass)
- [x] Ring colors update when enemies move/die (signal handlers connected)
- [x] Intent bar shows accurate damage calculation (unit tests pass)
- [x] Intent bar updates after card plays (_update_ui called)
- [x] Bomber indicator appears when bombers on field (behavior_type check)
- [x] Buffer indicator shows when Torchbearer is active (position-based check)
- [x] Spawner indicator shows when Channeler is active (position-based check)
- [ ] System performs well with 20+ enemies on field (needs manual testing)
- [ ] All features work with enemy stacking system (needs manual testing)

### Unit Tests Added
- `_run_behavior_type_tests()` - Tests all 10 enemy behavior type assignments
- `_run_intent_bar_tests()` - Tests threat calculation and enemy counting

---

## Notes

- All new UI elements should respect the existing dark theme
- Badge colors should be distinct for colorblind accessibility
- Consider adding a "Clarity Settings" section in Settings menu
- Intent bar should not overlap with existing threat preview

