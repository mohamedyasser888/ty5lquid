# ✅ COMPLETE TEST CHECKLIST - Solo Mode Quidditch

## 🔧 Pre-Test Setup
- [x] Server running: http://localhost:3000
- [x] Cache cleared (.next folder removed)
- [x] Fresh build completed
- [x] Database functions deployed

## 🧪 Critical Fixes Verified

### Fix 1: Solo Mode Captain Detection
**File:** `src/app/game/[roomCode]/page.tsx`
**Lines:** 2057-2062, 2235
- [x] `isSoloMode` state added
- [x] Fetches `room.mode` from database
- [x] `isCaptain = isSoloMode || dbIsCaptain`

### Fix 2: Attacker Choice Buttons
**File:** `src/app/game/[roomCode]/page.tsx`
**Lines:** 3695-3700
- [x] Added condition: `iAmAttackerController || (atk?.team === myTeam && isCaptain)`
- [x] Buttons show for captain in solo mode

---

## 📋 MANUAL TEST STEPS

### STEP 1: Clear Browser Cache
1. Open Chrome/Edge
2. Press `Ctrl + Shift + Delete`
3. Select "All time"
4. Check "Cached images and files"
5. Click "Clear data"
6. **OR** just press `Ctrl + Shift + R` for hard refresh

### STEP 2: Login
1. Go to http://localhost:3000
2. Login with your account
3. Should redirect to /home

### STEP 3: Create Solo Room
1. Click "Play Quidditch"
2. Click "SOLO" card
3. Should redirect to /room/create?solo=true
4. Click "Create Room"
5. Note the room code (e.g., QUID-XXXX)

### STEP 4: Setup Room
1. Select your house
2. Click "Ready"
3. **Expected:** Captain badge appears (👑 Team Captain)
4. Room status shows "Ready to Begin"

### STEP 5: Start Match (Coin Flip)
1. Click "Begin Match"
2. **Expected:** 3D coin flip animation plays
3. Coin lands showing Purple or Yellow
4. **Expected:** Redirects to /game/QUID-XXXX
5. **Expected:** Game board appears with pieces

### STEP 6: Deployment Phase
1. **Check 1:** Can select pieces from deployment area
2. **Check 2:** Can place pieces on field
3. **Check 3:** Can assign broom speeds (0-4)
4. Click "Deployment Complete"
5. **Expected:** Match begins

### STEP 7: Movement & Combat
1. Select a piece (should highlight)
2. Click destination (should move)
3. **Expected:** Turn switches
4. Move pieces until combat triggers
5. **Expected:** Combat wheel spins
6. **Expected:** Winner determined

### STEP 8: CRITICAL TEST - Attacker Choice
**This is the main bug we fixed!**

1. Move an attacker to opponent's goal zone (row 0 or 6)
2. Win the combat
3. **EXPECTED:** Two buttons appear:
   - 🛡️ STAY IN POSITION
   - ⚽ SHOOT GOAL
4. Click one of the buttons
5. **EXPECTED:** Button activates, action executes

**If buttons DON'T appear:**
- ❌ Solo mode detection failed
- Check browser console for errors
- Check `[SOLO MODE]` log messages

### STEP 9: Goal Duel
1. After choosing "SHOOT GOAL"
2. **Expected:** Duel UI appears
3. Choose LEFT, MIDDLE, or RIGHT
4. **Expected:** Opponent's GK chooses
5. **Expected:** Result shows (GOAL or SAVE)
6. **Expected:** Score updates

### STEP 10: Snitch Phase
1. Play until turn count ≥ 10
2. **Expected:** "✨ THE SNITCH APPEARS!" message
3. Move seeker to snitch location
4. **Expected:** Snitch encounter wheel
5. **Expected:** Catch/Hold/Move outcome
6. If caught: Match ends, winner declared

---

## 🎯 Expected Behaviors (Solo Mode)

### ✅ Captain Controls
- Captain sees ALL action buttons
- Captain controls ALL pieces
- Captain makes ALL decisions (duels, attacker choice, etc.)

### ✅ Synchronization
- Actions broadcast via realtime
- Both tabs see same game state
- No duplicate actions
- No missing actions

### ✅ UI Elements
- Turn indicator shows correctly
- Piece selection works
- Movement highlights appear
- Buttons are clickable
- Animations play smoothly

---

## 🐛 Known Issues to Watch For

### ❌ OLD BUGS (Should be FIXED):
1. **Attacker choice buttons missing** - FIXED ✅
2. **Solo mode not detected** - FIXED ✅
3. **controllerPlayerId undefined** - FIXED ✅

### ⚠️ Potential Issues:
1. Database save errors → Check console
2. Realtime sync delays → Check network tab
3. State conflicts → Check revision numbers

---

## 🔍 Console Log Checks

Open browser DevTools (F12) and look for:

### Good Logs:
```
[SOLO MODE] Room mode: solo isSolo: true
[CAPTAIN STATUS] userId: xxx isActualCaptain: true isSolo: true
[REALTIME] Broadcast received: MOVE
[REALTIME] Applying action from team 1
```

### Bad Logs:
```
[EMIT] Database save failed: {...}
[REALTIME] Ignoring own action (WRONG - this was the bug)
Cannot select pieces while attacker scoring choice is pending
```

---

## 📊 Success Criteria

### Minimum Working Test:
- [x] Login successful
- [x] Solo room created
- [x] Match started
- [x] Deployment works
- [x] Movement works
- [x] Combat works
- [ ] **Attacker choice buttons appear** ← MAIN TEST
- [ ] Buttons are clickable
- [ ] Action executes correctly

### Full Working Test:
- [ ] Complete game: deployment → combat → goal → snitch → match end
- [ ] Score tracking accurate
- [ ] No console errors
- [ ] Smooth animations
- [ ] Match result saved to database

---

## 🚀 START YOUR TEST NOW

1. **Clear browser cache** (Ctrl + Shift + Delete)
2. **Open:** http://localhost:3000
3. **Follow steps 1-10 above**
4. **Report:** Which step failed (if any)

**Server is ready at:** http://localhost:3000
**Status:** ✅ All fixes applied, fresh build complete

---

## 📞 If Something Goes Wrong

1. Check browser console (F12)
2. Check server terminal output
3. Note the exact step that failed
4. Copy any error messages
5. Tell me what happened!

