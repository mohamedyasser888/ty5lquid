# 🧪 TWO BROWSER TEST GUIDE - Solo Mode

## ✅ PRE-TEST CHECKLIST

**ALL FIXES VERIFIED:**
- ✅ Database function has solo mode check
- ✅ Client captain checks skip in solo mode (3 locations)
- ✅ Attacker buttons use team-based logic
- ✅ Server running on http://localhost:3000

---

## 📋 STEP-BY-STEP TEST

### STEP 1: Clear Cache & Setup

1. **Close ALL browser tabs with localhost:3000**
2. **Clear browser cache:**
   - Press `Ctrl + Shift + Delete`
   - Select "All time"
   - Check "Cached images and files"
   - Click "Clear data"

### STEP 2: Create Solo Room

1. **Open Browser (any browser)**
2. Go to: `http://localhost:3000`
3. Login with your account
4. Click **"Play Quidditch"**
5. Click **"SOLO"** card
6. Click **"Create Room"**
7. **COPY THE ROOM CODE** (e.g., QUID-XXXX)

### STEP 3: Setup First Browser Tab

1. Select your house (e.g., Gryffindor)
2. Click **"Ready"**
3. You should see: **👑 Team Captain**
4. Click **"Begin Match"**
5. Watch coin flip animation (3D coin)
6. You'll be redirected to game page

### STEP 4: Open Second Browser Tab

**IMPORTANT**: You need to manually navigate to the OTHER team!

1. **Copy the game URL** from Tab 1
   - Example: `http://localhost:3000/game/QUID-LKIB?team=2&t1=lol&t2=cool&captain=true&starter=1&h1=hufflepuff&h2=hufflepuff`

2. **Open NEW tab** in same browser (or different browser)

3. **Change the team parameter:**
   - If Tab 1 has `?team=1`, change to `?team=2`
   - If Tab 1 has `?team=2`, change to `?team=1`
   
   Example:
   ```
   Tab 1: http://localhost:3000/game/QUID-LKIB?team=1&...
   Tab 2: http://localhost:3000/game/QUID-LKIB?team=2&...
   ```

4. Press Enter

5. **You should now have:**
   - Tab 1: Controlling Team 1 (Purple/Yellow)
   - Tab 2: Controlling Team 2 (Yellow/Purple)

---

## 🎯 CRITICAL TESTS

### TEST 1: Both Teams Can Move

**Expected:**
- ✅ Tab 1 can select and place Team 1 pieces
- ✅ Tab 2 can select and place Team 2 pieces
- ✅ NO "Non-captain cannot select pieces" errors

**Console Check:**
```
[CAPTAIN STATUS] { isSoloMode: true, dbIsCaptain: false, isCaptain: true }
```

**If pieces won't move:**
- ❌ Check console for `[CLICK PIECE] Non-captain cannot select pieces`
- ❌ This means `isCaptain = false` (bug not fixed)

---

### TEST 2: Real-Time Sync

**Steps:**
1. Tab 1: Place a piece at A1
2. Look at Tab 2

**Expected:**
- ✅ Tab 2 immediately shows the piece at A1
- ✅ Within 100ms (real-time)

**Console Check:**
```
Tab 1: [REALTIME] Broadcast sent
Tab 2: [REALTIME] Broadcast received: PLACE
Tab 2: [REALTIME] Applying action from team 1
```

---

### TEST 3: Deployment Phase

**Steps:**
1. In both tabs, place all pieces:
   - 1 Goalkeeper (GK)
   - 3 Defenders (D)
   - 3 Attackers (A)
   - 1 Seeker (S)

2. Assign broom speeds (0-4)

3. Both tabs click **"Deployment Complete"**

**Expected:**
- ✅ Both tabs enter match phase
- ✅ Turn indicator shows starting team
- ✅ No errors

---

### TEST 4: 🔴 CRITICAL - Attacker Buttons

**This is the main bug we fixed!**

**Steps:**
1. Start match phase
2. Move an attacker toward opponent's goal zone:
   - **Team 1 attacking:** Move to **row 1** (top row)
   - **Team 2 attacking:** Move to **row 5** (bottom row before goalkeeper)

3. Attacker reaches goal zone

**Expected Result:**
```
┌────────────────────────────────────┐
│  🏆 COMBAT WON! Choose your action:│
│                                    │
│  [🛡️ STAY IN POSITION]  [⚽ SHOOT GOAL] │
└────────────────────────────────────┘
```

**Console Check:**
```
[ATTACKER MOVE] Reached goal zone without defender, showing choice
  attackerId: "2-A-..."
  team: 2
  position: "D5"

[ATTACKER CHOICE UI] shouldShowControls: true
  attackerTeam: 2
  myTeam: 2
  isMyTeam: true
```

**If buttons DON'T appear:**
- ❌ Check console for `shouldShowControls: false`
- ❌ Check if `attackerTeam !== myTeam`
- ❌ This means team assignment is wrong

---

### TEST 5: Stay vs Shoot

**Test STAY:**
1. Click **🛡️ STAY IN POSITION**
2. Check turn indicator

**Expected:**
- ✅ Turn switches to opponent
- ✅ Snitch counter increments (+1)
- ✅ Attacker stays at goal zone
- ✅ Cannot click attacker again (not your turn)

**Test SHOOT:**
1. Next turn, click the attacker that stayed
2. **⚽ SHOOT GOAL** button appears
3. Click it

**Expected:**
- ✅ Goal duel UI appears
- ✅ Shows: LEFT / MIDDLE / RIGHT choices
- ✅ Goalkeeper also chooses
- ✅ Result: GOAL or SAVE
- ✅ Score updates on BOTH tabs

---

### TEST 6: Turn System

**Steps:**
1. Tab 1 makes a move
2. Check turn indicator

**Expected:**
- ✅ Turn indicator shows "Team 2's Turn" (or opponent name)
- ✅ Tab 1 cannot select pieces (not your turn)
- ✅ Tab 2 can now select pieces

**Console Check:**
```
Tab 1: [CLICK PIECE] Cannot select: not your turn
```

---

## 🐛 TROUBLESHOOTING

### Problem: "Non-captain cannot select pieces"

**Cause:** `isCaptain = false`

**Check:**
1. Open console (F12)
2. Look for: `[CAPTAIN STATUS]`
3. Should show: `{ isSoloMode: true, isCaptain: true }`

**Fix:**
- Refresh with `Ctrl + Shift + R`
- If still broken, restart server

---

### Problem: Buttons don't appear

**Cause:** `shouldShowControls = false`

**Check:**
1. Console should show:
   ```
   [ATTACKER CHOICE UI] shouldShowControls: true
   ```

2. If it shows `false`, check:
   - `attackerTeam: ???`
   - `myTeam: ???`
   - These should MATCH

**Fix:**
- Make sure you're controlling the correct team
- Check URL has correct `?team=X` parameter

---

### Problem: Pieces not syncing between tabs

**Cause:** Realtime channel not working

**Check:**
1. Console should show:
   ```
   [REALTIME] Broadcast received
   [REALTIME] Applying action from team X
   ```

2. If missing, check:
   - Internet connection
   - Supabase connection

**Fix:**
- Refresh both tabs
- Check network tab for WebSocket connection

---

## ✅ SUCCESS CRITERIA

### Minimum Working:
- [ ] Both tabs can move pieces
- [ ] Pieces sync in real-time
- [ ] Attacker buttons appear at goal zone
- [ ] Buttons are clickable
- [ ] STAY action ends turn
- [ ] SHOOT action triggers duel

### Full Game:
- [ ] Complete deployment phase
- [ ] Multiple turns with combat
- [ ] Score tracking works
- [ ] Goal duels work
- [ ] Snitch phase triggers
- [ ] Match ends correctly

---

## 📝 REPORT RESULTS

**If something fails, tell me:**
1. Which test step failed?
2. What did you see? (screenshot if possible)
3. What console logs appeared? (copy from DevTools)
4. Which browser? (Chrome, Edge, Firefox)

---

## 🚀 READY TO TEST!

**Server:** http://localhost:3000 ✅  
**Database:** Solo mode check deployed ✅  
**Client:** All captain checks fixed ✅

**Start testing now!** 🎮
