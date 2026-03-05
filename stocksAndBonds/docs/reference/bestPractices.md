Here is a list of rules and general tips for writing Basic09 code.

---

## Reserved Words

The following identifiers are reserved by Basic09 and **must not** be used as variable names, TYPE attribute names, array names, or procedure names.

### Statements & Control Flow

```
ABS       ACS       ADDR      AND       ASC       ASN
ATN       BASE      BYE       CHAIN     CHD       CHR$
CHX       CLOSE     COS       CREATE    DATA      DATE$
DEG       DELETE    DIM       DO        ELSE      END
ENDEXIT   ENDIF     ENDLOOP   ENDWHILE  EOF       ERR
ERROR     EXITIF    EXP       FALSE     FIX       FLOAT
FOR       GET       GOSUB     GOTO      IF        INKEY
INPUT     INT       KILL      LAND      LEFT$     LEN
LET       LNOT      LOG       LOG10     LOOP      LOR
LXOR      MID$      MOD       NEXT      NOT       ON
OPEN      OR        PARAM     PAUSE     PEEK      PI
POKE      POS       PRINT     PROCEDURE PUT       RAD
READ      REM       REPEAT    RESTORE   RETURN    RIGHT$
RND       RUN       SEEK      SGN       SHELL     SIZE
SIN       SQ        SQR       SQRT      STEP      STOP
STR$      STR       SUBSTR    SYSCALL   TAB       TAN
THEN      TO        TRIM$     TROFF     TRON      TRUE
TYPE      UNTIL     UPPER$    USING     VAL       WHILE
WRITE     XOR
```

### Data Types

```
BOOLEAN   BYTE      INTEGER   REAL      STRING
```

### File Access Parameters

```
DIR       EXEC      READ      UPDATE    WRITE
```

> **Note:** `READ`, `WRITE`, and `DIR` appear in both the Statements and File Access lists. They are reserved in all contexts.

---

## Rules

### Code Structure

* **Use structured programming techniques.** Large, complex programs are easier to develop, test, and maintain when they are divided into multiple procedures, each with a specific function.

* **Limit source changes to the task at hand.** This is a GitHub-managed project; check-ins should be targeted to solving given tasks only. Leave unrelated code unchanged.

* **Use the `:=` operator for assignment, `=` for comparison.** Although `=` is also accepted for assignment, using `:=` distinguishes assignment from comparison (test for equality).

* **Declare variables with `TYPE`, `PARAM`, and `DIM` at the start of a procedure.** This is not mandatory, but improves readability. The declaration order is strict: `TYPE` first, then `PARAM`, then `DIM`.

* **`TYPE` declarations must occupy a single line** You cannot split a `TYPE` declaration across multiple lines.

* **Initialize variables.** Basic09 does not automatically initialize variables - they contain random values when a procedure starts. Assign initial values explicitly.

* **Use parentheses to override operator precedence.** This improves expression readability.

### Line Numbers and Formatting

* **Reserve line numbers for `GOSUB`, `ON ERROR`, and `ON...GOTO/GOSUB` targets.** Line numbers make programs harder to read and increase compile time. Use them only where required by syntax. Line numbers must increase in value within a procedure. Separate procedures' line numbering is independent.

  Start line numbers at 100, increment by 100. Reserve line number `900` for the end-of-procedure error handler, unless already taken.

  ```basic09
  PROCEDURE ProcExample
    PARAM branchValue:BYTE
    ON ERROR GOTO 900
    ON branchValue GOSUB 100, 200
    END
  
  100 ! Branch A
    RETURN
  
  200 ! Branch B
    RETURN
  
  900 ! Error handler
    END
  ```
* **When to use ON...GOSUB** `ON...GOSUB` earns its compile cost and readability tradeoff when the selector is a contiguous `1..N` integer with N >= ~5, particularly inside loops where repeated evaluation matters. Below that threshold, `IF/ELSE IF` is preferable in this codebase.

* **Write one program statement per line.** The backslash statement concatenation syntax (`\`) hides program structure and offers no speed advantage. Exceptions: inline comments (`\ ! comment`) and multi-`ENDIF` switch closures (`ENDIF \ENDIF \ENDIF`).

* **Use end-of-line comments to clarify, not narrate.** End-of-line comments use the syntax `\ ! comment text`. The `!` alone is only legal at the start of a line or after a `\`.

  ```basic09
  IF testVal = 0 THEN \ ! Guard clause
    ! Handle zero case
  ENDIF
  ```

* **Keep lines to 79 characters or fewer.** The maximum is 256 characters, but Basic09's line editor has UI issues beyond 79.

* **Place all comments and logic inside `PROCEDURE` blocks.** Procedure header comments must immediately follow `PROCEDURE name`, before any declarations.

  ```basic09
  PROCEDURE demo
  (* ================================================== *)
  (* PROCEDURE: demo                                    *)
  (* ================================================== *)
  TYPE ...
  PARAM ...
  DIM ...
  END
  ```

### Logic Blocks and Termination

* **Terminate all logic blocks with their correct closing keyword.**

  | Opening | Closing |
  |---|---|
  | `IF`/`THEN` | `ENDIF` |
  | `WHILE`/`DO` | `ENDWHILE` |
  | `FOR` | `NEXT` |
  | `REPEAT` | `UNTIL` |
  | `LOOP` | `ENDLOOP` |
  | `EXITIF` | `ENDEXIT` |

* **Use explicit, nested `ENDIF` statements for `IF`/`ELSE IF` logic.** Each `ELSE IF` is a nested `IF` block. The total count of `ENDIF` statements must exactly match the total count of `IF` statements in the block.

* **Write switch/case logic using nested `IF`/`ELSE IF`.** `SWITCH`, `CASE`, and `ELSEIF` are not reserved words in Basic09.

  ```basic09
  IF condition1 THEN
    ! Branch 1
  ELSE IF condition2 THEN
    ! Branch 2
  ELSE IF condition3 THEN
    ! Branch 3
  ELSE \ ! Default
    ! Default branch
  ENDIF \ENDIF \ENDIF
  ```

### Procedure Calls and Parameters

* **Use `RUN` to execute a procedure.** `CALL` is not a valid keyword.

* **Rely on pass-by-reference as the default parameter behavior.** All `PARAM` variables are passed by reference; no special symbol (e.g., `@`) is required. To force pass-by-value, re-evaluate the variable at the call site: `RUN proc(myVar + 0)`.

* **Use line numbers (not labels) in `ON...GOTO` and `ON...GOSUB` statements.** Example: `ON ERROR GOTO 100`, not `ON ERROR GOTO MyLabel`.

* **Use `END` to terminate a `PROCEDURE`.** `RETURN` is valid only for returning from a `GOSUB` subroutine. It does not return data to the caller. Use passed-by-reference parameters to return values.

* **Declare a `TYPE` at the top of every procedure that receives or uses it.** When a `TYPE` variable is passed as a parameter, its `TYPE` definition must appear at the top of both the calling and called procedures.

### Scope

* **Treat all variables, line numbers, and error handlers as strictly local to their procedure.** There is no global scope in Basic09. A variable defined in one procedure has no meaning in another unless explicitly passed via `RUN`/`PARAM`.

### Error Handling

* **Include an `ON ERROR GOTO` handler in every procedure.** Global error handling is not supported. Each procedure must manage its own errors.

* **Use `ERROR(ERR)` to delegate unhandled errors to the calling procedure.** This bubbles the error up the call stack to the caller's `ON ERROR` handler.

* **Use `MODULE`/`ENDMODULE` syntax only in other languages.** These are not reserved words in Basic09 and must not appear in `.b09` source files.

### Naming

* **Use descriptive variable and type names under 10 characters.** This improves readability within Basic09's line editor constraints.

* **Ensure all variable and type names are unique within a program.** Duplicate names cause "duplicate definition" errors.

* **Never use a reserved word (see table above) as a variable name, TYPE attribute name, array name, or procedure name.**

### Variables and Data Types

* **Declare `STRING` variables with an explicit length when the default is insufficient.** Without a length specifier, `STRING` defaults to 32 characters. Use `DIM name:STRING[40]` to declare a longer string.

* **Account for the 32K variable memory limit.** Basic09 has only 32 KB available for variable storage. Size arrays with this constraint in mind.

* **`FOR` incrementer variable must be of type INTEGER** BYTE incrementer variables will cause a syntax error.

  ```basic09
  DIM i: INTEGER
  FOR i := 1 TO 9
    ! Logic here
  NEXT i
  ```

### File I/O

* **Isolate file I/O in dedicated procedures.** This enables I/O-specific error handling and allows callers to fail gracefully on I/O errors.

### Logging

* **Include progress logging for visibility.** Print statements confirming key operations help with debugging and give confidence that execution is proceeding correctly.

  ```basic09
  IF logVerbose THEN
    PRINT "> Loading Variable Definitions"
  ENDIF
  ```

---

## General Tips

* **ON ERROR GOTO and ON...GOTO/GOSUB are procedure-scoped.** A shared handler label across multiple procedures is syntactically invalid.

  ```basic09
  PROCEDURE ProcA
    ON ERROR GOTO 900
    ! ...
    END
  900 ! ProcA error handler
    END
  
  PROCEDURE ProcB
    ON ERROR GOTO 900
    ! ...
    END
  900 ! ProcB error handler - separate from ProcA's
    END
  ```

* **`STRING` variables with a `$` suffix are automatically typed.** Variables like `title$` are implicitly `STRING[32]`. Explicitly DIM them if a different length is needed.
