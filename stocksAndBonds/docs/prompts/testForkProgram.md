---

## Section A — Syscall Research Summary

**Task description:** Fork a child process from a parent Basic09 module, pass a parameter string to the child via the OS-level parameter area, then block the parent until the child exits.

---

### Applicable System Calls

| Call Name | Code (hex) | Input Registers | Output Registers | Carry Clear Meaning | Carry Set Meaning |
|---|---|---|---|---|---|
| F$Fork | $03 | A=lang/type, B=data area pages, X=name address, Y=param area pages, U=param area address | X=past end of name, A=child I/O number | Child process created | Error; B=error code |
| F$Wait | $04 | None | A=child process ID, B=child exit status | Child died normally; B=child status | Error; B=error code |
| F$Exit | $06 | CC=carry state, B=status code | (process terminated) | Clean exit | Error exit |

---

### Call Sequence

1. **Pre-condition:** Ensure the child module is resident in the system module directory. Either LOAD it prior to forking, or ensure it is already packed and loaded. F$Fork will attempt to load from disk if the module is not in memory, using the name string as a pathlist.
2. **Build the module name string** in a buffer in the parent's data area. The string must be terminated with CR ($0D), NUL ($00), or by setting bit 7 of the last character. X must point to the first byte.
3. **Build the parameter string** in a separate buffer in the parent's data area, at least one full page (256 bytes). The content of this buffer is copied verbatim into the child's parameter area by NitrOS-9. Terminate the parameter string with CR ($0D). X in the child will point to this copied string.
4. **Stage the F$Fork call:** Set regs.a=$00 (any lang/type), regs.b=requested additional data pages (minimum 1; do not pass 0), regs.x=ADDR(nameBuffer), regs.y=1 (one page of parameter area), regs.u=ADDR(paramBuffer).
5. **Issue F$Fork via SysCall.** Code = $03.
6. **Check carry in regs.cc.** If carry set, read regs.b for error code and abort.
7. **Carry clear:** Capture regs.a (child I/O number). **[INFERRED]** This is a path number, not the process ID; it may need to be closed after the child terminates. Hardware confirmation required.
8. **Issue F$Wait via SysCall immediately.** No inputs required. Code = $04. The parent blocks until any child exits.
9. **Check carry in regs.cc.** Carry clear = child exited. regs.a = deceased child process ID. regs.b = child exit status (0 = clean). Carry set = error (likely $E2 = No Children, or a signal woke the parent).
10. **Post-condition:** If regs.a = 0 on F$Wait exit, the parent itself received a signal, not a child death. Handle accordingly.

---

### Error Codes

| Code (hex) | Code (dec) | Meaning | Relevant call |
|---|---|---|---|
| $CF | 207 | MEMORY FULL — insufficient RAM for child data area | F$Fork |
| $D7 | 215 | BAD PATHNAME — module name string is malformed | F$Fork |
| $D8 | 216 | PATH NAME NOT FOUND — module not in directory, not findable on disk | F$Fork |
| $DD | 221 | MODULE NOT FOUND — module not in system module directory | F$Fork |
| $E0 | 224 | ILLEGAL PROCESS NUMBER | F$Fork |
| $E2 | 226 | NO CHILDREN — F$Wait called with no live children | F$Wait |
| $E4 | 228 | PROCESS ABORTED — child or parent received signal code 2 | F$Wait |
| $E5 | 229 | PROCESS TABLE FULL — no process table slots available | F$Fork |
| $E6 | 230 | ILLEGAL PARAMETER AREA — Y/U bounds are incorrect | F$Fork |
| $EB | 235 | BAD NAME — module name contains illegal characters | F$Fork |
| $EE | 238 | UNKNOWN PROCESS ID | F$Wait |

---

### Register Staging Notes

- **regs.a (BYTE):** Language/type code for F$Fork. Assign $00 directly to the BYTE field — no staging required.
- **regs.b (BYTE):** Data area size in pages for F$Fork; child exit status on F$Wait return. Assign directly to BYTE field.
- **regs.x (INTEGER):** Must receive the address of the name string buffer. Use `ADDR(nameBuf)` and assign to the INTEGER field directly. ADDR() returns an INTEGER in Basic09 — no staging required.
- **regs.y (INTEGER):** Parameter area size in pages. Assign as an INTEGER literal (e.g., 1). The OS reads the full 16-bit Y register; a value of 1 means one page (256 bytes).
- **regs.u (INTEGER):** Address of the parameter buffer in the parent's data area. Use `ADDR(paramBuf)` and assign to the INTEGER field. Same as regs.x — no staging required.
- **Carry flag:** Extract the carry bit from regs.cc (bit 0) after each call to determine success or failure. Use `LAND(regs.cc, 1)` to isolate the carry.

---

### Edge Cases

- The documentation states explicitly: **do not fork a process with a memory size of zero.** regs.b must be >= 1.
- If the parent calls F$Wait and a child already died before the call, NitrOS-9 reactivates the parent immediately — F$Wait does not deadlock in this case.
- If the parent has multiple children, one F$Wait call detects only the first child to die. One F$Wait per expected child is required.
- If F$Wait returns with A=0, the parent received a signal rather than a child death. If an intercept trap (F$Icpt) was not set up, the parent may have been killed. Confirm A != 0 before treating B as a child exit status.
- The parameter buffer in the parent must remain valid until after F$Fork returns. NitrOS-9 copies the parameter area during the fork; the buffer can be released or overwritten after the call completes.
- **[INFERRED]** The child I/O number returned in regs.a after F$Fork may be a path number that should be closed with I$Close after F$Wait returns, to avoid path table leaks. Hardware confirmation required before the coding agent acts on this.
- The name string X register value is advanced past the name terminator by F$Fork. The original string buffer is unmodified; the register value change is internal to the shim.

---

## Section B — Coding Agent Prompt

```
You are implementing a two-module test program for NitrOS-9 / CoCo3 / Basic09.
This test is STANDALONE and is NOT part of the Stocks and Bonds game modules.
Do not modify any existing project module.

Before writing any code, read bestPractices.md in full, then read the project
module map and memory-map.md to confirm there is no existing fork/wait procedure
that would conflict with this test.

---

OVERVIEW

Implement two new Basic09 procedures, each in its own .b09 source file:

  1. tForkParent — the parent process: forks a child, passes parameters, waits.
  2. tForkChild  — the child process: receives parameters, prints them, exits cleanly.

Both are standalone test modules. Neither calls into the Stocks and Bonds module tree.
Both must use the project-standard SysCall shim and Register TYPE.

---

BEFORE WRITING CODE

Look up the following in project knowledge:
  - The exact definition of the Register TYPE (cc, a, b, dp: BYTE; x, y, u: INTEGER).
  - The calling convention for the SysCall shim procedure.
  - The ADDR() built-in behavior and return type.
  - The LAND() built-in for bitwise AND on BYTE/INTEGER values.

Confirm these before writing any DIM or PARAM declarations.

---

tForkChild — CHILD MODULE

Purpose: Accept a parameter string from its parameter area and print it, then exit.

The child does NOT receive parameters via Basic09 PARAM declarations.
Parameters are in the OS-level parameter area, which NitrOS-9 places at the top
of the child's data area. In the child process, the OS sets X to point to the
parameter string in the child's address space.

For this test, the child should read one line from standard input (path 0),
print what it received as confirmation, then fall through to normal exit.
The child must NOT call F$Exit explicitly — normal Basic09 procedure exit is sufficient.

The child module name must be: tForkChild
The packed module filename must be: tForkChild

---

tForkParent — PARENT MODULE

Purpose: Fork tForkChild with a test parameter string, then wait for it to exit.

Step 1 — Build the module name string.
  Allocate a BYTE array of at least 16 bytes.
  Fill it with the characters of "tForkChild".
  Set the high bit (OR with $80) on the last character to terminate the name.
  This is the hi-bit-terminated name string required by F$Fork.

Step 2 — Build the parameter string.
  Allocate a BYTE array of exactly 256 bytes (one full OS page).
  Fill it with a short test string, e.g. "Hello from parent".
  Terminate the string with a CR byte ($0D).
  Zero-fill the remainder.

Step 3 — Call F$Fork.
  System call code: $03
  Register staging:
    regs.a := $00          (any language/type)
    regs.b := 1            (request 1 additional data page for child)
    regs.x := ADDR(nameBuf)   (INTEGER — address of name byte array)
    regs.y := 1            (1 page = 256 bytes of parameter area)
    regs.u := ADDR(paramBuf)  (INTEGER — address of parameter byte array)
  After the call:
    If LAND(regs.cc, 1) = 1: print the error code from regs.b, halt.
    If LAND(regs.cc, 1) = 0: capture regs.a as iChildIO (INTEGER staging from BYTE).

Step 4 — Call F$Wait.
  System call code: $04
  No input registers required — zero all regs fields before the call.
  After the call:
    If LAND(regs.cc, 1) = 1: print error code from regs.b, halt.
    If LAND(regs.cc, 1) = 0:
      If regs.a = 0: print "Parent received signal, not child death" and halt.
      Otherwise: print "Child exited, PID=", regs.a, " status=", regs.b

Step 5 — Print pass/fail summary and fall through to normal exit.

---

RESERVED WORD HAZARDS

  - SYSCALL is a Basic09 reserved word. The shim procedure name is SysCall (mixed case).
    Call it as: RUN SysCall(callCode, regs)
  - Do not use WAIT, FORK, EXIT, or KILL as variable names.
  - ADDR is a reserved word — use it only as a built-in function, not as a variable name.

BYTE/INTEGER STAGING RULES

  - ADDR() returns an INTEGER. Assign directly to regs.x or regs.u (INTEGER fields).
  - When reading regs.a or regs.b after a call, stage through a local INTEGER DIM
    variable if the value will be passed to any procedure expecting INTEGER.
  - Do not pass regs.a or regs.b (BYTE fields) directly to an INTEGER PARAM.

QA REQUIREMENTS

  - Add a TST* companion procedure: TSTForkParent
  - TSTForkParent must invoke tForkParent and report PASS if it exits without error,
    FAIL with error code if F$Fork or F$Wait returns carry set.
  - Before finalizing, run through the bestPractices.md QA checklist in full.
  - Confirm no reserved word conflicts. Confirm all variable names are unique within
    each procedure. Confirm TYPE declaration is on a single line.
```

---

## Section C — On-Device Test Instructions

1. **Compile and pack the child module first:**
   ```
   RUN b09,"tForkChild"
   RUN pack,"tForkChild"
   ```

2. **Set executable attribute on the child module:**
   ```
   ATTR tForkChild -e
   ```

3. **Compile and pack the parent module:**
   ```
   RUN b09,"tForkParent"
   RUN pack,"tForkParent"
   ```

4. **Set executable attribute on the parent module:**
   ```
   ATTR tForkParent -e
   ```

5. **Load the child module into the system module directory before running the parent:**
   ```
   LOAD tForkChild
   ```

6. **Run the parent:**
   ```
   RUN tForkParent
   ```

7. **Expected output — success path:**
   - Child window or output path prints: `Hello from parent` (or similar confirmation that the parameter string arrived)
   - Parent output prints: `Child exited, PID=` followed by a non-zero integer and ` status=0`
   - No error codes printed

8. **Failure indicators:**
   - `F$Fork error:` followed by a decimal error code — check the error code table in Section A
   - `F$Wait error:` followed by a decimal error code
   - `Parent received signal, not child death` — indicates a signal interrupted F$Wait; run again in a quieter process state
   - Error code $E5 (229) = process table full — kill background processes and retry
   - Error code $DD (221) or $D8 (216) = child module not found — confirm LOAD step completed without error

9. **Pass criteria — all of the following must be true:**
   - Parent exits without error
   - Child exit status reported as 0
   - Child PID reported as non-zero
   - No orphaned processes remain (run `PROCS` and confirm tForkChild is not listed)

10. **Post-test cleanup:**
    ```
    UNLOAD tForkChild
    ```
