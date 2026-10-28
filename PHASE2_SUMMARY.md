# Phase 2 Complete: Snitch Rules Implementation

## What Changed
- Move counter now tracks regular moves separately (seeker+bonus=1, others=1 each)
- Snitch appears after 4 regular moves (not 4 turns)
- Snitch reappearance requires 2-move wait before encounter
- First appearance: no wait, immediate encounter
- Wait counter advances on each move, not turn-end

## Files Modified
- `src/app/game/[roomCode]/page.tsx`: Updated move counting, snitch wait logic

## Testing Status
- Server running on localhost:3000
- Manual tests documented in TEST_REPORT.md (pending execution)
- Console logs added for verification

## Next: Execute Tests
Open two browser tabs (Chrome + Edge), run through test scenarios in SNITCH_TEST_MANUAL.md, record results.
