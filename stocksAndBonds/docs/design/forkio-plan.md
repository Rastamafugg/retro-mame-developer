# forkio-plan.md — Phase Coordination and Refactoring Roadmap

**Architecture:** Option 2 — File-based IPC. `SNBSTATE` is the sole handoff
channel between the SNB coordinator and each phase child. Pipe-based IPC
(ForkPG, ForkYL, I$Dup/I$Close sequences) has been superseded and is not
implemented.

---

## Section 1 — Architecture Overview

The SNB coordinator (`SNB.b09`) runs as the persistent parent process for
the entire game session. It forks a child process for each major phase.
Each child reads `SNBSTATE` at startup, runs its phase logic, writes the
updated `SNBSTATE` at exit, then terminates. The coordinator reads only
the 11-byte `SaveHdr` from `SNBSTATE` after each `F$Wait` to decide what
to fork next.

```
SNB (coordinator)
  │
  ├─ chkStale          Delete stale SNBSTATE if present
  │
  ├─ forkPhase(pgChild) ── pgChild reads nothing (first write)
  │    F$Wait              pgChild runs setup screens
  │    read SaveHdr        pgChild writes SNBSTATE (gameStage=GS_PREGM)
  │
  ├─ LOOP while gameStage <> GS_DONE
  │    │
  │    ├─ forkPhase(ylChild) ── ylChild reads SNBSTATE
  │    │    F$Wait              ylChild runs one year
  │    │    read SaveHdr        ylChild writes SNBSTATE (gameStage=GS_YEAR
  │    │                        or GS_DONE)
  │    │
  │    └─ evaluate: currYear > maxYears? activePlayers <= 1?
  │         if true: exit LOOP
  │
  └─ forkPhase(egChild) ── egChild reads SNBSTATE
       F$Wait              egChild runs end-game screens
                           (no SNBSTATE write required)
```

The coordinator never holds live game state in memory between phase
transitions. All state is owned by `SNBSTATE`.

---

## Section 2 — gameStage State Machine

`gameStage` is written by each child at exit. The coordinator reads it
after `F$Wait` to select the next fork target.

| Value | Constant | Written By | Coordinator Action |
|-------|----------|-----------|-------------------|
| 1 | GS_PREGM | Pre-game child | Fork first year-loop child |
| 2 | GS_YEAR | Year-loop child | Evaluate year count and bankruptcy; fork again or advance |
| 3 | GS_DONE | Year-loop child | Fork end-game child; exit coordinator loop |

### Coordinator Phase Selection Logic

After each `F$Wait` and header read:

```
IF gameStage = GS_PREGM THEN
    ! First year: fork ylChild unconditionally
    RUN forkPhase("ylChild")

ELSE IF gameStage = GS_YEAR THEN
    ! Evaluate exit conditions
    activePlrs := plyrCount - countBits(bnkrFlgs)
    IF currYear > maxYears OR activePlrs <= 1 THEN
        gameStage := GS_DONE   ! force end-game fork
    ELSE
        RUN forkPhase("ylChild")
    ENDIF

ENDIF \ENDIF

IF gameStage = GS_DONE THEN
    RUN forkPhase("egChild")
    ! F$Wait for egChild; then exit coordinator loop
ENDIF
```

`countBits` is a local inline computation over bits 0–5 of `bnkrFlgs`.
`activePlrs <= 1` triggers end-game when only one player (or zero) remains
solvent; one player cannot meaningfully continue.

---

## Section 3 — SNBSTATE as IPC Channel

`SNBSTATE` is a standard save file (identical format to user saves) written
to the current data directory. It is not a pipe, not a special file, and
requires no OS-level IPC primitives beyond standard `I$Create`/`I$Open`.

### Parent writes SNBSTATE before forking ylChild

The coordinator calls `saveGame("SNBSTATE", hdr, deckOrd, plyrs, mkt)`
before each `forkPhase("ylChild")` call. The header fields `currYear`,
`gameStage`, and any coordinator-level overrides are set before this call.
The year-loop child reads this file at startup.

### Parent does NOT write SNBSTATE before forking pgChild

The pre-game child creates `SNBSTATE` from scratch. There is no prior
state to hand forward.

### Parent reads ONLY SaveHdr after F$Wait

The coordinator opens `SNBSTATE` in read mode, reads only `SIZE(SaveHdr)`
= 11 bytes, then closes the file. It does not read player records or market
state. All decisions are made from the 11-byte header.

### SNBSTATE lifecycle

| Event | Action |
|-------|--------|
| New game start | `chkStale` deletes stale `SNBSTATE` if found |
| Pre-game child exit | Child creates `SNBSTATE` with `gameStage=GS_PREGM` |
| Year-loop child exit | Child overwrites `SNBSTATE` with updated state |
| End-game child exit | Child reads `SNBSTATE`; no write required |
| Game complete | Coordinator exits; `SNBSTATE` remains on disk until next new game |
| Player-initiated save | `saveGame` writes named user file; `SNBSTATE` unaffected |

---

## Section 4 — Module Ownership

### SNB.b09 — Coordinator

Owns the top-level coordinator loop, `forkPhase`, `chkStale`, and
`readHdr` (header-only file read). SNB is resident for the entire game
session and is the only module guaranteed present across all phase
boundaries.

No live game state (plyrs, mkt, deckOrd) is held in SNB between phases
under Option 2. SNB holds only the SaveHdr struct after each phase
transition.

### snbSetup.b09 — Pre-Game Child Entry

Owns `pgChild`: the top-level entry procedure for the pre-game fork.
`pgChild` allocates local SaveHdr, deckOrd, PlyrRec, and MktState
variables; calls the existing setup procedures (`initPlayer`, `initMkt`,
`scrStart`, `scrSetup`, `scrConfirm`); then calls `saveGame("SNBSTATE")`
with `gameStage = GS_PREGM` and `maxYears` set from the configured game
length.

Existing setup procedures (`initPlayer`, `initMkt`, etc.) are unchanged.
They continue to take their existing parameters.

### snbYearLoop.b09 — Year-Loop Child Entry

Owns `ylChild`: the top-level entry procedure for the year-loop fork.
`ylChild` calls `loadGame("SNBSTATE")` at startup, calls `runYearLoop`
with the loaded state, then updates `hdr.currYear`, `hdr.gameStage`, and
calls `saveGame("SNBSTATE")` at exit.

`ylChild` determines `gameStage` at exit:
- If the year just completed is `maxYears` or only one player remains
  active: write `GS_DONE`.
- Otherwise: write `GS_YEAR`.

Existing year-loop procedures are unchanged.

### End-Game Module — End-Game Child Entry

Owns `egChild`: the top-level entry procedure for the end-game fork.
`egChild` calls `loadGame("SNBSTATE")`, runs closing price display and
winner determination, then ENDs. No `saveGame` call is required at exit
unless save-on-exit for the completed game is desired (deferred decision).

### snbSaveLoad.b09 — Save/Load Infrastructure

Owns `saveGame`, `loadGame`, and `guardSave`. Updated to reflect the
revised SaveHdr and PlyrRec types, trimmed deck write/read, and updated
checksum. `guardSave` rejects `SNBSTATE` as a player-supplied filename.

---

## Section 5 — Procedure Signatures

All procedures require TYPE declarations in the standard order
(TYPE, PARAM, DIM) per `bestPractices.md`. All require `ON ERROR GOTO`.

| Procedure | Module | Key Params | Purpose |
|-----------|--------|-----------|---------|
| `forkPhase` | SNB.b09 | childName:STRING[20] | Fork RunB with childName as target; F$Wait; call readHdr |
| `readHdr` | SNB.b09 | hdr:SaveHdr OUT | Open SNBSTATE, read 11-byte header, close |
| `chkStale` | SNB.b09 | wasStale:BOOLEAN OUT | Attempt I$Open SNBSTATE; if found, close and delete |
| `pgChild` | snbSetup.b09 | none | Pre-game child entry; allocates state; calls setup procs; calls saveGame(SNBSTATE) |
| `ylChild` | snbYearLoop.b09 | none | Year-loop child entry; calls loadGame; runs year; calls saveGame(SNBSTATE) |
| `egChild` | (end-game module) | none | End-game child entry; calls loadGame; runs end-game; ENDs |
| `saveGame` | snbSaveLoad.b09 | savePath, hdr, deckOrd(36), plyrs(6), mkt | Write full state; compute bnkrFlgs and checksum internally |
| `loadGame` | snbSaveLoad.b09 | savePath, hdr, deckOrd(36), plyrs(6), mkt, loadOK | Read full state; validate header; return loadOK |
| `guardSave` | snbSaveLoad.b09 | savName:STRING[20], isOK:BOOLEAN OUT | Reject SNBSTATE as filename; set isOK=FALSE if match |

`forkPhase` passes the child module name as the RunB parameter string
(module name + CR), consistent with the confirmed F$Fork/RunB pattern
from project hardware tests.

---

## Section 6 — Refactoring Roadmap

Steps are ordered by dependency. Each step is independently
hardware-testable. Step N+1 does not proceed until Step N passes on
device.

---

### R1 — TYPE Revisions

**Scope:** Update SaveHdr and PlyrRec TYPE declarations in every
procedure that declares them.

**SaveHdr changes:**
- Remove: `obligation`, `deckPos`
- Add: `maxYears`, `gameStage`, `bnkrFlgs`
- Field order: static block (magic, fmtVersion, maxYears, plyrCount,
  rollMode) then dynamic block (currYear, savedPhase, savedPlyr,
  gameStage, bnkrFlgs, checksum)
- SIZE remains 11 bytes

**PlyrRec changes:**
- Add `obligation:INTEGER` after `marginTot`
- SIZE grows from 61 to 63 bytes

**Files affected:** All .b09 procedures that declare SaveHdr or PlyrRec.
Minimum: `snbSaveLoad.b09`, `SNB.b09`, `snbSetup.b09`, `snbYearLoop.b09`.

**Test:** `TSTRTYPE`
- Compile all affected modules
- Print `SIZE(SaveHdr)` — expected 11
- Print `SIZE(PlyrRec)` — expected 63
- **Pass criterion:** Both values confirmed on hardware. No compile errors.

---

### R2 — snbSaveLoad.b09 Behavioral Update

**Scope:** Update `saveGame` and `loadGame` for the new types. Add
`guardSave`.

**saveGame changes:**
- Caller no longer sets `bnkrFlgs` or `checksum` — computed internally
- Caller no longer sets `deckPos` (eliminated from header)
- Deck write: loop `FOR i := 1 TO hdr.maxYears; PUT #path, deckOrd(i)`
- Checksum covers 10 BYTE fields (see `save-load-design.md §7`)
- `bnkrFlgs` computation precedes checksum computation

**loadGame changes:**
- Read header first; validate before reading deck section
- Deck read: loop `FOR i := 1 TO hdr.maxYears; GET #path, deckOrd(i)`
- Updated checksum verification formula

**guardSave:** String comparison of caller-supplied filename against
literal `"SNBSTATE"`. If match: set `isOK := FALSE`, print rejection
message, return. Otherwise: `isOK := TRUE`, return. Does not open any
file.

**Forced liquidation resume path:** Update any call to
`enterForcedLiq(...)` that passed `hdr.obligation` to instead pass
`plyrs(hdr.savedPlyr).obligation`.

**Test:** `TSTSLV2`
- Populate known SaveHdr, deckOrd (5-year game), 6 PlyrRec, MktState
- Call saveGame; verify file created with no error
- Call loadGame; verify all fields round-trip correctly
- Spot-check: `hdr.maxYears`, `hdr.gameStage`, `plyrs(1).obligation`,
  `deckOrd(5)` (last written entry), `deckOrd(6)` (not written; verify
  unchanged from pre-load value in memory)
- Call guardSave with `"SNBSTATE"` — verify `isOK = FALSE`
- Call guardSave with `"SNBGAME"` — verify `isOK = TRUE`
- **Pass criterion:** All field round-trips correct. guardSave both
  branches confirmed. Prints "TSTSLV2: PASS".

---

### R3 — SNB.b09: Coordinator Infrastructure

**Scope:** Add `chkStale`, `readHdr`, and `forkPhase` to SNB.b09.
Do not yet wire them into the main coordinator loop (that is R4).

**chkStale:**
- Attempt `I$Open "SNBSTATE"` in read mode via SysCall
- If carry clear (file found): close it; call `I$Delete "SNBSTATE"`
- If carry set (file not found): no action
- Return `wasStale:BOOLEAN`

**readHdr:**
- `I$Open "SNBSTATE"` in read mode
- `GET #path, hdr` (reads exactly SIZE(SaveHdr) = 11 bytes)
- `I$Close`
- Returns populated `hdr:SaveHdr`
- On error: delegate to caller via `ERROR(ERR)`

**forkPhase:**
- Accepts `childName:STRING[20]`
- Builds parameter string: childName + CR
- Issues F$Fork targeting RunB with parameter string
- Issues F$Wait; captures child PID and exit status
- Returns child exit status to caller
- On non-zero exit status: delegate error to caller

**Test:** `TSTCOORD`
- Write a synthetic SNBSTATE with known header values using saveGame
- Call readHdr; verify `hdr.gameStage`, `hdr.currYear`, `hdr.maxYears`
  match written values
- Write a second SNBSTATE; call chkStale; verify `wasStale = TRUE` and
  file is gone; call chkStale again; verify `wasStale = FALSE`
- Call forkPhase with a trivial test module that exits with code 0;
  verify F$Wait returns and exit status is 0
- **Pass criterion:** All three sub-tests pass. Prints "TSTCOORD: PASS".

---

### R4 — SNB.b09: Coordinator Loop

**Scope:** Replace the existing direct `RUN snbSetup(...)` and
`RUN runYearLoop(...)` calls in the main SNB procedure with the
coordinator loop. The coordinator loop uses `chkStale`, `forkPhase`,
and `readHdr` from R3.

**Main SNB procedure changes:**
- Call `chkStale` at new-game entry
- Call `forkPhase("pgChild")`; call `readHdr` → confirm `gameStage = GS_PREGM`
- Enter coordinator loop:
  - Call `forkPhase("ylChild")` while `gameStage = GS_YEAR` or `GS_PREGM`
  - After each wait: call `readHdr`; evaluate `currYear > maxYears` and
    `bnkrFlgs`; set `gameStage := GS_DONE` if exit condition met
  - On `gameStage = GS_DONE`: call `forkPhase("egChild")`; `F$Wait`;
    exit loop

**Existing direct RUN calls to snbSetup and runYearLoop are removed.**

**Test:** `TSTCOORDLP`
- Write a synthetic SNBSTATE with `gameStage = GS_YEAR`, `currYear = 10`,
  `maxYears = 10`; verify coordinator loop exits to end-game fork on next
  `readHdr` evaluation
- Write a synthetic SNBSTATE with `bnkrFlgs` indicating 5 of 6 players
  bankrupt and `plyrCount = 6`; verify coordinator exits to end-game fork
- **Pass criterion:** Both early-exit conditions trigger correctly.
  Prints "TSTCOORDLP: PASS".

---

### R5 — snbSetup.b09: pgChild Entry Procedure

**Scope:** Add `pgChild` to `snbSetup.b09`. Existing setup procedures
are unchanged.

**pgChild logic:**
- Declare local SaveHdr, deckOrd(36):BYTE, plyrs(6):PlyrRec, MktState
- Initialize all via `initPlayer` (all 6 slots) and `initMkt`
- Call existing setup procedures to populate player config and game rules
- Populate `hdr.magic`, `hdr.fmtVersion`, `hdr.maxYears`, `hdr.plyrCount`,
  `hdr.rollMode`, `hdr.currYear := 1`, `hdr.savedPhase := 0`,
  `hdr.savedPlyr := 0`, `hdr.gameStage := GS_PREGM`
- Call `guardSave("SNBSTATE", isOK)` — should always pass; log if not
- Call `saveGame("SNBSTATE", hdr, deckOrd, plyrs, mkt)`
- END

**Deck trimming:** The shuffle procedure fills all 36 entries of `deckOrd`.
After the shuffle, `maxYears` is known. `saveGame` writes only entries
1 through `maxYears`. No additional trimming step is required in `pgChild`.

**Test:** `TSTPGCHLD`
- Fork `pgChild` via `forkPhase`; interact with setup screens to configure
  a 5-player, 8-year game
- After `F$Wait`: call `readHdr`; verify `gameStage = 1` (GS_PREGM),
  `plyrCount = 5`, `maxYears = 8`, `currYear = 1`, `bnkrFlgs = 0`
- Call `loadGame("SNBSTATE", ...)`: verify `plyrs(1).plyrName`,
  `plyrs(1).cashBal = 5000`, `deckOrd(8)` non-zero, `deckOrd(9)`
  untouched (not loaded from file)
- **Pass criterion:** All assertions pass. Prints "TSTPGCHLD: PASS".

---

### R6 — snbYearLoop.b09: ylChild Entry Procedure

**Scope:** Add `ylChild` to `snbYearLoop.b09`. Existing year-loop
procedures are unchanged.

**ylChild logic:**
- Declare local SaveHdr, deckOrd(36):BYTE, plyrs(6):PlyrRec, MktState
- Call `loadGame("SNBSTATE", hdr, deckOrd, plyrs, mkt, loadOK)`
- If not `loadOK`: print error; END
- Call `runYearLoop(hdr, deckOrd, plyrs, mkt)` (or equivalent entry)
- After `runYearLoop` returns: update `hdr.currYear` to reflect
  completed year
- Determine `gameStage` at exit:
  - Count active players from `plyrs` array
  - If `hdr.currYear > hdr.maxYears` OR `activePlayers <= 1`:
    `hdr.gameStage := GS_DONE`
  - Else: `hdr.gameStage := GS_YEAR`
- Call `saveGame("SNBSTATE", hdr, deckOrd, plyrs, mkt)`
  (saveGame computes bnkrFlgs and checksum internally)
- END

**Test:** `TSTYLCHLD`
- Write a synthetic SNBSTATE with known state (Year 2 of 5, 4 players)
- Fork `ylChild`; wait
- Call `readHdr`: verify `currYear = 3`, `gameStage = GS_YEAR`
- Call `loadGame`: verify at least one `stckPrice` differs from 100
  (market resolved during the year)
- Repeat with `currYear = 5` of `maxYears = 5`; verify `gameStage = GS_DONE`
- **Pass criterion:** Both year-exit scenarios produce correct `gameStage`.
  Prints "TSTYLCHLD: PASS".

---

### R7 — End-Game Phase

**Scope:** Implement `egChild` in the end-game module.

**egChild logic:**
- Call `loadGame("SNBSTATE", ...)`
- Sell all remaining securities at closing prices (spec end-game rules)
- Display closing portfolio values and determine winner
- END (no saveGame call required)

**Test:** `TSTEGCHLD`
- Write a synthetic SNBSTATE with `gameStage = GS_DONE`, known player
  portfolios, known stock prices
- Fork `egChild`; wait
- Verify correct output displayed (winner announcement matches expected
  winner given known state)
- **Pass criterion:** End-game runs to completion without error.
  Prints "TSTEGCHLD: PASS".

---

### R8 — Full Integration

**Scope:** End-to-end game run from coordinator loop through all phases.

**Test:** `TSTFULLGM`
- Launch SNB normally
- Play a complete 3-year game with 2 human players (minimum viable game)
- Verify all phase transitions execute without error
- Verify `SNBSTATE` reflects correct final state before end-game
- Verify end-game displays correct winner
- **Pass criterion:** Game completes. No error popups. Correct winner
  displayed. Prints "TSTFULLGM: PASS".

---

## Section 7 — Test Summary

| Step | Test Procedure | Module | What It Confirms |
|------|---------------|--------|-----------------|
| R1 | TSTRTYPE | Multiple | SIZE(SaveHdr)=11, SIZE(PlyrRec)=63 |
| R2 | TSTSLV2 | snbSaveLoad.b09 | saveGame/loadGame round-trip; guardSave |
| R3 | TSTCOORD | SNB.b09 | readHdr, chkStale, forkPhase |
| R4 | TSTCOORDLP | SNB.b09 | Coordinator loop exit conditions |
| R5 | TSTPGCHLD | snbSetup.b09 | Pre-game child writes correct SNBSTATE |
| R6 | TSTYLCHLD | snbYearLoop.b09 | Year child reads, runs, writes correctly |
| R7 | TSTEGCHLD | end-game module | End-game child runs to completion |
| R8 | TSTFULLGM | All | Full game end-to-end |

Each test must pass on hardware before the next step begins.

---

## Section 8 — Risk and Constraint Register

### 8.1 Header Read After F$Wait — File Ordering

The coordinator calls `saveGame("SNBSTATE")` before forking `ylChild`.
The child calls `loadGame("SNBSTATE")` at startup. This sequence is safe
because `F$Fork` does not return to the parent until the child process is
scheduled — the parent's `saveGame` write completes before the child
executes.

The coordinator's `readHdr` call after `F$Wait` is safe for the same
reason: `F$Wait` does not return until the child has exited, ensuring the
child's `saveGame` write is complete.

No synchronization primitives are required.

### 8.2 SNBSTATE Deletion on Abnormal Exit

If `forkPhase` returns an error (child exited abnormally), `SNBSTATE`
may be in an indeterminate state. The coordinator's `ON ERROR` handler
should attempt to delete `SNBSTATE` before propagating the error, to
prevent a stale file from corrupting a subsequent new-game session.
`chkStale` at new-game startup provides a secondary safeguard.

### 8.3 bnkrFlgs BYTE-to-INTEGER Staging

`hdr.bnkrFlgs` is a BYTE field. All LAND and LOR operations on it must
stage through a local INTEGER variable first per `bestPractices.md`.
This applies in:
- `saveGame`: computing bnkrFlgs from plyrs.isBankrupt
- `ylChild`: computing gameStage exit decision from bnkrFlgs
- Coordinator loop: counting active players from bnkrFlgs

The confirmed hardware rule: BYTE field directly into an INTEGER PARAM
produces `byteValue × 256 + nextMemByte`. Always assign BYTE to INTEGER
DIM variable before arithmetic.

### 8.4 Deck Array Sizing

The in-memory `deckOrd` array must be declared as `DIM deckOrd(36):BYTE`
in all procedures that hold it. Basic09 array sizes are compile-time
constants; the array cannot be sized dynamically to `maxYears`. `saveGame`
and `loadGame` access only indices 1 through `hdr.maxYears` via loops.
Indices above `maxYears` in the live array contain shuffle residue and
are never read or written to disk.

### 8.5 obligation Field Location in Resume Path

All procedures that reference `hdr.obligation` (as it existed in the
prior SaveHdr design) must be updated to reference
`plyrs(hdr.savedPlyr).obligation`. Search for `hdr.obligation` and
`.obligation` across all .b09 files before R2 is considered complete.
The forced liquidation resume path in the load-game caller is the
primary location.

### 8.6 Reserved Word Check for New Names

All new procedure names and variable names checked against
`bestPractices.md` reserved word list:

- Procedure names: `forkPhase`, `readHdr`, `chkStale`, `pgChild`,
  `ylChild`, `egChild`, `guardSave` — CLEAR
- Variable names: `wasStale`, `isOK`, `childName`, `activePlrs`,
  `iFlgs`, `iMask` — CLEAR
- Header field names: `maxYears`, `gameStage`, `bnkrFlgs` — CLEAR
- Constants: `GS_PREGM`, `GS_YEAR`, `GS_DONE` — these are used as
  literal BYTE values (1, 2, 3) in code; the labels are documentation
  only

### 8.7 Pipe IPC Infrastructure — Disposition

The following procedures and test files from the previous pipe-based
design are superseded and should not be implemented:

- `forkPG`, `forkYL`, `desPG`, `desYL`, `serPG`, `serYL`
- `ForkPG` TYPE, `ForkYL` TYPE
- `TSTFKFORK`, `TSTFKPGSER`, `TSTFKPGDES`, `TSTFKYLSER`, `TSTFKYLDS`,
  `TSTFKPGINT`, `TSTFKYLINT`

`TSTFKPIPE` (basic pipe open/close/write/read round-trip) may be
retained as a general IPC diagnostic if desired, but is not part of the
SNB production architecture.

### 8.8 Module Loading — pgChild and ylChild Availability

`pgChild` and `ylChild` must be reachable by RunB when forked. Both
procedures are I-code modules in their respective .b09 source files.
They must be compiled, packed, and ATTRed with the execute bit before
`forkPhase` is called. The module name passed to `forkPhase` must match
the compiled procedure name exactly, including case.

Confirm the RunB parameter string format (module name + CR, no trailing
spaces) against the project's confirmed F$Fork/RunB test results before
R5 proceeds.