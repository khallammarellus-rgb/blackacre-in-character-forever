# Blackacre — Quality Assurance & Testing Guide

**The master in-game testing reference for Blackacre.**  
Testing in Blackacre is **modular and task-focused**: we run test suites targeted to what was modified, rather than forcing full monolithic visual passes during backend or comms work.

---

## 1. Universal Smoke Stop-Gate (Run on Any Code Change)

Before running specific feature checks, run this 30-second smoke test:

| # | Check | Expected Result | Pass? |
|---|-------|-----------------|:-----:|
| **S1** | `/reload` | Clean console — **Zero red Lua errors** (BugSack is silent) | [ ] |
| **S2** | Minimap icon | Minimap book icon is present and clickable | [ ] |
| **S3** | Packages loaded | `/ba packages` prints Core, Tome, Survival, Presence | [ ] |
| **S4** | Tome toggle | `/ba tome` (or right-click minimap) opens the Traveler's Tome | [ ] |
| **S5** | Window dismiss | Pressing **Esc** closes the open window cleanly | [ ] |

> [!STOP]
> **Stop-Gate Rule:** If S1 fails (any red Lua error), stop and report the error stack trace immediately. Do not proceed to deeper testing.

---

## 2. Modular Test Suites

Pick the suite corresponding to the current task.

---

### Suite A: Visuals & Chrome Standard Inspection
Use when modifying UI, frames, skins, or layout. Region codes match the labels `/ba skin` draws on the journal.

#### Region Standard Checklist

| Region Code | Element | Standard Criteria | Pass? |
|-------------|---------|-------------------|:-----:|
| **1S** | Outer NineSlice | Clean faction border, corners unclipped, no blurred edge stretch | [ ] |
| **2F** | Header Title Bar | Title readable on `OVERLAY`; no collision with Close or Add Page | [ ] |
| **3F** | Close Button | Single X button in header right; clicks dismiss window | [ ] |
| **4F** | Book Art Canvas | Single unified Encounter Journal parchment background, centered | [ ] |
| **5F / 6F** | Left / Right Leaves | Equal width leaves, proper page margins, content sits within borders | [ ] |
| **5F.sub / 6F.sub** | Text Elements | Text on `OVERLAY`, crisp white/graphite ink, zero mudding or clipping | [ ] |
| **7F** | Spine Gutter | Distinct visual spine separating the left and right leaves | [ ] |
| **8S** | TOC Bookmark Tab | Faction banner tab protruding cleanly from left edge at top alignment | [ ] |
| **9S** | Under-book Rail | Faction rail texture sits cleanly below book canvas without visual glitch | [ ] |
| **10F** | Footer Status | `Journaling: Locked` / `Journaling: On` button width 200px (no text clip) | [ ] |
| **11F** | Footer Tool Strip | Bottom action buttons (Save, Add Note, Pin, Delete) stay in footer | [ ] |

---

### Suite B: In-Character (IC) Narrative & Story Integrity
Use when testing chronicle capture, quest journaling, lore lines, or options.

| # | Check | Standard Criteria | Pass? |
|---|-------|-------------------|:-----:|
| **B1** | **First-Person IC Voice** | All auto-journaled entries and prompts are written strictly in the character's first-person IC voice (never OOC meta) | [ ] |
| **B2** | **Faction Calendar Dating** | Journal dates follow the character's faction: Alliance uses the King's Calendar (**K.C.**; it starts at `0 K.C.`, years before it read `-1 K.C.`), Horde counts from the Dark Portal (**ADP**; the year it opens is `0 ADP`, the year before is `-1 BDP`). Never both at once. | [ ] |
| **B3** | **OOC Separation** | All configuration, options, and settings live strictly in the ToolBox (`/ba`) or Game Menu — **zero settings controls inside the journal pages** | [ ] |
| **B4** | **Quest Inking** | Turning in or clicking "Journal this" records the page immediately without duplication | [ ] |

---

### Suite C: Communications & Addon Network
Use when debugging comms, bulletins, beacons, or peer data exchange.

| # | Check | Standard Criteria | Pass? |
|---|-------|-------------------|:-----:|
| **C1** | Channel Integrity | Hidden `Blackacre` comms channel registered cleanly without chat window spam | [ ] |
| **C2** | Distance Throttling | Board and beacon proximity checks trigger on movement, not idle timers | [ ] |
| **C3** | Bulletin Fetch | Fetching bulletin details retrieves post cleanly without Lua timeouts | [ ] |
| **C4** | Seeking State | Toggling Seeking in ToolBox properly sets addon broadcast state | [ ] |

---

### Suite D: Backups & Data Safety
Use after any change to saved data, and before releasing an update. Open the Backups window with `/ba restore` (also in Settings → Profiles → "Restore or import a backup...").

| # | Check | Standard Criteria | Pass? |
|---|-------|-------------------|:-----:|
| **D1** | Automatic Backup | After a first login, wait about 15 seconds, then open `/ba restore`: one row appears ("First backup", with the right page and quest counts) | [ ] |
| **D2** | Quiet When Unchanged | `/reload` again without writing anything: no new row is added | [ ] |
| **D3** | Restore | Write a new page, `/reload`. In `/ba restore`, press Restore on the older row and confirm: the game reloads and the new page is gone, the older pages and the Quest Index are intact | [ ] |
| **D4** | Undo A Restore | After D3, open `/ba restore`: a "Before restoring..." row is there. Restore it: the new page returns | [ ] |
| **D5** | Export And Import | Export backup text, copy it, save it somewhere. Delete a page. In the window paste the text into the Import box and press Import, confirm: the page is back | [ ] |
| **D6** | Bad Text Refused | Paste `hello` (or half of a backup) into the Import box and press Import: a message says it isn't a valid backup, nothing changes | [ ] |
| **D7** | Survives An Update | Install a newer version over the old one, log in: pages and the Quest Index are all there, and the Backups window shows a "Before update to ..." row if anything had changed | [ ] |
| **D8** | No Hitch | Logging in with a large journal never freezes the screen, and fighting right after login is not affected | [ ] |

---

### Suite E: Survival & Death
Use after any change to the survival meters. Note the three stack numbers before you start.

| # | Check | Standard Criteria | Pass? |
|---|-------|-------------------|:-----:|
| **E1** | Spirit Form Appears | Die: a Spirit Form icon with a yellow-brown (disease) border appears after Exposure; the Prepared icon hides | [ ] |
| **E2** | Meters Paused | Stay dead or a ghost for 3+ minutes: none of the three numbers move | [ ] |
| **E3** | Spirit Tooltips | While dead, hovering Hunger, Thirst or Exposure reads "You are in spirit form" (no climate, no "Resting" line); hovering Spirit Form explains the pause | [ ] |
| **E4** | Return To Body | Take a res (spirit healer, corpse run, or a player's res): Hunger and Thirst read 0, Exposure is where it stopped, one toast "You return to your body hungry and parched", Spirit Form icon gone | [ ] |
| **E5** | Exposure Resumes | A minute after E4, Exposure drops again at the zone's normal rate | [ ] |
| **E6** | Ghost Across A Reload | As a ghost, `/reload`: Spirit Form is still there and the meters still don't move | [ ] |
| **E7** | Feign Death (Hunter) | Feign Death and stand up: no Spirit Form icon, meters untouched | [ ] |
| **E8** | Camp | Stand in a camp with the "Campfire Nearby" buff: Exposure climbs about 1 every second; tooltip reads "At camp: recovering quickly" | [ ] |
| **E9** | Cozy Fire | Stand by a fire with only the "Cozy Fire" buff: Exposure climbs 1 every 5 seconds; tooltip reads "By the fire: recovering" | [ ] |
| **E10** | Leaving The Fire | Walk away from the fire: Exposure stops climbing within a second or two and starts to drop again | [ ] |
| **E11** | Cooked Food | Eat a cooked (Well Fed) food: Hunger goes to 100 the moment you sit and eat | [ ] |
| **E12** | Food Tiers | `/ba survival scan` lists each food and water with its tier (1-7) and level; hovering Prepared shows "hunger drains N% slower" (10/15/20/25/30/35, tier 7 = 70%) for the best one you can eat | [ ] |
| **E13** | Too Young To Eat | Carry only food above your level: Prepared doesn't count it (scan says 0% slower) | [ ] |
| **E14** | Well Fed | Eat cooked food for 10+ seconds: Hunger tooltip reads "Well Fed: hunger holds steady" and the number doesn't drop until the buff ends | [ ] |
| **E15** | Drinking | Sit and drink: Thirst climbs about 1 a second; Thirst tooltip reads "Drinking: recovering" | [ ] |
| **E16** | Finish The Drink | Drink until the drink ends by itself: Thirst jumps to 100 | [ ] |
| **E17** | Stand Up Early | Stand up mid-drink: Thirst keeps what it gained, no jump to 100 | [ ] |

---

## 3. Owner Pass/Fail Reply Template

Copy, fill, and send when reporting test results:

```markdown
### QA Report: [Task / Feature Name]

**Smoke:** S1 [P/F], S2 [P/F], S3 [P/F], S4 [P/F], S5 [P/F]
**Active Suite:** [Suite A / B / C]

**Findings:**
- [Region or Check #]: [PASS / FAIL] — [Notes or error text if failed]

**Decision:**
- [ ] PASS — Ready to proceed / commit
- [ ] NEEDS FIX — See issues above
```
