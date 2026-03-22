# Stocks and Bonds — Save/Load Data Structure

Status: Current  
Authority: Save format and resume semantics  
Depends on: `specification.md`, `phase-child-design.md`  
Supersedes: Conflicting save/load assumptions in `project-timeline.md`

---

## 1. Overview

This document defines the complete game state that must be serialized to
disk on save, the binary TYPE structures used to represent that state, the
write and read sequences, file naming conventions, and save checkpoint
semantics.

The primary reference for all file I/O behavior is the Basic09 Programming
Language Reference Manual, Sections on GET, PUT, SEEK, CREATE, OPEN, and
CLOSE.

The save file format serves two purposes:

1. **User save/load**: player-initiated saves persist game state across
   sessions using named files (see Section 3).
2. **Internal phase handoff**: `SNBSTATE` is the sole IPC channel between
   the SNB coordinator process and each forked phase child. It uses the
   identical file format. See `phase-child-design.md` for the current
   coordinator design.

The shuffled deck is trimmed on first write. Only the first
`maxYears + 1` entries of the 36-element deck are written to disk.
Entries `1..maxYears` cover the annual market draws, and entry
`maxYears + 1` is reserved for the closing-price draw after the final
year.

`maxYears = 10` is the default, rules-faithful game length. Other values are a
project extension and must not change the rules behavior when `maxYears = 10`.

---

## 2. I/O Format Selection

**Selected format: binary random-access using `GET` and `PUT`.**

Rationale:

- `GET`/`PUT` transfer data in Basic09's internal binary format with no
  conversion overhead. The reference manual describes them as "very high
  throughput" versus `READ`/`WRITE`, which perform ASCII conversion on
  every operation.
- All game state values are integers, booleans, and bytes. No REAL values
  are required (spec Section 15). Binary format represents these types
  compactly and exactly.
- Fixed-size TYPE records make the file layout deterministic. Random access
  via `SEEK` is available if a multi-slot save system is added later.
- Sequential `READ`/`WRITE` would require converting every INTEGER to
  ASCII and back. For a save/load operation this is unnecessary overhead
  and produces larger files.

The save file is written sequentially in a fixed order. SEEK is not used
during normal save/load; the file pointer advances naturally via PUT/GET.

---

## 3. File Naming Convention

| Purpose              | Filename    | Notes                                        |
|----------------------|-------------|----------------------------------------------|
| Internal IPC file    | `SNBSTATE`  | Reserved. Written/read by coordinator only.  |
|                      |             | Never shown to player. Never user-writable.  |
| Default active save  | `SNBGAME`   | Overwritten on each save                     |
| Named save slot 1    | `SNBSAVE1`  | Player-named; optional feature               |
| Named save slot 2    | `SNBSAVE2`  |                                              |
| Named save slot 3    | `SNBSAVE3`  |                                              |
| Named save slot 4    | `SNBSAVE4`  |                                              |

`SNBSTATE` is a reserved internal filename. The `guardSave` procedure in
`snbSaveLoad.b09` rejects any player-supplied save name that matches
`SNBSTATE` before any `I$Create` call is made.

Save files are written to the current data directory. The load screen
(see `ui-screen-flow.md`) lists available save files by attempting to
open each known filename. `SNBSTATE` is never included in this list.

---

## 4. Save Checkpoint Semantics

A save may be taken at four defined points during the year loop
(see `ui-screen-flow.md` Section 5). The `savedPhase` field in the
save header records which checkpoint was active at save time. The load
procedure uses this to route directly to the correct resume point.

| `savedPhase` | Checkpoint  | Engine State at Save                               | Resume Entry Point           |
|--------------|-------------|----------------------------------------------------|------------------------------|
| 0            | YEAR_START  | Steps 1–8 NOT yet applied for `currYear`           | S8 — Year Header             |
| 1            | SELL_PHASE  | Steps 1–8 applied; sell turn `savedPlyr` pending   | S16 — Sell Phase (human) or  |
|              |             |                                                    | S19 — Computer Sell Summary  |
| 2            | BUY_PHASE   | Steps 1–9 applied; buy turn `savedPlyr` pending    | S17 — Buy Phase (human) or   |
|              |             |                                                    | S19 — Computer Buy Summary   |
| 3            | FORCED_LIQ  | Forced liquidation active for `savedPlyr`;         | S21 — Forced Liquidation     |
|              |             | `plyrs(savedPlyr).obligation` holds outstanding    |                              |
|              |             | amount                                             |                              |

### YEAR_START resume behavior

When `savedPhase = 0`, the deck position is derived from `currYear`. Steps
1–8 have not been applied. On resume, the game proceeds through S8 and
then executes steps 1–8 normally: card `deckOrd(currYear)` is drawn, dice
are rolled, and prices are updated. The player sees the full market
resolution sequence (S11–S15) as if the year is beginning fresh.

The final year is not treated specially for save format purposes. If
`currYear = maxYears`, the resumed year still performs dividend posting,
bond interest, and margin charge handling before market resolution.
The save format does reserve one extra deck entry beyond `maxYears`
for the closing-price draw that follows the final year.

### SELL_PHASE and BUY_PHASE resume behavior

When `savedPhase = 1` or `2`, steps 1–8 are already reflected in the
current stock prices stored in `MktState`. The deck position has already
advanced. On resume, the market resolution screens (S11–S15) are skipped.
The game jumps directly to the sell or buy turn for player `savedPlyr`.

### FORCED_LIQ resume behavior

`plyrs(savedPlyr).obligation` holds the outstanding amount that triggered
forced liquidation. The game resumes at S21 for player `savedPlyr` with
`plyrs(savedPlyr).obligation` as the initial `obligationRemaining` value.

---

## 5. TYPE Definitions

All TYPEs must be declared at the top of every procedure that uses
them, before any PARAM or DIM declarations (per `bestPractices.md`).

### 5.1 SaveHdr

File header. Always the first record written and first record read.

Fields are grouped: static fields (written once at pre-game exit, never
subsequently modified) precede dynamic fields (updated at one or more
phase exits).

```
TYPE SaveHdr
    ! Static fields — written once at pre-game exit
    magic       : BYTE      ! Format marker. Expected value: $53 ('S')
    fmtVersion  : BYTE      ! Save format version. Current: 1
    maxYears    : BYTE      ! Configured game length in years (1–10)
    plyrCount   : BYTE      ! Number of players (1–6)
    rollMode    : BYTE      ! Market roll mode: 1=A, 2=B, 3=C
    ! Dynamic fields — updated at phase boundaries
    currYear    : BYTE      ! Current game year (1–maxYears)
    savedPhase  : BYTE      ! Save checkpoint (0–3; see Section 4)
    savedPlyr   : BYTE      ! Player turn index at save (1–plyrCount)
    gameStage   : BYTE      ! Macro phase (1=pregame, 2=year, 3=done)
    bnkrFlgs    : BYTE      ! Bankruptcy bit flags (bit p-1 = player p)
    checksum    : BYTE      ! Header integrity byte (see Section 7)
```

SIZE(SaveHdr) = 11 bytes (11 BYTE fields, 1 byte each).

**`gameStage` values:**

| Value | Constant | Written By | Coordinator Action |
|-------|----------|-----------|-------------------|
| 1 | GS_PREGM | Pre-game child | Fork first year-loop child |
| 2 | GS_YEAR | Year-loop child | Re-evaluate; fork year-loop or end-game |
| 3 | GS_DONE | Year-loop child | Fork end-game child; exit loop |

**`bnkrFlgs` bit assignment:**

| Bit | Mask | Player |
|-----|------|--------|
| 0 | $01 | Player 1 |
| 1 | $02 | Player 2 |
| 2 | $04 | Player 3 |
| 3 | $08 | Player 4 |
| 4 | $10 | Player 5 |
| 5 | $20 | Player 6 |
| 6–7 | $C0 | Reserved — must be 0 |

`bnkrFlgs` is computed by `saveGame` from the `plyrs` array before
writing, analogous to how `checksum` is computed. The caller does not
set `bnkrFlgs` directly.

### 5.2 PlyrRec

One record per player. Contains all per-player state including holdings.

```
TYPE PlyrRec
    plyrName    : STRING[20]   ! Display name. Default length 32 truncated.
    plyrType    : BYTE         ! 1 = HUMAN, 2 = COMP
    cashBal     : INTEGER      ! Current cash balance
    marginTot   : INTEGER      ! Outstanding margin total
    obligation  : INTEGER      ! Outstanding forced liquidation amount
    isBankrupt  : BOOLEAN      ! TRUE if player has been eliminated
    hadCashPur  : BOOLEAN      ! TRUE if prior cash purchase made
    aiTier      : BYTE         ! AI difficulty: 1=Easy,2=Med,3=Hard;0=human
    stckShrs(9) : INTEGER      ! Shares owned per stock (index 1–9)
    mgnHeld(9)  : BOOLEAN      ! TRUE if shares at index i held on margin
    bondUnts(3) : INTEGER      ! Bond units held per denomination (index 1–3)
```

SIZE per player: 20 + 1 + 2 + 2 + 2 + 1 + 1 + 1 + 18 + 9 + 6 = **63 bytes**.

`obligation` records the outstanding forced liquidation amount for this
player when `savedPhase = 3`. It is 0 for all players when `savedPhase`
is 0, 1, or 2. The load procedure reads it from `plyrs(hdr.savedPlyr)`
when resuming a `FORCED_LIQ` checkpoint.

`aiTier` stores the difficulty tier for computer players. On load, the
full `AIProfile` record is reconstructed from `aiTier` without saving
the profile itself (see `ai-difficulty-tiers.md` Section 3). Human
players store 0.

`hadCashPur` records whether the player has made at least one prior cash
purchase, required for margin eligibility (spec Section 9.1).

### 5.3 MktState

Current stock market state after the most recent price resolution.

```
TYPE MktState
    stckPrice(9)  : INTEGER   ! Current price per stock (index 1–9)
    divSuspnd(9)  : BOOLEAN   ! TRUE if dividends suspended per stock
```

SIZE: 18 + 9 = **27 bytes**.

---

## 6. Byte-Size Accounting

The deck section is variable-length: `maxYears + 1` bytes, bounded by the
configured game length. The maximum game length is 10 years.

| Component             | Type/Count              | Bytes (max)  |
|-----------------------|-------------------------|--------------|
| SaveHdr               | 1 record                | 11           |
| deckOrd (trimmed)     | (maxYears+1) × BYTE     | 11           |
| PlyrRec               | 6 records × 63          | 378          |
| MktState              | 1 record                | 27           |
| **Total (max)**       |                         | **427**      |
| **Total (min, 1 yr)** |                         | **418**      |

426 bytes is negligible on any OS-9 storage medium. The variable memory
budget (32KB) is unaffected: the TYPE definitions and working variables
for save/load require under 200 bytes at runtime.

The in-memory `deckOrd` array is declared as `DIM deckOrd(36):BYTE`
and fully shuffled. Only indices 1 through `maxYears + 1` are written
to and read from disk. Indices above `maxYears + 1` are never used in
the rules-faithful flow and are not persisted.

All 6 `PlyrRec` entries are always written and read regardless of
`plyrCount`. Inactive slots (index > plyrCount) contain whatever values
they were initialized to. Only entries 1 through `plyrCount` are used
during gameplay.

---

## 7. Checksum

The `checksum` field is a single BYTE computed from the other ten
header fields. It provides format validation: a mismatched checksum
on load indicates a corrupt or incompatible save file.

Computation:

```
hdr.checksum := LAND(
    hdr.magic      + hdr.fmtVersion + hdr.maxYears  +
    hdr.plyrCount  + hdr.rollMode   + hdr.currYear   +
    hdr.savedPhase + hdr.savedPlyr  + hdr.gameStage  +
    hdr.bnkrFlgs,
    255)
```

All ten covered fields are BYTE (1 byte each). The maximum sum is
10 × 255 = 2550, which fits safely in a Basic09 INTEGER. No INTEGER
staging is required for this computation.

`LAND(..., 255)` retains only the low 8 bits of the INTEGER sum,
producing a value in the BYTE range 0–255.

The checksum is computed immediately before the `PUT #path, hdr` call.
`bnkrFlgs` must also be computed before the checksum is computed, since
it is a covered field. The correct sequence in `saveGame` is:

1. Compute `hdr.bnkrFlgs` from the `plyrs` array.
2. Compute `hdr.checksum` from all ten header fields including `bnkrFlgs`.
3. `PUT #path, hdr`.

On load, the checksum is recomputed from the loaded header fields and
compared to `hdr.checksum` before any game state is applied.

---

## 8. Write Sequence

Pseudocode for the save procedure. Error handling, path management, and
the `DELETE` before `CREATE` pattern follow `bestPractices.md`.

```
PROCEDURE saveGame
(*                                                                    *)
(* PURPOSE : Serialize complete game state to a save file.           *)
(* PARAMS  : savePath  - target filename                              *)
(*           hdr       - populated SaveHdr record                     *)
(*           deckOrd   - shuffled deck order array (36 BYTE)         *)
(*           plyrs     - player records array (6 PlyrRec)            *)
(*           mkt       - current market state                         *)
(*                                                                    *)
(* CALLER MUST SET before calling:                                    *)
(*   hdr.magic, hdr.fmtVersion, hdr.maxYears, hdr.plyrCount,        *)
(*   hdr.rollMode, hdr.currYear, hdr.savedPhase, hdr.savedPlyr,     *)
(*   hdr.gameStage                                                    *)
(*                                                                    *)
(* saveGame computes hdr.bnkrFlgs and hdr.checksum internally.       *)
(*                                                                    *)
TYPE SaveHdr = ...
TYPE PlyrRec = ...
TYPE MktState = ...
PARAM savePath    : STRING[20]
PARAM hdr         : SaveHdr
PARAM deckOrd(36) : BYTE
PARAM plyrs(6)    : PlyrRec
PARAM mkt         : MktState
DIM path     : BYTE
DIM pathOpen : BOOLEAN
DIM i        : INTEGER
DIM iMask    : INTEGER
DIM iFlgs    : INTEGER
DIM shft     : INTEGER

ON ERROR GOTO 900

pathOpen := FALSE

! Compute bnkrFlgs from plyrs.isBankrupt before checksum.
hdr.bnkrFlgs := 0
shft := 1
FOR i := 1 TO hdr.plyrCount
    IF plyrs(i).isBankrupt THEN
        iFlgs         := hdr.bnkrFlgs   ! stage BYTE to INTEGER
        hdr.bnkrFlgs  := iFlgs LOR shft
    ENDIF
    shft := shft * 2
NEXT i

! Compute header checksum.
hdr.checksum := LAND(
    hdr.magic      + hdr.fmtVersion + hdr.maxYears  +
    hdr.plyrCount  + hdr.rollMode   + hdr.currYear   +
    hdr.savedPhase + hdr.savedPlyr  + hdr.gameStage  +
    hdr.bnkrFlgs,
    255)

! Remove existing file; ignore error if not found.
ON ERROR GOTO 100
DELETE savePath

100 ON ERROR GOTO 900

CREATE #path, savePath: WRITE
pathOpen := TRUE

PUT #path, hdr

! Write only the first maxYears+1 deck entries.
FOR i := 1 TO hdr.maxYears + 1
    PUT #path, deckOrd(i)
NEXT i

PUT #path, plyrs   ! 6-element PlyrRec array; one PUT writes all 6
PUT #path, mkt

CLOSE #path
pathOpen := FALSE
END

900 ! Error handler
    IF pathOpen THEN
        CLOSE #path
    ENDIF
    ERROR(ERR)   ! Delegate to caller's error handler
END
```

---

## 9. Read Sequence

Pseudocode for the load procedure. Validates format version and checksum
before applying any state. Reads `hdr.maxYears` from the header before
reading the variable-length deck section.

```
PROCEDURE loadGame
(*                                                                    *)
(* PURPOSE : Deserialize game state from a save file.                *)
(* PARAMS  : savePath  - source filename                              *)
(*           hdr       - receives SaveHdr                            *)
(*           deckOrd   - receives deck order array (36 BYTE)         *)
(*           plyrs     - receives player records (6 PlyrRec)         *)
(*           mkt       - receives market state                        *)
(*           loadOK    - returns TRUE on success                      *)
(*                                                                    *)
TYPE SaveHdr = ...
TYPE PlyrRec = ...
TYPE MktState = ...
PARAM savePath    : STRING[20]
PARAM hdr         : SaveHdr
PARAM deckOrd(36) : BYTE
PARAM plyrs(6)    : PlyrRec
PARAM mkt         : MktState
PARAM loadOK      : BOOLEAN
DIM path      : BYTE
DIM pathOpen  : BOOLEAN
DIM chkExpect : BYTE
DIM i         : INTEGER

ON ERROR GOTO 900

pathOpen := FALSE
loadOK   := FALSE

OPEN #path, savePath: READ
pathOpen := TRUE

! Read header first — maxYears governs the deck section length.
GET #path, hdr

! Validate magic byte before reading further.
IF hdr.magic <> $53 THEN
    PRINT "Error: not a valid save file."
    END
ENDIF

! Validate format version.
IF hdr.fmtVersion <> 1 THEN
    PRINT "Error: incompatible save file version."
    END
ENDIF

! Validate checksum.
chkExpect := LAND(
    hdr.magic      + hdr.fmtVersion + hdr.maxYears  +
    hdr.plyrCount  + hdr.rollMode   + hdr.currYear   +
    hdr.savedPhase + hdr.savedPlyr  + hdr.gameStage  +
    hdr.bnkrFlgs,
    255)
IF chkExpect <> hdr.checksum THEN
    PRINT "Error: save file is corrupt."
    END
ENDIF

! Read trimmed deck — only maxYears+1 entries were written.
FOR i := 1 TO hdr.maxYears + 1
    GET #path, deckOrd(i)
NEXT i

GET #path, plyrs
GET #path, mkt

CLOSE #path
pathOpen := FALSE

loadOK := TRUE
END

900 ! Error handler
    IF pathOpen THEN
        CLOSE #path
    ENDIF
    PRINT "Error reading save file: "; ERR
    loadOK := FALSE
END
```

### 9.1 Resume Routing

After `loadGame` returns `loadOK = TRUE`, the caller routes to the
appropriate screen and game loop position based on `hdr.savedPhase`
and `hdr.savedPlyr`:

```
IF hdr.savedPhase = 0 THEN
    ! Resume at S8 (Year Header).
    ! Steps 1-8 will execute normally: card deckOrd(currYear) drawn,
    ! dice rolled, prices updated, market resolution screens shown.
    RUN enterYearLoop(hdr.currYear, hdr.rollMode, deckOrd, plyrs, mkt)

ELSE IF hdr.savedPhase = 1 THEN
    ! Resume at sell phase for player hdr.savedPlyr.
    ! Steps 1-8 already reflected in mkt.stckPrice.
    ! Skip S8-S15; jump to sell turn.
    RUN enterSellPhase(hdr.currYear, hdr.savedPlyr, plyrs, mkt)

ELSE IF hdr.savedPhase = 2 THEN
    ! Resume at buy phase for player hdr.savedPlyr.
    ! All sell turns through savedPlyr-1 already complete.
    RUN enterBuyPhase(hdr.currYear, hdr.savedPlyr, plyrs, mkt)

ELSE IF hdr.savedPhase = 3 THEN
    ! Resume in forced liquidation for player hdr.savedPlyr.
    ! obligation is read from the player record, not the header.
    RUN enterForcedLiq(hdr.savedPlyr,
                       plyrs(hdr.savedPlyr).obligation,
                       plyrs, mkt)

ENDIF \ENDIF \ENDIF \ENDIF
```

---

## 10. Save State Population Reference

For each save checkpoint, the following fields require explicit
population before calling `saveGame`. Fields computed internally by
`saveGame` (bnkrFlgs, checksum) are excluded from caller responsibility.

### 10.1 All Checkpoints

| Field             | Source                                               |
|-------------------|------------------------------------------------------|
| `hdr.magic`       | Constant $53                                         |
| `hdr.fmtVersion`  | Constant 1                                           |
| `hdr.maxYears`    | Game length from setup; set once at pre-game exit    |
| `hdr.plyrCount`   | Player count from setup                              |
| `hdr.rollMode`    | Market roll mode from setup (1/2/3)                  |
| `hdr.currYear`    | Current year loop variable                           |
| `hdr.gameStage`   | Phase constant written by child at exit              |
| `hdr.savedPhase`  | Current intra-year checkpoint (0–3)                  |
| `hdr.savedPlyr`   | Current player index at checkpoint                   |
| `deckOrd(1..36)`  | Shuffled deck array (only 1..maxYears+1 written)     |
| `plyrs(1..n)`     | All PlyrRec fields for active players                |
| `mkt.stckPrice`   | Current price per stock                              |
| `mkt.divSuspnd`   | Dividend suspension state per stock                  |

### 10.2 Per-Checkpoint Fields

| `savedPhase` | `savedPlyr`                          | `obligation` (in PlyrRec)                    |
|--------------|--------------------------------------|----------------------------------------------|
| 0            | 0 (unused)                           | 0 for all players (unused)                   |
| 1            | Index of next player to sell (1–n)   | 0 for all players (unused)                   |
| 2            | Index of next player to buy (1–n)    | 0 for all players (unused)                   |
| 3            | Index of player in liquidation (1–n) | `plyrs(savedPlyr).obligation` = outstanding amount |

---

## 11. AIProfile Reconstruction on Load

`AIProfile` records (see `ai-difficulty-tiers.md`) are not saved. On
load, the caller reconstructs each computer player's `AIProfile` from
`plyrs(i).aiTier` using the profile initialization procedure. This is
valid because `AIProfile` values are entirely determined by the tier
constant and do not accumulate state during play.

Exception: the `hadCashPur` field in `PlyrRec` captures the one piece
of AI-relevant state that does accumulate during play. It is saved
directly in `PlyrRec`.

---

## 12. Known Constraints and Limitations

### SNBSTATE is a reserved internal filename

`SNBSTATE` is used exclusively by the SNB coordinator and phase child
processes as an IPC channel. It must never appear in the player-visible
save slot list. The `guardSave` procedure in `snbSaveLoad.b09` rejects
any player-supplied filename matching `SNBSTATE` before any `I$Create`
call. See `forkio-plan.md` for the `chkStale` procedure that handles
stale `SNBSTATE` files on new-game startup.

### Variable-length deck section

The deck section of the save file is `maxYears + 1` bytes, not a fixed 36
bytes. Any procedure that reads the deck section must first read the
header to obtain `maxYears`. The load procedure enforces this ordering.
The in-memory `deckOrd` array is always declared as 36 elements; only
the first `maxYears + 1` elements are populated from disk.

### Single active save

The design supports one active save file (`SNBGAME`) plus four named
slots. There is no save history. Each save to `SNBGAME` overwrites the
previous. Players who want to preserve a specific game state must use
a named slot.

### No mid-market-resolution save

Saves are not permitted during steps 1–8 of the year loop (market
resolution). State is partially computed and inconsistent during these
steps. The earliest save point after market resolution is the beginning
of the first sell turn (`savedPhase = 1`).

### Checksum covers header only

The checksum validates the 11-byte header only (all fields except
checksum itself). Corruption in player records or market state is not
detected by the checksum. Full-file checksumming is deferred.

### Format version

`fmtVersion = 1` is the only defined version. If the TYPE structures
are changed in a future revision, `fmtVersion` must be incremented and
the load procedure must handle version migration or reject incompatible
files with a clear error message.
