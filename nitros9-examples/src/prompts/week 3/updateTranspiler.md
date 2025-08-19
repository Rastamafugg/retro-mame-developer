I am writing a Basic09 procedure that accepts a source file path string, a target file path string, and a folder path string containing three named files (types.b09, constants.b09, variables.b09). If the source file path or target file path is omitted, fail on error. If the folder path is omitted, assume named files are in current data directory. Fail on error if these files or the folder do not exist.

This procedure should read each line in sequence from the source and look for one of the following tokens (@@TYPE, @@CONST, @@VAR). If found, skip the following whitespace and take the string result of alphabetic (upper and lower case), plus "_" (and trailing $ characters for constants and variables) as the name of the type, constant, or variable respective to the token. Nothing but whitespace should follow the name on the source line (Print warning otherwise). Replace the token and name with the matching line in types.b09, constants.b09, or variables.b09, respective to the token. Preserve leading whitespace on the source line when writing to the output file.

I am attaching the source for the latest version of this code.  These are your tasks:
- We need the code to check for an existing file at the target file path location before creating it. If found, the code should open the file with write access and replace the contents instead of creating the file.
- Look for code redundency and suggest new procedures and replacement logic for the extracted code. Reading from the three types, constants, and variables files logic, and the use of these data structures throught the program are key targets.
- Don't make changes that are unecessary, as this is a GitHub managed project, so source changes in code check-ins should be targeted to solving given tasks.
- Identify other targets for streamlining, suggesting improvements for each target, individually.

Examples:

Source file:
```@@TYPE MyType```
types.b09:
```TYPE MyType = attr1:STRING[10]; attr2(3):BYTE```
Output file:
```TYPE MyType = attr1:STRING[10]; attr2(3):BYTE```

Source file:
```@@CONST _MyConst```
constants.b09:
```DIM _MyConst \_MyConst := 1```
Output file:
```DIM _MyConst \_MyConst := 1```

Source file:
```@@VAR MyVar```
variables.b09:
```DIM myVar:STRING[20]```
Output file:
```DIM myVar:STRING[20]```

Here is a list of do's, don'ts, and general tips for writing Basic09 code.

### Do's and Don'ts

* **Do use structured programming techniques.** Large, complex programs are easier to develop, test, and maintain when they are divided into multiple procedures, each with a specific function.

* **Do use the `:=` assignment operator.** Although `=` is also accepted, using `:=` distinguishes the assignment operation from a comparison (test for equality).

* **Do declare variables with `DIM` at the start of a procedure.** While not mandatory, this practice improves program readability.

* **Do initialize variables.** Basic09 does not automatically initialize variables, so they will contain random values when a procedure is run. Your program must assign initial values if needed.

* **Do use parentheses to override operator precedence.** This can make your expressions easier to read and understand.

* **Don't use line numbers unless necessary.** Using line numbers with statements like `GOSUB` is acceptable, but they make programs harder to understand, use more memory, and increase compile time.

* **Don't write more than one program statement on a single line** The use of the backslash character to separate statements on one line is not recommended because it hides the program's structure and offers no speed advantage.

* **Don't use strict comparisons (`=` or `<>`) on `REAL` quantities.** Floating-point arithmetic is inherently inexact, and cumulative errors can occur, so the exact desired value may not happen during execution.

* **Do use end of line comments, if clarifying** End of line comments are allowed, using the syntax "\! comment text".  It is not legal to use the ! on any line after non-white space characters. The "\" symbol indicates to the loader that a new line is starting, thus allowing a new expression, such as a comment. Example:

```basic09
IF x = 0 THEN \ ! IF statement comment
! Do something
ENDIF
```

* **Do keep line length to 128 characters** The number of characters on a line is dependent on the content, but the general recommendation is to limit lines to 128 characters or less to avoid errors when the code is decompiled at runtime.

* **Do use proper termination.** All logic blocks must be terminated properly with their corresponding closing statements: `IF/THEN` with `ENDIF`, `WHILE/DO` with `ENDWHILE`, `FOR` with `NEXT`, `REPEAT` with `UNTIL`, `LOOP` with `ENDLOOP`, and `EXITIF` with `ENDEXIT`.

* **Don't assume you know how to write Basic09 code**  LLMs are trained on a lot of Basic language variants that are not Basic09.  Basic09 has language restrictions that newer languages have created solutions for, and you were trained on them.  If you don't see the name of the target language keyword in the provided reference code, ask for clarification.  

### General Tips

* **STRING variable declaration:** When you declare a `STRING` variable with a `$` suffix and without specifying a maximum length, the default length is 32 characters. To declare a string with a different length, use the `DIM` statement with a maximum length. For example: `DIM name:STRING[40]` for a 40-character string. Variables with a `$` suffix (e.g., `title$`) are automatically assigned the default `STRING` type.

* **Automatic type conversion:** Basic09 automatically converts numeric data types (BYTE, INTEGER, or REAL) to the largest type necessary to retain accuracy in expressions. However, these conversions take time, so it's more efficient to use expressions where all values are of a single type whenever possible.

* **Choosing numeric data types:** Use `INTEGER` whenever possible, as arithmetic operations with this type are much faster and require less storage than `REAL` values. The `REAL` type is the default for undeclared variables.

* **Variable storage:** All variables are "local" to the procedure where they are defined. Their storage is allocated when the procedure is called and is lost when the procedure is exited.

* **File Input/Output:** Files for this project include read access to the source file and types, constants, and variables, plus write access to a target file.  There should be a check for the existence of a file before creating it. In either case, the contents of the file will be overwritten. 

* **Input/Output:** The `GET` and `PUT` statements are much faster for random access file I/O than `READ` and `WRITE` because they transfer binary data in the same format used internally by Basic09, avoiding conversion time. 

* **Switch Logic:** SWITCH and CASE are not reserved words in Basic09. This has to be written in the pattern:

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