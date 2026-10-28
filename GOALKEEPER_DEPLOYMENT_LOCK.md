# 🔒 GOALKEEPER DEPLOYMENT LOCK - FINAL FIX

## Rule
**Goalkeepers CANNOT be repositioned during deployment phase after placement.**

Once you place a goalkeeper, it's locked in that position. You cannot click it to move it to another cell.

## Implementation

**File:** `src/app/game/[roomCode]/page.tsx`  
**Location:** Lines 3559-3575 (piece onClick handlers in renderCell)

### Fix Applied

Added goalkeeper lock check in piece click handlers:

```typescript
onClick={e => {
  e.stopPropagation()
  if (vMove || vDep) clickCell(col, row)
  else {
    // GOALKEEPER LOCK: Cannot reposition GK during deployment
    if (gs.phase === 'deployment' && piece.type === 'GK') {
      console.log('[DEPLOYMENT] Goalkeeper cannot be moved after placement')
      return  // Block click, do nothing
    }
    clickPiece(piece)
  }
}}
```

Same check added to keyboard handler (`onKeyDown`).

## Behavior

### ✅ Deployment Phase
- **First placement:** Can place goalkeeper in any goal zone cell
- **After placement:** ❌ **CANNOT click goalkeeper to reposition it**
- **Other pieces:** ✅ Can still be clicked and repositioned normally
- **Goalkeeper is locked** until deployment ends

### ✅ Match Phase
- **Goalkeeper CAN move** 2 cells left/right in goal zone
- Normal movement like before

## Expected User Experience

### Scenario: Place Goalkeeper During Deployment

1. **Select GK from piece palette**
2. **Click on goal zone cell** (e.g., C0)
3. **Goalkeeper appears on board** ✅
4. **Try to click goalkeeper again**
5. **❌ Nothing happens** - goalkeeper is locked
6. **Console shows:** `[DEPLOYMENT] Goalkeeper cannot be moved after placement`

### Scenario: Other Pieces

1. **Select Defender from palette**
2. **Click on field cell** (e.g., A2)
3. **Defender appears** ✅
4. **Click defender again**
5. **✅ Defender is selected** - can be repositioned
6. **Click another cell** - defender moves there

### Scenario: Match Phase Movement

1. **Match phase begins**
2. **Select goalkeeper**
3. **✅ Movement highlights appear** (2 cells left/right)
4. **Click destination** - goalkeeper moves ✅

## Why This Rule?

**Strategic commitment:** Forces players to choose goalkeeper position carefully during deployment.

**Prevents mistakes:** Can't accidentally move goalkeeper when trying to reposition other pieces.

**Matches intention:** Goalkeepers defend a fixed zone, not roam the field.

## Testing

### Test 1: Goalkeeper Lock During Deployment
1. Create game, enter deployment phase
2. Place goalkeeper at any goal zone cell (e.g., C0)
3. **Click goalkeeper**
4. **Expected:** Nothing happens, no movement options
5. **Console:** `[DEPLOYMENT] Goalkeeper cannot be moved after placement`

### Test 2: Other Pieces Still Movable
1. Place a Defender at A2
2. **Click defender**
3. **Expected:** Defender is selected
4. **Click another cell** (e.g., B3)
5. **Expected:** Defender moves to B3 ✅

### Test 3: Goalkeeper Moves in Match
1. Complete deployment, start match
2. Your turn, click goalkeeper
3. **Expected:** Green movement highlights appear (2 cells left/right)
4. **Click destination**
5. **Expected:** Goalkeeper moves ✅

## Files Modified

- ✅ `src/app/game/[roomCode]/page.tsx` (Lines 3559-3575)
  - Added deployment phase + GK type check in onClick
  - Added same check in onKeyDown

## Status
✅ **DEPLOYED**

Server restarted, all caches cleared.

---

**Now refresh browser and test goalkeeper placement!** 🧤
