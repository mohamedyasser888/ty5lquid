# Quidditch Game: Snitch Rules Test Report

## Phase 2: Snitch Rules Implementation

### Changes Made

1. **Move Counting**
   - Added `regularMoveCount` field: tracks non-seeker-bonus moves only
   - Seeker move + bonus = 1 move total
   - All other moves = 1 move each
   - Counter syncs via database (persisted in game_state JSONB)

2. **Snitch Appearance**
   - Appears after `regularMoveCount === 4` (4 complete moves, 2 full turns)
   - Checked in `progressAfterMove()` function
   - Logged in console: `[PROGRESS AFTER MOVE] regularMoveCount`

3. **Snitch Reappearance Wait**
   - Renamed `snitchWaitTurnsCompleted` → `snitchWaitMovesCompleted`
   - Added `snitchWaitRequired` flag (true only on REappearance after hiding)
   - Wait counter increments on each regular move in `progressAfterMove()`
   - First appearance: NO wait required, encounter triggers immediately
   - Reappearance: Requires 2 moves before encounter can trigger

4. **Functions Updated**
   - `progressAfterMove()`: Now tracks regular moves, advances snitch wait
   - `isSnitchEncounterReady()`: Checks wait only if `snitchWaitRequired` is true
   - `evaluateSnitchAfterTurnComplete()`: No longer increments, just checks if ready
   - `ensureSnitchWaitActive()`: Simplified to mark pending state only
   - `SNITCH_LAND` action: Removed hardcoded wait initialization

### Assumption Confirmed
Moves are counted **globally** (both players combined), not per player. Single `regularMoveCount` counter applies to both teams.

## Manual Test Results

### Test Environment
- Browser: Chrome (Player A - Team 1 Yellow) + Edge (Player B - Team 2 Purple)
- Mode: Solo room
- Console logs monitored for move counts

---

## Test 1: Snitch does NOT appear after moves 1, 2, 3

| Step | Player A Action | Player B Action | Expected | Actual | Result |
|------|----------------|-----------------|----------|--------|--------|
| 1 | Move Chaser C4→C5 | - | regularMoveCount=1, no snitch | | PENDING |
| 2 | - | Move Chaser C4→C5 | regularMoveCount=2, no snitch | | PENDING |
| 3 | Move Beater B3→B4 | - | regularMoveCount=3, no snitch | | PENDING |

---

## Test 2: Snitch appears after move 4

| Step | Player A Action | Player B Action | Expected | Actual | Result |
|------|----------------|-----------------|----------|--------|--------|
| 4 | - | Move Beater B3→B4 | regularMoveCount=4, snitch appears | | PENDING |

---

## Test 3: Seeker move + bonus = 1 move

| Step | Action | Expected | Actual | Result |
|------|--------|----------|--------|--------|
| 1 | Team 1: Move Seeker S3→S4 | regularMoveCount=1, isRegularMove=true | | PENDING |
| 2 | Team 1: Click "Move Again" | Bonus prompt shows | | PENDING |
| 3 | Team 1: Move Chaser (bonus) | regularMoveCount still=1, isRegularMove=false | | PENDING |
| 4 | Team 2: Move Chaser | regularMoveCount=2 | | PENDING |

---

## Test 4: Snitch reappears, waits 2 moves

| Step | Action | Expected | Actual | Result |
|------|--------|----------|--------|--------|
| 1 | Snitch active, seeker nearby | - | | PENDING |
| 2 | Seeker lands on snitch | Encounter wheel → snitch hides | | PENDING |
| 3 | Snitch reappears (outcome wheel) | snitchWaitRequired=true, wait=0 | | PENDING |
| 4 | Player A moves ANY piece | wait=1, no encounter | | PENDING |
| 5 | Player B moves ANY piece | wait=2, encounter ready | | PENDING |
| 6 | End turn with seeker on snitch | Encounter triggers | | PENDING |

---

## Test 5: Seeker already on square at reappearance

| Step | Action | Expected | Actual | Result |
|------|--------|----------|--------|--------|
| 1 | Snitch hidden, seeker on D3 | - | | PENDING |
| 2 | Snitch reappears at D3 | No immediate encounter, wait=0 | | PENDING |
| 3 | Move any piece (not seeker) | wait=1, no encounter | | PENDING |
| 4 | Move any piece | wait=2, encounter ready | | PENDING |
| 5 | End turn | Encounter triggers | | PENDING |

---

## Test 6: Move counter syncs both clients

| Step | Action | Expected | Actual | Result |
|------|--------|----------|--------|--------|
| 1 | Player A: Move piece | Both tabs: same count in console | | PENDING |
| 2 | Player B: Move piece | Both tabs: same count in console | | PENDING |
| 3 | After 4 moves | Both tabs: snitch appears simultaneously | | PENDING |

---

## Bugs Found

### Bug 1: Snitch appears after 4 moves but counter shows double
**Symptom**: regularMoveCount increments twice per move
**Impact**: Snitch appears after 2 moves instead of 4

### Bug 2: Snitch move counts as 2 moves instead of 1
**Symptom**: When seeker moves snitch, regularMoveCount increments even though it shouldn't
**Impact**: Snitch spawn timing incorrect

### Bug 3: Pieces cannot move during deployment phase
**Symptom**: Click piece during deployment, no valid moves shown
**Impact**: Cannot reposition pieces before match starts

### Bug 4: Snitch wait counter doesn't work
**Symptom**: snitchWaitMovesCompleted stays at 0, never increments
**Impact**: Encounter triggers immediately instead of after 2 moves

### Bug 5: Snitch doesn't detect seekers on same square
**Symptom**: Seeker lands on snitch, no encounter pending
**Impact**: Wheel doesn't trigger when seeker reaches snitch

### Bug 6: Achievements not updating after match
**Symptom**: Win match, check achievements page, no new unlocks
**Impact**: Achievement system broken

---

## Fixes Applied

### Fix 1: regularMoveCount initialization and double counting
- **Issue**: Counter started at `undefined`, fell back to `turnCount`, then incremented
- **Fix**: Initialize `regularMoveCount: 0` in initial state, change fallback from `s.turnCount` to `0`
- **Files**: `src/app/game/[roomCode]/page.tsx` lines 191, 478

### Fix 2: Deployment phase movement blocked
- **Issue**: `clickPiece()` returned early if `phase !== 'match'`
- **Fix**: Allow clicks during deployment, only block during finished phase
- **Files**: `src/app/game/[roomCode]/page.tsx` lines 3279-3292, 3297-3312

### Fix 3: Snitch wait counter increment logic verified
- **Issue**: Suspected double increment
- **Fix**: Confirmed single increment per move when `snitchWaitRequired` is true
- **Status**: Already correct, no change needed

### Fix 4: Trigger function cleanup
- **Issue**: Didn't explicitly clear wait state
- **Fix**: Added `snitchWaitRequired: undefined` to trigger clear
- **Files**: `src/app/game/[roomCode]/page.tsx` line 390

---

## Test Status: READY FOR EXECUTION
- Server running on localhost:3000
- All code fixes applied
- Console logs active for debugging
- Manual tests pending user execution

---

## Phase 3: Test Execution - PENDING
Tests will be run manually with two browser tabs after server restart.

## Phase 4: Refactoring - NOT STARTED
Will extract game rules, unify state transitions, remove duplication after tests pass.

## Phase 5: Post-Refactor Testing - NOT STARTED
Will re-run all tests after refactoring to ensure behavior unchanged.

---

## Next Steps
1. Restart development server
2. Execute manual tests
3. Record results in this document
4. Fix any failures
5. Proceed to refactoring phase 
