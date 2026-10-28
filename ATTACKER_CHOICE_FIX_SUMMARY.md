# ✅ ATTACKER CHOICE BUTTONS - BUG FIX COMPLETE

## 🐛 Bug Description
When an attacker reached the opponent's goal zone (row 0 for Team 1, row 6 for Team 2), the STAY/SHOOT buttons did NOT appear.

## 🔍 Root Causes Found

### 1. **Wrong Goal Zone Row Numbers** ⚠️
**File:** `src/app/game/[roomCode]/page.tsx` Line 398  
**Problem:**
```typescript
// WRONG - Checked rows 1 and 5 instead of goal zones!
const triggersShoot = (p: Piece) =>
  p.type === 'A' && ((p.team === 1 && p.row === 1) || (p.team === 2 && p.row === 5))
```

**Fix:**
```typescript
// CORRECT - Goal zones are rows 0 and 6
const triggersShoot = (p: Piece) =>
  p.type === 'A' && ((p.team === 1 && p.row === 0) || (p.team === 2 && p.row === 6))
```

### 2. **Attackers Couldn't Reach Goal Zones** ⚠️
**File:** `src/app/game/[roomCode]/page.tsx` Lines 253-275  
**Problem:**
```typescript
// WRONG - All pieces restricted to rows 1-5
if (nr < 1 || nr > 5 || nc < 0 || nc >= 4) continue
```

**Fix:**
```typescript
// CORRECT - Attackers can enter goal zones (rows 0 and 6)
const minRow = p.type === 'A' ? 0 : 1
const maxRow = p.type === 'A' ? 6 : 5

if (nr < minRow || nr > maxRow || nc < 0 || nc >= 4) continue
```

### 3. **Solo Mode Captain Detection** ⚠️
**File:** `src/app/game/[roomCode]/page.tsx` Lines 3700, 3765  
**Problem:** Buttons only showed if `controllerPlayerId === currentUserId`, but in solo mode pieces don't have controllers assigned.

**Fix:** Added captain check:
```typescript
// Initial choice (STAY or SHOOT)
const shouldShowControls = iAmAttackerController || (atk?.team === myTeam && isCaptain)

// Later SHOOT button (when attacker stayed)
const canShoot = selectedPiece && selectedPiece.readyToShoot && gs.turn === myTeam && 
  (iAmPieceController || (selectedPiece.team === myTeam && isCaptain))
```

---

## ✅ Complete Fix Summary

| Fix # | Location | Description | Status |
|-------|----------|-------------|--------|
| 1 | Line 398 | `triggersShoot` now checks rows 0 and 6 | ✅ Fixed |
| 2 | Lines 253-275 | Attackers can move to goal zones | ✅ Fixed |
| 3 | Line 3700 | Initial STAY/SHOOT buttons show for captain | ✅ Fixed |
| 4 | Line 3765 | Later SHOOT button shows for captain | ✅ Fixed |

---

## 📋 How The Feature Works Now

### **1. Attacker Reaches Goal Zone (First Time)**
- Attacker moves to row 0 (Team 1) or row 6 (Team 2)
- Combat happens if defender present
- **If attacker wins OR no defender:** Two buttons appear:
  - 🛡️ **STAY IN POSITION**: Attacker stays, turn ends, snitch counter +1
  - ⚽ **SHOOT GOAL**: Triggers goal duel immediately

### **2. Attacker Chooses STAY**
- Attacker remains in goal zone
- `readyToShoot` flag set to `true`
- Turn ends normally
- Snitch counter increments by 1

### **3. Click Attacker on Later Turn**
- Player clicks the attacker (still in goal zone)
- ⚽ **SHOOT GOAL** button appears
- Can shoot at any time, no forced shot
- No limit on how many turns attacker can stay

### **4. Both Options Count as Moves**
- "STAY" = 1 move toward snitch's 4-move trigger
- "SHOOT" = 1 move toward snitch's 4-move trigger
- On the 4th move, snitch appears correctly

---

## 🎮 User Experience

### For Team Mode (7 players/team):
- **Only the piece controller** sees buttons
- Other players see: "⏳ Waiting for [PlayerName] to choose..."
- Server validates that only the controller can act

### For Solo Mode (1 player controls all):
- **Captain sees ALL buttons** (captain fallback enabled)
- Works because `isCaptain = true` in solo mode
- No "waiting" message since captain controls everything

---

## 🧪 Testing Requirements

### Test 1: Buttons Appear
1. Move attacker to goal zone (row 0 or 6)
2. Win combat (if defender present)
3. ✅ **Expected:** STAY and SHOOT buttons appear

### Test 2: STAY Works
1. Click "STAY IN POSITION"
2. ✅ **Expected:**
   - Attacker remains in goal zone
   - Turn ends
   - Snitch counter increments
   - Buttons disappear

### Test 3: SHOOT Works  
1. Click "SHOOT GOAL"
2. ✅ **Expected:**
   - Goal duel starts
   - Goalkeeper chooses
   - Result shown (goal or save)
   - Score updates once

### Test 4: Click Attacker Later
1. Attacker stayed in position (previous turn)
2. New turn starts
3. Click the attacker piece
4. ✅ **Expected:** "SHOOT GOAL" button appears

### Test 5: Snitch Trigger
1. Make 3 moves (any combination of STAY/SHOOT)
2. On 4th move (STAY or SHOOT)
3. ✅ **Expected:** "✨ THE SNITCH APPEARS!" message

### Test 6: Solo Mode
1. Create solo room
2. Reach goal zone with attacker
3. ✅ **Expected:** Captain sees buttons immediately

### Test 7: No Duplicate Actions
1. Two players in same room
2. One clicks SHOOT, other tries to click
3. ✅ **Expected:** Server only accepts player whose turn it is

---

## 🚀 Server Status

**Running:** http://localhost:3000  
**Build:** Fresh compilation with all fixes  
**Cache:** Cleared

---

## 🎯 Next Steps

1. **Clear browser cache:** `Ctrl + Shift + R` (hard refresh)
2. **Open:** http://localhost:3000
3. **Create solo room**
4. **Test scenario:**
   - Deploy pieces
   - Move attacker to opponent's goal zone
   - Verify buttons appear
   - Test STAY option
   - Test SHOOT option
   - Test clicking attacker on later turn

---

## 📊 Expected Behavior Summary

| Scenario | Expected UI | Button Behavior |
|----------|-------------|-----------------|
| Attacker reaches goal (first time) | STAY + SHOOT buttons | Both clickable |
| Player clicks STAY | Buttons disappear | Turn ends, counter +1 |
| Player clicks SHOOT | Duel UI appears | Keeper chooses, result shown |
| Attacker in goal (later turn) | SHOOT button only | Clickable any turn |
| Wrong team's turn | No buttons | Disabled/hidden |
| Non-captain (team mode) | Waiting message | Cannot click |
| Captain (solo mode) | All buttons | Full control |

---

## ⚠️ Important Notes

1. **Goal zones are rows 0 and 6** (not 1 and 5!)
2. **Attackers are the ONLY pieces** that can enter goal zones
3. **Solo mode uses captain fallback** for all buttons
4. **Team mode validates piece controllers** via server
5. **Snitch counter increments** for BOTH "stay" and "shoot"
6. **No forced shooting** - attacker can stay forever

---

## 🎉 Ready to Test!

All fixes are deployed and server is running. The attacker choice feature should now work correctly in both solo and team modes!

