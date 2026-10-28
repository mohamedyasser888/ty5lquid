# 🔒 GOALKEEPER MOVEMENT LOCK

## Rule
**Goalkeepers (GK) cannot move from their position during the match phase.**

They must stay exactly where they were placed during deployment.

## Implementation

**File:** `src/app/game/[roomCode]/page.tsx`  
**Function:** `movable()` (Line 231-237)

### BEFORE (ALLOWED MOVEMENT):
```typescript
if (p.type === 'GK') {
  const goalIndex = GOAL_ZONE_COLS.indexOf(p.col)
  // Allow 2 cells left
  for (let d = 1; d <= 2; d++) {
    const lc = goalIndex - d
    if (lc < 0 || getOcc(ps, GOAL_ZONE_COLS[lc], p.row).length >= MAX_PIECES_PER_CELL) break
    out.push(`${GOAL_ZONE_COLS[lc]}${p.row}`)
  }
  // Allow 2 cells right
  for (let d = 1; d <= 2; d++) {
    const rc = goalIndex + d
    if (rc >= GOAL_ZONE_COLS.length || getOcc(ps, GOAL_ZONE_COLS[rc], p.row).length >= MAX_PIECES_PER_CELL) break
    out.push(`${GOAL_ZONE_COLS[rc]}${p.row}`)
  }
  return out
}
```
❌ Goalkeeper could move 2 cells in goal zone

### AFTER (NO MOVEMENT):
```typescript
// Goalkeepers CANNOT move during match phase (stay in their zone)
if (p.type === 'GK') {
  return []  // No valid moves for goalkeeper
}
```
✅ Goalkeeper stays locked in place

## Expected Behavior

### Deployment Phase
- ✅ Can place goalkeeper in any goal zone cell (row 0 or 6)
- ✅ Goalkeeper is positioned where you place them

### Match Phase
- ✅ Clicking goalkeeper shows NO movement highlights
- ✅ Goalkeeper cannot be moved at all
- ✅ Goalkeeper stays in their deployment position
- ✅ Goalkeeper still defends during goal duels

## Testing

### Test 1: Try to Move Goalkeeper
1. Start match phase
2. Click on your goalkeeper
3. **Expected:** No green movement highlights appear
4. **Expected:** Goalkeeper cannot move

### Test 2: Verify Other Pieces Can Move
1. Click on Defender, Attacker, or Seeker
2. **Expected:** Green movement highlights appear normally
3. **Expected:** Those pieces can move

### Test 3: Goal Duel Still Works
1. Attacker shoots at goal
2. **Expected:** Goalkeeper still participates in duel
3. **Expected:** Goalkeeper can choose LEFT/MIDDLE/RIGHT
4. **Expected:** Save or Goal result works correctly

## Why This Rule?

**Realism:** In real Quidditch, goalkeepers defend their hoops and don't roam the field.

**Balance:** Prevents goalkeeper from moving out of position.

**Strategy:** Forces players to place goalkeeper wisely during deployment.

## Status
✅ **IMPLEMENTED AND DEPLOYED**

All caches cleared, server restarted fresh.

---

**Now refresh your browser and test!** 🧤
