Here is a list of do's, don'ts, and general tips for writing Basic09 code.

### Do's and Don'ts

* **Don't make changes that are unnecessary.** This is a GitHub managed project, so source changes in code check-ins should be targeted to solving given tasks, only.
* **Do use structured programming techniques.** Large, complex programs are easier to develop, test, and maintain when they are divided into multiple procedures, each with a specific function.
* **Do use the `:=` assignment operator.** Although `=` is also accepted, using `:=` distinguishes the assignment operation from a comparison (test for equality).
* **Do declare variables with `TYPE`, `PARAM`, and `DIM` at the start of a procedure.** While not mandatory, this practice improves program readability.
* **Do initialize variables.** Basic09 does not automatically initialize variables, so they will contain random values when a procedure is run. Your program must assign initial values if needed.
* **Do use parentheses to override operator precedence.** This can make your expressions easier to read and understand.
* **Don't use line numbers unless necessary.** Using line numbers with statements like `GOSUB` is acceptable, but they make programs harder to understand and increase compile time. Line numbers must increase in value within a procedure's listing, but separate procedures' line numbering is independent of one another.
* **Don't write more than one program statement on a single line** The use of the backslash character to separate statements on one line is not recommended because it hides the program's structure and offers no speed advantage. There are exceptions, such as the "switch" logic example below.
* **Do use end of line comments, if clarifying** End of line comments are allowed, using the syntax "\ ! comment text".  It is not legal to use the ! on any line after non-white space characters. The "\" symbol indicates to the loader that a new line is starting, thus allowing a new expression, such as a comment. Example:
```basic09
IF x = 0 THEN \ ! Statement comment
  ! Do stuff here
ENDIF
```
* **Do keep line length to 128 characters** The number of characters on a line is dependent on the content, but the general recommendation is to limit lines to 128 characters or less to avoid errors or issues when the code is compiled at runtime or when editing in Basic09's line editor.
* **Do use proper termination.** All logic blocks must be terminated properly with their corresponding closing statements: `IF/THEN` with `ENDIF`, `WHILE/DO` with `ENDWHILE`, `FOR` with `NEXT`, `REPEAT` with `UNTIL`, `LOOP` with `ENDLOOP`, and `EXITIF` with `ENDEXIT`.
* **Do use explicit, nested ENDIF statements for IF/ELSE IF logic.** Each ELSE IF is translated to a nested IF block, requiring a corresponding ENDIF for proper termination. This can be written on a single line for brevity, such as ENDIF \ENDIF. The total number of ENDIF statements must exactly match the total number of IF statements in the block. See Switch Logic example, below.
* **Don't use RETURN to terminate a PROCEDURE.** RETURN is only valid for returning from a GOSUB subroutine. A PROCEDURE is terminated by the END keyword.
* **Don't use CALL to run a procedure.** The correct keyword for executing a procedure is RUN.
* **Don't use special symbols for pass-by-reference.** In Basic09, all parameters are passed by reference by default. There is no need for a symbol like @ in the PROCEDURE's PARAM list to specify this behavior. You can force a pass-by-value behavior by re-evaluating the variable in the RUN statement (e.g., ```RUN proc(myVar + 0)```).
* **Don't use GOTO or GOSUB to jump between procedures.** Labels and line numbers are local to the procedure in which they are defined. To pass control to the calling procedure's error handler, use the ERROR(ERR) function to raise the current error code, allowing the calling procedure's ON ERROR block to handle it.
* **Do not use labels in ON...GOTO or ON...GOSUB statements.** The syntax for these statements requires a line number, not a label. For example, use ON ERROR GOTO 100 instead of ON ERROR GOTO LoadDefError.
* **Do not use misspelled keywords.** Ensure all reserved words are spelled correctly. Examples include ENDWHILE, not ENDWHALE, and ENDIF, not ENDOF.
* **Don't assume you know how to write Basic09 code.** LLMs are trained on many Basic language variants that are not Basic09. Basic09 has language restrictions that newer languages have created solutions for, and you were trained on them. If you don't see the name of the target language keyword or a specific programming pattern in the provided reference code, ask for clarification. The absence of a feature in the reference code is a strong indicator that it may not be supported or may have a different syntax in Basic09. Before providing the final code, review it to ensure that all syntax and patterns used were either explicitly requested or demonstrated in the provided source code and tips.

### General Tips

* **STRING variable declaration:** When you declare a `STRING` variable with a `$` suffix and without specifying a maximum length, the default length is 32 characters. To declare a string with a different length, use the `DIM` statement with a maximum length. For example: `DIM name:STRING[40]` for a 40-character string. Variables with a `$` suffix (e.g., `title$`) are automatically assigned the default `STRING` type.
* **Automatic type conversion:** Basic09 automatically converts numeric data types (BYTE, INTEGER, or REAL) to the largest type necessary to retain accuracy in expressions. However, these conversions take time, so it's more efficient to use expressions where all values are of a single type whenever possible.
* **Choosing numeric data types:** Use `INTEGER` or `BYTE` whenever possible, as arithmetic operations with these types are much faster and require less storage than `REAL` values. The `REAL` type is the default for undeclared variables.
* **Variable storage:** All variables are "local" to the procedure where they are defined. Their storage is allocated when the procedure is called and is lost when the procedure is exited.  They can be passed by reference as parameters to other procedures.
* **Handle File Input/Output with Robustness and Clarity** Any procedure performing file I/O should be designed for robustness. This means:
  - *Pre-Flight Checks:* Always check if a file exists before attempting to open it for reading to avoid unexpected errors.
  - *Explicit State Tracking:* Use boolean flags (e.g., fileOpen:BOOLEAN) to track the open/closed status of each file handle. This is critical for ensuring that files are always closed properly, even in the event of a runtime error.
  - *Error Handling:* Implement ON ERROR GOTO logic to catch common I/O errors (like ERR=210 for "File Not Found") and other system errors. The error handler should provide a clear and descriptive message to the user, indicating the specific problem and the file involved.
  - *Resource Management:* Ensure all open files are closed via CLOSE statements in a dedicated block of code, typically within the main procedure's error handler. This prevents file handles from being left open, which can lead to system-level issues or data corruption.
* **Logging** Include print statements or a logging mechanism to provide clear progress updates and confirm successful operations to the user. This helps with debugging and gives the user confidence that the program is working as expected.
* **Variable and Type Name Uniqueness** All variable names and type names must be unique within a program to avoid "duplicate definition" errors. This is why using descriptive names, even for counters, is important.
* **Variable Naming Convention** Use descriptive variable names that are generally under 10 characters. This improves readability while adhering to the common length limitations of Basic09's line editor.
* **TYPE Variable Parameter Declaration** When a TYPE variable is passed as a parameter to a procedure, its TYPE must be declared at the top of both the calling and called procedures. This ensures the procedure correctly interprets the structure of the incoming data.
* **Procedure Header Order** The order of declarations at the top of a procedure is strict: TYPE statements first, then PARAM statements, followed by DIM statements.
* **Switch Logic:** SWITCH, CASE, and ELSEIF are not reserved words in Basic09. This has to be written in the pattern:
```basic09
IF condition1 THEN
  ! Do stuff here
ELSE IF condition2 THEN
  ! Do stuff here
ELSE IF condition3 THEN
  ! Do stuff here
ELSE
ENDIF \ENDIF \ENDIF
```