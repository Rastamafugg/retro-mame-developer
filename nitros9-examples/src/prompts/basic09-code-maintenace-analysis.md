```
TASK: Basic09 Code Maintenance Analysis
SYSTEM_CONSTRAINT: Adhere to the 'Basic09 Language Constraint' (SYSTEM PROMPT) previously defined. All analysis and validation must be based *only* on the provided documentation.

INPUT_CODE:
---
<<Paste complete Basic09 source code block here>>
---

DOCUMENTATION (COMPLETE):
---
<<Paste ALL Basic09 documentation and valid code templates here>>
---

Generate a "Code Maintenance Report" based on the `INPUT_CODE` and `DOCUMENTATION`. The report must strictly follow the "Structured Maintenance Output Format."
```

-----

### Structured Maintenance Output Format

**Code Maintenance Report**

### 1\. Procedure & Data Analysis

Analysis of all procedures, their local data, and shared data structures.

**User-Defined Data (`TYPE`)**

* `TYPE [name]`: [Description of the data structure. Note: This `TYPE` must be declared in any procedure that passes or receives it.]

**Procedure Interface & Storage**

* **`PROCEDURE [Name1]`**
    * **Parameters (`PARAM`):** Variables passed by reference.
        * `[var1]`: [e.g., Input value, type INTEGER]
        * `[var2]`: [e.g., Result container, type STRING[80]]
    * **Local Variables (`DIM`):**
        * `[var3]`: [e.g., Loop counter, type INTEGER]
        * `[var4]`: [e.g., File path number, type BYTE]
* **`PROCEDURE [Name2]`**
    * **Parameters (`PARAM`):**
        * ...
    * **Local Variables (`DIM`):**
        * ...

### 2\. Call Graph (RUN & GOSUB)

A map of inter-procedure (`RUN`) and intra-procedure (`GOSUB`) dependencies.

* **`PROCEDURE [Main]`**
    * `RUN [Name1]([param1], [param2])`: [Purpose of call]
    * `RUN [Name2]([param3])`: [Purpose of call]
    * `GOSUB [line#]`: [Purpose of internal subroutine]
* **`PROCEDURE [Name1]`**
    * `RUN [Name3](...)`: [Purpose of call]
    * No `GOSUB` calls.
* **`PROCEDURE [Name2]`**
    * No `RUN` calls.
    * `GOSUB [line#]`: [Purpose]
    * `GOSUB [line#]`: [Purpose]

### 3\. External Interaction Points

All statements that interact with the operating system, files, or hardware.

* **File I/O:**
    * `PROCEDURE [Name] (Line [Num])`: `OPEN #[path], [name$]`
    * `PROCEDURE [Name]`: `CREATE #[path], [name$]`
    * `PROCEDURE [Name]`: `GET #[path], [variable]`
    * `PROCEDURE [Name] (Line [Num])`: `PUT #[path], [variable]`
    * `PROCEDURE [Name]`: `CLOSE #[path]`
* **System/Shell I/O:**
    * `PROCEDURE [Name]`: `SHELL [command$]`
    * `PROCEDURE [Name]`: `CHAIN [command$]`
* **Memory/Hardware I/O:**
    * `PROCEDURE [Name] (Line [Num])`: `POKE [addr], [val]`
    * `PROCEDURE [Name]`: `[var] := PEEK([addr])`

### 4\. Logic Walk-Through

A step-by-step explanation of each procedure's execution flow.

* **`PROCEDURE [Main]`**
    * **Purpose:** [e.g., Main program loop, coordinates other procedures.]
    * **Parameters (`PARAM`):** [None, or description if called by another procedure.]
    * **Main Logic:**
        1.  [Step 1: Initializes local variables (e.g., `DIM flag:BOOLEAN`).]
        2.  [Step 2: Sets the procedure-local error handler `ON ERROR GOTO 900`.]
        3.  [Step 3: Calls `RUN [Name1]` to load data into local array `[local_array]`.]
        4.  [Step 4: Loops through `[local_array]` and calls `GOSUB 100` for each element.]
        5.  [Step 5: Calls `RUN [Name2]` to save results.]
    * **Subroutines (GOSUB):**
        * `Line 100:` [e.g., Validation logic for an array element.]
    * **Error Handling:**
        * `Line 900:` [e.g., Prints error from `ERR`, closes files, and `END`s procedure.]

* **`PROCEDURE [Name1]`**
    * **Purpose:** [e.g., To open and read data from "DATA.FIL".]
    * **Parameters (`PARAM`):**
        * `[result_array]`: [e.g., Array passed by reference to be filled with data.]
    * **Main Logic:**
        1.  [Step 1: Sets local error handler `ON ERROR GOTO 900`.]
        2.  [Step 2: `OPEN`s file "DATA.FIL" on path `#[path_var]`.]
        3.  [Step 3: `LOOP`s and `READ`s data into `[result_array]` until `EOF()` is `TRUE`.]
    * **Error Handling:**
        * `Line 900:` [e.g., Checks `ERR` for File Not Found, `CLOSE`s path, and passes error to caller using `ERROR(ERR)`.]