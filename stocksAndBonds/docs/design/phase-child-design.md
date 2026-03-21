# SNB Phase-Child Architecture Design (Revised)

**Replaces:** `snbYearLoop.b09` (disposed of entirely).
**Margin rules:** Deferred. No mgnChild, no GS_MGN, no snbMargin/snbMgnScr
in pre-fork ensures.

---

## 1. gameStage Constants

| Value | Constant | Written By | Coordinator Action |
|-------|----------|-----------|-------------------|
| 1 | GS_PREGM | pgChild | Begin year loop |
| 2 | GS_YEAR | Any phase child | Continue year sequence |
| 3 | GS_DONE | tradeChild | Fork egChild; exit loop |

---

## 2. currYear Convention

`pgChild` writes `currYear=0` (pre-game; no year yet started).

`divChild` increments `currYear` at the very start of its run, before
doing any other work. After divChild exits, `currYear` in SNBSTATE
equals the year being actively processed. `mktChild` and `tradeChild`
read this value directly.

| State | currYear value |
|-------|---------------|
| After pgChild | 0 |
| During Year 1 (after divChild) | 1 |
| During Year 10 (after divChild) | 10 |

---

## 3. Phase Child Inventory

### 3.1 pgChild
- **Module:** `snbSetup.b09`
- **Pre-fork deps:** snbSaveLoad, snbSetup
- **Writes:** `currYear=0`, `gameStage=GS_PREGM (1)`
- **Responsibility:** Setup screens. Writes nothing on quit.

### 3.2 divChild
- **Module:** `snbDividend.b09`
- **Pre-fork deps:** snbSaveLoad, snbDividend
- **Writes:** `currYear=N` (incremented), `gameStage=GS_YEAR (2)`
- **Responsibility:**
  - Increments `currYear` immediately (all years)
  - Displays S8 (scrYearHdr) every year
  - Applies dividends and bond interest in Years 2-9 only
    (spec Section 6: skipped in Year 1 and Year 10)
  - Displays S9 (scrDivInt) per non-bankrupt player (Years 2-9 only)
  - Year 1 and Year 10: increment and year header only; no financial work

### 3.3 mktChild
- **Module:** `snbMarket.b09`
- **Pre-fork deps:** snbSaveLoad, snbMarket
- **Writes:** `gameStage=GS_YEAR (2)`
- **Responsibility:** Steps 3-8 per spec.
  - Draws card (drawCard / getCard), displays S11 (scrCard)
  - Generates dice rolls (doRolls), displays S12 (scrDice)
  - Resolves prices (applyMktYear), displays S13 (scrMktBoard)
  - Displays S14 (scrSplit) and S15 (scrDivFlag) per stock as needed
  - Applies Card 1 dividend bonus (Years 2-9 only)
  - Runs every year

### 3.4 tradeChild
- **Module:** `snbBuySell.b09`
- **Pre-fork deps:** snbSaveLoad, snbBuySell, snbTrade, snbAI
- **Writes:** `gameStage=GS_DONE (3)` when game ends; `GS_YEAR (2)`
  otherwise.
- **Responsibility:** Steps 9-10 per spec.
  - Sell phase: skipped internally when `currYear = 1`
  - Buy phase: runs every year
  - After buy phase: counts active (non-bankrupt) players.
    If `currYear >= maxYears` OR `activePlrs <= 1`: writes GS_DONE.
    Otherwise: writes GS_YEAR.

### 3.5 egChild
- **Module:** `snbEndGame.b09`
- **Pre-fork deps:** snbSaveLoad, snbEndGame
- **Responsibility:** Existing procedure. Loads SNBSTATE, runs
  S24-S27, exits.

---

## 4. Coordinator Year Sequence

```
LOOP
  EXITIF iCYr >= iMaxYr OR gameOver

  fork divChild   -> GOSUB 100 (updates iCYr, iGSt, gameOver)
  fork mktChild   -> GOSUB 100
  fork tradeChild -> GOSUB 100

  safety nets: iCYr >= iMaxYr, activePlrs <= 1
ENDLOOP
```

`GOSUB 100` updates `iCYr` from `hdr.currYear` on every call, so
after `divChild` exits the coordinator always has the current year.

---

## 5. Module Inventory

| Module | Procedures | Role |
|--------|-----------|------|
| `snbSetup.b09` | snbSetup, initPlayer, initMkt, scrStart, scrSetup, scrConfirm, pgChild | Pre-game setup and pgChild entry |
| `snbDividend.b09` | snbDividend, divChild, applyDivInt, scrYearHdr, scrDivInt | Year increment; dividends and bond interest |
| `snbMarket.b09` | snbMarket, mktChild, getMktDelta, getCard, resolvePrice, applyMktYear, drawCard, doRolls, scrCard, scrDice, scrMktBoard, scrSplit, scrDivFlag | Market resolution |
| `snbBuySell.b09` | snbBuySell, tradeChild, scrSell, scrBuy | Sell and buy phases |
| `snbTrade.b09` | snbTrade, scrMgnRepay, scrAITurn, applySells, applyBuys | Trade execution engines |
| `snbAI.b09` | snbAI, initAIProf, aiSell, aiBuy | Computer player logic |
| `snbEndGame.b09` | snbEndGame, egChild, scrFinalMkt, scrWealth, scrWinner, scrPostGame | End-game screens |
| `snbSaveLoad.b09` | snbSaveLoad, saveGame, loadGame, guardSave | Save/load; SNBSTATE IPC |
| `snbUtil.b09` | snbUtil, clrScr, printAt, fmtMoney, getMenuKey, waitKey, getNumIn, shuffleDeck | Utilities; permanent resident |
| `SNB.b09` | SNB, ensureModule, chkStale, readHdr, forkPhase | Coordinator |

**Retired modules (remove from /dd/cmds):**
- `snbMktEng` — procedures redistributed to snbDividend and snbMarket
- `snbMktScr` — procedures redistributed to snbDividend and snbMarket
- `snbYearLoop` — replaced by phase child architecture

---

## 6. Implementation Sequence

| Step | Deliverable | Test |
|------|-------------|------|
| C0 | pgChild currYear=0 fix | Re-run TSTCOORDLP |
| C1 | divChild in snbDividend.b09 | TSTDIVCHLD |
| C2 | mktChild in snbMarket.b09 | TSTMKTCHLD |
| C3 | tradeChild in snbBuySell.b09 | TSTTRCHLD |
| C4 | Full integration | TSTFULLGM |

---

## 7. pgChild Change Required

In `snbSetup.b09`, procedure `pgChild`, change one line:

```
! Before:
hdr.currYear := 1

! After:
hdr.currYear := 0  ! pre-game; divChild increments to 1 on first run
```