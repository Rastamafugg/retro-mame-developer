# SNB Phase-Child Architecture Design

Status: Current  
Authority: Runtime architecture  
Depends on: `specification.md`, `save-load-design.md`  
Supersedes: `forkio-plan.md` and older child-process notes that refer to
retired modules such as `snbBuySell`, `divChild`, `tradeChild`, or `egChild`

This document describes the current file-based phase-child architecture used by
the coordinator in `src/basic/snb.b09`.

---

## 1. Coordinator Model

The top-level coordinator is `snb` in `src/basic/snb.b09`.

It runs this process sequence:

1. Load `snbUtil` into the current process.
2. Fork `snbSetup` for setup.
3. For each game year, fork these child entries in order:
   - `snbDividend`
   - `snbMarket`
   - `snbSell`
   - `snbBuy`
4. If the configured final year has just completed, fork one extra
   `snbMarket` pass for the closing-price draw.
5. Fork `snbEndGame`.

All inter-process state handoff is done through `SNBSTATE`.

---

## 2. gameStage Constants

| Value | Constant | Written By | Coordinator Action |
|-------|----------|-----------|-------------------|
| 1 | `GS_PREGM` | `snbSetup` | Setup complete; enter year loop |
| 2 | `GS_YEAR` | `snbDividend`, `snbMarket`, `snbSell` | Continue current year sequence |
| 3 | `GS_DONE` | `snbBuy` | Leave year loop; run closing flow |

`GS_DONE` is currently written only by `snbBuy`, not by a combined trade child.

---

## 3. currYear Convention

`snbSetup` writes `currYear = 0` as pre-game state.

`snbDividend` increments `currYear` immediately after loading `SNBSTATE`.
After that increment:

- `snbMarket` reads the active year
- `snbSell` reads the active year
- `snbBuy` reads the active year

| State | `currYear` value |
|-------|------------------|
| After `snbSetup` | 0 |
| During Year 1 after `snbDividend` | 1 |
| During Year 10 after `snbDividend` | 10 |

The closing-price draw does not increment `currYear`. It reuses the final-year
value and distinguishes itself by running after `GS_DONE`.

---

## 4. Child Process Entry Procedures

### 4.1 `snbSetup`
- File: `src/basic/snbSetup.b09`
- Entry procedure: `snbSetup`
- Writes: `currYear = 0`, `gameStage = GS_PREGM`
- Responsibility:
  - Runs `setup`
  - Handles S1, S2, S7
  - Initializes header, deck, players, and market state
  - Saves `SNBSTATE` on normal setup completion
  - Writes nothing if the user quits from setup

### 4.2 `snbDividend`
- File: `src/basic/snbDividend.b09`
- Entry procedure: `snbDividend`
- Writes: incremented `currYear`, `gameStage = GS_YEAR`
- Responsibility:
  - Advances the year counter
  - Displays S8
  - Applies dividends and bond interest for Years 2 through `maxYears`
  - Displays S9 per non-bankrupt player

### 4.3 `snbMarket`
- File: `src/basic/snbMarket.b09`
- Entry procedure: `snbMarket`
- Writes: `gameStage = GS_YEAR`
- Responsibility:
  - Draws and decodes the situation card
  - Generates market rolls
  - Resolves stock prices, splits, and dividend-status transitions
  - Displays S11 through S15
  - Applies the Card 1 dividend bonus when allowed by the rules
  - Runs once per normal year, plus one extra closing-price draw after the
    final year ends

### 4.4 `snbSell`
- File: `src/basic/snbSell.b09`
- Entry procedure: `snbSell`
- Writes: `gameStage = GS_YEAR`
- Responsibility:
  - Runs the sell phase for each non-bankrupt player
  - Skips the entire sell pass in Year 1
  - Uses `scrSell` for humans
  - Uses `aiSell` plus `scrAISellTurn` for AI players
  - Applies sell orders to `SNBSTATE`

### 4.5 `snbBuy`
- File: `src/basic/snbBuy.b09`
- Entry procedure: `snbBuy`
- Writes: `gameStage = GS_YEAR` or `GS_DONE`
- Responsibility:
  - Runs the buy phase for each non-bankrupt player
  - Uses `scrBuy` for humans
  - Uses `aiBuy` plus `scrAIBuyTurn` for AI players
  - Applies margin repayment and buy orders to `SNBSTATE`
  - Determines whether the main year loop is complete
  - Writes `GS_DONE` when:
    - `currYear >= maxYears`, or
    - multiplayer game has one or zero non-bankrupt players left

### 4.6 `snbEndGame`
- File: `src/basic/snbEndGame.b09`
- Entry procedure: `snbEndGame`
- Writes: none
- Responsibility:
  - Loads the final saved state
  - Displays S24 through S27
  - Computes final wealth and winner display

---

## 5. Current Year/Phase Sequence

Normal year flow:

```text
snbSetup
  -> snbDividend
  -> snbMarket
  -> snbSell
  -> snbBuy
```

Final-year completion flow:

```text
snbSetup
  -> yearly loop through snbBuy writing GS_DONE
  -> closing snbMarket pass
  -> snbEndGame
```

Coordinator pseudoflow:

```text
fork snbSetup
read SNBSTATE

LOOP
  EXITIF iCYr >= iMaxYr OR gameOver

  fork snbDividend -> readHdr
  fork snbMarket   -> readHdr
  fork snbSell     -> readHdr
  fork snbBuy      -> readHdr

  apply safety nets
ENDLOOP

IF final year completed THEN
  fork snbMarket   \ closing-price draw
ENDIF

fork snbEndGame
```

Notes:

- The extra closing `snbMarket` pass happens only after completion of the
  configured final year.
- `GS_DONE` alone does not imply that `snbEndGame` is immediate; the
  coordinator may insert the closing-price market pass first.

---

## 6. Current Module and Library Layout

### 6.1 Coordinator and child-entry modules

| File | Primary entry procedures | Role |
|------|--------------------------|------|
| `snb.b09` | `snb` | Coordinator |
| `snbSetup.b09` | `snbSetup`, `setup` | Pre-game setup child and setup orchestrator |
| `snbDividend.b09` | `snbDividend` | Dividend/year-header child |
| `snbMarket.b09` | `snbMarket` | Market-resolution child |
| `snbSell.b09` | `snbSell` | Sell-phase child |
| `snbBuy.b09` | `snbBuy` | Buy-phase child and game-over gate |
| `snbEndGame.b09` | `snbEndGame` | Endgame child |

### 6.2 Shared library/support modules

| File | Key procedures | Role |
|------|----------------|------|
| `snbUtil.b09` | `clrScr`, `printAt`, `fmtMoney`, `fmtPlyrName`, `getMenuKey`, `waitKey`, `getNumIn`, `saveGame`, `loadGame`, `guardSave`, `initAIProf`, `shuffleDeck` | Utility, save/load, and shared setup helpers |
| `snbMargin.b09` | `scrMgnCall`, `applyLiqOrdr`, `scrBankrupt`, `scrMgnInt`, `aiLiqOrdr`, `scrForceLiq`, `scrMgnClr` | Shared margin and liquidation engine/screens |

### 6.3 Procedures co-located inside child modules

Several helpers now live inside the child module that uses them:

- `snbSetup.b09`: `initPlayer`, `initMkt`, setup screens
- `snbDividend.b09`: `applyDivInt`, `scrYearHdr`, `scrDivInt`
- `snbMarket.b09`: market tables, card decoding, roll generation, market screens
- `snbSell.b09`: `aiSell`, `applySells`, `scrAISellTurn`, `scrSell`
- `snbBuy.b09`: `aiBuy`, `applyBuys`, `scrMgnRepay`, `scrAIBuyTurn`, `scrBuy`
- `snbEndGame.b09`: endgame screens

Because of that co-location, the older module split described in earlier design
notes is no longer accurate.

---

## 7. Retired Names and Structures

The following names are obsolete in the current implementation and should not
be used as if they were current runtime components:

- `divChild`
- `mktChild`
- `tradeChild`
- `egChild`
- `snbBuySell.b09`
- `snbSaveLoad.b09`
- `snbAI.b09`
- `snbMktEng`
- `snbMktScr`
- `snbYearLoop`

Their responsibilities have been redistributed into the current module set
listed above.

---

## 8. Current Fork Targets

The coordinator currently calls `forkPhase(...)` with only these child names:

- `snbSetup`
- `snbDividend`
- `snbMarket`
- `snbSell`
- `snbBuy`
- `snbEndGame`

Any design note that lists other forked child entry names is historical.
