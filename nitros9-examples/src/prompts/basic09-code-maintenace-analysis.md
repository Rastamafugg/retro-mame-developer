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

This is the consistent structure the model will return.

> **Code Maintenance Report**
>
> ### 1\. Global Variable Analysis
>
> Variables used in the main logic or passed implicitly between procedures.
>
>   * `A$()`: [e.g., Main data array, read by 1000, modified by 2000]
>   * `F%`: [e.g., File handle, opened in main, used by 3000]
>   * `ERR$`: [e.g., Global error message string, set by 1000, 2000, 3000]
>
> ### 2\. Procedure Call Graph
>
> A map of `GOSUB` dependencies.
>
>   * **Main Logic**
>       * `GOSUB 1000` (Initialize)
>       * `GOSUB 2000` (Process Data)
>       * `GOSUB 3000` (Save Results)
>   * **Procedure 1000 (Initialize)**
>       * No calls.
>   * **Procedure 2000 (Process Data)**
>       * `GOSUB 2500` (Validation Sub-task)
>   * **Procedure 2500 (Validation Sub-task)**
>       * No calls.
>   * **Procedure 3000 (Save Results)**
>       * No calls.
>
> ### 3\. External Interaction Points
>
> All lines that perform I/O operations.
>
>   * **File I/O:**
>       * `L:50` `OPEN #F%, "DATAFILE", WRITE`
>       * `L:3010` `PUT #F%, A$()`
>       * `L:3020` `CLOSE #F%`
>   * **Hardware/Port I/O:**
>       * `L:1010` `POKE 65495, 0`
>       * `L:2020` `X = PEEK(65495)`
>
> -----
>
> ### 4\. Logic Walk-Through
>
> A step-by-step explanation of the program's execution flow.
>
>   * **Main Logic (Lines 10-90):**
>       * [Step 1: Calls 1000 to initialize arrays and hardware.]
>       * [Step 2: Opens "DATAFILE" for writing, assigns handle to global `F%`.]
>       * [Step 3: Calls 2000 to process the data.]
>       * [Step 4: Calls 3000 to save data to the open file.]
>   * **Procedure 1000 (Initialize):**
>       * **Purpose:** To clear the screen and set hardware port.
>       * **Logic:**
>         1.  [Step 1: Executes `CLEAR` command.]
>         2.  [Step 2: `POKE`s port 65495 to 0.]
>   * **Procedure 2000 (Process Data):**
>       * **Purpose:** To validate and process items in global array `A$()`.
>       * **Logic:**
>         1.  [Step 1: Loops through `A$()`.]
>         2.  [Step 2: Calls 2500 for each item.]
>   * **Procedure 2500 (Validation Sub-task):**
>       * **Purpose:** To check if an item is valid.
>       * **Logic:**
>         1.  [...logic description...]
>   * **Procedure 3000 (Save Results):**
>       * **Purpose:** To write the `A$()` array to the file `F%`.
>       * **Logic:**
>         1.  [Step 1: `PUT`s the entire `A$()` array to file `F%`.]
>         2.  [Step 2: `CLOSE`s file `F%`.]
