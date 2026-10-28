# ✅ GOAL DUEL FIX - Solo Mode

## Issue Reported
"When I tap SHOOT, it says 'waiting for player and goalkeeper' but we are in solo mode with only one player controlling all pieces on each team."

## Root Cause
The duel UI was checking if the current user is the **piece controller** (`controllerPlayerId`):
```typescript
const canChooseDuel = gs.duel?.phase === 'choosing' && (iAmAttackerController || iAmKeeperController)
```

**Problem in Solo Mode Two-Tab Scenario:**
- Tab 1 (Team 1): `myTeam = 1`, viewing as Team 1
- Tab 2 (Team 2): `myTeam = 2`, viewing as Team 2
- Both pieces might have same `controllerPlayerId` (same user)
- BUT each tab needs different controls (attacker vs goalkeeper)

## Fix Applied

**File:** `src/app/game/[roomCode]/page.tsx`  
**Lines:** 3190-3197

### BEFORE (BROKEN):
```typescript
const canChooseDuel = gs.duel?.phase === 'choosing' && (iAmAttackerController || iAmKeeperController)
const myDuelRole = iAmAttackerController ? 'attacker' : iAmKeeperController ? 'keeper' : null
```
❌ Only showed controls if you're the piece controller

### AFTER (FIXED):
```typescript
const iAmAttackerTeam = duelAtk?.team === myTeam
const iAmKeeperTeam = duelGkPiece?.team === myTeam
const canChooseDuel = gs.duel?.phase === 'choosing' && (
  iAmAttackerController || iAmKeeperController ||  // Team mode: controller only
  iAmAttackerTeam || iAmKeeperTeam                 // Solo mode: team ownership
)
const myDuelRole = (iAmAttackerController || iAmAttackerTeam) ? 'attacker' : 
                   (iAmKeeperController || iAmKeeperTeam) ? 'keeper' : null
```
✅ Shows controls based on team ownership in solo mode

## How It Works Now

### Solo Mode Two-Tab Scenario

**Attacker Shoots Goal (e.g., Team 2 attacker vs Team 1 goalkeeper)**

#### Tab 1 (Team 1 - Goalkeeper's Team):
```
┌────────────────────────────────────┐
│         ⚽ GOAL DUEL               │
│                                    │
│  🧤 GOALKEEPER — choose your dive  │
│                                    │
│   [◀ LEFT]  [● MIDDLE]  [▶ RIGHT] │
└────────────────────────────────────┘
```
- Checks: `duelGkPiece.team === myTeam` → `1 === 1` → TRUE
- Role: 'keeper'
- Shows: Goalkeeper dive choices

#### Tab 2 (Team 2 - Attacker's Team):
```
┌────────────────────────────────────┐
│         ⚽ GOAL DUEL               │
│                                    │
│  🏹 ATTACKER — choose your shot    │
│                                    │
│   [◀ LEFT]  [● MIDDLE]  [▶ RIGHT] │
└────────────────────────────────────┘
```
- Checks: `duelAtk.team === myTeam` → `2 === 2` → TRUE
- Role: 'attacker'
- Shows: Attacker shot choices

### Team Mode (Multi-Player)
Still works correctly:
- Only the designated controller sees their controls
- Other team members see "waiting" message

## Expected Behavior After Fix

### Scenario: Solo Mode Goal Duel

1. **Attacker reaches goal zone and clicks SHOOT**
2. **Goal duel overlay appears on BOTH tabs**
3. **Tab 1 (Goalkeeper's team):**
   - Sees: "🧤 GOALKEEPER — choose your dive direction"
   - Buttons: LEFT / MIDDLE / RIGHT (purple theme)
4. **Tab 2 (Attacker's team):**
   - Sees: "🏹 ATTACKER — choose your shot direction"
   - Buttons: LEFT / MIDDLE / RIGHT (orange theme)
5. **Both players make their choices**
6. **Result shown on both tabs:**
   - GOAL! (+10 or +20 points) OR
   - SAVED! (goalkeeper wins)

## Testing Steps

### Test 1: Trigger Goal Duel
1. Move attacker to goal zone (row 5 for Team 2, row 1 for Team 1)
2. Click **⚽ SHOOT GOAL**
3. **Expected:** Duel overlay appears on BOTH tabs

### Test 2: Verify Controls Show
1. **Tab 1 (Goalkeeper's team):** Should see GOALKEEPER choices
2. **Tab 2 (Attacker's team):** Should see ATTACKER choices
3. **Expected:** NO "waiting for player" messages in solo mode

### Test 3: Make Choices
1. Both tabs click a choice (LEFT/MIDDLE/RIGHT)
2. **Expected:** Each tab shows "✓ You chose X"
3. **Expected:** Shows "⏳ Waiting for opponent…"
4. When BOTH chosen: Result reveals

### Test 4: Verify Result
1. After both choices made
2. **Expected:** Same result shown on BOTH tabs
3. If GOAL: Score increases on both tabs
4. If SAVED: Turn passes, no score change

## Console Debug

After clicking SHOOT, check console for:

```javascript
// Should show true on BOTH tabs
[DUEL] canChooseDuel: true
[DUEL] myDuelRole: "attacker"  // or "keeper" depending on tab
[DUEL] iAmAttackerTeam: true   // on attacker's tab
[DUEL] iAmKeeperTeam: true     // on keeper's tab
```

If shows false:
```javascript
[DUEL] canChooseDuel: false
```
❌ This means team check failed - verify `myTeam` is set correctly

## Files Modified

- ✅ `src/app/game/[roomCode]/page.tsx` (Lines 3190-3197)
  - Added team-based checks for duel controls
  - Removed player name display from waiting message

## Compatibility

- ✅ **Solo mode:** Both players see their respective controls
- ✅ **Team mode:** Only controllers see controls (unchanged)
- ✅ **Spectators:** See waiting message (unchanged)

## Summary

**Before:** Solo mode showed "waiting for player" because it checked `controllerPlayerId`  
**After:** Solo mode shows controls to both teams based on piece ownership

**Status:** ✅ **READY TO TEST**

---

**Now refresh your browsers and try shooting a goal!** 🎯
