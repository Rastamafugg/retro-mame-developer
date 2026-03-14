# Stocks and Bonds — Module Phase Transition Table

**Version:** 0.1 (pre-measurement draft)
**Status:** Design artifact. Memory cost columns are TBD pending hardware
measurement. Module sizes populated by Step 1 hardware pilot.

---

## 1. Entry Procedures

Each packed module file is named after the first procedure in its PACK list.
All such entry procedures must carry the `snb` prefix for consistent file
grouping. The table below records every entry procedure for each module.

| Entry Procedure | Module File   | Source File         |
|-----------------|---------------|---------------------|
| `SNB`           | `SNB`         | `snb.b09`           |
| `snbYearLoop`   | `snbYearLoop` | `snbGameLoop.b09`   |
| `snbUtil`       | `snbUtil`     | `snb.b09`           |
| `snbSaveLoad`   | `snbSaveLoad` | `snbSaveLoad.b09`   |
| `snbMktEng`     | `snbMktEng`   | `snbMktEng.b09`     |
| `snbMktScr`     | `snbMktScr`   | `snbMktScr.b09`     |
| `snbTrade`      | `snbTrade`    | `snbTrade.b09`      |
| `snbBuySell`    | `snbBuySell`  | `snbBuySell.b09`    |
| `snbMargin`     | `snbMargin`   | `snbMargin.b09`     |
| `snbMgnScr`     | `snbMgnScr`   | `snbMgnScr.b09`     |
| `snbAI`         | `snbAI`       | `snbAI.b09`         |
| `snbEndGame`    | `snbEndGame`  | `snbEndGame.b09`    |

---

## 2. Module Roster

| Module File    | Constituent Procedures                                                                                   | Deps at Runtime      |
|----------------|----------------------------------------------------------------------------------------------------------|----------------------|
| `snbUtil`      | snbUtil, clrScr, printAt, fmtMoney, getMenuKey, waitKey, getNumIn, shuffleDeck                           | *(none)*             |
| `snbMemMgmt`   | snbMemMgmt, memMapGet, memModGet, memReport, memEnsure, memRelease                                       | *(none)*             |
| `SNB`          | SNB, initPlayer, initMkt, scrStart, scrSetup, scrConfirm                                                 | snbUtil, snbSaveLoad |
| `snbSaveLoad`  | snbSaveLoad, saveGame, loadGame                                                                          | snbUtil              |
| `snbYearLoop`  | snbYearLoop, runYearLoop                                                                                 | snbUtil              |
| `snbMktEng`    | snbMktEng, getMktDelta, getCard, resolvePrice, applyMktYear, applyDivInt, applyMgnInt, drawCard, doRolls | snbUtil              |
| `snbMktScr`    | snbMktScr, scrYearHdr, scrDivInt, scrDivFlag, scrCard, scrDice, scrMktBoard, scrSplit                    | snbUtil, snbMktEng   |
| `snbTrade`     | snbTrade, scrMgnRepay, scrAITurn, applySells, applyBuys                                                  | snbUtil              |
| `snbBuySell`   | snbBuySell, scrSell, scrBuy                                                                              | snbUtil              |
| `snbMargin`    | snbMargin, scrMgnCall, applyLiqOrdr, scrBankrupt, scrMgnInt                                              | snbUtil, snbTrade    |
| `snbMgnScr`    | snbMgnScr, scrForceLiq, scrMgnClr                                                                        | snbUtil, snbTrade    |
| `snbAI`        | snbAI, initAIProf, aiSell, aiBuy                                                                         | snbUtil              |
| `snbEndGame`   | snbEndGame, scrFinalMkt, scrWealth, scrWinner, scrPostGame                                               | snbUtil              |

---

## 3. Memory Cost File (Stub)

Populated by hardware measurement during Step 1 pilot and subsequent
phases. `modSzRpt` is reporting tool for generating these values.

| Module File    | Procedure      | Mem Size (Bytes) |
|----------------|----------------|------------------|
| `snbUtil`      | snbUtil        | 133              |
| `snbUtil`      | clrScr         | 97               |
| `snbUtil`      | printAt        | 136              |
| `snbUtil`      | fmtMoney       | 233              |
| `snbUtil`      | getMenuKey     | 214              |
| `snbUtil`      | waitKey        | 136              |
| `snbUtil`      | getNumIn       | 128              |
| `snbUtil`      | shuffleDeck    | 219              |
| `snbMemMgmt`   | snbMemMgmt     | 133              |
| `snbMemMgmt`   | memMapGet      | 3604             |
| `snbMemMgmt`   | memModGet      | 1366             |
| `snbMemMgmt`   | memReport      | 840              |
| `snbMemMgmt`   | memEnsure      | 656              |
| `snbMemMgmt`   | memRelease     | 826              |
| `SNB`          | SNB            | 827              |
| `SNB`          | initPlayer     | 316              |
| `SNB`          | initMkt        | 146              |
| `SNB`          | scrStart       | 241              |
| `SNB`          | scrSetup       | 505              |
| `SNB`          | scrConfirm     | 470              |
| `snbSaveLoad`  | snbSaveLoad    | 87               |
| `snbSaveLoad`  | saveGame       | 455              |
| `snbSaveLoad`  | loadGame       | 650              |
| `snbYearLoop`  | snbYearLoop    | 76               |
| `snbYearLoop`  | runYearLoop    | 5537             |
| `snbMktEng`    | snbMktEng      | 199              |
| `snbMktEng`    | getMktDelta    | 911              |
| `snbMktEng`    | getCard        | 1644             |
| `snbMktEng`    | resolvePrice   | 222              |
| `snbMktEng`    | applyMktYear   | 865              |
| `snbMktEng`    | applyDivInt    | 619              |
| `snbMktEng`    | applyMgnInt    | 318              |
| `snbMktEng`    | drawCard       | 133              |
| `snbMktEng`    | doRolls        | 763              |
| `snbMktScr`    | snbMktScr      | 174              |
| `snbMktScr`    | scrYearHdr     | 370              |
| `snbMktScr`    | scrDivInt      | 848              |
| `snbMktScr`    | scrDivFlag     | 353              |
| `snbMktScr`    | scrCard        | 673              |
| `snbMktScr`    | scrDice        | 671              |
| `snbMktScr`    | scrMktBoard    | 724              |
| `snbMktScr`    | scrSplit       | 422              |
| `snbTrade`     | snbTrade       | 116              |
| `snbTrade`     | scrMgnRepay    | 669              |
| `snbTrade`     | scrAITurn      | 1052             |
| `snbTrade`     | applySells     | 633              |
| `snbTrade`     | applyBuys      | 630              |
| `snbBuySell`   | snbBuySell     | 82               |
| `snbBuySell`   | scrSell        | 2806             |
| `snbBuySell`   | scrBuy         | 3595             |
| `snbMargin`    | snbMargin      | 106              |
| `snbMargin`    | scrMgnCall     | 403              |
| `snbMargin`    | applyLiqOrdr   | 680              |
| `snbMargin`    | scrBankrupt    | 608              |
| `snbMargin`    | scrMgnInt      | 590              |
| `snbMgnScr`    | snbMgnScr      | 87               |
| `snbMgnScr`    | scrForceLiq    | 2660             |
| `snbMgnScr`    | scrMgnClr      | 3513             |
| `snbAI`        | snbAI          | 86               |
| `snbAI`        | initAIProf     | 800              |
| `snbAI`        | aiSell         | 2536             |
| `snbAI`        | aiBuy          | 2756             |
| `snbEndGame`   | snbEndGame     | 121              |
| `snbEndGame`   | scrFinalMkt    | 646              |
| `snbEndGame`   | scrWealth      | 1143             |
| `snbEndGame`   | scrWinner      | 550              |
| `snbEndGame`   | scrPostGame    | 206              |

---

## 4. Phase Definitions

Phases are named game states that drive load/release decisions. Each phase
has a defined entry event, an exit event, and a fixed module set that must
be resident for the phase to execute. Modules outside the required set for
a given phase are candidates for release at that phase's entry, subject to
the retention policy in Section 5.

| Phase ID | Phase Name            | Entry Event                              | Exit Event                                |
|----------|-----------------------|------------------------------------------|-------------------------------------------|
| PH-00    | Launch                | Application start (`SNB` executed)       | S1 displayed                              |
| PH-01    | Main Menu             | S1 displayed                             | Player selects New Game, Load, or Quit    |
| PH-02    | New Game Setup        | Player selects New Game                  | S7 Confirm pressed                        |
| PH-03    | Load Game             | Player selects Load Game                 | Load succeeds or fails                    |
| PH-04    | Game Initialization   | Setup confirmed or load succeeded        | `snbYearLoop` entry called                |
| PH-05    | Year Header           | Year loop iteration begins               | S8 dismissed (any year)                   |
| PH-06    | Revenue Phase         | S8 dismissed, Year 2–9                   | All players processed for div/margin      |
| PH-07    | Market Phase          | Revenue phase complete (or Year 1/10)    | S13 (market board) dismissed              |
| PH-08    | Trade Phase           | Market phase complete                    | All players complete sell and buy         |
| PH-09    | Margin Phase          | During trade phase, margin call trigger  | Margin call resolved (repay or bankrupt)  |
| PH-10    | Year 10 Margin Clear  | Year 10 buy phase entry, marginTot > 0   | All marginTot cleared or bankruptcy       |
| PH-11    | Year Save             | End of each complete year                | Save written to disk                      |
| PH-12    | End Game              | Year 10 market board dismissed           | S27 player choice recorded                |
| PH-13    | Post-Game             | S27 displayed                            | Player selects New Game, Load, or Quit    |

---

## 5. Phase Transition Table

For each phase, columns are:

- **Load on Entry:** modules brought into memory when this phase begins
- **Required Resident:** full set of modules that must be in memory during this phase
- **Release on Exit:** modules unloaded when this phase ends
- **Notes:** constraints, ordering requirements, retention flags

`snbUtil` and `snbYearLoop` (during PH-05 through PH-12) are omitted from
individual phase rows as they are permanently resident once loaded. See
Section 6 for the permanent-resident policy.

---

### PH-00 — Launch

| Field              | Value                                |
|--------------------|--------------------------------------|
| Load on Entry      | snbUtil, snbMemMgmt, SNB             |
| Required Resident  | snbUtil, snbMemMgmt, SNB             |
| Release on Exit    | *(none)*                             |
| Notes              | snbUtil is never released after load. SNB remains through PH-04. |

---

### PH-01 — Main Menu (S1)

| Field              | Value                                |
|--------------------|--------------------------------------|
| Load on Entry      | *(none)*                             |
| Required Resident  | snbUtil, snbMemMgmt, SNB             |
| Release on Exit    | *(none)*                             |
| Notes              | scrStart is within SNB. No additional loads. |

---

### PH-02 — New Game Setup (S2 → S7)

| Field              | Value                                |
|--------------------|--------------------------------------|
| Load on Entry      | *(none)*                             |
| Required Resident  | snbUtil, snbMemMgmt, SNB             |
| Release on Exit    | *(none)*                             |
| Notes              | scrSetup and scrConfirm are within SNB. No additional loads needed until PH-04. |

---

### PH-03 — Load Game

| Field              | Value                                     |
|--------------------|-------------------------------------------|
| Load on Entry      | snbSaveLoad                               |
| Required Resident  | snbUtil, snbMemMgmt, SNB, snbSaveLoad     |
| Release on Exit    | snbSaveLoad                               |
| Notes              | snbSaveLoad loaded only for the duration of the load call. Released immediately on success or failure. SNB remains through PH-04. |

---

### PH-04 — Game Initialization

| Field              | Value                                                |
|--------------------|------------------------------------------------------|
| Load on Entry      | snbYearLoop, snbMktEng                               |
| Required Resident  | snbUtil, snbMemMgmt, SNB, snbMktEng, snbYearLoop     |
| Release on Exit    | SNB                                                  |
| Notes              | initPlayer and initMkt execute within SNB. shuffleDeck requires snbUtil. SNB is released after initialization is complete and before snbYearLoop begins its first iteration. snbMktEng is retained into PH-05/PH-06 to avoid an immediate load at PH-07. |

---

### PH-05 — Year Header (S8)

| Field              | Value                                                  |
|--------------------|--------------------------------------------------------|
| Load on Entry      | snbMktScr                                              |
| Required Resident  | snbUtil, snbMemMgmt, snbYearLoop, snbMktEng, snbMktScr |
| Release on Exit    | *(none; market group retained through PH-07)*          |
| Notes              | scrYearHdr is within snbMktScr. snbMktEng must be resident because snbMktScr depends on it. Both retained through PH-07. |

---

### PH-06 — Revenue Phase (S9, S10) — Years 2–9 only

| Field              | Value                                                  |
|--------------------|--------------------------------------------------------|
| Load on Entry      | *(none; market group already resident)*                |
| Required Resident  | snbUtil, snbMemMgmt, snbYearLoop, snbMktEng, snbMktScr |
| Release on Exit    | *(none)*                                               |
| Notes              | applyDivInt and applyMgnInt are in snbMktEng. scrDivInt and scrMgnInt are in snbMktScr. Skipped in Year 1 and Year 10. Phase is transparent from a load/release perspective. |

---

### PH-07 — Market Phase (S11–S15)

| Field              | Value                                                  |
|--------------------|--------------------------------------------------------|
| Load on Entry      | *(none; market group already resident)*                |
| Required Resident  | snbUtil, snbMemMgmt, snbYearLoop, snbMktEng, snbMktScr |
| Release on Exit    | snbMktEng, snbMktScr                                   |
| Notes              | All market engine and screen procedures are within the already-resident group. Both released at market phase completion; not needed again until next year's PH-05. |

---

### PH-08 — Trade Phase (S16–S19)

| Field              | Value                                                          |
|--------------------|----------------------------------------------------------------|
| Load on Entry      | snbTrade, snbBuySell, snbAI                                    |
| Required Resident  | snbUtil, snbMemMgmt, snbYearLoop, snbTrade, snbBuySell, snbAI  |
| Release on Exit    | snbBuySell, snbAI                                              |
| Notes              | snbBuySell carries scrSell and scrBuy; released immediately when all players complete the buy phase. snbTrade retained because snbMargin and snbMgnScr depend on it. snbAI released after all players complete buy; not needed during margin resolution. |

---

### PH-09 — Margin Phase (S20–S22)

| Field              | Value                                                            |
|--------------------|------------------------------------------------------------------|
| Load on Entry      | snbMargin, snbMgnScr                                             |
| Required Resident  | snbUtil, snbMemMgmt, snbYearLoop, snbTrade, snbMargin, snbMgnScr |
| Release on Exit    | snbTrade, snbMargin, snbMgnScr                                   |
| Notes              | Both snbMargin and snbMgnScr depend on snbTrade at runtime; all three must be resident simultaneously. snbBuySell is not required and must not be loaded here — its release at PH-08 exit is what makes this footprint viable. PH-09 may not occur in every year; snbYearLoop handles the conditional load. |

---

### PH-10 — Year 10 Margin Clearance (S23)

| Field              | Value                                                             |
|--------------------|-------------------------------------------------------------------|
| Load on Entry      | snbMargin, snbMgnScr  (if not already resident from PH-09)        |
| Required Resident  | snbUtil, snbMemMgmt, snbYearLoop, snbTrade, snbMargin, snbMgnScr  |
| Release on Exit    | snbTrade, snbMargin, snbMgnScr                                    |
| Notes              | Same module set and dependency constraints as PH-09. scrMgnClr is in snbMgnScr; snbTrade required as a runtime dep of both snbMargin and snbMgnScr. All three released before PH-12. |

---

### PH-11 — Year Save

| Field              | Value                                              |
|--------------------|----------------------------------------------------|
| Load on Entry      | snbSaveLoad                                        |
| Required Resident  | snbUtil, snbMemMgmt, snbYearLoop, snbSaveLoad      |
| Release on Exit    | snbSaveLoad                                        |
| Notes              | Save is restricted to year boundaries to avoid holding snbSaveLoad resident during game phases. snbYearLoop triggers save at end of each complete year before loading next year's market group. snbSaveLoad released immediately after write. |

---

### PH-12 — End Game (S24–S27)

| Field              | Value                                              |
|--------------------|----------------------------------------------------|
| Load on Entry      | snbEndGame                                         |
| Required Resident  | snbUtil, snbMemMgmt, snbYearLoop, snbEndGame       |
| Release on Exit    | snbEndGame, snbYearLoop                            |
| Notes              | All trade, margin, AI, and market modules must be released before loading snbEndGame. snbYearLoop released at S27 exit; game loop is complete. scrFinalMkt, scrWealth, scrWinner, scrPostGame are all within snbEndGame. |

---

### PH-13 — Post-Game (S27 branches)

| Field              | Value                                              |
|--------------------|----------------------------------------------------|
| Load on Entry      | *(none; depends on S27 selection)*                 |
| Required Resident  | snbUtil, snbMemMgmt, SNB                           |
| Release on Exit    | SNB (on Quit)                                      |
| Notes              | S27 New Game: load SNB → return to PH-02. S27 Load Game: load SNB + snbSaveLoad → PH-03 → PH-04. S27 Quit: release all, exit. SNB must be loaded fresh at S27 New Game/Load since it was released at PH-04 exit. |

---

## 6. Permanent Resident Policy

| Module        | Resident From | Released At          | Rationale                                                                |
|---------------|---------------|----------------------|--------------------------------------------------------------------------|
| `snbUtil`     | PH-00         | Process exit         | Required by every other module. Release cost exceeds benefit.            |
| `snbMemMgmt`  | PH-00         | Process exit         | Required to load and unload other modules. Release cost exceeds benefit. |
| `snbYearLoop` | PH-04         | PH-12 exit (S27)     | Dispatcher must be resident throughout all year loop phases.             |

All other modules follow the load/release schedule in Section 5.

---

## 7. Module Co-Residency Constraints

The following pairs are **never required in memory simultaneously** and
represent the primary memory savings opportunities:

| Group A                     | Group B                         | Reason Never Co-Resident               |
|-----------------------------|---------------------------------|----------------------------------------|
| SNB                         | snbYearLoop (after PH-04)       | Setup complete before loop begins      |
| snbMktEng + snbMktScr       | snbTrade + snbBuySell + snbAI + snbMargin + snbMgnScr    | Market phase ends before trade begins |
| snbMktEng + snbMktScr       | snbEndGame                      | Market is Year 1–9 only                |
| snbTrade + snbBuySell + snbMargin + snbMgnScr + snbAI | snbEndGame                     | Trade complete before endgame screens |
| SNB                         | snbEndGame                      | Setup and endgame do not overlap       |
| snbBuySell                  | snbMargin + snbMgnScr           | Buy/sell complete and released before margin phase loads       |

---

## 8. Save Trigger Policy

Mid-game save is restricted to year boundaries (end of PH-09/PH-10, before
PH-11) to prevent snbSaveLoad from needing to be co-resident with any game
phase module. Rationale: holding snbSaveLoad through an arbitrary phase
wastes memory for a capability used at most once per year.

**Consequence:** A crash mid-year loses that year's progress. The last
complete year's state is always on disk.

This policy may be revisited after hardware memory measurements confirm
available headroom, but it is the conservative default.

---

## 9. Open Items

1. **Dependency slot limit:** `memMapGet` DATA records currently support 8 dependency slots per procedure. After full decomposition, verify no load target requires more than 8 module deps. Resize the DATA schema if needed before any DATA record is finalized.

2. **Post-game SNB reload:** PH-13 requires SNB to be reloaded from disk. Verify that the disk file is present and attr'd correctly after the game loop has been running. This is a cold load, not a link, if SNB was fully unloaded at PH-04 exit.
