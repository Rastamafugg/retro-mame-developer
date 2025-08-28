# Transpiler

I am writing a transpiler process that currently accepts a source file path string, a target file path string, and a folder path string containing three named files (types.b09, constants.b09, variables.b09). I have two version of this process, one written in awk that is run via a bash script, and one written in Basic09 that is run on NitrOS9 EOU on the Tandy Coco 3.

This procedure starts by parsing these three named files and collects the types, constants, and variables into an in-memory structure of matching tokens, token types and replacement lines.  It then reads each line of the source file in sequence and looks for one of the following tokens (@@TYPE, @@CONST, @@VAR). If found, it skips the following white space and takes the string result of alphabetic (upper and lower case), plus "_" (and trailing $ characters for constants and variables) as the name of the type, constant, or variable respective to the token. Nothing but white space should follow the name on the source line (A printed warning happens, otherwise). It then replaces the token and name with the matching line from the types.b09, constants.b09, or variables.b09, respective to the token type. Leading white space is preserved on the source line when writing to the output file.

I want to modify this transpiler that converts my custom enhanced version of Basic09 to legal Basic09 code.  The features this transpiler will include are listed below.  I am attaching the root projects folder's build.sh file.  This file is called from a project sub-folder's build.sh file with the three command line params (PROJECT, TARGET_TYPE, and IMAGE_NAME) referenced in the source code of this parent build.sh file.

Please write the awk logic code snippet to work with these requirements.  This code should first parse a global.b09 file located in the same folder as the source files to be transpiled and store all types, constants, and variables in memory, sotring the token name, type, and replacement value for each statements found in the file.

Only write the new code changes as a single code snippet.  I will perform the update to the original source. Use the logic from the provided source, replacing the logic reading from types.b09, constants.b09, and variables.b09 with the processing logic for a global.b09 file in the same folder, which contains all types, constants, and variables declarations.  Then, parse all files with the pattern *.b09, using the existing code as a guide and apply the changes described below.

## Global Source File

A file called global.b09 containing types, constants, and variables available to all modules in a given project. The format for types, constants, and variables matches the current line values for types.b09, constants.b09, variables.b09. For example:

```
TYPE Reading=value:REAL,timestamp:STRING[20]
CONST MaxReadings:INTEGER := 100
VAR sessionCount:INTEGER
```

## Module source files

A module source file can contain module-level types, constants, and variables declared at the top of the module declaration, along with any number of procedures, some or all of which may use global and/or module types, constants, and variables. For example:

```
MODULE Logger
  TYPE Session=id:INTEGER,readings[10]:Reading
  CONST DefaultSessionSize:INTEGER := 10
  VAR logCount:INTEGER

PROCEDURE AddReading
  @@TYPE Reading
  @@CONST DefaultSessionSize
  @@VAR logCount

  DIM newReading:Reading
  DIM currentSession:Session

  ! Use constant for array size
  DIM tempArray[DefaultSessionSize]:REAL

  PRINT "Enter temperature value: ";
  INPUT newReading.value
  PRINT "Enter timestamp: ";
  INPUT newReading.timestamp

  logCount := logCount + 1
  PRINT "Reading added. Log count = "; logCount
END

PROCEDURE ComputeAverage
  @@CONST MaxReadings
  @@VAR sessionCount

  DIM counter,total:REAL
  DIM avg:REAL

  total := 0
  FOR counter := 1 TO MaxReadings DO
    total := total + counter
  END FOR

  IF MaxReadings > 0 THEN
    avg := total / MaxReadings
    PRINT "Average: "; avg
  ELSE
    PRINT "No readings available"
  END IF

  sessionCount := sessionCount + 1
  PRINT "Sessions processed = "; sessionCount
END

ENDMODULE
```

## Language Additions

The following language additions will be supported by the transpiler:

### Global and Module Types, Constants, Variables

Types, constants, and variables can be defined in the global.b09 file, at the top of the MODULE definition (before any PROCEDURE declarations), or within a given PROCEDURE block (Before any PARAM or DIM variable declarations).

If there is a naming conflict for a given type, constant, or variable, resolve in this order: procedure, module, global. Within any given procedure, the same name cannot be used for multiple variables or type attributes.

*NOTE:* Basic09 only understands TYPE, PARAM, and DIM statements.  CONST and VAR would be transplied to DIM statements, and CONST declarations would need a new line where the dimmed variable is assigned the literal value from the CONST statement. For example, if the global.b09 file contains:

```
TYPE Reading=value:REAL,timestamp:STRING[20]
CONST MaxReadings:INTEGER := 100
VAR sessionCount:INTEGER
```

A procedure that looks like this:

```
PROCEDURE Test
  @@TYPE Reading
  @@CONST MaxReadings
  @@VAR sessionCount
END
```

is transpiled to this

```
PROCEDURE Test
  TYPE Reading=value:REAL,timestamp:STRING[20]
  DIM MaxReadings:INTEGER
  MaxReadings := 100
  DIM sessionCount:INTEGER
END
```

In addition to this, any references to constants within other DIM statements needs to be replaced with the literal value of the constants during the transpile.  For example:

```
DIM readings: INTEGER[MaxReadings]
```

becomes

```
DIM readings: INTEGER[100]
``` 

### SELECT CASE Statements

`SWITCH`, `CASE`, and `ELSEIF` are not reserved words in Basic09. Each `ELSE IF` is translated to a nested `IF` block, requiring a corresponding `ENDIF` for proper termination. This can be written on a single line for brevity, such as `ENDIF \ENDIF`. The total number of `ENDIF` statements must exactly match the total number of `IF` statements in the block. This is an example of how the transpiler should handle this SELECT CASE logic:

```
SELECT mode
  CASE 1
    PRINT "One"
  CASE 2, 3
    PRINT "Two or Three"
  CASE DEFAULT
    PRINT "Other"
ENDSELECT
```

becomes

```
IF mode=1 THEN
  PRINT "One"
ELSE IF mode=2 OR mode=3 THEN
  PRINT "Two or Three"
ELSE
  PRINT "Other"
ENDIF /ENDIF
```

### ENUM statements

ENUM statements are also not supported by Basic09.  The transpiler should convert the following code from:

```
ENUM Color = [Red=1, Green=2, Blue=3]
DIM selectedColor

! Application logic here

IF selectedColor = Color.Red THEN
  ! Do something
ENDIF
```

to

```
DIM Red:INTEGER
Red := 1
DIM Green:INTEGER
Green := 2
DIM Blue:INTEGER
Blue := 3
DIM selectedColor

! Application logic

IF selectedColor = Red THEN
  ! Do something
ENDIF
```

### GOTO and GOSUB Labels

Labels as destinations for GOTO and GOSUB statements are not supported by Basic09.  The transpiler should convert this:

```
ON ERROR GOTO ErrorHandler
ON value GOSUB GoodValue, BadValue

! Application logic
END

GoodValue:
  ! Do something
  RETURN

BadValue:
  ! Do something
  RETURN

ErrorHandler:
  ! Do something
  END
```
to this

```
ON ERROR GOTO 300
ON value GOSUB 100, 200

! Application logic
END

100: \ ! GoodValue
  ! Do something
  RETURN

200: \ ! BadValue
  ! Do something
  RETURN

300: \ ! ErrorHandler
  ! Do something
  END
```

# Full Transpile Example

## Input Files

PROJECT/src/basic/global.b09:

```
TYPE Reading=value:REAL,timestamp:STRING[20]
CONST MaxReadings:INTEGER := 100
VAR sessionCount:INTEGER
```

PROJECT/src/basic/sourceModule.b09

```
MODULE Logger
  TYPE Session=id:INTEGER,readings[10]:Reading
  CONST DefaultSessionSize:INTEGER := 10
  VAR logCount:INTEGER

PROCEDURE AddReading
  @@TYPE Reading
  @@CONST DefaultSessionSize
  @@VAR logCount

  DIM newReading:Reading
  DIM currentSession:Session

  ! Use constant for array size
  DIM tempArray[DefaultSessionSize]:REAL

  DIM value:BYTE

  ENUM Color = [Red=1, Green=2, Blue=3]
  DIM selectedColor:BYTE

  ON ERROR GOTO ErrorHandler

  IF DefaultSessionSize <= 10 THEN
    PRINT "DefaultSessionSize less than or equal to 10";
  ELSE
    PRINT "DefaultSessionSize graeter than to 10";
  ENDIF

  PRINT "Enter temperature value: ";
  INPUT newReading.value
  PRINT "Enter timestamp: ";
  INPUT newReading.timestamp

  logCount := logCount + 1
  PRINT "Reading added. Log count = "; logCount

  PRINT "Enter branch number (1-2): ";
  INPUT value

  ON value GOSUB GoodValue, BadValue

  PRINT "Enter color (1-3): ";
  INPUT selectedColor

  SELECT selectedColor
    CASE Color.Red
      PRINT "Red Chosen"
    CASE Color.Green, Color.Blue
      PRINT "Green or Blue Chosen"
    CASE DEFAULT
      PRINT "Incorrect Color Selection"
  ENDSELECT

  END

  GoodValue:
    PRINT "Good Value Chosen"
    RETURN

  BadValue:
    PRINT "Bad Value Chosen"
    RETURN

  ErrorHandler:
    ! Do something
    END
END

PROCEDURE ComputeAverage
  @@CONST MaxReadings
  @@VAR sessionCount

  DIM counter,total:REAL
  DIM avg:REAL

  total := 0
  FOR counter := 1 TO MaxReadings DO
    total := total + counter
  END FOR

  IF MaxReadings > 0 THEN
    avg := total / MaxReadings
    PRINT "Average: "; avg
  ELSE
    PRINT "No readings available"
  END IF

  sessionCount := sessionCount + 1
  PRINT "Sessions processed = "; sessionCount
END

ENDMODULE
```

## Output File

PROJECT/build/basic/sourceModule.b09

```
PROCEDURE AddReading
  TYPE Reading=value:REAL,timestamp:STRING[20]
  DIM DefaultSessionSize:INTEGER
  DefaultSessionSize := 10
  DIM logCount:INTEGER

  DIM newReading:Reading
  DIM currentSession:Session

  ! Use constant for array size
  DIM tempArray[10]:REAL

  DIM value:BYTE

  DIM Red:INTEGER
  Red := 1
  DIM Green:INTEGER
  Green := 2
  DIM Blue:INTEGER
  Blue := 3
  DIM selectedColor:BYTE

  ON ERROR GOTO 300 \ ! ErrorHandler

  IF DefaultSessionSize <= 10 THEN
    PRINT "DefaultSessionSize less than or equal to 10";
  ELSE
    PRINT "DefaultSessionSize greater than to 10";
  ENDIF

  PRINT "Enter temperature value: ";
  INPUT newReading.value
  PRINT "Enter timestamp: ";
  INPUT newReading.timestamp

  logCount := logCount + 1
  PRINT "Reading added. Log count = "; logCount

  PRINT "Enter branch number (1-2): ";
  INPUT value

  ON value GOSUB 100, 200 \ ! GoodValue, BadValue

  PRINT "Enter color (1-3): ";
  INPUT selectedColor

  IF selectedColor=Red THEN
    PRINT "Red Chosen"
  ELSE IF selectedColor=Green OR selectedColor=Blue THEN
    PRINT "Green or Blue Chosen"
  ELSE
    PRINT "Incorrect Color Selection"
  ENDIF / ENDIF

  END

  100: \ ! GoodValue
    PRINT "Good Value Chosen"
    RETURN

  200: \ ! BadValue
    PRINT "Bad Value Chosen"
    RETURN

  300: \ ! ErrorHandler
    ! Do something
    END
END

PROCEDURE ComputeAverage
  DIM MaxReadings:INTEGER
  MaxReadings := 100
  DIM sessionCount:INTEGER

  DIM counter,total:REAL
  DIM avg:REAL

  total := 0
  FOR counter := 1 TO MaxReadings DO
    total := total + counter
  END FOR

  IF MaxReadings > 0 THEN
    avg := total / MaxReadings
    PRINT "Average: "; avg
  ELSE
    PRINT "No readings available"
  END IF

  sessionCount := sessionCount + 1
  PRINT "Sessions processed = "; sessionCount
END
```
