# Stocks and Bonds — Implementation Timeline

---

## 1. Principles

Status: Historical  
Authority: Historical planning artifact  
Depends on: None  
Superseded by: `specification.md`, `phase-child-design.md`,
`save-load-design.md`, and `ui-screen-flow.md`

This file is retained as planning history only. It is not authoritative for
current rules behavior, save semantics, or runtime architecture.

### Incremental delivery

Each task produces a runnable, testable artifact before the next task
begins. No task is complete until its confirmation tests pass on target
hardware (NitrOS-9 / 6809).

### Dependency order

Tasks within a phase may be parallelized only when explicitly noted.
Phase boundaries are hard sequencing gates: Phase N+1 does not begin
until all Phase N confirmation tests pass.

### Testing convention

Each task includes one or more **Confirmation Tests** stated as specific
actions and expected outcomes. Tests are manual on-device unless noted
as a standalone test procedure (prefix `TST`).

### Scope discipline

Per `bestPractices.md`: each commit is limited to the scope of the
assigned task. No bundling of unrelated changes.

---

## 2. Dependency Map

```
Phase 1: TYPE Definitions and Data Initialization
    |
Phase 2: Engine — Market Tables and Card Data
    |
Phase 3: Engine — Year Loop Steps 1–8 (no I/O)
    |
Phase 4: Deck Shuffle and Card Draw
    |
Phase 5: Save / Load
    |
Phase 6: Display Utilities and Screen Primitives
    |
Phase 7: Setup and Main Menu Screens (S1, S2, S7)
    |
Phase 8: Year Loop Screens — Market Resolution (S8–S15)
    |
Phase 9: Player Action Screens — Sell and Buy (S16–S19)
    |
Phase 10: Margin, Forced Liquidation, Bankruptcy (S20–S23)
    |
Phase 11: End of Game Screens (S24–S27)
    |
Phase 12: Computer Player — Sell and Buy Logic
    |
Phase 13: AI Difficulty Tiers — AIProfile Integration
    |
Phase 14: Integration and Full Game Loop
    |
Phase 15: Regression, Edge Cases, and Final QA
```

---

## 3. Phase 1 — TYPE Definitions and Data Initialization

**Goal:** All shared TYPE records exist, compile, and initialize correctly.
No game logic yet.

---

### Task 1.1 — Define shared TYPE records

Procedures: `SNBTYPES` (type-definition-only file; no logic).

Define the following TYPEs per `save-load-design.md` and
`ai-difficulty-tiers.md`:

- `SaveHdr`
- `PlyrRec`
- `MktState`
- `AIProfile`

Verify each TYPE compiles without error. Use `SIZE()` to confirm byte
sizes match the values in `save-load-design.md` Section 6.

**Confirmation Test 1.1:**

```
Procedure TSTSIZE prints SIZE() of each TYPE.
Expected output:
    SaveHdr  : 11
    PlyrRec  : 61
    MktState : 27
    AIProfile: 15 (verify against ai-difficulty-tiers.md Section 3)
```

---

### Task 1.2 — Player initialization procedure

Procedure: `initPlayer`

Initializes a single `PlyrRec` to starting values per spec Section 3:
`cashBal = 5000`, all shares and bonds zero, `marginTot = 0`,
`isBankrupt = FALSE`, `hadCashPur = FALSE`.

**Confirmation Test 1.2:**

```
Call initPlayer for slots 1–6.
Print each plyrRec.cashBal, plyrRec.marginTot, plyrRec.isBankrupt.
Expected: all cashBal = 5000, all marginTot = 0, all isBankrupt = FALSE.
```

---

### Task 1.3 — Market state initialization procedure

Procedure: `initMkt`

Sets all `stckPrice(1..9) = 100` and all `divSuspnd(1..9) = FALSE` per
spec Section 2.1 (`StockStartPrice = 100`).

**Confirmation Test 1.3:**

```
Call initMkt.
Print mkt.stckPrice(1) through mkt.stckPrice(9).
Expected: all 100.
Print mkt.divSuspnd(1) through mkt.divSuspnd(9).
Expected: all FALSE.
```

---

### Task 1.4 — AIProfile initialization procedure

Procedure: `initAIProf`

Accepts `tier : BYTE` (1/2/3) and populates an `AIProfile` record with
the values from `ai-difficulty-tiers.md` Section 4.

**Confirmation Test 1.4:**

```
Call initAIProf(1). Print all fields. Verify against Easy column.
Call initAIProf(2). Print all fields. Verify against Medium column.
Call initAIProf(3). Print all fields. Verify against Hard column.
```

---

## 4. Phase 2 — Market Tables and Situation Card Data

**Goal:** All static game data accessible via lookup procedures.

---

### Task 2.1 — Bull and Bear market table lookups

Procedure: `getMktDelta`

Accepts `stockId : BYTE`, `mktType : BYTE` (1=Bull, 2=Bear),
`roll : BYTE` (2–12). Returns `delta : INTEGER`.

Implements the 9×11 tables from spec Sections 5.1 and 5.2 using
`DATA`/`READ` or nested `IF` chains. `DATA`/`READ` is preferred for
compactness.

**Confirmation Test 2.1:**

```
Procedure TSTMKT calls getMktDelta for a representative sample:
    getMktDelta(5, 1, 9) -> expected: 67   (Stryker, Bull, roll=9)
    getMktDelta(5, 2, 4) -> expected: -20  (Stryker, Bear, roll=4)
    getMktDelta(9, 1, 7) -> expected: 14   (Valley Power, Bull, roll=7)
    getMktDelta(9, 2, 2) -> expected: 8    (Valley Power, Bear, roll=2)
    getMktDelta(1, 1, 2) -> expected: -2   (Growth Corp, Bull, roll=2)
```

---

### Task 2.2 — Situation card data

Procedure: `getCard`

Accepts `cardId : BYTE` (1–36). Populates a working record with:
`cardType` (1=Bull, 2=Bear), `effect` array of `{stockId, priceDelta}`
pairs, `divBonus : INTEGER` (0 for all cards except Card 1).

All 36 cards from spec Section 4.3 are encoded. `DATA`/`READ` preferred.

**Confirmation Test 2.2:**

```
Procedure TSTCARD calls getCard for boundary and anomaly cards:
    Card 1:  type=Bear, Growth Corp +10, divBonus=2
    Card 5:  type=Bull, Growth Corp -10, divBonus=0
    Card 8:  type=Bear, Metro +10, divBonus=0
    Card 34: type=Bull, 4 stocks affected, correct deltas
    Card 36: type=Bear, 3 stocks affected, correct deltas
```

---

## 5. Phase 3 — Year Loop Engine Steps 1–8

**Goal:** All market resolution logic runs correctly with no display.
Results verified by printing state before and after each step.

All procedures in this phase take `mkt : MktState`, `plyrs : PlyrRec`
array, and game-loop variables as parameters. No screen procedures are
called.

---

### Task 3.1 — Apply dividends and bond interest (Step 1)

Procedure: `applyDivInt`

Implements spec Section 8. Skips Year 1 and Year 10. Applies per-stock
dividend to each player's `cashBal` if `divSuspnd = FALSE`. Applies
bond interest per denomination held.

**Confirmation Test 3.1:**

```
Setup: Year 2, Player 1 holds 100 shares Shady Brooks ($7/share),
       1 medium bond. stckPrice(4) = 100, divSuspnd(4) = FALSE.
Before: cashBal = 5000.
Call applyDivInt(2, plyrs, mkt).
After: cashBal = 5000 + (100*7) + 250 = 5950.
```

---

### Task 3.2 — Apply margin interest (Step 2)

Procedure: `applyMgnInt`

Implements spec Section 9.3. Deducts `marginTot * 0.05` from
`cashBal`. If `cashBal < 0` after deduction, sets `forceLiq = TRUE`
for that player.

**Confirmation Test 3.2:**

```
Setup: Player marginTot = 2000, cashBal = 80.
marginCharge = 2000 * 5 / 100 = 100.
After: cashBal = 80 - 100 = -20.
forceLiq flag = TRUE.
```

---

### Task 3.3 — Price resolution per stock (Steps 6–8)

Procedure: `resolvePrice`

Implements spec Section 7 for a single stock. Accepts
`currentPrice : INTEGER`, `mktDelta : INTEGER`, `cardDelta : INTEGER`,
`sharesOwnd : INTEGER`. Returns `newPrice`, `newShares`, `splitOccrd`,
`divSuspndNow`, `divSuspndPrev`.

- Clamps price at 0.
- Sets `divSuspndNow` based on `DividendCutoff` (50).
- Applies split when `newPrice >= StockSplitThreshold` (150).

**Confirmation Test 3.3:**

```
Test A — Split:
    currentPrice=130, mktDelta=25, cardDelta=0, sharesOwnd=100.
    newPrice before split = 155. Split: price=78, shares=200.
    splitOccrd = TRUE, divSuspndNow = FALSE.

Test B — Bankruptcy floor:
    currentPrice=5, mktDelta=-10, cardDelta=0, sharesOwnd=50.
    newPrice clamped to 0. divSuspndNow = TRUE.

Test C — Dividend suspension boundary:
    currentPrice=55, mktDelta=-10, cardDelta=0.
    newPrice = 45. divSuspndNow = TRUE (45 < 50).

Test D — Dividend reinstatement:
    currentPrice=45, mktDelta=10, cardDelta=0.
    newPrice = 55. divSuspndNow = FALSE (55 >= 50).
```

---

### Task 3.4 — Apply full market resolution for all stocks (Steps 3–8 combined)

Procedure: `applyMktYear`

Calls `getMktDelta` and `getCard`, applies results to `mkt` via
`resolvePrice` for all 9 stocks. Records split events and dividend
status changes for later display (via output flags array).

**Confirmation Test 3.4:**

```
Setup: Year 3, draw Card 13 (Stryker Drilling Bull +17).
Roll = 5 (Bull market). getMktDelta(5, Bull, 5) = 56.
stckPrice(5) before = 100.
After applyMktYear:
    stckPrice(5) = 100 + 56 + 17 = 173.
    Split triggers: 173 / 2 = 87 (rounded up). newPrice = 87.
    stckShrs(5) doubled for all players who held Stryker.
    splitOccrd(5) = TRUE in output flags.
All other stocks updated by card (Card 13 only affects Stryker)
and their respective Bull table roll-5 deltas.
```

---

## 6. Phase 4 — Deck Shuffle and Card Draw

**Goal:** A correctly shuffled 36-card deck that persists across turns
and does not repeat until reshuffled.

---

### Task 4.1 — Fisher-Yates deck shuffle

Procedure: `shuffleDeck`

Accepts `deckOrd(36) : BYTE`. Populates with 1–36 then applies a
Fisher-Yates shuffle using `RND`. The procedure uses INTEGER arithmetic
throughout (no REAL).

**Confirmation Test 4.1:**

```
Call shuffleDeck. Print all 36 values.
Verify: all values 1–36 present exactly once.
Call shuffleDeck again. Verify different order (probabilistic;
    repeat 3 times and confirm no identical sequence).
```

---

### Task 4.2 — Card draw procedure

Procedure: `drawCard`

Accepts `deckOrd(36) : BYTE`, `deckPos : BYTE`. Returns the card ID at
`deckOrd(deckPos)` and increments `deckPos`. If `deckPos > 36`,
reshuffles and resets `deckPos = 1`.

**Confirmation Test 4.2:**

```
Draw all 36 cards from a known deck order.
Verify card 36 is followed by a reshuffle (deckPos resets to 1,
    new card drawn from reshuffled deck).
Verify no card drawn twice before reshuffle.
```

---

## 7. Phase 5 — Save and Load

**Goal:** Complete game state survives a round-trip to disk and resumes
at the correct point.

---

### Task 5.1 — saveGame procedure

Procedure: `saveGame`

Implements the write sequence from `save-load-design.md` Section 8.
Writes `SaveHdr`, `deckOrd`, `plyrs(6)`, `MktState` to a named file
using `PUT`. Computes and writes checksum.

**Confirmation Test 5.1:**

```
Initialize two players with known non-default state
(cashBal = 7500, stckShrs(3) = 50, bondUnts(2) = 1).
Call saveGame with savedPhase=0.
Verify file exists and has SIZE = 440 bytes.
```

---

### Task 5.2 — loadGame procedure

Procedure: `loadGame`

Implements the read sequence from `save-load-design.md` Section 9.
Reads and validates magic byte, format version, and checksum before
applying state. Returns `loadOK : BOOLEAN`.

**Confirmation Test 5.2:**

```
Load the file written in Task 5.1.
Verify loadOK = TRUE.
Verify plyrRec(1).cashBal = 7500.
Verify plyrRec(1).stckShrs(3) = 50.
Verify plyrRec(1).bondUnts(2) = 1.
Modify one byte in the save file manually (OS-9 hex editor).
Reload. Verify loadOK = FALSE with "corrupt" error message.
```

---

### Task 5.3 — Save checkpoint coverage

Verify all four `savedPhase` values (0–3) write and reload correctly,
including `obligation` field for `savedPhase = 3`.

**Confirmation Test 5.3:**

```
For each savedPhase 0, 1, 2, 3:
    Save with appropriate field values.
    Load and verify hdr.savedPhase and hdr.savedPlyr correct.
    For phase 3: verify hdr.obligation = saved value.
```

---

## 8. Phase 6 — Display Utilities and Screen Primitives

**Goal:** Reusable display building blocks available to all screen
procedures.

---

### Task 6.1 — Screen clear and cursor positioning

Procedure: `clrScr`

Sends ASCII form-feed (12) to path 1. Confirmed approach from
`basicReference.b09`.

Procedure: `printAt`

Accepts `row : BYTE`, `col : BYTE`, `txt : STRING`. Positions output
using TAB and newline sequences appropriate to the terminal.

**Confirmation Test 6.1:**

```
Call clrScr. Verify terminal clears.
Call printAt(5, 10, "TEST"). Verify "TEST" appears at row 5, column 10.
```

---

### Task 6.2 — Formatted integer display

Procedure: `fmtMoney`

Accepts `amt : INTEGER`. Returns `STRING[8]` with right-justified
dollar value. Handles negative values (for margin or deficit display).

**Confirmation Test 6.2:**

```
fmtMoney(5000)  -> "   5000"
fmtMoney(0)     -> "      0"
fmtMoney(-200)  -> "   -200"
fmtMoney(32767) -> "  32767"
```

---

### Task 6.3 — Confirm/continue prompt

Procedure: `waitKey`

Prints "Press any key to continue" and blocks on `GET #0`. Used by all
passive display screens (S9–S15, S19, S22, S24–S26).

**Confirmation Test 6.3:**

```
Call waitKey. Verify prompt displayed.
Press a key. Verify execution resumes immediately.
```

---

### Task 6.4 — Single-character menu input

Procedure: `getMenuKey`

Accepts `minKey : BYTE`, `maxKey : BYTE`. Loops on `GET #0` until a
character in the valid range is entered. Returns `choice : BYTE`.
Does not echo invalid keypresses.

**Confirmation Test 6.4:**

```
Call getMenuKey(1, 3).
Press '5' — verify no response (invalid).
Press '2' — verify choice = 2 returned immediately.
```

---

## 9. Phase 7 — Setup and Main Menu Screens

**Goal:** Complete new-game setup and main menu flow playable end-to-end,
routing correctly to the year loop entry point.

---

### Task 7.1 — Start screen (S1)

Procedure: `scrStart`

Displays: New Game / Load Game / Quit. Returns `action : BYTE`
(1/2/3). Uses `getMenuKey`.

**Confirmation Test 7.1:**

```
Run scrStart. Verify menu displays.
Press 1 — verify action = 1 returned.
Press 2 — verify action = 2 returned.
Press 3 — verify action = 3 returned.
Press invalid key — verify no response.
```

---

### Task 7.2 — New game setup screen (S2)

Procedure: `scrSetup`

Collects `plyrCount`, `plyrType(6)`, `plyrName(6)`, `rollMode`.
Uses `getMenuKey` for count and type. Uses `INPUT` for names.

**Confirmation Test 7.2:**

```
Run scrSetup. Configure 2 players: Human "ALICE", Computer "BOT".
RollMode = B.
Verify returned values: plyrCount=2, plyrType(1)=1, plyrType(2)=2,
    plyrName(1)="ALICE", plyrName(2)="BOT", rollMode=2.
```

---

### Task 7.3 — Setup confirmation screen (S7)

Procedure: `scrConfirm`

Displays setup summary. Returns `action : BYTE` (1=Confirm, 2=Back).

**Confirmation Test 7.3:**

```
Run scrConfirm with the values from Task 7.2.
Verify all values displayed correctly.
Press Back — verify action = 2.
Re-run scrSetup and change player 2 to Human "CAROL".
Press Confirm — verify action = 1 with updated values.
```

---

### Task 7.4 — Main menu routing

Procedure: `SNBMAIN`

Integrates S1 → S2 → S7 → game loop entry, plus Load Game → `loadGame`
→ game loop entry, plus Quit → exit. Game loop entry is a stub `PRINT`
for now.

**Confirmation Test 7.4:**

```
Run SNBMAIN.
New Game path: S1 → S2 → S7 Confirm → stub print "STARTING GAME".
Load Game path: S1 → Load → (no save file present) → error message.
Quit path: S1 → clean exit.
```

---

## 10. Phase 8 — Year Loop Screens: Market Resolution

**Goal:** All market display screens (S8–S15) render correctly using
live engine output from Phase 3.

---

### Task 8.1 — Year header screen (S8)

Procedure: `scrYearHdr`

Displays year number, rule notices (no dividends Year 1/10, no margin
Year 10, no sell Year 1). Returns on keypress.

**Confirmation Test 8.1:**

```
Run scrYearHdr(1, ...). Verify "YEAR 1 OF 10", no-dividends notice,
    no-sell notice shown.
Run scrYearHdr(5, ...). Verify year 5, no special notices.
Run scrYearHdr(10, ...). Verify no-dividends and no-margin notices.
```

---

### Task 8.2 — Dividend and interest summary screen (S9)

Procedure: `scrDivInt`

Displays per-stock dividends received and bond interest, totals,
before/after cash balance. One player at a time. Uses `waitKey`.

**Confirmation Test 8.2:**

```
Supply known dividend values (Shady Brooks 100 shares = $700,
1 medium bond = $250). Verify all figures render correctly.
Verify screen skipped when called for Year 1 (caller responsibility;
    document that scrDivInt must not be called in Year 1 or Year 10).
```

---

### Task 8.3 — Situation card display screen (S11)

Procedure: `scrCard`

Displays card number, Bull/Bear type, flavour text, affected stocks
and deltas, dividend bonus if applicable.

**Confirmation Test 8.3:**

```
Display Card 1 (Bear, Growth Corp +10, divBonus=$2).
Verify type, flavour text, delta, and bonus all shown correctly.
Display Card 34 (Bull, 4 stocks). Verify all 4 stocks and deltas listed.
Display Card 36 (Bear, 3 stocks). Verify negative deltas shown.
```

---

### Task 8.4 — Dice roll display screen (S12)

Procedure: `scrDice`

Displays roll result(s). Under Mode A/B: one roll. Under Mode C: one
row per stock.

**Confirmation Test 8.4:**

```
Mode A: supply roll total=7. Verify single result displayed.
Mode C: supply 9 rolls (one per stock). Verify 9 rows displayed.
```

---

### Task 8.5 — Market results board screen (S13)

Procedure: `scrMktBoard`

Displays all 9 stocks: prior price, market delta, card delta, new price,
flags for split, dividend suspended/reinstated, bankruptcy.

**Confirmation Test 8.5:**

```
Supply state: stock 5 split (price 87, was 173), stock 2 suspended,
stock 8 reinstated, stock 3 at 0.
Verify each flag renders in the correct row.
Verify prices and deltas are numerically correct.
```

---

### Task 8.6 — Split notification (S14) and dividend status screens (S15)

Procedures: `scrSplit`, `scrDivFlag`

S14: displays old/new price and shares for each affected player.
S15: displays suspension or reinstatement with price context.

**Confirmation Test 8.6:**

```
S14: Player 1 held 100 Stryker, split to 200 at $87.
Verify old price=173, new price=87, shares before=100, after=200.
S15 SUSPENDED: stock at $45, cutoff $50.
S15 REINSTATED: stock at $55.
Verify correct event label and price shown for each case.
```

---

## 11. Phase 9 — Player Action Screens: Sell and Buy

**Goal:** Human players can execute sell and buy transactions. Engine
applies them correctly. Computer player summaries display.

---

### Task 9.1 — Human sell phase screen (S16)

Procedure: `scrSell`

Displays portfolio (shares, prices, margin flags) and bond holdings.
Accepts sell orders per asset. Validates: share quantity must be
positive multiple of 10, must not exceed held quantity.
Returns `sellOrders` array and `action` (Confirm/Pass).

**Confirmation Test 9.1:**

```
Player holds 100 Growth Corp at $120, 50 Shady Brooks at $85,
    1 medium bond.
Attempt to sell 15 shares (not multiple of 10) — verify rejection.
Attempt to sell 150 Growth Corp (exceeds holding) — verify rejection.
Sell 50 Growth Corp, pass on Shady Brooks, sell 1 bond.
Verify sellOrders array contains 2 entries with correct values.
Verify cashBal updated: 50*120 + 5000 = 11000 added to prior balance.
```

---

### Task 9.2 — Transaction engine: apply sell orders

Procedure: `applySells`

Applies validated sell orders from S16 to `plyrRec`. Handles margin
repayment on margin-held stock sales per spec Section 11.3.

**Confirmation Test 9.2:**

```
Player holds 100 Stryker on margin (marginTot = 5000),
    currentPrice = 80.
Sell 100 shares: proceeds = 8000.
marginTot must be repaid from proceeds.
After: cashBal += (8000 - 5000) = +3000 net, marginTot = 0.
```

---

### Task 9.3 — Human buy phase screen (S17)

Procedure: `scrBuy`

Displays cash balance, margin total, eligibility flags, all stock
prices, bond options. Accepts buy orders with purchase type
(Cash/Margin). Includes inline margin repayment entry (routes to S18
logic). Validates all purchases against cash balance and spec rules.

**Confirmation Test 9.3:**

```
Player cashBal = 3000, marginEligible = FALSE.
Attempt margin purchase — verify rejected.
Buy 20 Growth Corp at $100 (cost = 2000). Verify cashBal = 1000.
Attempt to buy 20 more (cost = 2000 > remaining 1000) — verify rejection.
Buy 1 small bond ($1000). Verify cashBal = 0.
```

---

### Task 9.4 — Margin repayment sub-screen (S18)

Procedure: `scrMgnRepay`

Accepts repayment amount within valid range (0 to MIN(marginTot,
cashBal)). Returns `amountToRepay : INTEGER`.

**Confirmation Test 9.4:**

```
marginTot = 2000, cashBal = 800.
Enter 900 — verify rejection (exceeds cashBal).
Enter 500 — verify accepted.
Enter 0 — verify accepted (no repayment).
After 500: cashBal = 300, marginTot = 1500.
```

---

### Task 9.5 — Computer player turn summary screen (S19)

Procedure: `scrAITurn`

Displays AI decisions (sell/buy/pass per asset) for sell and buy
phases. Returns on keypress.

**Confirmation Test 9.5:**

```
Supply a decision set: sell 50 Stryker, buy 20 Pioneer Mutual,
    repay $500 margin.
Verify all three decisions listed with correct asset names, quantities,
    and action labels.
```

---

## 12. Phase 10 — Margin Events, Forced Liquidation, Bankruptcy

**Goal:** All involuntary financial events resolve correctly per spec.

---

### Task 10.1 — Margin call alert screen (S20)

Procedure: `scrMgnCall`

Displays stock name, current price, margin call threshold, amount due.
Routes unconditionally to forced liquidation.

**Confirmation Test 10.1:**

```
Supply: Stryker at $22 (below $25 threshold), amountDue = 3000.
Verify all values displayed and screen proceeds to S21 on keypress.
```

---

### Task 10.2 — Forced liquidation screen (S21) and engine

Procedure: `scrForceLiq`
Procedure: `applyLiqOrdr`

S21 accepts liquidation sell orders. `applyLiqOrdr` applies them and
recalculates `obligationRemaining`. Loops until obligation = 0 or
no holdings remain.

**Confirmation Test 10.2:**

```
Obligation = 3000, Player holds 50 Metro at $50 and 1 small bond.
Sell 50 Metro: proceeds = 2500. Obligation remaining = 500.
Sell 1 bond: proceeds = 1000. Obligation remaining = 0. Loop exits.
Verify cashBal correctly updated across both sells.
```

---

### Task 10.3 — Bankruptcy declaration screen (S22)

Procedure: `scrBankrupt`

Displays player name, reason (MARGIN_INTEREST or MARGIN_CALL), year.
Sets `isBankrupt = TRUE` in `plyrRec`. Player removed from turn order.

**Confirmation Test 10.3:**

```
Trigger after forced liquidation with cashBal still negative.
Verify screen displays correct player name and reason.
Verify plyrRec.isBankrupt = TRUE after return.
Verify player is skipped in subsequent turn iteration.
```

---

### Task 10.4 — Margin clearance required screen (S23)

Procedure: `scrMgnClr`

Enforced at Year 10 boundary for players with `marginTot > 0`.
Loops until `marginTot = 0`. Same liquidation engine as Task 10.2.

**Confirmation Test 10.4:**

```
Entry to Year 10 with player marginTot = 4000.
Player sells sufficient assets to clear 4000.
Verify marginTot = 0 before Year 10 buy phase opens.
```

---

## 13. Phase 11 — End of Game Screens

---

### Task 11.1 — Final market board (S24), wealth summary (S25),
winner declaration (S26), post-game menu (S27)

Procedures: `scrFinalMkt`, `scrWealth`, `scrWinner`, `scrPostGame`

`scrWealth` computes `totalWealth` per spec Section 13 and sorts
players descending before display.

**Confirmation Test 11.1:**

```
Setup Year 10 end state:
    Player 1: cashBal=3000, 100 Valley Power at $95, 1 large bond.
        totalWealth = 3000 + 9500 + 10000 = 22500.
    Player 2: cashBal=8000, 50 Shady Brooks at $140, 0 bonds.
        totalWealth = 8000 + 7000 = 15000.
Verify scrWealth shows Player 1 first (higher total).
Verify scrWinner names Player 1.
Tie test: set both totals equal. Verify both names appear in scrWinner.
scrPostGame: verify New Game/Load Game/Quit options route correctly.
```

---

## 14. Phase 12 — Computer Player Sell and Buy Logic

**Goal:** AI sell and buy procedures produce correct, rule-compliant
decisions for baseline (Medium) tier before tier parameters are wired.

---

### Task 12.1 — AI sell procedure (Medium baseline)

Procedure: `aiSell`

Implements `ai-player-logic.md` Section 4 with hardcoded Medium
parameter values. Produces `sellOrders` array. Passes to `applySells`.

**Confirmation Test 12.1:**

```
Rule 1: stckPrice(2) = 0, sharesOwnd = 50 → SELL 50.
Rule 2: stckPrice(5) = 20, marginHeld = TRUE, sharesOwnd = 100 → SELL 100.
Rule 3: stckPrice(4) = 155, sharesOwnd = 100 → SELL 50 (50% of 100).
Rule 4: divSuspnd(1) = TRUE, stckPrice(1) = 45 → SELL all.
Rule 5: stckPrice(3) = 110, divSuspnd = FALSE → PASS.
Bond: cashBal >= 0 → PASS bonds.
Bond: cashBal = -100 → SELL 1 bond unit.
```

---

### Task 12.2 — AI buy procedure (Medium baseline)

Procedure: `aiBuy`

Implements `ai-player-logic.md` Section 5 with hardcoded Medium
parameters. Produces `buyOrders` array. Passes to `applyBuys`.

**Confirmation Test 12.2:**

```
Margin repayment: marginTot=2000, cashBal=500.
    annualCharge=100. 100 > (500*10/100=50). Repay 500*50/100=250.
    cashBal=250, marginTot=1750 after repayment.
Scoring: verify Shady Brooks scores higher than Growth Corp.
Concentration: cashBal=5000, Shady Brooks at $100.
    maxCash=5000*40/100=2000. maxLots=2000/100=20 → BUY 20 shares.
Bond fallback: no stocks bought, cashBal >= 5000 → BUY 1 medium bond.
Bond skip: stocks were bought → no bond.
```

---

## 15. Phase 13 — AIProfile Integration and Difficulty Tiers

**Goal:** All three tiers produce distinct, correct behavior from
AIProfile parameters. Endgame overrides apply correctly for Hard.

---

### Task 13.1 — Wire AIProfile into aiSell and aiBuy

Replace hardcoded Medium values in `aiSell` and `aiBuy` with
`aiProfile` field references per `ai-player-logic.md`.

**Confirmation Test 13.1:**

```
For each tier 1/2/3, initialize AIProfile and run the same sell/buy
scenario from Tasks 12.1 and 12.2.

Rule 3 split sell:
    Easy: SELL 20% of shares (splitSellPct=20).
    Medium: SELL 50%.
    Hard: SELL 30%.

Rule 4 distress:
    Easy/Medium: distressSellPrice=50. Stock at $48, suspended → SELL.
    Hard: distressSellPrice=60. Stock at $55, suspended → SELL.
    Hard: distressSellPrice=60. Stock at $65, suspended → PASS.

Concentration cap:
    Easy: 70% cap. Available=5000. Cap=3500. Lots at $100: 35 → BUY 30
        (rounded to multiple of 10).
    Hard: 25% cap. Available=5000. Cap=1250. Lots at $100: 12 → BUY 10.
```

---

### Task 13.2 — Endgame overrides (Hard tier, Year >= 7)

Verify endgame working variables override base values correctly for
Hard tier from Year 7 onward.

**Confirmation Test 13.2:**

```
Hard tier, Year 7:
    splitSellPctW should be 70 (override from 30).
    zeroDivEligibleW should be FALSE (same as normal Hard).
    repayFractionW should be 90 (override from 75).

Hard tier, Year 6:
    splitSellPctW should be 30 (no override yet).
    repayFractionW should be 75 (no override yet).

Easy tier, Year 7:
    endgameYear=0 → no override. All W variables equal base values.
```

---

# Revised Timeline — Backfill Tasks and Phase 14

---

## Backfill Task 10.5 — Margin Interest Notice screen (S10)

**Status:** Missing. No source file contains `scrMgnInt`. This screen
is referenced in `ui-screen-flow.md` as S10 and sits between
`applyMgnInt` (engine) and S11 (card display) in the year loop.

**Procedure:** `scrMgnInt`

Display-only. Shows each active, non-bankrupt player their annual
margin interest charge and resulting cash balance. If `forceLiq` is
TRUE for that player, displays a "FORCED LIQUIDATION" notice before
returning; the caller routes to `scrForceLiq`. One player at a time;
`waitKey` between players. No-op for Years 1 and 10 (caller
responsibility; procedure must guard internally as well).

```
PARAMS : plyrNam   - player name for display
         mgnCharge - interest deducted this year (>= 0)
         cashBef   - cash balance before deduction
         cashAft   - cash balance after deduction
         isFrcLiq  - TRUE if cashAft < 0 (forced liquidation flag)
         action    - OUT: always 1 (CONTINUE)
```

**Confirmation Test 10.5:**

```
Normal case: mgnCharge=100, cashBef=500, cashAft=400, isFrcLiq=FALSE.
    Verify charge and both balances displayed. No liquidation notice.

Forced case: mgnCharge=200, cashBef=150, cashAft=-50, isFrcLiq=TRUE.
    Verify charge and both balances displayed.
    Verify FORCED LIQUIDATION notice visible before waitKey.

Year guard: call with currYear=1. Verify no output produced.
```

**File:** `snbMargin.b09`

**Gate:** Must pass before Phase 14 begins. Insert into packed module
at same position as other `snbMargin.b09` procedures.

---

## Backfill Task 3.4a — Roll array support in `applyMktYear`

**Status:** Defect. `applyMktYear` accepts `roll : INTEGER` (scalar).
Mode B Year 1 and Mode C (absent a 2/12 override) require per-stock
rolls. The scalar is passed to `getMktDelta` for every stock, making
all nine stocks share the same roll result.

**Fix:** Replace `roll : INTEGER` with `rolls(9) : INTEGER`.

Inside `applyMktYear`, change:

```
RUN getMktDelta(s, card.crdType, roll, delta)
```

to:

```
RUN getMktDelta(s, card.crdType, rolls(s), delta)
```

**Caller contract (all modes):**

| Mode | Year | Action |
|------|------|--------|
| A    | Any  | Fill `rolls(1..9)` with the single roll value |
| B    | 1    | Fill `rolls(s)` independently for each stock s |
| B    | 2-10 | Fill `rolls(1..9)` with the single roll value |
| C    | Any  | Fill `rolls(s)` independently; apply 2/12 override first (see Task 14.0) |

**Confirmation Test 3.4a:**

```
Pass rolls(1)=7, rolls(2)=4, rolls(3..9)=7 (mixed).
Verify getMktDelta called with roll=7 for stock 1, roll=4 for stock 2.
Verify stock 2 delta differs from stocks 1/3-9.
Existing Task 3.4 tests remain valid: all slots filled with 5 → same
    result as before.
```

**File:** `snbMktEng.b09`

**Gate:** Must pass before Phase 14 begins.

---

## Backfill Task 14.0 — Roll generation and 2/12 override helper

**Procedure:** `doRolls`

Encapsulates all roll generation logic for a single year. Populates
`dieOne(9)`, `dieTwo(9)`, `rollTot(9)`, and the effective `rolls(9)`
array passed to `applyMktYear`. Also sets `rollCnt` for `scrDice`.

**Roll mode behavior:**

```
Mode A (rollMode=1), any year:
    Roll once. Fill all 9 slots of dieOne/dieTwo/rollTot with that
    result. rollCnt := 1.

Mode B (rollMode=2), Year 1:
    Roll independently per stock s=1..9.
    No 2/12 override rule applies to Mode B.
    rollCnt := 9.

Mode B (rollMode=2), Years 2-10:
    Same as Mode A.

Mode C (rollMode=3), any year:
For Mode C any year:
    Roll stocks s=1..9 in sequence
    EXITIF rollTot(s) = 2 OR rollTot(s) = 12 THEN
        fill rolls(1..9) all with rollTot(s)
        ovrdActive := TRUE
    ENDEXIT
    EXITIF s = 9 THEN
    ENDEXIT
```

```
PARAMS : rollMode     - 1=A 2=B 3=C
         currYear     - current game year (1..10)
         dieOne(9)    - OUT: die 1 per slot
         dieTwo(9)    - OUT: die 2 per slot
         rollTot(9)   - OUT: sum per slot
         rollCnt      - OUT: populated slot count (1 or 9)
         ovrdActive   - OUT: TRUE if 2/12 override fired (Mode C only)
```

**Confirmation Test 14.0:**

```
Mode A, Year 5: verify all 9 rollTot slots identical. rollCnt=1.

Mode B, Year 1: verify rollTot slots differ (statistical; run 3 times
    and confirm at least one difference across 9 stocks).

Mode B, Year 3: verify all 9 rollTot slots identical. rollCnt=1.

Mode C override: stub RND to produce roll=12 on stock 3.
    Verify rollTot(3..9) all = 12. ovrdActive = TRUE. rollCnt = 9.
    Verify rollTot(1) and rollTot(2) hold their independent results.

Mode C no override: stub RND to avoid 2/12 on all 9 stocks.
    Verify ovrdActive = FALSE. All 9 slots independent.
```

**File:** `snbMktEng.b09`

---

## 16. Phase 14 — Integration and Full Game Loop

**Goal:** A complete 10-year game runs from start screen to winner
declaration with at least one human and one computer player. All roll
modes verified. Save/resume verified. Bankruptcy path verified.

**Prerequisites before any Phase 14 task begins:**

- Task 10.5 (`scrMgnInt`) confirmed passing.
- Task 3.4a (`applyMktYear` roll array fix) confirmed passing.
- Task 14.0 (`doRolls`) confirmed passing.

---

### Stub Procedure Strategy

**Rationale:** `runYearLoop` must load alongside all engine, screen,
and AI procedures. The combined packed module may exceed available
memory before all real procedures are included. Stub procedures with
the same name and identical TYPE/PARAM signatures allow `runYearLoop`
to be tested end-to-end before all real procedures are packed.

**Stub contract:**

- TYPE and PARAM blocks must be byte-for-byte identical to the real
  procedure.
- All output PARAMs must be set to a safe default before END.
- A single PRINT trace line identifies the stub in output.
- `ON ERROR GOTO 900` and `900 ERROR(ERR) END` required.
- No functional logic.

**Stub targets and safe output defaults:**

| Procedure   | Key outputs and defaults                                  |
|-------------|-----------------------------------------------------------|
| `scrSell`   | `ordCnt := 0`, `action := 1`                             |
| `scrBuy`    | `ordCnt := 0`, `mgnRepay := 0`, `action := 1`            |
| `scrForceLiq` | `ordCnt := 0`, `action := 1`                           |
| `scrMgnClr` | `action := 1`                                            |
| `scrDivInt` | (display-only; no outputs)                               |
| `scrMgnInt` | `action := 1`                                            |
| `aiSell`    | `ordCnt := 0`                                            |
| `aiBuy`     | `ordCnt := 0`, `mgnRepay := 0`                           |
| `scrAITurn` | (display-only; no outputs)                               |

**Integration sequence:** Stubs are packed with `runYearLoop` first.
Real procedures replace stubs one at a time after the loop logic is
confirmed stable. This allows isolated regression testing at each
swap.

---

### Task 14.1-P1 — Interface and variable scoping

Define the complete TYPE, PARAM, and DIM block for `runYearLoop`.
Resolve all naming collisions between local variables and TYPE field
names. No executable logic beyond skeleton structure.

**Collision resolutions (confirmed against SaveHdr, PlyrRec,
MktState field names):**

| Intended purpose       | Collision field     | Local name used  |
|------------------------|---------------------|------------------|
| Current year counter   | `hdr.currYear`      | `cYear`          |
| Player count           | `hdr.plyrCount`     | `pCnt`           |
| Roll mode              | `hdr.rollMode`      | `rMode`          |
| Forced liquidation flags | (none; new array) | `forceLiq(6)`    |
| Game-over sentinel     | (none)              | `gameOver`       |
| Active player count    | (none)              | `activeCnt`      |

**Stub pack:** All stub procedures loaded and resident before
`runYearLoop` is compiled. Verify SIZE() of the combined variable
space is under 32KB before proceeding to P2.

**Confirmation Test 14.1-P1:**

```
Compile runYearLoop skeleton (no logic). Verify no Error #076
    (Multiply-defined Variable). Verify no Error #009 (Type mismatch)
    on BYTE-to-INTEGER staging variables.
Print SIZE() of all DIM arrays in runYearLoop. Total < 32KB.
```

---

### Task 14.1-P2 — Revenue and margin sub-loops

Implement Year 1/10 guards and the dividend/margin interest sequence:

```
Step 1: IF cYear > 1 AND cYear < 10 THEN
    RUN applyDivInt(cYear, pCnt, plyrs, mkt)
    FOR p := 1 TO pCnt (non-bankrupt players)
        show scrDivInt per player
    ENDIF

Step 2: IF cYear > 1 AND cYear < 10 THEN
    initialize forceLiq(1..pCnt) := FALSE
    RUN applyMgnInt(cYear, pCnt, plyrs, forceLiq)
    FOR p := 1 TO pCnt (non-bankrupt players with marginTot > 0)
        RUN scrMgnInt(...)
        IF forceLiq(p) THEN route to forced liquidation (GOSUB 500)
    ENDIF
```

The forced liquidation GOSUB at line 500 is stubbed as a PRINT
placeholder in this phase. It is fully implemented in P4.

**Confirmation Test 14.1-P2:**

```
Year 1: verify applyDivInt and applyMgnInt not called.
Year 5, player with margin: verify scrMgnInt called with correct
    charge and cashAft values. Stub scrMgnInt prints trace.
Year 10: verify both steps skipped.
```

---

### Task 14.1-P3 — Market resolution mechanics

Implement card draw, roll generation, and price resolution:

```
Step 3: RUN drawCard(hdr, card)   \ ! draws from shuffled deck
Step 4: RUN scrCard(card, action)
Step 5: RUN doRolls(rMode, cYear, dieOne, dieTwo, rollTot,
                    rollCnt, ovrdActive)
        RUN scrDice(rMode, rollCnt, dieOne, dieTwo, rollTot, action)
Steps 6-8: RUN applyMktYear(card.cardId, rolls, pCnt, plyrs, mkt,
                    prcBef, mktDlta, crdDlta, splitOcc,
                    divSuspd, divRnstd)
           \ ! Line exceeds 79 chars; documented exception.
        RUN scrMktBoard(prcBef, mktDlta, crdDlta, mkt.stckPrice,
                    splitOcc, divSuspd, divRnstd, action)
        FOR s := 1 TO 9
            IF splitOcc(s): RUN scrSplit(...)
            IF divSuspd(s) OR divRnstd(s): RUN scrDivFlag(...)
        NEXT s
        IF card.divBonus > 0 AND cYear > 1 AND cYear < 10 THEN
            apply Card 1 dividend bonus to all non-bankrupt players
        ENDIF
```

**Confirmation Test 14.1-P3:**

```
Year 3, Mode A: verify card drawn, dice displayed, market board
    shown with correct deltas. Stub scrMktBoard prints trace.
Card 1 bonus: set divBonus > 0, Year 2. Verify cashBal incremented
    per share held. Year 1: verify bonus not applied.
Mode C, override roll=12: verify all 9 stocks use roll 12 delta.
```

---

### Task 14.1-P4 — Player action and liquidation logic

Implement sell phase (skipped Year 1), buy phase, margin call check,
forced liquidation GOSUB, and Year 10 margin clearance gate.

**Sell phase (GOSUB 300):**

```
SELL_GATE: IF cYear = 1 THEN GOTO BUY_PHASE
FOR p := 1 TO pCnt
    IF plyrs(p).isBankrupt THEN skip
    IF plyrs(p).plyrType = 1 THEN
        RUN scrSell(cYear, plyrs(p), mkt, ordType, ordId,
                    ordQty, ordCnt, action)
        IF ordCnt > 0: RUN applySells(plyrs(p), mkt,
                    ordType, ordId, ordQty, ordCnt)
        check margin call per stock → GOSUB 500 if triggered
    ELSE
        RUN aiSell(cYear, plyrs(p), mkt, prof(p),
                    ordType, ordId, ordQty, ordCnt)
        IF ordCnt > 0: RUN applySells(...)
        RUN scrAITurn(...)
        check margin call → GOSUB 500 if triggered
    ENDIF
NEXT p
```

**Margin call trigger (per stock s, per player p):**

```
IF plyrs(p).mgnHeld(s) AND mkt.stckPrice(s) <= 25 THEN
    obligation := plyrs(p).marginTot
    RUN scrMgnCall(plyrs(p).plyrName, sNam(s),
                   mkt.stckPrice(s), 25, obligation)
    GOSUB 500   \ ! forced liquidation handler
ENDIF
```

**Forced liquidation GOSUB 500:**

```
500 LOOP
    RUN scrForceLiq(plyrs(p).plyrName, oblgRem, plyrs(p), mkt,
                    ordType, ordId, ordQty, ordCnt, liqAction)
    IF liqAction = 2 THEN GOSUB 600  \ ! bankruptcy
        RETURN
    ENDIF
    IF ordCnt > 0 THEN
        RUN applyLiqOrdr(plyrs(p), mkt, ordType, ordId,
                         ordQty, ordCnt, oblgRem)
    ENDIF
    EXITIF oblgRem <= 0 THEN
    ENDEXIT
    ! Implicit bankruptcy guard: if ordCnt=0 and oblgRem>0,
    ! no progress possible; force bankruptcy.
    IF ordCnt = 0 THEN GOSUB 600  \ ! bankruptcy
        RETURN
    ENDIF
ENDLOOP
RETURN
```

**Bankruptcy GOSUB 600:**

```
600 RUN scrBankrupt(plyrs(p), plyrs(p).cashBal, bkReason, cYear)
activeCnt := activeCnt - 1
IF activeCnt <= 1 THEN gameOver := TRUE
RETURN
```

**Year 10 margin clearance (before buy phase):**

```
IF cYear = 10 THEN
    FOR p := 1 TO pCnt
        IF NOT plyrs(p).isBankrupt THEN
            LOOP
                EXITIF plyrs(p).marginTot <= 0 THEN
                ENDEXIT
                RUN scrMgnClr(plyrs(p), mkt, mgnClrAct)
                IF mgnClrAct = 2 THEN GOSUB 600
                    EXITIF TRUE THEN
                    ENDEXIT
                ENDIF
            ENDLOOP
        ENDIF
    NEXT p
ENDIF
```

**Buy phase:** Mirrors sell phase structure. `mgnYrOk := (cYear < 10)`.
For human: `RUN scrBuy(...)`, apply repayment, then `applyBuys`.
For AI: `RUN aiBuy(...)`, apply repayment, then `applyBuys`.

**Confirmation Test 14.1-P4:**

```
Year 1: verify sell phase skipped entirely.
Year 2 human sell, no orders (stub): verify applySells not called.
Margin call trigger: set mgnHeld(3)=TRUE, stckPrice(3)=20.
    Verify scrMgnCall called, then scrForceLiq called.
    Stub scrForceLiq returns action=1, ordCnt=0 → implicit bankruptcy.
    Verify scrBankrupt called. activeCnt decremented.
Year 10 margin clearance: set marginTot=1000 before buy phase.
    Stub scrMgnClr returns action=1. Verify loop re-entered until
    marginTot manually zeroed (simulate via save edit or stub).
```

---

### Task 14.1-P5 — Endgame sequence and confirmation test

Implement the year-end check and post-Year-10 routing:

```
YEAR_END:
    IF cYear = 10 OR gameOver THEN
        RUN scrFinalMkt(mkt)
        RUN scrWealth(plyrs, pCnt, mkt, wlth, srtOrd)
        RUN scrWinner(plyrs, pCnt, wlth, srtOrd)
        RUN scrPostGame(pgAction)
        ! Caller handles pgAction routing (SNBMAIN).
        END
    ELSE
        cYear := cYear + 1
        hdr.currYear := cYear  \ ! BYTE stage back
        GOTO YEAR_TOP
    ENDIF
```

**Single-survivor early exit:** `gameOver` is set TRUE in GOSUB 600
when `activeCnt <= 1`. The `YEAR_END` check fires at the bottom of
the current year's loop iteration; no partial-year continuation.

**Confirmation Test 14.1-P5 (Task 14.1 full test):**

```
Run complete game: 1 human (stub scrSell/scrBuy → pass all),
    1 computer Medium, Roll Mode A.
Verify:
    Year 1: no dividend screen, no margin screen, no sell phase.
    Year 10: no dividend screen, no margin screen, margin clearance
        gate entered for any player with marginTot > 0.
    All 10 years iterate. scrFinalMkt, scrWealth, scrWinner,
        scrPostGame all called in sequence after Year 10.
    No stack overflow or Error #090 (out of memory).
    gameOver path: manually set activeCnt=1 in Year 5 stub.
        Verify game routes to endgame after Year 5 rather than
        continuing to Year 6.
```

---

### Task 14.2 — Stub-to-real procedure swap sequence

Replace stub procedures with real implementations one at a time.
Confirm each swap passes prior test before proceeding.

**Recommended swap order (least-to-most complex; minimizes
regression blast radius):**

1. `scrDivInt` — display-only, no input
2. `scrMgnInt` — display-only, no input
3. `scrAITurn` — display-only, no input
4. `aiSell` — no input, deterministic
5. `aiBuy` — no input, deterministic
6. `scrSell` — human input, sell phase only
7. `scrBuy` — human input, buy phase
8. `scrForceLiq` — human input, liquidation path
9. `scrMgnClr` — human input, Year 10 only

After each swap, re-run the Task 14.1-P5 confirmation test.

---

### Task 14.3 — Save and resume integration

**Confirmation Test 14.3:**

```
During Year 5 sell phase (human player's turn), invoke save.
Quit game. Reload save from main menu.
Verify game resumes at Year 5 sell phase for the correct player.
Verify stock prices, player portfolios, and deck position all
    match pre-save state.
Verify all subsequent years complete correctly after resume.
```

---

### Task 14.4 — All three roll modes end-to-end

**Confirmation Test 14.4:**

```
Mode A: run 3-year game. Verify all 9 stocks share same roll each year.
Mode B: run 3-year game. Year 1: verify 9 independent rolls.
    Years 2-3: verify single roll applies to all stocks.
Mode C no override: stub RND to avoid 2/12. Verify 9 independent
    deltas per stock each year.
Mode C with override: stub RND to produce 12 on stock 4 in Year 2.
    Verify all 9 stocks use roll=12 delta that year.
    Verify rolls(1..3) used their independent values in Year 2
    before override (stocks 1-3 already resolved individually
    before stock 4 triggered override).
```

**Note on Mode C semantics:** Stocks 1 through (trigger-1) have
already been independently resolved before the 2/12 roll fires.
`applyMktYear` processes them with their individual rolls.
Stocks from the trigger point onward all receive the override roll.
This is consistent with the user-confirmed rule: "rolling stops as
soon as the first 2 or 12 is rolled."

---

## Updated Phase Summary Table (revised rows only)

| Phase | Tasks        | Gate Condition                                        |
|-------|--------------|-------------------------------------------------------|
| 3     | 3.1–3.4, **3.4a** | All price resolution verified; roll array fix confirmed |
| 10    | 10.1–10.4, **10.5** | All margin/bankruptcy paths verified; scrMgnInt confirmed |
| 14    | **14.0**, 14.1-P1 through P5, 14.2–14.4 | Full 10-year game with all roll modes and save/resume confirmed |

---

## 17. Phase 15 — Regression, Edge Cases, and Final QA

---

### Task 15.1 — Memory budget verification

Run `SIZE()` on all active TYPEs and DIM arrays in each major
procedure. Total must remain under 32KB.

**Confirmation Test 15.1:**

```
Produce a memory audit: list all DIM arrays and TYPE instances in
the year loop procedure context with their SIZE() values.
Sum must be < 32768.
Document the total in a comment in the main procedure header.
```

---

### Task 15.2 — Edge case: all players bankrupt except one

**Confirmation Test 15.2:**

```
Arrange all players bankrupt except one via save edit.
Verify game ends immediately with that player declared winner
    without completing the remaining years.
```

---

### Task 15.3 — Edge case: tie at Year 10

**Confirmation Test 15.3:**

```
Arrange two players with identical totalWealth via save edit.
Verify scrWinner displays both names.
```

---

### Task 15.4 — Edge case: deck exhaustion and reshuffle

**Confirmation Test 15.4:**

```
Play 37 card draws across multiple years (requires a long game or
    save edit on deckPos).
Verify reshuffle triggers correctly at draw 37.
Verify no card repeats before reshuffle at draw 36.
```

---

### Task 15.5 — Reserved word audit

Review all TYPE field names, procedure names, variable names, and
array names in every `.b09` file against the reserved words list in
`bestPractices.md`.

**Confirmation Test 15.5:**

```
No reserved word appears as an identifier in any source file.
Document any near-conflicts (names that were avoided and what was
    used instead) in a comment at the top of the affected procedure.
```

---

### Task 15.6 — Full QA checklist sign-off

Apply the full QA checklist from the project instructions Section 5
to every procedure in the codebase:

- All IF/WHILE/FOR/LOOP/REPEAT/EXITIF blocks correctly closed
- All ELSE IF nesting has matching ENDIF count
- Every procedure has ON ERROR GOTO handler
- Every procedure ends with END
- No RETURN outside GOSUB
- No MODULE/ENDMODULE present
- No GOTO/GOSUB crosses procedure boundaries
- TYPE declarations before PARAM before DIM in every procedure
- All STRING variables with non-default lengths explicitly DIMmed
- All line numbers unique and monotonically increasing per procedure
- No line exceeds 79 characters

**Confirmation Test 15.6:**

```
Checklist completed and initialed for every procedure.
Zero open items before release commit.
```

---

## 18. Task Summary Table

| Phase | Tasks | Gate Condition                                  |
|-------|-------|-------------------------------------------------|
| 1     | 1.1–1.4 | All TYPEs compile; SIZE() values match spec   |
| 2     | 2.1–2.2 | All market table and card lookups verified    |
| 3     | 3.1–3.4 | All price resolution logic verified           |
| 4     | 4.1–4.2 | Shuffle and draw confirmed correct            |
| 5     | 5.1–5.3 | Round-trip save/load verified; checksum works |
| 6     | 6.1–6.4 | All display primitives working on target      |
| 7     | 7.1–7.4 | Full setup flow routes correctly              |
| 8     | 8.1–8.6 | All market resolution screens render correctly|
| 9     | 9.1–9.5 | Human sell/buy with validation; AI summary    |
| 10    | 10.1–10.4 | All margin/bankruptcy paths verified        |
| 11    | 11.1    | End-of-game screens and tie handling verified |
| 12    | 12.1–12.2 | AI baseline decisions correct for all rules |
| 13    | 13.1–13.2 | All three tiers produce distinct behavior   |
| 14    | 14.1–14.4 | Full 10-year game completes correctly       |
| 15    | 15.1–15.6 | Memory budget, edge cases, QA checklist     |
