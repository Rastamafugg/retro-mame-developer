# Stocks and Bonds — Save/Load Data Structure

---

## 1. Overview

This document defines the complete game state that must be serialized to
disk on save, the binary TYPE structures used to represent that state, the
write and read sequences, file naming conventions, and save checkpoint
semantics.

The primary reference for all file I/O behavior is the Basic09 Programming
Language Reference Manual, Sections on GET, PUT, SEEK, CREATE, OPEN, and
CLOSE.

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
- Fixed-size TYPE records make the file layout deterministic. Total save
  file size is 440 bytes. Random access via `SEEK` is available if a
  multi-slot save system is added later.
- Sequential `READ`/`WRITE` would require converting every INTEGER to
  ASCII and back. For a save/load operation this is unnecessary overhead
  and produces larger files.

The save file is written sequentially in a fixed order. SEEK is not used
during normal save/load; the file pointer advances naturally via PUT/GET.

---

## 3. File Naming Convention

| Purpose              | Filename    | Notes                              |
|----------------------|-------------|------------------------------------|
| Default active save  | `SNBGAME`   | Overwritten on each save           |
| Named save slot 1    | `SNBSAVE1`  | Player-named; optional feature     |
| Named save slot 2    | `SNBSAVE2`  |                                    |
| Named save slot 3    | `SNBSAVE3`  |                                    |
| Named save slot 4    | `SNBSAVE4`  |                                    |

Save files are written to the current data directory. The load screen
(see `ui-screen-flow.md`) lists available save files by attempting to
open each known filename.

OS-9 filename length is not restricted to 8 characters, but short names
are conventional for this era and platform.

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
|              |             | `obligation` holds outstanding amount              |                              |

### YEAR_START resume behavior

When `savedPhase = 0`, the deck position (`deckPos`) points to the next
card to be drawn for `currYear`. Steps 1–8 have not been applied. On
resume, the game proceeds through S8 and then executes steps 1–8 normally:
a card is drawn from the deck at `deckPos`, dice are rolled, and prices
are updated. The player sees the full market resolution sequence (S11–S15)
as if the year is beginning fresh.

### SELL_PHASE and BUY_PHASE resume behavior

When `savedPhase = 1` or `2`, steps 1–8 are already reflected in the
current stock prices stored in `MktState`. The deck position has already
advanced past the drawn card. On resume, the market resolution screens
(S11–S15) are skipped. The game jumps directly to the sell or buy turn
for player `savedPlyr`.

### FORCED_LIQ resume behavior

`obligation` holds the outstanding amount that triggered forced
liquidation. The game resumes at S21 for player `savedPlyr` with
`obligation` as the initial `obligationRemaining` value.

---

## 5. TYPE Definitions

All TYPEs must be declared at the top of every procedure that uses
them, before any PARAM or DIM declarations (per `bestPractices.md`).

### 5.1 SaveHdr

File header. Always the first record written and first record read.

```
TYPE SaveHdr
    magic       : BYTE      ! Format marker. Expected value: $53 ('S')
    fmtVersion  : BYTE      ! Save format version. Current: 1
    currYear    : BYTE      ! Current game year (1–10)
    plyrCount   : BYTE      ! Number of players (1–6)
    rollMode    : BYTE      ! Market roll mode: 1=A, 2=B, 3=C
    savedPhase  : BYTE      ! Save checkpoint (0–3; see Section 4)
    savedPlyr   : BYTE      ! Player turn index at save (1–plyrCount)
    obligation  : INTEGER   ! Outstanding forced liquidation amount
    deckPos     : BYTE      ! Next card index in deckOrder (1–36)
    checksum    : BYTE      ! Header integrity byte (see Section 7)
```

SIZE(SaveHdr) = 11 bytes.

Note: `magic`, `fmtVersion`, `currYear`, `plyrCount`, `rollMode`,
`savedPhase`, `savedPlyr`, `deckPos`, `checksum` are all BYTE (1 byte
each = 9 bytes); `obligation` is INTEGER (2 bytes). Total: 11 bytes.

### 5.2 PlyrRec

One record per player. Contains all per-player state including holdings.

```
TYPE PlyrRec
    plyrName    : STRING[20]   ! Display name. Default length 32 truncated.
    plyrType    : BYTE         ! 1 = HUMAN, 2 = COMP
    cashBal     : INTEGER      ! Current cash balance
    marginTot   : INTEGER      ! Outstanding margin total
    isBankrupt  : BOOLEAN      ! TRUE if player has been eliminated
    hadCashPur  : BOOLEAN      ! TRUE if prior cash purchase made
    aiTier      : BYTE         ! AI difficulty: 1=Easy,2=Med,3=Hard;0=human
    stckShrs(9) : INTEGER      ! Shares owned per stock (index 1–9)
    mgnHeld(9)  : BOOLEAN      ! TRUE if shares at index i held on margin
    bondUnts(3) : INTEGER      ! Bond units held per denomination (index 1–3)
```

SIZE per player: 20 + 1 + 2 + 2 + 1 + 1 + 1 + 18 + 9 + 6 = **61 bytes**.

Note: `stckShrs`, `mgnHeld`, and `bondUnts` use inline array syntax
within the TYPE definition, following the pattern demonstrated in the
Basic09 reference manual: `address(3):STRING`.

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

| Component             | Type/Count         | Bytes       |
|-----------------------|--------------------|-------------|
| SaveHdr               | 1 record           | 11          |
| deckOrder array       | 36 × BYTE          | 36          |
| PlyrRec               | 6 records × 61     | 366         |
| MktState              | 1 record           | 27          |
| **Total**             |                    | **440**     |

440 bytes is negligible on any OS-9 storage medium. The variable memory
budget (32KB) is unaffected: the TYPE definitions and working variables
for save/load require under 200 bytes at runtime.

The `deckOrder` array is written separately as a `DIM deckOrder(36):BYTE`
array, not embedded in `SaveHdr`. Basic09's `PUT` statement writes the
exact binary representation of the array in one operation.

All 6 `PlyrRec` entries are always written and read regardless of
`plyrCount`. Inactive slots (index > plyrCount) contain whatever values
they were initialized to. Only entries 1 through `plyrCount` are used
during gameplay.

---

## 7. Checksum

The `checksum` field is a single BYTE computed from the other nine
header fields. It provides format validation: a mismatched checksum
on load indicates a corrupt or incompatible save file.

Computation:

```
hdr.checksum := LAND(
    hdr.magic    + hdr.fmtVersion + hdr.currYear  +
    hdr.plyrCount + hdr.rollMode  + hdr.savedPhase +
    hdr.savedPlyr + hdr.deckPos   + hdr.obligation,
    255)
```

`LAND(..., 255)` retains only the low 8 bits of the INTEGER sum,
producing a value in the BYTE range 0–255.

`obligation` is INTEGER (2 bytes); when added to the BYTE fields it is
automatically widened to INTEGER for the arithmetic, then truncated to
BYTE by `LAND`. This is expected behavior.

The checksum is computed immediately before the `PUT #path, hdr` call.
On load, the checksum is recomputed from the loaded header fields and
compared to `hdr.checksum` before any game state is applied.

---

## 8. Write Sequence

Pseudocode for the save procedure. Error handling, path management, and
the `DELETE` before `CREATE` pattern follow `bestPractices.md`.

```
PROCEDURE saveGame
(*                                                          *)
(* PURPOSE : Serialize complete game state to a save file.  *)
(* PARAMS  : savePath - target filename                     *)
(*           hdr      - populated SaveHdr record            *)
(*           deckOrd  - shuffled deck order array (36 BYTE) *)
(*           plyrs    - player records array (6 PlyrRec)    *)
(*           mkt      - current market state                *)
(*                                                          *)
TYPE SaveHdr = ...
TYPE PlyrRec = ...
TYPE MktState = ...
PARAM savePath   : STRING[20]
PARAM hdr        : SaveHdr
PARAM deckOrd(36): BYTE
PARAM plyrs(6)   : PlyrRec
PARAM mkt        : MktState
DIM path    : BYTE
DIM pathOpen: BOOLEAN

ON ERROR GOTO 900

pathOpen := FALSE

! Compute and store header checksum before writing.
hdr.checksum := LAND(
    hdr.magic    + hdr.fmtVersion + hdr.currYear  +
    hdr.plyrCount + hdr.rollMode  + hdr.savedPhase +
    hdr.savedPlyr + hdr.deckPos   + hdr.obligation,
    255)

! Remove existing file; ignore error if not found.
ON ERROR GOTO 100
DELETE savePath

100 ON ERROR GOTO 900

CREATE #path, savePath: WRITE
pathOpen := TRUE

PUT #path, hdr
PUT #path, deckOrd     ! 36-element BYTE array; one PUT writes all 36
PUT #path, plyrs       ! 6-element PlyrRec array; one PUT writes all 6
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

The entire save is four PUT statements. The array forms of PUT (`plyrs`
and `deckOrd`) write all elements in one operation.

---

## 9. Read Sequence

Pseudocode for the load procedure. Validates format version and checksum
before applying any state.

```
PROCEDURE loadGame
(*                                                              *)
(* PURPOSE : Deserialize game state from a save file.          *)
(* PARAMS  : savePath  - source filename                       *)
(*           hdr       - receives SaveHdr                      *)
(*           deckOrd   - receives deck order array (36 BYTE)   *)
(*           plyrs     - receives player records (6 PlyrRec)   *)
(*           mkt       - receives market state                 *)
(*           loadOK    - returns TRUE on success               *)
(*                                                             *)
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

ON ERROR GOTO 900

pathOpen := FALSE
loadOK   := FALSE

OPEN #path, savePath: READ
pathOpen := TRUE

GET #path, hdr
GET #path, deckOrd
GET #path, plyrs
GET #path, mkt

CLOSE #path
pathOpen := FALSE

! Validate magic byte.
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
    hdr.magic    + hdr.fmtVersion + hdr.currYear  +
    hdr.plyrCount + hdr.rollMode  + hdr.savedPhase +
    hdr.savedPlyr + hdr.deckPos   + hdr.obligation,
    255)
IF chkExpect <> hdr.checksum THEN
    PRINT "Error: save file is corrupt."
    END
ENDIF

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
    ! Steps 1-8 will execute normally: card drawn, dice rolled,
    ! prices updated, market resolution screens shown.
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
    RUN enterForcedLiq(hdr.savedPlyr, hdr.obligation, plyrs, mkt)

ENDIF \ENDIF \ENDIF \ENDIF
```

---

## 10. Save State Population Reference

For each save checkpoint, the following fields require explicit
population before calling `saveGame`.

### 10.1 All Checkpoints

| Field             | Source                                               |
|-------------------|------------------------------------------------------|
| `hdr.magic`       | Constant $53                                         |
| `hdr.fmtVersion`  | Constant 1                                           |
| `hdr.currYear`    | Current year loop variable                           |
| `hdr.plyrCount`   | Player count from setup                              |
| `hdr.rollMode`    | Market roll mode from setup (1/2/3)                  |
| `hdr.deckPos`     | Current deck position (next undrawn card index)      |
| `hdr.checksum`    | Computed by saveGame; do not set before calling      |
| `deckOrd(1..36)`  | Shuffled deck array (persists for full game)         |
| `plyrs(1..n)`     | All PlyrRec fields for active players                |
| `mkt.stckPrice`   | Current price per stock                              |
| `mkt.divSuspnd`   | Dividend suspension state per stock                  |

### 10.2 Per-Checkpoint Fields

| `savedPhase` | `savedPlyr`                          | `obligation`                  |
|--------------|--------------------------------------|-------------------------------|
| 0            | 0 (unused)                           | 0 (unused)                    |
| 1            | Index of next player to sell (1–n)   | 0 (unused)                    |
| 2            | Index of next player to buy (1–n)    | 0 (unused)                    |
| 3            | Index of player in liquidation (1–n) | Outstanding obligation amount |

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

The checksum validates the 9-byte header only. Corruption in player
records or market state is not detected by the checksum. Full-file
checksumming would require byte-level iteration over the entire 440-byte
image, which is feasible but adds implementation complexity. Deferred.

### Format version

`fmtVersion = 1` is the only defined version. If the TYPE structures
are changed in a future revision, `fmtVersion` must be incremented and
the load procedure must handle version migration or reject incompatible
files with a clear error message.
