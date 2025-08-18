I will attach my root-projects build.sh file.  This file is called from a project sub-folder's build.sh file with the three command line params (PROJECT, TARGET_TYPE, and IMAGE_NAME) referenced in the source code of this parent build.sh file.
Your task: modify this script to insert a preprocessing step that replaces @@TYPE and @@CONST references in src/basic/*.b09 source files (excluding types.b09 and constants.b09) with definitions from:
- src/basic/types.b09
- src/basic/constants.b09

Follow these requirements exactly:

- Maintain my script’s variable naming conventions exactly as in the attached build.sh.
- No case insensitivity in any matching or file search logic.
- Perform the TYPE/constant replacement step before the floppy creation logic, then replace SOURCE_PATH references with BUILD_PATH for the remainder of the build process.
- I will copy & paste the generated code into my existing build.sh, so your output must not create syntax errors when inserted directly.
- For missing TYPE or constant references:
  - Add a REM line to the generated Basic09 file.
  - Also echo the error in the build log.
- If types.b09 or constants.b09 are missing, output an error and exit.
- Assume UTF-8 encoding for all files.
- Multiline TYPE definitions are not supported.
- Definitions can appear in multiple locations within a source file.
- At the end of the build, output a log summary showing:
  - Number of files processed
  - Number of replacements made
  - Number of missing definitions
- Handle possible CRLF (\r\n) line endings in .b09 files — strip them before processing to avoid replacement issues.
- Add a verbose mode toggle (VERBOSE=true|false) to allow detailed debugging output or quiet operation.
- Ensure the script works in a standard Bash environment without requiring special shells.
- Keep TYPE and CONST lookups exact — no partial matches, no regex looseness.
- Output replacement lines exactly as in the source definition files.
- @@TYPE MyType → TYPE MyType = ... (single-line, from types.b09).
- @@CONST MyConst → DIM MyConst = ... (single-line, from constants.b09).
- Replacement code should never alter whitespace, comments, or expressions in unaffected lines.
- Preserve indentation of the @@TYPE or @@CONST marker line in the inserted replacement.
- Add set -e and set -u at the top to catch errors early