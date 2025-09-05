# Transpiler

I want you to write a transpiler process, written in Basic09, that accepts a source file path string, a target file path string, and a global file path string for a file, called global.b09, containing types, constants, and variables available to all modules in a given project.

This process starts by parsing the global file and collects the types, constants, and variables into an in-memory structure of matching tokens, token types and replacement lines.  It then reads each line of the source file in sequence and performs the transpiling actions described at the end of this prompt.

I am attaching the best practices for writing Basic09 code in the best-practices.txt document.  Please follow those instructions strictly as you convert the logic. You can create multiple PROCEDURE blocks in a single module file, with a "TRANSPILE" procedure being the point of entry that accepts the 3 input variables. 

I am including basicReference.txt, which is my reference example template for writing proper Basic09 code. I am also attaching transpile.txt, which includes a working Basic09 transpile module from a previous interation of this project. Use these two source code listings as reference templates for your generated code.

For all Basic09 error handling syntax, you must defer exclusively to the basic09-error-handling.md document.

Review your generated Basic09 code against the provided basic09-error-handling.md and best-practices.txt. If a requested feature is not supported by Basic09, state this explicitly before before generating any code.

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

Labels as destinations for GOTO and GOSUB statements are not supported by Basic09. Literal line numbers in GOTO and GOSUB statements should be left as is.  The transpiler should convert this:

```
ON ERROR GOTO ErrorHandler
ON value GOSUB GoodValue, BadValue, 300

! Application logic
END

GoodValue:
  ! Do something
  RETURN

BadValue:
  ! Do something
  RETURN

300:
  ! Do something
  RETURN

ErrorHandler:
  ! Do something
  END
```
to this

```
ON ERROR GOTO 400
ON value GOSUB 100, 200, 300

! Application logic
END

100: \ ! GoodValue
  ! Do something
  RETURN

200: \ ! BadValue
  ! Do something
  RETURN

300: \ ! Literal Line Number
  ! Do something
  END

400: \ ! ErrorHandler
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
