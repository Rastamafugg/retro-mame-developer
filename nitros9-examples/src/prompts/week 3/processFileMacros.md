I want to write a Basic09 procedure that accepts a source file path string, a target file path string, and a folder path string containing three named files (types.b09, constants.b09, variables.b09). If the source file path or target file path is omitted, fail on error. If the folder path is omitted, assume named files are in current data directory. Fail on error if they do not exist.


This procedure should read each line in sequence from the source and look for one of the following tokens (@@TYPE, @@CONST, @@VAR). If found, skip the following whitespace and take the string result of alphabetic (upper and lower case), plus "_" (and trailing $ characters for constants and variables) as the name of the type, constant, or variable respective to the token. Nothing but whitespace should follow the name on the source line (Print warning otherwise). Replace the token and name with the matching line in types.b09, constants.b09, or variables.b09, respective to the token. Preserve leading whitespace on the source line when writing to the output file.


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

* **Do use end of line comments, if clarifying** End of line comments are allowed, using the syntax "\! comment text"

* **Do keep line length to 128 characters** The number of characters on a line is dependent on the content, but the general recommendation is to limit lines to 128 characters or less to avoid errors when the code is decompiled at runtime.

* **Do use proper termination.** All logic blocks must be terminated properly with their corresponding closing statements: `IF/THEN` with `ENDIF`, `WHILE/DO` with `ENDWHILE`, `FOR` with `NEXT`, `REPEAT` with `UNTIL`, and `LOOP` with `ENDLOOP`.


### General Tips


* **STRING variable declaration:** When you declare a `STRING` variable without specifying a maximum length, the default length is 32 characters. To declare a string with a different length, use the `DIM` statement with a maximum length. For example: `DIM name:STRING[40]` for a 40-character string. Variables with a `$` appended to their name (e.g., `title$`) are automatically assigned the default `STRING` type.

* **Automatic type conversion:** Basic09 automatically converts numeric data types (BYTE, INTEGER, or REAL) to the largest type necessary to retain accuracy in expressions. However, these conversions take time, so it's more efficient to use expressions where all values are of a single type whenever possible.

* **Choosing numeric data types:** Use `INTEGER` whenever possible, as arithmetic operations with this type are much faster and require less storage than `REAL` values. The `REAL` type is the default for undeclared variables.

* **Variable storage:** All variables are "local" to the procedure where they are defined. Their storage is allocated when the procedure is called and is lost when the procedure is exited.

* **Input/Output:** The `GET` and `PUT` statements are much faster for file I/O than `READ` and `WRITE` because they transfer binary data in the same format used internally by Basic09, avoiding conversion time. 