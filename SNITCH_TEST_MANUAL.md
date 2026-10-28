# Snitch Rules Manual Test Plan

## Setup
- Open localhost:3000 in Chrome (Player A - Team 1 Yellow)
- Open localhost:3000 in Edge (Player B - Team 2 Purple)
- Create solo room, deploy pieces, start match
- Console logs will show: `[PROGRESS AFTER MOVE] regularMoveCount`

## Test 1: Snitch does NOT appear after moves 1, 2, 3

| Step | Player A Action | Player B Action | Expected | Actual | Result |
|------|----------------|-----------------|----------|--------|--------|
| 1 | Move Chaser C4→C5 | - | regularMoveCount=1, no snitch | | |
| 2 | - | Move Chaser C4→C5 | regularMoveCount=2, no snitch | | |
| 3 | Move Beater B3→B4 | - | regularMoveCount=3, no snitch | | |

## Test 2: Snitch appears after move 4

| Step | Player A Action | Player B Action | Expected | Actual | Result |
|------|----------------|-----------------|----------|--------|--------|
| 4 | - | Move Beater B3→B4 | regularMoveCount=4, snitch appears | | |

## Test 3: Seeker move + bonus = 1 move

| Step | Action | Expected | Actual | Result |
|------|--------|----------|--------|--------|
| 1 | Team 1: Move Seeker S3→S4 | regularMoveCount=1 | | |
| 2 | Team 1: Click "Move Again" | Shows bonus prompt | | |
| 3 | Team 1: Move Chaser (bonus) | regularMoveCount still=1 (no increment) | | |
| 4 | Team 2: Move Chaser | regularMoveCount=2 | | |

## Test 4: Snitch reappears, waits 2 moves

| Step | Action | Expected | Actual | Result |
|------|--------|----------|--------|--------|
| 1 | Snitch is active, seeker nearby | - | | |
| 2 | Seeker lands on snitch | Encounter triggered, snitch hides | | |
| 3 | Snitch reappears (via wheel) | snitchWaitMovesCompleted=0 | | |
| 4 | Player moves ANY piece | snitchWaitMovesCompleted=1, no encounter | | |
| 5 | Other player moves ANY piece | snitchWaitMovesCompleted=2, encounter can trigger | | |

## Test 5: Seeker already on square at reappearance

| Step | Action | Expected | Actual | Result |
|------|--------|----------|--------|--------|
| 1 | Snitch hidden, seeker on D3 | - | | |
| 2 | Snitch reappears at D3 | No immediate encounter, wait=0 | | |
| 3 | Move any piece (not seeker) | wait=1, no encounter | | |
| 4 | Move any piece | wait=2, encounter ready | | |
| 5 | End turn with seeker still on snitch | Encounter triggers | | |

## Test 6: Move counter syncs both clients

| Step | Action | Expected | Actual | Result |
|------|--------|----------|--------|--------|
| 1 | Player A: Move piece | Check console both tabs: same count | | |
| 2 | Player B: Move piece | Check console both tabs: same count | | |
| 3 | After 4 moves | Both tabs show snitch at same time | | |

## Bugs Found

(Record bugs here during testing)

## Fixes Applied

(Record fixes here)
