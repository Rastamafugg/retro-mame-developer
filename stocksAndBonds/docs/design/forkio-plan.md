# forkio-plan.md — Pipe-Based Phase Handoff: Planning Document

**Status:** Step 0 — pending review before any implementation proceeds.

---

## Section 1 — Handoff TYPE Definitions

### 1.1 ForkPG — Pre-Game Handoff (179 bytes)

Used by the pre-game child to write final setup state to the pipe before exiting.
The parent reads this after `F$Wait` returns and uses it to reconstruct live game state.

#### TYPE Definition

```
! Line exceeds 79 chars; TYPE statement requires single line.
TYPE ForkPG = pgMag,pgFmtV,pgCYr,pgPCnt,pgRMod,pgSPhs,pgSPlr,pgDkPs,pgChks:BYTE;pgOblg:INTEGER;pgDeck(36):BYTE;pgNam1,pgNam2,pgNam3,pgNam4,pgNam5,pgNam6:STRING[20];pgTyp(6),pgTier(6):BYTE
```

#### Field Layout — Write Order

| # | Field | Type | Bytes | Running Total | Source Field | Notes |
|---|-------|------|-------|---------------|--------------|-------|
| 1 | pgMag | BYTE | 1 | 1 | hdr.magic | Format marker |
| 2 | pgFmtV | BYTE | 1 | 2 | hdr.fmtVersion | |
| 3 | pgCYr | BYTE | 1 | 3 | hdr.currYear | Always 1 at pre-game exit |
| 4 | pgPCnt | BYTE | 1 | 4 | hdr.plyrCount | |
| 5 | pgRMod | BYTE | 1 | 5 | hdr.rollMode | |
| 6 | pgSPhs | BYTE | 1 | 6 | hdr.savedPhase | Always 0 at pre-game exit |
| 7 | pgSPlr | BYTE | 1 | 7 | hdr.savedPlyr | Always 0 at pre-game exit |
| 8 | pgOblg | INTEGER | 2 | 9 | hdr.obligation | Always 0 at pre-game exit |
| 9 | pgDkPs | BYTE | 1 | 10 | hdr.deckPos | Set to 1 after shuffleDeck |
| 10 | pgChks | BYTE | 1 | 11 | hdr.checksum | Computed per save-load-design.md §7 |
| 11 | pgDeck(36) | BYTE[36] | 36 | 47 | deckOrd(1..36) | Shuffled deck order array |
| 12 | pgNam1 | STRING[20] | 20 | 67 | plyrs(1).plyrName | |
| 13 | pgNam2 | STRING[20] | 20 | 87 | plyrs(2).plyrName | |
| 14 | pgNam3 | STRING[20] | 20 | 107 | plyrs(3).plyrName | |
| 15 | pgNam4 | STRING[20] | 20 | 127 | plyrs(4).plyrName | |
| 16 | pgNam5 | STRING[20] | 20 | 147 | plyrs(5).plyrName | |
| 17 | pgNam6 | STRING[20] | 20 | 167 | plyrs(6).plyrName | |
| 18 | pgTyp(6) | BYTE[6] | 6 | 173 | plyrs(i).plyrType | Flat array; index 1..6 |
| 19 | pgTier(6) | BYTE[6] | 6 | 179 | plyrs(i).aiTier | Flat array; index 1..6 |

**Confirmed total: 179 bytes. Margin: 77 bytes below 256-byte ceiling.**

#### Packing Logic

No packing is required for ForkPG. All fields are direct assignments:

```
pgMag   := hdr.magic
pgFmtV  := hdr.fmtVersion
...
pgDeck(i) := deckOrd(i)   ! i = 1..36
pgNam1  := plyrs(1).plyrName
...
pgTyp(i) := plyrs(i).plyrType   ! i = 1..6
pgTier(i) := plyrs(i).aiTier
```

STRING[20] field in a TYPE occupies 20 bytes on this platform (confirmed by TSTSIZE:
SIZE(PlyrRec) = 61, which is consistent with plyrName = 20 bytes, not 22).

---

### 1.2 ForkYL — Year-Loop Handoff (199 bytes)

Used by the year-loop child to write mutated game state to the pipe after a year
completes (or after all years complete). The parent reads this and overlays only the
mutable fields; static/structural fields (deck order, player names, types, tiers) are
preserved from the parent's live state and not retransmitted.

#### TYPE Definition

```
! Line exceeds 79 chars; TYPE statement requires single line.
TYPE ForkYL = ylMag,ylFmtV,ylCYr,ylPCnt,ylRMod,ylSPhs,ylSPlr,ylDkPs,ylChks:BYTE;ylOblg:INTEGER;ylSPrc(9):INTEGER;ylDvPk:INTEGER;ylCash(6),ylMgns(6):INTEGER;ylFlgs(6):BYTE;ylShrs(54):INTEGER;ylMgPk(6):INTEGER;ylBnds(18):BYTE
```

#### Field Layout — Write Order

| # | Field | Type | Bytes | Running Total | Source Field | Notes |
|---|-------|------|-------|---------------|--------------|-------|
| 1 | ylMag | BYTE | 1 | 1 | hdr.magic | |
| 2 | ylFmtV | BYTE | 1 | 2 | hdr.fmtVersion | |
| 3 | ylCYr | BYTE | 1 | 3 | hdr.currYear | Year at handoff exit |
| 4 | ylPCnt | BYTE | 1 | 4 | hdr.plyrCount | |
| 5 | ylRMod | BYTE | 1 | 5 | hdr.rollMode | |
| 6 | ylSPhs | BYTE | 1 | 6 | hdr.savedPhase | 0 at normal year exit |
| 7 | ylSPlr | BYTE | 1 | 7 | hdr.savedPlyr | |
| 8 | ylOblg | INTEGER | 2 | 9 | hdr.obligation | |
| 9 | ylDkPs | BYTE | 1 | 10 | hdr.deckPos | Deck position after year |
| 10 | ylChks | BYTE | 1 | 11 | hdr.checksum | |
| 11 | ylSPrc(9) | INTEGER[9] | 18 | 29 | mkt.stckPrice(1..9) | Post-year prices |
| 12 | ylDvPk | INTEGER | 2 | 31 | mkt.divSuspnd(1..9) | Packed; see below |
| 13 | ylCash(6) | INTEGER[6] | 12 | 43 | plyrs(i).cashBal | |
| 14 | ylMgns(6) | INTEGER[6] | 12 | 55 | plyrs(i).marginTot | |
| 15 | ylFlgs(6) | BYTE[6] | 6 | 61 | isBankrupt + hadCashPur | Packed; see below |
| 16 | ylShrs(54) | INTEGER[54] | 108 | 169 | plyrs(i).stckShrs(s) | Flat; index (i-1)*9+s |
| 17 | ylMgPk(6) | INTEGER[6] | 12 | 181 | plyrs(i).mgnHeld(1..9) | Packed per player; see below |
| 18 | ylBnds(18) | BYTE[18] | 18 | 199 | plyrs(i).bondUnts(b) | Flat; index (i-1)*3+b |

**Confirmed total: 199 bytes. Margin: 57 bytes below 256-byte ceiling.**

#### Packing Logic

**`ylDvPk` — packing `mkt.divSuspnd(1..9)` into one INTEGER:**

Stock index s maps to bit (s-1). Shift doubles each iteration:

```
ylDvPk := 0
shft   := 1
FOR s := 1 TO 9
  IF mkt.divSuspnd(s) THEN
    ylDvPk := ylDvPk LOR shft
  ENDIF
  shft := shft * 2
NEXT s
```

Unpack (parent side):

```
shft := 1
FOR s := 1 TO 9
  iDvPk := ylDvPk   ! stage INTEGER field to INTEGER var
  mkt.divSuspnd(s) := LAND(iDvPk, shft) <> 0
  shft := shft * 2
NEXT s
```

Bit positions for `ylDvPk` and all `ylMgPk(p)` fields:

| Stock index | Bit | Mask value |
|-------------|-----|------------|
| 1 | 0 | $0001 |
| 2 | 1 | $0002 |
| 3 | 2 | $0004 |
| 4 | 3 | $0008 |
| 5 | 4 | $0010 |
| 6 | 5 | $0020 |
| 7 | 6 | $0040 |
| 8 | 7 | $0080 |
| 9 | 8 | $0100 |

**`ylMgPk(p)` — packing `plyrs(p).mgnHeld(1..9)` into one INTEGER per player:**

Identical bit assignment to `ylDvPk`. For each player p (1..6):

```
ylMgPk(p) := 0
shft       := 1
FOR s := 1 TO 9
  IF plyrs(p).mgnHeld(s) THEN
    iMgPk    := ylMgPk(p)   ! stage BYTE array element to INTEGER
    iMgPk    := iMgPk LOR shft
    ylMgPk(p) := iMgPk
  ENDIF
  shft := shft * 2
NEXT s
```

Note: `ylMgPk(p)` is declared as `INTEGER` (not BYTE), so no staging is needed
when reading it. However `shft` and any intermediate value must also be `INTEGER`.

**`ylFlgs(p)` — packing `isBankrupt` and `hadCashPur` per player:**

```
ylFlgs(p) := 0
IF plyrs(p).isBankrupt THEN
  ylFlgs(p) := 1
ENDIF
IF plyrs(p).hadCashPur THEN
  iFlg      := ylFlgs(p)   ! stage BYTE to INTEGER for LOR
  iFlg      := iFlg LOR 2
  ylFlgs(p) := iFlg
ENDIF
```

Unpack (parent side) — stage `ylFlgs(p)` to INTEGER before LAND:

```
iFlg := ylFlgs(p)   ! BYTE → INTEGER
plyrs(p).isBankrupt  := LAND(iFlg, 1) <> 0
plyrs(p).hadCashPur  := LAND(iFlg, 2) <> 0
```

Bit assignments for `ylFlgs(p)`:

| Bit | Mask | Field |
|-----|------|-------|
| 0 | $01 | isBankrupt |
| 1 | $02 | hadCashPur |

**`ylShrs(54)` flat index** — player p, stock s: `ylShrs((p-1)*9 + s)`

**`ylBnds(18)` flat index** — player p, bond b: `ylBnds((p-1)*3 + b)`

**`ylBnds` downcast note:** `plyrs(p).bondUnts(b)` is INTEGER. Assignment to
BYTE field silently truncates values > 255. The game's starting cash is $5000
and bond units are purchased at $1000 each; max practical units per denomination
is bounded well below 255. This is assumed safe. See Section 5 — Risk Register.

---

## Section 2 — Module Ownership

### 2.1 Pipe Open / Fork / Wait / Read Wrappers

**Module: SNB.b09**

Justification: SNB is the permanent coordinator — it is never released after
PH-00 and orchestrates all phase transitions. The existing `SNB` procedure already
calls `RUN snbSetup(...)` (pre-game) and `RUN runYearLoop(...)` (year loop) directly.
The fork wrappers replace these two call sites. No other module is an appropriate
owner because no other module is guaranteed resident across phase boundaries.

The phase transition table confirms: SNB is `Load on Entry: SNB, snbUtil` at PH-00
and is `Required Resident` in every subsequent phase through PH-12. This is the
only module with a persistent-resident guarantee spanning both fork points.

### 2.2 Pre-Game Serialization

**Module: snbSetup.b09**

The child process runs the setup phase. `snbSetup` owns `initPlayer`, `initMkt`,
`scrStart`, `scrSetup`, and `scrConfirm` — all the procedures that produce the
pre-game state. Adding `serPG` to snbSetup is consistent: the procedure that
creates the state also serializes it.

A separate child entry procedure (`pgChild`) is required in snbSetup.b09 because
the forked child process cannot receive PARAM-based output — it is a new OS-9
process. `pgChild` has no PARAMs; it allocates local game-state variables, calls
`snbSetup(...)` as if it were the parent, then calls `serPG(...)` to write ForkPG
to stdout (pipe), then ENDs.

### 2.3 Year-Loop Serialization

**Module: snbYearLoop.b09**

Same reasoning as pre-game. `runYearLoop` owns all year-loop state. Adding `serYL`
to snbYearLoop is consistent. A child entry procedure (`ylChild`) in snbYearLoop.b09
is required for the same reason as `pgChild`: no PARAM-based handoff from parent
to child is possible across a fork boundary.

`ylChild` has no PARAMs. It loads game state from the pre-fork save file (written by
the parent via `saveGame` before F$Fork), calls `runYearLoop(...)`, then calls
`serYL(...)` to write ForkYL to stdout (pipe), then ENDs.

This design reuses the existing save/load infrastructure to get initial state INTO
the child. The parent calls `saveGame` to a temp file (`SNBFORK`) before forking.
The child calls `loadGame` at startup. This is the only mechanism that avoids
passing > 256 bytes of structured game state via the RunB parameter buffer.

### 2.4 Deserialization and Reconstruction

**Module: SNB.b09**

The parent reads the pipe payload after `F$Wait` returns. Deserialization populates
the parent's live game-state variables. Both `desPG` and `desYL` are added to SNB.b09.
This is consistent with SNB already owning `hdr`, `deckOrd`, `plyrs`, and `mkt` as
DIM variables in the `SNB` procedure.

---

## Section 3 — New Procedure Signatures

All new procedures require TYPE declarations in the standard order (TYPE, PARAM, DIM)
per `bestPractices.md`. All procedures need `ON ERROR GOTO` handlers.

| Procedure | Module | Params | Direction | Purpose |
|-----------|--------|--------|-----------|---------|
| `forkPG` | SNB.b09 | hdr:SaveHdr, deckOrd(36):BYTE, plyrs(6):PlyrRec, mkt:MktState | all OUTPUT | Open pipe, redirect child stdout, fork `pgChild`, wait, read ForkPG, call desPG, close pipe |
| `forkYL` | SNB.b09 | savPath:STRING[20], hdr:SaveHdr, deckOrd(36):BYTE, plyrs(6):PlyrRec, mkt:MktState | hdr/plyrs/mkt are IN/OUT | Save state to SNBFORK, open pipe, redirect, fork `ylChild`, wait, read ForkYL, call desYL, close pipe, delete SNBFORK |
| `desPG` | SNB.b09 | pgBuf:ForkPG, hdr:SaveHdr, deckOrd(36):BYTE, plyrs(6):PlyrRec, mkt:MktState | pgBuf INPUT; others OUTPUT | Unpack ForkPG into hdr/deckOrd/plyrs fields; call initPlayer for each slot; call initMkt; overlay plyrName/plyrType/aiTier from pgBuf |
| `desYL` | SNB.b09 | ylBuf:ForkYL, hdr:SaveHdr, plyrs(6):PlyrRec, mkt:MktState | ylBuf INPUT; others IN/OUT | Unpack ForkYL; overlay mutable fields in plyrs and mkt; unpack bit fields via LAND; update hdr fields |
| `pgChild` | snbSetup.b09 | none | — | Child entry point for pre-game fork. Allocates local SaveHdr/deckOrd/PlyrRec/MktState; calls snbSetup; if menuAct <> 3 calls serPG; ENDs |
| `serPG` | snbSetup.b09 | hdr:SaveHdr, deckOrd(36):BYTE, plyrs(6):PlyrRec | all INPUT | Populate ForkPG TYPE from params; call I$Write to stdout (path 1) with ADDR(pgBuf) and SIZE(ForkPG) |
| `ylChild` | snbYearLoop.b09 | none | — | Child entry point for year-loop fork. Loads SNBFORK via loadGame; calls runYearLoop; calls serYL; ENDs |
| `serYL` | snbYearLoop.b09 | hdr:SaveHdr, plyrs(6):PlyrRec, mkt:MktState | all INPUT | Populate ForkYL TYPE from params; pack divSuspnd, mgnHeld, flags; call I$Write to stdout (path 1) with ADDR(ylBuf) and SIZE(ForkYL) |
| `TSTFKPIPE` | test file | none | — | S1: pipe open/close/write/read round-trip |
| `TSTFKFORK` | test file | none | — | S2: pipe redirect + fork minimal child + read string back |
| `TSTFKPGSER` | test file | none | — | S3: pre-game serialization byte-count and spot-check |
| `TSTFKPGDES` | test file | none | — | S4: pre-game deserialization + reconstruction correctness |
| `TSTFKYLSER` | test file | none | — | S5: year-loop serialization + packing round-trip |
| `TSTFKYLDS` | test file | none | — | S6: year-loop deserialization correctness |
| `TSTFKPGINT` | test file | none | — | S7: full pre-game fork integration |
| `TSTFKYLINT` | test file | none | — | S8: full year-loop fork integration |

### Notes on `desPG` reconstruction

`desPG` calls `initPlayer` for each slot 1..6 (zeroes financial state), then calls
`initMkt` (sets all prices to 100, all divSuspnd to FALSE). It then overlays:
- `hdr.*` fields from pgBuf
- `deckOrd(i)` from `pgBuf.pgDeck(i)` for i=1..36
- `plyrs(p).plyrName` from `pgBuf.pgNam1..pgNam6`
- `plyrs(p).plyrType` from `pgBuf.pgTyp(p)` (BYTE array)
- `plyrs(p).aiTier` from `pgBuf.pgTier(p)` (BYTE array)
- For computer players, call `initAIProf` using `plyrs(p).aiTier`

Financial state (cashBal, shares, etc.) is fully handled by `initPlayer`, since
ForkPG does not carry those fields — they are always at initial values after setup.

---

## Section 4 — Incremental Test Plan

All steps are hardware-testable in order. Step N+1 does not proceed until Step N
passes on device. Each step has a named TST* procedure.

### Step S1 — Pipe Open/Close Round-Trip

**Procedure:** TSTFKPIPE

**What it tests:** I$Open `/pipe` in mode 3, I$Write one byte, I$Read it back,
I$Close. Confirms PIPEMAN is available and the basic pipe path works.

**Pass criterion:** PRINT confirms written byte value matches read byte value.
No carry-set errors from any SysCall. Prints "TSTFKPIPE: PASS".

### Step S2 — Fork/Pipe Stdout Redirect

**Procedure:** TSTFKFORK

**What it tests:** Full parent-side path manipulation sequence:
1. Open `/pipe` (mode 3)
2. Dup path 1 → save as savedOut
3. Close path 1
4. Dup pipePath (assigns pipe to slot 1)
5. Fork RunB with a minimal child that PRINTs a known string and ENDs
6. Close path 1
7. Dup savedOut (restore stdout)
8. Close savedOut
9. F$Wait
10. I$ReadLn from pipePath; confirm string matches
11. Close pipePath

**Pass criterion:** Read string matches the known string. F$Wait returns nonzero PID.
No carry-set errors. Prints "TSTFKFORK: PASS".

**Note:** The child used here is a separate minimal test procedure, not pgChild
or ylChild. Keeps this step independent of serialization.

### Step S3 — Pre-Game Serialization Only

**Procedure:** TSTFKPGSER

**What it tests:** Forks `pgChild` (which calls `snbSetup` with known test values,
then calls `serPG`). Parent reads raw bytes from pipe. Confirms:
- Byte count read = 179
- Spot-checks: `pgBuf.pgMag = $53`, `pgBuf.pgPCnt` matches configured player count,
  `pgBuf.pgTyp(1)` = 1 (HUMAN), `pgBuf.pgNam1` = expected test string

**Pass criterion:** Byte count = 179 confirmed via I$Read return value in regs.y.
At least 3 field spot-checks pass. Prints "TSTFKPGSER: PASS".

### Step S4 — Pre-Game Deserialization and Reconstruction

**Procedure:** TSTFKPGDES

**What it tests:** Calls `desPG` with the ForkPG buffer from S3. Confirms:
- `hdr.magic = $53`
- `hdr.plyrCount` correct
- `deckOrd(1..36)` non-zero (deck was shuffled)
- `plyrs(1).cashBal = 5000` (from initPlayer)
- `plyrs(1).plyrName` = expected test string
- `mkt.stckPrice(1) = 100` (from initMkt)
- `mkt.divSuspnd(1) = FALSE`

**Pass criterion:** All assertions pass. Prints "TSTFKPGDES: PASS".

### Step S5 — Year-Loop Serialization and Packing Round-Trip

**Procedure:** TSTFKYLSER

**What it tests:** Populates a known ForkYL buffer with test values including
specific divSuspnd and mgnHeld bit patterns. Reads the buffer back and confirms
packing round-trips correctly. Focus: bit-packing symmetry between child (pack)
and parent (unpack).

Specific checks:
- Set `divSuspnd(1)=TRUE`, all others FALSE → `ylDvPk` should equal 1
- Set `divSuspnd(9)=TRUE`, all others FALSE → `ylDvPk` should equal 256
- Set `divSuspnd(1)` and `divSuspnd(9)=TRUE` → `ylDvPk` should equal 257
- Round-trip: pack then unpack for each of the above; confirm BOOLEAN array matches

**Pass criterion:** All bit-pattern round-trips confirmed. Byte count read = 199.
Prints "TSTFKYLSER: PASS".

### Step S6 — Year-Loop Deserialization Correctness

**Procedure:** TSTFKYLDS

**What it tests:** Calls `desYL` with a ForkYL buffer containing known test values.
Confirms:
- `mkt.stckPrice(i)` values match for all 9 stocks
- `mkt.divSuspnd(i)` unpacked correctly for test bit pattern
- `plyrs(p).cashBal` correct for all 6 players
- `plyrs(p).isBankrupt` and `hadCashPur` unpacked correctly from `ylFlgs(p)`
- `plyrs(p).stckShrs(s)` correct for all 9 stocks per player (via flat array index)
- `plyrs(p).mgnHeld(s)` correct for test bit pattern
- `plyrs(p).bondUnts(b)` correct for all 3 bonds per player
- Static fields (plyrName, plyrType, aiTier) are NOT altered by desYL

**Pass criterion:** All 6 × (cashBal + isBankrupt + hadCashPur + 9 shares + 9 mgnHeld
+ 3 bonds) assertions pass. Static fields unchanged. Prints "TSTFKYLDS: PASS".

### Step S7 — Integration: Pre-Game Full Path

**Procedure:** TSTFKPGINT

**What it tests:** End-to-end from `forkPG` call in SNB context. User interacts
with the setup screens (scrStart → scrSetup → scrConfirm) in the child process.
After child exits, parent confirms `hdr`, `deckOrd`, and `plyrs` contain the
values entered during setup.

**Pass criterion:** `plyrs(1).plyrName` matches entered name. `hdr.plyrCount`
matches entered count. `deckOrd` is non-trivially shuffled. All cashBal = 5000.
Prints "TSTFKPGINT: PASS".

### Step S8 — Integration: Year-Loop Full Path

**Procedure:** TSTFKYLINT

**What it tests:** End-to-end from `forkYL` call. Parent writes SNBFORK, forks
`ylChild`. Child loads state, runs one year of `runYearLoop`, writes ForkYL, exits.
Parent reads ForkYL and calls `desYL`. Confirms:
- `hdr.currYear` advanced by 1
- `mkt.stckPrice` values changed (at least one non-100 price expected after Year 1)
- `plyrs` mutable fields reflect year-end state

**Pass criterion:** `hdr.currYear` = 2 after one-year run. At least one stckPrice
differs from 100. SNBFORK temp file deleted. Prints "TSTFKYLINT: PASS".

---

## Section 5 — Risk and Constraint Register

### 5.1 256-Byte Pipe Buffer Ceiling

This is a hard limit imposed by PIPEMAN on NitrOS-9. The child must write the
complete payload in a single I$Write call before exiting.

| Payload | Current Size | Headroom | Fields That Would First Breach Limit |
|---------|-------------|----------|--------------------------------------|
| ForkPG | 179 bytes | 77 bytes | Adding bondUnts(3) as INTEGER per player would add 18 bytes → 197 (still safe). Adding stckShrs(9) per player (108 bytes) would breach at 287. |
| ForkYL | 199 bytes | 57 bytes | Upgrading ylBnds to INTEGER (18→36 bytes) would add 18 → 217 (still safe). Adding a second flags byte per player (6 bytes) → 205 (safe). Adding per-player divRate snapshot (9×2×6=108 bytes) would breach. |

If any new field addition to either TYPE would exceed 256 bytes, the design must
first evaluate whether the field can be packed (bit-packing, BYTE downcast) before
concluding that a different IPC mechanism is required.

### 5.2 I$Write and I$Read Exact Byte Counts

`I$Write` must be called with `regs.y = SIZE(ForkPG)` (179) or `SIZE(ForkYL)` (199).
`I$WriteLn` is **prohibited** for binary payloads — it appends CR ($0D), which
corrupts binary fields and breaks the exact-count contract.

`I$Read` on the parent side must use the same exact byte count. The framing is
positional only — there are no delimiters or length headers in the payload.

The `regs.y` register for I$Write and I$Read holds the byte count as an INTEGER.
Both 179 and 199 fit safely within the signed 16-bit INTEGER range.

### 5.3 I$Dup / I$Close / I$Dup Sequence Atomicity

The path slot manipulation sequence (Section A of the syscall research document)
depends on `I$Dup` always assigning the **lowest available** slot number.

The sequence for redirecting stdout to the pipe is:

1. Open `/pipe` → assigned to some path N
2. Dup path 1 (stdout) → saves to slot M (lowest available after step 1)
3. Close path 1 (frees slot 1)
4. Dup path N (pipe) → assigns to slot 1 (now lowest available)
5. Fork child (child inherits path 1 = pipe)
6. Close path 1 again (frees slot 1 from parent's perspective)
7. Dup savedOut (M) → assigns to slot 1 (restore parent stdout)
8. Close savedOut (M)
9. F$Wait

**No other I/O operations of any kind may occur between steps 2 and 4, or between
steps 6 and 7.** Any intervening PRINT, OPEN, GET, or other path operation will
break the slot ordering assumption and corrupt the path table state.

All PRINT debug statements inside `forkPG` and `forkYL` must be placed outside this
critical section.

### 5.4 Bit-Packing Symmetry

The pack/unpack logic for `ylDvPk`, `ylMgPk(p)`, and `ylFlgs(p)` must be identical
in child (serYL) and parent (desYL). Any asymmetry is silent — there are no type
errors or runtime checks on INTEGER bit values.

The canonical bit assignment for all 9-element BOOLEAN→INTEGER pack operations
is stock index s → bit (s-1). Mask value = 2^(s-1). The shift is computed via
integer multiplication (shft := 1; shft := shft * 2) because Basic09 has no
shift operator.

S5 (TSTFKYLSER) specifically tests round-trip symmetry for boundary cases
(only stock 1, only stock 9, both stock 1 and 9) before any integration step.

### 5.5 BYTE-to-INTEGER Staging Rules

All LAND and LOR operations on values derived from BYTE fields or BYTE array
elements must stage through a local INTEGER DIM variable first. The rules from
`bestPractices.md` (hardware-confirmed TSTBYTEINT H2/H5) apply:

- `ylFlgs(p)` is declared BYTE. Before LAND: `iFlg := ylFlgs(p)`; use `iFlg` in LAND.
- Path numbers returned in `regs.a` (BYTE) must be staged: `iPath := regs.a`.
- `regs.cc` (BYTE) must be staged: `iCC := regs.cc` before LAND carry test.
- `regs.b` (BYTE) error codes must be staged: `iErr := regs.b` before printing.
- `ylBnds(i)` is BYTE; when assigning back to `plyrs(p).bondUnts(b)` (INTEGER),
  direct assignment is safe (BYTE→INTEGER widens correctly). No staging needed
  for that direction.

### 5.6 bondUnts BYTE Truncation

`plyrs(p).bondUnts(b)` is INTEGER in PlyrRec. Assignment to `ylBnds(i):BYTE`
silently truncates values > 255. Based on game rules: starting cash $5000, bonds
cost $1000/$5000/$10000 each. Maximum practical units:
- $1000 bond: 5 units initial, grows via dividends but rarely exceeds 50
- $5000 bond: 1 unit initially, rarely exceeds 10
- $10000 bond: 0 units initially, rarely exceeds 5

All values are expected to remain well below 255. This assumption should be
verified with a max-value guard in serYL during testing (print warning if any
bondUnts > 200 as early warning).

### 5.7 Child State Delivery Mechanism (Year Loop)

The year-loop child (ylChild) receives initial game state via a save file (`SNBFORK`)
written by the parent before F$Fork. This adds one `saveGame` + one `loadGame`
round-trip per year. Risk: if F$Fork fails after `saveGame` writes SNBFORK, the
temp file is left on disk. The parent must delete SNBFORK in its error handler
regardless of fork/wait outcome.

### 5.8 Reserved Word Check for New Names

All new TYPE field names and procedure names checked against `bestPractices.md`
reserved word list:

- `pgMag`, `pgFmtV`, `pgCYr`, `pgPCnt`, `pgRMod`, `pgSPhs`, `pgSPlr`, `pgOblg`,
  `pgDkPs`, `pgChks`, `pgDeck`, `pgNam1`..`pgNam6`, `pgTyp`, `pgTier` — CLEAR
- `ylMag`, `ylFmtV`, `ylCYr`, `ylPCnt`, `ylRMod`, `ylSPhs`, `ylSPlr`, `ylOblg`,
  `ylDkPs`, `ylChks`, `ylSPrc`, `ylDvPk`, `ylCash`, `ylMgns`, `ylFlgs`, `ylShrs`,
  `ylMgPk`, `ylBnds` — CLEAR
- Procedure names: `forkPG`, `forkYL`, `desPG`, `desYL`, `pgChild`, `ylChild`,
  `serPG`, `serYL` — CLEAR
- Test names: `TSTFKPIPE`, `TSTFKFORK`, `TSTFKPGSER`, `TSTFKPGDES`,
  `TSTFKYLSER`, `TSTFKYLDS`, `TSTFKPGINT`, `TSTFKYLINT` — CLEAR

One caution: `pgOblg` and `ylOblg` map to `hdr.obligation` (INTEGER). Field naming
is consistent with no reserved word conflicts.
