### **Basic09 Error Handling: A Guide to Procedural Scope and Delegation**

This document outlines the authoritative rules and patterns for managing runtime errors in Basic09. It is critical to understand that Basic09's error handling model is based on **procedural scope** and does not support the concept of a single, centralized "global" handler found in modern languages.

#### **I. The Principle of Procedural Scope**

In Basic09, the scope of an `ON ERROR GOTO` statement is strictly limited to the procedure in which it is defined.[1] This is a core architectural principle:

  * **Locality:** All variables, line numbers, and labels are local to a procedure.
  * **No Global Handlers:** There is no mechanism for creating a truly global, application-wide error handler. The pattern of a shared label for an error handler across multiple, separate procedures is syntactically invalid.[1]

The correct approach is to implement error handling on a per-procedure basis, with each procedure responsible for managing its own specific errors.

#### **II. The `ON ERROR GOTO` Statement**

The `ON ERROR GOTO` statement establishes a local error handler within a procedure. The handler is a labeled section of code (e.g., a line number) that the program jumps to when a runtime error occurs.

**Example 1: Top-Level Handler**
In a main procedure like `FILEMGR` or `TRANSPILE`, a top-level handler is used to manage general runtime errors and perform cleanup operations, such as closing files, before the program terminates.[1, 1]

```basic09
PROCEDURE FILEMGR
! Main file management demonstration procedure
ON ERROR GOTO 900
...
! Main program loop
REPEAT
 ...
UNTIL done
...
! Error handler
900 errorCode := ERR
PRINT "Error"; errorCode; "occurred."
PRINT "File Manager terminated."
END
```

**Example 2: Specific, Local Handler**
For procedures that perform specific tasks with predictable errors, a local handler is used to manage those errors gracefully. The `readFile` procedure, for instance, has a handler specifically for an End of File error (`ERR=211`), which is an expected condition.[1]

```basic09
PROCEDURE readFile
...
ON ERROR GOTO 210
OPEN #path, fileName: READ
...
210! Error handler - check for EOF
    IF ERR = 211 THEN
      PRINT "End of file reached."
    ELSE
      PRINT "Error reading file: "; ERR
    ENDIF
    IF pathOpen THEN CLOSE #path \ENDIF
    END
```

#### **III. The `ERROR(ERR)` Function for Delegation**

Instead of a "global" handler, Basic09 uses a delegation pattern known as **error bubbling**. This allows a called procedure to manage its own errors and, if it cannot handle them, to propagate them back up the call stack to the calling procedure's handler.[1] The `ERROR(ERR)` function is the correct mechanism for this behavior.

The `TRANSPILE` and `LoadDefinitions` procedures provide a canonical example of this delegation.[1]

**The Delegation Process:**

1.  The `TRANSPILE` procedure calls `LoadDefinitions` and is set up with its own `ON ERROR GOTO 900` handler.[1]
2.  The `LoadDefinitions` procedure, in turn, has its own local handler at line `100` to deal with file-specific issues.[1]
3.  If a file-related error occurs within `LoadDefinitions`, such as a "File not found" (`ERR=210`), the program branches to the local handler at `100`.[1]
4.  After the local handler performs its task (e.g., printing a specific error message and closing the file), it uses `ERROR(ERR)` to pass the original error code back to the calling procedure's (`TRANSPILE`'s) error handler.[1]
5.  The `TRANSPILE` handler at line `900` then takes over, prints a generic runtime error message, and performs any necessary cleanup, such as closing all remaining open files.[1]

This chain of responsibility ensures that each procedure manages its own context-specific errors while allowing for controlled termination by the main procedure.

#### **IV. Common Basic09 Error Codes**

The following table lists common error codes from the provided documentation and their typical meaning:

| Error Code (`ERR`) | Description | Example Context |
| :--- | :--- | :--- |
| `210` | "File not found".[1] | Opening a file for reading that does not exist. |
| `211` | "End of file".[1] | This is a normal, expected error when reading to the end of a file.[1] |
| `900` | Generic Runtime Error | A custom error code used by the `TRANSPILE` procedure to flag parameter validation failures.[1] |