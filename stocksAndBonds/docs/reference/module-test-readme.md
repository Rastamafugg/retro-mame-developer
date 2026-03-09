# Module Management Syscall Test Procedures

This file contains Basic09 procedures for testing NitrOS-9 system calls related to module management in packed Basic09 programs.

## Files Created/Modified

- `moduleTest.b09` - Contains the test procedures
- `global.b09` - Updated with Register type definition
- `modular-development.md` - Updated to confirm the NOT CONFIRMED item

## Procedures

### checkModule(moduleName: STRING)
Checks if a specific module is loaded in memory.
- **Parameters**: moduleName - Name of the module to check
- **Returns**: BOOLEAN - TRUE if loaded, FALSE if not
- **Uses**: F$Link syscall to attempt linking the module

### loadModule(moduleName: STRING)
Loads a module into memory.
- **Parameters**: moduleName - Name of the module to load
- **Returns**: BOOLEAN - TRUE if successful, FALSE if failed
- **Uses**: First tries F$Link (if already loaded), then F$Load (from disk)

### unloadModule(moduleName: STRING, headerAddr: INTEGER)
Unloads a module from memory.
- **Parameters**:
  - moduleName - Name of the module to unload
  - headerAddr - Module header address (0 to use name-based unloading)
- **Returns**: BOOLEAN - TRUE if successful, FALSE if failed
- **Uses**: F$UnLink (by header) or F$UnLoad (by name)

### getMemoryUsage()
Displays current memory usage of the process.
- **Uses**: F$Mem syscall to get current memory size and upper bound

### TSTMODULE()
Comprehensive test procedure that runs all module management tests.
- Tests loading/unloading of single and multi-procedure modules
- Verifies the behavior of multi-procedure module unloading
- Confirms the "NOT CONFIRMED" item from modular-development.md
- Provides detailed test results and success/failure counts

## Usage

1. Load the procedures in Basic09:
   ```
   LOAD moduleTest.b09
   ```

2. Run the comprehensive test:
   ```
   RUN TSTMODULE
   ```

3. Or run individual procedures:
   ```
   RUN checkModule("singleProc")
   RUN loadModule("multiProc1")
   RUN getMemoryUsage()
   ```

## Test Coverage

The TSTMODULE procedure tests:
- Initial memory state
- Checking unloaded modules
- Loading single procedure modules
- Executing loaded procedures
- Unloading single procedure modules
- Loading multi-procedure modules
- Executing multi-procedure modules
- **CONFIRMED**: Multi-procedure module unloading behavior
- Loading independent procedure modules
- Executing independent procedures
- Unloading independent procedures
- Final memory state verification

## Prerequisites

- The test modules referenced in modular-development.md must be packed and available:
  - `singleProc` - Single procedure module
  - `multiProc1` - Multi-procedure module (contains multiProc1 and multiProc2)
  - `indepProc1` - Independent procedures module (contains indepProc1, indepProc2, indepProc3)

- Modules must have execute permissions set (use `attr` command)

## Expected Results

- All tests should pass if the system calls work correctly
- The "NOT CONFIRMED" item should be confirmed: procedures in multi-procedure modules need explicit unloading
- Memory usage should return to reasonable levels after cleanup